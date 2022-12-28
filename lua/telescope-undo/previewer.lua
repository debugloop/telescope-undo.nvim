local previewers = require("telescope.previewers")

function get_previewer(opts)
  if opts.use_custom_command ~= nil then
    return previewers.new_termopen_previewer({
      get_command = function(entry, status)
        local difftext = entry.value.diff:gsub("'", [['"'"']])
        local shlexed = {}
        for i, part in ipairs(opts.use_custom_command) do
          shlexed[i] = part:gsub("$DIFF", difftext)
        end
        return shlexed
      end,
    })
  end
  if opts.use_delta and vim.fn.executable("bash") == 1 and vim.fn.executable("delta") == 1 then
    return previewers.new_termopen_previewer({
      get_command = function(entry, status)
        local append = ""
        if opts.side_by_side == true then
          append = append .. " -s"
        end
        return {
          "bash",
          "-c",
          "echo '" .. entry.value.diff:gsub("'", [['"'"']]) .. "' | delta" .. append,
          -- HACK: check out this escape method -----^
        }
      end,
    })
  else
    return previewers.new_buffer_previewer({
      -- this is not the prettiest preview...
      define_preview = function(self, entry, status)
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, true, vim.split(entry.value.diff, "\n"))
        require("telescope.previewers.utils").highlighter(
          self.state.bufnr,
          "diff",
          { preview = { treesitter = { enable = {} } } }
        )
      end,
    })
  end
end
