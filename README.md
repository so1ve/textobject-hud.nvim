# textobject-hud.nvim

Show the textobjects and selectable ranges available at your cursor in a small floating HUD.

`textobject-hud.nvim` collects candidates from configured sources, previews the exact source range under the HUD cursor, and selects that range. Built-in sources include Tree-sitter textobject captures and mini.ai textobjects.

## Requirements

- Neovim 0.12+
- Tree-sitter parser for the current buffer's language when using the Tree-sitter source
- Optional: `nvim-treesitter-textobjects` query files for Tree-sitter textobject captures
- Optional: `mini.ai` for mini.ai textobject candidates

## Installation

### lazy.nvim

```lua
{
  "so1ve/textobject-hud.nvim",
  keys = {
    {
      "<leader>o",
      function()
        require("textobject-hud").open()
      end,
      desc = "Open textobject HUD",
    },
  },
  opts = function()
    local hud = require("textobject-hud")

    return {
      sources = {
        hud.sources.treesitter,
        hud.sources.mini_ai,
      },
      key_hints = {
        ["treesitter:@function.outer"] = { "]f", "[f", "]F", "[F" },
        ["treesitter:@parameter.inner"] = { "]a", "[a", "]A", "[A" },
      },
    }
  end,
}
```

## Usage

Open the HUD with `:TextobjectHud` or:

```lua
require("textobject-hud").open()
```

Inside the HUD:

| Key | Action |
| --- | --- |
| `<CR>` | Select candidate |
| `q` / `<Esc>` | Close HUD |

Use native window movement (`j`, `k`, arrows, `<C-d>`, `<C-u>`, mouse, etc.) to move the HUD cursor.

## Default config

```lua
local hud = require("textobject-hud")

hud.setup({
  -- Floating HUD window.
  window = {
    border = "rounded",
    max_height = 12,
    row_offset = 1,
    col_offset = 1,
    follow = true,
  },

  -- Source-buffer range preview shown while the HUD is open.
  preview = {
    enabled = true,
    hl_group = "TextobjectHudRange",
  },

  -- Candidate sources. Replace this list to choose exactly which sources run.
  -- Built-ins are available as `require("textobject-hud").sources.*`.
  sources = {
    hud.sources.treesitter,
    hud.sources.mini_ai,
  },

  -- Source safety limits.
  -- `max_ancestor_depth` and `include_anonymous` affect `treesitter_ancestors`.
  collect = {
    max_ancestor_depth = 20,
    max_lines = 200,
    include_anonymous = false,
  },

  -- Display-only source-prefixed candidate-to-keys mapping. This does not define
  -- or whitelist textobjects; it only annotates candidates that were discovered.
  key_hints = {},
})
```

`key_hints` keys use each source's `key_prefix`, for example `treesitter:@function.outer`, `mini_ai:a(`, or `treesitter_ancestors:function_definition`.

For complete documentation, see below.

## Documentation

See [textobject-hud.txt](./doc/textobject-hud.txt) or `:help textobject-hud.nvim`.

## License

[MIT](./LICENSE). Made with ❤️ by [Ray](https://github.com/so1ve)
