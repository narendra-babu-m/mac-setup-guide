# NEW-MAC-PLAYBOOK — Mac-to-Mac migration lessons

This is the playbook distilled from migrating a fully configured Mac to a fresh
SAP-managed MacBook on 2026-11-03. It supplements `bootstrap.sh` with the
Mac-to-Mac data migration dance that the repo alone does not cover.

## Order of operations

| Phase | What | Tool | Minutes |
|-------|------|------|---------|
| 1 | SSH keyless from OLD → NEW | `ssh-copy-id` | 1 |
| 2 | Install Xcode CLT on NEW (triggers GUI) | `xcode-select --install` | 10 |
| 3 | Install Homebrew on NEW (needs user sudo) | `/bin/bash -c "$(curl ...)"` | 5 |
| 4 | Clone this repo on NEW + run `bootstrap.sh` | `git clone + bash` | 20-40 |
| 5 | Install `rsync 3.5+` on BOTH macs (critical!) | `brew install rsync` | 2 |
| 6 | Rsync the stateful dirs below | `scripts/migrate-to-new-mac.sh` | 20-60 |
| 7 | Install Hermes on NEW via `hermes-setup.sh` | `SETUP_HERMES=1 bash bootstrap.sh` | 5 |
| 8 | Hyperspace AI.app → `/Applications/` (sudo) | manual on NEW | 1 |
| 9 | Load LaunchAgents on NEW | `LOAD_AGENTS=1 bash scripts/hermes-setup.sh` | 1 |
| 10 | Stop OLD gateway, cut over | manual on OLD | 1 |

## War stories & gotchas

### 1. macOS stock `rsync` is `openrsync 2.6.9` — AVOID for Mac-to-Mac

Stock rsync rejects common flags including `--info=progress2`. Install rsync 3.5+
via brew FIRST, use `--rsync-path=/opt/homebrew/bin/rsync` on EVERY call so SSH's
bare `PATH=/usr/bin:/bin` doesn't pick stock on the remote.

```
rsync -az -s --rsync-path=/opt/homebrew/bin/rsync \
  --info=progress2,stats2 --stats --human-readable --partial \
  SOURCE/ user@host:DEST/
```

- `-s` / `--protect-args` disables remote shell arg splitting (fixes spaces in paths)
- `--partial` lets you resume on SSH TCP drop
- Use `-e "ssh -o ServerAliveInterval=30"` for jobs >5 min (prevents idle disconnect)

### 2. Remote path with spaces → use `--protect-args`, NOT quoting

Wrong (every variation):
```
rsync ... "user@host:'Library/Application Support/Claude/'"      # quotes become literal
rsync ... "user@host:Library/Application\ Support/Claude/"       # backslash becomes literal
```

Right:
```
rsync ... -s "user@host:Library/Application Support/Claude/"     # -s = --protect-args
```

### 3. SAP MDM breaks `sshd` after reboots

- `sudo systemsetup -setremotelogin on` says "already on" but `sshd state = not running`
- Fix: System Settings → General → Sharing → Remote Login → toggle OFF/ON
- Firewall + stealth mode = MDM-locked, can't disable via CLI

### 4. The `uv.lock` write race

Running Hermes rewrites `uv.lock` during normal use. If you rsync while Hermes
is up on OLD mac, `uv.lock` can land as "not yet present" on NEW mac because
rsync built its file list before the write. **Rerun the hermes-agent rsync
after `setup-hermes.sh` fails once** — targeted top-level sync fixes it.

### 5. hai CLI version drift bites SAP-side

SAP's HAI proxy enforces minimum CLI version. If you see `426 Upgrade Required`
in `~/.hermes/logs/hai-proxy-hermes.log`, your `hai` is too old. Install current:

```
curl -fsSL https://ai-docs.portal.hyperspace.tools.sap/llm-proxy/update/ | less  # see current
# Or copy from old Mac: rsync -az ~/.local/bin/hai NEWMAC:.local/bin/hai
# LaunchAgent plist expects /opt/homebrew/bin/hai, symlink from ~/.local/bin/hai
```

### 6. `gh auth` -25308 Keychain error on fresh Mac

Fresh Macs can't restore Keychain tokens from this profile. First login flow:
```
gh auth logout -h github.tools.sap -u $USER
gh auth login -h github.tools.sap --git-protocol https --web  # follow SSO
```

### 7. Running BOTH macs' Hermes gateways concurrently = race on auth.json

Hermes gateway writes to `~/.hermes/auth.json` + `sessions/*/current.jsonl`.
When BOTH macs are up, you get `RuntimeError: the launch session authority
cannot be removed` and lock conflicts. **Stop OLD before using NEW:**

```
launchctl unload ~/Library/LaunchAgents/ai.hermes.gateway.plist
launchctl unload ~/Library/LaunchAgents/local.hermes-stack.hai-proxy.plist
launchctl unload ~/Library/LaunchAgents/local.hermes-stack.litellm-watchdog.plist
```

### 8. Hyperspace AI.app not in brew-cask

It's SAP-internal (`com.sap.hyperspace.AI`, bundle 1.4.8). Options:
- `rsync /Applications/Hyperspace\ AI.app/ NEWMAC:/tmp/Hyperspace\ AI.app/`
- Then on NEW mac manually: `sudo mv /tmp/Hyperspace\ AI.app /Applications/`
- Clear quarantine: `xattr -dr com.apple.quarantine /Applications/Hyperspace\ AI.app`

### 9. `MII_PASS` in `~/.zshrc` is cleartext — ROTATE before copying

The repo's `zshrc.template` has `REPLACE_FROM_BITWARDEN` placeholder. Fill from
Bitwarden on NEW mac. Also rotate the secret itself if it was ever in cleartext
cloud backups.

## Volumes to rsync (verified today)

| Source | Size | New Mac dest | Exclude |
|---|---|---|---|
| `~/.hermes/` | ~16GB | `~/.hermes/` | `cache/`, `logs/*.log.*`, `browser-profile/*/Cache`, `audio_cache/`, `tools/python-*` only if you'll run `hermes-setup.sh` |
| `~/.claude/` | 150MB | `~/.claude/` | `paste-cache`, `shell-snapshots`, `ide` |
| `~/Library/Application Support/Claude/` | 400MB | same | `Cache`, `Code Cache`, `GPUCache`, `Dawn*Cache`, `Service Worker`, `SavedState`, `Crashpad` |
| `~/Vaults/` | 100MB | `~/Vaults/` | `.trash`, `.obsidian/workspace.json` |
| `~/Library/Application Support/obsidian/` | 140MB | same | `Cache`, `Code Cache`, `GPUCache`, `Dawn*`, `Service Worker`, `DIPS` |
| `~/.aicore/` | 6MB | `~/.aicore/` | - |
| `~/.config/hai/` | 1MB | `~/.config/hai/` | - |
| `~/.local/bin/hai` | 30MB | `~/.local/bin/hai` | - |
| `/Applications/Hyperspace AI.app/` | 85MB | via `/tmp` + `sudo mv` | - |
| `~/Library/LaunchAgents/*.plist` | tiny | render from templates, don't rsync literal | - |

## Reference scripts

- `scripts/migrate-to-new-mac.sh` — rsync batch (edit REMOTE_HOST before running)
- `scripts/hermes-setup.sh` — Hermes install + LaunchAgent render
- `scripts/iterm2-setup.sh` — iTerm2 prefs via custom-folder (NOT raw plist copy)
