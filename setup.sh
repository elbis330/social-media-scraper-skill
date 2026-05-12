#!/usr/bin/env bash
#
# Social Media Scraper Skill — Interactive Setup
# Usage: ./setup.sh
#
set -euo pipefail

# ────────────────────────────────────────────────────────────────────
# Colors & helpers
# ────────────────────────────────────────────────────────────────────
if [ -t 1 ]; then
    BOLD=$'\033[1m'
    DIM=$'\033[2m'
    GREEN=$'\033[0;32m'
    YELLOW=$'\033[1;33m'
    RED=$'\033[0;31m'
    BLUE=$'\033[0;34m'
    CYAN=$'\033[0;36m'
    MAGENTA=$'\033[0;35m'
    NC=$'\033[0m'
else
    BOLD="" DIM="" GREEN="" YELLOW="" RED="" BLUE="" CYAN="" MAGENTA="" NC=""
fi

info()    { printf "%sℹ%s  %s\n" "$BLUE" "$NC" "$*"; }
ok()      { printf "%s✓%s  %s\n" "$GREEN" "$NC" "$*"; }
warn()    { printf "%s⚠%s  %s\n" "$YELLOW" "$NC" "$*"; }
err()     { printf "%s✗%s  %s\n" "$RED" "$NC" "$*"; }
hr()      { printf "%s────────────────────────────────────────────────────────%s\n" "$DIM" "$NC"; }

header() {
    printf "\n%s%s%s\n" "$BOLD$CYAN" "$1" "$NC"
    hr
}

# Ask a question with a default value (prompt to stderr, answer to stdout)
ask() {
    local prompt="$1"
    local default="${2:-}"
    local reply
    if [ -n "$default" ]; then
        printf "%s» %s%s %s(default: %s)%s: " "$MAGENTA" "$NC" "$prompt" "$DIM" "$default" "$NC" >&2
    else
        printf "%s» %s%s: " "$MAGENTA" "$NC" "$prompt" >&2
    fi
    read -r reply
    printf "%s" "${reply:-$default}"
}

# yes/no question (interaction goes to stderr)
ask_yn() {
    local prompt="$1"
    local default="${2:-y}"
    local hint="[Y/n]"
    [ "$default" = "n" ] && hint="[y/N]"
    while true; do
        printf "%s» %s%s %s%s%s: " "$MAGENTA" "$NC" "$prompt" "$DIM" "$hint" "$NC" >&2
        read -r reply
        reply="${reply:-$default}"
        case "$reply" in
            [yY]|[yY][eE][sS]) return 0 ;;
            [nN]|[nN][oO])     return 1 ;;
            *) printf "%s⚠%s  Please type 'yes' or 'no'.\n" "$YELLOW" "$NC" >&2 ;;
        esac
    done
}

# ────────────────────────────────────────────────────────────────────
# Header
# ────────────────────────────────────────────────────────────────────
clear 2>/dev/null || true
cat <<EOF

${BOLD}${CYAN}🎬  Social Media Scraper Skill — Setup${NC}
${DIM}Instagram · TikTok · Twitter/X · YouTube → everything from a single link${NC}

EOF
hr

# ────────────────────────────────────────────────────────────────────
# OS detection
# ────────────────────────────────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
    Darwin*) PLATFORM_OS="macos" ;;
    Linux*)  PLATFORM_OS="linux" ;;
    *)       err "Unsupported operating system: $OS"; exit 1 ;;
esac
ok "Operating system: $PLATFORM_OS"

# ────────────────────────────────────────────────────────────────────
# Step 1/4: Platform selection
# ────────────────────────────────────────────────────────────────────
header "Step 1/4: Platform Selection"
cat <<EOF
Which platforms do you want to use?

  ${BOLD}[1]${NC} 📸 Instagram   ${DIM}(reel, post, story)${NC}
  ${BOLD}[2]${NC} 🎵 TikTok      ${DIM}(video + comments)${NC}
  ${BOLD}[3]${NC} 🐦 Twitter/X   ${DIM}(tweet + thread)${NC}
  ${BOLD}[4]${NC} 📺 YouTube     ${DIM}(video + captions)${NC}
  ${BOLD}[a]${NC} Select all    ${DIM}(recommended)${NC}

EOF

raw_choice=$(ask "Make your selection (comma-separated, e.g. 1,3)" "a")

WANT_INSTAGRAM=false
WANT_TIKTOK=false
WANT_TWITTER=false
WANT_YOUTUBE=false

case "$raw_choice" in
    a|A|all)
        WANT_INSTAGRAM=true
        WANT_TIKTOK=true
        WANT_TWITTER=true
        WANT_YOUTUBE=true
        ;;
    *)
        IFS=',' read -ra PARTS <<< "$raw_choice"
        for p in "${PARTS[@]}"; do
            p="${p// /}"
            case "$p" in
                1) WANT_INSTAGRAM=true ;;
                2) WANT_TIKTOK=true ;;
                3) WANT_TWITTER=true ;;
                4) WANT_YOUTUBE=true ;;
                "" ) ;;
                *) warn "Unknown selection skipped: $p" ;;
            esac
        done
        ;;
