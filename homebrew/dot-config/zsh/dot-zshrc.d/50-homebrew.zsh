#!/usr/bin/env zsh

# This is NOT the typical brew.env mentioned in their docs, that file doesn't support shell expansion...
# This is sourced to make things work better as expected

if (( ! $+commands[brew] )); then
  if [[ -n "$BREW_LOCATION" ]]; then
    if [[ ! -x "$BREW_LOCATION" ]]; then
      echo "$BREW_LOCATION is not executable"
      return
    fi
  elif [[ -x /opt/homebrew/bin/brew ]]; then
    BREW_LOCATION="/opt/homebrew/bin/brew"
  elif [[ -x "${XDG_DATA_HOME:-$HOME/.local/share}/homebrew/bin/brew" ]]; then
    BREW_LOCATION="${XDG_DATA_HOME:-$HOME/.local/share}/homebrew/bin/brew"
  elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
    BREW_LOCATION="$HOME/.linuxbrew/bin/brew"
  else
    return
  fi

  ## All handled by shellenv
  # if [[ $(uname) == 'Darwin' ]]; then
  #   export HOMEBREW_PREFIX="/opt/homebrew"
  # else
  #   export HOMEBREW_PREFIX="${XDG_DATA_HOME:-$HOME/.local/share}/homebrew"
  # fi

  # export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
  # export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX"
  # export PATH="${HOMEBREW_PREFIX}/bin:${HOMEBREW_PREFIX}/sbin${PATH+:$PATH}"
  # export MANPATH="${HOMEBREW_PREFIX}/share/man${MANPATH+:$MANPATH}:"
  # export INFOPATH="${HOMEBREW_PREFIX}/share/info:${INFOPATH:-}"
  # fpath[1,0]="${HOMEBREW_PREFIX}/share/zsh/site-functions"

  eval "$("$BREW_LOCATION" shellenv)"
  unset BREW_LOCATION
fi

export HOMEBREW_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/homebrew"
export HOMEBREW_BUNDLE_FILE="${DOTFILES:-$HOME/.config/dotfiles}/homebrew/dot-config/homebrew/Brewfile"
export HOMEBREW_BUNDLE_USER_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/homebrew"
export HOMEBREW_LOGS="${XDG_CACHE_HOME:-$HOME/.cache}/homebrew/logs"
export HOMEBREW_TEMP="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/homebrew"

# Performance and behavior options
export HOMEBREW_COLOR=1
export HOMEBREW_EDITOR="nvim"
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_CURL_RETRIES=3
export HOMEBREW_NO_INSECURE_REDIRECT=1
export HOMEBREW_DISPLAY_INSTALL_TIMES=1
export HOMEBREW_FORCE_BREWED_CURL=1
export HOMEBREW_FORCE_BREWED_CA_CERTIFICATES=1
export HOMEBREW_MAKE_JOBS="${MACHINE_CORES:-4}"

# Custom paths
HOMEBREW_OPT="${HOMEBREW_PREFIX}/opt"

export PATH="${HOMEBREW_OPT}/bison/bin${PATH+:$PATH}"
export PATH="${HOMEBREW_OPT}/coreutils/libexec/gnubin${PATH+:$PATH}"
export PATH="${HOMEBREW_OPT}/curl/bin${PATH+:$PATH}"
export PATH="${HOMEBREW_OPT}/ed/libexec/gnubin${PATH+:$PATH}"
export PATH="${HOMEBREW_OPT}/findutils/libexec/gnubin${PATH+:$PATH}"
export PATH="${HOMEBREW_OPT}/file-formula/bin${PATH+:$PATH}"
export PATH="${HOMEBREW_OPT}/flex/bin${PATH+:$PATH}"
export PATH="${HOMEBREW_OPT}/gawk/libexec/gnubin${PATH+:$PATH}"
export PATH="${HOMEBREW_OPT}/grep/libexec/gnubin${PATH+:$PATH}"
export PATH="${HOMEBREW_OPT}/gnu-indent/libexec/gnubin${PATH+:$PATH}"
export PATH="${HOMEBREW_OPT}/gnu-getopt/bin${PATH+:$PATH}"
export PATH="${HOMEBREW_OPT}/gnu-sed/libexec/gnubin${PATH+:$PATH}"
export PATH="${HOMEBREW_OPT}/gnu-tar/libexec/gnubin${PATH+:$PATH}"
export PATH="${HOMEBREW_OPT}/gnu-which/libexec/gnubin${PATH+:$PATH}"
export PATH="${HOMEBREW_OPT}/icu4c/bin${PATH+:$PATH}"
export PATH="${HOMEBREW_OPT}/icu4c/sbin${PATH+:$PATH}"
export PATH="${HOMEBREW_OPT}/jpeg/bin${PATH+:$PATH}"
export PATH="${HOMEBREW_OPT}/krb5/bin${PATH+:$PATH}"
export PATH="${HOMEBREW_OPT}/krb5/sbin${PATH+:$PATH}"
export PATH="${HOMEBREW_OPT}/libiconv/bin${PATH+:$PATH}"
export PATH="${HOMEBREW_OPT}/libpq/bin${PATH+:$PATH}"
export PATH="${HOMEBREW_OPT}/libressl/bin${PATH+:$PATH}"
export PATH="${HOMEBREW_OPT}/libxml2/bin${PATH+:$PATH}"
export PATH="${HOMEBREW_OPT}/m4/bin${PATH+:$PATH}"
export PATH="${HOMEBREW_OPT}/make/libexec/gnubin${PATH+:$PATH}"
export PATH="${HOMEBREW_OPT}/ncurses/bin${PATH+:$PATH}"
export PATH="${HOMEBREW_OPT}/unzip/bin${PATH+:$PATH}"

