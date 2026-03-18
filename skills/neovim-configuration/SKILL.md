---
name: neovim-configuration
description: "Guides Neovim configuration through home-manager programs.neovim module. Auto-activates when working with Neovim plugins, themes, nvim-tree, lualine, or LSP setup in flake.nix. Covers plugin management, file explorer configuration, theme consistency, duplicate installation prevention, buffer navigation, and PATH issues. Trigger keywords: neovim, nvim-tree, lualine, colorscheme, theme, plugin, extraLuaConfig, home-manager, buildInputs, devShells, direnv, duplicate, PATH, theme not found, buffer, buffer navigation, NvimTreeFocus, NvimTreeResize."
metadata:
  version: 1.0.0
---

# Configuring Neovim in Nix Home-Manager

## Core Principles

1. **Single source of truth**: Use ONLY `programs.neovim` module for Neovim - never install bare `neovim` package in `home.packages` or `devShell.buildInputs`
2. **Configuration in flake.nix**: All Neovim settings live in `programs.neovim` within home-manager configuration
3. **Plugin consistency**: Plugins referenced in `plugins` list must match those configured in `extraLuaConfig`
4. **Theme auto-detection**: Use `theme = 'auto'` in lualine to automatically match active colorscheme
5. **User-friendly defaults**: Configure plugins with sensible defaults (e.g., nvim-tree stays open, adequate width)

## Required Patterns

### Nvim-tree File Explorer Configuration

Three configuration tiers (each builds on the previous):

| Tier | Key Settings | Use When |
|------|-------------|----------|
| Basic | `width = 40`, `quit_on_open = false` | Minimum acceptable config |
| Highlighting | + `update_focused_file.enable = true` | Default recommendation |
| Dynamic width | + `width = { min = 30, max = 60 }`, resize keybindings | Full-featured setup |

**Canonical configuration (Tier 3 — dynamic width with all features):**

```lua
local nvim_tree_ok, nvim_tree = pcall(require, 'nvim-tree')
if nvim_tree_ok then
  nvim_tree.setup({
    view = {
      width = {
        min = 30,      -- Minimum width in columns
        max = 60,      -- Maximum width (adapts to content)
        padding = 1,
      },
    },
    actions = {
      open_file = {
        quit_on_open = false,  -- Keep tree open when opening files
      },
    },
    update_focused_file = {
      enable = true,        -- Highlight current buffer's file in tree
      update_root = false,  -- Don't change tree root to match file
    },
  })

  -- Tree visibility and focus
  vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { desc = 'Toggle file tree' })
  vim.keymap.set('n', '<leader>ef', ':NvimTreeFocus<CR>', { desc = 'Focus file tree' })

  -- Width adjustment keybindings
  vim.keymap.set('n', '<leader>w+', ':NvimTreeResize +5<CR>', { desc = 'Increase tree width' })
  vim.keymap.set('n', '<leader>w-', ':NvimTreeResize -5<CR>', { desc = 'Decrease tree width' })

  -- Toggle between narrow and wide presets
  local is_wide = false
  vim.keymap.set('n', '<leader>ww', function()
    is_wide = not is_wide
    vim.cmd.NvimTreeResize(is_wide and 55 or 35)
  end, { desc = 'Toggle tree width (narrow/wide)' })
end
```

**Navigation patterns:**
- `<leader>e` — Toggle nvim-tree visibility
- `<leader>ef` — Focus nvim-tree (move cursor to tree without toggling)
- `Ctrl-h` / `Ctrl-l` — Navigate between windows (tree <-> editor)
- `<leader>w+` / `<leader>w-` — Adjust width by 5 columns
- `<leader>ww` — Toggle narrow (35) / wide (55) presets

**Width options:** Static (`width = 40`), percentage (`width = "30%"`), dynamic bounds (`width = { min = 30, max = 60 }`), or function-based.

### Buffer Navigation Keybindings

```lua
-- Bracket-style navigation (follows Vim convention like [c/]c for quickfix)
vim.keymap.set('n', '[b', ':bprevious<CR>', { desc = 'Previous buffer' })
vim.keymap.set('n', ']b', ':bnext<CR>', { desc = 'Next buffer' })
vim.keymap.set('n', '<leader>bd', ':bd<CR>', { desc = 'Delete buffer' })
```

Complements Telescope buffer picker (`<leader>fb`).

### Theme Consistency

**Keep these three elements synchronized:**

1. Plugin in `plugins` list:
```nix
plugins = with pkgs.vimPlugins; [
  tokyonight-nvim  # Current default theme
];
```

2. Default colorscheme in `extraLuaConfig`:
```lua
vim.defer_fn(function()
  local ok, _ = pcall(vim.cmd, "colorscheme tokyonight")
  if not ok then
    print("Theme tokyonight not found, using default")
  end
end, 0)
```

