# Session log — 2026-06-07

**Outcome:** repo reached **67 OK / 0 DRIFT / 0 MISSING** on the work Mac for the first time. Refactored the config-as-data layer, added cloud-sync safety, made screenshot location auto-detect OneDrive.

## Commits this session

| SHA | Type | Summary |
|---|---|---|
| `3d6ae26` | feat(validate) | `validate.sh` drift detector — shadows `defaults`/`killall`/`PlistBuddy` while sourcing each `*-defaults.sh`, captures EXPECTED, reads live, diffs |
| `0746a3f` | refactor(scripts) | Replaced inline `if/else` blocks with `apply_*` helpers across 5 scripts |
| `94bec49` | feat(screenshot) | OneDrive auto-detection, fall back to `~/Pictures/Screenshots` |
| `291319e` | feat(safety) | `assert_cloud_safe` — refuse git/symlink/root cloud paths |

Net: 5 files changed, 130 lines deleted, 98 added on the refactor pass alone. Plus 88 lines of safety code + tests.

## What changed in `lib/common.sh`

New helpers (added to the public API):

```text
apply_bool_inverted   VAR DOMAIN KEY    write -bool with VALUE INVERTED
                                        (DISABLE_X=true → KeyEnabled=false)
apply_bool_currenthost  VAR DOMAIN KEY  write -bool to -currentHost scope
apply_int_currenthost   VAR DOMAIN KEY  write -int  to -currentHost scope
assert_cloud_safe       <path>          validate path is safe to write into
                                        cloud-sync. Returns 0 safe / 1 unsafe.
```

Internal: unified `_apply` now handles type + scope + invert in one place. Five wrappers above it.

## Why the refactor mattered

**Bug surfaced by `validate.sh`:** keyboard-defaults.sh was writing `ApplePressAndHoldEnabled` *twice* — once with the un-inverted value (line 63), once correctly via inline if/else (lines 66-70). The duplicate write was hidden because the second won, but the EXPECTED table in validate.sh listed the same key with conflicting expected values. Refactor naturally collapsed it to one correct call.

**Hidden side benefit:** humanize rule (smart-quotes, dashes, auto-cap, period sub, autocorrect, automatic-spelling all OFF) finally applied to live system. The keys had been in the script for weeks but slipped past on prior runs because of the `_invert_bool` local helper that was missing safe-skip semantics.

## Cloud-sync safety: what `assert_cloud_safe` rejects

The helper walks from the target path up to the cloud root and refuses on any of:

1. **Symlink** anywhere in the path. OneDrive ignores them, Dropbox follows them and uploads the target, iCloud refuses to sync them.
2. **`.git` ancestor** anywhere up the tree. Git's atomic-rename + lockfiles + cloud sync = corrupt `.git/index`, lost commits, "(Naren's MacBook conflicted copy 2026-06-07)" turds.
3. **The cloud root itself.** Some MDMs make it read-only; the sync client reserves it for status files.
4. **Local paths skip silently** — the helper is no-op for anything not under a known cloud-sync root.

Tested live against 5 scenarios (local pass, subfolder pass, root reject, symlink reject, git-ancestor reject). All correct.

## Detection probes used

| Where | Probe | Notes |
|---|---|---|
| OneDrive present? | `ls -d "$HOME"/Library/CloudStorage/OneDrive-* 2>/dev/null \| head -1` | Matches OneDrive-SAPSE, OneDrive-Personal, etc. |
| Cloud-sync root inference | Pattern-match prefix in `assert_cloud_safe` | OneDrive / Dropbox / iCloud / legacy `~/OneDrive` |
| Git anywhere up the tree | Walk parents, test `-e $probe/.git` | Catches both repo dir and worktree marker file |

## Validate.sh journey

```text
26 OK / 16 DRIFT / 27 MISSING   (start of session)
51 OK /  9 DRIFT /  7 MISSING   (after refactor + humanize finally applied)
51 OK /  9 DRIFT /  7 MISSING   (after OneDrive auto-detect — drift just shifted)
67 OK /  0 DRIFT /  0 MISSING   (after dock-defaults.sh applied — first clean state)
```

## bash 3.2 patterns used (preserve when extending)

macOS system bash is 3.2. Under `set -u`:

- Empty array expansion: `${arr[@]+"${arr[@]}"}` (NOT `"${arr[@]}"`)
- Case fold: `printf "%s" "$1" | tr '[:upper:]' '[:lower:]'` (NOT `${var,,}`)
- No `declare -A`; dedupe via `printf "%s\n" "${arr[@]:-}" | sort -u`
- Variable presence: `[ -n "${VAR+x}" ]` (set, even if empty), NOT `[ -n "${VAR}" ]`

## Skills updated this session

- **`mac-setup-sync`** — added section on data-driven path resolution, milestone log entry, cloud-sync hazard pitfall pointing at sister skill.
- **`phoenix-data-driven-paths`** (new) — three-tier resolution recipe (override → detect → fallback), detection probe table, anchored example from `screenshot-defaults.sh`, cloud-sync hazards section, `assert_cloud_safe` usage pattern, idempotence rules, anti-patterns, checklist.

Both skills live in `~/.hermes/skills/macos/` (agent-side, not in this repo). Reference them by name when you want the agent to load them.

## How to run a single script on someone else's Mac

```bash
git clone https://github.com/narendra-babu-m/mac-setup-guide.git /tmp/mac-setup-guide
bash /tmp/mac-setup-guide/scripts/finder-defaults.sh
find /tmp/mac-setup-guide -depth -mindepth 0 -delete
```

Three lines. No persistent state on their Mac. They can read CONFIG before running. (Considered: `bash <(curl ...)` one-liner — fails because the script does `source "$(dirname "$0")/lib/common.sh"` and `$0` resolves to a process-substitution path. Would need a `run-remote.sh` shim. Not built this session.)

## Open / not done

- `run-remote.sh` shim for the `bash <(curl ...)` workflow (mentioned, deferred).
- Long-domain alignment in validate.sh table output (cosmetic, mentioned earlier).
- Activity Monitor + more NSGlobalDomain misc could be added — same pattern.

## Critical context for next session

- Repo state at session close: `main @ 291319e`, clean, in sync with origin.
- No `.DS_Store` to commit; ignored as macOS noise.
- Hooks in play: ECC `commit_quality` (72-char subject limit, conventional commits), `gateguard` (challenges `rm -rf` + non-trivial edits).
- Memory entry untouched — existing trigger ("after any brew/cask/System-Settings change → load skill mac-setup-sync") still valid.
