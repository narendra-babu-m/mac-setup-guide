# YouTube Transcript — Fallback Recipe

**Purpose:** Reproduce a clean, timestamped transcript from any YouTube video in one command, even when the standard Python library (`youtube-transcript-api`) is broken because YouTube changed their transcript endpoint format.

**Verified working:** 2026-09-10 on macOS 26.6 with `yt-dlp 2026.6.9` (Homebrew).

---

## When to use this

The primary tool (Hermes skill `media/youtube-content` → `fetch_transcript.py`) uses `youtube-transcript-api`. That library breaks periodically — verified failure mode is `{"error": "no element found: line 1, column 0"}` (YouTube returns HTML/empty XML instead of the expected transcript format).

When that happens, this fallback uses `yt-dlp` to grab the auto-generated VTT subtitles and reconstructs a clean transcript locally. It has no Python deps beyond stdlib.

## Prerequisites (already in the repo Brewfile)

```bash
brew "yt-dlp"        # already in Brewfile line 91
brew "ffmpeg"        # already in Brewfile line 90 (not strictly needed for subs-only)
```

Fresh-Mac bootstrap: `bash bootstrap.sh` (which runs `brew bundle`) installs both. No manual step.

## One-liner (raw yt-dlp, no dedup)

```bash
cd /tmp && yt-dlp \
  --write-auto-subs --write-subs \
  --sub-langs "en.*,en" \
  --skip-download --sub-format vtt \
  --no-update \
  -o "yt-%(id)s.%(ext)s" \
  "https://www.youtube.com/watch?v=VIDEO_ID"
# produces yt-VIDEO_ID.en.vtt (and yt-VIDEO_ID.en-orig.vtt if both exist)
```

This gets you the VTT file, but auto-generated YouTube subtitles have a **rolling-caption problem**: each cue duplicates the previous cue's text plus one new phrase. A 1h20m video produces ~5000 cues and ~200KB of massively duplicated text. You need the dedup step below to make it usable.

## Full script (dedup + rolling-suffix merge + timestamps)

The canonical implementation lives in the Hermes skill:

```
~/.hermes/skills/media/youtube-content/scripts/fetch_transcript_ytdlp.py
```

Usage:

```bash
python3 ~/.hermes/skills/media/youtube-content/scripts/fetch_transcript_ytdlp.py \
  "https://www.youtube.com/watch?v=VIDEO_ID" \
  --out /tmp/transcript.txt
```

Options:
- `--raw` — plain text, no timestamp anchors
- `--chunk 120` — seconds between `[HH:MM:SS]` anchors (default 60)
- `--out FILE` — write to file instead of stdout

Real-world benchmark: a 1h23m interview (5032 raw VTT cues) collapses cleanly to a 91KB transcript with `[HH:MM:SS]` anchors every minute. Runs in under 5 seconds end-to-end.

## Standalone fallback (no Hermes installed yet)

If you're on a fresh Mac before Hermes is set up, save the script below as `~/bin/yt-transcript` (make executable) or run inline:

