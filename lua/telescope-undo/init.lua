local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local actions = require("telescope.actions")
local conf = require("telescope.config").values

require("telescope-undo.previewer")
require("telescope-undo.mappings")
require("telescope-undo.lua-timeago")

function _traverse_undotree(entries, level)
  local undolist = {}
  -- create diffs for each entry in our undotree
  for i = #entries, 1, -1 do
    -- grab the buffer as it is after this iteration's undo state
    vim.cmd("silent undo " .. entries[i].seq)
    buffer_after_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false) or {}
    buffer_after = table.concat(buffer_after_lines, "\n")

    -- grab the buffer as it is after this undo state's parent
    vim.cmd("silent undo")
    buffer_before_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false) or {}
    buffer_before = table.concat(buffer_before_lines, "\n")

    -- create temporary vars and prepare this iteration
    diff = ""
    ordinal = ""
    additions = {}
    deletions = {}
    on_hunk_callback = function(start_a, count_a, start_b, count_b)
      -- build diff header for this hunk, this is important for delta to show line numbers
      diff = diff .. "@@ -" .. start_a
      if count_a ~= 1 then
        diff = diff .. "," .. count_a
      end
      diff = diff .. " +" .. start_b
      if count_b ~= 1 then
        diff = diff .. "," .. count_b
      end
      diff = diff .. " @@"
      -- get front context based on scrolloff
      for i = start_a - vim.o.scrolloff, start_a - 1 do
        if buffer_before_lines[i] ~= nil then
          diff = diff .. "\n " .. buffer_before_lines[i]
        end
      end
      -- get deletions
      for i = start_a, start_a + count_a - 1 do
        diff = diff .. "\n-" .. buffer_before_lines[i]
        table.insert(deletions, buffer_before_lines[i])
        ordinal = ordinal .. buffer_before_lines[i]
      end
      -- get additions
      for i = start_b, start_b + count_b - 1 do
        diff = diff .. "\n+" .. buffer_after_lines[i]
        table.insert(additions, buffer_after_lines[i])
        ordinal = ordinal .. buffer_after_lines[i]
      end
      -- and finally, get some more context in the back
      for i = start_a + count_a, start_a + count_a + vim.o.scrolloff - 1 do
        if buffer_before_lines[i] ~= nil then
          diff = diff .. "\n " .. buffer_before_lines[i]
        end
      end
      -- terminate all this with a newline, so we're ready for the next hunk
      diff = diff .. "\n"
    end

    -- do the diff using our internal diff function
    vim.diff(buffer_before, buffer_after, {
      result_type = "indices",
      on_hunk = on_hunk_callback,
      algorithm = "patience",
    })

    -- use the data we just created to feed into our finder later
    table.insert(undolist, {
      seq = entries[i].seq, -- save state number, used in display and to restore
      alt = level, -- current level, i.e. how deep into alt branches are we, used to graph
      first = i == #entries, -- whether this is the first node in this branch, used to graph
      time = entries[i].time, -- save state time, used in display
      ordinal = ordinal, -- a long string of all additions and deletions, used for search
      diff = diff, -- the proper diff, used for preview
      additions = additions, -- all additions, used to yank a result
      deletions = deletions, -- all deletions, used to yank a result
      bufnr = vim.api.nvim_get_current_buf(), -- for which buffer this telescope was invoked, used to restore
    })

    -- descend recursively into alternate histories of undo states
    if entries[i].alt ~= nil then
      alt_undolist = _traverse_undotree(entries[i].alt, level + 1)
      -- pretend these results are our results
      for _, elem in pairs(alt_undolist) do
        table.insert(undolist, elem)
      end
    end
  end
  return undolist
end

function build_undolist()
  -- save our current cursor
  local cursor = vim.api.nvim_win_get_cursor(0)

  -- get all diffs
  local ut = vim.fn.undotree()

  -- TODO: maybe use this opportunity to limit the number of root nodes we process overall, to ensure good performance
  local undolist = _traverse_undotree(ut.entries, 0)

  -- restore everything after all diffs have been created
  -- BUG: `gi` (last insert location) is being killed by our method, we should save that as well
  vim.cmd("silent undo " .. ut.seq_cur)
  vim.api.nvim_win_set_cursor(0, cursor)

  return undolist
end

function undo(opts)
  if not vim.api.nvim_buf_get_option(0, "modifiable") then
    print("telescope-undo.nvim: Current buffer is not modifiable.")
    return
  end
  opts = opts or {}
  pickers
    .new(opts, {
      prompt_title = "Undo History",
      finder = finders.new_table({
        results = build_undolist(),
        entry_maker = function(undo)
          -- TODO: show a table instead of a list
          if #undo.additions + #undo.deletions == 0 then
            -- skip empty changes, vim has these sometimes...
            return nil
          end
          -- the following prefix should work out to this graph structure:
          -- state #1
          -- └─state #2
          -- state #3
          -- ├─state #4
          -- └─state #5
          -- state #6
          -- ├─state #7
          -- ┆ ├─state #8
          -- ┆ └─state #9
          -- └─state #10
          local prefix = ""
          if undo.alt > 0 then
            prefix = string.rep("┆ ", undo.alt - 1)
            if undo.first then
              prefix = prefix .. "└─"
            else
              prefix = prefix .. "├─"
            end
          end
          return {
            value = undo,
            display = prefix
              .. "state #"
              .. undo.seq
              .. ", +"
              .. #undo.additions
              .. " -"
              .. #undo.deletions
              .. ", "
              .. timeago(undo.time),
            ordinal = undo.ordinal,
          }
        end,
      }),
      previewer = get_previewer(),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        -- TODO: make these configurable
        map("i", "<c-cr>", function()
          restore()
          actions.close(prompt_bufnr)
        end)
        map("i", "<s-cr>", function()
          yank_deletions()
          actions.close(prompt_bufnr)
        end)
        map("i", "<cr>", function()
          yank_additions()
          actions.close(prompt_bufnr)
        end)
        -- TODO: provide means to filter for time frames
        return true -- include defaults as well
      end,
    })
    :find()
end

return undo
