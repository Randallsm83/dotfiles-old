#!/usr/bin/env zsh

(( $+commands[vagrant] )) || return 1

export ZSH_THEME_VAGRANT_PROMPT_PREFIX="%{$fg_bold[blue]%}["
export ZSH_THEME_VAGRANT_PROMPT_SUFFIX="%{$fg_bold[blue]%}]%{$reset_color%} "
export ZSH_THEME_VAGRANT_PROMPT_RUNNING="%{$fg_no_bold[green]%}●"
export ZSH_THEME_VAGRANT_PROMPT_POWEROFF="%{$fg_no_bold[red]%}●"
export ZSH_THEME_VAGRANT_PROMPT_SUSPENDED="%{$fg_no_bold[yellow]%}●"
export ZSH_THEME_VAGRANT_PROMPT_NOT_CREATED="%{$fg_no_bold[white]%}○"

function vagrant_prompt_info() {
  if [[ ! -d .vagrant || ! -f Vagrantfile ]]; then
    return
  fi

  local vm_states vm_state
  vm_states=(${(f)"$(vagrant status 2> /dev/null | sed -nE 's/^[^ ]* *([[:alnum:] ]*) \([[:alnum:]_]+\)$/\1/p')"})
  printf '%s' 'OK'
  printf '%s' $ZSH_THEME_VAGRANT_PROMPT_PREFIX
  for vm_state in $vm_states; do
    case "$vm_state" in
      running) printf '%s' $ZSH_THEME_VAGRANT_PROMPT_RUNNING ;;
      "not running"|poweroff) printf '%s' $ZSH_THEME_VAGRANT_PROMPT_POWEROFF ;;
      paused|saved|suspended) printf '%s' $ZSH_THEME_VAGRANT_PROMPT_SUSPENDED ;;
      "not created") printf '%s' $ZSH_THEME_VAGRANT_PROMPT_NOT_CREATED ;;
    esac
  done
  printf '%s' $ZSH_THEME_VAGRANT_PROMPT_SUFFIX
}

# -------------------------------------------------------------------------------------------------
# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et
# -------------------------------------------------------------------------------------------------
