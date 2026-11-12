#!/usr/bin/env bats

load test_helper

@test "mise sources preserve exact pins and verification policy" {
    run python3 - "$BATS_TEST_DIRNAME/.." <<'PY'
import pathlib
import re
import sys
import tomllib

root = pathlib.Path(sys.argv[1]).resolve()
source = root / "home/dot_config/mise/config.toml"
raw = tomllib.loads(source.read_text())
project = tomllib.loads((root / ".mise.toml").read_text())
lock = tomllib.loads((root / "mise.lock").read_text())

def version(value):
    return value["version"] if isinstance(value, dict) else value

for config in (raw, project):
    for name, value in config["tools"].items():
        assert re.fullmatch(r"v?\d+(?:\.\d+)+", version(value)), (name, value)
    settings = config["settings"]
    assert settings["auto_install"] is False
    assert settings["not_found_system_fallback"] is False
    assert settings["locked_verify_provenance"] is True
    assert settings["provenance_api_failures_fatal"] is True
    assert settings["minimum_release_age"] == "7d"
    assert all(settings["aqua"][name] is True for name in
               ("cosign", "github_attestations", "minisign", "slsa"))
    assert settings["node"]["verify"] is True
    assert settings["go"]["skip_checksum"] is False
for name, value in project["tools"].items():
    assert any(entry["version"] == version(value) for entry in lock["tools"][name]), name
assert raw["settings"]["python"]["compile"] is False
assert raw["settings"]["python"]["github_attestations"] is True
assert raw["tools"]["aqua:eza-community/eza"]["os"] == ["linux"]
PY
    printf '%s\n' "$output"
    [ "$status" -eq 0 ]
}
