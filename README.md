# Mac Setup — Apps, Tools & Productivity Guide

> **Machine**: MacBook (Apple Silicon) — I576292
> **Last updated**: April 2026

---

## Table of Contents

1. [Installed Applications](#1-installed-applications)
2. [Homebrew Formulae](#2-homebrew-formulae)
3. [Homebrew Casks](#3-homebrew-casks)
4. [Global npm Packages](#4-global-npm-packages)
5. [Python Packages](#5-python-packages)
6. [Top 10 Productivity Tools — Installed](#6-top-10-productivity-tools--installed)
7. [Quick Setup for Each New Tool](#7-quick-setup-for-each-new-tool)
8. [Full Recommendations List](#8-full-recommendations-list)

---

## 1. Installed Applications

### Productivity
| App | What it does |
|---|---|
| **Obsidian** | Markdown knowledge base / notes |
| **Microsoft Excel / Word / PowerPoint** | Office suite |
| **Microsoft Outlook** | Email + Calendar |
| **Microsoft Teams** | Video calls + chat |
| **Microsoft 365 Copilot** | MS AI assistant |
| **Google Docs / Sheets** | Google Office suite |
| **Snagit 2024** | Screenshot + screen recorder |
| **Flow** | Pomodoro / focus timer |
| **Rectangle** | Window snapping/tiling |
| **Maccy** | Clipboard manager |
| **Hidden Bar** | Menu bar icon manager |
| **Only Switch** | macOS quick toggles |
| **Zoom** | Video calls |

### Development
| App | What it does |
|---|---|
| **Visual Studio Code** | Code editor |
| **Xcode** | Apple developer tools |
| **Xcodes** | Xcode version manager |
| **iTerm** | Terminal emulator |
| **Docker** | Container platform |
| **GitHub Desktop** | Git GUI |
| **Bruno** | API client (Postman alternative) |
| **UTM** | VM manager (QEMU-based) |
| **VMware Fusion** | Virtual machines |
| **PostgreSQL 16** | Database |
| **Python 3.12 / 3.13 / 3.14** | Python runtimes |

### AI
| App | What it does |
|---|---|
| **Claude** | Anthropic Claude desktop |
| **Promptly** | Prompt management |
| **Comet** | AI tool |

### Browsers
| App | Notes |
|---|---|
| **Brave Browser** | Privacy-focused Chromium |
| **Microsoft Edge** | Chromium browser |
| **Safari** | Apple native browser |

### Media
| App | What it does |
|---|---|
| **VLC** | Universal media player |
| **Prime Video** | Amazon streaming |
| **Audible** | Audiobooks |

### Utilities
| App | What it does |
|---|---|
| **LocalSend** | Local WiFi file transfer |
| **HEIC Converter** | Image format converter |
| **Authy Desktop** | 2FA authenticator |
| **Backgrounds** | Wallpaper manager |
| **Macs Fan Control 2** | Fan speed control |
| **Power Monitor** | Power/battery monitor |
| **OneDrive** | Microsoft cloud storage |
| **Windows App** | Remote Windows desktop |

### Corporate / SAP
| App | What it does |
|---|---|
| **GlobalProtect** | VPN client |
| **FortiClient** | VPN client |
| **BIG-IP Edge Client** | VPN client |
| **Microsoft Defender** | Antivirus |
| **Company Portal** | Intune MDM |
| **Self Service** | IT app portal |
| **Privileges** | Temporary admin elevation |
| **Apple Configurator** | Device management |

---

## 2. Homebrew Formulae

### Terminal / Shell Tools
| Package | What it does |
|---|---|
| `bat` | `cat` with syntax highlighting |
| `btop` | Beautiful resource monitor (TUI) |
| `eza` | `ls` replacement with colors + icons |
| `fastfetch` | System info display |
| `fzf` | Fuzzy finder — works with everything |
| `htop` | Classic process monitor |
| `neofetch` | System info display |
| `procs` | `ps` replacement in Rust |
| `ripgrep` | Blazing-fast `grep` replacement |
| `thefuck` | Corrects mistyped commands |
| `tldr` | Simplified man pages |
| `tmux` | Terminal multiplexer |
| `tree` | Directory tree viewer |
| `yazi` | Terminal file manager |
| `zoxide` | Smart `cd` — learns your directories |
| `cmatrix` | Matrix rain in terminal |
| `powerlevel10k` | Zsh prompt theme |
| `ncdu` | Disk usage analyzer (TUI) |
| `glow` | Markdown viewer in terminal |
| `screenresolution` | Set screen resolution from CLI |

### Development Tools
| Package | What it does |
|---|---|
| `gh` | GitHub CLI |
| `git` | Version control |
| `git-delta` | Beautiful git diffs |
| `lazygit` | TUI Git client |
| `jq` | JSON processor |
| `httpie` | HTTP client (curl alternative) |
| `node` | Node.js runtime |
| `go` | Go language |
| `pyenv` | Python version manager |
| `python@3.11 / 3.12 / 3.13 / 3.14` | Python runtimes |
| `maven` | Java build tool |
| `openjdk` + `openjdk@17` | Java runtimes |
| `cmake` + `make` | Build systems |
| `sqlite` | Embedded database |
| `terraform` | Infrastructure as code |
| `kubectl` (`kubernetes-cli`) | Kubernetes CLI |
| `azure-cli` | Azure cloud CLI |
| `cf-cli@7 / @8` | Cloud Foundry CLI |
| `ollama` | Run local LLMs |
| `mlx` + `mlx-c` | Apple Silicon ML framework |
| `qemu` | CPU emulation |
| `hai` | SAP AI proxy CLI |
| `wget` + `curl` | File download tools |

### Newly Installed (April 2026)
| Package | What it does |
|---|---|
| `atuin` | Shell history sync + powerful search |
| `k9s` | TUI Kubernetes cluster manager |

---

## 3. Homebrew Casks

| Cask | What it does |
|---|---|
| `bruno` | API client |
| `caffeine` | Prevent Mac from sleeping |
| `font-fira-code-nerd-font` | Dev font with icons |
| `github` | GitHub Desktop |
| `miniforge` | Conda for Apple Silicon |
| `only-switch` | macOS quick toggles |
| `soduto` | KDE Connect for Mac |
| **`raycast`** | Launcher / Spotlight replacement *(new)* |
| **`warp`** | AI-powered terminal *(new)* |
| **`tableplus`** | Database GUI *(new)* |
| **`proxyman`** | HTTP proxy / API debugger *(new)* |
| **`lens`** | Kubernetes IDE *(new)* |
| **`iina`** | Native macOS video player *(new)* |
| **`appcleaner`** | Clean app uninstaller *(new)* |
| **`stats`** | Full system stats in menu bar *(new)* |

---

## 4. Global npm Packages

| Package | Purpose |
|---|---|
| `@anthropic-ai/claude-code` | Claude Code CLI |
| `@github/copilot` | GitHub Copilot |
| `@sap/cds-dk` | SAP CAP framework |
| `@sap/generator-fiori` | SAP Fiori generator |
| `@ui5/cli` | SAP UI5 CLI |
| `typescript` + `ts-node` | TypeScript runtime |
| `yo` | Yeoman generator |
| `mbt` | SAP MTA build tool |
| `dmc-local-app-router` | SAP DMC local router |
| `generator-dmcpodplugin-local` | SAP DMC POD plugin generator |
| `@modelcontextprotocol/sdk` | MCP SDK |
| `openclaw` | Open Claw tool |
| `typescript-language-server` | TypeScript LSP |

---

## 5. Python Packages

| Package | Version | Purpose |
|---|---|---|
| `lxml` | 6.0.2 | XML/HTML processing |
| `pillow` | 12.2.0 | Image processing |
| `python-pptx` | 1.0.2 | PowerPoint file manipulation |
| `xlsxwriter` | 3.2.9 | Excel file generation |
| `typing_extensions` | 4.15.0 | Python typing backports |

---

## 6. Top 10 Productivity Tools — Installed

All installed on **April 17, 2026** via Homebrew.

| # | Tool | Replaces | Install Command |
|---|---|---|---|
| 1 | **Raycast** | Spotlight + Maccy + Rectangle | `brew install --cask raycast` |
| 2 | **Warp** | iTerm2 | `brew install --cask warp` |
| 3 | **TablePlus** | pgAdmin / raw psql | `brew install --cask tableplus` |
| 4 | **Proxyman** | Charles Proxy / nothing | `brew install --cask proxyman` |
| 5 | **Lens** | raw kubectl | `brew install --cask lens` |
| 6 | **k9s** | raw kubectl (TUI) | `brew install k9s` |
| 7 | **atuin** | fzf history / Ctrl+R | `brew install atuin` |
| 8 | **IINA** | VLC | `brew install --cask iina` |
| 9 | **AppCleaner** | Nothing | `brew install --cask appcleaner` |
| 10 | **Stats** | Macs Fan Control | `brew install --cask stats` |

---

## 7. Quick Setup for Each New Tool

### Raycast
- Press `⌘ Space` to launch (replaces Spotlight)
- Settings → set as default Spotlight replacement
- Install extensions from the Raycast Store:
  - **Window Management** → replace Rectangle
  - **Clipboard History** → replace Maccy
  - **GitHub** → search repos, PRs, issues
  - **brew** → manage Homebrew from Raycast
  - **Docker** → manage containers
  - **Color Picker**, **Unit Converter**, **Calculator** — all built-in

### Warp
- Open from `/Applications/Warp.app`
- Sign in with free account
- Auto-detects your zsh + powerlevel10k config
- Type `#` followed by natural language to get command suggestions
- Block-based output — click any output block to copy cleanly
- Built-in workflows: `Ctrl+Shift+R` to search saved commands

### TablePlus
- Open → **New Connection** → select **PostgreSQL**
- Host: `localhost`, Port: `5432`, Database: your DB name
- Works with PostgreSQL 16 you already have installed
- Supports PostgreSQL, MySQL, SQLite, Redis, MongoDB, and more

### Proxyman
- Open → **Certificate** → **Install Certificate on this Mac**
- Open **Keychain Access** → find Proxyman certificate → Trust → Always Trust
- All HTTP/HTTPS traffic from your Mac is now interceptable
- Great for debugging SAP API calls, REST endpoints, frontend requests
- Also has iOS/Android device proxying via WiFi

### Lens
- Open `/Applications/Lens.app`
- Auto-discovers your `~/.kube/config`
- All clusters appear in the left sidebar immediately
- Click any cluster → browse Pods, Deployments, Services, ConfigMaps
- Built-in terminal, log viewer, port-forward UI

### k9s (Terminal)
```bash
k9s                    # Open in default namespace
k9s -n my-namespace    # Open in specific namespace
k9s --context my-ctx   # Open with specific kubeconfig context
```
**Key bindings inside k9s:**
- `?` — show all keyboard shortcuts
- `:pod` — navigate to pods view
- `:deploy` — deployments
- `:svc` — services
- `l` — view logs for selected pod
- `s` — shell into selected pod
- `d` — describe resource
- `/` — filter/search
- `Ctrl+D` — delete resource

### atuin (Shell History)
Activate in your shell first:
```bash
echo 'eval "$(atuin init zsh)"' >> ~/.zshrc
source ~/.zshrc
```
**Usage:**
- `Ctrl+R` — opens beautiful searchable history UI (replaces default history search)
- Searches full command text, not just prefix
- Shows timestamp, directory, exit code for every command
- Optional: `atuin login` to sync history across machines

### IINA (Video Player)
- Set as default for video files:
  - Right-click any video file → **Get Info** → **Open With** → IINA → **Change All**
- Supports every format VLC does but with native macOS UI
- Picture-in-picture, AirPlay, Touch Bar, subtitle support built-in
- CLI: `iina /path/to/video.mp4`

### AppCleaner
- Drag any `.app` onto AppCleaner window to find all leftover files
- Shows exactly what will be deleted (preferences, caches, support files)
- Click **Remove** to cleanly uninstall everything
- Or: Open AppCleaner → search app name
- Enable **SmartDelete** in preferences to automatically intercept app deletions from Finder

### Stats (Menu Bar)
- Launch `/Applications/Stats.app`
- Right-click the menu bar icons to configure each module:
  - **CPU** — usage graph or percentage
  - **GPU** — utilisation (great for ML/AI work)
  - **RAM** — memory pressure
  - **Disk** — read/write speeds
  - **Network** — upload/download speeds
  - **Battery** — detailed battery health
- Replaces both **Macs Fan Control** and **Power Monitor** for most use cases

---

## 8. Full Recommendations List

Additional tools recommended but not yet installed, grouped by category:

### Terminal Enhancements
```bash
brew install starship    # Cross-shell prompt (faster alternative to powerlevel10k)
brew install mise        # Universal version manager — replaces pyenv + nvm + rbenv
brew install carapace    # Shell completions for 1000+ commands
brew install atuin       # ✅ Already installed
```

### Developer Tools
```bash
brew install xh                    # httpie in Rust — faster HTTP client
brew install fx                    # Interactive JSON viewer (pairs with jq)
brew install yq                    # Like jq but for YAML
brew install watchman              # File change watcher
brew install git-lfs               # Git Large File Storage
brew install dive                  # Explore Docker image layers
brew install --cask insomnia       # REST + GraphQL API client (alternative to Bruno)
brew install --cask proxyman       # ✅ Already installed
brew install --cask tableplus      # ✅ Already installed
```

### Kubernetes / Cloud
```bash
brew install k9s                   # ✅ Already installed
brew install --cask lens           # ✅ Already installed
brew install helm                  # Kubernetes package manager
brew install kubectx               # Switch between kubectl contexts quickly
```

### AI / LLM
```bash
brew install aider                 # AI pair programmer in terminal (Claude/GPT)
brew install --cask chatbox        # Desktop app for Claude/GPT/Ollama
```

### macOS Productivity
```bash
brew install --cask aerospace      # i3-style tiling window manager (more powerful than Rectangle)
brew install --cask bartender      # Better menu bar organizer than Hidden Bar
brew install --cask pasta          # Upgraded clipboard manager (alternative to Maccy/Raycast)
brew install --cask notion         # Richer notes/wiki (alternative/complement to Obsidian)
brew install --cask cleanshot-x    # Best screenshot tool on Mac (alternative to Snagit)
```

### Utilities
```bash
brew install --cask keka           # Best archive tool (zip/7z/rar)
brew install --cask handbrake      # Video transcoding
brew install --cask imageoptim     # Batch image compression
brew install --cask appcleaner     # ✅ Already installed
brew install --cask iina           # ✅ Already installed
brew install --cask stats          # ✅ Already installed
```

---

## Install Everything at Once

To reinstall all newly added tools on a fresh machine:

```bash
# Casks (GUI apps)
brew install --cask raycast warp tableplus proxyman lens iina appcleaner stats

# Formulae (CLI tools)
brew install k9s atuin
```

To activate atuin after install:
```bash
echo 'eval "$(atuin init zsh)"' >> ~/.zshrc && source ~/.zshrc
```

---

*Related files:*
- `Setup-RetroGamingMachine.ps1` — Windows retro gaming automation script
- `RetroGaming-Setup-Guide.md` — Complete retro gaming reference guide
