# ============================================================================
# Brewfile — Declarative install for ~/mac-setup-guide
# Run:    brew bundle --file=~/mac-setup-guide/Brewfile
# Audit:  bash ~/mac-setup-guide/sync.sh   (compares to live Mac, no overwrite)
# ============================================================================
# Conventions:
#   - Curated, hand-grouped, with `# WHY` notes where intent isn't obvious.
#   - sync.sh NEVER overwrites this file; it only reports drift.
#   - When sync.sh shows "ON MAC, NOT IN REPO", re-home each entry into the
#     right section below with a brief WHY comment, then commit.
#   - When sync.sh shows "IN REPO, NOT ON MAC", either reinstall via
#     `brew bundle` or remove the entry intentionally.

# ── Taps ────────────────────────────────────────────────────────────────────
tap "homebrew/bundle"
# WHY: terraform — official HashiCorp tap (cf core terraform formula was deprecated).
tap "hashicorp/tap", trusted: true
# WHY: cf CLI for SAP BTP / Cloud Foundry deployments (work).
tap "cloudfoundry/tap", trusted: true
# WHY: hAIperspace `hai` CLI — internal SAP AI tool. Memory: HAI = SAP work only.
tap "haiperspace/hai", "https://github.tools.sap/hAIperspace/hai-homebrew", trusted: true
# WHY: design fonts (font-crimson-pro, ia-writer-quattro, inter, lora) for
#      vault/docs. NOTE: tap homebrew/cask-fonts deprecated (2026-06); fonts
#      now live in homebrew/cask. Untapped on 2026-06-12 — no-op for users.

# ── Formulae: terminal essentials ───────────────────────────────────────────
brew "bat"           # cat with syntax highlighting
brew "btop"          # gorgeous resource monitor
brew "eza"           # modern ls replacement
brew "fastfetch"     # system info
brew "tealdeer"      # tldr fork, actively maintained (replaces deprecated tldr)
brew "fzf"           # fuzzy finder
brew "htop"          # process monitor
brew "procs"         # ps replacement
brew "ripgrep"       # fast grep
brew "tmux"          # terminal multiplexer (legacy / SSH compatibility)
brew "zellij"        # terminal multiplexer (modern, layouts, sessions)
brew "tree"          # directory viewer
brew "yazi"          # TUI file manager
brew "zoxide"        # smart cd
brew "ncdu"          # disk usage TUI
brew "glow"          # markdown viewer
brew "atuin"         # shell history (sync across Macs)
brew "thefuck"       # command corrector
brew "bash"          # newer bash (>3.2) for scripts that need it
brew "direnv"        # per-directory env vars
brew "cmatrix"       # for the lulz / screensaver

# ── Formulae: dev tools ─────────────────────────────────────────────────────
brew "gh"            # GitHub CLI
brew "git"
brew "git-delta"     # better git diffs
brew "lazygit"       # git TUI
brew "difftastic"    # structural diff
brew "jq"            # JSON processor
brew "yq"            # YAML processor
brew "httpie"        # HTTP client
brew "node"
brew "go"
brew "pyenv"
brew "python@3.13"
brew "python@3.11"   # WHY: pinned for projects requiring 3.11 (some ML tooling)
brew "uv"            # fast Python package/env manager
brew "maven"
brew "openjdk"
brew "openjdk@17"
brew "cmake"
brew "make"
brew "sqlite"
brew "kubernetes-cli"
brew "kubectx"       # kubectl context/namespace switcher
brew "k9s"
brew "azure-cli"
brew "ollama", restart_service: :changed   # local LLMs (auto-restart on upgrade)
brew "wget"
brew "curl"

# WHY: terraform from hashicorp/tap (newer than core formula)
brew "hashicorp/tap/terraform"

# ── Formulae: SAP / cloud ──────────────────────────────────────────────────
brew "cloudfoundry/tap/cf-cli@8"                # primary cf CLI for BTP
brew "haiperspace/hai/hai"                      # SAP HAI CLI (work only)

