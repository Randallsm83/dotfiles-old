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