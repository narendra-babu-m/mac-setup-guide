# Migration Day Protocol — Old Mac → New Mac (SAP work replacement)

> Written 2026-10-23 for Monday 2026-10-26 handover. Walk top-to-bottom.
> Companion to `MANUAL_STEPS.md` (§5 Restore Personal State links here).

**Scope:** SAP-issued MDM-enrolled replacement. Same Cisco/Umbrella/GlobalProtect posture, SAP AI Core workflows live, dept DI-02, OneDrive-SAPSE as cloud sync. Personal Mac migration = different playbook (see `hermes-on-personal-mac.md`).

**Hard rule:** nothing gets erased from the old Mac until the new Mac verifies the same green on all §7 sanity checks.

---

## 0. Pre-flight state snapshot (do THIS FIRST, right now)

Current numbers from live audit `2026-10-23 Fri`:

| Surface | Size | Status |
|---|---|---|
| Mac disk | 460Gi total, 44Gi free (90% full) | Delete `~/.npm` + `~/.cache` reclaims ~18Gi if needed |
| OneDrive-SAPSE local | 79Gi | Already in cloud, no action needed |
| Downloads | 17G | Filter first, then OneDrive if kept |
| Projects | 2.3G | GitHub only, never OneDrive |
| AI_Project | 1.7G | Audit per-repo, GitHub where possible |
| .hermes state | 16G | Encrypted archive (see §4) |
| Vaults | 108M | Already on GitHub, dirty=0 ✓ |

**No-regret cleanups before anything else (reclaims ~18Gi, no data loss):**
```bash
# These regenerate on first use. Safe anywhere.
rm -rf ~/.cache ~/.npm/_cacache ~/.npm/_logs
brew cleanup --prune=all                              # old brew tarballs
docker system prune -a --volumes                      # if Docker still used
```

---

## 1. The three failure surfaces (where data actually lives)

Every byte that matters is in exactly one of these three buckets. Treat each bucket differently.

### Bucket A — Already in the cloud (zero action)
- OneDrive-SAPSE: Teams Chat Files, SAP Dev work, Documents already synced
- iCloud: whatever you have signed in
- GitHub remotes: anything with `remote=yes` AND `dirty=0`

### Bucket B — Needs a `git push` before Monday
Dirty working trees + unpushed commits. Lose the laptop = lose the delta.

### Bucket C — Needs net-new upload
Media, downloads, un-git'd state dirs. These need to physically move.

---

## 2. BUCKET B — Repo cleanup (do this today or tomorrow, latest Saturday)

Live audit shows 14 dirty + 3 orphan-remote repos. Decision tree per repo:

### 2a. Dirty but has a GitHub remote (push `wip:` snapshot)

| Repo | Dirty | Action |
|---|---|---|
| `~/claude-professional` | 8 | Audit → commit → push |
| `~/work-log` | 27 | Audit → commit → push (likely daily logs catch-up) |
| `~/claude-os-dashboard` | 1 | Quick commit |
| `~/hermes-self` | 1 | Quick commit |
| `~/bruno-collections` | 1 | Push to github.tools.sap/I576292 |
| `~/Projects/16-production-process-analyser` | 3 | Push to github.tools.sap/SAP-DMC-Utilities |
| `~/Projects/PANDORA-docs/*` (3 repos) | 2+3+1 | Push to Azure DevOps pandora-jewelry |
| `~/Projects/tv-detox` | 10 | **External repo (Ansub/tv-detox)** — if you own the delta, fork + push; else back up as patch file |
| `~/AI_Project/scb_pa_final` | 6 | **External repo (sriramrokkam)** — same decision as tv-detox |

**Batch command (per repo):**
```bash
cd <repo>
git status                                           # eyeball what's dirty
git add -A && git commit -m "chore: pre-migration snapshot $(date +%F)"
git push
```

### 2b. NO-REMOTE repos (create private remote NOW)

