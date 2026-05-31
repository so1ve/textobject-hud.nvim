# textobject-hud.nvim

Show the Tree-sitter textobjects available at your cursor in a small floating HUD.

`textobject-hud.nvim` discovers captures from `textobjects.scm`, previews the exact source range under the HUD cursor, and selects that range.

## Requirements

- Neovim 0.12+
- Tree-sitter parser for the current buffer's language

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
  opts = {
    key_hints = {
      ["@function.outer"] = { "]f", "[f", "]F", "[F" },
      ["@parameter.inner"] = { "]a", "[a", "]A", "[A" },
    },
  },
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
require("textobject-hud").setup({
  -- Floating HUD window.
  window = {
    border = "rounded",
    width = 50,
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

  -- Candidate sources and safety limits.
  -- `textobjects` discovers captures from `textobjects.scm` automatically.
  -- `ancestors` adds generic AST nodes, so it is disabled by default.
  collect = {
    ancestors = false,
    textobjects = true,
    max_ancestor_depth = 20,
    max_lines = 200,
    include_anonymous = false,
  },

  -- Display-only capture-to-keys mapping. This does not define or whitelist
  -- textobjects; it only annotates captures that were already discovered.
  key_hints = {},
})
```

For complete documentation, see below.

## Documentation

See [textobject-hud.txt](./doc/textobject-hud.txt) or `:help textobject-hud.nvim`.

## License

[MIT](./LICENSE). Made with ❤️ by [Ray](https://github.com/so1ve)
