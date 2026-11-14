#!/usr/bin/env bats

@test "Renovate discovers manifests and keeps URL/checksum updates paired" {
  command -v bun >/dev/null 2>&1 || skip "Bun is not installed"
  if [ -z "${RENOVATE_RESOLVED_CONFIG:-}" ]; then
    export RENOVATE_RESOLVED_CONFIG="$BATS_TEST_TMPDIR/renovate-resolved.json"
    run "$BATS_TEST_DIRNAME/../bin/check-renovate-policy" "$RENOVATE_RESOLVED_CONFIG"
    printf '%s\n' "$output"
    [ "$status" -eq 0 ] || return 1
  fi
  run env REPO_ROOT="$BATS_TEST_DIRNAME/.." bun --eval '
    import { strict as assert } from "node:assert";
    import { readFileSync } from "node:fs";
    import { join } from "node:path";
    import { runInNewContext } from "node:vm";

    const root = process.env.REPO_ROOT;
    const config = JSON.parse(readFileSync(process.env.RENOVATE_RESOLVED_CONFIG, "utf8"));
    const filePatterns = manager => (manager.managerFilePatterns ?? manager.fileMatch ?? [])
      .filter(pattern => pattern.startsWith("/") && pattern.endsWith("/"))
      .map(pattern => new RegExp(pattern.slice(1, -1)));
    assert.equal(config.schedule, undefined);
    assert.equal(config.minimumReleaseAge, "7 days");
    assert.equal(config.minimumReleaseAgeBehaviour, "timestamp-required");
    assert.equal(config.internalChecksFilter, "strict");
    assert.equal(config.automerge, false);
    assert.equal(config.dependencyDashboard, true);
    assert.equal(config.osvVulnerabilityAlerts, true);
    assert.equal(config.vulnerabilityAlerts.minimumReleaseAge, null);
    assert.equal(config.vulnerabilityAlerts.automerge, true);
    assert(config.vulnerabilityAlerts.addLabels.includes("security"));
    const tools = JSON.parse(readFileSync(join(root, "home/dot_config/dotfiles/package.json"), "utf8"));
    for (const version of Object.values(tools.devDependencies)) {
      assert.match(version, /^\d+\.\d+\.\d+$/);
    }
    assert.equal(config.platformAutomerge, false);
    assert.equal(config.automergeType, "pr");
    assert.equal(config.automergeStrategy, "squash");
    assert.equal(config.statusCheckNames, undefined);
    const mergePolicy = config.packageRules.find(rule => rule.automerge === true);
    assert.equal(mergePolicy.automerge, true);
    assert.deepEqual(Array.from(mergePolicy.matchUpdateTypes), ["minor", "patch", "digest", "major"]);
    for (const file of ["package.json", "home/dot_config/dotfiles/package.json"]) {
      assert(filePatterns(config.npm).some(pattern => pattern.test(file)), file);
    }

    const miseFile = "home/dot_config/mise/config.toml";
    assert(filePatterns(config.mise).some(pattern => pattern.test(miseFile)));
    const mise = Bun.TOML.parse(readFileSync(join(root, miseFile), "utf8"));
    for (const tool of Object.values(mise.tools)) {
      const version = typeof tool === "string" ? tool : tool.version;
      assert.notEqual(version, "latest");
    }

    const file = "home/.chezmoiexternals/zellij.externals.toml";
    const contents = readFileSync(join(root, file), "utf8");
    const managers = config.customManagers.filter(manager =>
      filePatterns(manager).some(pattern => pattern.test(file)));
    assert.equal(managers.length, 1, "no URL-only updater may compete with checksums");
    const manager = managers[0];
    assert.equal(manager.datasourceTemplate, "github-release-attachments");
    assert.equal(manager.versioningTemplate, "loose");
    const matches = [...contents.matchAll(new RegExp(manager.matchStrings[0], "g"))];
    const externals = Bun.TOML.parse(contents);
    assert.equal(matches.length, Object.keys(externals).length);
    for (const match of matches) {
      const {depName, currentValue, currentDigest} = match.groups;
      const original = Object.values(externals).find(external =>
        external.url.includes("/" + depName + "/releases/download/" + currentValue + "/"));
      assert(original, depName);
      assert.equal(original.checksum.sha256, currentDigest);
      // Renovate auto-replaces currentValue and currentDigest in the same match.
      const newValue = "v99.0.0";
      const newDigest = "a".repeat(64);
      const newMatch = match[0].replace(currentValue, newValue).replace(currentDigest, newDigest);
      const updated = Bun.TOML.parse(contents.replace(match[0], newMatch));
      const changed = Object.values(updated).filter(external => external.checksum.sha256 === newDigest);
      assert.equal(changed.length, 1);
      assert(changed[0].url.includes("/releases/download/" + newValue + "/"));
      assert(!contents.replace(match[0], newMatch).includes(currentDigest));
    }
    assert(config.packageRules.some(rule =>
      rule.matchDatasources?.includes("github-release-attachments") && rule.groupName === "zellij-plugins"));

    for (const manager of config.customManagers.filter(manager =>
      manager.currentValueTemplate === "master" || manager.currentValueTemplate === "main")) {
      assert.equal(manager.datasourceTemplate, "github-digest", "branch updates require commit timestamps");
      assert.match(manager.packageNameTemplate, /^[^/]+\/[^/]+$/);
    }
  '
  printf '%s\n' "$output"
  [ "$status" -eq 0 ]
}