| Repo | Dirty | What it is |
|---|---|---|
| `~/Projects/hermes-litellm-stack` | 12 | Local LiteLLM/HAI proxy work |
| `~/Projects/daylio-bulk-insert` | 5 | Daylio import script |
| `~/Archive/SAP_DMC_APIs.OLD-DELETE-AFTER-2026-08-13` | 26 | **Expired archive — delete, do not back up** (name says so) |

**For the two keepers:**
```bash
cd ~/Projects/hermes-litellm-stack
git add -A && git commit -m "feat: pre-migration snapshot"
gh repo create narendra-babu-m/hermes-litellm-stack --private --source=. --push

cd ~/Projects/daylio-bulk-insert
git add -A && git commit -m "feat: pre-migration snapshot"
gh repo create narendra-babu-m/daylio-bulk-insert --private --source=. --push
```

**For the expired archive:**
```bash
rm -rf ~/Archive/SAP_DMC_APIs.OLD-DELETE-AFTER-2026-08-13
```

### 2c. External-fork dirty repos (one call: own the fork or drop the delta)

- `~/Projects/tv-detox` (Ansub/tv-detox) — DIRTY=10
- `~/AI_Project/scb_pa_final` (sriramrokkam/scb_pa_final) — DIRTY=6

Decide per repo: `git diff > ~/Backup-Migration/patches/<repo>.patch` and attach to OneDrive, OR fork the upstream + push the delta.

---

## 3. BUCKET C — What goes to OneDrive-SAPSE

Only non-dev, non-secret user data. Dev state goes to GitHub (§2) or encrypted archive (§4).

### Pre-upload hygiene (shrinks Downloads from 17G to probably ~2-3G)

```bash
# Delete DMGs and installers (regenerable)
find ~/Downloads -maxdepth 1 \( -name "*.dmg" -o -name "*.pkg" -o -name "*.zip" \) -size +50M -ls
# Review the list, then:
# find ~/Downloads -maxdepth 1 \( -name "*.dmg" -o -name "*.pkg" \) -delete

# Delete things older than 1 year nobody touched
find ~/Downloads -type f -atime +365 -ls | less
```

### Upload target structure (create ONCE)

```
~/Library/CloudStorage/OneDrive-SAPSE/Backup-Migration-2026-10/
├── Downloads/              rsync -a --exclude='*.dmg' --exclude='*.pkg' ~/Downloads/
├── Pictures/               rsync -a ~/Pictures/
├── Music/                  rsync -a ~/Music/
├── Movies/                 rsync -a ~/Movies/
├── Documents/              rsync -a ~/Documents/      # tiny, 64K
├── Desktop/                rsync -a ~/Desktop/        # tiny, 20K
├── Archive/                rsync -a ~/Archive/        # minus the OLD-DELETE dir
├── Patches/                any `git diff` patches from §2c
├── Brewfile.snapshot       cp ~/mac-setup-guide/Brewfile .   # just in case
└── RESTORE-NOTES.md        ← write a 1-pager pointing new-Mac-Naren at this doc
```

**Executable version** (dry-run first, remove `-n` to commit):
```bash
DEST=~/Library/CloudStorage/OneDrive-SAPSE/Backup-Migration-2026-10
mkdir -p $DEST/{Downloads,Pictures,Music,Movies,Documents,Desktop,Archive,Patches}

rsync -avhn --exclude='*.dmg' --exclude='*.pkg' --exclude='.DS_Store' ~/Downloads/ $DEST/Downloads/
rsync -avhn ~/Pictures/ $DEST/Pictures/
rsync -avhn ~/Music/ $DEST/Music/
rsync -avhn ~/Movies/ $DEST/Movies/
rsync -avhn ~/Documents/ $DEST/Documents/
rsync -avhn ~/Desktop/ $DEST/Desktop/
rsync -avhn --exclude='SAP_DMC_APIs.OLD-DELETE-AFTER-*' ~/Archive/ $DEST/Archive/
cp ~/mac-setup-guide/Brewfile $DEST/Brewfile.snapshot
```

