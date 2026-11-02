# Powerlevel10k — best-of-breed config tuned for Naren's macOS dev workstation.
# Backup of previous config: ~/.p10k.zsh.backup-*
# To re-customize interactively at any time: p10k configure

'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases'         ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'

() {
  emulate -L zsh -o extended_glob

  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'

  # ===========================================================================
  # SEGMENTS — left and right prompt
  # ===========================================================================
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    os_icon                 # macOS apple
    context                 # user@host (only shown over SSH or as root — see below)
    dir                     # current directory
    vcs                     # git status with full detail (ahead/behind/stash/conflicts)
    newline                 # split prompt onto two lines
    prompt_char             # ❯ (green ok / red error / yellow vicmd)
  )

  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    status                  # exit code of last command (errors only)
    command_execution_time  # >3s commands surfaced
    background_jobs         # & jobs count
    direnv                  # direnv loaded
    asdf                    # asdf-managed tool versions (no-op if not installed)
    virtualenv              # python venv
    anaconda                # conda env
    pyenv                   # pyenv shell version (when not the system default)
    nodenv                  # nodenv version
    nodeversion             # node version (project-aware)
    nvm                     # nvm version (project-aware)
    kubecontext             # k8s context — only when kubectl in cwd recently
    aws                     # aws profile
    gcloud                  # gcloud config
    google_app_cred         # GOOGLE_APPLICATION_CREDENTIALS=…
    todo                    # https://github.com/todotxt/todo.txt-cli
    timewarrior             # TimeWarrior (only when active)
    taskwarrior             # TaskWarrior count
    time                    # HH:MM
    newline
    ip                      # local IP (off by default — see at bottom)
    public_ip
    proxy
    battery                 # battery on laptop (auto-hidden on AC + full)
    wifi                    # wifi rssi (off by default)
    example                 # placeholder for ad-hoc segment
  )
  # The ip/public_ip/proxy/battery/wifi/example block on the second right line
  # stays empty unless you flip the relevant POWERLEVEL9K_*_DISABLED flags
  # below. Keeping the elements registered means flipping a flag is one line.
  typeset -g POWERLEVEL9K_IP_DISABLED=true
  typeset -g POWERLEVEL9K_PUBLIC_IP_DISABLED=true
  typeset -g POWERLEVEL9K_PROXY_DISABLED=true
  typeset -g POWERLEVEL9K_BATTERY_DISABLED=false  # show battery when on battery
  typeset -g POWERLEVEL9K_WIFI_DISABLED=true
  typeset -g POWERLEVEL9K_EXAMPLE_DISABLED=true
  typeset -g POWERLEVEL9K_TODO_DISABLED=true
  typeset -g POWERLEVEL9K_TIMEWARRIOR_DISABLED=true
  typeset -g POWERLEVEL9K_TASKWARRIOR_DISABLED=true

  # ===========================================================================
  # GENERAL
  # ===========================================================================
  typeset -g POWERLEVEL9K_MODE=nerdfont-complete
  typeset -g POWERLEVEL9K_ICON_PADDING=moderate
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=false
  typeset -g POWERLEVEL9K_ICON_BEFORE_CONTENT=true
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_CHAR='·'
  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_FOREGROUND=240
  typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX='%240F╰─%f'
  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX='%240F╭─%f'
  typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX='%240F├─%f'

  # Empty line between commands — easier to scan back through tmux history.
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

  # ===========================================================================
  # SEPARATORS — clean, no powerline arrows
  # ===========================================================================
  typeset -g POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR=''
  typeset -g POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR=''
  typeset -g POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_RIGHT_SUBSEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL=''
  typeset -g POWERLEVEL9K_EMPTY_LINE_LEFT_PROMPT_FIRST_SEGMENT_END_SYMBOL=

  # ===========================================================================
  # OS ICON
  # ===========================================================================
  typeset -g POWERLEVEL9K_OS_ICON_FOREGROUND=212     # pink
  typeset -g POWERLEVEL9K_OS_ICON_BACKGROUND=

  # ===========================================================================
  # CONTEXT — user@host. Hidden locally; visible over SSH or as root.
  # ===========================================================================
  typeset -g POWERLEVEL9K_CONTEXT_DEFAULT_FOREGROUND=180
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_FOREGROUND=178
  typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE='%n@%m'
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_TEMPLATE='%B%n@%m'
  typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_{CONTENT,VISUAL_IDENTIFIER}_EXPANSION=
  typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_{CONTENT,VISUAL_IDENTIFIER}_EXPANSION='${P9K_CONTENT}'
  # Show context only over SSH or as root.
  typeset -g POWERLEVEL9K_CONTEXT_DEFAULT_VISUAL_IDENTIFIER_EXPANSION=
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_VISUAL_IDENTIFIER_EXPANSION=
  typeset -g POWERLEVEL9K_ALWAYS_SHOW_CONTEXT=false
  typeset -g POWERLEVEL9K_ALWAYS_SHOW_USER=false

  # ===========================================================================
  # DIRECTORY
  # ===========================================================================
  typeset -g POWERLEVEL9K_DIR_BACKGROUND=
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=75
  typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=103
  typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=39
  typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
  typeset -g POWERLEVEL9K_SHORTEN_DELIMITER=
  typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=80
  typeset -g POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS=40
  typeset -g POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS_PCT=50
  typeset -g POWERLEVEL9K_DIR_HOME_ICON=''
  typeset -g POWERLEVEL9K_DIR_HOME_SUBFOLDER_ICON=''
  typeset -g POWERLEVEL9K_DIR_ETC_ICON=''
  typeset -g POWERLEVEL9K_DIR_DEFAULT_ICON=''
  typeset -g POWERLEVEL9K_DIR_SHOW_WRITABLE=v3

  # Directory classes — let p10k know which dirs are "important" so the
  # truncate-to-unique strategy keeps them visible. Tuned for Naren's tree.
  typeset -g POWERLEVEL9K_DIR_CLASSES=(
    '~/Vaults/ObsidianBrain-*/(*/|)*'  VAULT     ''
    '~/Projects/SAP/(*/|)*'            SAP       ''
    '~/Projects/AI/(*/|)*'             AI        ''
    '~/Projects/MCP/(*/|)*'            MCP       ''
    '~/.hermes/(*/|)*'                 HERMES    ''
    '~/Projects/(*/|)*'                PROJECTS  ''
    '~/(*/|)*'                         HOME_SUB  ''
    '~'                                HOME      ''
    '/'                                ROOT      ''
    '*'                                DEFAULT   ''
  )
  typeset -g POWERLEVEL9K_DIR_VAULT_FOREGROUND=141     # purple — Obsidian
  typeset -g POWERLEVEL9K_DIR_VAULT_VISUAL_IDENTIFIER_EXPANSION='󱓼'  # nf-md-notebook
  typeset -g POWERLEVEL9K_DIR_SAP_FOREGROUND=39        # SAP blue
  typeset -g POWERLEVEL9K_DIR_SAP_VISUAL_IDENTIFIER_EXPANSION='󰌘'
  typeset -g POWERLEVEL9K_DIR_AI_FOREGROUND=212
  typeset -g POWERLEVEL9K_DIR_AI_VISUAL_IDENTIFIER_EXPANSION=''
  typeset -g POWERLEVEL9K_DIR_MCP_FOREGROUND=156
  typeset -g POWERLEVEL9K_DIR_MCP_VISUAL_IDENTIFIER_EXPANSION='󰒋'
  typeset -g POWERLEVEL9K_DIR_HERMES_FOREGROUND=220
  typeset -g POWERLEVEL9K_DIR_HERMES_VISUAL_IDENTIFIER_EXPANSION='⚕'
  typeset -g POWERLEVEL9K_DIR_PROJECTS_FOREGROUND=75

  # Anchor expansion — show anchors (.git, package.json, etc.) bolded so you
  # always see where the project root is in a long path.
  typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true

  # ===========================================================================
  # VCS (Git) — full detail without sacrificing speed
  # ===========================================================================
  # Use gitstatusd, the fastest git status engine on the planet (it's why p10k
  # exists). Defaults are good; just bump limits a little for big monorepos.
  typeset -g POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY=-1            # always show dirty status
  typeset -g POWERLEVEL9K_VCS_MAX_NUM_UNSTAGED=15
  typeset -g POWERLEVEL9K_VCS_MAX_NUM_STAGED=15
  typeset -g POWERLEVEL9K_VCS_MAX_NUM_UNTRACKED=15
  typeset -g POWERLEVEL9K_VCS_MAX_NUM_CONFLICTED=15

  # Stage indicators
  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON=$'\uF126 '       # 
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_ICON='?'
  typeset -g POWERLEVEL9K_VCS_UNSTAGED_ICON='!'
  typeset -g POWERLEVEL9K_VCS_STAGED_ICON='+'
  typeset -g POWERLEVEL9K_VCS_STASH_ICON='⚑ '
  typeset -g POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON='⇣'   # behind remote
  typeset -g POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON='⇡'   # ahead of remote
  typeset -g POWERLEVEL9K_VCS_TAG_ICON='󰓹 '
  typeset -g POWERLEVEL9K_VCS_COMMIT_ICON=''

  # Custom format function — shows ahead/behind, stash, conflicts, all stages.
  function my_git_formatter() {
    emulate -L zsh
    if [[ -n $P9K_CONTENT ]]; then
      typeset -g my_git_format=$P9K_CONTENT
      return
    fi
    if (( $1 )); then
      local       meta='%6F'  # gray for separators
      local      clean='%76F'  # green
      local   modified='%220F' # yellow
      local  untracked='%39F'  # blue
      local conflicted='%196F' # red
      local      stash='%208F' # orange
    else
      local       meta='%246F'
      local      clean='%246F'
      local   modified='%246F'
      local  untracked='%246F'
      local conflicted='%246F'
      local      stash='%246F'
    fi

    local res
    if [[ -n $VCS_STATUS_LOCAL_BRANCH ]]; then
      local branch=${(V)VCS_STATUS_LOCAL_BRANCH}
      # Truncate long branch names — keep first 32 chars + … if longer.
      (( ${#branch} > 32 )) && branch[28,-1]="…"
      res+="${clean}${(g::)POWERLEVEL9K_VCS_BRANCH_ICON}${branch//\%/%%}"
    elif [[ -n $VCS_STATUS_TAG ]]; then
      local tag=${(V)VCS_STATUS_TAG}
      (( ${#tag} > 32 )) && tag[28,-1]="…"
      res+="${meta}${POWERLEVEL9K_VCS_TAG_ICON}${tag//\%/%%}"
    fi
    [[ -z $VCS_STATUS_LOCAL_BRANCH && -z $VCS_STATUS_TAG ]] && res+="${meta}${POWERLEVEL9K_VCS_COMMIT_ICON}${VCS_STATUS_COMMIT[1,8]}"
    [[ -n $VCS_STATUS_REMOTE_BRANCH && $VCS_STATUS_REMOTE_BRANCH != $VCS_STATUS_LOCAL_BRANCH ]] && res+=" ${meta}:${clean}${VCS_STATUS_REMOTE_BRANCH//\%/%%}"

    # ⇣N — behind remote
    (( VCS_STATUS_COMMITS_BEHIND )) && res+=" ${clean}${POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON}${VCS_STATUS_COMMITS_BEHIND}"
    # ⇡N — ahead of remote
    (( VCS_STATUS_COMMITS_AHEAD  )) && res+=" ${clean}${POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON}${VCS_STATUS_COMMITS_AHEAD}"
    # ⇠/⇢ — push behind/ahead (different remote vs upstream)
    (( VCS_STATUS_PUSH_COMMITS_BEHIND )) && res+=" ${clean}⇠${VCS_STATUS_PUSH_COMMITS_BEHIND}"
    (( VCS_STATUS_PUSH_COMMITS_AHEAD  )) && res+=" ${clean}⇢${VCS_STATUS_PUSH_COMMITS_AHEAD}"
    # *N — stash count
    (( VCS_STATUS_STASHES        )) && res+=" ${stash}${POWERLEVEL9K_VCS_STASH_ICON}${VCS_STATUS_STASHES}"
    # ~N — merge/rebase conflicts
    (( VCS_STATUS_NUM_CONFLICTED )) && res+=" ${conflicted}~${VCS_STATUS_NUM_CONFLICTED}"
    # +N — staged
    (( VCS_STATUS_NUM_STAGED     )) && res+=" ${modified}${POWERLEVEL9K_VCS_STAGED_ICON}${VCS_STATUS_NUM_STAGED}"
    # !N — unstaged
    (( VCS_STATUS_NUM_UNSTAGED   )) && res+=" ${modified}${POWERLEVEL9K_VCS_UNSTAGED_ICON}${VCS_STATUS_NUM_UNSTAGED}"
    # ?N — untracked
    (( VCS_STATUS_NUM_UNTRACKED  )) && res+=" ${untracked}${POWERLEVEL9K_VCS_UNTRACKED_ICON}${VCS_STATUS_NUM_UNTRACKED}"
    # In-progress operation marker (rebase/merge/cherry-pick/bisect)
    [[ -n $VCS_STATUS_ACTION ]] && res+=" ${conflicted}[${VCS_STATUS_ACTION}]"

    typeset -g my_git_format=$res
  }
  functions -M my_git_formatter 2>/dev/null
  typeset -g POWERLEVEL9K_VCS_DISABLE_GITSTATUS_FORMATTING=true
  typeset -g POWERLEVEL9K_VCS_CONTENT_EXPANSION='${$((my_git_formatter(1)))+${my_git_format}}'
  typeset -g POWERLEVEL9K_VCS_LOADING_CONTENT_EXPANSION='${$((my_git_formatter(0)))+${my_git_format}}'
  typeset -g POWERLEVEL9K_VCS_BACKENDS=(git)
  typeset -g POWERLEVEL9K_VCS_FOREGROUND=
  typeset -g POWERLEVEL9K_VCS_LOADING_FOREGROUND=246

  # ===========================================================================
  # PROMPT CHAR — ❯ green ok / red error / yellow vicmd
  # ===========================================================================
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=76
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=196
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VICMD_FOREGROUND=220
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VICMD_FOREGROUND=220
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='V'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIOWR_CONTENT_EXPANSION='▶'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=true
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''

  # ===========================================================================
  # STATUS — exit code on error
  # ===========================================================================
  typeset -g POWERLEVEL9K_STATUS_EXTENDED_STATES=true
  typeset -g POWERLEVEL9K_STATUS_OK=false
  typeset -g POWERLEVEL9K_STATUS_OK_PIPE=false
  typeset -g POWERLEVEL9K_STATUS_ERROR=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=196
  typeset -g POWERLEVEL9K_STATUS_ERROR_BACKGROUND=
  typeset -g POWERLEVEL9K_STATUS_ERROR_VISUAL_IDENTIFIER_EXPANSION='✘'
  typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_FOREGROUND=196
  typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_VISUAL_IDENTIFIER_EXPANSION='✘'
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_FOREGROUND=196
  typeset -g POWERLEVEL9K_STATUS_VERBOSE_SIGNAME=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_VISUAL_IDENTIFIER_EXPANSION='✘'

  # ===========================================================================
  # COMMAND EXECUTION TIME — surface anything >3s
  # ===========================================================================
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=1
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=220
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND=
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_VISUAL_IDENTIFIER_EXPANSION='󱎫'

  # ===========================================================================
  # BACKGROUND JOBS
  # ===========================================================================
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=70
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_BACKGROUND=
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VISUAL_IDENTIFIER_EXPANSION='⚙'

  # ===========================================================================
  # DIRENV
  # ===========================================================================
  typeset -g POWERLEVEL9K_DIRENV_FOREGROUND=178
  typeset -g POWERLEVEL9K_DIRENV_BACKGROUND=
  typeset -g POWERLEVEL9K_DIRENV_VISUAL_IDENTIFIER_EXPANSION='󰒓'

  # ===========================================================================
  # ASDF
  # ===========================================================================
  typeset -g POWERLEVEL9K_ASDF_FOREGROUND=66
  typeset -g POWERLEVEL9K_ASDF_BACKGROUND=
  typeset -g POWERLEVEL9K_ASDF_SOURCES=(shell local global)
  typeset -g POWERLEVEL9K_ASDF_PROMPT_ALWAYS_SHOW=false
  typeset -g POWERLEVEL9K_ASDF_SHOW_SYSTEM=false

  # ===========================================================================
  # PYTHON
  # ===========================================================================
  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=37
  typeset -g POWERLEVEL9K_VIRTUALENV_BACKGROUND=
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=true
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_WITH_PYENV=false
  typeset -g POWERLEVEL9K_VIRTUALENV_{LEFT,RIGHT}_DELIMITER=
  typeset -g POWERLEVEL9K_VIRTUALENV_VISUAL_IDENTIFIER_EXPANSION=''

  typeset -g POWERLEVEL9K_ANACONDA_FOREGROUND=37
  typeset -g POWERLEVEL9K_ANACONDA_BACKGROUND=
  typeset -g POWERLEVEL9K_ANACONDA_SHOW_PYTHON_VERSION=true
  typeset -g POWERLEVEL9K_ANACONDA_SHOW_ON_COMMAND='python|pip|jupyter|ipython|conda|mamba'
  typeset -g POWERLEVEL9K_ANACONDA_{LEFT,RIGHT}_DELIMITER=
  typeset -g POWERLEVEL9K_ANACONDA_VISUAL_IDENTIFIER_EXPANSION='🐍'

  typeset -g POWERLEVEL9K_PYENV_FOREGROUND=37
  typeset -g POWERLEVEL9K_PYENV_BACKGROUND=
  typeset -g POWERLEVEL9K_PYENV_SOURCES=(shell local global)
  typeset -g POWERLEVEL9K_PYENV_PROMPT_ALWAYS_SHOW=false
  typeset -g POWERLEVEL9K_PYENV_SHOW_SYSTEM=false
  typeset -g POWERLEVEL9K_PYENV_VISUAL_IDENTIFIER_EXPANSION=''

  # ===========================================================================
  # NODE / NVM
  # ===========================================================================
  typeset -g POWERLEVEL9K_NODE_VERSION_FOREGROUND=70
  typeset -g POWERLEVEL9K_NODE_VERSION_BACKGROUND=
  typeset -g POWERLEVEL9K_NODE_VERSION_PROJECT_ONLY=true
  typeset -g POWERLEVEL9K_NODE_VERSION_VISUAL_IDENTIFIER_EXPANSION=''

  typeset -g POWERLEVEL9K_NVM_FOREGROUND=70
  typeset -g POWERLEVEL9K_NVM_BACKGROUND=
  typeset -g POWERLEVEL9K_NVM_PROMPT_ALWAYS_SHOW=false

  typeset -g POWERLEVEL9K_NODENV_FOREGROUND=70
  typeset -g POWERLEVEL9K_NODENV_BACKGROUND=
  typeset -g POWERLEVEL9K_NODENV_PROMPT_ALWAYS_SHOW=false

  # ===========================================================================
  # KUBECONTEXT — only when relevant; show namespace too
  # ===========================================================================
  typeset -g POWERLEVEL9K_KUBECONTEXT_DEFAULT_FOREGROUND=134
  typeset -g POWERLEVEL9K_KUBECONTEXT_BACKGROUND=
  typeset -g POWERLEVEL9K_KUBECONTEXT_SHOW_ON_COMMAND='kubectl|helm|kubens|kubectx|oc|istioctl|kogito|k9s|helmfile|flux|stern|skaffold'
  typeset -g POWERLEVEL9K_KUBECONTEXT_CLASSES=(
    '*prod*'    PROD
    '*production*' PROD
    '*staging*' STAGING
    '*stg*'     STAGING
    '*qa*'      QA
    '*dev*'     DEV
    '*'         DEFAULT
  )
  typeset -g POWERLEVEL9K_KUBECONTEXT_PROD_FOREGROUND=196
  typeset -g POWERLEVEL9K_KUBECONTEXT_STAGING_FOREGROUND=178
  typeset -g POWERLEVEL9K_KUBECONTEXT_QA_FOREGROUND=178
  typeset -g POWERLEVEL9K_KUBECONTEXT_DEV_FOREGROUND=70
  typeset -g POWERLEVEL9K_KUBECONTEXT_DEFAULT_FOREGROUND=134
  typeset -g POWERLEVEL9K_KUBECONTEXT_VISUAL_IDENTIFIER_EXPANSION='⎈'
  typeset -g POWERLEVEL9K_KUBECONTEXT_DEFAULT_CONTENT_EXPANSION=
  POWERLEVEL9K_KUBECONTEXT_DEFAULT_CONTENT_EXPANSION+='${P9K_KUBECONTEXT_CLOUD_CLUSTER:-${P9K_KUBECONTEXT_NAME//\%/%%}}'
  POWERLEVEL9K_KUBECONTEXT_DEFAULT_CONTENT_EXPANSION+='${${P9K_KUBECONTEXT_NAMESPACE:#default}:+/${P9K_KUBECONTEXT_NAMESPACE//\%/%%}}'

  # ===========================================================================
  # AWS — show profile only when relevant; mark prod red
  # ===========================================================================
  typeset -g POWERLEVEL9K_AWS_BACKGROUND=
  typeset -g POWERLEVEL9K_AWS_DEFAULT_FOREGROUND=208
  typeset -g POWERLEVEL9K_AWS_SHOW_ON_COMMAND='aws|cdk|terraform|tofu|pulumi|sam|chef|sls|serverless'
  typeset -g POWERLEVEL9K_AWS_CLASSES=(
    '*prod*'    PROD
    '*production*' PROD
    '*staging*' STAGING
    '*stg*'     STAGING
    '*'         DEFAULT
  )
  typeset -g POWERLEVEL9K_AWS_PROD_FOREGROUND=196
  typeset -g POWERLEVEL9K_AWS_STAGING_FOREGROUND=178
  typeset -g POWERLEVEL9K_AWS_DEFAULT_FOREGROUND=208
  typeset -g POWERLEVEL9K_AWS_VISUAL_IDENTIFIER_EXPANSION=''

  # AWS EB env (less noise)
  typeset -g POWERLEVEL9K_AWS_EB_ENV_DISABLED=true

  # ===========================================================================
  # GCLOUD
  # ===========================================================================
  typeset -g POWERLEVEL9K_GCLOUD_FOREGROUND=32
  typeset -g POWERLEVEL9K_GCLOUD_BACKGROUND=
  typeset -g POWERLEVEL9K_GCLOUD_SHOW_ON_COMMAND='gcloud|gcs|gsutil'
  typeset -g POWERLEVEL9K_GCLOUD_VISUAL_IDENTIFIER_EXPANSION='󱇶'

  typeset -g POWERLEVEL9K_GOOGLE_APP_CRED_FOREGROUND=32
  typeset -g POWERLEVEL9K_GOOGLE_APP_CRED_BACKGROUND=
  typeset -g POWERLEVEL9K_GOOGLE_APP_CRED_SHOW_ON_COMMAND='gcloud|gcs|gsutil'

  # ===========================================================================
  # BATTERY — laptop, only when on battery or low
  # ===========================================================================
  typeset -g POWERLEVEL9K_BATTERY_LOW_THRESHOLD=20
  typeset -g POWERLEVEL9K_BATTERY_LOW_FOREGROUND=196
  typeset -g POWERLEVEL9K_BATTERY_CHARGING_FOREGROUND=70
  typeset -g POWERLEVEL9K_BATTERY_CHARGED_FOREGROUND=70
  typeset -g POWERLEVEL9K_BATTERY_DISCONNECTED_FOREGROUND=178
  typeset -g POWERLEVEL9K_BATTERY_STAGES=('▁' '▂' '▃' '▄' '▅' '▆' '▇' '█')
  typeset -g POWERLEVEL9K_BATTERY_BACKGROUND=
  typeset -g POWERLEVEL9K_BATTERY_VERBOSE=false

  # ===========================================================================
  # TIME
  # ===========================================================================
  typeset -g POWERLEVEL9K_TIME_FOREGROUND=66
  typeset -g POWERLEVEL9K_TIME_BACKGROUND=
  typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'
  typeset -g POWERLEVEL9K_TIME_UPDATE_ON_COMMAND=false  # only changes when prompt redraws (cheap)
  typeset -g POWERLEVEL9K_TIME_VISUAL_IDENTIFIER_EXPANSION=

  # ===========================================================================
  # INSTANT PROMPT — quiet means no warnings if your zshrc misbehaves at boot
  # ===========================================================================
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

  # ===========================================================================
  # TRANSIENT PROMPT — collapse old prompts to a single line, cleaner scroll-back
  # ===========================================================================
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=always

  # ===========================================================================
  # HOT-RELOAD — let `p10k reload` and editing this file pick up changes live.
  # ===========================================================================
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=false

  # If p10k is already loaded, force a reload so changes apply now.
  (( ! $+functions[p10k] )) || p10k reload
}

(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
'builtin' 'unset' 'p10k_config_opts'
