# Hermes on Personal Mac — Migration Guide

> [!info] Created 22 Jun 2026 · Captures everything learned during the SAP-Mac Discord + voice setup session, packaged as a clean rebuild path for Naren's personal Mac (or Windows PC, Linux box, any non-corp machine).

This doc exists because:

1. SAP-managed Mac runs **Cisco Secure Client + Cisco Umbrella + Palo Alto GlobalProtect + FortiClient** as root system extensions. They intercept ALL outbound TLS — Discord, Telegram, anything social — even on home Wi-Fi.
2. Disabling Cisco temporarily made Discord work, but it broke MDM compliance and had to be re-enabled.
3. Going forward, Hermes' messaging surface (Discord voice, Telegram voice notes) lives on a NON-CORP machine. This doc is the rebuild path.

═══════════════════════════════════════════════

## TL;DR — what you're rebuilding on personal Mac

| Capability | Setup time | Verified working on corp Mac? |
|---|---|---|
| Hermes core (CLI, terminal voice mode) | 10 min | ✅ |
| Two profiles (`personal`, `professional`) | done, just copy files | ✅ |
| Notion 3-DB integration | done, token portable | ✅ |
| Discord bot (text + voice channel) | 5-7 min (re-using existing bot token) | ✅ (briefly, with Cisco off) |
| Google Workspace OAuth | 10 min | not yet — planned |
| Telegram voice notes | 5 min (needs proxy in India) | ❌ ISP-blocked |

═══════════════════════════════════════════════

## Phase 1 — Install Hermes on the new machine

Same procedure as SAP Mac, no surprises:

```bash
# 1. Install via the official one-liner (whatever the current method is per docs)
#    See https://hermes-agent.nousresearch.com/docs/install

# 2. Verify
hermes --version
hermes setup     # interactive wizard, walks model/tools/gateway

# 3. Install voice extras (use uv pip — NOT system pip)
brew install portaudio espeak-ng ffmpeg opus  # opus may need: brew install --HEAD opus
uv pip install --python ~/.hermes/hermes-agent/venv/bin/python "hermes-agent[voice]"
uv pip install --python ~/.hermes/hermes-agent/venv/bin/python "hermes-agent[messaging]"
uv pip install --python ~/.hermes/hermes-agent/venv/bin/python truststore  # in case of any cert weirdness
```

**Reminder:** Hermes venv has NO `pip` exposed. Always `uv pip install --python <venv-python>`.

═══════════════════════════════════════════════

## Phase 2 — Restore profiles, skills, memory, cron

The whole `~/.hermes` directory is portable. Three options:

### Option A — Full rsync (fastest)

```bash
# On SAP Mac, package what's safe to migrate
rsync -av --exclude='sessions/' --exclude='logs/' --exclude='cache/' \
  --exclude='hermes-agent/venv/' --exclude='*.lock' \
  ~/.hermes/ ~/Desktop/hermes-migration/

# Carry to personal Mac (AirDrop, USB, github private repo)

# On personal Mac, after `hermes setup` runs once:
rsync -av ~/Desktop/hermes-migration/ ~/.hermes/
chmod 600 ~/.hermes/.env ~/.hermes/profiles/*/.env
```

### Option B — Git-tracked dotfile pattern

Already partially in place:

- Vaults: `gh.com/narendra-babu-m/obsidian-personal` and `obsidian-professional`
- Mac-setup-guide: `gh.com/narendra-babu-m/mac-setup-guide` (your Phoenix repo)

Add `~/.hermes/skills` and `~/.hermes/profiles/*/skills` to a NEW private repo:

```bash
# On corp Mac
cd ~/.hermes
git init
echo -e ".env\n.env.*\nsessions/\nlogs/\ncache/\nhermes-agent/venv/\naudio_cache/\n*.lock\n*.pid\n*.sock" > .gitignore
git add .gitignore skills/ profiles/*/skills/ profiles/*/SOUL.md profiles/*/MEMORY.md profiles/*/USER.md
git remote add origin gh:narendra-babu-m/hermes-config-private.git
git commit -m "hermes config baseline 2026-06-22"
git push -u origin main
```

On personal Mac: clone, then layer on top of the freshly-installed Hermes.

**Secrets stay OUT.** Repo excludes `.env`. Regenerate or transfer those by hand.

### Option C — Minimal copy

Just the things that matter:

| Path | What it is | How to copy |
|---|---|---|
| `~/.hermes/config.yaml` | Default profile config | rsync |
| `~/.hermes/profiles/personal/` | Personal profile | rsync (whole dir) |
| `~/.hermes/profiles/professional/` | Pro profile | rsync (whole dir) |
| `~/.hermes/skills/` | All your custom skills | rsync |
| `~/.hermes/.env` | Secrets — HANDLE WITH CARE | manual entry on new machine |

