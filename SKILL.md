---
name: social-media-scraper
description: |
  Sosyal medya paylaşımlarından tüm verileri çeken ve analiz eden skill. Instagram (reel, post, story), TikTok, Twitter/X ve YouTube linklerinden içerik çeker. Metin, açıklama, yorumlar, beğeni/paylaşım sayıları, tarih bilgisi, hashtag'ler dahil tüm metadata'yı toplar. Video veya ses içeren paylaşımlarda otomatik olarak faster-whisper ile transkripsiyon yapar ve Gemini Vision ile görsel analiz uygular. MANDATORY TRIGGERS: herhangi bir sosyal medya linki paylaşıldığında (instagram.com, tiktok.com, x.com, twitter.com, youtube.com, youtu.be), "bu tweeti oku", "bu reeli çek", "bu videoyu analiz et", "şu paylaşıma bak", "bu linkteki içerik ne", veya herhangi bir sosyal medya URL'si içeren mesaj.
---

# Social Media Scraper

Sosyal medya paylaşımlarının tüm verilerini çeken, analiz eden ve video/ses içeriklerin transkripsiyonu + görsel analizini yapan skill.

## İlk Kurulum

Bu skill ilk kez çağrıldığında veya kullanıcı "kur", "ayarla", "setup", "yapılandır" derse, önce kurulum modunu başlat.

### Kurulum Algılama

Yapılandırma dosyası: `~/.social-media-scraper.env`. Dosya yoksa veya kullanıcı yeniden kurulum istiyorsa, aşağıdaki interaktif soruları sor.

```bash
test -f ~/.social-media-scraper.env || echo "İlk kurulum gerekli"
```

### Kurulum Soruları

Soruları **tek tek** sor, kullanıcı her birini cevaplasın. Cevaplara göre `~/.social-media-scraper.env` dosyasını oluştur ve **sadece** seçilen platformlara ait araçları kur.

**Soru 1 — Platformlar**

> "Hangi platformları kullanmak istiyorsun? Instagram, TikTok, Twitter/X, YouTube — hepsini seçebilirsin ya da sadece istediklerini. (varsayılan: hepsi)"

Cevabı virgülle ayrılmış küçük harf liste olarak normalize et: `instagram,tiktok,twitter,youtube`.

**Soru 2 — Gemini görsel analizi**

> "Gemini ile görsel video analizi aktif olsun mu? Bu, ekrandaki yazıları, ürünleri ve sahneleri okur — Whisper'ın çeviremeyeceği görsel bağlamı verir. Aktif etmek için ücretsiz bir Gemini API key gerekiyor (https://aistudio.google.com/apikey). Aktif olsun mu? (varsayılan: evet)"

Cevap evetse: "Gemini API key'ini yapıştır:" diye sor. Key'i `~/.social-media-scraper.env` içine yaz ama **terminal ekranına yazma**, **commit etme**, **logla**. Dosyayı `chmod 600` ile koru.

Cevap hayırsa: `GEMINI_ENABLED=false` olarak işaretle, google-genai kurma.

**Soru 3 — Transkripsiyon dili**

> "Varsayılan transkripsiyon dili ne olsun? Otomatik algılama (önerilen — 99 dil), Türkçe, İngilizce, ya da başka bir ISO 639-1 dil kodu (örn. fr, de, es). (varsayılan: otomatik)"

Değeri `auto`, `tr`, `en` veya ISO kodu olarak sakla.

### Yapılandırma Dosyası Formatı

`~/.social-media-scraper.env`:

```env
# Aktif platformlar (virgülle ayrılmış)
PLATFORMS=instagram,tiktok,twitter,youtube

# Gemini video analizi
GEMINI_ENABLED=true
GEMINI_API_KEY=AIza...

# Transkripsiyon
TRANSCRIPTION_LANG=auto
WHISPER_MODEL=medium
```

### Kurulum Adımları (cevaplara göre)

Sadece seçilen platformların araçlarını kur:

```bash
# Her zaman gerekli
pip install faster-whisper --break-system-packages
# ffmpeg: macOS → brew install ffmpeg | Linux → apt install ffmpeg

# Sadece seçilirse
# instagram:
pip install instaloader --break-system-packages
# tiktok veya youtube:
pip install yt-dlp --break-system-packages
# twitter:
npm install -g @steipete/bird
# gemini aktifse:
pip install google-genai --break-system-packages
```

### Sonra

Kurulum bittiğinde kullanıcıya kısa bir özet ver (hangi platformlar aktif, Gemini açık mı, dil ne) ve test için bir örnek link iste.

### Mevcut Yapılandırmayı Okuma

Skill çalışırken `~/.social-media-scraper.env` dosyasını oku ve seçimlere göre davran. Örn. `GEMINI_ENABLED=false` ise görsel analiz adımını atla. `TRANSCRIPTION_LANG=tr` ise Whisper'a `language="tr"` parametresini ver.

```bash
set -a
source ~/.social-media-scraper.env 2>/dev/null
set +a
```

