local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  error("telescope_undo.nvim requires telescope.nvim - https://github.com/nvim-telescope/telescope.nvim")
end

-- full list of available config items and their defaults
local defaults = {
  use_delta = true,
  use_custom_command = nil, -- should be in this format: { "bash", "-c", "echo '$DIFF' | delta" }
  side_by_side = false,
  entry_format = "state #$ID, $STAT, $TIME",
  time_format = "",
  saved_only = false,
  vim_diff_opts = {
    ctxlen = vim.o.scrolloff,
  },
  mappings = {
    i = {
      ["<cr>"] = require("telescope-undo.actions").yank_additions,
      ["<S-cr>"] = require("telescope-undo.actions").yank_deletions,
      ["<C-cr>"] = require("telescope-undo.actions").restore,
      -- alternative defaults, for users whose terminals do questionable things with modified <cr>
      ["<C-y>"] = require("telescope-undo.actions").yank_deletions,
      ["<C-r>"] = require("telescope-undo.actions").restore,
    },
    n = {
      ["y"] = require("telescope-undo.actions").yank_additions,
      ["Y"] = require("telescope-undo.actions").yank_deletions,
      ["u"] = require("telescope-undo.actions").restore,
    },
  },
}

local M = {
  exports = {},
}

local function extend_config(base, extend)
  local config = vim.tbl_deep_extend("force", base, extend)
  -- deprecation notices
  if config.diff_context_lines ~= nil then
    vim.deprecate(
      "diff_context_lines",
      "vim_diff_opts = { ctxlen = " .. config.diff_context_lines .. " }",
      "1.0",
      "telescope-undo.nvim",
      false
    )
    config.vim_diff_opts.ctxlen = config.diff_context_lines
    config.diff_context_lines = nil
  end

  -- warn about impossible configurations
  if config["side_by_side"] and not config["use_delta"] then
    error("telescope_undo.nvim: setting side_by_side but not use_delta will have no effect")
  end

  -- remove default keymaps that have been disabled by the user
  for _, mode in ipairs({ "i", "n" }) do
    config.mappings[mode] = vim.tbl_map(function(val)
      return val ~= false and val or nil
    end, config.mappings[mode])
  end

  -- expand theme configs
  if config.theme then
    config = require("telescope.themes")["get_" .. config.theme](config)
  end
  return config
end

M.exports.undo = function(config)
  local final_config
  -- skip reevaluation of extend_config if we're updating with an empty table
  if config == nil or next(config) == nil then
    final_config = M.config
  else
    final_config = extend_config(M.config, config)
  end
  require("telescope-undo").undo(final_config)
end

M.setup = function(extension_config, _)
  M.config = extend_config(defaults, extension_config)
end

return telescope.register_extension(M)
