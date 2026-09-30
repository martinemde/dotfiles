// Offline provider and UI prompts at Pi's external boundaries; no real services.
import { createAssistantMessageEventStream } from '@earendil-works/pi-ai';
import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';

export default function (pi: ExtensionAPI) {
  let askDuringRequest = false;
  // Other extensions may still be loading when the title extension starts.
  pi.on('session_start', async () => {
    await new Promise((resolve) => setTimeout(resolve, 200));
  });
  pi.on('before_agent_start', (event) => {
    askDuringRequest = event.prompt === 'question';
  });
  pi.on('before_provider_request', async (_event, ctx) => {
    if (askDuringRequest) {
      askDuringRequest = false;
      await ctx.ui.confirm('Continue?', 'Sandboxed question');
    }
  });
  pi.registerCommand('title-idle-question', {
    description: 'Open a sandboxed confirmation while idle',
    handler: async (_args, ctx) => {
      await ctx.ui.confirm('Continue?', 'Sandboxed question');
    },
  });

  pi.registerProvider('terminal-title-test', {
    api: 'terminal-title-test-api',
    baseUrl: 'https://never-contact.invalid',
    apiKey: 'sandbox-only',
    models: ['alpha', 'beta'].map((id) => ({
      id,
      name: id,
      reasoning: false,
      input: ['text'],
      contextWindow: 100000,
      maxTokens: 4096,
      cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    })),
    streamSimple(model, _context, options) {
      const stream = createAssistantMessageEventStream();
      void (async () => {
        await options?.onPayload?.({ sandbox: true }, model);
        await options?.onResponse?.({ status: 200, headers: {} }, model);
        await new Promise((resolve) => setTimeout(resolve, 1000));
        const aborted = options?.signal?.aborted;
        const message = {
          role: 'assistant' as const,
          content: [{ type: 'text' as const, text: 'Done.' }],
          api: model.api,
          provider: model.provider,
          model: model.id,
          timestamp: Date.now(),
          stopReason: aborted ? ('aborted' as const) : ('stop' as const),
          usage: {
            input: 40000,
            output: 2000,
            cacheRead: 0,
            cacheWrite: 0,
            totalTokens: 42000,
            cost: {
              input: 0,
              output: 0,
              cacheRead: 0,
              cacheWrite: 0,
              total: 0,
            },
          },
        };
        if (aborted) {
          stream.push({ type: 'error', reason: 'aborted', error: message });
        } else {
          stream.push({ type: 'done', reason: 'stop', message });
        }
        stream.end();
      })();
      return stream;
    },
  });
}
