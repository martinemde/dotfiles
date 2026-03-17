# Tmux Configuration

This dotfiles repository includes a comprehensive tmux configuration based on [gpakosz/.tmux](https://github.com/gpakosz/.tmux) with custom local overrides for enhanced functionality.

## Overview

- **Base Configuration**: gpakosz/.tmux - a feature-rich, modern tmux configuration
- **External Source**: Automatically managed via Chezmoi externals
- **Local Overrides**: `home/dot_tmux.conf.local` for custom settings
- **Auto-updates**: Configuration refreshes every 24 hours
- **Vi Mode**: Enhanced vi-style navigation and copy mode

## Architecture

### External Configuration

The base tmux configuration is managed as a Chezmoi external in `.chezmoiexternal.toml.tmpl`:

```toml
[".tmux"]
type = "git-repo"
url = "https://github.com/gpakosz/.tmux.git"
refreshPeriod = "24h"
```

This automatically:

- Clones the gpakosz/.tmux repository to `~/.tmux/`
- Updates the configuration daily
- Provides a solid foundation with modern tmux features

### Configuration Files

```
~/.tmux.conf              -> ~/.tmux/.tmux.conf (symlink)
~/.tmux.conf.local        -> Custom local overrides
~/.tmux/                  -> External gpakosz configuration
```

The main config (`~/.tmux.conf`) is a symlink managed by Chezmoi that points to the external gpakosz configuration. Local customizations go in `~/.tmux.conf.local`.

## Custom Features

### Vi Mode Navigation

**Location**: `home/dot_tmux.conf.local`

#### Copy Mode

- `setw -g mode-keys vi` - Enables vi-style copy mode
- `v` - Begin selection in copy mode
- `y` - Yank selection and exit copy mode

#### Pane Navigation (Prefix-based)

- `prefix + h/j/k/l` - Navigate between panes
- `prefix + H/J/K/L` - Resize panes (with repeat)

### Seamless Neovim Integration

**Plugin Integration**: Works with `christoomey/vim-tmux-navigator`

#### Smart Navigation

The configuration includes intelligent vim detection:

```bash
is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
    | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?)(diff)?$'"
```

#### Navigation Keybindings

- `Ctrl+h` - Move left (tmux pane or vim split)
- `Ctrl+j` - Move down (tmux pane or vim split)
- `Ctrl+k` - Move up (tmux pane or vim split)
- `Ctrl+l` - Move right (tmux pane or vim split)
- `Ctrl+\` - Move to previous pane/split

These bindings work seamlessly:

- **In Neovim**: Navigate between vim splits
- **Outside Neovim**: Navigate between tmux panes
- **Copy Mode**: Navigate with same keys
- **Fallback**: Prefix-based navigation always available

### Custom Keybindings

**Location**: `home/dot_tmux.conf.local`

#### Claude Code Integration

- `prefix + e` - Open Claude Code in dotfiles directory
  - Overrides the default gpakosz "edit config" binding
  - Opens a new tmux window named "dotfiles"
  - Automatically navigates to the chezmoi working directory
  - Launches Claude Code for AI-assisted dotfiles management

### Version Compatibility

The configuration handles different tmux versions for the `Ctrl+\` binding:

- **tmux < 3.0**: Uses single backslash escape
- **tmux >= 3.0**: Uses double backslash escape

## gpakosz/.tmux Features

The external base configuration provides:

### Visual Enhancements

- Modern status line with system information
- Battery status and system load indicators
- Window and pane numbering
- Custom color schemes

### Productivity Features

- Smart pane splitting
- Window and session management
- Mouse support toggle
- Copy mode improvements

### Built-in Keybindings

- `prefix + e` - ~~Edit local config and reload~~ **Overridden**: Open Claude Code in dotfiles directory
- `prefix + r` - Reload configuration
- `prefix + m` - Toggle mouse mode
- Many more - see gpakosz documentation

## Installation & Management

### Initial Setup

The tmux configuration is installed automatically with the dotfiles:

```bash
# Installs both external config and local overrides
chezmoi apply
```

### Configuration Updates

```bash
# Update external gpakosz configuration
chezmoi update

# Apply local changes
chezmoi apply
```

### Runtime Management

```bash
# Edit local config (opens in $EDITOR and reloads)
prefix + e

# Reload configuration
prefix + r

# View current key bindings
tmux list-keys
```

## Customization

### Adding Custom Settings

Edit `home/dot_tmux.conf.local` in your dotfiles repository:

```bash
# Example: Change prefix key
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Example: Custom status line
set -g status-right "#{?window_bigger,[#{window_width}x#{window_height}],} %H:%M %d-%b-%y"
```

### Plugin Management

The gpakosz configuration supports TPM (Tmux Plugin Manager). Add plugins to your local config:

```bash
# Add to ~/.tmux.conf.local
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'

# Initialize TPM (add to end of config)
run '~/.tmux/plugins/tpm/tpm'
```

### Overriding Base Settings

Any setting in the local config will override the base gpakosz configuration:

```bash
# Override default window numbering
set -g base-index 0
setw -g pane-base-index 0

# Change split keybindings
bind | split-window -h
bind - split-window -v
```

## Integration with Development Workflow

### Neovim Integration

- Seamless navigation between vim splits and tmux panes
- Consistent keybindings across both environments
- Copy mode navigation matches vim movement

### Shell Integration

- Works with any shell (zsh, bash, fish)
- Preserves shell history across sessions
- Smart window/pane naming

### Session Management

```bash
# Create named session
tmux new-session -s development

# Attach to session
tmux attach-session -t development

# List sessions
tmux list-sessions
```

### Stacked panes

Custom stacked pane implementation shrinks non-active panes to 1 line when more than 1 pane in same
column.

## Troubleshooting

### Navigation Issues

- Ensure Neovim has `vim-tmux-navigator` plugin installed
- Check tmux version compatibility for `Ctrl+\` binding
- Verify `ps` command output format on your system

### Configuration Problems

- Use `prefix + r` to reload after changes
- Check syntax with: `tmux -f ~/.tmux.conf.local -T`
- View logs: `tmux show-messages`

### External Update Issues

```bash
# Force refresh external configuration
chezmoi update --force

# Check external status
chezmoi status
```

## Performance Considerations

The configuration is optimized for:

- **Lazy Loading**: Features load on demand
- **Minimal Overhead**: Efficient status line updates
- **Smart Detection**: Vim detection uses minimal resources
- **Caching**: External updates only every 24 hours

## References

- [gpakosz/.tmux](https://github.com/gpakosz/.tmux) - Base configuration
- [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) - Seamless navigation plugin
- [Tmux Manual](http://man.openbsd.org/OpenBSD-current/man1/tmux.1) - Complete tmux documentation