3. Lualine theme — use `'auto'` to auto-detect from active colorscheme:
```lua
local lualine_ok, lualine = pcall(require, 'lualine')
if lualine_ok then
  lualine.setup {
    options = {
      theme = 'auto'
    }
  }
end
```

### Theme Switching Keybindings

```lua
vim.keymap.set('n', '<leader>tn', ':ThemeNext<CR>', { desc = 'Next theme' })
vim.keymap.set('n', '<leader>tt', ':Telescope colorscheme<CR>', { desc = 'Choose theme with Telescope' })
```

### Protected Plugin Loading

**ALWAYS wrap plugin setup with pcall:**

```lua
local plugin_ok, plugin = pcall(require, 'plugin-name')
if plugin_ok then
  plugin.setup({
    -- configuration here
  })
end
```

## Forbidden Patterns

### DON'T Use Default nvim-tree Settings

```lua
-- WRONG - Uses narrow width (30) and closes on file open
nvim_tree.setup()
```

### DON'T Forget File Highlighting Configuration

```lua
-- WRONG - No visual indication of current file in tree
nvim_tree.setup({
  view = { width = 40 },
  actions = { open_file = { quit_on_open = false } },
  -- Missing: update_focused_file configuration
})
```

### DON'T Use Fixed Width Without Adjustment Options

```lua
-- WRONG - Locked into single width with no flexibility
nvim_tree.setup({
  view = { width = 40 },
})
-- No keybindings to resize
```

### DON'T Keep Unused Theme Plugins

```nix
# WRONG - Loading theme that's not used
plugins = with pkgs.vimPlugins; [
  gruvbox-material  # Not using this anymore
  tokyonight-nvim   # Actually using this
];
```

### DON'T Mismatch Theme References

```lua
-- WRONG - Inconsistent theme references
vim.cmd("colorscheme tokyonight")
lualine.setup { options = { theme = 'gruvbox-material' } }  -- Different theme!
```

### DON'T Install Bare Neovim Package

```nix
# WRONG - Duplicate neovim installations
home.packages = with pkgs; [ neovim ];  # AND ALSO:
programs.neovim = { enable = true; plugins = [ /* ... */ ]; };
```

**Critical**: Creates TWO neovim installations — bare version takes PATH precedence (especially in direnv/nix-shell), causing "Theme not found" errors. Affects `home.packages`, `buildInputs` in devShells, and per-workstation configs. Remove ALL bare `neovim` packages; use ONLY `programs.neovim`.

## Quick Decision Tree

- **Adding a plugin?** -> Add to `plugins` list + setup in `extraLuaConfig` with pcall + rebuild
- **Removing a plugin?** -> Remove from `plugins` + remove setup code + update theme/lualine refs + rebuild
- **Changing default theme?** -> Ensure plugin in list + update `colorscheme` command + lualine uses `'auto'` + rebuild
- **Configuring plugin behavior?** -> Find `.setup()` in `extraLuaConfig` + pass config table + check plugin docs

## Common Mistakes

### Mistake 1: Forgetting to Rebuild

```bash
# Just editing flake.nix — nvim still has old config
# Edit AND rebuild:
darwin-rebuild switch --flake .#<hostname>
```

### Mistake 2: Plugin Name Mismatch

```nix
# Nix package name: nvim-tree-lua
# Lua require name: require('nvim-tree')  -- NOT require('nvim-tree-lua')
```

Check plugin documentation for correct require name.

### Mistake 3: Missing Error Protection

```lua
-- Crashes if plugin not installed
local telescope = require('telescope')

-- Protected call
local telescope_ok, telescope = pcall(require, 'telescope')
if telescope_ok then telescope.setup{} end
```

### Mistake 4: Not Refreshing Environment After Rebuild

```bash
# After darwin-rebuild, refresh shell:
exec zsh                    # Restart shell
# OR close and reopen terminal

# Verify correct nvim:
which nvim
# Expected: /etc/profiles/per-user/$USER/bin/nvim
```

### Mistake 5: Direnv/Nix-Shell Caching Issues

After removing neovim from devShell `buildInputs`, clear direnv cache:
```bash
rm -rf .direnv && direnv allow
```

## Violation Detection

```bash
# Minimal nvim-tree.setup() calls (missing explicit settings)
grep -A 2 "nvim_tree.setup" flake.nix | grep -v "view\|actions"

# Theme inconsistencies
grep "colorscheme\|theme.*=" flake.nix

# Unprotected plugin calls (require without pcall)
grep -n "= require(" flake.nix

# Duplicate neovim installations
awk '/home.packages|buildInputs/,/];/' flake.nix | grep -n "neovim"

# Verify correct binary and plugin loading
which nvim  # Should be /etc/profiles/per-user/$USER/bin/nvim
nvim --headless +"colorscheme tokyonight" +"echo 'Success'" +quit 2>&1
```
