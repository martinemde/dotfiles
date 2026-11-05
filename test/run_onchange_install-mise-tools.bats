#!/usr/bin/env bats

load test_helper

@test "renders correctly and produces valid shell syntax" {
    # Test our ACTUAL script renders to valid shell syntax
    local script_file="home/.chezmoiscripts/run_onchange_after_00-install-mise-tools.sh.tmpl"

    # Render our actual script (no template variables needed for this script)
    run chezmoi --config /dev/null --config-format toml --source "$BATS_TEST_DIRNAME/../home" execute-template --file "$script_file"
    [ "$status" -eq 0 ]

    assert_script_structure "$output"
}


@test "installs global tools outside the checkout using configured release-age policy" {
    local script="$TEST_TMPDIR/install-mise.sh"
    chezmoi --config /dev/null --config-format toml --source "$BATS_TEST_DIRNAME/../home" execute-template --file home/.chezmoiscripts/run_onchange_after_00-install-mise-tools.sh.tmpl >"$script"
    mkdir -p "$TEST_TMPDIR/bin"
    cat >"$TEST_TMPDIR/bin/mise" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" >>"$MISE_CALLS"
# No bun installation in this fixture.
[ "$1" != "which" ]
EOF
    chmod +x "$TEST_TMPDIR/bin/mise"

    run env PATH="$TEST_TMPDIR/bin:$PATH" HOME="$TEST_HOME_DIR" \
        GITHUB_TOKEN=test-token MISE_CALLS="$TEST_TMPDIR/mise-calls" bash "$script"
    [ "$status" -eq 0 ]
    [ "$(head -n 1 "$TEST_TMPDIR/mise-calls")" = "--cd $TEST_HOME_DIR install --yes" ]
}

@test "global and project configs enable release delay and download verification" {
    local os
    for os in linux darwin; do
        chezmoi --config /dev/null --config-format toml \
            --override-data "{\"chezmoi\":{\"os\":\"$os\",\"arch\":\"arm64\"}}" \
            execute-template --file home/dot_config/mise/config.toml.tmpl >"$TEST_TMPDIR/$os.toml"
    done

    run python3 -c '
import pathlib, sys, tomllib
for name in sys.argv[1:]:
    config = tomllib.loads(pathlib.Path(name).read_text())
    settings = config["settings"]
    assert settings["minimum_release_age"] == "7d"
    assert settings["auto_install"] is False
    assert settings["not_found_system_fallback"] is False
    for key in ("locked_verify_provenance", "provenance_api_failures_fatal", "github_attestations", "slsa"):
        assert settings[key] is True
    assert all(settings["aqua"][key] is True for key in ("cosign", "github_attestations", "minisign", "slsa"))
    assert settings["node"]["verify"] is True
    assert settings["go"]["skip_checksum"] is False
' .mise.toml "$TEST_TMPDIR/linux.toml" "$TEST_TMPDIR/darwin.toml"
    [ "$status" -eq 0 ]
}

@test "global Python alone bypasses tool delay with required precompiled attestations" {
    local os
    for os in linux darwin; do
        chezmoi --config /dev/null --config-format toml \
            --override-data "{\"chezmoi\":{\"os\":\"$os\",\"arch\":\"arm64\"}}" \
            execute-template --file home/dot_config/mise/config.toml.tmpl >"$TEST_TMPDIR/$os.toml"
    done

    run python3 -c '
import pathlib, sys, tomllib
for name in sys.argv[1:]:
    config = tomllib.loads(pathlib.Path(name).read_text())
    assert config["tools"]["python"] == {"version": "latest", "minimum_release_age": "0s"}
    assert config["tools"]["uv"] == "latest"
    settings = config["settings"]
    assert settings["python"]["compile"] is False
    assert settings["python"]["github_attestations"] is True
    assert settings["minimum_release_age"] == "7d"
    assert settings["self_update"]["minimum_release_age"] == "0s"
' "$TEST_TMPDIR/linux.toml" "$TEST_TMPDIR/darwin.toml"
    [ "$status" -eq 0 ]
}

@test "project lock covers configured tools and all supported desktop platforms" {
    run python3 -c '
import pathlib, re, tomllib
config = tomllib.loads(pathlib.Path(".mise.toml").read_text())
lock = tomllib.loads(pathlib.Path("mise.lock").read_text())
assert set(config["tools"]) == set(lock["tools"])
for name, request in config["tools"].items():
    entry, = lock["tools"][name]
    assert request == "latest" or entry["version"] == request
    assert entry["specifiers"] == [request]
    for platform in ("linux-x64", "linux-arm64", "macos-x64", "macos-arm64"):
        target = entry["platforms." + platform]
        assert target["url"].startswith("https://github.com/")
        assert re.fullmatch(r"sha256:[a-f0-9]{64}", target["checksum"])
'
    [ "$status" -eq 0 ]
}
