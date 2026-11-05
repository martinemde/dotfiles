#!/usr/bin/env bats

load test_helper

setup() {
    TEST_TMPDIR="$(mktemp -d)"
    export TEST_TMPDIR
    export XDG_CONFIG_HOME="$TEST_TMPDIR/config"
    export TOOL_LOG="$TEST_TMPDIR/tool.log"
    export TOOL_BIN="$TEST_TMPDIR/bin"
    mkdir -p "$TOOL_BIN" "$XDG_CONFIG_HOME/dotfiles"
    export PATH="$TOOL_BIN:$PATH"

    cat > "$TOOL_BIN/mise" <<'STUB'
#!/bin/sh
[ "$1" = which ] || exit 1
printf '%s/%s\n' "$TOOL_BIN" "$2"
STUB
    cat > "$TOOL_BIN/jq" <<'STUB'
#!/bin/sh
printf '%s\n' 'example-tool@1.0.0'
STUB
    cat > "$TOOL_BIN/bun" <<'STUB'
#!/bin/sh
printf '%s\n' "$@" > "$TOOL_LOG"
exit "${TOOL_EXIT:-0}"
STUB
    cp "$TOOL_BIN/bun" "$TOOL_BIN/uv"
    chmod +x "$TOOL_BIN/"*
    printf '%s\n' '{"devDependencies":{"example-tool":"1.0.0"}}' > "$XDG_CONFIG_HOME/dotfiles/package.json"
    printf '%s\n' 'example-tool==1.0.0' > "$XDG_CONFIG_HOME/dotfiles/requirements.txt"
}

render_installer() {
    chezmoi execute-template --file "home/.chezmoiscripts/run_onchange_after_install-$1-tools.sh.tmpl" > "$TEST_TMPDIR/install.sh"
}

@test "Node tool installation enforces a seven-day release age" {
    render_installer nodejs
    run sh "$TEST_TMPDIR/install.sh"
    [ "$status" -eq 0 ]
    expected="$(printf '%s\n' add --global --minimum-release-age 604800 example-tool@1.0.0)"
    [ "$(cat "$TOOL_LOG")" = "$expected" ]
}

@test "Python tool installation enforces a seven-day release age" {
    render_installer python
    run sh "$TEST_TMPDIR/install.sh"
    [ "$status" -eq 0 ]
    expected="$(printf '%s\n' tool install --force --exclude-newer P7D example-tool==1.0.0)"
    [ "$(cat "$TOOL_LOG")" = "$expected" ]
}

@test "Node tool installation does not retry without the release-age check" {
    render_installer nodejs
    export TOOL_EXIT=23
    run sh "$TEST_TMPDIR/install.sh"
    [ "$status" -eq 23 ]
}

@test "Python tool installation does not retry without the release-age check" {
    render_installer python
    export TOOL_EXIT=23
    run sh "$TEST_TMPDIR/install.sh"
    [ "$status" -eq 23 ]
}
