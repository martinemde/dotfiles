#!/usr/bin/env bats

load test_helper

render_canary() {
    local source="$1" os="${2:-linux}" host="${3:-thria}"
    "${CHEZMOI_BIN:-chezmoi}" --config /dev/null --config-format toml --source "$BATS_TEST_DIRNAME/../home" \
        --override-data "{\"chezmoi\":{\"os\":\"$os\",\"hostname\":\"$host\",\"arch\":\"arm64\"},\"git\":{\"name\":\"Fixture\",\"email\":\"fixture@example.invalid\"}}" \
        execute-template --file "$BATS_TEST_DIRNAME/../$source"
}

prepare_commands() {
    CHEZMOI_BIN="$(command -v chezmoi)"
    export CALLS="$TEST_TMPDIR/calls"
    mkdir -p "$TEST_TMPDIR/root" "$TEST_HOME_DIR/.local/bin"
    # Root paths are replaced only in disposable rendered fixtures, never on-host.
    render_canary home/dot_local/bin/executable_gh.tmpl |
        sed "s|/usr/local/bin/gh-app-gh|$TEST_TMPDIR/root/gh-app-gh|" >"$TEST_HOME_DIR/.local/bin/gh"
    sed -e "s|/usr/local/bin/gh-app-run|$TEST_TMPDIR/root/gh-app-run|" \
        -e "s|/usr/bin/mise|$TEST_TMPDIR/root/mise|" \
        "$BATS_TEST_DIRNAME/../home/dot_local/bin/executable_mise" >"$TEST_HOME_DIR/.local/bin/mise"
    cat >"$TEST_TMPDIR/root/gh-app-run" <<'SH'
#!/bin/bash
printf 'app-run\n' >>"$CALLS"
[ "${FAIL_BROKER:-}" != 1 ] || exit 71
exec "$@"
SH
    cat >"$TEST_TMPDIR/root/gh-app-gh" <<'SH'
#!/bin/bash
# Mirror the broker's bare mise resolver, not command -v gh (which recurses).
real_gh="$(mise which gh)" || exit
exec "$real_gh" "$@"
SH
    cat >"$TEST_TMPDIR/root/mise" <<'SH'
#!/bin/bash
printf 'mise %s\n' "$*" >>"$CALLS"
if [ "$*" = 'which gh' ]; then
    printf '%s/root/native-gh\n' "$TEST_TMPDIR"
elif [ "$*" = 'which bun' ]; then
    exit 1
fi
SH
    cat >"$TEST_TMPDIR/root/native-gh" <<'SH'
#!/bin/bash
printf 'native-gh %s GIT_DIR=%s\n' "$*" "${GIT_DIR:-}" >>"$CALLS"
SH
    cat >"$TEST_HOME_DIR/.local/bin/jj" <<'SH'
#!/bin/bash
printf '%s/backing.git\n' "$TEST_TMPDIR"
SH
    chmod +x "$TEST_TMPDIR/root/"* "$TEST_HOME_DIR/.local/bin/"*
    export PATH="$TEST_HOME_DIR/.local/bin:/usr/bin:/bin"
}

@test "only Linux Thria uses the app gh and installs the mise wrapper" {
    local os host
    for os in linux darwin; do
        for host in thria other; do
            render_canary home/dot_local/bin/executable_gh.tmpl "$os" "$host" >"$TEST_TMPDIR/gh"
            render_canary home/.chezmoiignore "$os" "$host" >"$TEST_TMPDIR/ignore"
            bash -n "$TEST_TMPDIR/gh"
            if [ "$os/$host" = linux/thria ]; then
                grep -q '^exec /usr/local/bin/gh-app-gh ' "$TEST_TMPDIR/gh"
                ! grep -q '^.local/bin/mise$' "$TEST_TMPDIR/ignore"
            else
                ! grep -q gh-app "$TEST_TMPDIR/gh"
                grep -q '^.local/bin/mise$' "$TEST_TMPDIR/ignore"
            fi
        done
    done
}

@test "gh retains jj backing repo and nested mise resolution is finite" {
    prepare_commands
    run env HOME="$TEST_HOME_DIR" gh repo view
    [ "$status" -eq 0 ]
    [ "$(grep -c '^app-run$' "$CALLS")" -eq 1 ]
    grep -q "^native-gh repo view GIT_DIR=$TEST_TMPDIR/backing.git$" "$CALLS"
    run env HOME="$TEST_HOME_DIR" GIT_DIR=preexisting gh api user
    [ "$status" -eq 0 ]
    grep -q '^native-gh api user GIT_DIR=preexisting$' "$CALLS"
}

@test "mise wrapper forwards arguments and broker failure cannot reach native mise or gh" {
    prepare_commands
    run mise --cd 'path with spaces' install --yes
    [ "$status" -eq 0 ]
    grep -q '^mise --cd path with spaces install --yes$' "$CALLS"
    rm "$CALLS"
    run env FAIL_BROKER=1 GITHUB_TOKEN=bad MISE_ALLOW_ANONYMOUS_GITHUB=1 mise install --yes
    [ "$status" -eq 71 ]
    [ "$(cat "$CALLS")" = app-run ]
    rm "$CALLS"
    run env FAIL_BROKER=1 gh api user
    [ "$status" -ne 0 ]
    [ "$(cat "$CALLS")" = app-run ]
}