```bash
mkdir -p ~/bin && cat > ~/bin/yt-transcript <<'PYEOF'
#!/usr/bin/env python3
"""Standalone YouTube transcript via yt-dlp VTT + rolling-caption dedup."""
import argparse, os, re, subprocess, sys, tempfile

def extract_video_id(s):
    s = s.strip()
    for p in (r'(?:v=|youtu\.be/|shorts/|embed/|live/)([a-zA-Z0-9_-]{11})', r'^([a-zA-Z0-9_-]{11})$'):
        m = re.search(p, s)
        if m: return m.group(1)
    return s

def download_vtt(vid, wd):
    subprocess.run(["yt-dlp", "--write-auto-subs", "--write-subs",
                    "--sub-langs", "en.*,en", "--skip-download",
                    "--sub-format", "vtt", "--no-update",
                    "-o", os.path.join(wd, "%(id)s.%(ext)s"),
                    f"https://www.youtube.com/watch?v={vid}"],
                   check=True, capture_output=True)
    for suf in (".en.vtt", ".en-orig.vtt", ".en-US.vtt"):
        p = os.path.join(wd, vid + suf)
        if os.path.exists(p): return p
    for f in os.listdir(wd):
        if f.endswith(".vtt"): return os.path.join(wd, f)
    sys.exit("No VTT produced")

def parse_vtt(path):
    with open(path) as f: lines = f.readlines()
    cues, i = [], 0
    while i < len(lines):
        m = re.match(r'^(\d{2}):(\d{2}):(\d{2})\.\d{3} --> ', lines[i].strip())
        if m:
            h, mm, s = map(int, m.groups())
            secs = h*3600 + mm*60 + s
            i += 1; txt = []
            while i < len(lines) and lines[i].strip():
                t = re.sub(r'<[^>]+>', '', lines[i]).replace('&gt;','>').replace('&lt;','<').replace('&amp;','&').strip()
                if t: txt.append(t)
                i += 1
            if txt: cues.append((secs, ' '.join(txt)))
        else: i += 1
    return cues

def dedupe(cues):
    uniq, seen = [], set()
    for s,t in cues:
        if t not in seen: seen.add(t); uniq.append((s,t))
    merged, prev = [], ""
    for s, t in uniq:
        ov = 0
        for k in range(min(len(prev), len(t)), 0, -1):
            if prev[-k:] == t[:k]: ov = k; break
        new = t[ov:].strip()
        if new: merged.append((s, new)); prev = t
    return merged

def fmt(s): return f"{s//3600:02d}:{(s%3600)//60:02d}:{s%60:02d}"

def render(m, chunk=60):
    if not m: return ""
    out, buf, cur, last = [], [], m[0][0], -999
    for s, n in m:
        if s - last >= chunk:
            if buf: out.append(f"[{fmt(cur)}] " + " ".join(buf)); buf = []
            cur = s; last = s
        buf.append(n)
    if buf: out.append(f"[{fmt(cur)}] " + " ".join(buf))
    return "\n\n".join(out)

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("url"); ap.add_argument("--out"); ap.add_argument("--raw", action="store_true")
    ap.add_argument("--chunk", type=int, default=60)
    a = ap.parse_args()
    vid = extract_video_id(a.url)
    with tempfile.TemporaryDirectory() as wd:
        vtt = download_vtt(vid, wd)
        cues = parse_vtt(vtt)
        if not cues: sys.exit("Empty VTT — no captions.")
        merged = dedupe(cues)
    text = " ".join(n for _,n in merged) if a.raw else render(merged, a.chunk)
    if a.out:
        with open(a.out, "w") as f: f.write(text)
        print(f"wrote {len(text)} chars -> {a.out}", file=sys.stderr)
    else:
        print(text)
PYEOF
chmod +x ~/bin/yt-transcript
```

Then:

```bash
yt-transcript "https://www.youtube.com/watch?v=VIDEO_ID" --out /tmp/transcript.txt
```

(Requires `~/bin` on `$PATH` — already set in Naren's zsh.)

## The rolling-caption problem (why this script exists)

YouTube's auto-generated captions are designed for real-time display, not archival. Each cue is:

```
cue N   : "words words words previous chunk"
cue N+1 : "words previous chunk NEW WORD"
cue N+2 : "previous chunk NEW WORD another"
```

A naive VTT-to-text conversion produces the same text repeated hundreds of times. The dedup logic runs two passes:

1. **Exact dedup** — drop any cue whose text is identical to the previous cue (halves the volume).
2. **Rolling-suffix merge** — for each remaining cue, find the largest prefix of the cue that overlaps the tail of the accumulated transcript; append only the NEW tail.

Empirically: 5032 raw cues → 2525 exact-unique cues → 91KB of clean, non-redundant text.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `yt-dlp: command not found` | `brew install yt-dlp` (or run `brew bundle` on fresh Mac) |
| `WARNING: Your yt-dlp version is older than 90 days` | `brew upgrade yt-dlp` — script includes `--no-update` to silence this at runtime |
| `impersonation for this download` warning | Cosmetic; VTT still downloads fine. To silence: `brew install curl-impersonate` (not currently in Brewfile — add only if needed) |
| Empty VTT / "no captions" | Video genuinely has no captions (auto or manual). No workaround. |
| Two Python `yt-dlp` shims on PATH (`~/.pyenv/shims/yt-dlp` older than the brew one) | Brew's `yt-dlp` at `/opt/homebrew/bin/yt-dlp` is newer. Ensure brew's bin is ahead of pyenv shims in `$PATH`, or just call `/opt/homebrew/bin/yt-dlp` directly in the script. |

## Repro test (proof this works)

Full 1h23m interview transcript reproduced from `https://www.youtube.com/watch?v=Av0EGv7WLqc`:

```bash
$ python3 ~/.hermes/skills/media/youtube-content/scripts/fetch_transcript_ytdlp.py \
    "Av0EGv7WLqc" --out /tmp/test.txt
wrote 91451 chars -> /tmp/test.txt

$ head -1 /tmp/test.txt
[00:00:01] There's a new show that we are starting undercover billionaires. ...
```

Elapsed: ~4 seconds (mostly the VTT download).

## Cross-references

- Hermes skill: `~/.hermes/skills/media/youtube-content/`
- Primary path (works when it works): `fetch_transcript.py` via `youtube-transcript-api`
- This fallback: `fetch_transcript_ytdlp.py`
- Root cause of the primary breaking: [youtube-transcript-api#407](https://github.com/jdepoix/youtube-transcript-api/issues) (YouTube changes transcript endpoint faster than the library updates)
