#!/usr/bin/env bash
#
# Social Media Scraper — one-command install
# Usage: ./install.sh
#
set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}ℹ${NC}  $*"; }
ok()      { echo -e "${GREEN}✓${NC}  $*"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $*"; }
err()     { echo -e "${RED}✗${NC}  $*"; }

echo ""
echo "🎬 Social Media Scraper Skill — Install"
echo "========================================"
echo ""

# 1) Detect the operating system
OS="$(uname -s)"
case "$OS" in
    Darwin*) PLATFORM="macos" ;;
    Linux*)  PLATFORM="linux" ;;
    *)       err "Unsupported platform: $OS"; exit 1 ;;
esac
ok "Platform detected: $PLATFORM"

# 2) Dependency check
need_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        err "Required command not found: $1"
        echo "    To install: $2"
        exit 1
    fi
}

info "Checking system requirements..."
need_cmd python3 "https://www.python.org/downloads/"
need_cmd pip3    "Comes with Python"
need_cmd npm     "https://nodejs.org/"
need_cmd git     "https://git-scm.com/downloads"
ok "Base dependencies present"

# 3) ffmpeg
if ! command -v ffmpeg >/dev/null 2>&1; then
    warn "ffmpeg not found, installing..."
    if [ "$PLATFORM" = "macos" ]; then
        if command -v brew >/dev/null 2>&1; then
            brew install ffmpeg
        else
            err "Homebrew is not installed. Install it from https://brew.sh and try again."
            exit 1
        fi
    else
        sudo apt-get update && sudo apt-get install -y ffmpeg
    fi
    ok "ffmpeg installed"
else
    ok "ffmpeg is already installed"
fi

# 4) Python packages
info "Installing Python packages..."
PIP_FLAGS="--upgrade"
# Some modern Python versions throw externally-managed env errors
if pip3 install --help 2>&1 | grep -q "break-system-packages"; then
    PIP_FLAGS="$PIP_FLAGS --break-system-packages"
fi

pip3 install $PIP_FLAGS \
    yt-dlp \
    instaloader \
    faster-whisper \
    google-genai

ok "Python packages installed"

# 5) bird CLI (Twitter/X)
info "Installing bird CLI (for Twitter/X)..."
if ! command -v bird >/dev/null 2>&1; then
    npm install -g @steipete/bird
    ok "bird CLI installed"
else
    ok "bird CLI is already installed"
fi

# 6) Place the skill
# Works with any agent that loads skills from a directory. Set AGENT_SKILLS_DIR
# to your agent's skills directory (falls back to ~/.agent-skills).
SKILLS_ROOT="${AGENT_SKILLS_DIR:-$HOME/.agent-skills}"
SKILL_DIR="$SKILLS_ROOT/social-media-scraper"
info "Placing skill: $SKILL_DIR"
mkdir -p "$SKILL_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/SKILL.md" "$SKILL_DIR/SKILL.md"
ok "SKILL.md copied"

# 7) Gemini API Key check
echo ""
if [ -z "${GEMINI_API_KEY:-}" ]; then
    warn "GEMINI_API_KEY environment variable is not defined"
    echo ""
    echo "    To use the Gemini Vision feature, get a free API key:"
    echo "    👉  https://aistudio.google.com/apikey"
    echo ""
    echo "    Then run this command (for zsh):"
    echo "        echo 'export GEMINI_API_KEY=\"your_key_here\"' >> ~/.zshrc"
    echo "        source ~/.zshrc"
    echo ""
    echo "    For bash:"
    echo "        echo 'export GEMINI_API_KEY=\"your_key_here\"' >> ~/.bashrc"
    echo "        source ~/.bashrc"
    echo ""
    warn "Without an API key, visual analysis won't work — everything else will work fine."
else
    ok "GEMINI_API_KEY is set"
fi

if [ -n "${XQUIK_API_KEY:-}" ]; then
    ok "XQUIK_API_KEY is set for optional Twitter/X API fallback"
else
    info "Optional Twitter/X API fallback: set XQUIK_API_KEY if you want API-backed tweet metadata and replies"
fi

# 8) Done
echo ""
echo "========================================"
ok "Installation complete! 🎉"
echo ""
echo "Now restart your AI coding agent and try this:"
echo ""
echo "    \"Analyze this reel: https://www.instagram.com/reel/<a_link>/\""
echo ""
echo "If you run into issues: https://github.com/elbis330/social-media-scraper-skill/issues"
echo ""
