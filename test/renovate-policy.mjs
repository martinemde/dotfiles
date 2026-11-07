import assert from 'node:assert/strict';
import { readFile, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';

// Internal APIs are intentionally pinned to the deployed Renovate Docker image.
const engine = process.env.RENOVATE_DIST ?? '/usr/local/renovate/dist';
const load = (path) => import(`${engine}/${path}.js`);
const { getConfig } = await load('config/defaults');
const { GlobalConfig } = await load('config/global');
const { mergeChildConfig } = await load('config/utils');
const { resolveConfigPresets } = await load('config/presets/index');
const { parseJson } = await load('util/common');
const { flattenUpdates } = await load('workers/repository/updates/flatten');
const { applyPackageRules } = await load('util/package-rules/index');
const { extractPackageFile: extractMise } = await load('modules/manager/mise/extract');
const { extractPackageFile: extractPreset } = await load('modules/manager/renovate-config/extract');
const { extractPackageFile: extractJsonata } = await load('modules/manager/custom/jsonata/index');
const { extractPackageFile: extractRegex } = await load('modules/manager/custom/regex/index');
const { parse: parseToml } = await load('util/toml');
const { parseYaml } = await load('util/yaml');
const { matchRegexOrGlob } = await load('util/string-match');
const { init: initLogger } = await load('logger/index');
initLogger();
const root = new URL('../', import.meta.url);
const read = (path) => readFile(new URL(path, root), 'utf8');
GlobalConfig.set({ localDir: fileURLToPath(root) });
const source = await read('renovate.json5');
const local = parseJson(source, 'renovate.json5');
const presetRef = 'github>martinemde/renovate-config#v1.0.0';
assert.deepEqual(local.extends, [presetRef]);
if (process.env.LOCAL_PRESET_PATH) {
  // Prepublication only: seed the normal resolver cache, not a second policy copy.
  const { init, set } = await load('util/cache/memory/index');
  init();
  const { buildCacheKey } = await load('util/cache/package/key');
  set(buildCacheKey('preset', presetRef), JSON.parse(await readFile(process.env.LOCAL_PRESET_PATH, 'utf8')));
}
const { config: resolved, visitedPresets } = await resolveConfigPresets(local);
assert.ok(visitedPresets.merged.includes(presetRef));
const config = mergeChildConfig(getConfig(), resolved);
if (process.env.OUTPUT_CONFIG) await writeFile(process.env.OUTPUT_CONFIG, JSON.stringify(resolved, null, 2) + '\n');

const miseFile = 'home/dot_config/mise/config.toml';
assert.ok(config.enabledManagers.includes('mise'));
assert.ok(!config.customManagers.some(manager => manager.matchStrings.some(pattern => pattern.includes('aqua:'))), 'native mise replaces duplicate aqua regex');
const miseText = await read(miseFile);
const mise = await extractMise(miseText, miseFile);
assert.equal(Object.keys(parseToml(miseText).tools).length, 44);
assert.equal(mise.deps.length, 44, 'all tools, including tool-options tables');
assert.ok(mise.deps.every(dep => !dep.skipReason && dep.datasource && dep.currentValue), 'all mise tools have supported datasources');
assert.equal(new Set(mise.deps.map(dep => dep.depName)).size, 44);
const eza = mise.deps.find(dep => dep.depName === 'aqua:eza-community/eza' || dep.packageName === 'eza-community/eza');
assert.ok(eza, 'eza tool-options table is extracted');
assert.equal(eza.currentValue, parseToml(miseText).tools['aqua:eza-community/eza'].version);

const miseVersionManager = config.customManagers.find(manager => manager.depNameTemplate === 'jdx/mise');
const miseConstraint = await extractRegex(source, 'renovate.json5', miseVersionManager);
const ciFile = '.github/workflows/ci.yml';
const ciMise = await extractRegex(await read(ciFile), ciFile, miseVersionManager);
assert.equal(miseConstraint.deps.length, 1, 'mise constraint is extracted');
assert.equal(ciMise.deps.length, 3, 'all three CI mise-action inputs are extracted');
for (const dep of [...miseConstraint.deps, ...ciMise.deps]) {
  assert.equal(dep.depName, 'jdx/mise');
  assert.equal(dep.datasource, 'github-releases');
  assert.equal(dep.currentValue, local.constraints.mise, 'constraint and CI use the same mise release');
}

const bootstrapFile = '.mise.toml';
assert.ok(config.mise.managerFilePatterns.some(pattern => matchRegexOrGlob(bootstrapFile, pattern)), 'root bootstrap manifest is discovered');
assert.ok(config.mise.managerFilePatterns.some(pattern => matchRegexOrGlob(miseFile, pattern)), 'global mise manifest is discovered');
const bootstrap = await extractMise(await read(bootstrapFile), bootstrapFile);
const bootstrapChezmoi = bootstrap.deps.find(dep => dep.depName === 'chezmoi');
assert.ok(bootstrapChezmoi && !bootstrapChezmoi.skipReason);
const cliFile = 'home/dot_config/dotfiles/cli-versions.toml';
const chezmoiManager = config.customManagers.find(manager => manager.depNameTemplate === 'twpayne/chezmoi');
const cliChezmoi = (await extractRegex(await read(cliFile), cliFile, chezmoiManager)).deps[0];
assert.equal(bootstrapChezmoi.currentValue, cliChezmoi.currentValue, 'bootstrap chezmoi matches installer manifest');
assert.equal(bootstrapChezmoi.packageName ?? bootstrapChezmoi.depName, cliChezmoi.packageName ?? cliChezmoi.depName, 'both pins resolve to the same dependency');
// Renovate's native mise registry uses tags; the installer pin uses releases.
assert.equal(bootstrapChezmoi.datasource, 'github-tags');
assert.equal(cliChezmoi.datasource, 'github-releases');
for (const [manager, packageFile, dep] of [['mise', bootstrapFile, bootstrapChezmoi], ['custom.regex', cliFile, cliChezmoi]]) {
  const effective = await update(manager, packageFile, dep);
  assert.equal(effective.groupName, 'chezmoi', 'both chezmoi pins share an update group');
}

const tmuxFile = 'home/.chezmoidata/tmux-plugins.yaml';
const tmuxManager = config.customManagers.find(manager => manager.customType === 'jsonata' && manager.managerFilePatterns.some(pattern => matchRegexOrGlob(tmuxFile, pattern)));
assert.equal(tmuxManager.fileFormat, 'yaml');
const tmuxText = await read(tmuxFile);
const tmux = await extractJsonata(tmuxText, tmuxFile, tmuxManager);
assert.deepEqual(tmux.deps.map(({depName, currentValue, currentDigest, datasource}) => ({depName, currentValue, currentDigest, datasource})),
  parseYaml(tmuxText)[0].tmuxPlugins.map(({repo, branch, commit}) => ({ depName: repo, currentValue: branch, currentDigest: commit, datasource: 'github-digest' })));
const preset = extractPreset(source, 'renovate.json5').deps.find(dep => dep.depName === 'martinemde/renovate-config');
assert.ok(config.enabledManagers.includes('renovate-config'));
assert.equal(preset.datasource, 'github-tags');
assert.equal(preset.currentValue, 'v1.0.0');

async function update(manager = 'mise', packageFile = miseFile, dep = mise.deps[0], overrides = {}) {
  const [result] = await flattenUpdates(config, {
    [manager]: [{ packageFile, deps: [{ ...dep, packageName: dep.packageName ?? dep.depName, currentVersion: '1.0.0', updates: [{ updateType: 'minor', newValue: '1.1.0', newVersion: '1.1.0', ...overrides }] }] }],
  });
  assert.ok(result);
  return result;
}
for (const updateType of ['minor', 'patch', 'digest', 'major']) {
  const effective = await update('mise', miseFile, mise.deps[0], { updateType });
  assert.equal(effective.automerge, true, updateType);
  assert.equal(effective.platformAutomerge, false);
  assert.equal(effective.automergeType, 'pr');
  assert.equal(effective.automergeStrategy, 'squash');
}
for (const depName of ['jdx/mise', 'twpayne/chezmoi', 'astral-sh/uv', 'oven-sh/bun']) {
  const effective = await update('custom.regex', 'versions.toml', {depName, datasource: 'github-releases', currentValue: '1.0.0'});
  assert.equal(effective.minimumReleaseAge, '12 hours', depName);
}
assert.equal((await update()).minimumReleaseAge, '7 days', 'ordinary tools retain the default delay');
for (const updateType of ['minor', 'patch', 'digest', 'major']) {
  assert.equal((await update('mise', miseFile, mise.deps[0], { updateType, isVulnerabilityAlert: true, automerge: true })).automerge, false, `security ${updateType}`);
}
for (const file of ['home/.chezmoiexternals/pi.externals.toml', 'home/dot_pi/private_agent/settings.json', 'home/.chezmoiexternals/zellij.externals.toml']) {
  assert.equal((await update('custom.regex', file, {depName: 'example/plugin', datasource: 'github-releases', currentValue: '1.0.0'})).automerge, true, file);
}
assert.equal((await update('renovate-config', 'renovate.json5', preset)).automerge, false);
const misePolicy = await applyPackageRules({ ...config, manager: 'mise', packageFile: miseFile, depName: mise.deps[0].depName });
assert.equal(misePolicy.lockFileMaintenance.enabled, false, 'global mise lock maintenance stays disabled');

const zellijFile = 'home/.chezmoiexternals/zellij.externals.toml';
const zellijText = await read(zellijFile);
const matchingManagers = config.customManagers.filter(manager => manager.managerFilePatterns.some(pattern => matchRegexOrGlob(zellijFile, pattern)));
assert.equal(matchingManagers.length, 1, 'no competing URL-only updater');
const zellijManager = matchingManagers[0];
assert.equal(zellijManager.datasourceTemplate, 'github-release-attachments');
const zellij = await extractRegex(zellijText, zellijFile, zellijManager);
const externals = Object.values(parseToml(zellijText));
assert.equal(zellij.deps.length, externals.length);
for (const dep of zellij.deps) {
  const original = externals.find(external => external.url.includes(`/${dep.depName}/releases/download/${dep.currentValue}/`));
  assert.ok(original, dep.depName);
  assert.equal(dep.currentDigest, original.checksum.sha256);
  assert.ok(dep.replaceString.includes(dep.currentValue) && dep.replaceString.includes(dep.currentDigest), 'one replacement includes URL version and checksum');
  const replacement = dep.replaceString.replace(dep.currentValue, 'v99.0.0').replace(dep.currentDigest, 'a'.repeat(64));
  const changed = Object.values(parseToml(zellijText.replace(dep.replaceString, replacement))).filter(external => external.checksum.sha256 === 'a'.repeat(64));
  assert.equal(changed.length, 1);
  assert.ok(changed[0].url.includes('/releases/download/v99.0.0/'));
}
console.log('Policy behavior passed: shared preset, 44 native mise tools, tmux JSONata, preset discovery, automerge/review exceptions, disabled mise lock maintenance, paired Zellij checksums.');
