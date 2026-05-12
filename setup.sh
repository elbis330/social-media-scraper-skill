#!/usr/bin/env bash
#
# Social Media Scraper Skill — İnteraktif Kurulum
# Kullanım: ./setup.sh
#
set -euo pipefail

# ────────────────────────────────────────────────────────────────────
# Renkler & yardımcılar
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

# Soru sor, varsayılan değer ile (prompt stderr'a, cevap stdout'a)
ask() {
    local prompt="$1"
    local default="${2:-}"
    local reply
    if [ -n "$default" ]; then
        printf "%s» %s%s %s(varsayılan: %s)%s: " "$MAGENTA" "$NC" "$prompt" "$DIM" "$default" "$NC" >&2
    else
        printf "%s» %s%s: " "$MAGENTA" "$NC" "$prompt" >&2
    fi
    read -r reply
    printf "%s" "${reply:-$default}"
}

# evet/hayır sorusu (etkileşim stderr'a yazılır)
ask_yn() {
    local prompt="$1"
    local default="${2:-e}"
    local hint="[E/h]"
    [ "$default" = "h" ] && hint="[e/H]"
    while true; do
        printf "%s» %s%s %s%s%s: " "$MAGENTA" "$NC" "$prompt" "$DIM" "$hint" "$NC" >&2
        read -r reply
        reply="${reply:-$default}"
        case "$reply" in
            [eE]|[eE][vV][eE][tT]|[yY]|[yY][eE][sS]) return 0 ;;
            [hH]|[hH][aA][yY][iI][rR]|[nN]|[nN][oO])  return 1 ;;
            *) printf "%s⚠%s  Lütfen 'evet' veya 'hayır' yaz.\n" "$YELLOW" "$NC" >&2 ;;
        esac
    done
}

# ────────────────────────────────────────────────────────────────────
# Başlık
# ────────────────────────────────────────────────────────────────────
clear 2>/dev/null || true
cat <<EOF

${BOLD}${CYAN}🎬  Social Media Scraper Skill — Kurulum${NC}
${DIM}Instagram · TikTok · Twitter/X · YouTube → tek linkten her şey${NC}

EOF
hr

# ────────────────────────────────────────────────────────────────────
# Platform algılama
# ────────────────────────────────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
    Darwin*) PLATFORM_OS="macos" ;;
    Linux*)  PLATFORM_OS="linux" ;;
    *)       err "Desteklenmeyen işletim sistemi: $OS"; exit 1 ;;
esac
ok "İşletim sistemi: $PLATFORM_OS"

# ────────────────────────────────────────────────────────────────────
# Adım 1/4: Platform seçimi
# ────────────────────────────────────────────────────────────────────
header "Adım 1/4: Platform Seçimi"
cat <<EOF
Hangi platformları kullanmak istiyorsun?

  ${BOLD}[1]${NC} 📸 Instagram   ${DIM}(reel, post, story)${NC}
  ${BOLD}[2]${NC} 🎵 TikTok      ${DIM}(video + yorumlar)${NC}
  ${BOLD}[3]${NC} 🐦 Twitter/X   ${DIM}(tweet + thread)${NC}
  ${BOLD}[4]${NC} 📺 YouTube     ${DIM}(video + altyazı)${NC}
  ${BOLD}[a]${NC} Hepsini seç   ${DIM}(önerilen)${NC}

EOF

raw_choice=$(ask "Seçimini yap (virgülle ayır, örn: 1,3)" "a")

WANT_INSTAGRAM=false
WANT_TIKTOK=false
WANT_TWITTER=false
WANT_YOUTUBE=false

case "$raw_choice" in
    a|A|all|hepsi|tümü)
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
                *) warn "Bilinmeyen seçim atlandı: $p" ;;
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
    err "Hiç platform seçilmedi. Kurulum iptal edildi."
    exit 1
fi

ok "Seçilen platformlar: $PLATFORM_LIST"

# ────────────────────────────────────────────────────────────────────
# Adım 2/4: Gemini video analizi
# ────────────────────────────────────────────────────────────────────
header "Adım 2/4: Video Analizi (Gemini Vision)"
cat <<EOF
Gemini ile görsel video analizi, ekrandaki yazıları, ürünleri, arayüzleri
ve sahneleri okur. Whisper sadece konuşmayı çevirir; Gemini ${BOLD}ekranda${NC}
${BOLD}olanı${NC} anlatır. ${DIM}İkisi birlikte çok daha zengin bir özet üretir.${NC}

${DIM}Ücretsiz API key:${NC} https://aistudio.google.com/apikey

EOF

GEMINI_ENABLED=false
GEMINI_API_KEY_VALUE=""

