# Neovim Configuration

This dotfiles repository includes a complete Neovim configuration based on [LazyVim](https://lazyvim.org/), a modern Neovim configuration framework built on top of [lazy.nvim](https://github.com/folke/lazy.nvim).

## Overview

- **Base Framework**: LazyVim - provides sensible defaults and plugin management
- **Plugin Manager**: lazy.nvim - fast and modern plugin manager
- **Configuration Location**: `home/dot_config/nvim/`
- **Colorscheme**: Catppuccin
- **Picker**: fzf-lua (replaces telescope for faster fuzzy finding)
- **Features**: LSP, treesitter, completion, which-key, and more out of the box

## Philosophy

This configuration prioritizes **LazyVim defaults** with minimal customization. The goal is to leverage LazyVim's well-tested configuration while adding only essential tweaks. Most functionality comes from LazyVim itself - see the [LazyVim documentation](https://lazyvim.org/) for available features and keybindings.

## Directory Structure

```
home/dot_config/nvim/
├── init.lua                    # Main entry point - bootstraps lazy.nvim
├── lua/
│   ├── config/
│   │   ├── autocmds.lua       # Custom autocommands
│   │   ├── keymaps.lua        # Custom key mappings
│   │   ├── lazy.lua           # Lazy.nvim bootstrap and configuration
│   │   └── options.lua        # Neovim options and settings
│   └── plugins/
│       ├── autopairs.lua      # Auto-close brackets, quotes, etc.
│       ├── catppuccin.lua     # Catppuccin colorscheme with LazyVim integrations
│       ├── completion.lua     # Completion settings (disabled in markdown)
│       ├── example.lua        # Example plugin spec (mostly commented out)
│       ├── fzf.lua            # fzf-lua for faster fuzzy finding
│       ├── neo-tree.lua       # File explorer customization
│       └── tmux-navigator.lua # Tmux integration for seamless pane navigation
```

## Key Features

### LazyVim Integration

- Automatic plugin management and updates
- Sensible defaults for modern development
- Built-in LSP support with mason.nvim
- Treesitter syntax highlighting
- Telescope fuzzy finding
- Which-key for discoverable keybindings

### Custom Plugins & Overrides

#### Catppuccin Colorscheme
**Plugin**: `catppuccin/nvim`
**Location**: `lua/plugins/catppuccin.lua`

Catppuccin is configured with comprehensive LazyVim integrations for consistent theming across all plugins (bufferline, telescope, neo-tree, lsp, etc.).

#### fzf-lua Picker
**Plugin**: `ibhagwan/fzf-lua`
**Location**: `lua/plugins/fzf.lua`

Replaces the default Telescope picker with fzf-lua for faster fuzzy finding. LazyVim automatically detects and uses this as the picker.

#### Completion Configuration
**Location**: `lua/plugins/completion.lua`

Disables auto-completion in markdown files for better writing experience. Supports both blink.cmp (LazyVim default) and nvim-cmp.

#### Auto Pairs
**Location**: `lua/plugins/autopairs.lua`

Automatically closes brackets, quotes, parentheses, etc.

#### Tmux Navigator
**Plugin**: `christoomey/vim-tmux-navigator`
**Location**: `lua/plugins/tmux-navigator.lua`

Seamless navigation between Neovim splits and tmux panes:
- `Ctrl+h` - Move left
- `Ctrl+j` - Move down
- `Ctrl+k` - Move up
- `Ctrl+l` - Move right
- `Ctrl+\` - Move to previous pane/split

#### Neo-tree File Explorer
**Location**: `lua/plugins/neo-tree.lua`

Customizations for LazyVim's file explorer (if any specific overrides are configured).

## Configuration Files

### init.lua

Simple bootstrap that loads the lazy.nvim configuration:

```lua
require("config.lazy")
```

### lua/config/lazy.lua

- Bootstraps lazy.nvim if not installed
- Configures LazyVim with custom settings
- Sets up plugin loading from the `plugins/` directory
- Enables automatic plugin update checking

### lua/config/ Files

- **keymaps.lua**: Add custom keybindings here
- **options.lua**: Override Neovim options
- **autocmds.lua**: Custom autocommands
- All files are automatically loaded by LazyVim

### lua/plugins/ Files

Each `.lua` file in this directory is automatically loaded as a plugin specification. Files should return a table with plugin configuration.

## Adding New Plugins

Create a new file in `lua/plugins/` that returns a plugin spec:

```lua
-- lua/plugins/example.lua
return {
  "plugin/name",
  config = function()
    -- Plugin setup
  end,
  keys = {
    { "<leader>x", "<cmd>PluginCommand<cr>", desc = "Plugin action" },
  },
}
```

## Common Workflows

### Installing/Updating Plugins

- `:Lazy` - Open lazy.nvim interface
- `:Lazy sync` - Install/update all plugins
- `:Lazy clean` - Remove unused plugins

### LSP Management

- `:Mason` - Manage LSP servers, formatters, linters
- `:LspInfo` - Show LSP client information
- `:Lazy extras` - Install additional language support

### Key Discovery

- `<leader>` (space by default) - Opens which-key menu
- `:Telescope keymaps` - Search all keybindings
- `:LazyVim` - Open LazyVim help and configuration

## Customization

### Overriding LazyVim Defaults

Create plugin files that override LazyVim's default configurations:

```lua
-- lua/plugins/overrides.lua
return {
  {
    "LazyVim/LazyVim",
    opts = {
      -- Override LazyVim options
    },
  },
}
```

### Disabling LazyVim Plugins

```lua
return {
  { "plugin/name", enabled = false },
}
```

## Tmux Integration

The configuration includes seamless navigation between Neovim and tmux:

1. **Automatic Detection**: Tmux detects when Neovim is running
2. **Smart Navigation**: `Ctrl+hjkl` navigates within Neovim or between tmux panes
3. **Copy Mode Support**: Navigation works in tmux copy mode
4. **Fallback Bindings**: Prefix-based navigation available as backup

See `doc/tmux.md` for tmux-side configuration details.

## Troubleshooting

### Plugin Issues

- `:Lazy log` - View plugin installation logs
- `:Lazy health` - Check plugin health
- `:checkhealth` - Neovim health check

### LSP Issues

- `:LspLog` - View LSP logs
- `:Mason log` - View Mason installation logs

### Performance

LazyVim is configured for optimal performance with:

- Disabled unused built-in plugins
- Lazy loading for most plugins
- Optimized RTP (runtime path)