`PLATFORMS` listesinde olmayan bir platforma link gelirse, kullanıcıya "Bu platform kurulu değil, eklemek ister misin?" diye sor.

## Genel Akış

1. Kullanıcı bir sosyal medya linki paylaşır
2. Platform otomatik algılanır (URL'den)
3. Platforma uygun araç ile tüm veriler çekilir
4. Video/ses içerik varsa: indir → ffmpeg ile ses çıkar → faster-whisper ile transkript al → Gemini ile görsel/ekran analizi → geçici dosyaları sil
5. Transkripsiyon + görsel analiz birleştirilerek tam bir anlayış oluşturulur
6. Sonuçları kullanıcıya temiz ve okunabilir şekilde sun

## Platform Algılama

URL'ye bakarak platformu belirle:
- `instagram.com` veya `instagr.am` → Instagram
- `tiktok.com` → TikTok
- `x.com` veya `twitter.com` → Twitter/X
- `youtube.com` veya `youtu.be` → YouTube

## Platform Bazlı Araçlar

### Twitter/X
Öncelik sırası:
1. `bird` CLI (npm paketi: @steipete/bird) — en kapsamlı, tweet + reply thread + medya bilgisi
2. Jina Reader (`curl -s "https://r.jina.ai/TWEET_URL"`) — yedek yöntem
3. Tarayıcı ile okuma — son çare

bird CLI kullanımı:
```bash
bird --urls "TWEET_URL"
```

bird kurulu değilse: `npm install -g @steipete/bird`
bird çalışması için Chrome cookie'leri gerekebilir, otomatik algılar.

### Instagram
Öncelik sırası:
1. `instaloader` (pip paketi) — reel, post, story indirme ve metadata
2. `instagrapi` (pip paketi) — daha kapsamlı API, giriş gerektirebilir
3. yt-dlp — yedek video indirme

instaloader kullanımı:
```bash
pip install instaloader --break-system-packages
instaloader -- -SHORTCODE
```

Shortcode URL'den çıkarılır: instagram.com/reel/SHORTCODE/ veya instagram.com/p/SHORTCODE/

Metadata çekme (Python):
```python
import instaloader
L = instaloader.Instaloader()
post = instaloader.Post.from_shortcode(L.context, "SHORTCODE")
print(f"Başlık: {post.caption}")
print(f"Beğeni: {post.likes}")
print(f"Yorum sayısı: {post.comments}")
print(f"Tarih: {post.date}")
print(f"Hashtag'ler: {post.caption_hashtags}")
```

### TikTok
Öncelik sırası:
1. yt-dlp ile video + metadata indirme
2. Jina Reader ile sayfa içeriği çekme

yt-dlp kullanımı:
```bash
yt-dlp --write-info-json --write-comments -o "downloads/%(id)s.%(ext)s" "TIKTOK_URL"
```

yt-dlp kurulu değilse: `pip install yt-dlp --break-system-packages`
TikTok için cookie gerekebilir: `yt-dlp --cookies-from-browser chrome "URL"`

### YouTube
yt-dlp ile video + metadata + yorumlar:
```bash
yt-dlp --write-info-json --write-comments --skip-download -o "downloads/%(id)s.%(ext)s" "YOUTUBE_URL"
```

Video transkripsiyonu gerekiyorsa (altyazı yoksa):
```bash
yt-dlp -f "bestaudio" -o "downloads/audio.%(ext)s" "YOUTUBE_URL"
```

## Transkripsiyon (Video/Ses İçerikler İçin)

Video veya ses içeren her paylaşımda otomatik olarak transkripsiyon yap. Kullanıcının ayrıca istemesine gerek yok.

### Adımlar:
1. Videoyu indir (platforma göre uygun araçla)
2. ffmpeg ile sesi çıkar:
```bash
ffmpeg -i video.mp4 -vn -acodec pcm_s16le -ar 16000 -ac 1 audio.wav
```
3. faster-whisper ile transkripsiyon:
```python
from faster_whisper import WhisperModel
model = WhisperModel("medium", compute_type="int8")
segments, info = model.transcribe("audio.wav")
print(f"Algılanan dil: {info.language} ({info.language_probability:.0%})")
for segment in segments:
    print(f"[{segment.start:.1f}s → {segment.end:.1f}s] {segment.text}")
```
4. Geçici video ve ses dosyalarını sil (yer kaplamasın)

faster-whisper kurulu değilse: `pip install faster-whisper --break-system-packages`
ffmpeg kurulu değilse: `brew install ffmpeg` (macOS) veya `apt install ffmpeg` (Linux)

## Video Analizi (Gemini Vision)

Video içeren paylaşımlarda sadece sesin transkripsiyonu yeterli değil. Ekranda akan yazılar, gösterilen ürünler, arayüzler, logolar, jestler, sahne geçişleri — bunların hepsi anlamın parçası. Whisper sadece konuşmayı çevirir; ekranda görüneni Gemini ile analiz et.

### Akış
1. Videoyu indir (yt-dlp / instaloader / vb.)
2. Whisper ile ses transkripsiyonu al (yukarıdaki bölüm)
3. Gemini File API ile videoyu yükle, analiz et
4. İki kaynağı birleştirip kullanıcıya sun
5. Geçici dosyaları sil

### API Key
Gemini API key'i `GEMINI_API_KEY` environment variable'ı üzerinden okunur. API key'i [Google AI Studio](https://aistudio.google.com/apikey) üzerinden ücretsiz alabilirsin.

Kurulum:
```bash
export GEMINI_API_KEY="your_api_key_here"
```

Kalıcı olarak shell config'e eklemek için:
```bash
echo 'export GEMINI_API_KEY="your_api_key_here"' >> ~/.zshrc   # macOS / zsh
echo 'export GEMINI_API_KEY="your_api_key_here"' >> ~/.bashrc  # Linux / bash
```

`.env` dosyası kullanıyorsan:
```bash
export GEMINI_API_KEY=$(grep "^GEMINI_API_KEY=" .env | cut -d= -f2- | tr -d '"' | tr -d "'" | tr -d ' ')
```

### Önemli: ASCII dosya yolu
Gemini SDK upload'da httpx, dosya adındaki Türkçe karakterleri (ı, ş, ç, ö, ğ) ASCII'ye çeviremeyip patlıyor. Yüklemeden önce videoyu `/tmp/video.mp4` gibi ASCII bir yola kopyala.

### Kod (yeni SDK: google-genai)
Eski `google.generativeai` paketi deprecated. Yeni `google-genai` paketini kullan:

```python
import os, time, shutil
from google import genai

src = "downloads/instagram_reel.mp4"
tmp = "/tmp/scraper_video.mp4"
shutil.copy(src, tmp)

client = genai.Client()  # GEMINI_API_KEY env var'dan okunur
f = client.files.upload(file=tmp)

while f.state.name == "PROCESSING":
    time.sleep(3)
    f = client.files.get(name=f.name)

if f.state.name != "ACTIVE":
    raise RuntimeError(f"Gemini upload failed: {f.state.name}")

prompt = (
    "Bu videoda neler oluyor? Şunları detaylı anlat: "
    "ekranda görünen yazılar/başlıklar, logolar, ürün isimleri, "
    "arayüzler (uygulama/website), gösterilen yer veya kişiler, "
    "anlatım sırasını ve önemli sahneleri. "
    "Türkçe yanıtla."
)
resp = client.models.generate_content(model="gemini-2.5-flash", contents=[f, prompt])
visual_analysis = resp.text

client.files.delete(name=f.name)
os.remove(tmp)
```

Kurulum:
```bash
pip install google-genai --break-system-packages
```

### Birleştirme
Whisper transkripti + Gemini görsel analizi birlikte tek bir anlatıma çevir. Örnek yapı:

- **Konuşma (Whisper):** "Bugün size yeni bir ürünü göstereceğim..."
- **Ekran/Görsel (Gemini):** "Video bir e-ticaret sitesinde ürün detay sayfasını gösteriyor, kullanıcı fiyat ve özelliklere odaklanıyor, iç/dış görsellerde geziniyor..."

Kullanıcıya akıcı paragraflar halinde anlat, "konuştuğu şey şu, ekranda gösterdiği şey şu" diye birleştirerek.

## Çıktı Formatı

Sonuçları kullanıcıya şu şekilde sun (basit, okunabilir, listesiz):

**Paylaşım bilgisi:** Kim paylaşmış, ne zaman, hangi platform
**İçerik:** Paylaşımın metni veya açıklaması
**Etkileşim:** Beğeni, yorum, paylaşım, görüntülenme sayıları
**Yorumlar:** Öne çıkan yorumların özeti (çok fazla varsa en dikkat çekici olanları seç)
**Transkripsiyon:** Video/ses varsa tam metin (zaman damgalı)

Kullanıcı bu işlerden pek anlamayan biri olabilir. Teknik jargon kullanma, basit ve akıcı paragraflarla anlat. Uzun listeler ve tablolar yerine doğal dilde özetle.

## Bağımlılıklar

Bu araçlar gerektiğinde otomatik kurulacak:
- bird CLI: `npm install -g @steipete/bird`
- instaloader: `pip install instaloader --break-system-packages`
- yt-dlp: `pip install yt-dlp --break-system-packages`
- faster-whisper: `pip install faster-whisper --break-system-packages`
- ffmpeg: `brew install ffmpeg` (macOS) veya `apt install ffmpeg` (Linux)
- google-genai (Gemini Vision): `pip install google-genai --break-system-packages` — kullanım için `GEMINI_API_KEY` env var gerekli

Her aracı kullanmadan önce kurulu olup olmadığını kontrol et. Kurulu değilse kur.

## Önemli Notlar

- Video/ses dosyaları geçicidir, transkripsiyon alındıktan sonra silinir
- Metin verileri (transkript, yorumlar, metadata) saklanabilir
- Bazı platformlar giriş gerektirebilir, bu durumda kullanıcıyı bilgilendir
- Hata alırsan bir sonraki yönteme geç, kullanıcıya sadece sonucu sun
- Cookie gerektiğinde `--cookies-from-browser chrome` kullan
