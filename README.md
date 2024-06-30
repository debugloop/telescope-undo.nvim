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
previewer will always show the diff of the current selection with some context according to the
config or your `scrolloff` value.

If you have found the undo state you were looking for, you can use `<C-cr>` or `<C-r>` to revert to
that state. If you'd rather not change your whole buffer, you can use `<cr>` to yank the additions
of this undo state into your default register (use `<S-cr>` or `<C-y>` to yank the deletions).

## Installation
Install with your favorite Neovim package manager.

As part of your Telescope plugin spec for [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "debugloop/telescope-undo.nvim",
  },
  config = function()
    require("telescope").setup({
      -- the rest of your telescope config goes here
      extensions = {
        undo = {
          -- telescope-undo.nvim config, see below
        },
        -- other extensions:
        -- file_browser = { ... }
      },
    })
    require("telescope").load_extension("undo")
    -- optional: vim.keymap.set("n", "<leader>u", "<cmd>Telescope undo<cr>")
  end,
},
```

If you prefer standalone Lazy plugin specs (my personal recommendation), here's how you do that with
some more options as an example:

```lua
{
  "debugloop/telescope-undo.nvim",
  dependencies = { -- note how they're inverted to above example
    {
      "nvim-telescope/telescope.nvim",
      dependencies = { "nvim-lua/plenary.nvim" },
    },
  },
  keys = {
    { -- lazy style key map
      "<leader>u",
      "<cmd>Telescope undo<cr>",
      desc = "undo history",
    },
  },
  opts = {
    -- don't use `defaults = { }` here, do this in the main telescope spec
    extensions = {
      undo = {
        -- telescope-undo.nvim config, see below
      },
      -- no other extensions here, they can have their own spec too
    },
  },
  config = function(_, opts)
    -- Calling telescope's setup from multiple specs does not hurt, it will happily merge the
    -- configs for us. We won't use data, as everything is in it's own namespace (telescope
    -- defaults, as well as each extension).
    require("telescope").setup(opts)
    require("telescope").load_extension("undo")
  end,
},
```

Invoke using:

```viml
" Directly by calling it through Telescope's extension interface:

" using lua
:lua require("telescope").extensions.undo.undo()

" using custom options for just this call
:lua require("telescope").extensions.undo.undo({ side_by_side = true })

" using legacy Vim script
:Telescope undo

" Using the optional mapping:

" using lua
:lua vim.keymap.set("n", "<leader>u", "<cmd>Telescope undo<cr>")
" using legacy Vim script
:nmap <leader>u <cmd>Telescope undo<cr>
```


## Configuration

The available configuration values are:

* `use_delta`, which controls whether [delta](https://github.com/dandavison/delta) is used for fancy
diffs in the preview section. If set to false, `telescope-undo` will not use `delta` even when
available and fall back to a plain diff with treesitter highlights.
* `use_custom_command`, which can be used to use an *unsupported* diff tool other than `delta`
* `side_by_side`, which tells `delta` to render diffs side-by-side. Thus, requires `delta` to be
used. Be aware that `delta` always uses its own configuration, so it might be that you're getting
the side-by-side view even if this is set to false.
* `vim_diff_opts`, defaults to all of `:help vim.diff` default options, but sets `ctxlen` to your
scrolloff value.
* `entry_format`, defaults to `"state #$ID, $STAT, $TIME""`, which contains the three supported
variables.
* `time_format`, defaults to "" for a timeago-style representation. Can be set to a [Lua date format
  string](https://www.lua.org/pil/22.1.html).
* `saved_only`, defaults to false, but can be used to limit shown undo states to those that have
been saved to disk.

Further, the undo telescope should accept any of the usual telescope attributes as well as the
special `theme` key which auto-extends the telescope theme *on top* of any of your explicitly
provided config. Of course, you might also want to remap some of the default keys.

This is what the defaults look like with some additional explanations:

```lua
opts = {
  extensions = {
    undo = {
      use_delta = true,
      use_custom_command = nil, -- setting this implies `use_delta = false`. Accepted format is: { "bash", "-c", "echo '$DIFF' | delta" }
      side_by_side = false,
      vim_diff_opts = {
        ctxlen = vim.o.scrolloff,
      },
      entry_format = "state #$ID, $STAT, $TIME",
      time_format = "",
      saved_only = false,
    },
  },
},
```

The full list will always be available in the code providing the defaults
[here](https://github.com/debugloop/telescope-undo.nvim/blob/main/lua/telescope/_extensions/undo.lua#L6).

My personal recommendation is the following, which maximizes the width of the preview to enable
side-by-side diffs:

```lua
opts = {
  extensions = {
    undo = {
      side_by_side = true,
      layout_strategy = "vertical",
      layout_config = {
        preview_height = 0.8,
      },
    },
  },
}
```

## Mappings

By default, the following mappings are enabled.

```lua
require("telescope").setup({
  extensions = {
    undo = {
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
    },
  },
})
```

> [!IMPORTANT]
> Note how above example uses the call to telescope's `setup()`. This is due to the fact that
> directly requiring these actions needs `telescope-undo` to be available already, which it is not
> inside lazy's `opts` key when using above "standalone" spec. See the next example for how to do it
> inside `opts`.

There is one more mapping available, `yank_larger`. This yanks either the additions or the deletions
based on their line count, with the additions winning in case of a tie. This is how you configure
this mapping, or remap any of the default actions for that matter:

```lua
opts = {
  extensions = {
    undo = {
      mappings = {
        -- Wrapping the actions inside a function prevents the error due to telescope-undo being not
        -- yet loaded.
        i = {
          ["<cr>"] = function(bufnr)
            return require("telescope-undo.actions").yank_larger(bufnr)
          end,
        },
        n = {
          ["y"] = function(bufnr)
            return require("telescope-undo.actions").yank_larger(bufnr)
          end,
        },
      },
    },
  },
}
```

If you wish to disable one of the default mappings, just set it to `false`.

```lua
opts = {
  extensions = {
    undo = {
      mappings = {
        i = {
          ["<C-y>"] = false,
        },
      },
    },
  },
}
```

## Contributions

Suggestions, issues and patches are very much welcome. There are some TODOs sprinkeled into the code
that need addressing, but could also use some input and opinions.