═══════════════════════════════════════════════

## Phase 3 — Re-establish secrets (.env on new machine)

The .env on SAP Mac currently contains:

```
NOTION_API_KEY=...                     # transferable, same workspace
TELEGRAM_BOT_TOKEN=...                 # same bot works anywhere
DISCORD_BOT_TOKEN=...                  # same bot works anywhere
DISCORD_ALLOWED_USERS=645117117254991902  # your Discord user ID
ANTHROPIC_API_KEY=...                  # personal key, transferable
SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET, SPOTIFY_REFRESH_TOKEN
AICORE_SERVICE_KEY                     # SAP-specific, DON'T move to personal
PANDORA_QA / PANDORA_PROD client secrets   # SAP-specific, DON'T move
```

**On personal Mac:**

1. Open Bitwarden Secrets Manager (BWS) — the secrets are already in there
2. Re-apply: `hermes secrets apply` (or run `bws secret list` to inspect)
3. SAP secrets stay on corp Mac; personal Mac only needs the personal/transferable ones
4. Verify with: `hermes status`

For tokens that are unique to the bot/integration (Discord, Notion), they work on any machine — no re-registration needed.

═══════════════════════════════════════════════

## Phase 4 — Discord bot recovery on personal Mac

Bot already exists at https://discord.com/developers/applications (named `Hermes`). Privileged intents already enabled. Bot already invited to your server.

On personal Mac:

```bash
# 1. Token already in .env from Phase 3
grep "^DISCORD_BOT_TOKEN" ~/.hermes/.env

# 2. Discord enabled in config
hermes config set discord.enabled true

# 3. Restart gateway
hermes gateway restart

# 4. Watch logs
tail -f ~/.hermes/logs/gateway.log | grep -i discord
```

Should see `[Discord] Connected as bot1518593697178976406#4841` within ~10 seconds. Bot goes green in your server's member list.

**Test in Discord:**
- Text: `@Hermes hello` in any text channel → reply within 5 sec
- Voice: join a VC, then `/voice channel` → bot joins
- Voice mode toggle: `/voice tts` (every reply spoken) or `/voice on` (speaks only when you sent voice)

═══════════════════════════════════════════════

## Phase 5 — Telegram (if your home ISP allows)

ISPs in India often block direct connections to `api.telegram.org` even without corp interception. Test:

```bash
nc -G 4 -zv api.telegram.org 443
```

If TCP succeeds, restart gateway — Telegram bot comes online same way. If timeout, options:

