if (( ! $+commands[bun] )); then
  return
fi

if [[ ! -f "$ZSH_CACHE_DIR/completions/_bun" ]]; then
  typeset -g -A _comps
  autoload -Uz _bun
  _comps[bun]=_bun
fi

SHELL=zsh bun completions >| "$ZSH_CACHE_DIR/completions/_bun" &|
