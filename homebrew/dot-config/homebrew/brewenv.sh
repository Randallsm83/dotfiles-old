#!/bin/sh

# This is NOT the typical brew.env mentioned in their docs, that file doesn't support shell expansion...
# This is sourced to make things work better as expected
#

# Set caching and storage locations
export HOMEBREW_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/Homebrew"
export HOMEBREW_BUNDLE_USER_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/Homebrew"
export HOMEBREW_LOGS="${XDG_CACHE_HOME:-$HOME/.cache}/Homebrew/Logs"
export HOMEBREW_TEMP="${XDG_RUNTIME_DIR:-/tmp}/Homebrew"

# Performance optimizations
cores="$(sysctl -n hw.ncpu)"
export HOMEBREW_MAKE_JOBS="$cores"
export HOMEBREW_DISPLAY_INSTALL_TIMES=1
export HOMEBREW_COLOR=1

# Security and download optimizations
export HOMEBREW_NO_INSECURE_REDIRECT=1
export HOMEBREW_CURL_RETRIES=3

# Privacy
export HOMEBREW_NO_ANALYTICS=1

# Set default editor for Homebrew commands
export HOMEBREW_EDITOR="nvim"

# Always use Homebrew installed apps if available
export HOMEBREW_FORCE_BREWED_GIT=1
export HOMEBREW_FORCE_BREWED_CURL=1
export HOMEBREW_FORCE_VENDOR_RUBY=1
export HOMEBREW_FORCE_BREWED_CA_CERTIFICATES=1

# -------------------------------------------------------------------------------------------------
# -*- mode: sh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=sh sw=2 ts=2 et
# -------------------------------------------------------------------------------------------------
