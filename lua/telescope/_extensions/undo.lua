local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  error("telescope_undo.nvim requires telescope.nvim - https://github.com/nvim-telescope/telescope.nvim")
end

-- full list of available config items and their defaults
local config = {
  use_delta = true,
  use_custom_command = nil, -- should be in this format: { "bash", "-c", "echo '$DIFF' | delta" }
  side_by_side = false,
  diff_context_lines = vim.o.scrolloff,
  mappings = {
    i = {
      ["<cr>"] = require("telescope-undo.actions").yank_additions,
      ["<S-cr>"] = require("telescope-undo.actions").yank_deletions,
      ["<C-cr>"] = require("telescope-undo.actions").restore,
    },
  },
}

local undo = function()
  local telescope_undo = require("telescope-undo")
  telescope_undo.undo(config)
end

return telescope.register_extension({
  setup = function(extension_config, telescope_config)
    _ = telescope_config -- shut up lsp, I want this named for reference
    config = vim.tbl_extend("force", config, extension_config)
  end,
  exports = {
    undo = undo,
  },
})
