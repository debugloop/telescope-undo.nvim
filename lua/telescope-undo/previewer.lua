local previewers = require("telescope.previewers")

function get_previewer(opts)
  if opts.use_delta and vim.fn.executable("bash") == 1 and vim.fn.executable("delta") == 1 then
    return previewers.new_termopen_previewer({
      get_command = function(entry, status)
        return {
          "bash",
          "-c",
          "echo '" .. entry.value.diff:gsub("'", [['"'"']]) .. "' | delta",
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