COMMON_LIB_PATHS=(
  "${HOMEBREW_OPT}/bison/lib"
  "${HOMEBREW_OPT}/flex/lib"
  "${HOMEBREW_OPT}/icu4c/lib"
  "${HOMEBREW_OPT}/jpeg/lib"
  "${HOMEBREW_OPT}/krb5/lib"
  "${HOMEBREW_OPT}/libedit/lib"
  "${HOMEBREW_OPT}/libiconv/lib"
  "${HOMEBREW_OPT}/libpq/lib"
  "${HOMEBREW_OPT}/libressl/lib"
  "${HOMEBREW_OPT}/libxml2/lib"
  "${HOMEBREW_OPT}/openssl/lib"
  "${HOMEBREW_OPT}/curl/lib"
  "${HOMEBREW_OPT}/ncurses/lib"
  "${HOMEBREW_OPT}/readline/lib"
)
for lib_path in "${COMMON_LIB_PATHS[@]}"; do
  export LDFLAGS="-L$lib_path ${LDFLAGS:-}"
  export LIBRARY_PATH="$lib_path${LIBRARY_PATH+:$LIBRARY_PATH}"
  export LD_LIBRARY_PATH="$lib_path${LD_LIBRARY_PATH+:$LD_LIBRARY_PATH}"
done

# export LDFLAGS="-L${HOMEBREW_PREFIX}/lib ${LDFLAGS:-}"
# export LIBRARY_PATH="${HOMEBREW_PREFIX}/lib${LIBRARY_PATH+:$LIBRARY_PATH}"
# export LD_LIBRARY_PATH="${HOMEBREW_PREFIX}/lib${LD_LIBRARY_PATH+:$LD_LIBRARY_PATH}"

COMMON_INCLUDE_PATHS=(
  "${HOMEBREW_OPT}/flex/include"
  "${HOMEBREW_OPT}/icu4c/include"
  "${HOMEBREW_OPT}/jpeg/include"
  "${HOMEBREW_OPT}/krb5/include"
  "${HOMEBREW_OPT}/libedit/include"
  "${HOMEBREW_OPT}/libiconv/include"
  "${HOMEBREW_OPT}/libpq/include"
  "${HOMEBREW_OPT}/libressl/include"
  "${HOMEBREW_OPT}/libxml2/include"
  "${HOMEBREW_OPT}/openssl/include"
  "${HOMEBREW_OPT}/curl/include"
  "${HOMEBREW_OPT}/ncurses/include"
  "${HOMEBREW_OPT}/readline/include"
)
for include_path in "${COMMON_INCLUDE_PATHS[@]}"; do
  export CFLAGS="-I$include_path ${CFLAGS:-}"
  export CPPFLAGS="-I$include_path ${CPPFLAGS:-}"
  export CXXFLAGS="-I$include_path ${CXXFLAGS:-}"
  export C_PATH="$include_path${C_PATH+:$C_PATH}"
  export C_INCLUDE_PATH="$include_path${C_INCLUDE_PATH+:$C_INCLUDE_PATH}"
  export CPLUS_INCLUDE_PATH="$include_path${CPLUS_INCLUDE_PATH+:$CPLUS_INCLUDE_PATH}"
done

