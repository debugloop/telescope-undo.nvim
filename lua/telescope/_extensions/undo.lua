local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  error("telescope_undo.nvim requires telescope.nvim - https://github.com/nvim-telescope/telescope.nvim")
end

-- full list of available config items and their defaults
local defaults = {
  use_delta = true,
  use_custom_command = nil, -- should be in this format: { "bash", "-c", "echo '$DIFF' | delta" }
  side_by_side = false,
  diff_context_lines = vim.o.scrolloff,
  entry_format = "state #$ID, $STAT, $TIME",
  time_format = "",
  saved_only = false,
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

M = {
  exports = {},
}

M.exports.undo = function(config)
  config = vim.tbl_deep_extend("force", M.config, config or {})
  if config.theme then
    config = require("telescope.themes")["get_" .. config.theme](config)
  end
  require("telescope-undo").undo(config)
end

M.setup = function(extension_config, telescope_config)
  M.config = vim.tbl_deep_extend("force", defaults, extension_config)
  if M.config["side_by_side"] and not M.config["use_delta"] then
    error("telescope_undo.nvim: setting side_by_side but not use_delta will have no effect")
  end
end

return telescope.register_extension(M)
