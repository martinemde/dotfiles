#!/bin/sh
#
# install.sh -- Chezmoi Dotfiles Installer
#
# This script installs Chezmoi (https://chezmoi.io) and initializes your
# dotfiles from this repository. It follows security best practices:
#   - Installs cosign for signature verification
#   - Tries package managers first (Homebrew, apt, dnf, pacman, apk)
#   - Downloads from GitHub releases with proper signature verification
#   - Uses cosign to verify downloaded binaries
#
# HOW TO USE:
#   1. Clone this repository: git clone https://github.com/ivy/dotfiles.git
#   2. Run the installer: ./install.sh
#   3. The script will:
#      - Install Chezmoi to ~/.local/bin
#      - Initialize your dotfiles from this repo
#      - Apply all configurations automatically
#
# ENVIRONMENT VARIABLES:
#   CHEZMOI_VERSION: Override the version to install (default: latest)
#   COSIGN_VERSION: Override the cosign version to install (default: latest)
#   BIN_DIR: Override installation directory (default: ~/.local/bin)
#   VERIFY_SIGNATURES: Disable signature verification (default: true)
#   SKIP_PACKAGE_MANAGER: Force binary download (default: false)
#   DEBUG: Enable debug output
#
# EXAMPLE USAGE:
#   $ git clone https://github.com/ivy/dotfiles.git
#   $ cd dotfiles
#   $ ./install.sh
#   Installing Chezmoi to /home/user/.local/bin...
#   Chezmoi installed successfully
#   Initializing dotfiles from /home/user/dotfiles...
#   [Chezmoi output showing applied configurations]

# =============================================================================
# CONFIGURATION AND CONSTANTS
# =============================================================================

[ -n "${DEBUG:-}" ] && set -o xtrace
set -o errexit
set -o nounset

# URLs and constants
readonly CHEZMOI_REPO="twpayne/chezmoi"
readonly COSIGN_REPO="sigstore/cosign"
readonly GITHUB_API_URL="https://api.github.com"
readonly GITHUB_RELEASES_URL="https://github.com"

# Get the directory where this script is located
script_dir_temp="$(cd "$(dirname "$0")" && pwd)"
readonly script_dir="$script_dir_temp"

# =============================================================================
# ENVIRONMENT SETUP AND VALIDATION
# =============================================================================

# Create temporary directory for downloads
temp_dir=""

# Set up cleanup trap
cleanup() {
  # Clean up temporary directory
  if [ -n "$temp_dir" ] && [ -d "$temp_dir" ]; then
    log_debug "Cleaning up temporary directory: $temp_dir"
    rm -rf "$temp_dir"
  fi
}
trap cleanup EXIT INT TERM

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

log_info() {
  printf "\033[32m[INFO]\033[0m %s\n" "$*" >&2
}

log_error() {
  printf "\033[31m[ERROR]\033[0m %s\n" "$*" >&2
}

log_debug() {
  if [ -n "${DEBUG:-}" ]; then
    printf "\033[36m[DEBUG]\033[0m %s\n" "$*" >&2
  fi
}

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

# Parse command line arguments
parse_arguments() {
  # Store all arguments for passthrough to chezmoi init
  CHEZMOI_ARGS=""

  while [ $# -gt 0 ]; do
    case $1 in
    --help | -h)
      cat <<'EOF'
Chezmoi Dotfiles Installer

USAGE:
    ./install.sh [OPTIONS] [-- CHEZMOI_ARGS...]

OPTIONS:
    --help, -h  Show this help message

ENVIRONMENT VARIABLES:
    REINSTALL_TOOLS        Force reinstallation even if tools are already installed (default: false)
    CHEZMOI_VERSION         Override the version to install (default: latest)
    COSIGN_VERSION          Override the cosign version to install (default: latest)
    BIN_DIR                 Override installation directory (default: ~/.local/bin)
    VERIFY_SIGNATURES       Disable signature verification (default: true)
    SKIP_PACKAGE_MANAGER    Force binary download (default: false)
    DEBUG                   Enable debug output

EXAMPLES:
    ./install.sh                                    # Install normally
    REINSTALL_TOOLS=true ./install.sh               # Force reinstall everything
    ./install.sh -- --force                         # Pass --force to chezmoi init
    ./install.sh -- --one-shot                      # Use chezmoi one-shot mode
    DEBUG=1 ./install.sh                            # Install with debug output
    BIN_DIR=/usr/local/bin ./install.sh             # Install to custom directory

EOF
      exit 0
      ;;
    --)
      shift
      CHEZMOI_ARGS="$CHEZMOI_ARGS $*"
      break
      ;;
    *)
      CHEZMOI_ARGS="$CHEZMOI_ARGS $1"
      shift
      ;;
    esac
  done
}

