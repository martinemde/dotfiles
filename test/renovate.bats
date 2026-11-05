#!/usr/bin/env bats

@test "Renovate discovers manifests and keeps URL/checksum updates paired" {
  command -v bun >/dev/null 2>&1 || skip "Bun is not installed"
  run env REPO_ROOT="$BATS_TEST_DIRNAME/.." bun --eval '
    import { strict as assert } from "node:assert";
    import { readFileSync } from "node:fs";
    import { join } from "node:path";
    import { runInNewContext } from "node:vm";

    const root = process.env.REPO_ROOT;
    const config = runInNewContext("(" + readFileSync(join(root, "renovate.json5"), "utf8") + ")");
    assert.equal(config.schedule, undefined);
    assert.equal(config.minimumReleaseAge, "7 days");
    assert.equal(config.minimumReleaseAgeBehaviour, "timestamp-required");
    assert.equal(config.internalChecksFilter, "strict");
    assert.equal(config.automerge, false);
    assert.equal(config.dependencyDashboard, true);
    assert.equal(config.osvVulnerabilityAlerts, true);
    assert.equal(config.vulnerabilityAlerts.minimumReleaseAge, null);
    assert.equal(config.vulnerabilityAlerts.automerge, false);
    assert(config.vulnerabilityAlerts.addLabels.includes("security"));
    const tools = JSON.parse(readFileSync(join(root, "home/dot_config/dotfiles/package.json"), "utf8"));
    for (const version of Object.values(tools.devDependencies)) {
      assert.match(version, /^\d+\.\d+\.\d+$/);
    }
    assert.equal(config.platformAutomerge, false);
    assert.equal(config.automergeType, "pr");
    assert.equal(config.automergeStrategy, "squash");
    assert.equal(config.statusCheckNames, undefined);
    const mergePolicy = config.packageRules.at(-1);
    assert.equal(mergePolicy.automerge, true);
    assert.deepEqual(Array.from(mergePolicy.matchUpdateTypes), ["minor", "patch", "digest"]);
    for (const file of ["package.json", "home/dot_config/dotfiles/package.json"]) {
      assert(config.npm.fileMatch.some(pattern => new RegExp(pattern).test(file)), file);
    }

    const miseFile = "home/dot_config/mise/config.toml.tmpl";
    const aqua = config.customManagers.find(manager =>
      manager.matchStrings.some(pattern => pattern.includes("aqua:")));
    assert(aqua.fileMatch.some(pattern => new RegExp(pattern).test(miseFile)));
    const mise = readFileSync(join(root, miseFile), "utf8");
    const envsense = [...mise.matchAll(new RegExp(aqua.matchStrings[0], "g"))]
      .find(match => match.groups.depName === "technicalpickles/envsense");
    assert(envsense);
    assert.match(envsense.groups.currentValue, /^v?\d+\.\d+\.\d+$/);

    const file = "home/.chezmoiexternals/zellij.externals.toml";
    const contents = readFileSync(join(root, file), "utf8");
    const managers = config.customManagers.filter(manager =>
      manager.fileMatch?.some(pattern => new RegExp(pattern).test(file)));
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

@test "Renovate separates read-only validation from App-authenticated writes" {
  command -v bun >/dev/null 2>&1 || skip "Bun is not installed"
  run env REPO_ROOT="$BATS_TEST_DIRNAME/.." bun --eval '
    import { strict as assert } from "node:assert";
    import { readFileSync } from "node:fs";
    import { join } from "node:path";

    const workflow = Bun.YAML.parse(readFileSync(join(process.env.REPO_ROOT, ".github/workflows/renovate.yml"), "utf8"));
    assert.equal(workflow.on.workflow_dispatch.inputs.dry_run.default, true);
    assert(workflow.on.schedule.length);
    assert(Object.values(workflow.permissions).every(permission => permission === "read"));
    const job = workflow.jobs.renovate;
    assert(job.if.includes("vars.RENOVATE_APP_ID"));
    assert.equal(job.env.RENOVATE_TOKEN, undefined);
    const dry = job.steps.find(step => step.env?.RENOVATE_DRY_RUN);
    const token = job.steps.find(step => step.id === "app-token");
    const live = job.steps.find(step => step.env?.RENOVATE_TOKEN?.includes("app-token.outputs.token"));
    assert.equal(dry.env.RENOVATE_TOKEN, "${{ github.token }}");
    assert.equal(dry.env.RENOVATE_DRY_RUN, "full");
    assert.equal(live.env.RENOVATE_DRY_RUN, undefined);
    assert.equal(live.if, token.if);
    // Omitting owner and repositories scopes the token to the current repository.
    assert.equal(token.with.owner, undefined);
    assert.equal(token.with.repositories, undefined);
    assert.equal(token.with["permission-workflows"], "write");
    assert.equal(token.with["permission-vulnerability-alerts"], "read");
  '
  printf '%s\n' "$output"
  [ "$status" -eq 0 ]
}
