import { View, div } from 'gpui-kit';
import { v_flex, h_flex } from 'gpui-base';
import { run, props, closeOverlay, theme, focused, panes } from 'herdr';

// [label, command, arguments, stay in mode]
const ACTIONS = {
  prefix: {
    n: ['New pane (right)', 'pane.split', { direction: 'right' }],
  },
  pane: {
    d: ['Split down', 'pane.split', { direction: 'down' }],
    r: ['Split right', 'pane.split', { direction: 'right' }],
    n: ['New pane (right)', 'pane.split', { direction: 'right' }],
    x: ['Close pane', 'pane.close'],
    z: ['Zoom pane', 'pane.zoom'],
    tab: ['Next pane', 'cycle-pane', { by: 1 }, true],
  },
  tab: {
    n: ['New tab', 'tab.new'],
    r: ['Rename tab', 'tab.rename'],
    x: ['Close tab', 'tab.close'],
  },
  move: {
    n: ['Swap with next pane', 'cycle-swap', { by: 1 }, true],
    p: ['Swap with previous pane', 'cycle-swap', { by: -1 }, true],
    tab: ['Swap with next pane', 'cycle-swap', { by: 1 }, true],
  },
  scroll: {
    f: ['Find in terminal', 'terminal.search'],
    'ctrl-c': ['Return to live screen', 'terminal.scroll', { to: 'bottom' }],
  },
  resize: {},
  session: {
    c: ['Settings', 'app.settings'],
    w: ['Spaces picker', 'mod.open', { name: 'picker' }],
    d: ['Close window; keep terminals running', 'window.close'],
  },
};
const MODES = {
  p: 'pane',
  t: 'tab',
  m: 'move',
  s: 'scroll',
  r: 'resize',
  o: 'session',
};
const EXIT = {
  pane: 'p',
  tab: 't',
  move: 'm',
  scroll: 's',
  resize: 'r',
  session: 'o',
};
const NOTES = {
  prefix: 'n splits right; Herdr has no automatic split direction.',
  pane: 'Floating, stacked, pinned panes, pane names and frame toggles have no matching command.',
  tab: 'Break-pane, tab sync and last-tab toggle are not exposed by Herdr.',
  move: 'Moves swap panes. Next/previous follows Herdr’s pane order.',
  scroll:
    'Search uses Herdr’s find bar. Prompt jumps, command-output copy and scrollback editing are not exposed.',
  resize:
    'Herdr has no terminal-pane resize command. Drag a split divider instead.',
  session:
    'Spaces are the closest match to sessions. Closing the window keeps terminals running.',
};
const DIRECTIONS = {
  h: 'left',
  j: 'down',
  k: 'up',
  l: 'right',
  left: 'left',
  down: 'down',
  up: 'up',
  right: 'right',
};
for (const [key, direction] of Object.entries(DIRECTIONS)) {
  ACTIONS.pane[key] = [`Focus ${direction}`, 'pane.go', { direction }, true];
  ACTIONS.move[key] = [`Swap ${direction}`, 'pane.swap', { direction }, true];
  ACTIONS.tab[key] = [
    direction === 'left' || direction === 'up' ? 'Previous tab' : 'Next tab',
    direction === 'left' || direction === 'up' ? 'tab.prev' : 'tab.next',
    {},
    true,
  ];
  const args =
    direction === 'left'
      ? { pages: -1 }
      : direction === 'right'
        ? { pages: 1 }
        : { lines: direction === 'up' ? -1 : 1 };
  ACTIONS.scroll[key] = [`Scroll ${direction}`, 'terminal.scroll', args, true];
}
for (let index = 1; index <= 9; index++)
  ACTIONS.tab[String(index)] = [`Tab ${index}`, 'tab.select', { index }];
for (const [key, pages] of Object.entries({
  pageup: -1,
  pagedown: 1,
  'ctrl-b': -1,
  'ctrl-f': 1,
  u: -0.5,
  d: 0.5,
})) {
  ACTIONS.scroll[key] = [
    pages < 0 ? 'Scroll up' : 'Scroll down',
    'terminal.scroll',
    { pages },
    true,
  ];
}

export default class ZellijKeys extends View {
  init(_props, cx) {
    this.mode = 'prefix';
    this.handle = cx.focus_handle();
    this.handle.focus();
  }

  close() {
    closeOverlay(props().overlay);
  }

