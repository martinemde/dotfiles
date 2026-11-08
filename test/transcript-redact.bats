#!/usr/bin/env bats

load test_helper

prepare_redaction_fixture() {
  command -v python3 >/dev/null 2>&1 || skip "Python 3 is not installed"
  command -v gitleaks >/dev/null 2>&1 || skip "gitleaks is not installed"
  export REDACT_SCRIPT="$BATS_TEST_DIRNAME/../home/dot_local/bin/executable_transcript-redact"
  python3 - "$TEST_HOME_DIR" "$TEST_TMPDIR/before.json" <<'PY'
import base64
import json
from pathlib import Path
import sys

home = Path(sys.argv[1])
# Synthetic GitHub PAT; never use a live credential in these fixtures.
secret = "ghp_" + "aB3dE6gH9jK2mN5pQ8sT1vW4yZ7cF0iL3oR6"
transcripts = [
    ".claude/projects/example/session.jsonl",
    ".claude/projects/example/nested/child.jsonl",
    ".claude/history.jsonl",
    ".codex/sessions/2026/11/session.jsonl",
    ".codex/archived_sessions/session.jsonl",
    ".codex/history.jsonl",
    ".codex/session_index.jsonl",
    ".prime/agent/sessions/session.jsonl",
    ".prime/agent-dev-example/sessions/session.jsonl",
    ".prime/agent-dev-example/session-artifacts/session/sub-agent/session.jsonl",
]
untouched = [
    ".env",
    ".claude/settings.json",
    ".claude/auth.json",
    ".claude/unrelated.jsonl",
    ".codex/auth.json",
    ".codex/config.toml",
    ".codex/unrelated.jsonl",
    ".prime/agent/settings.json",
    ".prime/agent/auth.json",
    ".prime/agent/unrelated.jsonl",
    "work/transcript.jsonl",
]
before = {"transcripts": {}, "untouched": {}}
for group, paths in [("transcripts", transcripts), ("untouched", untouched)]:
    for index, relative in enumerate(paths):
        path = home / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        line = json.dumps({"message": "api_key=" + secret, "note": "keep café and metadata", "index": index})
        if group == "transcripts" and index == 1:
            line = line.replace(secret, "\\u0067" + secret[1:])
        data = (line + '\n' + json.dumps({"message": "ordinary text", "index": index}) + '\n').encode()
        path.write_bytes(data)
        before[group][relative] = base64.b64encode(data).decode()
Path(sys.argv[2]).write_text(json.dumps(before))
PY
}

assert_fixture_unchanged() {
  python3 - "$TEST_HOME_DIR" "$TEST_TMPDIR/before.json" <<'PY'
import base64
import json
from pathlib import Path
import sys

home = Path(sys.argv[1])
for paths in json.loads(Path(sys.argv[2]).read_text()).values():
    for relative, encoded in paths.items():
        assert (home / relative).read_bytes() == base64.b64decode(encoded), relative
PY
}

@test "transcript redaction defaults to a read-only dry run" {
  prepare_redaction_fixture
  run python3 "$REDACT_SCRIPT" --home "$TEST_HOME_DIR"
  [ "$status" -eq 0 ]
  assert_fixture_unchanged
}

@test "transcript redaction requires stopped-agent confirmation before writing" {
  prepare_redaction_fixture
  run python3 "$REDACT_SCRIPT" --home "$TEST_HOME_DIR" --write
  [ "$status" -ne 0 ]
  assert_fixture_unchanged
}

