# Download trust

Checksums pin bytes; signatures bind bytes to a trusted publisher. Neither proves that
publisher's code is safe. A correctly signed malicious release remains possible.

## Decisions

- Zellij WASM plugins run downloaded code. Pin SHA256 as well as the release URL;
  a mutable GitHub asset must not silently replace an accepted plugin. Renovate's
  `github-release-attachments` datasource updates the URL and digest together.
  CI downloads both assets and checks their hashes. These upstream releases have
  no verified build attestations: initially accepting their hashes is still a
  trust decision, not proof of their origin.
- Prefer current authenticated critical tools over a blanket delay. Precompiled
  CPython has no age delay and requires GitHub artifact attestations; source-build
  fallback is disabled. Mise self-update also has no delay: its signed packslip
  manifest enforces publisher/repository/workflow continuity. These are practical
  authenticity checks, not a universal SLSA build-provenance gate. Python does not
  pin an exact workflow or attestation predicate, and packslip does not verify
  linked build provenance. Package-manager updates of mise use their own policy.
- Hold other mise, Bun, uv and Renovate selections back seven days. This gives
  incident reports time to appear, but is not malware detection. Explicit mise
  pins and existing locks bypass its release-age selection filter, and mise
  cannot filter releases whose timestamp it does not know. Renovate checks daily
  and checks the age when proposing new versions. Urgent fixes need an explicit
  reviewed override.
- Keep signature and provenance checks enabled. Recheck supported provenance on
  mise downloads even when a lockfile records a previous verification. Aqua's
  checks depend on the package's registry entry; enabled verification does not
  require every upstream to publish attestations.
- Do not automatically merge tooling, image or executable dependency updates.
  Hashes and signatures do not make patch releases intrinsically safe. Tests and
  provenance changes still need review.
- Bootstrap verification must start with a trust root in this checkout, not a
  key fetched beside the binary. Key changes need independent verification and
  manual review; never "fix" a failure by fetching whatever key the release uses.

## Deliberately left out

Global mise tools use exact versions, but there is no reviewed multi-platform
lockfile for the global configuration yet. The project lockfile does
not lock the tools installed into the user's home directory. Enforcing locked
mode before those files and their refresh path exist would break fresh installs.

Bun's global installs and uv's isolated tool installs still resolve transitive
dependencies without a committed dependency graph. Release delays reduce exposure
but do not replace frozen hash-locked environments. Migrating these installations
needs a separate update design, not hashes appended to top-level requirements.

OS packages trust their distribution's repositories. Other downloads and upstream
self-updaters do not automatically inherit mise's policy. Prime's remote bootstrap
still executes its official installer; this change does not authenticate that
installer independently. Existing installed binaries are not reverified by these
controls.

Sources: [mise security](https://mise.jdx.dev/security.html),
[mise locks](https://mise.jdx.dev/dev-tools/mise-lock.html),
[Renovate release attachments](https://docs.renovatebot.com/modules/datasource/github-release-attachments/).
