# Coder workspace proof of concept

Use the `coder` layout. In the tab bar's + menu, choose **Coder workspace…**.
Choose a workspace (or press its number). Stopped workspaces are started.
Herdr Core is installed on first connection. One space is reused per Coder
machine; new tabs and splits stay on that workspace.

This mod runs your authenticated local `coder`, `hc`, and `herdr-app` CLIs.
It lists existing workspaces only. It does not create, stop, or delete them.
Closing a space leaves its Coder workspace running under Coder's own policy.
The picker must stay open while connecting. Errors remain in the picker.

Files:

- mods/coder-workspaces: picker and connection flow
- mods/coder-new-menu: personal clone with Coder entry
- mods/coder-tabs: personal clone that opens that menu
- layouts/coder.json: personal clone using coder-tabs

Return to the unmodified layout with:
`herdr-app do layout.switch --name main`
Open the picker directly with:
`herdr-app do mod.open --name coder-workspaces`

Prototype constants: machine names `coder-<workspace name>`, 10-minute start/install
budget, 60-second remote-layout wait. Uses WORKSPACE_WORKDIR, else remote HOME.
Existing manually registered `coder-emerald-fox` uses its SSH alias; newly
registered machines use `coder ssh` directly, with no SSH-config edits.

No Coder credentials are copied into mod files. Coder's existing local login is used.
