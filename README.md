# 🎬 Social Media Scraper Skill

> **Drop a single link, and your AI agent fetches everything.** Instagram reel, TikTok video, Twitter thread, YouTube video — doesn't matter. Text, comments, likes, transcription **and** analysis of what's on screen via Gemini Vision, all delivered as a single fluent summary.

A portable, tool-agnostic **Agent Skill**: a single `SKILL.md` plus install scripts that work with any agentic AI coding assistant that supports the skill format.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Agent Skill](https://img.shields.io/badge/Agent-Skill-7C3AED)](#-installation)
[![Platforms](https://img.shields.io/badge/Platforms-Instagram%20%7C%20TikTok%20%7C%20X%20%7C%20YouTube-blue)](#-supported-platforms)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](#-contributing)

---

## 🎥 Demo

<div align="center">

https://github.com/user-attachments/assets/82103420-9e30-4337-8ecf-4d88783b4bdd

</div>

---

## 🤔 Why?

Social media posts contain valuable data locked behind platform walls. Whether you're a researcher tracking trends, a marketer analyzing competitor content, a developer building datasets, or a journalist verifying sources — you need structured access to this data.

This skill turns any social media link into structured, actionable data:

- **🔬 Research & Analysis** — Track conversations, extract engagement metrics, analyze sentiment across platforms. No manual copy-pasting.
- **📡 Content Monitoring** — Monitor brand mentions, competitor activity, or industry trends. Get full post data including comments and replies.
- **♿ Accessibility** — Video content is inaccessible to many. Auto-transcription + AI video analysis makes visual content searchable and readable.
- **🧱 Development & Datasets** — Build training datasets, content pipelines, or analytics dashboards from real social media data.
- **📰 Journalism & OSINT** — Verify sources, archive posts before deletion, extract metadata for fact-checking.

**4 layers of info from a single link:**
1. 📊 Metadata (who, when, how many likes)
2. 💬 Comments (the most notable ones)
3. 🎙️ Speech transcription (faster-whisper)
4. 👁️ Screen/visual analysis (Gemini Vision)

---

## 🌐 Supported Platforms

| Platform | Metadata | Comments | Video Download | Transcription | Visual Analysis |
|----------|----------|----------|----------------|---------------|-----------------|
| 📸 **Instagram** (post, reel, story) | ✅ | ✅ | ✅ | ✅ | ✅ |
| 🎵 **TikTok** | ✅ | ✅ | ✅ | ✅ | ✅ |
| 🐦 **Twitter / X** | ✅ | ✅ (thread) | ✅ | ✅ | ✅ |
| 📺 **YouTube** | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## ✨ Features

- 🔗 **Automatic platform detection** — Drop a link, don't think about the rest
- 📝 **Full metadata** — Likes, comments, shares, date, hashtags
- 💬 **Comment summary** — The most notable comments are auto-selected
- 🎙️ **Whisper transcription** — Video/audio content turned into timestamped text
- 👁️ **Gemini Vision analysis** — On-screen text, products, interfaces, scenes are read
- 🧹 **Automatic cleanup** — Temporary video/audio files are removed after analysis
- 🔄 **Multi-fallback** — If one tool fails, it switches to another (bird → Jina → browser)
- 🌍 **Multilingual** — Whisper auto-detects 99 languages, content is understood correctly

---

## 📦 Installation

There are three installation methods. Give the first one to someone who doesn't know what they're doing — the agent asks all the questions. The others are the classic terminal flow.

### Method 1 — Through your AI coding agent (recommended)

Once the skill is installed in your agent, just type:

```
install the social-media-scraper skill
```

The agent will ask the following in order:
1. Which platforms? (Instagram, TikTok, Twitter/X, YouTube — all or a selection)
2. Should Gemini visual video analysis be enabled? (if yes, asks for the API key)
3. Transcription language? (auto / tr / en / other)

Based on the answers, it installs **only the required tools** and writes the configuration to `~/.social-media-scraper.env`.

### Method 2 — Interactive setup from terminal

```bash
git clone https://github.com/elbis330/social-media-scraper-skill.git
cd social-media-scraper-skill
chmod +x setup.sh
./setup.sh
```

`setup.sh` asks the same questions in color, step by step, and installs based on your selections. The configuration is saved to `~/.social-media-scraper.env` (protected with chmod 600).

### Method 3 — Quick, no-questions install

If you want to install all tools without being asked:

```bash
git clone https://github.com/elbis330/social-media-scraper-skill.git
cd social-media-scraper-skill
chmod +x install.sh
./install.sh
```

`install.sh` asks nothing and installs all tools for all platforms (yt-dlp, instaloader, faster-whisper, google-genai, bird, ffmpeg).

### Manual Installation

#### 1. Place the Skill

Copy `SKILL.md` into the directory your agent loads skills from. Point `AGENT_SKILLS_DIR` at that directory (the install scripts read this variable), then copy the skill into place:

```bash
# Set this to your agent's skills directory.
export AGENT_SKILLS_DIR="$HOME/.agent-skills"

mkdir -p "$AGENT_SKILLS_DIR/social-media-scraper"
cp SKILL.md "$AGENT_SKILLS_DIR/social-media-scraper/SKILL.md"
```

#### 2. Install Dependencies

```bash
# Python packages
pip install yt-dlp instaloader faster-whisper google-genai --break-system-packages

# Node package (for Twitter/X)
npm install -g @steipete/bird

# ffmpeg (for transcription)
brew install ffmpeg          # macOS
sudo apt install ffmpeg      # Linux (Debian/Ubuntu)
```

#### 3. Set the Gemini API Key

Get a **free** API key from [Google AI Studio](https://aistudio.google.com/apikey), then:

```bash
echo 'export GEMINI_API_KEY="your_api_key_here"' >> ~/.zshrc
source ~/.zshrc
```

#### 4. Verify

Restart your AI agent and test:

```
Analyze this reel: https://www.instagram.com/reel/EXAMPLE/
```

---

## 🚀 Usage Examples

### Fetch an Instagram Reel

```
User:   What is this reel about?
        https://www.instagram.com/reel/Cxyz12345/

Agent:  [automatically downloads, transcribes, analyzes visuals]
        Posted by: @username (45.2K followers)
        Date: March 8, 2026, 14:32
        Likes: 12,432  ·  Comments: 248

        In the video the user introduces a new coffee machine.
        The La Marzocco Linea Mini device is shown on screen, filmed
        in a cafe. The narration emphasizes "professional espresso
        in 3 minutes". The majority of comments say the price is
        too high.
```

### Read a Twitter Thread

```
User:   Summarize this thread:
        https://x.com/example/status/1234567890

Agent:  [pulls the entire thread with bird CLI]
        [presents a summary]
```

### TikTok Trend Analysis

```
User:   Why does this TikTok have so many comments?
        https://www.tiktok.com/@user/video/123

Agent:  [downloads video, transcribes + visual analysis]
        [groups and presents the most notable comments]
```

### YouTube Video Summary

```
User:   This video is long, summarize it for me in 20 seconds:
        https://www.youtube.com/watch?v=abc123

Agent:  [pulls metadata + captions with yt-dlp, transcribes if absent]
        [presents a summary]
```

---

## 🛠️ Requirements

| Dependency | Version | Why? |
|------------|---------|------|
| Python | 3.10+ | yt-dlp, instaloader, faster-whisper, google-genai |
| Node.js | 18+ | bird CLI (Twitter/X) |
| ffmpeg | any | Video → audio conversion |
| An agentic AI coding assistant | — | Runs the skill (any agent that supports the skill format) |
| **Gemini API Key** | — | For visual analysis ([free](https://aistudio.google.com/apikey)) |

> **Note:** All Python packages are installed system-wide with `--break-system-packages`. If you want to use a virtualenv, edit the relevant commands inside `install.sh`.

---

## 🔧 Architecture

```
Social media link
        │
        ▼
┌───────────────────┐
│ Detect platform   │ (regex: instagram.com / tiktok.com / x.com / youtube.com)
└────────┬──────────┘
         ▼
┌───────────────────┐
│ Metadata + media  │ (bird / instaloader / yt-dlp)
│ download          │
└────────┬──────────┘
         ▼
┌───────────────────┐    ┌─────────────────────┐
│ Extract audio     │ ─→ │ faster-whisper      │ (timestamped transcript)
│ (ffmpeg)          │    └─────────────────────┘
└────────┬──────────┘
         ▼
┌───────────────────┐
│ Gemini Vision     │ (on-screen text, products, interfaces)
└────────┬──────────┘
         ▼
┌───────────────────┐
│ Merge + present   │ (transcript + visual → one fluent summary)
└───────────────────┘
```

---

## ❓ FAQ

**Q: Is this skill paid?**
A: No. The Gemini API key is free via Google AI Studio (generous quota). Everything else is open source.

**Q: Can it fetch private posts that require login?**
A: No. Only public content. Instagram may ask for cookies in some cases, which can be solved with `--cookies-from-browser chrome`.

**Q: Does transcription support languages other than English?**
A: Yes. faster-whisper supports 99 languages, and the language is auto-detected.

**Q: I don't have a Gemini API key, will it still work?**
A: Yes, but it cannot do visual analysis. Only transcription + metadata + comments will be provided.

**Q: Does it work on Windows?**
A: Yes. All dependencies (bird CLI, instaloader, yt-dlp, faster-whisper, google-genai) are cross-platform and work on Windows. Install ffmpeg via `choco install ffmpeg` or `winget install ffmpeg`. For bird CLI, install Node.js first, then `npm install -g @steipete/bird`. The `setup.sh` script supports macOS and Linux only — on Windows, install dependencies manually using the commands above, or run setup under WSL.

---

## 🤝 Contributing

PRs are welcome. Wanted additions:

- [ ] Threads (Meta) support
- [ ] Reddit post support
- [ ] LinkedIn post support
- [ ] install.ps1 for Windows
- [ ] Docker image
- [ ] Multi-link batch processing

Workflow:
1. Fork
2. Create a branch (`git checkout -b feature/threads-support`)
3. Commit (`git commit -m 'feat: add Threads support'`)
4. Push (`git push origin feature/threads-support`)
5. Open a PR

---

## 📜 License

MIT — see [LICENSE](LICENSE)

---

## 🙏 Acknowledgments

This skill stands on the shoulders of these projects:

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) — universal media downloader
- [instaloader](https://github.com/instaloader/instaloader) — Instagram scraping
- [faster-whisper](https://github.com/SYSTRAN/faster-whisper) — fast local transcription
- [bird](https://github.com/steipete/bird) — Twitter/X CLI
- [google-genai](https://github.com/googleapis/python-genai) — Gemini Python SDK

---

<p align="center">
  <b>🌟 If you liked it, don't forget to leave a star!</b><br>
  <sub>Made with ☕ for the open-source community</sub>
</p>