# export CFLAGS="-I${HOMEBREW_PREFIX}/include ${CFLAGS:-}"
# export CPPFLAGS="-I${HOMEBREW_PREFIX}/include ${CPPFLAGS:-}"
# export CXXFLAGS="-I${HOMEBREW_PREFIX}/include ${CXXFLAGS:-}"
# export C_PATH="${HOMEBREW_PREFIX}/include${C_PATH+:$C_PATH}"
# export C_INCLUDE_PATH="${HOMEBREW_PREFIX}/include${C_INCLUDE_PATH+:$C_INCLUDE_PATH}"
# export CPLUS_INCLUDE_PATH="${HOMEBREW_PREFIX}/include${CPLUS_INCLUDE_PATH+:$CPLUS_INCLUDE_PATH}"

export PKG_CONFIG_PATH="${HOMEBREW_OPT}/curl/lib/pkgconfig${PKG_CONFIG_PATH+:$PKG_CONFIG_PATH}"
export PKG_CONFIG_PATH="${HOMEBREW_OPT}/icu4c/lib/pkgconfig${PKG_CONFIG_PATH+:$PKG_CONFIG_PATH}"
export PKG_CONFIG_PATH="${HOMEBREW_OPT}/jpeg/lib/pkgconfig${PKG_CONFIG_PATH+:$PKG_CONFIG_PATH}"
export PKG_CONFIG_PATH="${HOMEBREW_OPT}/krb5/lib/pkgconfig${PKG_CONFIG_PATH+:$PKG_CONFIG_PATH}"
export PKG_CONFIG_PATH="${HOMEBREW_OPT}/libedit/lib/pkgconfig${PKG_CONFIG_PATH+:$PKG_CONFIG_PATH}"
export PKG_CONFIG_PATH="${HOMEBREW_OPT}/libpq/lib/pkgconfig${PKG_CONFIG_PATH+:$PKG_CONFIG_PATH}"
export PKG_CONFIG_PATH="${HOMEBREW_OPT}/libressl/lib/pkgconfig${PKG_CONFIG_PATH+:$PKG_CONFIG_PATH}"
export PKG_CONFIG_PATH="${HOMEBREW_OPT}/libxml2/lib/pkgconfig${PKG_CONFIG_PATH+:$PKG_CONFIG_PATH}"
export PKG_CONFIG_PATH="${HOMEBREW_OPT}/openssl/lib/pkgconfig${PKG_CONFIG_PATH+:$PKG_CONFIG_PATH}"
export PKG_CONFIG_PATH="${HOMEBREW_OPT}/ncurses/lib/pkgconfig${PKG_CONFIG_PATH+:$PKG_CONFIG_PATH}"
export PKG_CONFIG_PATH="${HOMEBREW_OPT}/readline/lib/pkgconfig${PKG_CONFIG_PATH+:$PKG_CONFIG_PATH}"
export PKG_CONFIG_PATH="${HOMEBREW_PREFIX}/lib/pkgconfig/${PKG_CONFIG_PATH+:$PKG_CONFIG_PATH}"

unset HOMEBREW_OPT
unset COMMON_LIB_PATHS
unset COMMON_INCLUDE_PATHS

## Unused for now

# Linux only
# if [[ $(uname) != 'Darwin' ]]; then
  # export PATH="$HOMEBREW_OPT/glibc/bin${PATH+:$PATH}"
  # export PATH="$HOMEBREW_OPT/glibc/sbin${PATH+:$PATH}"
  # export LDFLAGS="-L$HOMEBREW_OPT/glibc/lib ${LDFLAGS:-}"
  # export CFLAGS="-I$HOMEBREW_OPT/glibc/include ${CFLAGS:-}"
  # export CPPFLAGS="-I$HOMEBREW_OPT/glibc/include ${CPPFLAGS:-}"
  # export CXXFLAGS="-I$HOMEBREW_OPT/glibc/include ${CXXFLAGS:-}"
  # export LIBRARY_PATH="$HOMEBREW_OPT/glibc/lib${LIBRARY_PATH+:$LIBRARY_PATH}"
  # export LD_LIBRARY_PATH="$HOMEBREW_OPT/glibc/lib${LD_LIBRARY_PATH+:$LD_LIBRARY_PATH}"
  # export C_PATH="$HOMEBREW_OPT/glibc/include${C_PATH+:$C_PATH}"
  # export C_INCLUDE_PATH="$HOMEBREW_OPT/glibc/include${C_INCLUDE_PATH+:$C_INCLUDE_PATH}"
  # export CPLUS_INCLUDE_PATH="$HOMEBREW_OPT/glibc/include${CPLUS_INCLUDE_PATH+:$CPLUS_INCLUDE_PATH}"
