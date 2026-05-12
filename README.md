# 🎬 Social Media Scraper Skill for Claude Code

> **Tek link at, Claude her şeyi getirsin.** Instagram reel, TikTok video, Twitter thread, YouTube video — fark etmez. Metin, yorumlar, beğeniler, transkripsiyon **ve** ekranda ne olduğunu Gemini Vision ile analiz ederek tek bir akıcı özet olarak sunar.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Skill-7C3AED)](https://claude.com/claude-code)
[![Platforms](https://img.shields.io/badge/Platforms-Instagram%20%7C%20TikTok%20%7C%20X%20%7C%20YouTube-blue)](#-desteklenen-platformlar)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](#-katkıda-bulunma)

---

## 🤔 Bu Skill Ne İşe Yarıyor?

Bir sosyal medya linki gördün ama açmaya üşeniyorsun. Ya da videoyu izlemeden ne anlattığını öğrenmek istiyorsun. Bu skill tam olarak bunu çözüyor:

```
Sen: https://www.instagram.com/reel/Cxyz.../

Claude: Bu reel'de @kullaniciadi yeni bir kahve makinesi tanıtıyor.
        12,432 beğeni, 248 yorum almış.
        Videoda anlatım: "Bu makineyle 3 dakikada espresso..."
        Ekranda görünenler: La Marzocco Linea Mini cihazı,
        bir kafede çekilmiş, fiyat etiketi 24.500 TL...
```

**Tek linkten 4 katman bilgi:**
1. 📊 Metadata (kim, ne zaman, kaç beğeni)
2. 💬 Yorumlar (en dikkat çekici olanlar)
3. 🎙️ Konuşma transkripsiyonu (faster-whisper)
4. 👁️ Ekran/görsel analizi (Gemini Vision)

---

## 🌐 Desteklenen Platformlar

| Platform | Metadata | Yorumlar | Video İndirme | Transkripsiyon | Görsel Analiz |
|----------|----------|----------|---------------|----------------|---------------|
| 📸 **Instagram** (post, reel, story) | ✅ | ✅ | ✅ | ✅ | ✅ |
| 🎵 **TikTok** | ✅ | ✅ | ✅ | ✅ | ✅ |
| 🐦 **Twitter / X** | ✅ | ✅ (thread) | ✅ | ✅ | ✅ |
| 📺 **YouTube** | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## ✨ Özellikler

- 🔗 **Otomatik platform algılama** — Link at, gerisini düşünme
- 📝 **Tam metadata** — Beğeni, yorum, paylaşım, tarih, hashtag
- 💬 **Yorumların özeti** — En dikkat çekici yorumlar otomatik seçilir
- 🎙️ **Whisper transkripsiyonu** — Video/ses içerik zaman damgalı metne döner
- 👁️ **Gemini Vision analizi** — Ekrandaki yazılar, ürünler, arayüzler, sahneler okunur
- 🧹 **Otomatik temizlik** — Geçici video/ses dosyaları analiz sonrası silinir
- 🔄 **Çoklu fallback** — Bir araç çalışmazsa diğerine geçer (bird → Jina → tarayıcı)
- 🇹🇷 **Türkçe-friendly** — Türkçe içerikleri doğru anlar ve Türkçe yanıt verir

---

## 📦 Kurulum

İki kurulum yöntemi var. İlkini ne yaptığını anlamayan birine ver — bütün soruları Claude soruyor. İkincisi klasik terminal akışı.

### Yöntem 1 — Claude Code ile (önerilen)

Claude Code'da skill kuruluysa, sadece şunu yaz:

```
social-media-scraper skill'ini kur
```

Claude sırasıyla şunları soracak:
1. Hangi platformlar? (Instagram, TikTok, Twitter/X, YouTube — hepsi veya seçim)
2. Gemini ile görsel video analizi olsun mu? (evetse API key'i ister)
3. Transkripsiyon dili? (otomatik / tr / en / diğer)

Cevaplara göre **sadece gerekli araçları** kurar ve yapılandırmayı `~/.social-media-scraper.env` dosyasına yazar.

### Yöntem 2 — Terminal'den interaktif kurulum

```bash
git clone https://github.com/elbis330/social-media-scraper-skill.git
cd social-media-scraper-skill
chmod +x setup.sh
./setup.sh
```

`setup.sh` aynı soruları renkli, adım adım sorar ve seçimlere göre kurar. Yapılandırma `~/.social-media-scraper.env` içine kaydedilir (chmod 600 ile korunur).

### Yöntem 3 — Hızlı, sorusuz kurulum

Bütün araçları sormadan kurmak istersen:

```bash
git clone https://github.com/elbis330/social-media-scraper-skill.git
cd social-media-scraper-skill
chmod +x install.sh
./install.sh
```

`install.sh` hiçbir şey sormaz, tüm platformlara ait tüm araçları kurar (yt-dlp, instaloader, faster-whisper, google-genai, bird, ffmpeg).

### Manuel Kurulum

#### 1. Skill'i Yerleştir

```bash
mkdir -p ~/.claude/skills/social-media-scraper
cp SKILL.md ~/.claude/skills/social-media-scraper/SKILL.md
```

#### 2. Bağımlılıkları Kur

```bash
# Python paketleri
pip install yt-dlp instaloader faster-whisper google-genai --break-system-packages

# Node paketi (Twitter/X için)
npm install -g @steipete/bird

# ffmpeg (transkripsiyon için)
brew install ffmpeg          # macOS
sudo apt install ffmpeg      # Linux (Debian/Ubuntu)
```

#### 3. Gemini API Key Ayarla

[Google AI Studio](https://aistudio.google.com/apikey) üzerinden **ücretsiz** API key al, ardından:

```bash
echo 'export GEMINI_API_KEY="your_api_key_here"' >> ~/.zshrc
source ~/.zshrc
```

#### 4. Doğrula

Claude Code'u yeniden başlat ve test et:

```
Bu reel'i analiz et: https://www.instagram.com/reel/EXAMPLE/
```

---

## 🚀 Kullanım Örnekleri

### Instagram Reel'i Çek

```
Kullanıcı: Bu reel'de ne anlatıyor?
           https://www.instagram.com/reel/Cxyz12345/

Claude:    [otomatik olarak indirir, transkripsiyon yapar, görselini analiz eder]
           Paylaşan: @kullaniciadi (45.2K takipçi)
           Tarih: 8 Mart 2026, 14:32
           Beğeni: 12,432  ·  Yorum: 248

           Videoda kullanıcı yeni bir kahve makinesini tanıtıyor.
           Ekranda La Marzocco Linea Mini cihazı görünüyor, bir
           kafede çekilmiş. Anlatımında "3 dakikada profesyonel
           espresso" vurgusu var. Yorumlarda çoğunluk fiyatın
           pahalı olduğunu söylüyor.
```

### Twitter Thread Oku

```
Kullanıcı: Bu thread'i özetle:
           https://x.com/example/status/1234567890

Claude:    [bird CLI ile tüm thread'i çeker]
           [özet sunar]
```

### TikTok Trend Analizi

```
Kullanıcı: Bu TikTok'ta neden bu kadar yorum var?
           https://www.tiktok.com/@user/video/123

Claude:    [video indirir, transkript + görsel analiz]
           [en dikkat çekici yorumları gruplayıp sunar]
```

### YouTube Video Özeti

```
Kullanıcı: Bu video uzun, beni 20 saniyede özetle:
           https://www.youtube.com/watch?v=abc123

Claude:    [yt-dlp ile metadata + altyazı çeker, yoksa transkript yapar]
           [özet sunar]
```

---

## 🛠️ Gereksinimler

| Bağımlılık | Versiyon | Niye? |
|------------|----------|-------|
| Python | 3.10+ | yt-dlp, instaloader, faster-whisper, google-genai |
| Node.js | 18+ | bird CLI (Twitter/X) |
| ffmpeg | herhangi | Video → ses dönüşümü |
| Claude Code | en son | Skill çalıştırma |
| **Gemini API Key** | — | Görsel analiz için ([ücretsiz](https://aistudio.google.com/apikey)) |

> **Not:** Tüm Python paketleri sistemsel olarak `--break-system-packages` ile kuruluyor. Virtualenv kullanmak istersen `install.sh` içindeki ilgili komutları düzenle.

---

## 🔧 Mimari

```
Sosyal medya linki
        │
        ▼
┌───────────────────┐
│ Platform algıla   │ (regex: instagram.com / tiktok.com / x.com / youtube.com)
└────────┬──────────┘
         ▼
┌───────────────────┐
│ Metadata + medya  │ (bird / instaloader / yt-dlp)
│ indir             │
└────────┬──────────┘
         ▼
┌───────────────────┐    ┌─────────────────────┐
│ Ses çıkar (ffmpeg)│ ─→ │ faster-whisper      │ (zaman damgalı transkript)
└────────┬──────────┘    └─────────────────────┘
         ▼
┌───────────────────┐
│ Gemini Vision     │ (ekrandaki yazılar, ürünler, arayüzler)
└────────┬──────────┘
         ▼
┌───────────────────┐
│ Birleştir + sun   │ (transkript + görsel → tek akıcı özet)
└───────────────────┘
```

---

## ❓ SSS

**S: Bu skill ücretli mi?**
C: Hayır. Gemini API key'i Google AI Studio üzerinden ücretsiz alınıyor (cömert kota var). Diğer her şey açık kaynak.

**S: Login gerektiren özel paylaşımları çekebilir mi?**
C: Hayır. Sadece public içerik. Instagram bazı durumlarda cookie ister, `--cookies-from-browser chrome` ile çözülür.

**S: Transkripsiyon Türkçe destekliyor mu?**
C: Evet. faster-whisper 99 dil destekliyor, dil otomatik algılanır.

**S: Gemini API key'im yok, yine de çalışır mı?**
C: Evet ama görsel analiz yapamaz. Sadece transkripsiyon + metadata + yorumlar gelir.

**S: Windows desteği var mı?**
C: Test edilmedi. Kurulum scripti macOS/Linux için. WSL altında çalışması beklenir.

---

## 🤝 Katkıda Bulunma

PR'lar memnuniyetle karşılanır. Eklenmek istenenler:

- [ ] Threads (Meta) desteği
- [ ] Reddit post desteği
- [ ] LinkedIn paylaşım desteği
- [ ] Windows için install.ps1
- [ ] Docker image
- [ ] Çoklu link batch işleme

İşleyiş:
1. Fork et
2. Branch aç (`git checkout -b feature/threads-support`)
3. Commit (`git commit -m 'feat: add Threads support'`)
4. Push (`git push origin feature/threads-support`)
5. PR aç

---

## 📜 Lisans

MIT — bkz. [LICENSE](LICENSE)

---

## 🙏 Teşekkürler

Bu skill şu projelerin sırtında yükseliyor:

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) — evrensel medya indirici
- [instaloader](https://github.com/instaloader/instaloader) — Instagram çekme
- [faster-whisper](https://github.com/SYSTRAN/faster-whisper) — hızlı yerel transkripsiyon
- [bird](https://github.com/steipete/bird) — Twitter/X CLI
- [google-genai](https://github.com/googleapis/python-genai) — Gemini Python SDK

---

<p align="center">
  <b>🌟 Beğendiysen yıldız bırakmayı unutma!</b><br>
  <sub>Made with ☕ for the Claude Code community</sub>
</p>
