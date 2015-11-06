# Dracula Theme v0.7.6
#
# https://github.com/zenorocha/dracula-theme
#
# Copyright 2015, All rights reserved
#
# Code licensed under the MIT license
# http://zenorocha.mit-license.org
#
# @author Zeno Rocha <hi@zenorocha.com>

local user_host='%m'

PROMPT='%{$fg_bold[cyan]%}%m%{$fg_bold[green]%}➜ %{$fg_bold[green]%}%p %{$fg_bold[blue]%}%c %{$reset_color%}'

RPROMPT='${PR_RESET}$(git_prompt_info)$(svn_prompt_info)${PR_YELLOW}%D{%R.%S %a %b %d} ${GREEN_END}${PR_RESET}'

ZSH_THEME_GIT_PROMPT_CLEAN=") %{$fg_bold[green]%}✔ "
ZSH_THEME_GIT_PROMPT_DIRTY=") %{$fg_bold[yellow]%}✗ "
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[cyan]%}("
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
