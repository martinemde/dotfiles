#!/usr/bin/env bats

load test_helper

@test "Library is excluded on non-darwin platforms" {
    local ignore_file="home/.chezmoiignore"

    # Test that the template renders correctly on different platforms
    # Copy the .chezmoiignore to test directory
    cp "$ignore_file" "$TEST_SOURCE_DIR/.chezmoiignore"

    # Test on darwin - should NOT exclude the files
    cat >"$TEST_TMPDIR/darwin-config.toml" <<EOF
[data]
    chezmoi = { os = "darwin", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
EOF

    run chezmoi execute-template --config "$TEST_TMPDIR/darwin-config.toml" --file "$TEST_SOURCE_DIR/.chezmoiignore"
    [ "$status" -eq 0 ]
    [[ "$output" != *"Library/**"* ]]

    # Test on linux - should exclude the files
    cat >"$TEST_TMPDIR/linux-config.toml" <<EOF
[data]
    chezmoi = { os = "linux", homeDir = "$TEST_HOME_DIR", sourceDir = "$TEST_SOURCE_DIR" }
EOF

    run chezmoi execute-template --config "$TEST_TMPDIR/linux-config.toml" --file "$TEST_SOURCE_DIR/.chezmoiignore"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Library/**"* ]]
}
