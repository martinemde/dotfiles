#!/usr/bin/env bats

load test_helper

prepare_external_fixture() {
  python3 -c '
import hashlib
from pathlib import Path
import sys
import tomllib

source = Path(sys.argv[1])
payload = Path(sys.argv[2])
payload.write_bytes(b"verified plugin fixture\n")
manifest = Path("home/.chezmoiexternals/zellij.externals.toml").read_text()
for entry in tomllib.loads(manifest).values():
    manifest = manifest.replace(entry["url"], payload.as_uri())
    manifest = manifest.replace(entry["checksum"]["sha256"], hashlib.sha256(payload.read_bytes()).hexdigest())
(source / ".chezmoiexternal.toml").write_text(manifest)
' "$TEST_SOURCE_DIR" "$TEST_TMPDIR/plugin.wasm"
}

cat_plugin() {
  chezmoi --config /dev/null --config-format toml \
    --source "$TEST_SOURCE_DIR" --destination "$TEST_HOME_DIR" \
    --cache "$TEST_TMPDIR/cache" --persistent-state "$TEST_TMPDIR/state.boltdb" \
    cat "$TEST_HOME_DIR/.config/zellij/plugins/$1"
}

@test "all Zellij release plugins have SHA256 pins" {
  run python3 -c '
from pathlib import Path
import re
import tomllib

entries = tomllib.loads(Path("home/.chezmoiexternals/zellij.externals.toml").read_text())
assert entries
for target, entry in entries.items():
    assert entry["type"] == "file", target
    assert re.fullmatch(r"https://github[.]com/[^/]+/[^/]+/releases/download/v?[0-9.]+/[^/]+[.]wasm", entry["url"]), target
    assert re.fullmatch(r"[0-9a-f]{64}", entry["checksum"]["sha256"]), target
'
  [ "$status" -eq 0 ]
}

@test "chezmoi accepts each Zellij plugin with a matching checksum" {
  prepare_external_fixture

  for plugin in zellij-autolock.wasm zjstatus.wasm; do
    run cat_plugin "$plugin"
    [ "$status" -eq 0 ]
    [ "$output" = "verified plugin fixture" ]
    [ ! -e "$TEST_HOME_DIR/.config/zellij/plugins/$plugin" ]
  done
}

@test "chezmoi rejects each Zellij plugin when downloaded bytes change" {
  prepare_external_fixture
  printf "tampered plugin\n" >"$TEST_TMPDIR/plugin.wasm"

  for plugin in zellij-autolock.wasm zjstatus.wasm; do
    run cat_plugin "$plugin"
    [ "$status" -ne 0 ]
    [[ "$output" == *"SHA256 mismatch"* ]]
    [ ! -e "$TEST_HOME_DIR/.config/zellij/plugins/$plugin" ]
  done
}

@test "live Zellij checker rejects changed bytes and API digest mismatches" {
  run python3 -B "$BATS_TEST_DIRNAME/zellij-plugins.py"
  printf '%s\n' "$output"
  [ "$status" -eq 0 ]
}
