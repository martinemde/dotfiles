import { basename } from 'node:path';
import type {
  ExtensionAPI,
  ExtensionContext,
} from '@earendil-works/pi-coding-agent';

// Same frames and 80 ms cadence as Pi's default Loader.
const SPINNER_FRAMES = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];

// Context is percent used, matching Pi's footer. Unknown usage stays unknown.
export default function (pi: ExtensionAPI) {
  let active = false;
  let working = false;
  let compacting = false;
  let waiting = false;
  let attention = false;
  let frame = 0;
  let suffix = '';
  let context: ExtensionContext | undefined;
  let timer: ReturnType<typeof setInterval> | undefined;
  let intervalMs = 0;

  function stopTimer() {
    clearInterval(timer);
    timer = undefined;
    intervalMs = 0;
  }

  function syncTimer() {
    const nextInterval = !waiting && (working || compacting) ? 80 : 500;
    if (timer && intervalMs === nextInterval) return;
    stopTimer();
    intervalMs = nextInterval;
    // Also reassert the title after Pi's asynchronous startup/reload writes.
    timer = setInterval(() => {
      if (waiting) attention = !attention;
      else if (working || compacting)
        frame = (frame + 1) % SPINNER_FRAMES.length;
      render();
    }, intervalMs);
    timer.unref();
  }

  function render() {
    if (!active || context?.mode !== 'tui') return;
    const state = waiting
      ? attention
        ? '[!]'
        : '[.]'
      : working || compacting
        ? `── ${SPINNER_FRAMES[frame]} Working`
        : 'ready';
    context.ui.setTitle(`π ${state} | ${suffix}`);
  }

  function refresh(ctx: ExtensionContext) {
    if (!active || ctx.mode !== 'tui') return;
    context = ctx;
    const percent = ctx.getContextUsage()?.percent;
    const usage = percent == null ? '?%' : `${Math.round(percent)}%`;
    const model = ctx.model?.id ?? 'no model';
    const effort = ctx.model?.reasoning ? ` ${pi.getThinkingLevel()}` : '';
    const name = pi.getSessionName() || basename(ctx.cwd);
    // Titles are OSC sequences: never let session names inject terminal controls.
    suffix = `${usage} | ${model}${effort} | ${name}`.replace(
      /[\x00-\x1f\x7f-\x9f]/g,
      ' '
    );
    render();
    syncTimer();
  }

  pi.on('session_start', (_event, ctx) => {
    stopTimer();
    active = ctx.mode === 'tui';
    working = !ctx.isIdle();
    compacting = false;
    waiting = false;
    frame = 0;
    if (!active) return;
    refresh(ctx);
  });

  pi.on('agent_start', (_event, ctx) => {
    working = true;
    frame = 0;
    refresh(ctx);
  });
  // agent_end can be followed by retries, compaction, or queued work.
  pi.on('agent_settled', (_event, ctx) => {
    working = false;
    refresh(ctx);
  });

  pi.on('ui_prompt_start', (_event, ctx) => {
    if (!active || ctx.mode !== 'tui') return;
    waiting = true;
    attention = false;
    refresh(ctx);
  });
  pi.on('ui_prompt_end', (_event, ctx) => {
    waiting = false;
    refresh(ctx);
  });

  pi.on('session_before_compact', (_event, ctx) => {
    compacting = true;
    frame = 0;
    refresh(ctx);
  });
  function afterCompaction(_event: unknown, ctx: ExtensionContext) {
    compacting = false;
    refresh(ctx);
  }
  pi.on('session_compact', afterCompaction);
  pi.on('session_compact_failed', afterCompaction);
  pi.on('turn_end', (_event, ctx) => refresh(ctx));
  pi.on('model_select', (_event, ctx) => refresh(ctx));
  pi.on('thinking_level_select', (_event, ctx) => refresh(ctx));
  pi.on('session_tree', (_event, ctx) => refresh(ctx));
  pi.on('session_info_changed', (_event, ctx) => refresh(ctx));

  pi.on('session_shutdown', () => {
    active = false;
    stopTimer();
    context = undefined;
  });
}
