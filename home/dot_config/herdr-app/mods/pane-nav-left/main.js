import { View, div } from 'gpui-kit';
import {
  checking,
  closeOverlay,
  focused,
  nextCommand,
  props,
  run,
} from 'herdr';

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
        run(direction === 'left' ? 'tab.prev' : 'tab.next');
      }
      closeOverlay(overlay);
    });
  }

  render() {
    return div();
  }
}
