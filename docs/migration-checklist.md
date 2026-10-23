# Mac Migration — Live Checklist (Oct 2026)

> **Companion doc to `docs/migration-day.md`** — this one is the tick-off view, mirrored into Notion for mobile use.
> Notion page: [🚚 Mac Migration — Oct 2026 (SAP work replacement)](https://app.notion.com/p/Mac-Migration-Oct-2026-SAP-work-replacement-402806250ab781dab5d1fecd596a6b51) — parent: 🖥️ Mac Setup hub.
> **Mirror into Obsidian** at `Tools-Setup/Migration-Checklist.md`.

---

## 🚨 Critical finding from today's audit (2026-10-23)

**OneDrive is NOT auto-backing-up your home directory.** Verified live:

| Path | Reality |
|---|---|
| `~/Downloads` (17G, today's files) | NOT in OneDrive. The 67G `OneDrive-SAPSE/Downloads` is an old manual copy from Aug 2026, different inode, 1534 extra files but missing recent ones. |
| `~/Projects` (2.3G, current) | NOT in OneDrive. The 8.7G `OneDrive-SAPSE/Projects` is from Aug, 5 fewer current repos. |
| `~/Desktop`, `~/Documents`, `~/Pictures`, `~/Music`, `~/Movies` | NOT in OneDrive. Known Folder Move is OFF. |
| `~/.hermes` (16G), `~/.claude`, `~/.codex`, `~/.ssh`, `~/.gnupg` | NOT in OneDrive. Only on this laptop. |

**Only files you placed inside `~/Library/CloudStorage/OneDrive-SAPSE/` sync to cloud.** Everything else dies with the laptop. Act accordingly.

**No reliable OneDrive CLI on Mac for SAP tenants.** `abraunegg/onedrive` and `onedriver` exist but SAP conditional access blocks them (can't do Entra device registration). Verification is via `fileproviderctl dump` + `du` + Finder badges — all three used today.

---

## 0. Pre-flight (do first — disk reclaim)

Mac is 90% full (44Gi free of 460Gi). These reclaim ~18Gi, zero data loss:

- [ ] `rm -rf ~/.cache ~/.npm/_cacache ~/.npm/_logs`
- [ ] `brew cleanup --prune=all`
- [ ] `docker system prune -a --volumes` (if Docker still used)
- [ ] Verify ≥60Gi free: `df -h ~`

---

## 1. OneDrive — fix the sync gap

**Decision:** either enable Known Folder Move (KFM) OR manually rsync into OneDrive-SAPSE. KFM is cleaner but may conflict with SAP MDM — check if unsure.

- [ ] Confirm OneDrive menu bar icon = "Up to date" (not paused/error)
- [ ] Spot-check: `diff <(ls ~/Downloads) <(ls ~/Library/CloudStorage/OneDrive-SAPSE/Downloads)` — expect huge diff (confirms audit)
- [ ] Decide KFM vs manual rsync (see §3 commands below)
- [ ] If KFM: OneDrive settings → Backup → Manage backup → Desktop + Documents + Pictures → Start backup
- [ ] If manual rsync: run §3 commands and wait for sync to catch up

---

## 2. Git repos — push before Monday

**14 dirty + 3 orphan-remote repos. Decision tree:**

### 2a. NO-REMOTE (highest priority — laptop death = loss)

- [ ] `~/Projects/hermes-litellm-stack` (dirty=12) → create private remote:
      ```bash
      cd ~/Projects/hermes-litellm-stack
      git add -A && git commit -m "feat: pre-migration snapshot"
      gh repo create narendra-babu-m/hermes-litellm-stack --private --source=. --push
      ```
- [ ] `~/Projects/daylio-bulk-insert` (dirty=5) → same pattern as above
- [ ] `~/Archive/SAP_DMC_APIs.OLD-DELETE-AFTER-2026-08-13` (dirty=26) → **name says delete**: `rm -rf` it, do not back up

### 2b. Dirty with remote — push wip snapshot

For each: `cd <repo> && git status`, review, then:
```bash
git add -A && git commit -m "chore: pre-migration snapshot $(date +%F)" && git push
```

- [ ] `~/claude-professional` (dirty=8) → github.com/narendra-babu-m/claude-professional
- [ ] `~/work-log` (dirty=27, likely daily-log catchup) → github.com/narendra-babu-m/work-log
- [ ] `~/claude-os-dashboard` (dirty=1) → github.com/narendra-babu-m/claude-os-dashboard
- [ ] `~/hermes-self` (dirty=1) → github.com/narendra-babu-m/hermes-self
- [ ] `~/bruno-collections` (dirty=1) → github.tools.sap/I576292/bruno-collections (SAP internal)
- [ ] `~/Projects/16-production-process-analyser` (dirty=3) → github.tools.sap/SAP-DMC-Utilities
- [ ] `~/Projects/PANDORA-docs/11-vn-fx-custom-launchpad` (dirty=2) → Azure DevOps pandora-jewelry
- [ ] `~/Projects/PANDORA-docs/04-vn-fe-teamlead-plugin` (dirty=3) → Azure DevOps
- [ ] `~/Projects/PANDORA-docs/06-vn-next-number-ext` (dirty=1) → Azure DevOps

### 2c. External forks (decide: own delta or drop it)

- [ ] `~/Projects/tv-detox` (dirty=10, upstream Ansub/tv-detox) — fork + push, or save as patch
- [ ] `~/AI_Project/scb_pa_final` (dirty=6, upstream sriramrokkam) — same decision

### 2d. Clean repos (verify remote has latest commit)

Already safe, nothing to do unless `git log origin/main..HEAD` shows unpushed:

- `~/mac-setup-guide` (clean, 0ddf63f pushed ✓)
- `~/Vaults/ObsidianBrain-{Personal,Professional}` ✓
- `~/bloomberg-terminal`, `~/claude-workspace-system`, `~/Projects/local-ai-fabric`, `~/Projects/atlas`, `~/Projects/spotify-library-os` ✓
- SAP internal: `~/repos/dm-mcp-server`, `~/dmc-pod-toolkit`, `~/Projects/joule-a2a-agent-toolkit` ✓

---

## 3. OneDrive upload — what GOES to cloud

**Non-dev, non-secret user data only.** Dev state goes to git (§2) or encrypted archive (§5). Create one target dir and rsync into it.

```bash
DEST=~/Library/CloudStorage/OneDrive-SAPSE/Backup-Migration-2026-10
mkdir -p $DEST/{Downloads,Pictures,Music,Movies,Documents,Desktop,Archive,Patches,AppSettings}

# Dry-run first (-n). Review output, then remove -n to commit.
rsync -avhn --exclude='*.dmg' --exclude='*.pkg' --exclude='.DS_Store' ~/Downloads/ $DEST/Downloads/
rsync -avhn ~/Pictures/ $DEST/Pictures/
rsync -avhn ~/Music/ $DEST/Music/
rsync -avhn ~/Movies/ $DEST/Movies/
rsync -avhn ~/Documents/ $DEST/Documents/
rsync -avhn ~/Desktop/ $DEST/Desktop/
rsync -avhn --exclude='SAP_DMC_APIs.OLD-DELETE-AFTER-*' ~/Archive/ $DEST/Archive/
cp ~/mac-setup-guide/Brewfile $DEST/Brewfile.snapshot
```

Expected total: ~15-20Gi after Downloads filter. Verify: `du -sh $DEST`. Then wait for OneDrive menu bar = "Up to date".

- [ ] Dry-run rsync (reads output, nothing changes)
- [ ] Commit rsync (remove `-n` flag)
- [ ] Wait for OneDrive sync completion (menu bar check)

---

## 4. App settings — the "my customizations" layer

**Many apps store their customization locally, not in iCloud or OneDrive.** Lose the laptop = lose years of tweaking. These need explicit backup.

### 4a. Terminal + shell (critical first)

- [ ] **iTerm2** profiles + colors: `~/Library/Preferences/com.googlecode.iterm2.plist` → copy to `$DEST/AppSettings/iterm2.plist`
- [ ] **Warp** settings: `~/.warp/settings.toml` + `~/.warp/tab_configs/` → `$DEST/AppSettings/warp/`
- [ ] **Zellij** configs: already in `~/mac-setup-guide/dotfiles/zellij/` (symlinked) ✓
- [ ] **Ghostty**: already in `~/mac-setup-guide/dotfiles/ghostty/` (symlinked, if used) ✓
- [ ] **Zsh**: `~/.zshrc` + `~/.zprofile` → copy to `$DEST/AppSettings/zsh/` (protected files, not in dotfiles repo)
- [ ] **atuin** (shell history): `atuin sync` first, then `atuin login` on new Mac restores it
- [ ] **thefuck, zoxide, direnv, powerlevel10k** — all brew formulas, configs regenerate from `.zshrc`

### 4b. Editors (biggest customization surface)

- [ ] **VS Code** settings (10K): `~/Library/Application Support/Code/User/settings.json` + `keybindings.json` + `snippets/`
      - Alternative: **Settings Sync** (sign in with GitHub, auto-restores on new Mac)
      - 51 extensions installed — Settings Sync restores these too
- [ ] **Cursor** settings (662B): `~/Library/Application Support/Cursor/User/settings.json` + extensions
- [ ] **Xcode** preferences: `~/Library/Developer/Xcode/UserData/` (if you've customized key bindings / behaviors)
- [ ] **Obsidian** per-vault plugins + settings: `~/Vaults/*/.obsidian/` — **already in git ✓** (part of each vault repo)

### 4c. Productivity apps

- [ ] **Raycast**: Pro users get cloud sync. Free users: `~/Library/Application Support/com.raycast.macos/` (NodeJS extensions, activities DB)
- [ ] **Rectangle** window shortcuts: `~/Library/Preferences/com.knollsoft.Rectangle.plist`
- [ ] **Maccy** clipboard: `~/Library/Application Support/Maccy/` — history is probably not worth keeping; shortcuts via plist
- [ ] **Hidden Bar** menu config: plist
- [ ] **Stats** menu bar: plist (CPU/GPU/RAM module settings)
- [ ] **Only Switch**: plist
- [ ] **Caffeine**: brew cask reinstalls; settings minimal

### 4d. Dev tools

- [ ] **TablePlus** DB connections: `~/Library/Application Support/com.tinyapp.TablePlus/Data/` — contains encrypted connection strings, port these intact to `$DEST/AppSettings/tableplus/`
- [ ] **Bruno** API collections: `~/bruno-collections/` is already a git repo (dirty=1, push per §2b)
- [ ] **Docker Desktop**: `~/.docker/config.json` + `~/.docker/contexts/` → `$DEST/AppSettings/docker/`
- [ ] **GitHub Desktop** / `gh` CLI: `gh auth status` → PAT lives in Keychain, `gh auth login` on new Mac
- [ ] **git config**: already in `~/mac-setup-guide/scripts/git-defaults.sh` ✓

### 4e. SAP work-specific

- [ ] **Microsoft Teams**: signs in via SAP SSO, chat history survives (server-side)
- [ ] **Outlook**: online data, signs in via SSO
- [ ] **GlobalProtect / Cisco AnyConnect / FortiClient**: SAP IT reinstalls via Self Service; connection profiles may need re-entry
- [ ] **Snagit 2024**: licenses tied to SAP account; captures in `~/Documents/Snagit/` or similar
- [ ] **Self Service**: SAP IT reinstalls

### 4f. Browsers (where most "set up again" pain actually lives)

- [ ] **Brave Browser**: sign in to Brave account → bookmarks/extensions/history/passwords sync
- [ ] **Edge**: sign in to Microsoft account → same
- [ ] **Chrome**: sign in to Google account → same
- [ ] **Safari**: iCloud Keychain + Safari sync via Apple ID
- [ ] **Comet**: check if it has cloud sync; otherwise plist

**Pre-flight: ensure sync is working on each browser BEFORE wiping the old Mac.** Open each → settings → sync status → "Up to date / synced".

---

## 5. State dirs — special handling (NOT OneDrive)

### 5a. ~/.hermes (16G) — encrypted archive

Too big for a plain git repo, needs to carry secrets intact.

- [ ] Use `app-state-backup-to-git` skill's **encrypted-portable-archive** variant
- [ ] Produces `~/.hermes/migration/hermes-<date>.tar.gz.gpg` + checksum manifest
- [ ] Store `.gpg` in OneDrive-SAPSE/AppSettings/hermes/; passphrase in Bitwarden
- [ ] **Lighter alternative:** config-only (skills + cron + memories + hooks + configs, skip cache/logs/sessions) — likely enough for work-Mac handover; chat history ≠ productivity

### 5b. ~/.claude (199M) — this one is "the biggest challenge"

See §6 below — full dedicated section.

### 5c. ~/.codex (687M)

- [ ] Check if there's a backup repo — likely not. Create one:
      ```bash
      # Pattern from the app-state-backup-to-git skill
      mkdir ~/codex-backup && cd ~/codex-backup
      rsync -a --exclude='cache' --exclude='sessions' --exclude='*.log' ~/.codex/ ./codex/
      git init && git add -A && git commit -m "feat: initial codex state"
      gh repo create narendra-babu-m/codex-backup --private --source=. --push
      ```

### 5d. ~/.ssh, ~/.gnupg, service keys — Bitwarden ONLY

**Never OneDrive. Never git plaintext.**

- [ ] SSH keys: either regenerate on new Mac (add new pubkey to GitHub) OR archive encrypted:
      ```bash
      tar -czf /tmp/ssh.tar.gz -C ~ .ssh && gpg --symmetric --cipher-algo AES256 /tmp/ssh.tar.gz && rm /tmp/ssh.tar.gz
      # Store the .gpg as Bitwarden attachment, OR in OneDrive (encrypted = safe)
      ```
- [ ] GPG keys: same pattern as SSH
- [ ] SAP AI Core service key: **regenerate from BTP cockpit on new Mac** (easier than copy)
- [ ] HAI proxy API key: **rotates on restart anyway** — fresh key on new Mac Keychain
- [ ] Scan projects for `.env` leaks: `find ~/Projects ~/AI_Project -name ".env*" -o -name "*.key" -o -name "*service-key*"`
      - For each: decide regenerate / Bitwarden entry / delete

### 5e. ~/.config (145M)

Partially mirrored by `~/mac-setup-guide/dotfiles/`. Audit the rest:
- [ ] `ls ~/.config` — for each `~/.config/<tool>` NOT in dotfiles: port into repo or skip

---

## 6. Claude Code — the "biggest challenge" (full parity restore)

**Scope confirmed:** full parity = 22 plugins, 10 MCP servers, 11 hooks, 18 skills, 137M project state, 3 repos, LiteLLM proxy routing.

### 6a. BEFORE old Mac is wiped — commit all state

- [ ] `cd ~/claude-professional` → audit, commit, push:
      ```bash
      git status  # dirty=8 as of audit; eyeball before mass-commit
      git add -A && git commit -m "chore: pre-migration snapshot" && git push
      ```
- [ ] `cd ~/claude-workspace-system` → already clean, confirm `git log origin/main..HEAD` empty
- [ ] `cd ~/claude-os-dashboard` → commit `scripts/publish.py` dirty, push
- [ ] Produce `~/.claude` state archive (same pattern as `~/.hermes` encrypted archive):
      ```bash
      mkdir ~/claude-state-backup && cd ~/claude-state-backup
      rsync -a \
        --exclude='cache' --exclude='paste-cache' --exclude='shell-snapshots' \
        --exclude='file-history' --exclude='sessions' --exclude='debug' \
        --exclude='downloads' --exclude='.DS_Store' --exclude='*.log' \
        --exclude='settings.json.bak*' --exclude='settings.json.backup*' --exclude='settings.json.pre-*' \
        ~/.claude/ ./claude/
      # Keep: CLAUDE.md, settings.json, settings.local.json, agents/, hooks/, plugins/, skills/, tasks/, projects/
      git init && git add -A && git commit -m "feat: initial claude state (config + agents + hooks + skills)"
      gh repo create narendra-babu-m/claude-state-backup --private --source=. --push
      ```
- [ ] Export the enabled-plugins list AS TEXT (survives everything):
      ```bash
      jq '.enabledPlugins | keys' ~/.claude/settings.json > ~/claude-plugins-enabled.txt
      cat ~/claude-plugins-enabled.txt
      # Commit this into claude-state-backup repo
      ```

### 6b. Capture current MCP + env setup to a Phoenix doc

- [ ] Record the exact LiteLLM proxy routing (`settings.json.env` already captured today):
      - `ANTHROPIC_BASE_URL=http://localhost:4000`
      - `ANTHROPIC_MODEL=sap/anthropic--claude-4.7-opus`
      - `ANTHROPIC_DEFAULT_HAIKU_MODEL=sap/anthropic--claude-4.5-haiku`
      - `ANTHROPIC_DEFAULT_SONNET_MODEL=sap/anthropic--claude-4.6-sonnet`
      - `ANTHROPIC_DEFAULT_OPUS_MODEL=sap/anthropic--claude-4.7-opus`
      - OTEL endpoint: `http://localhost:6655/otel/v1/metrics`
      - `ANTHROPIC_AUTH_TOKEN` — Bitwarden entry needed
- [ ] Record each MCP server command (from `~/.claude.json .mcpServers`):
      - `gitnexus`, `sapui5-mcp`, `fiori-element-brain`, `github-tools` (HTTP), `cds-mcp`, `ui5mcp`, `playwright`, `context7`, `dm-pod2-mcp`, `notion`
- [ ] Record hooks (iTerm status + gitnexus pre/post bash hooks)

### 6c. ON NEW MAC — Claude Code restore order (micro-steps)

**Phase 1: Prerequisites**

- [ ] 1. Install Node via brew bootstrap (already in Brewfile)
- [ ] 2. Install Claude Code CLI: `npm install -g @anthropic-ai/claude-code` OR via claude.ai/download
- [ ] 3. Verify: `claude --version` → should match 2.1.74 or newer
- [ ] 4. Install dependencies: `npm install -g gitnexus` (if MCP depends on global install) — check which MCP servers need global vs npx

**Phase 2: Local proxy stack (CRITICAL — Claude won't work without this)**

- [ ] 5. Install HAI proxy via SAP internal install (per `~/.hermes/skills/mlops/sap-aicore-doctor` or `hai-proxy-degradation-recovery` skills)
- [ ] 6. Start HAI proxy: `hai proxy start` → rotates API key into macOS Keychain (`hai-cli` / `hai-proxy-api-key`)
- [ ] 7. Verify HAI proxy: `hai proxy status` → listening on 6655
- [ ] 8. Install LiteLLM via `~/Projects/local-ai-fabric` (already a cleanly pushed repo): `git clone ... && docker compose up -d`
- [ ] 9. Verify LiteLLM: `curl -s http://localhost:4000/v1/models | head`

**Phase 3: Clone state repos**

- [ ] 10. `git clone git@github.com:narendra-babu-m/claude-state-backup.git ~/.claude-restore`
- [ ] 11. `rsync -a ~/.claude-restore/claude/ ~/.claude/` (restores CLAUDE.md, settings.json, agents, hooks, plugins list, skills)
- [ ] 12. `git clone git@github.com:narendra-babu-m/claude-professional.git ~/claude-professional`
- [ ] 13. `git clone git@github.com:narendra-babu-m/claude-workspace-system.git ~/claude-workspace-system`
- [ ] 14. `git clone git@github.com:narendra-babu-m/claude-os-dashboard.git ~/claude-os-dashboard`

**Phase 4: Secrets + auth**

- [ ] 15. `ANTHROPIC_AUTH_TOKEN` from Bitwarden → put into `~/.claude/settings.json` env block (already in restored file)
- [ ] 16. Verify Keychain has `hai-cli` / `hai-proxy-api-key` entries (step 6 should have done this)
- [ ] 17. Test one claude invocation: `claude --version && cd /tmp && claude -p "say hi"` → should respond via LiteLLM proxy

**Phase 5: Plugins + MCP servers**

- [ ] 18. Open Claude Code once interactively — triggers plugin reload from `enabledPlugins` in settings.json
- [ ] 19. Verify 22 plugins listed: `/plugins` command shows them
- [ ] 20. For each MCP server, verify command path exists:
      - `which gitnexus` (brew formula)
      - For `node`/`npx` servers: check path to `.js` entry file
      - For `https://mcp.github.tools.sap/mcp`: needs SAP network (GlobalProtect)
- [ ] 21. If `context7` / `playwright` / `cds-mcp` show auth-needed on first use, run through OAuth once
- [ ] 22. Test MCP: in Claude Code, ask it to use `notion` MCP → should list Notion pages

**Phase 6: Hooks (optional but nice)**

- [ ] 23. Verify `~/.config/iterm2/cc-status` script exists (iTerm status line integration)
- [ ] 24. Verify `~/.claude/hooks/gitnexus/gitnexus-hook.cjs` exists (restored by rsync)
- [ ] 25. In a Bash tool call, see PreToolUse hook fire ("Enriching with GitNexus graph context...")

**Phase 7: Knowledge graph pipeline + Obsidian integration**

- [ ] 26. Clone `~/Vaults/ObsidianBrain-Personal` and `~/Vaults/ObsidianBrain-Professional` (if not already done per §5)
- [ ] 27. Verify `claude-professional/scripts/` paths are intact (knowledge-graph pipeline lives here)
- [ ] 28. Run one knowledge-graph refresh: `cd ~/claude-professional && bash scripts/<entry>.sh` (check name)
- [ ] 29. Confirm Obsidian daily-note integration works end-to-end

**Phase 8: Smoke test**

- [ ] 30. Open a real work repo: `cd ~/dmc-pod-toolkit && claude`
- [ ] 31. Ask Claude to do a mid-complexity task (grep + file edit + hook fires)
- [ ] 32. If all green → Claude Code is fully restored, parity achieved

---

## 7. Monday on new Mac — top-level restore order

Follow `MANUAL_STEPS.md` top to bottom. Fast version:

### 7a. First hour (Setup Assistant → Apple ID)
- [ ] Boot new Mac, Apple ID sign-in
- [ ] Enable FileVault (save recovery key to Bitwarden immediately)
- [ ] Enable Touch ID for sudo (MANUAL_STEPS §1)
- [ ] Install Bitwarden from App Store, sign in

### 7b. Next hour (downloads in background)
- [ ] Install Homebrew
- [ ] `gh auth login`
- [ ] `git clone https://github.com/narendra-babu-m/mac-setup-guide ~/mac-setup-guide`
- [ ] `cd ~/mac-setup-guide && bash bootstrap.sh` (goes 30-60 min)
- [ ] Parallel: SAP Self Service → install §6e corporate apps

### 7c. Afternoon — state restore (per sections above)
- [ ] Clone both Obsidian vaults
- [ ] Restore `~/.hermes` (§5a)
- [ ] Restore `~/.claude` + full parity (§6 — 30+ micro-steps)
- [ ] Restore `~/.codex` (§5c)
- [ ] Restore app settings per §4 → copy from OneDrive `AppSettings/` back to `~/Library/...`
- [ ] Rebuild SAP AI Core service key (BTP cockpit)
- [ ] `atuin login && atuin sync` → shell history

### 7d. Sanity checks (go/no-go for retiring old Mac)
Per MANUAL_STEPS §7 PLUS:
- [ ] `hermes --version` works
- [ ] `hai proxy status` healthy
- [ ] Both Obsidian vaults open with latest notes
- [ ] `claude --version && claude -p "test"` works via LiteLLM
- [ ] `cd ~/mac-setup-guide && bash validate.sh --drift-only` → 0 DRIFT
- [ ] One real work task end-to-end (open DMC PPD, run Bruno collection)
- [ ] One real personal task (Bloomberg terminal, Hermes query)

**Only when ALL green: old Mac can be wiped and returned.**

---

## 8. Priority order (today → Sunday → Monday)

### Today (Thursday 2026-10-23)
- [ ] §0 disk cleanup (reclaim 18Gi)
- [ ] §2a create 2 private remotes for orphan repos
- [ ] §2a delete expired archive
- [ ] §6a start Claude state backup repo
- [ ] §4f confirm browser sync is ON for all 4 browsers

### Friday
- [ ] §2b push 9 dirty repos (claude-professional, work-log, PANDORA, etc.)
- [ ] §2c decide on 2 external forks
- [ ] §5a produce ~/.hermes encrypted archive
- [ ] §5d scan for .env secret leaks, Bitwarden entries

### Saturday
- [ ] §4 app settings backup (iTerm, Warp, VS Code, TablePlus, Docker, etc.) → OneDrive AppSettings/
- [ ] §3 OneDrive upload (Downloads/Pictures/Music/Movies/Documents filtered rsync)
- [ ] §6a push `claude-professional` dirty state

### Sunday
- [ ] Verify everything synced (OneDrive menu bar = "Up to date")
- [ ] `bash sync.sh` → Brewfile matches live Mac
- [ ] Dry-run restore mentally: close the laptop, could you rebuild from Bitwarden + github.com?

### Monday
- [ ] §7a → §7b → §7c → §7d
- [ ] All green = retire old Mac

---

## 9. See also

- `~/mac-setup-guide/docs/migration-day.md` — the prose runbook this checklist mirrors
- `MANUAL_STEPS.md` §5 Restore Personal State — top-level restore order
- `~/mac-setup-guide/docs/hermes-on-personal-mac.md` — personal-Mac counterpart (different: no MDM, no Umbrella)
- Skill `app-state-backup-to-git` — encrypted-portable-archive pattern (§5a, §5b, §5c)
- Skill `mac-setup-sync` — keeping this repo honest post-migration
- Notion page: [🚚 Mac Migration — Oct 2026](https://app.notion.com/p/Mac-Migration-Oct-2026-SAP-work-replacement-402806250ab781dab5d1fecd596a6b51) (parent: 🖥️ Mac Setup hub)
