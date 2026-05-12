---
name: social-media-scraper
description: |
  Skill that pulls and analyzes all data from social media posts. Fetches content from Instagram (reel, post, story), TikTok, Twitter/X and YouTube links. Collects all metadata including text, description, comments, like/share counts, date info, hashtags. Automatically transcribes with faster-whisper and applies visual analysis with Gemini Vision on posts containing video or audio. MANDATORY TRIGGERS: whenever a social media link is shared (instagram.com, tiktok.com, x.com, twitter.com, youtube.com, youtu.be), "read this tweet", "fetch this reel", "analyze this video", "look at this post", "what is the content of this link", or any message containing a social media URL.
---

# Social Media Scraper

A skill that pulls all data from social media posts, analyzes them, and performs transcription + visual analysis for video/audio content.

## First-Time Setup

When this skill is invoked for the first time or when the user says "install", "configure", "setup", run the setup mode first.

### Setup Detection

Configuration file: `~/.social-media-scraper.env`. If the file does not exist or the user requests reinstallation, ask the interactive questions below.

```bash
test -f ~/.social-media-scraper.env || echo "First-time setup required"
```

### Setup Questions

Ask the questions **one by one**, letting the user answer each. Based on the answers, create the `~/.social-media-scraper.env` file and install **only** the tools for the selected platforms.

**Question 1 — Platforms**

> "Which platforms do you want to use? Instagram, TikTok, Twitter/X, YouTube — pick all of them or only the ones you want. (default: all)"

Normalize the answer as a comma-separated lowercase list: `instagram,tiktok,twitter,youtube`.

**Question 2 — Gemini visual analysis**

> "Should Gemini visual video analysis be enabled? This reads on-screen text, products, and scenes — it provides visual context that Whisper cannot translate. Enabling it requires a free Gemini API key (https://aistudio.google.com/apikey). Enable it? (default: yes)"

If yes: ask "Paste your Gemini API key:". Write the key into `~/.social-media-scraper.env` but **do not print to terminal**, **do not commit**, **do not log**. Protect the file with `chmod 600`.

If no: mark `GEMINI_ENABLED=false`, do not install google-genai.

**Question 3 — Transcription language**

> "What should the default transcription language be? Auto-detect (recommended — 99 languages), Turkish, English, or another ISO 639-1 language code (e.g. fr, de, es). (default: auto)"

Store the value as `auto`, `tr`, `en` or an ISO code.

### Configuration File Format

`~/.social-media-scraper.env`:

```env
# Active platforms (comma-separated)
PLATFORMS=instagram,tiktok,twitter,youtube

# Gemini video analysis
GEMINI_ENABLED=true
GEMINI_API_KEY=AIza...

# Transcription
TRANSCRIPTION_LANG=auto
WHISPER_MODEL=medium
```

### Installation Steps (based on answers)

Install only the tools for the selected platforms:

```bash
# Always required
pip install faster-whisper --break-system-packages
# ffmpeg: macOS → brew install ffmpeg | Linux → apt install ffmpeg

# Only if selected
# instagram:
pip install instaloader --break-system-packages
# tiktok or youtube:
pip install yt-dlp --break-system-packages
# twitter:
npm install -g @steipete/bird
# if gemini enabled:
pip install google-genai --break-system-packages
```

### After Setup

When setup is complete, give the user a short summary (which platforms are active, whether Gemini is enabled, what language) and ask for a sample link to test.

### Reading the Current Configuration

When the skill is running, read the `~/.social-media-scraper.env` file and behave according to the selections. E.g. if `GEMINI_ENABLED=false`, skip the visual analysis step. If `TRANSCRIPTION_LANG=tr`, pass `language="tr"` to Whisper.

```bash
set -a
source ~/.social-media-scraper.env 2>/dev/null
set +a
```

If a link from a platform not in the `PLATFORMS` list arrives, ask the user "This platform is not installed, would you like to add it?".

## General Flow

