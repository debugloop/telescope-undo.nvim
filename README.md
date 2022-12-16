# telescope-undo
Search and browse your buffers' undo trees.

## Usage

After invoking `telescope-undo` you can browse the undo tree in a graphical representation by using
telescope's `move_selection_next/previous` actions. These are mapped to arrow keys or `<C-n>,<C-p>`
by default. Inserted text is fuzzy matched against the additions and deletions in each undo state
in your undo tree. The previewer will show the diff with some context according to your `scrolloff`
value.

If you have found the undo state you were looking for, you can use `<C-cr>` to revert to that state.
If you'd rather not change your whole buffer, you can use `<cr>` or `<S-cr>` to yank the additions
or deletions of this undo state into your default buffer.

Invoke it using:

```viml
:Telescope undo
" or
:lua require('telescope-undo')()
```

I prefer to use this mapping:

```lua
vim.keymap.set("n", "<leader>u", "<cmd>Telescope undo<cr>")
```

## Installation
Install with your favorite Neovim package manager.

[dep.nvim](https://github.com/chiyadev/dep):

```lua
require("dep")({
  {
    "debugloop/telescope-undo",
    function()
      require("telescope").load_extension("undo")
      vim.keymap.set("n", "<leader>u", "<cmd>Telescope undo<cr>")
    end,
    requires = { "nvim-telescope/telescope.nvim" },
  },
})
```

[packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'debugloop/telescope-undo',
  requires = { 'nvim-telescope/telescope.nvim' },
  config = function()
    require("telescope").load_extension("undo")
  end,
}
```

## Configuration

None, yet :)