# ── Formulae: media / OCR / Android ────────────────────────────────────────
brew "ffmpeg"        # video transcoding (ASCII video, songsee, etc.)
brew "yt-dlp"        # YouTube DL (vault ingest)
brew "exiftool"      # photo/video metadata (HDD photo sort skill)
brew "tesseract"     # OCR engine (ocr-and-documents skill)
brew "pandoc"        # markdown ↔ everything
brew "poppler"       # PDF utilities (pdfto* commands)
brew "harfbuzz"      # text shaping (transitive: needed by ASS subtitles, sdl2_ttf)
brew "sdl2_ttf"      # TrueType in SDL apps (emulator deps)
brew "scrcpy"        # Android screen mirroring (samsung-adb / kde-connect skills)
brew "qemu"          # cross-arch emulation (CEH lab)
brew "sevenzip"      # archives

# ── Formulae: shell prompt ──────────────────────────────────────────────────
brew "powerlevel10k"

# ── Formulae: AI / agents ───────────────────────────────────────────────────
brew "fabric"        # AI workflow CLI (Daniel Miessler)
brew "happy-coder"   # CLI for AI coding agents from mobile

# ── Casks: productivity ─────────────────────────────────────────────────────
cask "raycast"           # launcher (replaces Spotlight + Maccy + Rectangle)
cask "obsidian"
cask "rectangle"         # window snapping (fallback if Raycast WM not configured)
cask "hiddenbar"         # menu bar icon manager
cask "stats"             # system stats in menu bar
cask "only-switch"       # toggle macOS settings from menu bar
cask "soduto"            # KDE Connect for macOS (kde-connect-mac-bridge skill)

# ── Casks: dev ──────────────────────────────────────────────────────────────
cask "visual-studio-code"
cask "iterm2"
cask "ghostty"           # GPU-accelerated terminal (Hermes default)
cask "warp"              # AI terminal
cask "github"            # GitHub Desktop
cask "docker"
cask "bruno"             # API client
cask "tableplus"         # database GUI
cask "proxyman"          # HTTP proxy
cask "lens"              # Kubernetes IDE
cask "android-platform-tools"   # adb/fastboot (samsung-adb skill)
cask "btp"               # SAP BTP CLI installer (cask wraps signed binary)
cask "font-fira-code-nerd-font"

# ── Casks: AI ───────────────────────────────────────────────────────────────
cask "claude"
cask "antigravity"       # Google Antigravity (agent orchestration)
cask "antigravity-cli"
cask "antigravity-ide"

# ── Casks: browsers ─────────────────────────────────────────────────────────
cask "brave-browser"
cask "microsoft-edge"

# ── Casks: media ────────────────────────────────────────────────────────────
cask "iina"              # video player (replaces VLC)
cask "vlc"               # fallback / specific format support

# ── Casks: utilities ────────────────────────────────────────────────────────
cask "appcleaner"
cask "localsend"         # WiFi file transfer
cask "caffeine"          # prevent sleep
cask "miniforge"         # conda for Apple Silicon

# ── Casks: emulators / retro gaming (personal Mac) ─────────────────────────
# WARNING (2026-06-12): casks marked DEPRECATED below fail macOS Gatekeeper
# and will be disabled on 2026-09-01. They still work today. Plan: install
# direct from each project's website using the managed-mac-user-scope-install
# pattern, then remove the deprecated cask line here.
cask "openemu"           # DEPRECATED 2026-09-01 — all-in-one retro front end
cask "retroarch"         # libretro multi-system
cask "dolphin"           # GameCube/Wii
cask "flycast"           # DEPRECATED 2026-09-01 — Dreamcast
cask "melonds"           # DEPRECATED 2026-09-01 — Nintendo DS
cask "mgba-app"          # Game Boy Advance
cask "pcsx2"             # PlayStation 2
cask "ppsspp-emulator"   # PSP
cask "xemu"              # original Xbox

# ── Casks: design / writing fonts ──────────────────────────────────────────
cask "font-crimson-pro"
cask "font-ia-writer-quattro"
cask "font-inter"
cask "font-lora"

# ── App Store apps ──────────────────────────────────────────────────────────
# Requires `mas` CLI: brew install mas; sign in to App Store first.
brew "mas"
# mas "Xcode", id: 497799835     # uncomment if you need Xcode (huge download)