Expected total upload: **~15-20Gi** depending on how aggressive Downloads cleanup is. Verify after upload:
```bash
du -sh $DEST
```

Then **wait for OneDrive to sync** (menu bar icon → "Up to date") before touching anything on the old Mac.

---

## 4. State dirs — the special cases

These are **NOT** OneDrive candidates. They either go to git repos (preferred) or an encrypted archive.

### 4a. `~/.hermes` (16G) — encrypted archive

Per the `app-state-backup-to-git` skill → "encrypted-portable-archive" variant. 16G is too big for a git repo but needs to carry secrets intact for the new Mac to work same-day.

```bash
# One-shot: see references/encrypted-portable-archive.md in that skill
# Produces ~/.hermes/migration/hermes-<date>.tar.gz.gpg + checksum manifest
# Stored on OneDrive encrypted; passphrase in Bitwarden
```

Alternative (lighter): back up only durable surfaces (skills, cron, memories, scripts, hooks, configs), skip cache/logs/sessions. See the skill's §4 "config-only vs config+history" decision point. For a work-Mac handover, config-only is probably correct — chat history ≠ required for productivity.

### 4b. `~/.codex` (687M), `~/.claude` (199M)

- `.claude` → already covered by `claude-professional` + `claude-workspace-system` repos (both DIRTY, push per §2a)
- `.codex` → check if it has a backup repo; if not, create `narendra-babu-m/codex-config` same pattern

### 4c. `~/.ssh`, `~/.gnupg`, `~/.aicore/service-key.json`

**NEVER goes to OneDrive. NEVER goes to git plaintext.**

Options:
1. **Bitwarden Secrets Manager** (if you have it) — store each secret as a named entry
2. **1Password** — same pattern
3. **Export + GPG encrypt + OneDrive** — only if neither of the above exists

```bash
# SSH keys — regenerate on new Mac is also valid; GitHub lets you add a new key
# For now, archive the current pair safely:
tar -czf ~/ssh-backup-$(date +%F).tar.gz -C ~ .ssh
gpg --symmetric --cipher-algo AES256 ~/ssh-backup-$(date +%F).tar.gz
rm ~/ssh-backup-$(date +%F).tar.gz   # delete plaintext
# Move the .gpg to Bitwarden as an attachment, OR to OneDrive (encrypted = safe)
```

### 4d. `~/.config` (145M)

Already partially mirrored by `mac-setup-guide/dotfiles/` symlinks (zellij, zsh). Audit any `~/.config/<tool>` NOT in the dotfiles tree:
```bash
ls ~/.config
# For each not in mac-setup-guide/dotfiles/: decide (port into repo, or skip)
```

---

## 5. Secrets inventory (write this out, print it, carry it)

The things that have NO backup other than your knowledge of them + the password manager:

| Secret | Where it lives now | Where it needs to be on new Mac |
|---|---|---|
| SAP corporate password | Head | — |
| Apple ID password | Bitwarden | Bitwarden auto-restores |
| GitHub PAT (`gh auth`) | `~/.config/gh/hosts.yml` | `gh auth login` again |
| SAP AI Core service key | `~/.aicore/service-key.json` | Regenerate from BTP cockpit (easier than copy) |
| HAI proxy API key | macOS Keychain `hai-cli` / `hai-proxy-api-key` | Rotates on restart anyway — regenerate on new Mac |
| Bitwarden master password | Head | — |
| SSH private key passphrase | Head | — |
| GPG private key passphrase | Head | — |
| FileVault recovery key | Bitwarden secure note | Set up new FileVault on new Mac |
| OneDrive sign-in | SAP SSO | SAP SSO on new Mac |
| Any `.env` files in `~/Projects/*` | Each project dir | Audit NOW — many will be re-created from Bitwarden |

**Action for secrets**: open each `.env` and `*.key` in `~/Projects/` and `~/AI_Project/`:
```bash
find ~/Projects ~/AI_Project -name ".env*" -o -name "*.key" -o -name "*service-key*" 2>/dev/null
```
For each hit, decide: (a) regenerate on new Mac, (b) copy value to Bitwarden now, (c) irrelevant/delete.

