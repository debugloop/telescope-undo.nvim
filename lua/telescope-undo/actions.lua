local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")

function _get_default_register()
  local clipboardFlags = vim.split(vim.api.nvim_get_option("clipboard"), ",")
  if vim.tbl_contains(clipboardFlags, "unnamedplus") then
    return "+"
  end
  if vim.tbl_contains(clipboardFlags, "unnamed") then
    return "*"
  end
  return '"'
end

-- TODO maybe provide actions for the following:
--  * yank to arbitrary registers
--  * open state in new file
--  * rewind to last saved state
--  * goto lastest undo state
--  * something with git staging?
myactions = {}

-- these actions are returning named functions with the prompt_bufnr en-closured so that their metatable contains a name that telescope which-key can use
myactions.restore = function(prompt_bufnr)
  local function restore()
    -- makes the selected undo state the buffers current state
    entry = actions_state.get_selected_entry()
    if entry ~= nil then
      vim.api.nvim_buf_call(entry.value.bufnr, function()
        vim.cmd("undo " .. entry.value.seq)
      end)
      actions.close(prompt_bufnr)
    end
  end
  return restore
end

myactions.yank_deletions = function(prompt_bufnr)
  local function yank_deletions()
    -- yanks the deletions from the currently selected undo state into the default register
    entry = actions_state.get_selected_entry()
    if entry ~= nil then
      vim.fn.setreg(_get_default_register(), entry.value.deletions, (#entry.value.deletions > 1) and "V" or "v")
      actions.close(prompt_bufnr)
    end
  end
  return yank_deletions
end

myactions.yank_additions = function(prompt_bufnr)
  local function yank_additions()
    -- yanks the additions from the currently selected undo state into the default register
    entry = actions_state.get_selected_entry()
    if entry ~= nil then
      vim.fn.setreg(_get_default_register(), entry.value.additions, (#entry.value.additions > 1) and "V" or "v")
      actions.close(prompt_bufnr)
    end
  end
  return yank_additions
end

return myactions
