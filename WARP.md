# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

---

Title: Project Rules — dotfiles

1) Scope and precedence
- These rules apply to this repository. If subdirectory rules are added later, subdirectory WARP.md overrides the root WARP.md. When multiple rules conflict, later rules take precedence over earlier ones. Project rules override personal/global rules when both apply.

2) Supported platforms and shells
- Primary target: WSL2 Ubuntu on Windows. Also support native Linux and macOS.
- Excluded: Git Bash/MSYS2/Cygwin.
- Shells: PowerShell (pwsh) on Windows, zsh/bash in WSL. Provide PowerShell guidance where relevant, but not exclusively.

3) Package managers and installs
- Windows: prefer winget; scoop/chocolatey acceptable when needed. Keep installs idempotent, non-interactive when possible.
- macOS: use Homebrew.
- Linux/WSL: prefer the system package manager for prerequisites; respect XDG locations.
- Avoid sudo unless explicitly required and called out; explain side effects before running.

4) Symlinks and GNU Stow policy
- Manage dotfiles with GNU Stow into $HOME using XDG-style layouts (dot-config/, dot-local/, etc.).
- On Windows, enabling Developer Mode for symlinks is acceptable when needed.
- Conflict handling should follow the repo's scripted approach: first detect regular-file conflicts (stow -nv), then adopt with --adopt only when explicitly approved. Prefer safe, reviewable operations.

5) Bootstrap flow (installer and behavior)
- Preferred bootstrap: the README one-liner invokes install.sh.
- install.sh behavior (summary):
  - Creates XDG directory structure and logs to ~/.local/state/build/dotfiles/logs.
  - Clones/pulls the dotfiles repo to ~/.config/dotfiles.
  - Sources environment files from ~/.config/env.d and package-specific env.conf files if present.
  - Ensures build tools. On Linux it verifies dev headers (glibc) and expects required CLI tools; on macOS it can install via Homebrew.
  - Builds and installs GNU Stow to ~/.local if not present.
  - Runs stow across each top-level package, handling conflicts as above.
  - Installs asdf, adds plugins from ~/.config/asdf/tool-versions, and runs asdf install.

6) XDG Base Directory compliance
- Place configs under XDG paths (XDG_CONFIG_HOME, XDG_DATA_HOME, XDG_STATE_HOME, XDG_CACHE_HOME). Prefer these locations in commands and examples.

7) Managed tools and configs
- This repo manages configs and/or bootstrap for: neovim, wezterm, starship, git, bat, ripgrep, fzf, npm/node, fonts, and (optionally) Windows Terminal and VS Code settings. Prefer practical, minimal steps that keep these in XDG paths when supported.

8) Git configuration
- Prefer conditional includes for Windows-specific options. Keep cross-platform settings sane (e.g., symlinks-friendly where applicable). Favor LF line endings in repo unless a file type needs otherwise; consider enforcing via .gitattributes if needed.

9) WezTerm defaults (reference for agent outputs)
- Default theme: "Gruvbox Material (Gogh)". Prefer Nerd Fonts fallback stack (Hack, Fira Code, Symbols Nerd Font, Noto Color Emoji). Agents should avoid overriding these in examples unless requested.

10) Agent response guidelines (terminal tasks)
- Provide commands for the appropriate shell and platform (pwsh on Windows, bash/zsh on WSL/Linux/macOS). Avoid Git Bash/MSYS2/Cygwin.
- Use absolute paths or environment-variable-anchored paths; avoid implicit cd when possible.
- Avoid interactive/fullscreen commands. Prefer non-paginated output and --no-pager for Git.
- Favor idempotent steps; explain destructive actions and obtain confirmation.
- Use HTTPS for downloads; verify sources; avoid executing untrusted scripts without review.

11) Privacy and secrets
- Do not log, echo, or commit secrets/tokens. Prefer environment variables or OS keychains.

12) Rule conflicts
- If conflicts arise, prefer rules closest to the work area (future subdirectory rules) over root, and prefer later statements in this document over earlier ones.

Post-change note
- Placing this WARP.md in the repo root is sufficient for assistants to apply these rules automatically when operating within this project.

---

## Repository-Specific Commands and Architecture

### Bootstrap Commands

**Recommended bootstrap from repo root:**

Linux/WSL:
```bash
bash -lc ". ./install.sh; main"
```

macOS:
```bash
bash -lc ". ./install.sh; main"
```

**Notes:**
- install.sh defines functions and runs main() at the end automatically
- For manual step-by-step: source install.sh, then call functions in sequence: `ensure_build_tools`, `install_stow`, `stow_dotfiles`
- Logs written to `$XDG_STATE_HOME/build/dotfiles/logs` with timestamped filenames
- Stow installs to `$HOME/.local/bin/stow` and is invoked explicitly by path inside the script