---

## 6. Apps inventory (what's on this Mac + how each gets to the new one)

### 6a. Via Brewfile (automatic — `bash bootstrap.sh` installs these)

Already captured in `~/mac-setup-guide/Brewfile`. Current count: ~31 casks + ~180 formulas. Verify before Monday:
```bash
bash ~/mac-setup-guide/sync.sh                 # should report "in sync"
```

### 6b. SAP corporate (via Self Service — do these on new Mac day 1)

NOT in Brewfile because they come from SAP IT:
- Cisco AnyConnect / Umbrella Roaming
- GlobalProtect
- FortiClient
- Microsoft Defender
- Microsoft Teams
- Microsoft 365 (Outlook, Word, Excel, PowerPoint)
- Company Portal
- Self Service itself
- Privileges.app
- HP / Hewlett-Packard printer drivers
- Snagit 2024 (SAP license)
- BIG-IP Edge Client
- F5 Endpoint Inspector
- Access Experience
- Joule Work
- Microsoft 365 Copilot
- Support.app

### 6c. App Store (sign in with Apple ID → "Purchased")

- Xcode / Xcodes
- Hyperspace AI
- Comet (also brew cask — pick one)
- Prime Video
- 1% Club
- Flow
- Hidden Bar
- Lockera Widgets
- Maccy
- Only Switch (also brew cask)
- Power Monitor
- Promptly
- Rectangle
- Soduto (also brew cask)
- Wallspace

### 6d. Direct download (not in brew, not SAP, not App Store)

- PostgreSQL 16 (EDB installer) + pgAdmin 4 — download from postgresql.org
- Python 3.12/3.13/3.14 (official python.org installers) — pyenv is already in Brewfile, consider dropping these
- Google Docs / Google Sheets stub apps — these are just URL shortcuts, ignore
- LocalSend (if not in Brewfile)
- KDE Connect (if not in Brewfile)
- ExcalidrawZ (if not in Brewfile)
- VLC (should be in Brewfile; verify)
- Zoom (SAP managed; via Self Service)
- Windows App (Microsoft Remote Desktop replacement)

**Cross-check against Brewfile:**
```bash
cd ~/mac-setup-guide && bash sync.sh
# Any "+ ON MAC, NOT IN REPO" rows that match the §6d list should get added
```

### 6e. Already decommissioned / don't reinstall

- `android-commandlinetools`, `android-platform-tools` — if you're not actively using scrcpy anymore, skip
- Any abandoned experiments — audit the Brewfile this weekend

---

## 7. Monday (new Mac day) — the restore order

Follow MANUAL_STEPS.md top to bottom. The abbreviated version:

### 7a. First hour (while Setup Assistant finishes)
- [ ] Boot new Mac, Apple ID sign-in
- [ ] Enable FileVault (save recovery key to Bitwarden immediately)
- [ ] Enable Touch ID for sudo (per MANUAL_STEPS §1)
- [ ] Install Bitwarden (from App Store), sign in, pull everything

### 7b. Next hour (parallel: downloads happening in background)
- [ ] Install Homebrew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- [ ] `gh auth login` → paste PAT or browser-OAuth
- [ ] `git clone https://github.com/narendra-babu-m/mac-setup-guide ~/mac-setup-guide`
- [ ] `cd ~/mac-setup-guide && bash bootstrap.sh` (goes 30-60 min)
- [ ] While bootstrap runs: open SAP Self Service, start installing §6b corporate apps

### 7c. State restore (afternoon)
- [ ] Clone vaults:
  ```bash
  mkdir -p ~/Vaults && cd ~/Vaults
  git clone git@github.com:narendra-babu-m/obsidian-personal.git ObsidianBrain-Personal
  git clone git@github.com:narendra-babu-m/obsidian-professional.git ObsidianBrain-Professional
  ```
