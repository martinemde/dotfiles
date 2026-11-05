#!/usr/bin/env bats

setup() {
    TEMP_DIR="$(mktemp -d)"
    export BREW_LOG="$TEMP_DIR/brew.log"
    mkdir "$TEMP_DIR/bin"
    printf '#!/bin/bash\necho "$*" >> "$BREW_LOG"\nif [ "$1" = update ]; then exit "${UPDATE_EXIT:-0}"; fi\n' > "$TEMP_DIR/bin/brew"
    chmod +x "$TEMP_DIR/bin/brew"
    export PATH="$TEMP_DIR/bin:/usr/bin:/bin"
}

teardown() {
    rm -rf "$TEMP_DIR"
}

@test "scheduled Homebrew updates use the normal update and upgrade path" {
    run bash "$BATS_TEST_DIRNAME/../home/dot_local/bin/executable_update-homebrew"
    [ "$status" -eq 0 ]
    [ "$(cat "$BREW_LOG")" = "$(printf 'update\nupgrade')" ]
}

@test "failed metadata refresh prevents upgrade" {
    export UPDATE_EXIT=1
    run bash "$BATS_TEST_DIRNAME/../home/dot_local/bin/executable_update-homebrew"
    [ "$status" -eq 1 ]
    [ "$(cat "$BREW_LOG")" = update ]
}
