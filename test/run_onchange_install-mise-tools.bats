#!/usr/bin/env bats

load test_helper

@test "renders correctly and produces valid shell syntax" {
    # Test our ACTUAL script renders to valid shell syntax
    local script_file="home/.chezmoiscripts/run_onchange_after_00-install-mise-tools.sh.tmpl"

    # Render our actual script (no template variables needed for this script)
    run chezmoi execute-template --file "$script_file"
    [ "$status" -eq 0 ]

    assert_script_structure "$output"
}
