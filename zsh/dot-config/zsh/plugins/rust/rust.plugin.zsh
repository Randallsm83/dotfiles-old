# Generate rustup, cargo and rustc completions

# Check and handle `rustup`
if (( $+commands[rustup] )); then
  if [[ ! -f "$ZSH_CACHE_DIR/completions/_rustup" ]]; then
    autoload -Uz _rustup
    typeset -g -A _comps
    _comps[rustup]=_rustup
  fi
  rustup completions zsh >| "$ZSH_CACHE_DIR/completions/_rustup" &
fi

# Check and handle `cargo`
if (( $+commands[cargo] )); then
  if [[ ! -f "$ZSH_CACHE_DIR/completions/_cargo" ]]; then
    autoload -Uz _cargo
    typeset -g -A _comps
    _comps[cargo]=_cargo
  fi
  cat >| "$ZSH_CACHE_DIR/completions/_cargo" <<'EOF' &
#compdef cargo
source "$(rustc +${${(z)$(rustup default)}[1]} --print sysroot)"/share/zsh/site-functions/_cargo
EOF
fi

# Check and handle `rustc`
if (( $+commands[rustc] )); then
  if [[ ! -f "$ZSH_CACHE_DIR/completions/_rustc" ]]; then
    autoload -Uz _rustc
    typeset -g -A _comps
    _comps[rustc]=_rustc
  fi
  cat ./_rustc >| "$ZSH_CACHE_DIR/completions/_rustc" &
fi