esac

PLATFORM_LIST=""
$WANT_INSTAGRAM && PLATFORM_LIST="${PLATFORM_LIST}instagram,"
$WANT_TIKTOK    && PLATFORM_LIST="${PLATFORM_LIST}tiktok,"
$WANT_TWITTER   && PLATFORM_LIST="${PLATFORM_LIST}twitter,"
$WANT_YOUTUBE   && PLATFORM_LIST="${PLATFORM_LIST}youtube,"
PLATFORM_LIST="${PLATFORM_LIST%,}"

if [ -z "$PLATFORM_LIST" ]; then
    err "No platform selected. Setup canceled."
    exit 1
fi

ok "Selected platforms: $PLATFORM_LIST"

# ────────────────────────────────────────────────────────────────────
# Step 2/4: Gemini video analysis
# ────────────────────────────────────────────────────────────────────
header "Step 2/4: Video Analysis (Gemini Vision)"
cat <<EOF
Gemini visual video analysis reads on-screen text, products, interfaces
and scenes. Whisper only translates speech; Gemini explains ${BOLD}what is${NC}
${BOLD}on screen${NC}. ${DIM}Together they produce a much richer summary.${NC}

${DIM}Free API key:${NC} https://aistudio.google.com/apikey

EOF

GEMINI_ENABLED=false
GEMINI_API_KEY_VALUE=""

if ask_yn "Enable Gemini visual analysis?" "y"; then
    GEMINI_ENABLED=true
    # If an existing env var is present, show it (masked) as default
    existing_key="${GEMINI_API_KEY:-}"
    if [ -n "$existing_key" ]; then
        masked="${existing_key:0:6}…${existing_key: -4}"
        info "Existing GEMINI_API_KEY env var found: $masked"
        if ask_yn "Do you want to use it?" "y"; then
            GEMINI_API_KEY_VALUE="$existing_key"
        fi
    fi
    if [ -z "$GEMINI_API_KEY_VALUE" ]; then
        while true; do
            entered=$(ask "Gemini API key" "")
            if [ -z "$entered" ]; then
                warn "If left empty, visual analysis stays disabled."
                if ask_yn "Continue anyway (without visual analysis)?" "n"; then
                    GEMINI_ENABLED=false
                    break
                fi
            else
                GEMINI_API_KEY_VALUE="$entered"
                break
            fi
        done
    fi
fi

if $GEMINI_ENABLED; then
    ok "Gemini Vision: enabled"
else
    warn "Gemini Vision: disabled (transcription + metadata only)"
fi

# ────────────────────────────────────────────────────────────────────
# Step 3/4: Transcription language
# ────────────────────────────────────────────────────────────────────
header "Step 3/4: Transcription Language"
cat <<EOF
Which language should faster-whisper prioritize?

  ${BOLD}[1]${NC} Auto-detect          ${DIM}(recommended — 99 languages)${NC}
  ${BOLD}[2]${NC} Turkish              ${DIM}(tr)${NC}
  ${BOLD}[3]${NC} English              ${DIM}(en)${NC}
  ${BOLD}[4]${NC} Other                ${DIM}(ISO 639-1 code — fr, de, es, …)${NC}

EOF

lang_choice=$(ask "Make your selection" "1")
case "$lang_choice" in
    1|""|auto)  TRANSCRIPTION_LANG="auto" ;;
    2|tr|TR)    TRANSCRIPTION_LANG="tr"   ;;
    3|en|EN)    TRANSCRIPTION_LANG="en"   ;;
    4)
        custom=$(ask "ISO 639-1 language code (e.g. fr, de, es)" "auto")
        TRANSCRIPTION_LANG="${custom:-auto}"
        ;;
    *)
        # A direct code may have been entered
        TRANSCRIPTION_LANG="$lang_choice"
        ;;
esac

# Whisper model size (advanced choice)
WHISPER_MODEL="medium"
if ask_yn "Do you want to customize the Whisper model size?" "n"; then
    cat <<EOF

  ${BOLD}tiny${NC}    ~75MB    very fast, low quality
  ${BOLD}base${NC}    ~150MB   fast, medium quality
  ${BOLD}small${NC}   ~500MB   balanced
  ${BOLD}medium${NC}  ~1.5GB   ${DIM}(default)${NC} good quality
  ${BOLD}large-v3${NC} ~3GB     best quality, slow

EOF
    WHISPER_MODEL=$(ask "Model" "medium")
fi

ok "Transcription language: $TRANSCRIPTION_LANG · model: $WHISPER_MODEL"

# ────────────────────────────────────────────────────────────────────
# Step 4/4: Installation
# ────────────────────────────────────────────────────────────────────
header "Step 4/4: Installation"