1. The user shares a social media link
2. The platform is auto-detected (from the URL)
3. All data is fetched with the appropriate tool for the platform
4. If video/audio content exists: download → extract audio with ffmpeg → transcribe with faster-whisper → analyze visuals/screen with Gemini → delete temporary files
5. Transcription + visual analysis are merged into a full understanding
6. Present results to the user in a clean and readable way

## Platform Detection

Detect the platform by looking at the URL:
- `instagram.com` or `instagr.am` → Instagram
- `tiktok.com` → TikTok
- `x.com` or `twitter.com` → Twitter/X
- `youtube.com` or `youtu.be` → YouTube

## Per-Platform Tools

### Twitter/X
Priority order:
1. `bird` CLI (npm package: @steipete/bird) — most comprehensive, tweet + reply thread + media info
2. Jina Reader (`curl -s "https://r.jina.ai/TWEET_URL"`) — fallback method
3. Reading via browser — last resort

bird CLI usage:
```bash
bird --urls "TWEET_URL"
```

If bird is not installed: `npm install -g @steipete/bird`
bird may need Chrome cookies to work, it auto-detects them.

### Instagram
Priority order:
1. `instaloader` (pip package) — reel, post, story download and metadata
2. `instagrapi` (pip package) — more comprehensive API, may require login
3. yt-dlp — fallback video download

instaloader usage:
```bash
pip install instaloader --break-system-packages
instaloader -- -SHORTCODE
```

The shortcode is extracted from the URL: instagram.com/reel/SHORTCODE/ or instagram.com/p/SHORTCODE/

Fetching metadata (Python):
```python
import instaloader
L = instaloader.Instaloader()
post = instaloader.Post.from_shortcode(L.context, "SHORTCODE")
print(f"Caption: {post.caption}")
print(f"Likes: {post.likes}")
print(f"Comment count: {post.comments}")
print(f"Date: {post.date}")
print(f"Hashtags: {post.caption_hashtags}")
```

### TikTok
Priority order:
1. Download video + metadata with yt-dlp
2. Fetch page content with Jina Reader

yt-dlp usage:
```bash
yt-dlp --write-info-json --write-comments -o "downloads/%(id)s.%(ext)s" "TIKTOK_URL"
```

If yt-dlp is not installed: `pip install yt-dlp --break-system-packages`
Cookies may be required for TikTok: `yt-dlp --cookies-from-browser chrome "URL"`

### YouTube
Video + metadata + comments with yt-dlp:
```bash
yt-dlp --write-info-json --write-comments --skip-download -o "downloads/%(id)s.%(ext)s" "YOUTUBE_URL"
```

If video transcription is needed (when no captions are available):
```bash
yt-dlp -f "bestaudio" -o "downloads/audio.%(ext)s" "YOUTUBE_URL"
```

## Transcription (For Video/Audio Content)

Automatically transcribe every post containing video or audio. The user does not need to ask separately.

### Steps:
1. Download the video (with the appropriate tool per platform)
2. Extract audio with ffmpeg:
```bash
ffmpeg -i video.mp4 -vn -acodec pcm_s16le -ar 16000 -ac 1 audio.wav
```
3. Transcribe with faster-whisper:
```python
from faster_whisper import WhisperModel
model = WhisperModel("medium", compute_type="int8")
segments, info = model.transcribe("audio.wav")
print(f"Detected language: {info.language} ({info.language_probability:.0%})")
for segment in segments:
    print(f"[{segment.start:.1f}s → {segment.end:.1f}s] {segment.text}")
```
4. Delete temporary video and audio files (to save space)

If faster-whisper is not installed: `pip install faster-whisper --break-system-packages`
If ffmpeg is not installed: `brew install ffmpeg` (macOS) or `apt install ffmpeg` (Linux)

## Video Analysis (Gemini Vision)

For posts containing video, transcribing the audio alone is not enough. On-screen text, displayed products, interfaces, logos, gestures, scene transitions — all of these are part of the meaning. Whisper only translates speech; use Gemini to analyze what appears on screen.

