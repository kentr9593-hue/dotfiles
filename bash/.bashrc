#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
#PS1='[\u@\h \W]\$ '
PS1='\[\e[38;2;232;176;74m\]⚓ \u\[\e[38;2;243;227;192m\]@\h \[\e[38;2;240;122;42m\]\w\[\e[0m\] ❯ '
