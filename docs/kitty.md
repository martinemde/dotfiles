# Kitty Configuration Design

## Problem

Create a kitty terminal configuration that mirrors the ghostty setup for cross-terminal compatibility and testing.

## Design Decisions

### Keybinding Translation

**Tmux-style prefix**: Kept `ctrl+s` prefix scheme from ghostty. Kitty supports multi-key sequences with `>` syntax similar to ghostty, allowing direct translation of most bindings.

**Dvorak-friendly unicode**: Unbind physical key codes (`bracket_left`, `bracket_right`) and rebind using unicode characters (`[`, `]`) to ensure bindings work with Dvorak layout.

**Split navigation**: Kitty uses `neighboring_window` and `launch --location` instead of ghostty's `goto_split` and `new_split`. Mapped vim-style `hjkl` navigation to kitty's directional window commands.

### Feature Compromises

**No tab overview**: Ghostty's `toggle_tab_overview` has no direct equivalent. Mapped `ctrl+s>w` to `show_scrollback` as closest alternative for reviewing terminal state.

**No quick terminal**: Kitty lacks ghostty's global `toggle_quick_terminal` feature. Omitted rather than creating partial workaround.

**Inspector/command palette**: Ghostty's inspector maps to kitty's documentation viewer; command palette maps to hints kitten (URL/text selection). Neither is exact equivalent but provides similar utility access.

**Layout toggling**: `toggle_split_zoom` becomes `toggle_layout stack` in kitty - similar focus isolation but different visual behavior.

### Theme Implementation

Split Catppuccin Mocha into separate included file for clarity and potential reuse. Ghostty's `split-divider-color` and `unfocused-split-opacity` translate to kitty's border colors and `inactive_text_alpha`.

## Trade-offs

**Excluded**:

- Quick terminal (no kitty equivalent)
- Tab overview (fundamentally different model)
- Ghostty's hyperlink regex patterns (not yet implemented in ghostty anyway; both support OSC 8)

**Kept**:

- All tmux-style keybindings
- Font configuration with OpenType features
- Shell integration
- Dvorak-friendly bindings

## References

- [Kitty keybinding docs](https://sw.kovidgoyal.net/kitty/conf/#keyboard-shortcuts)
- [Catppuccin kitty theme](https://github.com/catppuccin/kitty)
- Ghostty config: `home/dot_config/ghostty/config*`