@test "transcript redaction preserves byte lengths and JSON while respecting its allowlist" {
  prepare_redaction_fixture
  run python3 "$REDACT_SCRIPT" --home "$TEST_HOME_DIR" --write --agents-stopped
  [ "$status" -eq 0 ]
  python3 - "$TEST_HOME_DIR" "$TEST_TMPDIR/before.json" "$TEST_TMPDIR/after.json" <<'PY'
import base64
import json
from pathlib import Path
import sys

home = Path(sys.argv[1])
before = json.loads(Path(sys.argv[2]).read_text())
secret = "ghp_" + "aB3dE6gH9jK2mN5pQ8sT1vW4yZ7cF0iL3oR6"
after = {}
for group, paths in before.items():
    for relative, encoded in paths.items():
        original = base64.b64decode(encoded)
        data = (home / relative).read_bytes()
        after[relative] = base64.b64encode(data).decode()
        if group == "untouched":
            assert data == original, relative
            continue
        assert len(data) == len(original), relative
        assert data != original, relative
        old_records = [json.loads(line) for line in original.splitlines()]
        records = [json.loads(line) for line in data.splitlines()]
        assert len(records) == len(old_records), relative
        assert secret not in json.dumps(records), relative
        assert records[1] == old_records[1], relative
        assert records[0]["index"] == old_records[0]["index"], relative
        assert records[0]["note"] == old_records[0]["note"], relative
Path(sys.argv[3]).write_text(json.dumps(after))
PY

  run python3 "$REDACT_SCRIPT" --home "$TEST_HOME_DIR" --write --agents-stopped
  [ "$status" -eq 0 ]
  python3 - "$TEST_HOME_DIR" "$TEST_TMPDIR/after.json" <<'PY'
import base64
import json
from pathlib import Path
import sys

home = Path(sys.argv[1])
for relative, encoded in json.loads(Path(sys.argv[2]).read_text()).items():
    assert (home / relative).read_bytes() == base64.b64decode(encoded), relative
PY
}

@test "malformed transcript JSON aborts before any file is written" {
  prepare_redaction_fixture
  local malformed="$TEST_HOME_DIR/.codex/sessions/2026/11/zzz-malformed.jsonl"
  printf '%s\n' '{"message": "unterminated}' >"$malformed"
  cp "$malformed" "$TEST_TMPDIR/malformed-before.jsonl"
  run python3 "$REDACT_SCRIPT" --home "$TEST_HOME_DIR" --write --agents-stopped
  [ "$status" -ne 0 ]
  assert_fixture_unchanged
  cmp "$malformed" "$TEST_TMPDIR/malformed-before.jsonl"
}

@test "transcript redaction detects generic API keys from JSON field names" {
  prepare_redaction_fixture
  local transcript="$TEST_HOME_DIR/.claude/projects/example/generic.jsonl"
  python3 - "$transcript" <<'PY'
import json
from pathlib import Path
import sys

# Synthetic high-entropy value without a provider-specific prefix.
token = "q7ZnR2vMp9LxT4kBc6WdH8sAj3FyN5eU"
Path(sys.argv[1]).write_text(json.dumps({"api_key": token, "note": "keep this"}) + "\n")
PY
  cp "$transcript" "$TEST_TMPDIR/generic-before.jsonl"
  run python3 "$REDACT_SCRIPT" --home "$TEST_HOME_DIR" --write --agents-stopped
  [ "$status" -eq 0 ]
  python3 - "$transcript" "$TEST_TMPDIR/generic-before.jsonl" <<'PY'
import json
from pathlib import Path
import sys

actual = Path(sys.argv[1]).read_bytes()
original = Path(sys.argv[2]).read_bytes()
assert len(actual) == len(original)
record = json.loads(actual)
assert record["api_key"] != json.loads(original)["api_key"]
assert record["note"] == "keep this"
PY
}

@test "transcript redaction masks JSON-encoded multiline keys" {
  prepare_redaction_fixture
  local transcript="$TEST_HOME_DIR/.claude/projects/example/key.jsonl"
  python3 - "$transcript" <<'PY'
import json
from pathlib import Path
import sys
key = "-----BEGIN RSA PRIVATE KEY-----\n" + "AbCdEf0123456789" * 8 + "\n-----END RSA PRIVATE KEY-----"
Path(sys.argv[1]).write_text(json.dumps({"message": key}) + "\n")
PY
  cp "$transcript" "$TEST_TMPDIR/key-before.jsonl"
  run python3 "$REDACT_SCRIPT" --home "$TEST_HOME_DIR" --write --agents-stopped
  [ "$status" -eq 0 ]
  python3 - "$transcript" "$TEST_TMPDIR/key-before.jsonl" <<'PY'
import json
from pathlib import Path
import sys
actual = Path(sys.argv[1]).read_bytes()
original = Path(sys.argv[2]).read_bytes()
assert len(actual) == len(original)
assert "PRIVATE KEY" not in json.loads(actual)["message"]
PY
}