# fi

# export PATH="$HOMEBREW_OPT/llvm/bin${PATH+:$PATH}"
# export PATH="$HOMEBREW_OPT/libtool/libexec/gnubin${PATH+:$PATH}"
# export PATH="$HOMEBREW_OPT/binutils/bin${PATH+:$PATH}"
# export PATH="$HOMEBREW_OPT/openldap/bin${PATH+:$PATH}"
# export PATH="$HOMEBREW_OPT/openldap/sbin${PATH+:$PATH}"

# export LIBRARY_PATH="$HOMEBREW_OPT/llvm/lib${LIBRARY_PATH+:$LIBRARY_PATH}"
# export LIBRARY_PATH="$HOMEBREW_OPT/openssl/lib${LIBRARY_PATH+:$LIBRARY_PATH}"
# export LIBRARY_PATH="$HOMEBREW_OPT/zlib/lib${LIBRARY_PATH+:$LIBRARY_PATH}"
# export LIBRARY_PATH="$HOMEBREW_OPT/binutils/lib${LIBRARY_PATH+:$LIBRARY_PATH}"
# export LIBRARY_PATH="$HOMEBREW_OPT/libiconv/lib${LIBRARY_PATH+:$LIBRARY_PATH}"
# export LIBRARY_PATH="$HOMEBREW_OPT/libxml2/lib${LIBRARY_PATH+:$LIBRARY_PATH}"
# export LIBRARY_PATH="$HOMEBREW_OPT/openldap/lib${LIBRARY_PATH+:$LIBRARY_PATH}"

# export LD_LIBRARY_PATH="$HOMEBREW_OPT/llvm/lib${LD_LIBRARY_PATH+:$LD_LIBRARY_PATH}"
# export LD_LIBRARY_PATH="$HOMEBREW_OPT/openssl/lib${LD_LIBRARY_PATH+:$LD_LIBRARY_PATH}"
# export LD_LIBRARY_PATH="$HOMEBREW_OPT/zlib/lib${LD_LIBRARY_PATH+:$LD_LIBRARY_PATH}"
# export LD_LIBRARY_PATH="$HOMEBREW_OPT/binutils/lib${LD_LIBRARY_PATH+:$LD_LIBRARY_PATH}"
# export LD_LIBRARY_PATH="$HOMEBREW_OPT/libiconv/lib${LD_LIBRARY_PATH+:$LD_LIBRARY_PATH}"
# export LD_LIBRARY_PATH="$HOMEBREW_OPT/libxml2/lib${LD_LIBRARY_PATH+:$LD_LIBRARY_PATH}"
# export LD_LIBRARY_PATH="$HOMEBREW_OPT/openldap/lib${LD_LIBRARY_PATH+:$LD_LIBRARY_PATH}"

# export C_PATH="$HOMEBREW_OPT/llvm/include${C_PATH+:$C_PATH}"
# export C_PATH="$HOMEBREW_OPT/openssl/include${C_PATH+:$C_PATH}"
# export C_PATH="$HOMEBREW_OPT/zlib/include${C_PATH+:$C_PATH}"
# export C_PATH="$HOMEBREW_OPT/binutils/include${C_PATH+:$C_PATH}"
# export C_PATH="$HOMEBREW_OPT/libiconv/include${C_PATH+:$C_PATH}"
# export C_PATH="$HOMEBREW_OPT/libxml2/include${C_PATH+:$C_PATH}"
# export C_PATH="$HOMEBREW_OPT/openldap/include${C_PATH+:$C_PATH}"

# export C_INCLUDE_PATH="$HOMEBREW_OPT/llvm/include${C_INCLUDE_PATH+:$C_INCLUDE_PATH}"
# export C_INCLUDE_PATH="$HOMEBREW_OPT/openssl/include${C_INCLUDE_PATH+:$C_INCLUDE_PATH}"
# export C_INCLUDE_PATH="$HOMEBREW_OPT/zlib/include${C_INCLUDE_PATH+:$C_INCLUDE_PATH}"
# export C_INCLUDE_PATH="$HOMEBREW_OPT/binutils/include${C_INCLUDE_PATH+:$C_INCLUDE_PATH}"
# export C_INCLUDE_PATH="$HOMEBREW_OPT/libiconv/include${C_INCLUDE_PATH+:$C_INCLUDE_PATH}"
# export C_INCLUDE_PATH="$HOMEBREW_OPT/libxml2/include${C_INCLUDE_PATH+:$C_INCLUDE_PATH}"
# export C_INCLUDE_PATH="$HOMEBREW_OPT/openldap/include${C_INCLUDE_PATH+:$C_INCLUDE_PATH}"

