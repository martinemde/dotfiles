"""Real tmux plugin integration; sources must be supplied locally, never fetched."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
import tomllib

ROOT = Path(__file__).resolve().parents[1]
sources = Path(os.environ["TMUX_PLUGIN_SOURCES"]).resolve()
tmux = shutil.which("tmux")
chezmoi = os.environ.get("CHEZMOI_BIN") or shutil.which("chezmoi")
assert tmux and chezmoi, "tmux and chezmoi are required"
with tempfile.TemporaryDirectory(prefix="tmux-plugins-test-") as tmp:
    home = Path(tmp)
    plugins = home / ".config/tmux/plugins"
    plugins.mkdir(parents=True)
    env = {"PATH": os.environ["PATH"], "TERM": "xterm-256color",
           "HOME": str(home), "XDG_CONFIG_HOME": str(home / ".config"),
           "XDG_CACHE_HOME": str(home / ".cache"), "XDG_DATA_HOME": str(home / ".local/share"),
           "XDG_STATE_HOME": str(home / ".local/state"), "MISE_AUTO_INSTALL": "0"}
    rendered = subprocess.run(
        [chezmoi, "--config", "/dev/null", "--config-format", "toml", "--source",
         str(ROOT / "home"), "execute-template"], env=env, text=True,
        input=(ROOT / "home/.chezmoiexternals/tmux.externals.toml.tmpl").read_text(),
        capture_output=True, check=True).stdout
    manifest = tomllib.loads(rendered)
    assert len(manifest) == 2
    for target, external in manifest.items():
        name = Path(target).name
        assert external["url"].startswith(f"https://github.com/tmux-plugins/{name}/archive/")
        assert len(external["url"].split("/")[-1].removesuffix(".tar.gz")) == 40
        shutil.copytree(sources / name, home / target, symlinks=True)
    config = home / "plugins.conf"
    config.write_text((ROOT / "home/dot_config/tmux/plugins.conf").read_text())
    socket = str(home / "socket")

    def t(*args):
        return subprocess.run([tmux, "-S", socket, *args], env=env,
                              text=True, capture_output=True, check=True).stdout.strip()

    try:
        t("-f", "/dev/null", "new-session", "-d", "-s", "test", "-x", "80", "-y", "24", "/bin/sh")
        t("set-option", "-g", "default-shell", "/bin/sh")
        t("set-option", "-g", "status-right", "test-status")
        t("source-file", str(config))
        for action in ("save", "restore"):
            expected = str(plugins / "tmux-resurrect/scripts" / f"{action}.sh")
            assert t("show-option", "-gqv", f"@resurrect-{action}-script-path") == expected
            key = "C-s" if action == "save" else "C-r"
            assert expected in t("list-keys", "-T", "prefix", key)
        assert t("show-option", "-gqv", "@continuum-restore") == "on"
        # Upstream skips autosave with another server; feed a private process list
        # only to its process-discovery call, leaving plugin/runtime code intact.
        bindir = home / "bin"
        bindir.mkdir()
        ps = bindir / "ps"
        real_ps = shutil.which("ps")
        ps.write_text(f'#!/bin/sh\nif [ "$1" = "-u" ]; then exit 0; fi\nexec {real_ps} "$@"\n')
        ps.chmod(0o755)
        t("set-environment", "-g", "PATH", str(bindir) + os.pathsep + env["PATH"])
        t("source-file", str(config))
        status = t("show-option", "-gqv", "status-right")
        assert status.count("continuum_save.sh") == 1, status
        assert status.endswith("test-status"), status
        # Exercise the actual automatic save command without waiting 15 minutes.
        t("new-window", "-t", "test:", "-n", "saved-window", "/bin/sh")
        t("set-option", "-g", "@continuum-save-last-timestamp", "0")
        t("run-shell", str(plugins / "tmux-continuum/scripts/continuum_save.sh"))
        last = home / ".local/share/tmux/resurrect/last"
        deadline = time.monotonic() + 10
        while not last.exists() and time.monotonic() < deadline:
            time.sleep(0.05)
        assert last.exists(), list(home.rglob("*"))
        assert "saved-window" in last.read_text()
        # Manual restore must recreate an absent window, not just return success.
        t("kill-window", "-t", "test:saved-window")
        t("run-shell", str(plugins / "tmux-resurrect/scripts/restore.sh"))
        assert "saved-window" in t("list-windows", "-t", "test", "-F", "#{window_name}")
        t("source-file", str(config))
        assert t("show-option", "-gqv", "status-right").count("continuum_save.sh") == 1
        assert "tpm" not in t("list-keys", "-T", "prefix")
    finally:
        subprocess.run([tmux, "-S", socket, "kill-server"], env=env, capture_output=True)
print("Pinned local plugins: ordered init, bindings, continuum status/save, restore and reload passed")
