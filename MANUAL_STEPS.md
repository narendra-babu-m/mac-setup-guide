# Manual Setup Steps

> Things `defaults write` and `brew bundle` cannot do for you. Apple's
> security model, App Store sign-in, biometric enrollment, and per-app
> "first launch" gates require human hands.

This file is the irreducible manual list. Walk it top to bottom on a
fresh Mac and you'll be operational in one day.

---

## ⏱ Time budget

| Block | Time | What |
|---|---|---|
| Apple ID + system | 30 min | iCloud, FileVault, Firewall, Touch ID for sudo |
| Identity + auth | 30 min | Bitwarden, GitHub, SSH/GPG keys, browsers |
| Run bootstrap.sh | 30-60 min | Brew + casks install runs in parallel |
| First-launch app config | 60-90 min | Raycast, Warp, Obsidian, etc. |
| Restore vaults | 30 min | git clone ObsidianBrain repos, restore Hermes |

Total: 4-6 hours of attention, mostly downloads + waiting.

---

## 1. Apple ID + System (do first, blocks everything else)

- [ ] **Sign in to iCloud** (System Settings → Apple ID)
  - Skip iCloud Drive sync for `Documents` and `Desktop` — keep work local
  - Naren rule: NEVER store dev tools, .env, or secrets on iCloud/OneDrive
- [ ] **Enable FileVault**: System Settings → Privacy & Security → FileVault → Turn On
  - Save the recovery key in your password manager (NOT iCloud)
- [ ] **Enable Firewall**: System Settings → Network → Firewall → Turn On
  - Enable stealth mode if you're on untrusted networks regularly
- [ ] **Touch ID for sudo** (massive ergonomic win):
  ```bash
  sudo cp /etc/pam.d/sudo /etc/pam.d/sudo.bak
  # On Sonoma+: use the local config so OS updates don't wipe it
  sudo tee /etc/pam.d/sudo_local <<'EOF'
  auth       sufficient     pam_tid.so
  EOF
  ```
  Test: open a new shell, run `sudo -k && sudo whoami` — Touch ID prompt should appear.
- [ ] **Find My Mac**: System Settings → Apple ID → iCloud → Find My Mac → On
- [ ] **Sound > Allow Accessories to Connect**: set per your security posture
- [ ] **Enable nightly screen lock check**: covered by `security-defaults.sh`,
      verify: System Settings → Lock Screen → Require password "immediately"

---

## 2. Identity & Auth

- [ ] **Bitwarden / 1Password**: install (in Brewfile? add it), sign in
- [ ] **GitHub auth**:
  ```bash
  gh auth login                           # follow the prompts (HTTPS + browser)
  ssh-keygen -t ed25519 -C "your@email"   # if you don't have a key yet
  cat ~/.ssh/id_ed25519.pub               # paste into github.com/settings/keys
  ssh -T git@github.com                   # verify
  ```
- [ ] **GPG (if you sign commits)**:
  ```bash
  brew install gnupg pinentry-mac
  # Restore keys from secure backup, or generate new
  ```
- [ ] **Browsers**: sign in to Brave, Edge, Safari; restore extensions, bookmarks

---

## 3. Run the bootstrap

```bash
cd ~
git clone https://github.com/narendra-babu-m/mac-setup-guide.git
cd mac-setup-guide
bash bootstrap.sh
```

This runs `brew bundle` + every `*-defaults.sh` script. Idempotent — safe
to re-run. Coffee, walk, or stretch while brew downloads.

---

## 4. First-Launch App Configuration

These apps need a one-time launch + settings before they're useful.

### Raycast
- Cmd+Space → set as Spotlight replacement (will prompt)
- Settings → Extensions → install: Window Management, Clipboard History,
  GitHub, Brew, Color Picker, Calculator
- Pro tip: Window Management replaces Rectangle for free

### Warp / iTerm2
- Sign in (Warp); apply your colorscheme + font (Fira Code Nerd Font)
- Source your shell config: `source ~/.zshrc`
- Init atuin: `echo 'eval "$(atuin init zsh)"' >> ~/.zshrc`
- Init zoxide: `echo 'eval "$(zoxide init zsh)"' >> ~/.zshrc`

### Obsidian
- Open vault from cloned location (NOT default Obsidian-Vault)
- Sign in to Obsidian Sync if used (Naren rule: prefer git remotes)

### Docker Desktop
- First launch needs admin password to install helper
- Settings → Resources: cap memory if needed

