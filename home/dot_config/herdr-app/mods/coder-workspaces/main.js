import { View, div } from 'gpui-kit';
import { v_flex, h_flex } from 'gpui-base';
import {
  exec,
  machines,
  spaces,
  run,
  theme,
  props,
  closeOverlay,
  checking,
  nextCommand,
} from 'herdr';

async function checked(command, args, options) {
  const result = await exec(command, args, options);
  if (result.code !== 0)
    throw new Error(
      (
        result.stderr ||
        result.stdout ||
        `${command} exited ${result.code}`
      ).trim()
    );
  return result.stdout;
}

export default class CoderWorkspaces extends View {
  init(_props, cx) {
    this.items = [];
    this.loading = true;
    this.busy = false;
    this.message = 'Loading workspaces…';
    this.error = null;
    this.pending = null;
    this.handle = cx.focus_handle();
    this.handle.focus();
    if (checking()) return;
    this.refresh(cx);
    cx.timer.every(1000, (cx) => this.finishWhenReady(cx));
    cx.spawn(async (cx) => {
      for (;;) {
        const command = await nextCommand();
        const item = this.items.find((w) => w.name === command);
        if (item) this.open(item, cx);
      }
    });
  }

  refresh(cx) {
    if (this.busy) return;
    this.loading = true;
    this.error = null;
    cx.spawn(async (cx) => {
      try {
        const output = await checked('coder', [
          'list',
          '--search',
          'user:me',
          '--output',
          'json',
        ]);
        this.items = JSON.parse(output).map((w) => ({
          name: w.name,
          owner: w.owner_name,
          template: w.template_name,
          status: w.latest_build.status,
          healthy: w.health.healthy,
          machine: `coder-${w.name}`,
        }));
        this.message = this.items.length ? '' : 'No existing Coder workspaces.';
      } catch (e) {
        this.error = String(e);
      }
      this.loading = false;
      cx.notify();
    });
  }

  open(workspace, cx) {
    if (this.busy || this.loading) return;
    this.busy = true;
    this.error = null;
    this.message = `Connecting to ${workspace.name}…`;
    cx.notify();
    cx.spawn(async (cx) => {
      try {
        // Refresh state before deciding whether this needs a start.
        const current = JSON.parse(
          await checked('coder', [
            'list',
            '--search',
            'user:me',
            '--output',
            'json',
          ])
        ).find(
          (w) => w.name === workspace.name && w.owner_name === workspace.owner
        );
        if (!current)
          throw new Error('Workspace no longer exists. Refresh the list.');
        if (current.latest_build.status === 'stopped') {
          this.message = `Starting ${workspace.name}…`;
          cx.notify();
          await checked(
            'coder',
            ['start', `${workspace.owner}/${workspace.name}`, '--yes'],
            { timeout: 600000 }
          );
        } else if (current.latest_build.status !== 'running') {
          throw new Error(
            `Workspace is ${current.latest_build.status}. Wait for its build or resolve it in Coder, then retry.`
          );
        }
        this.message = `Connecting and installing Herdr Core if needed…`;
        cx.notify();
        const configured = JSON.parse(
          await checked('hc', ['machine', 'ls', '--json'])
        ).machines;
        const via = `coder ssh --disable-autostart --wait=no ${workspace.owner}/${workspace.name}`;
        const existingMachine = configured.find(
          (m) => m.name === workspace.machine
        );
        if (
          existingMachine &&
          !(existingMachine.via
            ? existingMachine.target === via
            : existingMachine.target === `coder.${workspace.name}`)
        ) {
          throw new Error(
            `Machine ${workspace.machine} already points elsewhere. Choose another machine name before connecting.`
          );
        }
        if (!existingMachine) {
          // Coder executes the appended remote command without allocating a PTY.
          await checked(
            'hc',
            [
              'machine',
              'add',
              '--name',
              workspace.machine,
              '--via',
              via,
              '--install',
              '--json',
            ],
            { timeout: 600000 }
          );
        }
        const folder = (
          await checked('hc', [
            'exec',
            '--on',
            workspace.machine,
            '--',
            'sh',
            '-c',
            'printf "%s" "${WORKSPACE_WORKDIR:-$HOME}"',
          ])
        ).trim();
        this.message = 'Waiting for the remote layout…';
        this.pending = { workspace, folder, since: Date.now() };
        this.finishWhenReady(cx);
      } catch (e) {
        this.busy = false;
        this.error = String(e);
        this.message = '';
      }
      cx.notify();
    });
  }

