#!/bin/bash
#
# MshX Installer
# Usage: curl -sSL https://raw.githubusercontent.com/NaimurRahmannn/Mshx-shell-Linux-os/main/install.sh | bash
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

REPO_URL="https://github.com/NaimurRahmannn/Mshx-shell-Linux-os.git"
INSTALL_DIR="$HOME/.local/bin"
BUILD_DIR=$(mktemp -d)

info()  { echo -e "${CYAN}[INFO]${NC}  $1"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
fail()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

cleanup() {
    rm -rf "$BUILD_DIR"
}
trap cleanup EXIT

echo ""
echo -e "${BOLD}  ╔══════════════════════════════════════╗${NC}"
echo -e "${BOLD}  ║         MshX Shell Installer         ║${NC}"
echo -e "${BOLD}  ╚══════════════════════════════════════╝${NC}"
echo ""

# ── Check dependencies ──────────────────────────────────────────
info "Checking dependencies..."

if ! command -v gcc &> /dev/null; then
    fail "gcc is not installed. Install it with: sudo apt install gcc (Debian/Ubuntu) or sudo dnf install gcc (Fedora)"
fi
ok "gcc found: $(gcc --version | head -1)"

if ! command -v make &> /dev/null; then
    fail "make is not installed. Install it with: sudo apt install make (Debian/Ubuntu) or sudo dnf install make (Fedora)"
fi
ok "make found: $(make --version | head -1)"

if ! command -v git &> /dev/null; then
    fail "git is not installed. Install it with: sudo apt install git (Debian/Ubuntu) or sudo dnf install git (Fedora)"
fi
ok "git found: $(git --version)"

# ── Clone ────────────────────────────────────────────────────────
info "Cloning MshX repository..."
git clone --depth 1 "$REPO_URL" "$BUILD_DIR/mshx" 2>&1 | tail -1
ok "Repository cloned"

# ── Build ────────────────────────────────────────────────────────
info "Building MshX..."
cd "$BUILD_DIR/mshx"
make -j"$(nproc)" 2>&1 | tail -3
ok "Build complete"

# ── Install ──────────────────────────────────────────────────────
mkdir -p "$INSTALL_DIR"

info "Installing to $INSTALL_DIR/mshx..."
cp "$BUILD_DIR/mshx/mshX" "$INSTALL_DIR/mshx"
chmod +x "$INSTALL_DIR/mshx"
ok "Installed to $INSTALL_DIR/mshx"

# ── Check PATH ───────────────────────────────────────────────────
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    warn "$INSTALL_DIR is not in your PATH"
    echo ""

    SHELL_NAME=$(basename "$SHELL")
    case "$SHELL_NAME" in
        bash)
            RC_FILE="$HOME/.bashrc"
            ;;
        zsh)
            RC_FILE="$HOME/.zshrc"
            ;;
        *)
            RC_FILE="$HOME/.profile"
            ;;
    esac

    echo "  Add it by running:"
    echo ""
    echo -e "    ${CYAN}echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> $RC_FILE${NC}"
    echo -e "    ${CYAN}source $RC_FILE${NC}"
    echo ""
fi

# ── Done ─────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}  ✓ MshX installed successfully!${NC}"
echo ""
echo "  Run it with:"
echo ""
echo -e "    ${CYAN}mshx${NC}"
echo ""