- Switch to a different ISP (some allow direct, some don't)
- Use a Telegram MTProto proxy
- Use a VPN with split-tunneling (no corp software)
- Accept that Telegram doesn't work on this ISP and use Discord for voice

═══════════════════════════════════════════════

## Phase 6 — Google Workspace OAuth (planned)

Skill: `productivity:google-workspace` — already loaded.

Steps when you're ready:

1. Create OAuth client at https://console.cloud.google.com/apis/credentials (Desktop app type)
2. Enable APIs: Gmail, Calendar, Drive, Docs, Sheets, People
3. If app is in Testing, add yourself as test user at https://console.cloud.google.com/auth/audience
4. `python ~/.hermes/skills/productivity/google-workspace/scripts/setup.py --client-secret /path/to/json`
5. Follow OAuth URL → paste code back
6. Verify: `python ~/.hermes/skills/productivity/google-workspace/scripts/setup.py --check` → prints `AUTHENTICATED`

This is the only piece NOT yet done. Works from any machine (no corp interference — Google OAuth is enterprise-allowed traffic).

═══════════════════════════════════════════════

## Phase 7 — Voice mode polish

```yaml
# ~/.hermes/config.yaml
tts:
  provider: edge
  edge:
    voice: en-GB-RyanNeural   # Jarvis vibe — already set in your config

stt:
  enabled: true
  provider: local
  local:
    model: base

voice:
  record_key: ctrl+b          # change to ctrl+space if tmux conflict
  silence_threshold: 200
  silence_duration: 3.0
```

Voice extras (`hermes-agent[voice]`) install local Whisper + Edge TTS. ~250 MB total. Round-trip 7.9× realtime on M-series CPU.

**TTS brevity rule** is baked into `hermes-voice-setup` skill — when TTS is on, replies stay 1-3 sentences, no markdown, no separators, pure prose.

═══════════════════════════════════════════════

## Phase 8 — Cron jobs, gateway autostart

```bash
# Auto-start gateway on boot
hermes gateway install     # creates launchd plist on macOS

# Cron jobs you may want
hermes cron list           # show what's scheduled
# Existing cron jobs (transfer via Hermes UI or copy ~/.hermes/cron/)
```

═══════════════════════════════════════════════

## What we did on SAP Mac (chronological)

For reference if you need to retrace:

### Already shipped (12 items)
1. Whisper STT (faster-whisper 1.2.1) installed
2. Edge TTS 7.2.7 installed
3. Audio plumbing (portaudio, espeak-ng, ffmpeg, opus)
4. Config wired (tts=edge, stt=local, voice ctrl+b)
5. TTS↔STT round-trip verified (7.9× realtime)
6. Voice-Mode-Setup.md doc in vault
7. Personal profile created
8. Professional profile created
9. Gateway + hooks + BWS secrets wired
10. Notion 3-DB hierarchy built (Areas → Stories → Life)
11. SAP AI Core proxies (HAI :6655, anthropic_shim :6656, LiteLLM :4000)
12. Vaults pushed to GitHub

### This session (Discord push)
13. `notion-life-tracker-prompt` skill created — reflex prompt after every meaningful task
14. CLI keybinding → `busy_input_mode: steer` (Claude-Code-feel: Enter steers, Ctrl+C interrupts)
15. Discord bot created at Discord dev portal
16. DISCORD_BOT_TOKEN + DISCORD_ALLOWED_USERS in .env
17. Discord platform enabled in config
18. **Diagnosed: Cisco Umbrella TLS-intercepting Discord** (cert subject = `Cisco Umbrella Secondary SubCA`)
19. Cisco Secure Client disabled → Discord bot LIVE
20. Text + voice channel join verified in Discord
21. Voice swapped to `en-GB-RyanNeural` (Jarvis-ish)
22. TTS brevity rule patched into `hermes-voice-setup` skill

### After this doc
23. Cisco Secure Client RE-ENABLED on SAP Mac (compliance restored)
24. Future Discord/Telegram work moves to personal Mac

═══════════════════════════════════════════════

## Pitfalls observed

- **Cisco Umbrella blocks even home Wi-Fi.** It's a network EXTENSION, not a VPN — it intercepts at the OS layer regardless of which Wi-Fi you join. Disabling Cisco Secure Client app stops the processes. Re-enabling restores MDM compliance.
- **Telegram blocked by Indian ISPs too** — not just corp. Different problem from Cisco. Test independently on personal Mac.
- **Hermes venv has no `pip`** — always use `uv pip install --python ~/.hermes/hermes-agent/venv/bin/python <pkg>`. This is the #1 install mistake.
- **TLS handshake failure ≠ trust issue.** When you see `SSLV3_ALERT_HANDSHAKE_FAILURE` from `discord.com:443`, that's the SERVER alerting — Cisco is refusing to forward the connection. `truststore` and `pip-system-certs` don't help because there's no fake cert to trust; the proxy is dropping traffic.
- **Telltale corp interception check:**
  ```bash
  echo | openssl s_client -connect discord.com:443 -servername discord.com 2>&1 | grep issuer=
  ```
  If issuer says `Cisco`, `Palo Alto`, `Forti`, or `Umbrella` — your TLS is being inspected. Real cert issuer should be `Google Trust Services` (for Discord, Google) or similar real CAs.

═══════════════════════════════════════════════

## Asset inventory (what's saved + where)

**In vault:** This doc, `Voice-Mode-Setup.md`.

**In Hermes skills tree:** `productivity/notion-life-tracker-prompt`, `productivity/notion-beautified-pages`, `productivity/notion`, `software-development/hermes-voice-setup`, `productivity/google-workspace`, plus 200+ other skills.

**In Notion (Story page):** https://app.notion.com/p/Hermes-Agent-personal-AI-infra-382806250ab781f5ab6df7bd193eb7f2
30+ linked tasks in 🎯 Life DB.

**In Bitwarden Secrets Manager:** All keys (Notion, Discord, Telegram, Anthropic, Spotify, SAP) — accessible from any machine with BWS access.

**In GitHub:** `mac-setup-guide`, `obsidian-personal`, `obsidian-professional`. Not yet: hermes-config-private (recommended to create per Phase 2B).

═══════════════════════════════════════════════

## Related notes

- [[Voice-Mode-Setup]] — full voice stack reference
- [[Hermes-Agent-Setup]] — initial Hermes install reference
- [[Mac-Setup-Guide]] — Phoenix Mac setup repo
- Skill: `software-development/hermes-voice-setup` (load anytime voice breaks)
- Skill: `autonomous-ai-agents/hermes-agent` (bundled Hermes docs)
- Skill: `productivity/notion-life-tracker-prompt` (the reflex prompt that catches everything)

═══════════════════════════════════════════════

*Created 22 Jun 2026 · Update when migration actually happens on personal Mac · Patch the related skills if any step changes*