### VPN clients (corporate Mac only)
- GlobalProtect, FortiClient, BIG-IP — install via SAP Self Service if not Brewfile-able

### Stats menu bar app
- Right-click each module to configure CPU / GPU / RAM / Disk / Network display

---

## 5. Restore Personal State

- [ ] **Hermes config**: `git clone` your hermes profile repo (or rerun `hermes setup`)
- [ ] **Obsidian vaults**:
  ```bash
  mkdir -p ~/Vaults && cd ~/Vaults
  git clone git@github.com:narendra-babu-m/obsidian-personal.git ObsidianBrain-Personal
  git clone git@github.com:narendra-babu-m/obsidian-professional.git ObsidianBrain-Professional
  ```
- [ ] **SAP AI Core service key**: regenerate from Bitwarden Secrets Manager
      (see skill `sap-ai-core-local-tools`)
- [ ] **Dotfiles**: clone your dotfiles repo, run its install script
- [ ] **VS Code**: enable Settings Sync (sign in with GitHub)
- [ ] **Shell history (atuin)**: `atuin login` + `atuin sync` to pull history

---

## 6. MDM / Corporate Caveats (work Mac only)

If your Mac is MDM-enrolled (`profiles status -type enrollment`):

- Some `defaults` writes will be silently overridden by configuration profiles
  (firewall, FileVault, screen lock policy, certain Safari settings)
- VPN, antivirus, and login-item-managed apps may auto-install — let them
- App Store + brew casks may be partially restricted by Gatekeeper rules
- You'll likely need IT for: admin password, software allow-listing, certs

For a personal Mac, none of the above apply — every script in this repo
should work cleanly.

---

## 7. Sanity Checklist

After running everything, verify:

- [ ] `brew doctor` clean
- [ ] `gh auth status` signed in
- [ ] `ssh -T git@github.com` works
- [ ] `defaults read com.apple.finder ShowPathbar` returns 1
- [ ] Cmd+Space opens Raycast (not Spotlight)
- [ ] Touch ID works on `sudo whoami`
- [ ] Both Obsidian vaults open
- [ ] Hermes works: `hermes --help`

If any of these fail, see the matching section above. If a `defaults`
script reports "set" but the change doesn't appear, your Mac is likely
MDM-managed — that key is overridden by a profile (not your fault).

---

## 8. Maintenance — Keeping the repo as the source of truth

This is the part that breaks every "Mac setup repo" eventually: you install
a tool ad-hoc, change a System Settings toggle, and the repo silently
falls out of sync. Three weeks later the repo is a lie.

**Rule of thumb: any change to your Mac that you'd be sad to lose belongs in this repo.**

### When you install a brew package or cask

```bash
# install as usual
brew install <something>           # or: brew install --cask <app>

# then sync the repo
bash ~/mac-setup-guide/sync.sh
cd ~/mac-setup-guide
git diff Brewfile                  # review the change
git add Brewfile && git commit -m "chore(brewfile): add <package>" && git push
```

`sync.sh` runs `brew bundle dump` and compares it to the repo's `Brewfile`.
If there's drift, it overwrites the file and tells you to commit.

### When you change a System Settings toggle

System Settings doesn't write to a single deterministic place — there's no
clean "dump my Mac to a script" inverse. So:

1. Open the matching `scripts/<area>-defaults.sh`
2. Find the variable, flip the value (or add a new var + WHY comment)
3. Run the script to confirm it reproduces the change you made manually
4. Commit

Example: you turned off Dock magnification via System Settings. Edit
`scripts/dock-defaults.sh`, set `DOCK_MAGNIFICATION=false`, commit.

### When you add a new Login Item

System Settings → General → Login Items can't be written from `defaults`
on Sonoma+ (it's controlled by `SMAppService` per-app). Document it in
this file's §4 "First-Launch App Configuration" instead.

### When you add a Raycast / VS Code / browser extension

These have their own sync mechanisms — sign in to the cloud sync feature
and you're done. Don't try to script them.

### Checklist (paste into your weekly review)

- [ ] `bash ~/mac-setup-guide/sync.sh` shows no drift
- [ ] Any new System Settings change reflected in a `*-defaults.sh` var
- [ ] New Login Items documented in MANUAL_STEPS.md §4
- [ ] Repo committed + pushed

If you notice yourself thinking "I'll remember to add this later" —
that's the moment to stop and add it now. Future-you on a new Mac at
2 a.m. won't remember.
