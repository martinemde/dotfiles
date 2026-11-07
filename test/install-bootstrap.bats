#!/usr/bin/env bats

# Offline behavioral tests: only temporary binaries and keys are created.
setup() {
    export FIXTURE="$BATS_TEST_TMPDIR/bootstrap"
    mkdir -p "$FIXTURE/repo/keys" "$FIXTURE/bin" "$FIXTURE/downloads"
    sed '$d' "$BATS_TEST_DIRNAME/../install.sh" > "$FIXTURE/repo/install.sh"
    cp "$BATS_TEST_DIRNAME/../keys/chezmoi-cosign.pub" "$FIXTURE/repo/keys/"
    cp "$BATS_TEST_DIRNAME/../keys/mise-archive.asc" "$FIXTURE/repo/keys/"
    openssl ecparam -name prime256v1 -genkey -noout -out "$FIXTURE/signing.key" 2>/dev/null
    openssl pkey -in "$FIXTURE/signing.key" -pubout -out "$FIXTURE/repo/keys/cosign-release.pub" 2>/dev/null
    printf '#!/bin/sh\necho fixture-cosign\n' > "$FIXTURE/artifact"
    openssl dgst -sha256 -sign "$FIXTURE/signing.key" -out "$FIXTURE/signature.der" "$FIXTURE/artifact"
    openssl base64 -A -in "$FIXTURE/signature.der" > "$FIXTURE/signature"
    jq -n --arg signature "$(cat "$FIXTURE/signature")" \
        '{messageSignature: {messageDigest: {algorithm: "SHA2_256"}, signature: $signature}}' > "$FIXTURE/bundle"
    export SIGNATURE_FORMAT=v2 MISSING_TOOL=none
    cat > "$FIXTURE/run.sh" <<'EOF'
. "$0"
trap - EXIT INT TERM
BIN_DIR="$FIXTURE/bin"
temp_dir="$FIXTURE/downloads"
COSIGN_VERSION=vtest
CHEZMOI_VERSION=test
VERIFY_SIGNATURES="${FIXTURE_VERIFY_SIGNATURES:-true}"
REINSTALL_TOOLS=true
SKIP_PACKAGE_MANAGER=true
get_download_cmd() { echo fixture_download; }
detect_system() { echo linux_amd64; }
try_package_install() { return 1; }
# Hide optional tools without changing the environment used by OpenSSL or jq.
command() {
  if [ "$1" = -v ]; then
    if [ "${APT_FIXTURE:-false}" = true ]; then
      case "$2" in
        brew) return 1 ;;
        apt-get) return 0 ;;
      esac
    fi
    [ "$2" != "$MISSING_TOOL" ] && type "$2" >/dev/null 2>&1
  else
    "$@"
  fi
}
fixture_download() {
  printf '%s\n' "$1" >> "$FIXTURE/requests"
  case "$1" in
    */cosign-linux-amd64) cat "$FIXTURE/artifact" ;;
    */cosign-linux-amd64.sig)
      [ "$SIGNATURE_FORMAT" = v2 ] || return 1
      cat "$FIXTURE/signature" ;;
    */cosign-linux-amd64-kms.sigstore.json) cat "$FIXTURE/bundle" ;;
    */chezmoi_test_linux_amd64.tar.gz) cat "$FIXTURE/chezmoi.tar.gz" ;;
    */chezmoi_test_checksums.txt) cat "$FIXTURE/checksums" ;;
    */chezmoi_test_checksums.txt.sigstore.json) printf '{}\n' ;;
    *) return 1 ;;
  esac
}
case "$1" in
  cosign) install_cosign ;;
  mise)
    APT_FIXTURE=true
    run_with_sudo() {
      printf '%s\n' "$*" >> "$FIXTURE/apt-commands"
      case "$1" in
        apt-get | install) return 0 ;;
        tee) cat > "$FIXTURE/$(basename "$2")" ;;
        *) return 1 ;;
      esac
    }
    try_package_install() {
      [ "$1" = mise ] && [ "$2" = apt ]
    }
    install_mise ;;
  chezmoi | install-chezmoi)
    cosign() {
      # The verifier must receive the vendored key, never a downloaded key.
      while [ "$#" -gt 0 ]; do
        if [ "$1" = --key ]; then
          [ "$2" = "$script_dir/keys/chezmoi-cosign.pub" ] || return 1
          cmp "$2" "$FIXTURE/expected-chezmoi.pub" || return 1
          return "${COSIGN_VERIFY_STATUS:-0}"
        fi
        shift
      done
      return 1
    }
    if [ "$1" = install-chezmoi ]; then
      CHEZMOI_VERSION="${FIXTURE_CHEZMOI_VERSION:-test}"
      REINSTALL_TOOLS=false
      SKIP_PACKAGE_MANAGER=false
      PATH="$BIN_DIR:$PATH"
      command() {
        if [ "$1" = -v ] && [ "$2" = chezmoi ]; then
          [ -x "$BIN_DIR/chezmoi" ] || return 1
          printf '%s\n' "$BIN_DIR/chezmoi"
        elif [ "$1" = -v ]; then
          type "$2" >/dev/null 2>&1
        else
          "$@"
        fi
      }
      try_package_manager() {
        printf 'package-manager\n' >> "$FIXTURE/package-installs"
        cp "$FIXTURE/chezmoi" "$BIN_DIR/chezmoi"
        chmod +x "$BIN_DIR/chezmoi"
      }
      install_chezmoi
    else
      download_chezmoi
    fi ;;
  checksum)
    cd "$FIXTURE"
    verify_checksum artifact checksums ;;