# =============================================================================
# ENVIRONMENT VALIDATION
# =============================================================================

setup_environment() {
  log_debug "Setting up environment..."

  # Create temporary directory for downloads
  temp_dir="$(mktemp -d)"
  if [ ! -d "$temp_dir" ]; then
    log_error "Failed to create temporary directory"
    exit 1
  fi
  log_debug "Created temporary directory: $temp_dir"

  # Ensure BIN_DIR exists
  if ! mkdir -p "$BIN_DIR"; then
    log_error "Failed to create directory: $BIN_DIR"
    exit 1
  fi

  # Validate required tools
  if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    log_error "Neither curl nor wget is available"
    exit 1
  fi

  log_debug "Environment setup complete"
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Function to detect available download tool
get_download_cmd() {
  if command -v curl >/dev/null 2>&1; then
    echo "curl -fsSL"
  elif command -v wget >/dev/null 2>&1; then
    echo "wget -qO-"
  else
    log_error "Neither curl nor wget is available"
    exit 1
  fi
}

# Function to detect OS and architecture
detect_system() {
  # Detect OS
  case "$(uname -s)" in
  Linux*) os="linux" ;;
  Darwin*) os="darwin" ;;
  FreeBSD*) os="freebsd" ;;
  OpenBSD*) os="openbsd" ;;
  *)
    log_error "Unsupported operating system: $(uname -s)"
    log_error "Supported systems: Linux, Darwin (macOS), FreeBSD, OpenBSD"
    exit 1
    ;;
  esac

  # Detect architecture
  case "$(uname -m)" in
  x86_64 | amd64) arch="amd64" ;;
  aarch64 | arm64) arch="arm64" ;;
  armv7l | armv8l) arch="arm" ;;
  i386 | i686) arch="i386" ;;
  ppc64) arch="ppc64" ;;
  ppc64le) arch="ppc64le" ;;
  s390x) arch="s390x" ;;
  riscv64) arch="riscv64" ;;
  loong64) arch="loong64" ;;
  mips64) arch="mips64" ;;
  mips64le) arch="mips64le" ;;
  *)
    log_error "Unsupported architecture: $(uname -m)"
    log_error "Supported architectures: x86_64, aarch64, armv7l, i386, ppc64, s390x, riscv64, loong64, mips64"
    exit 1
    ;;
  esac

  echo "${os}_${arch}"
}

# Function to try installing a package with a specific package manager
try_package_install() {
  package_name="$1"
  manager="$2"
  install_cmd="$3"

  log_info "Installing $package_name via $manager..."
  if eval "$install_cmd"; then
    # Verify installation
    if command -v "$package_name" >/dev/null 2>&1; then
      log_info "$package_name installed successfully via $manager"
      return 0
    else
      log_debug "$package_name not found in PATH after $manager installation"
    fi
  else
    log_debug "$manager installation failed for $package_name"
  fi
  return 1
}

# =============================================================================
# PACKAGE MANAGER SUPPORT
# =============================================================================