# export CPLUS_INCLUDE_PATH="$HOMEBREW_OPT/llvm/include${CPLUS_INCLUDE_PATH+:$CPLUS_INCLUDE_PATH}"
# export CPLUS_INCLUDE_PATH="$HOMEBREW_OPT/openssl/include${CPLUS_INCLUDE_PATH+:$CPLUS_INCLUDE_PATH}"
# export CPLUS_INCLUDE_PATH="$HOMEBREW_OPT/zlib/include${CPLUS_INCLUDE_PATH+:$CPLUS_INCLUDE_PATH}"
# export CPLUS_INCLUDE_PATH="$HOMEBREW_OPT/binutils/include${CPLUS_INCLUDE_PATH+:$CPLUS_INCLUDE_PATH}"
# export CPLUS_INCLUDE_PATH="$HOMEBREW_OPT/libiconv/include${CPLUS_INCLUDE_PATH+:$CPLUS_INCLUDE_PATH}"
# export CPLUS_INCLUDE_PATH="$HOMEBREW_OPT/libxml2/include${CPLUS_INCLUDE_PATH+:$CPLUS_INCLUDE_PATH}"
# export CPLUS_INCLUDE_PATH="$HOMEBREW_OPT/openldap/include${CPLUS_INCLUDE_PATH+:$CPLUS_INCLUDE_PATH}"
#
# export LDFLAGS="-L$HOMEBREW_OPT/llvm/lib ${LDFLAGS:-}"
# export LDFLAGS="-L$HOMEBREW_OPT/openssl/lib ${LDFLAGS:-}"
# export LDFLAGS="-L$HOMEBREW_OPT/zlib/lib ${LDFLAGS:-}"
# export LDFLAGS="-L$HOMEBREW_OPT/binutils/lib ${LDFLAGS:-}"
#
# export CFLAGS="-I$HOMEBREW_OPT/binutils/include ${CFLAGS:-}"
# export CFLAGS="-I$HOMEBREW_OPT/llvm/include ${CFLAGS:-}"
# export CFLAGS="-I$HOMEBREW_OPT/openssl/include ${CFLAGS:-}"
# export CFLAGS="-I$HOMEBREW_OPT/zlib/include ${CFLAGS:-}"

# export CPPFLAGS="-I$HOMEBREW_OPT/llvm/include ${CPPFLAGS:-}"
# export CPPFLAGS="-I$HOMEBREW_OPT/openssl/include ${CPPFLAGS:-}"
# export CPPFLAGS="-I$HOMEBREW_OPT/zlib/include ${CPPFLAGS:-}"
# export CPPFLAGS="-I$HOMEBREW_OPT/binutils/include ${CPPFLAGS:-}"
#
# export CXXFLAGS="-I$HOMEBREW_OPT/llvm/include ${CXXFLAGS:-}"
# export CXXFLAGS="-I$HOMEBREW_OPT/openssl/include ${CXXFLAGS:-}"
# export CXXFLAGS="-I$HOMEBREW_OPT/zlib/include ${CXXFLAGS:-}"
# export CXXFLAGS="-I$HOMEBREW_OPT/binutils/include ${CXXFLAGS:-}"

# export PKG_CONFIG_PATH="$HOMEBREW_OPT/openssl/lib/pkgconfig${PKG_CONFIG_PATH+:$PKG_CONFIG_PATH}"
# export PKG_CONFIG_PATH="$HOMEBREW_OPT/zlib/lib/pkgconfig${PKG_CONFIG_PATH+:$PKG_CONFIG_PATH}"
# export PKG_CONFIG_PATH="$HOMEBREW_OPT/openldap/lib/pkgconfig${PKG_CONFIG_PATH+:$PKG_CONFIG_PATH}"

# export CLANG_CONFIG_FILE_SYSTEM_DIR="$HOMEBREW_PREFIX/etc/clang"
# export CLANG_CONFIG_FILE_USER_DIR="$XDG_CONFIG_HOME/clang"
#
# export GUILE_LOAD_PATH="$HOMEBREW_PREFIX/share/guile/site/3.0"
# export GUILE_LOAD_COMPILED_PATH="$HOMEBREW_PREFIX/lib/guile/3.0/site-ccache"
# export GUILE_SYSTEM_EXTENSIONS_PATH="$HOMEBREW_PREFIX/lib/guile/3.0/extensions"

# -------------------------------------------------------------------------------------------------
# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et
# -------------------------------------------------------------------------------------------------