### Flow
1. Download the video (yt-dlp / instaloader / etc.)
2. Transcribe audio with Whisper (section above)
3. Upload the video with Gemini File API, analyze it
4. Merge the two sources and present to the user
5. Delete temporary files

### API Key
The Gemini API key is read from the `GEMINI_API_KEY` environment variable. You can get an API key for free from [Google AI Studio](https://aistudio.google.com/apikey).

Setup:
```bash
export GEMINI_API_KEY="your_api_key_here"
```

To add it permanently to your shell config:
```bash
echo 'export GEMINI_API_KEY="your_api_key_here"' >> ~/.zshrc   # macOS / zsh
echo 'export GEMINI_API_KEY="your_api_key_here"' >> ~/.bashrc  # Linux / bash
```

If you use a `.env` file:
```bash
export GEMINI_API_KEY=$(grep "^GEMINI_API_KEY=" .env | cut -d= -f2- | tr -d '"' | tr -d "'" | tr -d ' ')
```

### Important: ASCII file path
In Gemini SDK upload, httpx cannot convert non-ASCII characters (ı, ş, ç, ö, ğ) in the filename and crashes. Before uploading, copy the video to an ASCII path like `/tmp/video.mp4`.

### Code (new SDK: google-genai)
The old `google.generativeai` package is deprecated. Use the new `google-genai` package:

```python
import os, time, shutil
from google import genai

src = "downloads/instagram_reel.mp4"
tmp = "/tmp/scraper_video.mp4"
shutil.copy(src, tmp)

client = genai.Client()  # read from GEMINI_API_KEY env var
f = client.files.upload(file=tmp)

while f.state.name == "PROCESSING":
    time.sleep(3)
    f = client.files.get(name=f.name)

if f.state.name != "ACTIVE":
    raise RuntimeError(f"Gemini upload failed: {f.state.name}")

prompt = (
    "What is happening in this video? Describe in detail: "
    "on-screen text/titles, logos, product names, "
    "interfaces (app/website), locations or people shown, "
    "the narrative order and key scenes. "
    "Respond in English."
)
resp = client.models.generate_content(model="gemini-2.5-flash", contents=[f, prompt])
visual_analysis = resp.text

client.files.delete(name=f.name)
os.remove(tmp)
```

Install:
```bash
pip install google-genai --break-system-packages
```

### Merging
Combine the Whisper transcript and Gemini visual analysis into a single narrative. Example structure:

- **Speech (Whisper):** "Today I'm going to show you a new product..."
- **Screen/Visual (Gemini):** "The video shows a product detail page on an e-commerce site, the user is focused on price and features, browsing interior/exterior images..."

Present it to the user in fluent paragraphs, merging "what they said" with "what they showed on screen".

## Output Format

Present results to the user as follows (simple, readable, no lists):

**Post info:** Who posted, when, on which platform
**Content:** The post's text or description
**Engagement:** Like, comment, share, view counts
**Comments:** Summary of standout comments (if there are many, pick the most notable ones)
**Transcription:** Full text with timestamps if there is video/audio

The user may not be a technical person. Avoid jargon, explain in simple, fluent paragraphs. Summarize in natural language rather than long lists and tables.

## Dependencies

These tools will be installed automatically when needed:
- bird CLI: `npm install -g @steipete/bird`
- instaloader: `pip install instaloader --break-system-packages`
- yt-dlp: `pip install yt-dlp --break-system-packages`
- faster-whisper: `pip install faster-whisper --break-system-packages`
- ffmpeg: `brew install ffmpeg` (macOS) or `apt install ffmpeg` (Linux)
- google-genai (Gemini Vision): `pip install google-genai --break-system-packages` — requires `GEMINI_API_KEY` env var to use

Check whether each tool is installed before using it. Install if not.

## Important Notes

- Video/audio files are temporary, deleted after transcription is taken
- Text data (transcript, comments, metadata) can be stored
- Some platforms may require login, in that case inform the user
- If you get an error, try the next method, present only the result to the user
- Use `--cookies-from-browser chrome` when cookies are needed