# Function to check if we need sudo for package operations
need_sudo() {
  # Check if we can write to common package manager directories
  if [ -w /var/lib/apt/lists ] 2>/dev/null ||
    [ -w /var/lib/dnf ] 2>/dev/null ||
    [ -w /var/lib/pacman ] 2>/dev/null ||
    [ -w /var/cache/apk ] 2>/dev/null; then
    return 1 # No sudo needed
  else
    return 0 # Sudo needed
  fi
}

# Function to run command with sudo if needed
run_with_sudo() {
  if need_sudo; then
    if ! command -v sudo >/dev/null 2>&1; then
      log_error "sudo is required but not available"
      exit 1
    fi
    sudo "$@"
  else
    "$@"
  fi
}

# =============================================================================
# COSIGN INSTALLATION
# =============================================================================

# Function to install cosign
install_cosign() {
  # Check if cosign is already available and not forcing reinstall
  if command -v cosign >/dev/null 2>&1 && [ "${REINSTALL_TOOLS:-false}" != "true" ]; then
    log_info "Cosign is already installed: $(command -v cosign)"
    log_info "Version: $(cosign version 2>/dev/null | grep 'GitVersion:' | cut -d' ' -f2 || echo "unknown")"
    log_info "Use --force to reinstall"
    return 0
  fi

  if [ "${REINSTALL_TOOLS:-false}" = "true" ]; then
    log_info "Force installing cosign for signature verification..."
  else
    log_info "Installing cosign for signature verification..."
  fi

  # Try package managers first
  if command -v brew >/dev/null 2>&1; then
    if try_package_install "cosign" "Homebrew" "brew install cosign"; then
      return 0
    fi
  elif command -v pacman >/dev/null 2>&1; then
    if try_package_install "cosign" "pacman" "run_with_sudo pacman -S --noconfirm cosign"; then
      return 0
    fi
  elif command -v apk >/dev/null 2>&1; then
    if try_package_install "cosign" "apk" "run_with_sudo apk add cosign"; then
      return 0
    fi
  elif command -v apt-get >/dev/null 2>&1; then
    if try_package_install "cosign" "apt" "run_with_sudo apt-get update && run_with_sudo apt-get install -y cosign"; then
      return 0
    else
      log_info "Cosign not available in apt repositories, falling back to binary installation"
    fi
  elif command -v dnf >/dev/null 2>&1; then
    if try_package_install "cosign" "dnf" "run_with_sudo dnf install -y cosign"; then
      return 0
    else
      log_info "Cosign not available in dnf repositories, falling back to binary installation"
    fi
  fi

  # Fallback to binary installation
  download_cmd=$(get_download_cmd)
  system=$(detect_system)

  log_info "Installing cosign binary..."
  cosign_binary="$temp_dir/cosign"

  # Convert system format from linux_arm64 to linux-arm64 for cosign
  cosign_system=$(echo "$system" | sed 's/_/-/g')

  # Use specific version or latest
  if [ "$COSIGN_VERSION" = "latest" ]; then
    cosign_url="$GITHUB_RELEASES_URL/$COSIGN_REPO/releases/latest/download/cosign-$cosign_system"
  else
    # Remove 'v' prefix if present for URL construction
    cosign_version_clean=$(echo "$COSIGN_VERSION" | sed 's/^v//')
    cosign_url="$GITHUB_RELEASES_URL/$COSIGN_REPO/releases/download/v$cosign_version_clean/cosign-$cosign_system"
  fi

  if ! $download_cmd "$cosign_url" >"$cosign_binary"; then
    log_error "Failed to download cosign"
    log_error "URL attempted: $cosign_url"
    exit 1
  fi

  # Move to final location and set permissions
  mv "$cosign_binary" "$BIN_DIR/cosign"
  chmod +x "$BIN_DIR/cosign"
  log_info "Cosign installed successfully"
}

# =============================================================================
# MISE INSTALLATION
# =============================================================================

