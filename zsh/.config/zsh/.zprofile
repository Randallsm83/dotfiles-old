#!/bin/zsh

export PATH="$LOCALDIR/bin:$HOME/bin:$HOME/projects/ndn/dh/bin:$HOME/perl5/bin:$HOME/.cargo/bin:$PATH"
export LD_LIBRARY_PATH="$LOCALDIR/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="$LOCALDIR/lib/pkgconfig:$LOCALDIR/share/pkgconfig:$PKG_CONFIG_PATH"

if [ "$(uname)" = "Darwin" ]; then
  export BREWDIR="/opt/homebrew/opt"
  export PATH="$BREWDIR/curl/bin:$PATH"
  export PATH="$BREWDIR/ncurses/bin:$PATH"
  export PATH="$BREWDIR/make/libexec/gnubin:$PATH"
  export PATH="$BREWDIR/grep/libexec/gnubin:$PATH"
  export PATH="$BREWDIR/gnu-sed/libexec/gnubin:$PATH"
  export PATH="$BREWDIR/gnu-tar/libexec/gnubin:$PATH"
  export PATH="$BREWDIR/coreutils/libexec/gnubin:$PATH"
  export PATH="$BREWDIR/findutils/libexec/gnubin:$PATH"
  export LD_LIBRARY_PATH="$BREWDIR/curl/lib:$LD_LIBRARY_PATH"
  export LD_LIBRARY_PATH="$BREWDIR/ncurses/lib:$LD_LIBRARY_PATH"
  export LD_LIBRARY_PATH="$BREWDIR/readline/lib:$LD_LIBRARY_PATH"
  export PKG_CONFIG_PATH="$BREWDIR/curl/lib/pkgconfig:$PKG_CONFIG_PATH"
  export PKG_CONFIG_PATH="$BREWDIR/ncurses/lib/pkgconfig:$PKG_CONFIG_PATH"
  export PKG_CONFIG_PATH="$BREWDIR/readline/lib/pkgconfig:$PKG_CONFIG_PATH"

  eval $(/opt/homebrew/bin/brew shellenv)
  [[ -f ~/.config/homebrew/brewenv.sh ]] && source ~/.config/homebrew/brewenv.sh
fi

# -------------------------------------------------------------------------------------------------
# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et
# -------------------------------------------------------------------------------------------------