@test "Thria installer uses absolute app routes and ignores inherited anonymous or token bypass" {
    prepare_commands
    render_canary home/.chezmoiscripts/run_onchange_after_00-install-mise-tools.sh.tmpl |
        sed -e "s|/usr/local/bin/gh-app-run|$TEST_TMPDIR/root/gh-app-run|g" \
            -e "s|/usr/bin/mise|$TEST_TMPDIR/root/mise|g" >"$TEST_TMPDIR/install"
    bash -n "$TEST_TMPDIR/install"
    run env HOME="$TEST_HOME_DIR" DEBUG=1 GITHUB_TOKEN=sentinel-not-logged \
        MISE_ALLOW_ANONYMOUS_GITHUB=1 FAIL_BROKER=1 bash "$TEST_TMPDIR/install"
    [ "$status" -eq 71 ]
    [ "$(cat "$CALLS")" = app-run ]
    [[ "$output" != *sentinel-not-logged* ]]
    [[ "$output" != *PAT* ]]
    rm "$CALLS"
    run env HOME="$TEST_HOME_DIR" bash "$TEST_TMPDIR/install"
    [ "$status" -eq 0 ]
    grep -q "^mise --cd $TEST_HOME_DIR install --yes$" "$CALLS"
    grep -q '^mise which bun$' "$CALLS"
}

@test "fresh and interactive Thria shell paths prioritize local wrappers and remove only gh alias" {
    command -v zsh >/dev/null || skip 'zsh is not installed'
    mkdir -p "$TEST_HOME_DIR/.local/bin" "$TEST_HOME_DIR/.local/share/mise/shims" "$TEST_HOME_DIR/.config/op"
    render_canary home/dot_zshenv.tmpl >"$TEST_HOME_DIR/.zshenv"
    render_canary home/dot_config/zsh/tools.zsh.tmpl >"$TEST_TMPDIR/tools"
    cat >"$TEST_HOME_DIR/.local/bin/mise" <<'SH'
#!/bin/sh
printf 'path=("$XDG_DATA_HOME/mise/shims" $path)\n'
SH
    chmod +x "$TEST_HOME_DIR/.local/bin/mise"
    printf "alias gh='false legacy-auth'\nalias keepme='true'\n" >"$TEST_HOME_DIR/.config/op/plugins.sh"
    run env -i HOME="$TEST_HOME_DIR" PATH=/usr/bin:/bin TERM=xterm \
        zsh -c '[[ $path[1] == "$HOME/.local/bin" ]]'
    [ "$status" -eq 0 ]
    run env -i HOME="$TEST_HOME_DIR" PATH=/usr/bin:/bin TERM=xterm \
        TOOLS="$TEST_TMPDIR/tools" zsh -ic \
        'znap() { :; }; source "$TOOLS"; [[ $path[1] == "$HOME/.local/bin" ]] && (( ! $+aliases[gh] )) && (( $+aliases[keepme] ))'
    [ "$status" -eq 0 ]
}

@test "GitHub helpers reset legacy auth, fail closed without askpass, and rewrite only exact SSH forms" {
    render_canary home/dot_config/git/config.tmpl >"$TEST_TMPDIR/gitconfig"
    export GIT_CONFIG_GLOBAL="$TEST_TMPDIR/gitconfig" GIT_CONFIG_NOSYSTEM=1
    export HOME="$TEST_HOME_DIR" GIT_ASKPASS="$TEST_TMPDIR/askpass"
    export ASKPASS_MARKER="$TEST_TMPDIR/asked" LEGACY_MARKER="$TEST_TMPDIR/legacy"
    printf '#!/bin/sh\ntouch "$ASKPASS_MARKER"\nexit 1\n' >"$GIT_ASKPASS"
    chmod +x "$GIT_ASKPASS"
    # The root helper contract is tested here using a stopped-broker fixture.
    printf '#!/bin/sh\n[ "$1" != get ] || printf "quit=true\\n\\n"\n' >"$TEST_TMPDIR/helper"
    chmod +x "$TEST_TMPDIR/helper"
    sed -i "s|/usr/local/bin/git-credential-gh-app|$TEST_TMPDIR/helper|g" "$GIT_CONFIG_GLOBAL"
    local host
    for host in github.com github.com:443 gist.github.com gist.github.com:443; do
        run bash -c 'printf "protocol=https\nhost=%s\n\n" "$1" | git -c credential.helper="!touch \"\$LEGACY_MARKER\"" credential fill' _ "$host"
        [ "$status" -ne 0 ]
        [ ! -e "$ASKPASS_MARKER" ]
        [ ! -e "$LEGACY_MARKER" ]
    done
    # Inspect the effective helper ordering without invoking a real helper.
    run git config --get-all credential.https://github.com.helper
    [ "$status" -eq 0 ]
    [ "$output" = $'\n'"$TEST_TMPDIR/helper" ]
    local source
    for source in git@github.com: ssh://git@github.com/ ssh://git@github.com:22/; do
        run git ls-remote --get-url "${source}owner/repo.git"
        [ "$status" -eq 0 ]
        [ "$output" = https://github.com/owner/repo.git ]
    done
    run git ls-remote --get-url git@example.invalid:owner/repo.git
    [ "$status" -eq 0 ]
    [ "$output" = git@example.invalid:owner/repo.git ]
}