# Function to install mise
install_mise() {
  # Check if mise is already available and not forcing reinstall
  if command -v mise >/dev/null 2>&1 && [ "${REINSTALL_TOOLS:-false}" != "true" ]; then
    log_info "Mise is already installed: $(command -v mise)"
    log_info "Version: $(mise --version 2>/dev/null | head -n1 || echo "unknown")"
    log_info "Use REINSTALL_TOOLS=true to reinstall"
    return 0
  fi

  if [ "${REINSTALL_TOOLS:-false}" = "true" ]; then
    log_info "Force installing mise for tool version management..."
  else
    log_info "Installing mise for tool version management..."
  fi

  # Try package managers first
  if command -v brew >/dev/null 2>&1; then
    if try_package_install "mise" "Homebrew" "brew install mise"; then
      return 0
    fi
  elif command -v apt-get >/dev/null 2>&1; then
    log_info "Installing mise via apt repository..."
    system=$(detect_system)

    # Determine architecture for apt repository
    case "$system" in
    linux_amd64) repo_arch="amd64" ;;
    linux_arm64) repo_arch="arm64" ;;
    *)
      log_info "Unsupported architecture for mise apt repository: $system"
      return 1
      ;;
    esac

    # Install required dependencies and set up repository
    if run_with_sudo apt-get update -y && run_with_sudo apt-get install -y gpg wget curl; then
      if run_with_sudo install -dm 755 /etc/apt/keyrings; then
        download_cmd=$(get_download_cmd)

        if $download_cmd https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | run_with_sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg >/dev/null; then
          echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=$repo_arch] https://mise.jdx.dev/deb stable main" | run_with_sudo tee /etc/apt/sources.list.d/mise.list
          if run_with_sudo apt-get update && try_package_install "mise" "apt" "run_with_sudo apt-get install -y mise"; then
            return 0
          fi
        fi
      fi
    fi
    log_info "Mise apt installation failed"
    return 1
  elif command -v pacman >/dev/null 2>&1; then
    if try_package_install "mise" "pacman" "run_with_sudo pacman -S --noconfirm mise"; then
      return 0
    fi
  elif command -v apk >/dev/null 2>&1; then
    if try_package_install "mise" "apk" "run_with_sudo apk add mise"; then
      return 0
    fi
  elif command -v dnf >/dev/null 2>&1; then
    if try_package_install "mise" "dnf" "run_with_sudo dnf install -y mise"; then
      return 0
    fi
  fi

  log_info "No suitable package manager found for mise installation"
  return 1
}

# =============================================================================
# CHEZMOI INSTALLATION
# =============================================================================

# Function to try package manager installation
try_package_manager() {
  log_info "Trying package manager installation..."

  if command -v brew >/dev/null 2>&1; then
    if try_package_install "chezmoi" "Homebrew" "brew install chezmoi"; then
      return 0
    fi
  elif command -v pacman >/dev/null 2>&1; then
    if try_package_install "chezmoi" "pacman" "run_with_sudo pacman -S --noconfirm chezmoi"; then
      return 0
    fi
  elif command -v apk >/dev/null 2>&1; then
    if try_package_install "chezmoi" "apk" "run_with_sudo apk add chezmoi"; then
      return 0
    fi
  elif command -v apt-get >/dev/null 2>&1; then
    if try_package_install "chezmoi" "apt" "run_with_sudo apt-get update && run_with_sudo apt-get install -y chezmoi"; then
      return 0
    fi
  elif command -v dnf >/dev/null 2>&1; then
    if try_package_install "chezmoi" "dnf" "run_with_sudo dnf install -y chezmoi"; then
      return 0
    fi
  fi

  log_info "Package manager installation failed or chezmoi not found in PATH"
  return 1
}

# Function to get latest version from GitHub
get_latest_version() {
  download_cmd=$(get_download_cmd)
  $download_cmd "$GITHUB_API_URL/repos/$CHEZMOI_REPO/releases/latest" |
    grep '"tag_name"' | cut -d'"' -f4 | sed 's/^v//'
}

