#!/usr/bin/env bats

load test_helper

# Use the installed CLI, but no user config, cache, installs, or network.
prepare_mise_fixture() {
    MISE_BIN="$(command -v mise)" || skip "mise is not installed"
    MISE_BIN="$(python3 -c 'import pathlib, sys; print(pathlib.Path(sys.argv[1]).resolve())' "$MISE_BIN")"
    export FIXTURE="$TEST_TMPDIR/mise"
    mkdir -p "$FIXTURE"/{config,data/shims,data/installs/node/1.0.0/bin,cache,state,project,bin}
    chezmoi execute-template --file home/dot_config/mise/config.toml.tmpl >"$FIXTURE/rendered.toml"
    python3 - "$FIXTURE" <<'PY'
import pathlib, sys, tomllib
root = pathlib.Path(sys.argv[1])
settings = tomllib.loads((root / "rendered.toml").read_text())["settings"]
(root / "config/config.toml").write_text("[settings]\n" + "".join(
    f"{key} = {str(settings[key]).lower()}\n"
    for key in ("auto_install", "not_found_system_fallback")
))
PY
    cat >"$FIXTURE/project/mise.toml" <<'TOML'
[tools]
node = "0.0.0"
[tasks.check]
run = "node --version"
TOML
    # A stale shim from a previously installed version, not a real tool install.
    printf '#!/bin/sh\nexit 0\n' >"$FIXTURE/data/installs/node/1.0.0/bin/node"
    chmod +x "$FIXTURE/data/installs/node/1.0.0/bin/node"
    ln -s "$MISE_BIN" "$FIXTURE/data/shims/node"
    cd "$FIXTURE/project"
}

isolated_mise() {
    env -i HOME="$TEST_HOME_DIR" PATH="$FIXTURE/data/shims:$FIXTURE/bin" \
        MISE_CONFIG_DIR="$FIXTURE/config" MISE_DATA_DIR="$FIXTURE/data" \
        MISE_CACHE_DIR="$FIXTURE/cache" MISE_STATE_DIR="$FIXTURE/state" \
        MISE_TRUSTED_CONFIG_PATHS="$FIXTURE/project" MISE_OFFLINE=1 \
        "$@"
}

assert_no_install() {
    [ ! -e "$FIXTURE/data/installs/node/0.0.0" ]
    [ ! -d "$FIXTURE/data/downloads" ]
    [ ! -e "$TEST_HOME_DIR/system-fallback" ]
}

@test "missing configured shim fails offline instead of installing or using system fallback" {
    prepare_mise_fixture
    # Even a matching executable later on PATH must not satisfy a configured shim.
    printf '#!/bin/sh\nprintf fallback >"$HOME/system-fallback"\n' >"$FIXTURE/bin/node"
    chmod +x "$FIXTURE/bin/node"

    run isolated_mise "$FIXTURE/data/shims/node" --version
    [ "$status" -ne 0 ]
    [[ "$output" == *"node@0.0.0"* ]]
    assert_no_install
}

@test "exec with a missing tool fails offline without installing" {
    prepare_mise_fixture

    run isolated_mise "$MISE_BIN" exec -- node --version
    [ "$status" -ne 0 ]
    [[ "$output" == *"node@0.0.0"* ]]
    assert_no_install
}

@test "task with a missing tool fails offline without installing" {
    prepare_mise_fixture

    run isolated_mise "$MISE_BIN" run check
    [ "$status" -ne 0 ]
    [[ "$output" == *"node@0.0.0"* ]]
    assert_no_install
}

@test "environment disables implicit installs even when a project enables them" {
    prepare_mise_fixture
    printf '\n[settings]\nauto_install = true\n' >>"$FIXTURE/project/mise.toml"

    run isolated_mise "$MISE_BIN" settings auto_install
    [ "$status" -eq 0 ]
    [ "$output" = true ]
    run isolated_mise "$(command -v env)" MISE_AUTO_INSTALL=0 "$MISE_BIN" settings auto_install
    [ "$status" -eq 0 ]
    [ "$output" = false ]
}
