#!/usr/bin/env zsh
# eza integration with layered config support

[[ $TERM == 'dumb' ]] && return 1

# Ensure LS_COLORS is loaded from vivid if generated
: ${XDG_CONFIG_HOME:=${HOME}/.config}
if [ -z "$LS_COLORS" ] && [ -f "$XDG_CONFIG_HOME/lscolors/${VIVID_THEME:-one-dark}.txt" ]; then
  export LS_COLORS="$(< "$XDG_CONFIG_HOME/lscolors/${VIVID_THEME:-one-dark}.txt")"
fi

_has() { command -v "$1" >/dev/null 2>&1; }

_eza_flags_file() {
  local base="$XDG_CONFIG_HOME/eza"
  for f in "flags.${HOST}.txt" "flags.zsh.txt" "flags.local.txt" "flags.txt"; do
    [ -f "$base/$f" ] && { printf '%s' "$base/$f"; return; }
  done
  printf '%s' "$base/flags.txt"
}

# Build flags array once at startup
_eza_flags=()
if _has eza; then
  local f="$(_eza_flags_file)"
  # Read flags file, filter comments and empty lines
  if [ -f "$f" ]; then
    while IFS= read -r line; do
      [[ "$line" =~ ^[[:space:]]*# ]] && continue  # Skip comments
      [[ -z "${line// }" ]] && continue             # Skip empty lines
      _eza_flags+=("$line")
    done < "$f"
  fi
  
  # Remove --group-directories-first if disabled
  [ -n "$EZA_DISABLE_GDF" ] && _eza_flags=(${_eza_flags:#--group-directories-first})
  
  # Add extra flags if specified
  [ -n "$EZA_FLAGS_EXTRA" ] && _eza_flags+=(${=EZA_FLAGS_EXTRA})
  
  # Define aliases using the array
  ls() { command eza $_eza_flags "$@"; }
  ll() { command eza $_eza_flags -l "$@"; }
  la() { command eza $_eza_flags -la "$@"; }
  lt() { command eza $_eza_flags --tree "$@"; }
else
  print "eza not found. Install with mise: mise use -g cargo:eza" >&2
  return 1
fi

return 0

# -------------------------------------------------------------------------------------------------
# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et
#