# Function to verify checksums (portable across systems)
verify_checksum() {
  # First parameter (archive file) is not used directly,
  # but kept for compatibility with calling convention
  checksums="$2"

  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -c "$checksums" --ignore-missing
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 -c "$checksums" --ignore-missing
  else
    log_error "Neither sha256sum nor shasum is available for checksum verification"
    exit 1
  fi
}

# Function to download and verify chezmoi
download_chezmoi() {
  download_cmd=$(get_download_cmd)
  system=$(detect_system)

  # Get version
  if [ "$CHEZMOI_VERSION" = "latest" ]; then
    version=$(get_latest_version)
  else
    version="$CHEZMOI_VERSION"
  fi

  log_info "Downloading chezmoi version $version for $system..."

  # Determine file extension based on system
  case "$system" in
  linux_*) ext="tar.gz" ;;
  darwin_*) ext="tar.gz" ;;
  freebsd_*) ext="tar.gz" ;;
  openbsd_*) ext="tar.gz" ;;
  *)
    log_error "Unsupported system for download: $system"
    exit 1
    ;;
  esac

  # Download files to temporary directory
  base_url="$GITHUB_RELEASES_URL/$CHEZMOI_REPO/releases/download/v$version"
  archive="chezmoi_${version}_${system}.${ext}"
  checksums="chezmoi_${version}_checksums.txt"
  signature="chezmoi_${version}_checksums.txt.sig"
  pubkey="chezmoi_cosign.pub"

  # Full paths in temporary directory
  archive_path="$temp_dir/$archive"
  checksums_path="$temp_dir/$checksums"
  signature_path="$temp_dir/$signature"
  pubkey_path="$temp_dir/$pubkey"

  log_info "Downloading $archive..."
  if ! $download_cmd "$base_url/$archive" >"$archive_path"; then
    log_error "Failed to download chezmoi archive"
    log_error "URL attempted: $base_url/$archive"
    exit 1
  fi

  log_info "Downloading checksums..."
  if ! $download_cmd "$base_url/$checksums" >"$checksums_path"; then
    log_error "Failed to download checksums"
    exit 1
  fi

  # Only download and verify signature if verification is enabled
  if [ "$VERIFY_SIGNATURES" = "true" ]; then
    log_info "Downloading signature..."
    if ! $download_cmd "$base_url/$signature" >"$signature_path"; then
      log_error "Failed to download signature"
      exit 1
    fi

    log_info "Downloading public key..."
    if ! $download_cmd "$base_url/$pubkey" >"$pubkey_path"; then
      log_error "Failed to download public key"
      exit 1
    fi

    # Verify signature using cosign
    log_info "Verifying signature..."
    if ! cosign verify-blob "$checksums_path" --signature "$signature_path" --key "$pubkey_path"; then
      log_error "Signature verification failed"
      exit 1
    fi
  else
    log_info "Signature verification disabled"
  fi

  # Verify checksum (need to change to temp directory for relative paths in checksums file)
  log_info "Verifying checksum..."
  if ! (cd "$temp_dir" && verify_checksum "$archive" "$checksums"); then
    log_error "Checksum verification failed"
    exit 1
  fi

  # Extract and install
  log_info "Extracting chezmoi..."
  (cd "$temp_dir" && tar -xzf "$archive" chezmoi)
  mv "$temp_dir/chezmoi" "$BIN_DIR/"
  chmod +x "$BIN_DIR/chezmoi"

  log_info "Chezmoi installed successfully to $BIN_DIR"
}

