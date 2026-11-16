# Zellij-style keys

Based on `~/.config/zellij/config.kdl`. Existing Herdr Cmd shortcuts remain.
`Ctrl+Space` opens this mod; it does not run Zellij inside Herdr.

## Keys

After `Ctrl+Space`:

- `p`: pane mode. `h/j/k/l` or arrows focus; `Tab` cycles panes;
  `d` splits down, `r` or `n` splits right, `x` closes, `z` zooms.
- `t`: tab mode. `h/k` or left/up goes back; `j/l` or down/right goes
  forward; `1–9` selects, `n` creates, `r` renames, `x` closes.
- `m`: move mode. `h/j/k/l` or arrows swap with a neighbor;
  `n` or `Tab` swaps with the next pane, `p` with the previous pane.
- `s`: scroll mode. `j/k` or down/up scroll a line; `h/l` or left/right
  scroll a page. PageUp/PageDown and Ctrl+b/f also page.
  `u/d` scroll half a page. `f` opens Herdr's native find bar.
  `Ctrl+c` returns to the live screen and exits.
  Alt+arrows or Alt+h/j/k/l focus a pane and exit.
- `r`: explains that keyboard pane resizing is unavailable; drag a divider.
- `o`: session substitutes. `c` opens settings, `w` opens the spaces picker,
  `d` closes the window without killing terminals.
- `n`: create a pane, splitting right.

Navigation and scrolling stay in their mode. Create/close/zoom/select/search
and rename actions return to the terminal or open Herdr's native UI.
Escape or Enter exits any mode. The mode's own letter also exits
(`p` in pane mode, `t` in tab mode, etc.). Zellij's shared mode-switch keys
are retained where they do not conflict with an action.

Outside the menu:

- Ctrl+h/j/k/l or Ctrl+arrows: focus left/down/up/right.
- Ctrl+i: move the current tab left, wrapping.

These take Ctrl+Space, Ctrl+h/j/k/l, Ctrl+arrows and Ctrl+i away from terminal programs,
matching the corresponding requested Zellij shortcuts. Physical Tab remains
separate in Herdr. Existing Cmd shortcuts and other terminal keys are unchanged.

## Differences and assumptions

- Herdr requires a split direction: undirected `n` always splits **right**.
- Move means **swap**, not Zellij's full pane relocation behavior.
- Pane cycling uses Herdr's pane list order, not Zellij's focus history.
- Ctrl+left/right and scroll-mode Alt+left/right do **not** cross tab edges.
- Ctrl+h/j/k/l focus panes directly, including while a menu mode is open.
  They override shell/Vim uses of these keys (backspace, newline, kill-line,
  clear-screen). Zellij's process-aware normal/locked autolock is not reproduced.
- Find uses Herdr's own bar: Enter/Shift+Enter navigate matches, Escape closes.
  Zellij's separate search-mode keys are not reproduced.
- Spaces are only a session substitute. No session-ending Quit key is installed.
- Unsupported keys are left unbound in the menu, not repurposed: pane resizing,
  pane rename, last-pane/last-tab toggles, floating/stacked panes, pane frames,
  floating pins, tab synchronization, break-pane, groups, swap layouts,
  prompt jumps, last-command-output copy, scrollback editing, and sharing.
  Scrollback does not exist on alternate screens such as Vim.

## Files and recovery

- Bindings: `~/.config/herdr-app/keys.json`
- Mod: `~/.config/herdr-app/mods/zellij-keys/`
- Chezmoi source: `home/dot_config/herdr-app/`

Edit the chezmoi source and apply it to sync changes. To remove the mod,
remove its keybindings and folder from the source, then apply. A pre-install
keys backup may exist locally as `keys.json.before-zellij`; it is not synced.
No shipped layout or mod was edited. No Zellij files were changed.
This mod uses only local Herdr commands; it runs no helpers and uses no network.

## Validation

`herdr-app check ~/.config/herdr-app/mods/zellij-keys` passes.
Live keyboard tests in a disposable space covered prefix opening, right/down
splits, repeated pane focus and cycle, tab creation/navigation/selection/rename,
pane swapping, half-page scroll, native find input, Ctrl+arrow navigation,
Ctrl+i tab movement, and pane close. Screenshots confirmed the menu and find bar.