  finishWhenReady(cx) {
    const pending = this.pending;
    if (!pending) return;
    const { workspace, folder } = pending;
    if (
      machines().find((m) => m.name === workspace.machine)?.layout !== 'ready'
    ) {
      if (Date.now() - pending.since > 60000) {
        this.pending = null;
        this.busy = false;
        this.error =
          'Herdr could not load the remote layout. Check the machine connection and retry.';
        this.message = '';
        cx.notify();
      }
      return;
    }
    this.pending = null;
    const existing = spaces().find((s) => s.machine === workspace.machine);
    // Read the command result before closing, so launch failures stay visible.
    cx.spawn(async (cx) => {
      try {
        const command = existing ? 'space.select' : 'space.new';
        const args = existing
          ? { id: existing.id }
          : {
              machine: workspace.machine,
              name: workspace.name,
              folder,
              tab: 'Terminal',
            };
        await checked('herdr-app', ['do', command, JSON.stringify(args)]);
        closeOverlay(props().overlay);
      } catch (e) {
        this.busy = false;
        this.error = String(e);
        this.message = '';
        cx.notify();
      }
    });
  }

  render() {
    const t = theme();
    return v_flex()
      .id('coder-workspaces')
      .w_full()
      .h(360)
      .p(14)
      .gap(10)
      .bg(t.popover)
      .text_color(t.foreground)
      .text_size(13)
      .track_focus(this.handle)
      .on_key_down((e, cx) => {
        const index = Number(e.key) - 1;
        if (/^[1-9]$/.test(e.key) && this.items[index])
          this.open(this.items[index], cx);
      })
      .child(
        h_flex()
          .items_center()
          .justify_between()
          .child(div().font_semibold().child('Coder workspace'))
          .child(
            div()
              .id('refresh')
              .px(8)
              .py(4)
              .rounded(5)
              .hover((s) => s.bg(t.hover))
              .on_click((_e, cx) => this.refresh(cx))
              .child('Refresh')
          )
      )
      .child(
        v_flex()
          .flex_1()
          .min_h(0)
          .gap(5)
          .overflow_y_scrollbar()
          .children(
            this.items.map((w, i) =>
              h_flex()
                .id(w.name)
                .p(10)
                .gap(10)
                .rounded(6)
                .bg(t.surface)
                .when(!this.busy, (el) => el.hover((s) => s.bg(t.selected)))
                .on_click((_e, cx) => this.open(w, cx))
                .child(
                  div()
                    .text_color(t.dim)
                    .child(String(i + 1))
                )
                .child(
                  v_flex()
                    .flex_1()
                    .gap(3)
                    .child(div().child(w.name))
                    .child(
                      div()
                        .text_size(11)
                        .text_color(t.muted)
                        .child(
                          `${w.template} · ${w.status}${w.healthy ? '' : ' · startup error'}`
                        )
                    )
                )
                .child(
                  div()
                    .text_color(t.muted)
                    .child(w.status === 'stopped' ? 'Start & open' : 'Open')
                )
            )
          )
      )
      .when(Boolean(this.message), (el) =>
        el.child(div().text_color(t.muted).child(this.message))
      )
      .when(Boolean(this.error), (el) =>
        el.child(div().text_color(t.blocked).child(this.error))
      )
      .child(
        div()
          .text_size(11)
          .text_color(t.dim)
          .child(
            'One space per workspace. Tabs share it. Closing a space leaves the workspace intact.'
          )
      );
  }
}
