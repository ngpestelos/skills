---
name: neovim-configuration
description: "Guides Neovim configuration through home-manager programs.neovim module. Auto-activates when working with Neovim plugins, themes, nvim-tree, lualine, or LSP setup in flake.nix. Covers plugin management, file explorer configuration, theme consistency, duplicate installation prevention, and PATH issues. Trigger keywords: neovim, nvim-tree, lualine, colorscheme, theme, plugin, extraLuaConfig, home-manager, buildInputs, devShells, direnv, duplicate, PATH, theme not found, buffer, NvimTreeFocus, NvimTreeResize."
metadata:
  version: "1.0.1"
---

# Configuring Neovim in Nix Home-Manager

## Core Principles

1. **Single source of truth**: Use ONLY `programs.neovim` — never install bare `neovim` in `home.packages` or `devShell.buildInputs`
2. **All config in `programs.neovim`**: Plugins in `plugins` list, behavior in `extraLuaConfig`
3. **Always pcall-wrap plugin setup**: Prevents crashes when plugin unavailable
4. **Theme sync**: Plugin list, `colorscheme` command, and lualine `theme = 'auto'` must agree

## Required Patterns

### Protected Plugin Loading

```lua
local plugin_ok, plugin = pcall(require, 'plugin-name')
if plugin_ok then
  plugin.setup({ --[[ config ]] })
end
```

### Nvim-tree Configuration

Use dynamic width with file highlighting and resize keybindings:

```lua
local nvim_tree_ok, nvim_tree = pcall(require, 'nvim-tree')
if nvim_tree_ok then
  nvim_tree.setup({
    view = {
      width = { min = 30, max = 60, padding = 1 },
    },
    actions = {
      open_file = { quit_on_open = false },
    },
    update_focused_file = {
      enable = true,
      update_root = false,
    },
  })

  vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { desc = 'Toggle file tree' })
  vim.keymap.set('n', '<leader>ef', ':NvimTreeFocus<CR>', { desc = 'Focus file tree' })
  vim.keymap.set('n', '<leader>w+', ':NvimTreeResize +5<CR>', { desc = 'Increase tree width' })
  vim.keymap.set('n', '<leader>w-', ':NvimTreeResize -5<CR>', { desc = 'Decrease tree width' })

  local is_wide = false
  vim.keymap.set('n', '<leader>ww', function()
    is_wide = not is_wide
    vim.cmd.NvimTreeResize(is_wide and 55 or 35)
  end, { desc = 'Toggle tree width (narrow/wide)' })
end
```

Key settings: `quit_on_open = false` keeps tree open, `update_focused_file` highlights current buffer's file, dynamic `width` adapts to content. Width also accepts static (`40`), percentage (`"30%"`), or function values.

### Theme Consistency

Keep these three synchronized:

```nix
# 1. Plugin in list
plugins = with pkgs.vimPlugins; [ tokyonight-nvim ];
```

```lua
-- 2. Colorscheme with fallback
vim.defer_fn(function()
  local ok, _ = pcall(vim.cmd, "colorscheme tokyonight")
  if not ok then print("Theme tokyonight not found, using default") end
end, 0)

-- 3. Lualine auto-detects from active colorscheme
local lualine_ok, lualine = pcall(require, 'lualine')
if lualine_ok then
  lualine.setup { options = { theme = 'auto' } }
end
```

Use `<leader>tt` for `:Telescope colorscheme` to browse themes interactively.

## Forbidden Patterns

### Bare Neovim Package (Critical)

```nix
-- WRONG: Creates TWO neovim installations; bare version takes PATH precedence
-- (especially in direnv/nix-shell), causing "Theme not found" errors
home.packages = with pkgs; [ neovim ];  -- Remove this
```

Affects `home.packages`, `buildInputs` in devShells, and per-workstation configs. After removal, clear direnv cache: `rm -rf .direnv && direnv allow`.

### Mismatched Themes

```lua
-- WRONG: colorscheme and lualine reference different themes
vim.cmd("colorscheme tokyonight")
lualine.setup { options = { theme = 'gruvbox-material' } }
```

Also remove unused theme plugins from `plugins` list.

### Unprotected Require

```lua
-- WRONG: crashes if plugin missing
local telescope = require('telescope')

-- RIGHT: pcall wrapper
local telescope_ok, telescope = pcall(require, 'telescope')
if telescope_ok then telescope.setup{} end
```

## Quick Decision Tree

- **Adding a plugin?** Add to `plugins` + setup in `extraLuaConfig` with pcall + rebuild
- **Removing a plugin?** Remove from `plugins` + remove setup code + update theme refs + rebuild
- **Changing theme?** Update plugin list + `colorscheme` command + keep lualine `'auto'` + rebuild

## Common Mistakes

### Plugin Name Mismatch

Nix package name differs from Lua require name:
```
Nix: nvim-tree-lua    Lua: require('nvim-tree')
```

### Post-Rebuild: Verify Correct Binary

```bash
which nvim  # Expected: /etc/profiles/per-user/$USER/bin/nvim
exec zsh    # Refresh shell after darwin-rebuild
```

## Violation Detection

```bash
# Unprotected plugin calls
grep -n "= require(" flake.nix

# Theme inconsistencies
grep "colorscheme\|theme.*=" flake.nix

# Duplicate neovim installations
awk '/home.packages|buildInputs/,/];/' flake.nix | grep -n "neovim"

# Verify theme loads
nvim --headless +"colorscheme tokyonight" +"echo 'Success'" +quit 2>&1
```