  act(action) {
    const [, command, args = {}, stay] = action;
    if (!stay) this.close();
    if (command === 'cycle-pane' || command === 'cycle-swap') {
      const f = focused();
      const list = panes().filter((p) => p.tab === f?.tab);
      const at = list.findIndex((p) => p.pane === f?.pane);
      if (at >= 0 && list.length > 1) {
        const target = list[(at + args.by + list.length) % list.length].pane;
        run(
          command === 'cycle-pane' ? 'pane.focus' : 'pane.swap',
          command === 'cycle-pane' ? { pane: target } : { target }
        );
      }
    } else run(command, args);
    if (stay) this.handle.focus();
  }

  key(e, cx) {
    if (e.modifiers.platform) return;
    cx.stop_propagation();
    const key = e.keystroke;
    if (
      key === 'escape' ||
      key === 'enter' ||
      key === 'ctrl-space' ||
      key === EXIT[this.mode]
    )
      return this.close();
    const action = ACTIONS[this.mode][key];
    if (action) {
      this.act(action);
      cx.notify();
      return;
    }
    if (this.mode === 'scroll' && e.modifiers.alt && DIRECTIONS[e.key]) {
      this.close();
      run('pane.go', { direction: DIRECTIONS[e.key] });
      return;
    }
    if (e.modifiers.control && DIRECTIONS[e.key]) {
      const direction = DIRECTIONS[e.key];
      if (e.key.length === 1) {
        run('mod.open', { name: `pane-nav-${direction}` });
      } else {
        run('pane.go', { direction });
      }
      this.handle.focus();
      return;
    }
    // Only switch modes where the Zellij shared bindings do not override an action.
    const target = MODES[key];
    const shared =
      key === 't' ||
      key === 'm' ||
      key === 'o' ||
      (key === 'r' && !['pane', 'tab'].includes(this.mode)) ||
      (key === 'p' && ['resize', 'tab', 'scroll'].includes(this.mode)) ||
      (key === 's' && ['resize', 'move'].includes(this.mode));
    if (target && (this.mode === 'prefix' || shared)) {
      this.mode = target;
      cx.notify();
    }
  }

  render(cx) {
    const t = theme();
    const rows =
      this.mode === 'prefix'
        ? [
            ['p', 'Panes'],
            ['t', 'Tabs'],
            ['m', 'Move panes'],
            ['s', 'Scroll / search'],
            ['r', 'Resize (not available)'],
            ['o', 'Sessions / spaces'],
            ['n', 'New pane (right)'],
          ]
        : this.mode === 'pane'
          ? [
              ['h j k l / arrows', 'Focus pane'],
              ['tab', 'Next pane'],
              ['d', 'Split down'],
              ['r / n', 'Split right'],
              ['x', 'Close pane'],
              ['z', 'Zoom pane'],
            ]
          : this.mode === 'tab'
            ? [
                ['h k / ← ↑', 'Previous tab'],
                ['j l / ↓ →', 'Next tab'],
                ['1–9', 'Select tab'],
                ['n', 'New tab'],
                ['r', 'Rename tab'],
                ['x', 'Close tab'],
              ]
            : this.mode === 'move'
              ? [
                  ['h j k l / arrows', 'Swap in direction'],
                  ['n / tab', 'Swap with next pane'],
                  ['p', 'Swap with previous pane'],
                ]
              : this.mode === 'scroll'
                ? [
                    ['j k / ↓ ↑', 'Scroll one line'],
                    ['h l / ← →', 'Scroll one page'],
                    ['PageUp / Ctrl+b', 'Page up'],
                    ['PageDown / Ctrl+f', 'Page down'],
                    ['u / d', 'Half page up / down'],
                    ['f', 'Find in terminal'],
                    ['Ctrl+c', 'Return to live screen'],
                  ]
                : Object.entries(ACTIONS[this.mode]).map(([key, action]) => [
                    key,
                    action[0],
                  ]);
    return v_flex()
      .id('zellij-keys')
      .track_focus(this.handle)
      .on_key_down((e, cx) => this.key(e, cx))
      .w_full()
      .p(16)
      .gap(9)
      .bg(t.popover)
      .text_color(t.foreground)
      .text_size(13)
      .child(
        h_flex()
          .justify_between()
          .items_center()
          .child(
            div()
              .font_semibold()
              .child(
                this.mode === 'prefix'
                  ? 'Ctrl+Space'
                  : `${this.mode[0].toUpperCase()}${this.mode.slice(1)} mode`
              )
          )
          .child(
            div()
              .text_color(t.dim)
              .text_size(11)
              .child('Esc / Enter → terminal')
          )
      )
      .children(
        rows.map(([key, label], i) =>
          h_flex()
            .id(`key-${i}`)
            .gap(12)
            .py(3)
            .child(div().w(180).text_color(t.accent).child(key))
            .child(div().flex_1().child(label))
        )
      )
      .child(
        div().pt(8).text_size(11).text_color(t.muted).child(NOTES[this.mode])
      );
  }
}
