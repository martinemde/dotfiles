import { basename } from 'node:path';
import type {
  ExtensionAPI,
  ExtensionContext,
} from '@earendil-works/pi-coding-agent';

// Context is percent used, matching Pi's footer. Unknown usage stays unknown.
export default function (pi: ExtensionAPI) {
  let active = false;
  let working = false;
  let compacting = false;
  let waiting = false;
  let attention = false;
  let suffix = '';
  let context: ExtensionContext | undefined;
  let timer: ReturnType<typeof setInterval> | undefined;

  function stopTimer() {
    clearInterval(timer);
    timer = undefined;
  }

  function render() {
    if (!active || context?.mode !== 'tui') return;
    const state = waiting
      ? attention
        ? '[!]'
        : '[.]'
      : working || compacting
        ? 'working'
        : 'ready';
    context.ui.setTitle(`π ${state} | ${suffix}`);
  }

  function refresh(ctx: ExtensionContext) {
    if (!active || ctx.mode !== 'tui') return;
    context = ctx;
    const percent = ctx.getContextUsage()?.percent;
    const usage = percent == null ? '?%' : `${Math.round(percent)}%`;
    const model = ctx.model?.id ?? 'no model';
    const name = pi.getSessionName() || basename(ctx.cwd);
    // Titles are OSC sequences: never let session names inject terminal controls.
    suffix = `${usage} | ${model} | ${name}`.replace(
      /[\x00-\x1f\x7f-\x9f]/g,
      ' '
    );
    render();
  }

  pi.on('session_start', (_event, ctx) => {
    stopTimer();
    active = ctx.mode === 'tui';
    working = !ctx.isIdle();
    compacting = false;
    waiting = false;
    if (!active) return;
    refresh(ctx);
    // Pi reasserts its own title after asynchronous startup/reload. Reassert
    // ours too; only the attention state animates, and usage is event-driven.
    timer = setInterval(() => {
      if (waiting) attention = !attention;
      render();
    }, 500);
    timer.unref();
  });

  pi.on('agent_start', (_event, ctx) => {
    working = true;
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
  pi.on('session_tree', (_event, ctx) => refresh(ctx));
  pi.on('session_info_changed', (_event, ctx) => refresh(ctx));

  pi.on('session_shutdown', () => {
    active = false;
    stopTimer();
    context = undefined;
  });
}