if ask_yn "Gemini görsel analizi aktif olsun mu?" "e"; then
    GEMINI_ENABLED=true
    # Mevcut env var varsa onu varsayılan göster (maskeli)
    existing_key="${GEMINI_API_KEY:-}"
    if [ -n "$existing_key" ]; then
        masked="${existing_key:0:6}…${existing_key: -4}"
        info "Mevcut GEMINI_API_KEY env var bulundu: $masked"
        if ask_yn "Bunu kullanmak istiyor musun?" "e"; then
            GEMINI_API_KEY_VALUE="$existing_key"
        fi
    fi
    if [ -z "$GEMINI_API_KEY_VALUE" ]; then
        while true; do
            entered=$(ask "Gemini API key" "")
            if [ -z "$entered" ]; then
                warn "Boş bırakılırsa görsel analiz devre dışı kalır."
                if ask_yn "Yine de devam edeyim mi (görsel analiz olmadan)?" "h"; then
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
    ok "Gemini Vision: aktif"
else
    warn "Gemini Vision: kapalı (sadece transkripsiyon + metadata)"
fi

# ────────────────────────────────────────────────────────────────────
# Adım 3/4: Transkripsiyon dili
# ────────────────────────────────────────────────────────────────────
header "Adım 3/4: Transkripsiyon Dili"
cat <<EOF
faster-whisper hangi dile öncelik versin?

  ${BOLD}[1]${NC} Otomatik algılama   ${DIM}(önerilen — 99 dil)${NC}
  ${BOLD}[2]${NC} Türkçe              ${DIM}(tr)${NC}
  ${BOLD}[3]${NC} İngilizce           ${DIM}(en)${NC}
  ${BOLD}[4]${NC} Diğer               ${DIM}(ISO 639-1 kodu — fr, de, es, …)${NC}

EOF

lang_choice=$(ask "Seçimini yap" "1")
case "$lang_choice" in
    1|""|auto)  TRANSCRIPTION_LANG="auto" ;;
    2|tr|TR)    TRANSCRIPTION_LANG="tr"   ;;
    3|en|EN)    TRANSCRIPTION_LANG="en"   ;;
    4)
        custom=$(ask "ISO 639-1 dil kodu (örn: fr, de, es)" "auto")
        TRANSCRIPTION_LANG="${custom:-auto}"
        ;;
    *)
        # Doğrudan kod girilmiş olabilir
        TRANSCRIPTION_LANG="$lang_choice"
        ;;
esac

# Whisper model boyutu (gelişmiş tercih)
WHISPER_MODEL="medium"
if ask_yn "Whisper model boyutunu özelleştirmek ister misin?" "h"; then
    cat <<EOF

  ${BOLD}tiny${NC}    ~75MB    çok hızlı, düşük kalite
  ${BOLD}base${NC}    ~150MB   hızlı, orta kalite
  ${BOLD}small${NC}   ~500MB   dengeli
  ${BOLD}medium${NC}  ~1.5GB   ${DIM}(varsayılan)${NC} iyi kalite
  ${BOLD}large-v3${NC} ~3GB     en iyi kalite, yavaş

EOF
    WHISPER_MODEL=$(ask "Model" "medium")
fi

ok "Transkripsiyon dili: $TRANSCRIPTION_LANG · model: $WHISPER_MODEL"

# ────────────────────────────────────────────────────────────────────
# Adım 4/4: Kurulum
# ────────────────────────────────────────────────────────────────────
header "Adım 4/4: Kurulum"

echo "Aşağıdakileri yapacağım:"
echo "  ${DIM}•${NC} Temel araçları (ffmpeg, faster-whisper) kuracağım"
$WANT_INSTAGRAM && echo "  ${DIM}•${NC} Instagram için: instaloader"
$WANT_TIKTOK    && echo "  ${DIM}•${NC} TikTok için: yt-dlp"
$WANT_YOUTUBE   && echo "  ${DIM}•${NC} YouTube için: yt-dlp"
$WANT_TWITTER   && echo "  ${DIM}•${NC} Twitter/X için: bird CLI (npm)"
$GEMINI_ENABLED && echo "  ${DIM}•${NC} Gemini Vision: google-genai"
echo "  ${DIM}•${NC} Yapılandırma: ~/.social-media-scraper.env"
echo "  ${DIM}•${NC} Skill: ~/.claude/skills/social-media-scraper/"
echo ""

if ! ask_yn "Devam edeyim mi?" "e"; then
    err "Kurulum iptal edildi."
    exit 1
fi

# ── Temel araç kontrolü ─────────────────────────────────────────────
info "Sistem gereksinimleri kontrol ediliyor..."

