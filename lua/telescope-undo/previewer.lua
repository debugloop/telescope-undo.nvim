local previewers = require("telescope.previewers")
local is_wsl = (function()
  local output = vim.fn.systemlist("uname -r")
  return not not string.find(output[1] or "", "WSL")
end)()
local function get_previewer(opts)
  if opts.use_custom_command ~= nil then
    return previewers.new_termopen_previewer({
      get_command = function(entry, _)
        local difftext = entry.value.diff:gsub("'", [['"'"']])
        local shlexed = {}
        for i, part in ipairs(opts.use_custom_command) do
          shlexed[i] = part:gsub("$DIFF", difftext)
        end
        return shlexed
      end,
    })
  end
  local has_powershell = vim.fn.executable("powershell") == 1
  local has_bash = vim.fn.executable("bash") == 1
  if opts.use_delta and not is_wsl and (has_powershell or has_bash) and vim.fn.executable("delta") == 1 then
    return previewers.new_termopen_previewer({
      get_command = function(entry, _)
        local append = ""
        if opts.side_by_side == true then
          append = append .. " -s"
        end
        if has_powershell then
          return {
            "powershell",
            "-Command",
            "echo '" .. entry.value.diff:gsub([[']], [['']]) .. "' | delta" .. append,
          }
        elseif has_bash then
          return {
            "bash",
            "-c",
            "echo '" .. entry.value.diff:gsub("'", [['"'"']]) .. "' | delta" .. append,
            -- HACK: check out this escape method -----^
          }
        end
      end,
    })
  else
    return previewers.new_buffer_previewer({
      -- this is not the prettiest preview...
      define_preview = function(self, entry, _)
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
return { get_previewer = get_previewer }
