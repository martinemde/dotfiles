import { View, div } from 'gpui-kit';
import {
  checking,
  closeOverlay,
  focused,
  nextCommand,
  panes,
  props,
  run,
  spaces,
} from 'herdr';

function enterAdjacentTab({ space, tab }, direction) {
  const tabs = spaces().find((s) => s.id === space)?.tabs;
  if (!tabs) return;
  const goingLeft = direction === 'left';
  if (goingLeft) tabs.reverse();
  const index = tabs.findIndex((t) => t.id === tab);
  if (index < 0) return;
  const target = [...tabs.slice(index + 1), ...tabs.slice(0, index)].find(
    (t) => !t.settled
  );
  if (!target) return;

  // Herdr walks split children left-to-right or top-to-bottom. The first
  // pane touches the left edge, and the last pane touches the right edge.
  const destination = panes().filter((p) => p.tab === target.id);
  const edge = goingLeft ? destination.at(-1) : destination[0];
  // Focusing by pane ID also selects its tab, without showing remembered focus first.
  if (edge) run('pane.focus', { pane: edge.pane });
}

export default class PaneNavigation extends View {
  init(_, cx) {
    if (checking()) return;
    const { overlay, direction } = props();
    const before = focused();
    run('pane.go', { direction });
    cx.spawn(async () => {
      // run() queues commands; send ourselves a marker after pane.go instead of guessing a delay.
      const moved = nextCommand();
      run(`pane-nav-${direction}.after-go`);
      await moved;
      const after = focused();
      if (
        before?.pane &&
        before.pane === after?.pane &&
        before.tab === after.tab
      ) {
        enterAdjacentTab(after, direction);
      }
      closeOverlay(overlay);
    });
  }

  render() {
    return div();
  }
}
