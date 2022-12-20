# telescope-undo.nvim
Visualize your undo tree and fuzzy-search changes in it. For those days where committing early and
often doesn't work out.

![screenshot](https://user-images.githubusercontent.com/4604331/208297854-df5a104a-2fc1-4411-9f5f-5e40454d8dac.png)

## Usage

After invoking `telescope-undo` you can browse the current buffer's undo tree in a text-based tree
representation by using telescope's `move_selection_next/previous` actions. These are mapped to
arrow keys or `<C-n>,<C-p>` by default. Inserted text is fuzzy matched against the additions and
deletions in each undo state in your undo tree and the finder will limit the results accordingly.
While this obviously breaks the tree visuals, you can freely search in your undo states. The
previewer will always show the diff of the current selection with some context according to your
`scrolloff` value.

If you have found the undo state you were looking for, you can use `<C-cr>` to revert to that state.
If you'd rather not change your whole buffer, you can use `<cr>` to yank the additions of this undo
state into your default register (use `<S-cr>` to yank the deletions).

Invoke using:

```viml
:Telescope undo
" or
:lua require('telescope-undo')()
```

Or use my preferred mapping:

```lua
vim.keymap.set("n", "<leader>u", "<cmd>Telescope undo<cr>")
```

## Installation
Install with your favorite Neovim package manager.

[dep.nvim](https://github.com/chiyadev/dep):

```lua
require("dep")({
  {
    "debugloop/telescope-undo.nvim",
    function()
      require("telescope").load_extension("undo")
      -- optional: vim.keymap.set("n", "<leader>u", "<cmd>Telescope undo<cr>")
    end,
    requires = { "nvim-telescope/telescope.nvim" },
  },
})
```

[packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'debugloop/telescope-undo.nvim',
  requires = { 'nvim-telescope/telescope.nvim' },
  config = function()
    require("telescope").load_extension("undo")
    -- optional: vim.keymap.set("n", "<leader>u", "<cmd>Telescope undo<cr>")
  end,
}
```

## Configuration

The available configuration values are:

* `use_delta`, which controls whether [delta](https://github.com/dandavison/delta) is used for fancy
diffs in the preview section. If set to false, `telescope-undo` will not use `delta` even when
available and fall back to a plain diff with treesitter highlights.
* `side_by_side`, which tells `delta` to render diffs side-by-side. Thus, requires `delta` to be
used.

The full list will always be available in the code providing the defaults
[here](https://github.com/debugloop/telescope-undo.nvim/blob/main/lua/telescope/_extensions/undo.lua#L6).

```lua
require("telescope").setup({
  extensions = {
    undo = {
      use_delta = true,     -- this is the default
      side_by_side = false, -- this is the default
    },
  },
})
```

My personal recommendation is the following, which maximizes the width of the preview to enable
side-by-side diffs:

```lua
require("telescope").setup({
  extensions = {
    undo = {
      side_by_side = true,
      layout_strategy = "vertical",
      layout_config = {
        preview_height = 0.8,
      },
    },
  },
})
```

## Contributions

Suggestions, issues and patches are very much welcome. There are some TODOs sprinkeled into the code
that need addressing, but could also use some input and opinions.