esac
EOF
}

bootstrap() {
    sh -c '. "$FIXTURE/run.sh"' "$FIXTURE/repo/install.sh" "$1"
}

@test "cosign v2 detached signature authenticates bytes before installation" {
    run bootstrap cosign
    [ "$status" -eq 0 ]
    cmp "$FIXTURE/artifact" "$FIXTURE/bin/cosign"
    [ -x "$FIXTURE/bin/cosign" ]
}

@test "cosign v3 KMS bundle authenticates bytes against the same trusted key" {
    export SIGNATURE_FORMAT=v3
    run bootstrap cosign
    [ "$status" -eq 0 ]
    cmp "$FIXTURE/artifact" "$FIXTURE/bin/cosign"
    [ -x "$FIXTURE/bin/cosign" ]
}

@test "tampered cosign bytes fail closed for both release formats" {
    printf 'tampered\n' >> "$FIXTURE/artifact"
    for SIGNATURE_FORMAT in v2 v3; do
        export SIGNATURE_FORMAT
        run bootstrap cosign
        [ "$status" -ne 0 ]
        [ ! -e "$FIXTURE/bin/cosign" ]
        [[ "$output" == *"signature verification failed"* ]]
    done
}

@test "an attacker key cannot authenticate either cosign release format" {
    openssl ecparam -name prime256v1 -genkey -noout -out "$FIXTURE/other.key" 2>/dev/null
    openssl pkey -in "$FIXTURE/other.key" -pubout -out "$FIXTURE/repo/keys/cosign-release.pub" 2>/dev/null
    for SIGNATURE_FORMAT in v2 v3; do
        export SIGNATURE_FORMAT
        run bootstrap cosign
        [ "$status" -ne 0 ]
        [ ! -e "$FIXTURE/bin/cosign" ]
    done
}

@test "bad detached signature does not downgrade to a bundle" {
    printf 'invalid signature\n' > "$FIXTURE/signature"
    run bootstrap cosign
    [ "$status" -ne 0 ]
    [ ! -e "$FIXTURE/bin/cosign" ]
    ! grep -q 'kms.sigstore.json' "$FIXTURE/requests"
}

@test "malformed KMS bundles fail closed" {
    export SIGNATURE_FORMAT=v3
    for bundle in 'not JSON' '{}' '{"messageSignature":{"messageDigest":{"algorithm":"SHA2_512"},"signature":"AAAA"}}'; do
        printf '%s\n' "$bundle" > "$FIXTURE/bundle"
        run bootstrap cosign
        [ "$status" -ne 0 ]
        [ ! -e "$FIXTURE/bin/cosign" ]
    done
}

@test "missing bootstrap verification tools give actionable errors" {
    for MISSING_TOOL in openssl jq; do
        export MISSING_TOOL SIGNATURE_FORMAT=v3
        run bootstrap cosign
        [ "$status" -ne 0 ]
        [ ! -e "$FIXTURE/bin/cosign" ]
        [[ "$output" == *"trusted package manager"* ]]
    done
}

chezmoi_fixture() {
    cp "$FIXTURE/repo/keys/chezmoi-cosign.pub" "$FIXTURE/expected-chezmoi.pub"
    printf '#!/bin/sh\necho fixture-chezmoi\n' > "$FIXTURE/chezmoi"
    tar -czf "$FIXTURE/chezmoi.tar.gz" -C "$FIXTURE" chezmoi
    (cd "$FIXTURE" && shasum -a 256 chezmoi.tar.gz) | sed 's/chezmoi.tar.gz/chezmoi_test_linux_amd64.tar.gz/' > "$FIXTURE/checksums"
}

@test "chezmoi uses the independently vendored key and verifies archive checksum" {
    chezmoi_fixture
    run bootstrap chezmoi
    [ "$status" -eq 0 ]
    cmp "$FIXTURE/chezmoi" "$FIXTURE/bin/chezmoi"
    ! grep -q 'chezmoi_cosign.pub' "$FIXTURE/requests"
}

