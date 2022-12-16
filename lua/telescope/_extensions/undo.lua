local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  error("telescope_undo.nvim requires telescope.nvim - https://github.com/nvim-telescope/telescope.nvim")
end

return telescope.register_extension({
  setup = function(ext_config, config)
    -- access extension config and user config
  end,
  exports = {
    undo = require("telescope-undo"),
  },
})
