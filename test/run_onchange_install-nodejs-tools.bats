#!/usr/bin/env bats

load test_helper

@test "Node tool installer renders with valid shell syntax" {
    run chezmoi --config /dev/null --config-format toml \
        --source "$BATS_TEST_DIRNAME/../home" execute-template \
        --file home/.chezmoiscripts/run_onchange_after_install-nodejs-tools.sh.tmpl
    [ "$status" -eq 0 ]
    assert_script_structure "$output"
}
