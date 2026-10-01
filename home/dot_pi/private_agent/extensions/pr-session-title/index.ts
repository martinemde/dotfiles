// The unmodified MIT-licensed upstream and LICENSE are pinned by Chezmoi externals.
import { AsyncLocalStorage } from 'node:async_hooks';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import type {
  ExtensionAPI,
  ExtensionContext,
} from '@earendil-works/pi-coding-agent';
import upstream, { findPrRef, type PrRef } from './upstream.ts';

const run = promisify(execFile);

type NamingRequest = {
  ctx: ExtensionContext;
  sessionId: string;
  existingName: string | undefined;
  ref: PrRef | undefined;
};
type PromptEvent = { text?: string; prompt?: string };
type PromptHandler = (event: PromptEvent, ctx: ExtensionContext) => unknown;

function shortSubject(subject: string): string {
  return subject
    .replace(/[\x00-\x1f\x7f-\x9f]/g, ' ')
    .replace(/^([a-z]+)(?:\([^)]*\))?!?:\s*/i, '$1 ')
    .trim()
    .split(/\s+/)
    .slice(0, 5)
    .join(' ')
    .replace(/[.,;:!?…]+$/, '')
    .toLowerCase();
}

async function repoName(cwd: string): Promise<string | undefined> {
  try {
    const { stdout } = await run(
      process.env.PR_SESSION_TITLE_GH ?? 'gh',
      ['repo', 'view', '--json', 'name', '--jq', '.name'],
      { cwd, timeout: 8_000, maxBuffer: 1 << 20 }
    );
    const name = stdout.trim();
    return /^[A-Za-z0-9._-]+$/.test(name) ? name : undefined;
  } catch {
    return undefined;
  }
}

export default function (pi: ExtensionAPI) {
  const requests = new AsyncLocalStorage<NamingRequest>();

  upstream({
    ...pi,
    // Bind the formatter to its prompt even when upstream defers or awaits a lookup.
    on: ((event: string, handler: PromptHandler) =>
      Reflect.apply(pi.on, pi, [
        event,
        (event: PromptEvent, ctx: ExtensionContext) =>
          requests.run(
            {
              ctx,
              sessionId: ctx.sessionManager.getSessionId(),
              existingName: pi.getSessionName(),
              ref: findPrRef(event.text ?? event.prompt ?? ''),
            },
            () => handler(event, ctx)
          ),
      ])) as ExtensionAPI['on'],
    async setSessionName(name) {
      const request = requests.getStore();
      const match = /^PR(?: review)? (\d+): ([\s\S]+)$/.exec(name);
      if (!request || !match) return;

      const stillCurrent = () =>
        request.ctx.sessionManager.getSessionId() === request.sessionId &&
        pi.getSessionName() === request.existingName;
      if (!stillCurrent()) return;

      // A URL supplies the repository; numeric references use GitHub's actual name,
      // not the cwd basename (which could just be a worktree called "default").
      const repo =
        request.ref?.repo?.split('/').pop() ??
        (await repoName(request.ctx.cwd));
      if (!repo || !stillCurrent()) return;
      pi.setSessionName(`${repo}#${match[1]} — ${shortSubject(match[2])}`);
    },
  });
}
