local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values

require("telescope-undo.actions")
local get_previewer = require("telescope-undo.previewer").get_previewer
local timeago = require("telescope-undo.lua-timeago").timeago

local function _traverse_undotree(opts, entries, level)
  local undolist = {}
  -- create diffs for each entry in our undotree
  for i = #entries, 1, -1 do
    if opts.saved_only ~= nil and opts.saved_only and entries[i].save == nil then
      goto continue
    end
    -- grab the buffer as it is after this iteration's undo state
    local success = pcall(function()
      vim.cmd("silent undo " .. entries[i].seq)
    end)
    if not success then
      vim.notify_once(
        "Encountered a bad state in nvim's native undolist for buffer "
          .. vim.api.nvim_buf_get_name(0)
          .. ", showing partial results.",
        vim.log.levels.ERROR
      )
      return undolist
    end

    local buffer_after_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false) or {}
    local buffer_after = table.concat(buffer_after_lines, "\n")

    -- grab the buffer as it is after this undo state's parent
    success = pcall(function()
      vim.cmd("silent undo")
    end)
    if not success then
      vim.notify_once(
        "Encountered a bad state in nvim's native undolist for buffer "
          .. vim.api.nvim_buf_get_name(0)
          .. ", showing partial results.",
        vim.log.levels.ERROR
      )
      return undolist
    end
    local buffer_before_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false) or {}
    local buffer_before = table.concat(buffer_before_lines, "\n")

    -- build diff header so that delta can go ahead and syntax highlight
    local filename = vim.fn.expand("%")
    local header = filename .. "\n--- " .. filename .. "\n+++ " .. filename .. "\n"

    -- do the diff using our internal diff function
    local diff = vim.diff(buffer_before, buffer_after, opts.vim_diff_opts)

    -- extract data for yanking and searching
    local ordinal = ""
    local additions = {}
    local deletions = {}
    for line in (diff .. "\n"):gmatch("(.-)\n") do
      if line:sub(1, 1) == "+" then
        local content = line:sub(2, -1)
        table.insert(additions, content)
        ordinal = ordinal .. content
      elseif line:sub(1, 1) == "-" then
        local content = line:sub(2, -1)
        table.insert(deletions, content)
        ordinal = ordinal .. content
      end
    end

    -- use the data we just created to feed into our finder later
    table.insert(undolist, {
      seq = entries[i].seq, -- save state number, used in display and to restore
      alt = level, -- current level, i.e. how deep into alt branches are we, used to graph
      first = i == #entries, -- whether this is the first node in this branch, used to graph
      time = entries[i].time, -- save state time, used in display
      ordinal = ordinal, -- a long string of all additions and deletions, used for search
      diff = header .. diff, -- the proper diff, used for preview
      additions = additions, -- all additions, used to yank a result
      deletions = deletions, -- all deletions, used to yank a result
      bufnr = vim.api.nvim_get_current_buf(), -- for which buffer this telescope was invoked, used to restore
    })

    -- descend recursively into alternate histories of undo states
    if entries[i].alt ~= nil then
      local alt_undolist = _traverse_undotree(opts, entries[i].alt, level + 1)
      -- pretend these results are our results
      for _, elem in pairs(alt_undolist) do
        table.insert(undolist, elem)
      end
    end
    ::continue::
  end
  return undolist
end

local function build_undolist(opts)
  -- save our current cursor
  local cursor = vim.api.nvim_win_get_cursor(0)

  -- get all diffs
  local ut = vim.fn.undotree()

  -- TODO: maybe use this opportunity to limit the number of root nodes we process overall, to ensure good performance
  local undolist = _traverse_undotree(opts, ut.entries, 0)

  -- restore everything after all diffs have been created
  -- BUG: `gi` (last insert location) is being killed by our method, we should save that as well
  vim.cmd("silent undo " .. ut.seq_cur)
  vim.api.nvim_win_set_cursor(0, cursor)

  return undolist
end

local M = {}

M.undo = function(opts)
  if not vim.api.nvim_get_option_value("modifiable", { buf = 0 }) then
    print("telescope-undo.nvim: Current buffer is not modifiable.")
    return
  end
  opts = opts or {}
  pickers
    .new(opts, {
      prompt_title = "Undo History",
      finder = finders.new_table({
        results = build_undolist(opts),
        entry_maker = function(undo)
          local order = opts.sorting_strategy or conf.sorting_strategy

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
              local corner = order == "ascending" and "┌" or "└"
              prefix = prefix .. corner .. "╴"
            else
              prefix = prefix .. "├╴"
            end
          end
          local diffstat = ""
          if #undo.additions > 0 then
            diffstat = "+" .. #undo.additions
          end
          if #undo.deletions > 0 then
            if diffstat ~= "" then
              diffstat = diffstat .. " "
            end
            diffstat = "-" .. #undo.deletions
          end
          local formatted_time = opts.time_format == "" and timeago(undo.time) or os.date(opts.time_format, undo.time)
          return {
            value = undo,
            display = prefix
              .. opts.entry_format:gsub("$ID", undo.seq):gsub("$STAT", diffstat):gsub("$TIME", formatted_time),
            ordinal = undo.ordinal,
          }
        end,
      }),
      previewer = get_previewer(opts),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        for _, mode in pairs({ "i", "n" }) do
          for key, get_action in pairs(opts.mappings[mode] or {}) do
            map(mode, key, get_action(prompt_bufnr))
          end
        end
        -- TODO: provide means to filter for time frames
        return true -- include defaults as well
      end,
    })
    :find()
end

return M