@test "chezmoi signature failure prevents extraction" {
    chezmoi_fixture
    export COSIGN_VERIFY_STATUS=1
    run bootstrap chezmoi
    [ "$status" -ne 0 ]
    [ ! -e "$FIXTURE/bin/chezmoi" ]
}

@test "chezmoi still rejects a bad checksum when signature verification is disabled" {
    chezmoi_fixture
    printf 'tampered\n' >> "$FIXTURE/chezmoi.tar.gz"
    export FIXTURE_VERIFY_SIGNATURES=false
    run bootstrap chezmoi
    [ "$status" -ne 0 ]
    [ ! -e "$FIXTURE/bin/chezmoi" ]
    [[ "$output" == *"Checksum verification failed"* ]]
}

@test "checksum manifest must contain exactly the requested archive" {
    (cd "$FIXTURE" && shasum -a 256 artifact) > "$FIXTURE/checksums"
    run bootstrap checksum
    [ "$status" -eq 0 ]
    cp "$FIXTURE/checksums" "$FIXTURE/good-checksums"
    sed 's/artifact/other-file/' "$FIXTURE/good-checksums" > "$FIXTURE/checksums"
    run bootstrap checksum
    [ "$status" -ne 0 ]
    cat "$FIXTURE/good-checksums" "$FIXTURE/good-checksums" > "$FIXTURE/checksums"
    run bootstrap checksum
    [ "$status" -ne 0 ]
}

@test "checksum verification works with the macOS shasum fallback" {
    (cd "$FIXTURE" && shasum -a 256 artifact) > "$FIXTURE/checksums"
    export MISSING_TOOL=sha256sum
    run bootstrap checksum
    [ "$status" -eq 0 ]
    printf 'tampered\n' >> "$FIXTURE/artifact"
    run bootstrap checksum
    [ "$status" -ne 0 ]
}

@test "mise APT bootstrap imports only the vendored repository key" {
    run bootstrap mise
    [ "$status" -eq 0 ]
    [ ! -e "$FIXTURE/requests" ]
    gpg --batch --yes --dearmor --output "$FIXTURE/expected.gpg" "$FIXTURE/repo/keys/mise-archive.asc"
    cmp "$FIXTURE/expected.gpg" "$FIXTURE/mise-archive-keyring.gpg"
    grep -q 'signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg' "$FIXTURE/mise.list"
}

@test "invalid vendored mise key cannot configure the APT repository" {
    printf 'invalid key\n' > "$FIXTURE/repo/keys/mise-archive.asc"
    run bootstrap mise
    [ "$status" -ne 0 ]
    [ ! -e "$FIXTURE/mise.list" ]
    [ ! -e "$FIXTURE/mise-archive-keyring.gpg" ]
}

@test "fresh pinned chezmoi installation bypasses package managers and verifies release bytes" {
    chezmoi_fixture
    run bootstrap install-chezmoi
    [ "$status" -eq 0 ]
    [ ! -e "$FIXTURE/package-installs" ]
    cmp "$FIXTURE/chezmoi" "$FIXTURE/bin/chezmoi"
    grep -q '/download/vtest/chezmoi_test_linux_amd64.tar.gz' "$FIXTURE/requests"
}

@test "fresh pinned chezmoi installation cannot bypass failed signature verification" {
    chezmoi_fixture
    export COSIGN_VERIFY_STATUS=1
    run bootstrap install-chezmoi
    [ "$status" -ne 0 ]
    [ ! -e "$FIXTURE/package-installs" ]
    [ ! -e "$FIXTURE/bin/chezmoi" ]
}

@test "latest chezmoi request may use an unversioned package manager" {
    chezmoi_fixture
    export FIXTURE_CHEZMOI_VERSION=latest
    run bootstrap install-chezmoi
    [ "$status" -eq 0 ]
    [ -e "$FIXTURE/package-installs" ]
    [ ! -e "$FIXTURE/requests" ]
}

@test "existing chezmoi is preserved without reconciling the requested pin" {
    chezmoi_fixture
    printf '#!/bin/sh\necho existing-version\n' > "$FIXTURE/bin/chezmoi"
    chmod +x "$FIXTURE/bin/chezmoi"
    cp "$FIXTURE/bin/chezmoi" "$FIXTURE/existing"
    run bootstrap install-chezmoi
    [ "$status" -eq 0 ]
    cmp "$FIXTURE/existing" "$FIXTURE/bin/chezmoi"
    [ ! -e "$FIXTURE/package-installs" ]
    [ ! -e "$FIXTURE/requests" ]
}
