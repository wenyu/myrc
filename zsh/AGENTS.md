# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Personal zsh configuration repo (`~/.myrc/zsh`). The `setup.sh` installer symlinks these files into `$HOME` as the standard zsh startup files (`.zshenv`, `.zprofile`, `.zshrc`, `.zlogin`, `.zlogout`).

## File Loading Order

Zsh sources files in this order on login shell startup:

1. `01_zshenv` — runs for every zsh invocation (env vars, PATH, Homebrew/Nix init)
2. `02_zprofile` — login shells only (currently empty)
3. `03_zshrc` — interactive shells (plugins, prompt, aliases, functions)
4. `04_zlogin` — post-`.zshrc` login hook (conda alias)
5. `99_zlogout` — cleanup on logout (currently empty)

## Vendored Plugins (git submodules)

- `autocomplete/` — [zsh-autocomplete](https://github.com/marlonrichert/zsh-autocomplete) (only loaded on macOS)
- `highlighting/` — [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)

Update with `git submodule update --remote`.

## Platform Logic

`01_zshenv` sets `_SYSTEM` (Darwin/Linux) and `_ARCH` (arm64/x86_64). Key platform branches:

- **macOS Apple Silicon**: Homebrew at `/opt/homebrew`
- **macOS Intel**: Homebrew at `/usr/local`
- **macOS under Rosetta 2**: detected when `_CPU == Apple` but `_ARCH == x86_64`; prompt shows "Rosetta2" indicator
- **Linux**: skips `compinit`, uses GNU `ls --color`
- **Nix**: profile scripts and completions sourced if `$NIX_PROFILES` is set

Autocomplete plugin is only loaded on macOS (`03_zshrc:19`).

## Setup

```sh
# Fresh install (appends source lines to ~/.zshenv etc.)
./setup.sh

# Reset existing configs first (backs up, then removes before appending)
./setup.sh -r
```

`setup.sh` backs up existing zsh dotfiles to `~/.zsh_backup.<timestamp>/` before modifying them.

## Key Custom Functions and Aliases

Defined in `03_zshrc`:
- `cleanall` — recursively deletes editor temp files, `.DS_Store`, `._*` from cwd
- `tbgs <pattern>` — recursive case-insensitive grep, skipping temp files
- `force_kill <name>` — kills all processes matching name (uses sudo)
- `cdroot`/`repo_root` — navigate to nearest Bazel `WORKSPACE` root (only when `bazel` is installed)
- `cdatv` — conda deactivate/reactivate shortcut (`04_zlogin`)

## Submodule Policy

`autocomplete/` and `highlighting/` are vendored git submodules — not our code. Never commit changes directly into submodule directories. When fixing bugs in a submodule, create a `.patch` file under `zsh/` named `<submodule>-<description>.patch` (e.g., `autocomplete-fd-leak-fix.patch`). The prefix before the first `-` must match the submodule directory name — `setup.sh` uses this convention to auto-apply patches.

**Important**: Patches are NOT persisted across `git submodule update`. `setup.sh` applies them automatically during initial setup. To re-apply manually: `cd <submodule> && git apply ../<patch-file>`.

## Known Issues and Fixes

### Autocomplete fd Leak (`autocomplete-fd-leak-fix.patch`)

The upstream `zsh-autocomplete` plugin has an fd leak in `.autocomplete__async`. Root causes:
- Variable name mismatch: the `clear` function checks `_autocomplete__async_fd` (double underscore) but the variable is actually named `_autocomplete_async_fd` (single underscore), so the cleanup branch never executes.
- The `-t $fd` test (is fd a terminal?) fails for process-substitution fds, silently skipping `exec {fd}<&-`.
- Missing `zle -F` unhook before closing the fd.

Symptom: after many cd/command cycles, fds exhaust and other plugins (e.g., zsh-syntax-highlighting) fail with `cannot duplicate fd 1: too many open files`.

**Critical `exec` pattern**: When suppressing errors on fd close, ALWAYS use `{ exec {fd}<&- } 2>/dev/null` (with braces). Never use `exec {fd}<&- 2>/dev/null` — because `exec` without a command applies ALL its redirections to the current shell permanently, so the `2>/dev/null` would permanently redirect stderr to `/dev/null` for the entire session.

### chpwd-recent-dirs Missing Directory

`chpwd_recent_filehandler` (zsh built-in for tracking recent directories) expects `$XDG_DATA_HOME/zsh/` to exist. If it doesn't, you get: `chpwd_recent_filehandler:29: no such file or directory: ...chpwd-recent-dirs`. Fixed by creating the directory in `03_zshrc` at startup.

## Debugging Guidance

### "too many open files" errors

These are almost always fd leaks in the autocomplete async machinery, not in the plugin that reports the error. The reporting plugin (typically zsh-syntax-highlighting) is the victim — it fails when trying routine fd operations because the system limit is exhausted. Check `autocomplete/Functions/Init/.autocomplete__async` first.

### Errors referencing missing XDG directories

Zsh built-in features (completion cache, `chpwd_recent_filehandler`, etc.) assume `$XDG_DATA_HOME/zsh/` exists. If a zsh built-in complains about a missing file under `~/.local/share/zsh/`, the fix belongs in `03_zshrc` as a `mkdir -p` guard — not as an external one-off fix.

### General approach

- When a plugin reports an error, check whether it's the cause or the symptom — fd/resource exhaustion from one plugin often surfaces as failures in another.
- Always verify submodule patches are actually applied (`git -C <submodule> diff`), not just that the `.patch` file exists.
- Fixes to the user's environment (directory creation, env vars) should be self-healing in the startup files, not manual one-time actions.