- [ ] Clone every repo per `~/mac-setup-guide/docs/migration-day.md §2` lists back to original paths
- [ ] Restore `~/.hermes` from encrypted archive (per §4a)
- [ ] Restore `~/.claude` from `claude-professional` + `claude-workspace-system`
- [ ] Restore `~/.codex` (if backed up)
- [ ] Rebuild SAP AI Core service key (per skill `sap-ai-core-local-tools`)
- [ ] Start HAI proxy: `hai proxy start` (new API key auto-rotates into Keychain)
- [ ] `atuin login && atuin sync` to pull shell history

### 7d. Sanity checks (go/no-go for retiring the old Mac)

Per MANUAL_STEPS §7, PLUS:
- [ ] `hermes --version` works
- [ ] `hai proxy status` reports healthy
- [ ] Both Obsidian vaults open, latest notes present
- [ ] `cd ~/mac-setup-guide && bash validate.sh --drift-only` → 0 DRIFT
- [ ] SAP: Outlook signed in, Teams signed in, OneDrive-SAPSE sync starting
- [ ] GlobalProtect / Cisco connect successfully
- [ ] One real work task: open a DMC PPD file, run a Bruno collection, something end-to-end
- [ ] One real personal task: open Bloomberg terminal, run a Hermes query

Only when ALL of these are green: **old Mac can be wiped and returned.**

---

## 8. Known gotchas (from this Mac's history)

- **MDM profiles override defaults**: some `scripts/*-defaults.sh` writes are silently reverted by SAP configuration profiles. `profiles status -type enrollment` to confirm. Not your fault if validate.sh shows persistent DRIFT on firewall / FileVault / screenlock keys.
- **macOS 26 HID-daemon pitfall**: after bootstrap, F-keys and trackpad gestures may need a System Settings pane toggle to re-arm (see `mac-setup-sync` skill's milestone log 2026-07-16).
- **OneDrive sync lag**: Teams Chat Files alone = 122 subdirs. First sign-in on new Mac can take 1-2 hours to fully sync. Don't panic if files appear as cloud-only placeholders at first.
- **SAP AI Core service key**: regenerating from BTP cockpit is faster than restoring. Mint fresh, don't copy old.
- **HAI proxy API key rotates on restart**: don't try to port the old key — it's dead the moment the new Mac starts the proxy.
- **Cisco/Umbrella + localhost loopback**: if a tool can't reach `127.0.0.1:<port>` on the new Mac, check Umbrella Roaming's "trusted networks" list.

---

## 9. Checklist card (print this)

**Before Monday (today → Sunday):**
- [ ] §0 cleanup commands (reclaim 18Gi)
- [ ] §2a push all dirty-with-remote repos
- [ ] §2b create remotes for 2 orphan repos; delete expired archive
- [ ] §2c decide on 2 external-fork dirty repos
- [ ] §3 upload non-dev data to OneDrive-SAPSE/Backup-Migration-2026-10/
- [ ] §4a produce `~/.hermes` encrypted archive (or git-mirror config-only)
- [ ] §4b push `.claude` + `.codex` state repos
- [ ] §4c secrets to Bitwarden (SSH, GPG, service keys)
- [ ] §5 secrets inventory walked, each `.env` decided
- [ ] §6 verify Brewfile matches live Mac (`bash sync.sh`)
- [ ] Wait for OneDrive menu bar icon = "Up to date"

**Monday on new Mac:**
- [ ] §7a Apple ID + FileVault + Touch ID
- [ ] §7b Homebrew + gh + mac-setup-guide + bootstrap.sh
- [ ] §7c State restore (vaults, repos, Hermes, Claude, Codex, AI Core)
- [ ] §7d All sanity checks green = old Mac retirable

---

## See also

- `MANUAL_STEPS.md` — the general fresh-Mac bootstrap this doc specialises
- `docs/hermes-on-personal-mac.md` — personal-Mac counterpart (different: no MDM, no Umbrella)
- Skill `app-state-backup-to-git` — the pattern used for §4 (encrypted archive variant)
- Skill `mac-setup-sync` — how to keep this repo honest after the migration