# Function to install chezmoi
install_chezmoi() {
  # Check if chezmoi is already available and not forcing reinstall
  if command -v chezmoi >/dev/null 2>&1 && [ "${REINSTALL_TOOLS:-false}" != "true" ]; then
    log_info "Chezmoi is already installed: $(command -v chezmoi)"
    log_info "Version: $(chezmoi --version 2>/dev/null || echo "unknown")"
    log_info "Use REINSTALL_TOOLS=true to reinstall"
    return 0
  fi

  # First, ensure cosign is available if signature verification is enabled
  if [ "$VERIFY_SIGNATURES" = "true" ] && ! command -v cosign >/dev/null 2>&1; then
    install_cosign
  fi

  if [ "${REINSTALL_TOOLS:-false}" = "true" ]; then
    log_info "Force installing chezmoi..."
  fi

  # Try package manager first unless skipped
  if [ "$SKIP_PACKAGE_MANAGER" != "true" ] && try_package_manager; then
    # Verify chezmoi is available
    if command -v chezmoi >/dev/null 2>&1; then
      log_info "Chezmoi installation verified"
      return 0
    else
      log_info "Warning: chezmoi not found in PATH after package manager installation"
    fi
  fi

  # Fallback to downloading from GitHub
  if [ "$SKIP_PACKAGE_MANAGER" = "true" ]; then
    log_info "Package manager installation skipped, downloading from GitHub..."
  else
    log_info "Package manager installation failed, downloading from GitHub..."
  fi
  download_chezmoi

  # Final verification
  if ! command -v chezmoi >/dev/null 2>&1; then
    log_error "chezmoi installation failed - binary not found in PATH"
    log_error "Please ensure $BIN_DIR is in your PATH"
    exit 1
  fi
}

# =============================================================================
# PATH MANAGEMENT
# =============================================================================

# Add BIN_DIR to PATH if not already there
add_to_path() {
  case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) export PATH="$BIN_DIR:$PATH" ;;
  esac
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

# Main execution
main() {
  # Parse command line arguments first
  parse_arguments "$@"

  # Set configuration variables after parsing arguments
  readonly BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
  readonly CHEZMOI_VERSION="${CHEZMOI_VERSION:-latest}"
  # Try to read cosign version from versions file, fallback to latest
  COSIGN_VERSION_FROM_FILE=""
  if [ -f "$script_dir/home/dot_config/dotfiles/cli-versions.toml" ]; then
    COSIGN_VERSION_FROM_FILE="$(grep '^cosign' "$script_dir/home/dot_config/dotfiles/cli-versions.toml" | cut -d'"' -f2 2>/dev/null || echo "")"
  fi
  readonly COSIGN_VERSION="${COSIGN_VERSION:-${COSIGN_VERSION_FROM_FILE:-latest}}"
  readonly VERIFY_SIGNATURES="${VERIFY_SIGNATURES:-true}"
  readonly SKIP_PACKAGE_MANAGER="${SKIP_PACKAGE_MANAGER:-false}"
  readonly REINSTALL_TOOLS="${REINSTALL_TOOLS:-false}"

  if [ "$REINSTALL_TOOLS" = "true" ]; then
    log_info "Starting Chezmoi dotfiles manager installation (force mode)..."
  else
    log_info "Starting Chezmoi dotfiles manager installation..."
  fi

  # Set up environment and validate requirements
  setup_environment

  # Install Mise (optional, continue on failure)
  if ! install_mise; then
    log_info "Mise installation failed, but continuing with chezmoi setup"
  fi

  # Install Chezmoi
  install_chezmoi

  # Add BIN_DIR to PATH
  add_to_path

  # Get the actual chezmoi path
  chezmoi="$(command -v chezmoi)"

  log_info "Initializing dotfiles from $script_dir..."
  log_info "Summary: Chezmoi available at $chezmoi and configured successfully"

  # Execute the initialization command with proper argument handling
  set -- --apply --source="$script_dir" --working-tree="$script_dir"

  # Add any additional passthrough arguments
  if [ -n "$CHEZMOI_ARGS" ]; then
    # shellcheck disable=SC2086
    set -- "$@" $CHEZMOI_ARGS
  fi

  # Execute the initialization command
  exec "$chezmoi" init "$@"
}

main "$@"
