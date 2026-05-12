#!/usr/bin/env bash
#
# Social Media Scraper — tek komut kurulum
# Kullanım: ./install.sh
#
set -euo pipefail

# Renkler
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
echo "🎬 Social Media Scraper Skill — Kurulum"
echo "========================================"
echo ""

# 1) İşletim sistemini algıla
OS="$(uname -s)"
case "$OS" in
    Darwin*) PLATFORM="macos" ;;
    Linux*)  PLATFORM="linux" ;;
    *)       err "Desteklenmeyen platform: $OS"; exit 1 ;;
esac
ok "Platform algılandı: $PLATFORM"

# 2) Bağımlılık kontrolü
need_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        err "Gerekli komut bulunamadı: $1"
        echo "    Yüklemek için: $2"
        exit 1
    fi
}

info "Sistem gereksinimleri kontrol ediliyor..."
need_cmd python3 "https://www.python.org/downloads/"
need_cmd pip3    "Python ile birlikte gelir"
need_cmd npm     "https://nodejs.org/"
need_cmd git     "https://git-scm.com/downloads"
ok "Temel bağımlılıklar mevcut"

# 3) ffmpeg
if ! command -v ffmpeg >/dev/null 2>&1; then
    warn "ffmpeg bulunamadı, yükleniyor..."
    if [ "$PLATFORM" = "macos" ]; then
        if command -v brew >/dev/null 2>&1; then
            brew install ffmpeg
        else
            err "Homebrew kurulu değil. https://brew.sh adresinden kur, sonra tekrar dene."
            exit 1
        fi
    else
        sudo apt-get update && sudo apt-get install -y ffmpeg
    fi
    ok "ffmpeg yüklendi"
else
    ok "ffmpeg zaten kurulu"
fi

# 4) Python paketleri
info "Python paketleri yükleniyor..."
PIP_FLAGS="--upgrade"
# Bazı modern Python sürümleri externally-managed env hatası verir
if pip3 install --help 2>&1 | grep -q "break-system-packages"; then
    PIP_FLAGS="$PIP_FLAGS --break-system-packages"
fi

pip3 install $PIP_FLAGS \
    yt-dlp \
    instaloader \
    faster-whisper \
    google-genai

ok "Python paketleri yüklendi"

# 5) bird CLI (Twitter/X)
info "bird CLI yükleniyor (Twitter/X için)..."
if ! command -v bird >/dev/null 2>&1; then
    npm install -g @steipete/bird
    ok "bird CLI yüklendi"
else
    ok "bird CLI zaten kurulu"
fi

# 6) Skill'i yerleştir
SKILL_DIR="$HOME/.claude/skills/social-media-scraper"
info "Skill yerleştiriliyor: $SKILL_DIR"
mkdir -p "$SKILL_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/SKILL.md" "$SKILL_DIR/SKILL.md"
ok "SKILL.md kopyalandı"

# 7) Gemini API Key kontrolü
echo ""
if [ -z "${GEMINI_API_KEY:-}" ]; then
    warn "GEMINI_API_KEY environment variable tanımlı değil"
    echo ""
    echo "    Gemini Vision özelliğini kullanmak için ücretsiz API key al:"
    echo "    👉  https://aistudio.google.com/apikey"
    echo ""
    echo "    Sonra şu komutu çalıştır (zsh için):"
    echo "        echo 'export GEMINI_API_KEY=\"your_key_here\"' >> ~/.zshrc"
    echo "        source ~/.zshrc"
    echo ""
    echo "    bash için:"
    echo "        echo 'export GEMINI_API_KEY=\"your_key_here\"' >> ~/.bashrc"
    echo "        source ~/.bashrc"
    echo ""
    warn "API key olmadan görsel analiz çalışmaz — diğer her şey sorunsuz çalışacak."
else
    ok "GEMINI_API_KEY tanımlı"
fi

# 8) Tamamlandı
echo ""
echo "========================================"
ok "Kurulum tamamlandı! 🎉"
echo ""
echo "Şimdi Claude Code'u yeniden başlat ve şunu dene:"
echo ""
echo "    \"Bu reel'i analiz et: https://www.instagram.com/reel/<bir_link>/\""
echo ""
echo "Sorun yaşarsan: https://github.com/elbis330/social-media-scraper-skill/issues"
echo ""
