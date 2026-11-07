#!/usr/bin/env bats

load test_helper

@test "mise source and OS renders preserve exact pins and verification policy" {
    command -v chezmoi >/dev/null 2>&1 || skip "chezmoi is not installed"
    run python3 - "$BATS_TEST_DIRNAME/.." <<'PY'
import json
import pathlib
import re
import subprocess
import sys
import tomllib

root = pathlib.Path(sys.argv[1]).resolve()
source = root / "home/dot_config/mise/config.toml"
env_source = root / "home/dot_config/mise/conf.d/10-homebrew.toml.tmpl"
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
for os_name in ("darwin", "linux"):
    for arch in ("amd64", "arm64"):
        output = subprocess.check_output([
            "chezmoi", "--override-data", json.dumps({"chezmoi": {"os": os_name, "arch": arch}}),
            "execute-template", "--file", str(env_source),
        ], text=True)
        rendered = tomllib.loads(output)
        if os_name == "darwin":
            prefix = "/opt/homebrew" if arch == "arm64" else "/usr/local"
            assert rendered["env"]["SSL_CERT_FILE"] == prefix + "/etc/ca-certificates/cert.pem"
            assert rendered["env"]["REQUESTS_CA_BUNDLE"] == rendered["env"]["SSL_CERT_FILE"]
            assert rendered["env"]["NODE_OPTIONS"] == "--use-openssl-ca"
        else:
            assert rendered == {}
assert raw["tools"]["aqua:eza-community/eza"]["os"] == ["linux"]
PY
    printf '%s\n' "$output"
    [ "$status" -eq 0 ]
}
