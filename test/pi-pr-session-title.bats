#!/usr/bin/env bats

@test "Pi PR source and license share an immutable pin tracked by Renovate" {
  command -v bun >/dev/null 2>&1 || skip "Bun is not installed"
  run env REPO_ROOT="$BATS_TEST_DIRNAME/.." bun --eval '
    import { strict as assert } from "node:assert";
    import { readFileSync } from "node:fs";
    import { join } from "node:path";
    import { runInNewContext } from "node:vm";

    const root = process.env.REPO_ROOT;
    const file = "home/.chezmoiexternals/pi.externals.toml";
    const contents = readFileSync(join(root, file), "utf8");
    const externals = Bun.TOML.parse(contents);
    assert.deepEqual(Object.keys(externals).sort(), [
      ".pi/agent/extensions/pr-session-title/LICENSE",
      ".pi/agent/extensions/pr-session-title/upstream.ts",
    ]);
    const config = runInNewContext("(" + readFileSync(join(root, "renovate.json5"), "utf8") + ")");
    assert(config.enabledManagers.includes("custom.regex"));
    const manager = config.customManagers.find((manager) =>
      manager.depNameTemplate === "lepht/pi-pr-session-title" &&
      manager.fileMatch.some((pattern) => new RegExp(pattern).test(file)));
    assert(manager);
    assert.equal(manager.datasourceTemplate, "git-refs");
    assert.equal(manager.currentValueTemplate, "main");
    const matches = manager.matchStrings.flatMap((pattern) =>
      [...contents.matchAll(new RegExp(pattern, "g"))]);
    assert.equal(matches.length, 2);
    const digest = matches[0].groups.currentDigest;
    assert.match(digest, /^[a-f0-9]{40}$/);
    assert.equal(matches[1].groups.currentDigest, digest);
    for (const external of Object.values(externals)) {
      assert.equal(external.type, "file");
      assert.equal(new URL(external.url).origin, "https://github.com");
      assert(external.url.includes("/lepht/pi-pr-session-title/raw/" + digest + "/"));
    }
  '
  printf '%s\n' "$output"
  [ "$status" -eq 0 ]
}

@test "Pi PR names follow real prompts, preserve manual names, and update terminal titles" {
  command -v pi >/dev/null 2>&1 || skip "Pi is not installed"
  command -v python3 >/dev/null 2>&1 || skip "Python 3 is not installed"
  upstream="${PI_PR_SESSION_TITLE_UPSTREAM:-$HOME/.pi/agent/extensions/pr-session-title/upstream.ts}"
  [ -f "$upstream" ] || skip "Apply the pinned PR extension first, or set PI_PR_SESSION_TITLE_UPSTREAM"
  run python3 "$BATS_TEST_DIRNAME/pi-pr-session-title.py" "$upstream"
  printf '%s\n' "$output"
  [ "$status" -eq 0 ]
}
