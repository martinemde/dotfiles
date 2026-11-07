"""Exercise actual znap cached eval calls from the rendered tools configuration."""
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
home = Path(sys.argv[1])
zsh = shutil.which("zsh")
chezmoi = subprocess.run(["mise", "which", "chezmoi"], cwd=ROOT,
                         text=True, capture_output=True, check=True).stdout.strip()
assert zsh and chezmoi, "zsh and chezmoi are required"
bin_dir = home / "bin"
bin_dir.mkdir()
tools = ["atuin", "starship", "zoxide", "jj", "thefuck"]
for tool in [*tools, "mise"]:
    stub = bin_dir / tool
    stub.write_text(f"""#!/bin/sh
printf '%s\n' "$*" >> "$HOME/{tool}.calls"
printf '%s\n' 'function initialized_{tool}() {{ print -r -- {tool}-ready; }}'
""")
    stub.chmod(0o755)
env = {"PATH": str(bin_dir) + os.pathsep + os.environ["PATH"], "HOME": str(home),
       "XDG_CACHE_HOME": str(home / "cache"), "XDG_CONFIG_HOME": str(home / "config"),
       "TERM": "xterm-256color"}
rendered = subprocess.run([chezmoi, "--config", "/dev/null", "--config-format", "toml", "--source", str(home), "execute-template",
                           "--override-data", '{"chezmoi":{"os":"linux"}}'],
                          input=(ROOT / "home/dot_config/zsh/tools.zsh.tmpl").read_text(),
                          text=True, capture_output=True, check=True, env=env).stdout
(home / "tools.zsh").write_text(rendered)
script = """source ~/.zsh/znap/zsh-snap/znap.zsh || exit
source ~/tools.zsh
""" + "\n".join(f'[[ $(initialized_{tool}) == {tool}-ready ]] || exit 1' for tool in tools)
for iteration in range(2):
    subprocess.run([zsh, "-dfc", script], env=env, cwd=home, check=True)
    for tool in tools:
        assert len((home / f"{tool}.calls").read_text().splitlines()) == 1, tool
        assert (home / f"cache/zsh-snap/eval/{tool}.zsh").is_file(), tool
# Deleting a cache must regenerate it; all other tools must still use their caches.
(home / "cache/zsh-snap/eval/atuin.zsh").unlink()
(home / "cache/zsh-snap/eval/atuin.zsh.zwc").unlink(missing_ok=True)
subprocess.run([zsh, "-dfc", script], env=env, cwd=home, check=True)
for tool in tools:
    assert len((home / f"{tool}.calls").read_text().splitlines()) == (2 if tool == "atuin" else 1), tool
print("znap evaluates tool init, reuses caches across shells, and regenerates removed caches")