### GNU Stow Operations

**Preview changes without modifying files:**
```bash
~/.local/bin/stow -nv PACKAGE_NAME
```

**Adopt existing files into repo (when conflicts are regular files):**
```bash
~/.local/bin/stow --adopt PACKAGE_NAME
git status && git diff  # Review before committing
```

**Restow a single package:**
```bash
~/.local/bin/stow -R PACKAGE_NAME
```

**Restow all packages from repo root:**
```bash
for d in */; do [ -d "$d" ] && ~/.local/bin/stow -R "${d%/}"; done
```

**Unstow a package:**
```bash
~/.local/bin/stow -D PACKAGE_NAME
```

### ASDF Version Manager

**Initialize ASDF for current shell:**
```bash
. "$XDG_DATA_HOME/asdf/asdf.sh"
```

**Install all tools from tool-versions:**
```bash
asdf install
```

**Add plugin and set version:**
```bash
asdf plugin add PLUGIN_NAME
echo "PLUGIN_NAME VERSION" >> "$XDG_CONFIG_HOME/asdf/tool-versions"
asdf install
```

### Utility Scripts

**SSH Key Manager:**
```bash
source ~/.local/bin/ssh-key-manager.sh
setup_ssh_keys        # Generate and configure SSH keys
rotate_keys           # Rotate existing keys
display_public_keys   # Show public keys for remote services
```

**Cache Cleaner (Windows only):**
```powershell
~\.local\utilities\UtilCacheClean.ps1
```

**GCC Symlink Updater (macOS/Linux):**
```bash
~/.local/bin/relink_gcc.sh  # Updates gcc/g++ symlinks to latest Homebrew version
```

### Architecture Overview

**Repository Structure:**
- Each top-level directory (e.g., `nvim/`, `wezterm/`, `starship/`) is a GNU Stow package
- Packages use naming convention: `PACKAGE/dot-config/APP/` → `~/.config/APP/`
- `stow_dotfiles` function loops through packages, previews conflicts, optionally adopts regular files, then restows

**Bootstrap Pipeline:**
1. `ensure_build_tools`: Verifies/installs build dependencies
   - macOS: Checks Xcode CLI Tools, installs missing tools via Homebrew
   - Linux: Validates gcc, cpp, ldd, make, automake, perl, curl; extracts glibc headers via dpkg-deb
2. `install_stow`: Builds GNU Stow from source into `$HOME/.local` with XDG-aware paths
3. `clone_dotfiles`: Ensures repo exists at `$XDG_CONFIG_HOME/dotfiles` and pulls latest
4. `stow_dotfiles`: Symlinks all packages into `$HOME`

**Key Paths:**
- Repo location: `$XDG_CONFIG_HOME/dotfiles` (typically `~/.config/dotfiles`)
- Build cache: `$XDG_CACHE_HOME/build/dotfiles` (typically `~/.cache/build/dotfiles`)
- Logs: `$XDG_STATE_HOME/build/dotfiles/logs` (typically `~/.local/state/build/dotfiles/logs`)
- Stow binary: `$HOME/.local/bin/stow`
- ASDF: `$XDG_DATA_HOME/asdf` (typically `~/.local/share/asdf`)

### Platform-Specific Notes

**macOS:**
- Requires Xcode Command Line Tools or equivalent
- Script automatically installs missing build tools via Homebrew
- Use `relink_gcc.sh` after Homebrew gcc updates to fix symlinks

**Linux/WSL:**
- Requires: gcc, cpp, ldd, make, automake, perl, curl (install via distro package manager if missing)
- `check_glibc_headers` downloads and extracts glibc dev headers using dpkg-deb
- Update glibc URL in install.sh if your distro version differs from Ubuntu 24.04

**Windows:**
- Run bootstrap inside WSL2 (Ubuntu) for proper POSIX symlink behavior
- Use WezTerm or Windows Terminal for best experience
- If managing dotfiles directly on Windows filesystem, enable Developer Mode for symlink creation without admin rights
- Windows-specific PowerShell utilities in the `utilities` package stow to `~/.local/utilities/`

### Managed Configurations

This repository provides configurations for:
- **Editors:** neovim
- **Terminal:** wezterm (with Gruvbox Material theme)
- **Shell:** starship prompt, bash/zsh integration
- **Tools:** git, bat, ripgrep, fzf
- **Languages:** npm/node/typescript, perl, rust
- **Fonts:** Nerd Fonts (Hack, Fira Code)
- **Optional:** Windows Terminal settings, VS Code settings

All configurations follow XDG Base Directory specification where supported.