@test "Renovate dispatch is read-only and never uses App credentials" {
  command -v bun >/dev/null 2>&1 || skip "Bun is not installed"
  run env REPO_ROOT="$BATS_TEST_DIRNAME/.." bun --eval '
    import { strict as assert } from "node:assert";
    import { readFileSync } from "node:fs";
    import { join } from "node:path";

    const source = readFileSync(join(process.env.REPO_ROOT, ".github/workflows/renovate.yml"), "utf8");
    const workflow = Bun.YAML.parse(source);
    assert.deepEqual(Object.keys(workflow.on), ["workflow_dispatch"]);
    assert.equal(workflow.on.workflow_dispatch.inputs.dry_run.type, "boolean");
    assert.equal(workflow.on.workflow_dispatch.inputs.dry_run.default, true);
    assert(Object.values(workflow.permissions).every(permission => permission === "read"));
    assert(!source.includes("secrets."));
    assert(!source.includes("RENOVATE_APP_"));
    assert(!source.includes("create-github-app-token"));
    const job = workflow.jobs.renovate;
    assert.equal(job.env.RENOVATE_TOKEN, undefined);
    assert.equal(job.if, undefined);
    assert(!job.steps.some(step => step.id === "app-token"));
    assert.deepEqual(job.strategy.matrix.repository, ["dotfiles", "martinemde.com", "micropub-publisher", "almanac", "containers", "beelink"]);
    assert.equal(job.strategy["fail-fast"], false);
    assert.equal(job.env.RENOVATE_REPOSITORY, "${{ github.repository_owner }}/${{ matrix.repository }}");
    const engines = job.steps.filter(step => step.run?.includes(`renovate "$RENOVATE_REPOSITORY"`));
    assert.equal(engines.length, 1);
    const dry = engines[0];
    assert.equal(dry.if, `github.event_name == '"'"'workflow_dispatch'"'"' && inputs.dry_run`);
    assert.equal(dry.env.RENOVATE_TOKEN, "${{ github.token }}");
    assert.equal(dry.env.RENOVATE_DRY_RUN, "full");

    assert.equal(dry.run, `renovate "$RENOVATE_REPOSITORY"`);
    assert(job.steps.filter(step => step.env?.RENOVATE_TOKEN).every(step => step.env.RENOVATE_DRY_RUN === "full"));
  '
  printf '%s\n' "$output"
  [ "$status" -eq 0 ]
}
