# Bootstrap release trust

GitHub release assets cannot supply their own trust anchor. The installer keeps reviewed
upstream public keys in `keys/` and never replaces them from a release download:

- `cosign-release.pub`: Sigstore's ECDSA release KMS key, from
  [`release/release-cosign.pub`](https://github.com/sigstore/cosign/blob/9204f4e6a7c2993b00f20658ba88261ea55494f4/release/release-cosign.pub).
- `chezmoi-cosign.pub`: chezmoi's signing key, from
  [`assets/cosign/cosign.pub`](https://github.com/twpayne/chezmoi/blob/993b367ae80f7d45f4b913207477a448c1a8a686/assets/cosign/cosign.pub).
- `mise-archive.asc`: mise's APT/release key, downloaded from
  <https://mise.jdx.dev/gpg-key.pub> and checked against the fingerprint documented
  in upstream's [installation instructions](https://github.com/jdx/mise/blob/35c67aa1bc5a7c5c8d174f4023e8460c0b98632c/docs/installing-mise.md):
  `24853EC9F655CE80B48E6C3A8B81C9D17413A06D`.

These commit links record key provenance, not dependencies that Renovate should
advance. Key rotations require manual review against upstream's announcement and
source history. A new key published beside an artifact is not sufficient evidence.
The mise key currently expires in January 2028. Its expiry extension or replacement
also needs manual review; the installer will not refresh it from the network.

The mise APT path dearmors the vendored key before configuring `signed-by` for its
repository. A failed key import cannot create the repository entry. The old live
key download would have let a compromised key endpoint authorize root packages.

Cosign must be trusted before it can verify chezmoi. OS packages remain preferred.
For direct downloads, OpenSSL verifies the ECDSA/SHA-256 signature over the exact
binary before it is made executable. Cosign v2 publishes a detached `.sig`; v3
publishes the same release-key signature inside `-kms.sigstore.json`. Reading that
bundle requires jq. This checks the pinned public key, not identities, timestamps,
or transparency-log proofs from the bundle. No downloaded verifier is run to
verify itself.

Missing tools, signatures, invalid signatures, or a changed format stop the direct
installation. Install OpenSSL and (for v3) jq, or install cosign through a trusted
OS package manager before retrying. Do not bypass verification to recover from a
key rotation. Existing `COSIGN_VERSION` Renovate updates remain usable for v2 and
v3 without a separate bootstrap-version pin or per-platform digest table.

Chezmoi's signed checksum manifest uses the separately vendored chezmoi key. The
archive must have exactly one matching SHA-256 entry before extraction. Setting
`VERIFY_SIGNATURES=false` skips chezmoi signature authentication only; archive
checksums still run. This opt-out does not weaken cosign's own download check.

Offline Bats tests sign local fixtures with temporary ECDSA keys and exercise v2,
v3, tampering, untrusted keys, missing tools, and checksum failures. The production
verifier was also checked against the real Linux amd64 v2.5.3 and v3.1.4 cosign
release binaries without executing either binary. Other supported release
platforms use the same verification path; unavailable assets fail closed.