need_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        err "Gerekli komut bulunamadı: $1"
        echo "    Yüklemek için: $2"
        exit 1
    fi
}

need_cmd python3 "https://www.python.org/downloads/"
need_cmd pip3    "Python ile birlikte gelir"
need_cmd git     "https://git-scm.com/downloads"
$WANT_TWITTER && need_cmd npm "https://nodejs.org/"
ok "Temel bağımlılıklar mevcut"

# ── ffmpeg ──────────────────────────────────────────────────────────
if ! command -v ffmpeg >/dev/null 2>&1; then
    warn "ffmpeg bulunamadı, yükleniyor..."
    if [ "$PLATFORM_OS" = "macos" ]; then
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

# ── Python paketleri (sadece seçilenler) ────────────────────────────
PIP_FLAGS="--upgrade --quiet"
if pip3 install --help 2>&1 | grep -q "break-system-packages"; then
    PIP_FLAGS="$PIP_FLAGS --break-system-packages"
fi

PIP_PACKAGES=("faster-whisper")
$WANT_INSTAGRAM && PIP_PACKAGES+=("instaloader")
($WANT_TIKTOK || $WANT_YOUTUBE) && PIP_PACKAGES+=("yt-dlp")
$GEMINI_ENABLED && PIP_PACKAGES+=("google-genai")

info "Python paketleri yükleniyor: ${PIP_PACKAGES[*]}"
# shellcheck disable=SC2086
pip3 install $PIP_FLAGS "${PIP_PACKAGES[@]}"
ok "Python paketleri yüklendi"

# ── bird CLI (Twitter) ──────────────────────────────────────────────
if $WANT_TWITTER; then
    if ! command -v bird >/dev/null 2>&1; then
        info "bird CLI yükleniyor (Twitter/X için)..."
        npm install -g @steipete/bird
        ok "bird CLI yüklendi"
    else
        ok "bird CLI zaten kurulu"
    fi
fi

# ── Yapılandırma dosyası ────────────────────────────────────────────
ENV_FILE="$HOME/.social-media-scraper.env"
info "Yapılandırma yazılıyor: $ENV_FILE"

# Mevcut dosya varsa yedekle
if [ -f "$ENV_FILE" ]; then
    cp "$ENV_FILE" "$ENV_FILE.bak.$(date +%s)"
    warn "Mevcut yapılandırma yedeklendi: $ENV_FILE.bak.*"
fi

cat > "$ENV_FILE" <<EOF
# Social Media Scraper — yapılandırma
# Bu dosya setup.sh tarafından oluşturuldu. Elle düzenleyebilirsin.

# Aktif platformlar (virgülle ayrılmış)
PLATFORMS=$PLATFORM_LIST

# Gemini video analizi
GEMINI_ENABLED=$GEMINI_ENABLED
GEMINI_API_KEY=$GEMINI_API_KEY_VALUE

# Transkripsiyon
TRANSCRIPTION_LANG=$TRANSCRIPTION_LANG
WHISPER_MODEL=$WHISPER_MODEL
EOF
chmod 600 "$ENV_FILE"
ok "Yapılandırma kaydedildi (sadece sen okuyabilirsin: chmod 600)"

# ── Skill'i yerleştir ───────────────────────────────────────────────
SKILL_DIR="$HOME/.claude/skills/social-media-scraper"
info "Skill yerleştiriliyor: $SKILL_DIR"
mkdir -p "$SKILL_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/SKILL.md" "$SKILL_DIR/SKILL.md"
ok "SKILL.md kopyalandı"

# ────────────────────────────────────────────────────────────────────
# Özet
# ────────────────────────────────────────────────────────────────────
echo ""
hr
printf "%s%s%s\n" "$BOLD$GREEN" "🎉  Kurulum tamamlandı!" "$NC"
hr
cat <<EOF

${BOLD}Özet${NC}
  Platformlar       : $PLATFORM_LIST
  Gemini Vision     : $([ "$GEMINI_ENABLED" = "true" ] && echo "aktif" || echo "kapalı")
  Transkripsiyon    : $TRANSCRIPTION_LANG ($WHISPER_MODEL)
  Yapılandırma      : $ENV_FILE
  Skill             : $SKILL_DIR/SKILL.md

${BOLD}Şimdi ne yapabilirsin?${NC}
  Claude Code'u yeniden başlat ve şunu dene:

    ${CYAN}"Bu reel'i analiz et: https://www.instagram.com/reel/<bir_link>/"${NC}

${DIM}Sorun yaşarsan: https://github.com/elbis330/social-media-scraper-skill/issues${NC}

EOF