echo "I will do the following:"
echo "  ${DIM}•${NC} Install base tools (ffmpeg, faster-whisper)"
$WANT_INSTAGRAM && echo "  ${DIM}•${NC} For Instagram: instaloader"
$WANT_TIKTOK    && echo "  ${DIM}•${NC} For TikTok: yt-dlp"
$WANT_YOUTUBE   && echo "  ${DIM}•${NC} For YouTube: yt-dlp"
$WANT_TWITTER   && echo "  ${DIM}•${NC} For Twitter/X: bird CLI (npm)"
$GEMINI_ENABLED && echo "  ${DIM}•${NC} Gemini Vision: google-genai"
echo "  ${DIM}•${NC} Configuration: ~/.social-media-scraper.env"
echo "  ${DIM}•${NC} Skill: ~/.claude/skills/social-media-scraper/"
echo ""

if ! ask_yn "Shall I continue?" "y"; then
    err "Setup canceled."
    exit 1
fi

# ── Base tool check ─────────────────────────────────────────────────
info "Checking system requirements..."

need_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        err "Required command not found: $1"
        echo "    To install: $2"
        exit 1
    fi
}

need_cmd python3 "https://www.python.org/downloads/"
need_cmd pip3    "Comes with Python"
need_cmd git     "https://git-scm.com/downloads"
$WANT_TWITTER && need_cmd npm "https://nodejs.org/"
ok "Base dependencies present"

# ── ffmpeg ──────────────────────────────────────────────────────────
if ! command -v ffmpeg >/dev/null 2>&1; then
    warn "ffmpeg not found, installing..."
    if [ "$PLATFORM_OS" = "macos" ]; then
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

# ── Python packages (only the selected ones) ────────────────────────
PIP_FLAGS="--upgrade --quiet"
if pip3 install --help 2>&1 | grep -q "break-system-packages"; then
    PIP_FLAGS="$PIP_FLAGS --break-system-packages"
fi

PIP_PACKAGES=("faster-whisper")
$WANT_INSTAGRAM && PIP_PACKAGES+=("instaloader")
($WANT_TIKTOK || $WANT_YOUTUBE) && PIP_PACKAGES+=("yt-dlp")
$GEMINI_ENABLED && PIP_PACKAGES+=("google-genai")

info "Installing Python packages: ${PIP_PACKAGES[*]}"
# shellcheck disable=SC2086
pip3 install $PIP_FLAGS "${PIP_PACKAGES[@]}"
ok "Python packages installed"

# ── bird CLI (Twitter) ──────────────────────────────────────────────
if $WANT_TWITTER; then
    if ! command -v bird >/dev/null 2>&1; then
        info "Installing bird CLI (for Twitter/X)..."
        npm install -g @steipete/bird
        ok "bird CLI installed"
    else
        ok "bird CLI is already installed"
    fi
fi

# ── Configuration file ──────────────────────────────────────────────
ENV_FILE="$HOME/.social-media-scraper.env"
info "Writing configuration: $ENV_FILE"

# Back up existing file if present
if [ -f "$ENV_FILE" ]; then
    cp "$ENV_FILE" "$ENV_FILE.bak.$(date +%s)"
    warn "Existing configuration backed up: $ENV_FILE.bak.*"
fi

cat > "$ENV_FILE" <<EOF
# Social Media Scraper — configuration
# This file was generated by setup.sh. You can edit it manually.

# Active platforms (comma-separated)
PLATFORMS=$PLATFORM_LIST

# Gemini video analysis
GEMINI_ENABLED=$GEMINI_ENABLED
GEMINI_API_KEY=$GEMINI_API_KEY_VALUE

# Transcription
TRANSCRIPTION_LANG=$TRANSCRIPTION_LANG
WHISPER_MODEL=$WHISPER_MODEL
EOF
chmod 600 "$ENV_FILE"
ok "Configuration saved (only you can read it: chmod 600)"

# ── Place the skill ─────────────────────────────────────────────────
SKILL_DIR="$HOME/.claude/skills/social-media-scraper"
info "Placing skill: $SKILL_DIR"
mkdir -p "$SKILL_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/SKILL.md" "$SKILL_DIR/SKILL.md"
ok "SKILL.md copied"

# ────────────────────────────────────────────────────────────────────
# Summary
# ────────────────────────────────────────────────────────────────────
echo ""
hr
printf "%s%s%s\n" "$BOLD$GREEN" "🎉  Setup complete!" "$NC"
hr
cat <<EOF

${BOLD}Summary${NC}
  Platforms         : $PLATFORM_LIST
  Gemini Vision     : $([ "$GEMINI_ENABLED" = "true" ] && echo "enabled" || echo "disabled")
  Transcription     : $TRANSCRIPTION_LANG ($WHISPER_MODEL)
  Configuration     : $ENV_FILE
  Skill             : $SKILL_DIR/SKILL.md

${BOLD}What can you do now?${NC}
  Restart Claude Code and try this:

    ${CYAN}"Analyze this reel: https://www.instagram.com/reel/<a_link>/"${NC}

${DIM}If you run into issues: https://github.com/elbis330/social-media-scraper-skill/issues${NC}

EOF
