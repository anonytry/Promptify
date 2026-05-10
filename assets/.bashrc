[[ $- != *i* ]] && return

shopt -s checkwinsize
shopt -s cmdhist
shopt -s globstar
shopt -s histappend
shopt -s histverify

if [ "$(id -u)" = "0" ]; then
	export HISTFILE="$HOME/.bash_root_history"
else
	export HISTFILE="$HOME/.bash_history"
fi
export HISTSIZE=4096
export HISTFILESIZE=16384
export HISTCONTROL="ignoreboth"

printf '\e[4 q'

[[ -f ~/.draw ]] && PROMPTIFY_DIR="${PROMPTIFY_DIR:-$HOME/.promptify}" bash ~/.draw

H_NAME="termux"
[[ $(uname -n) != "localhost" ]] && H_NAME=$(uname -n)

[[ -f ~/.username ]] && . ~/.username || NAME="user"

PROMPT_DIRTRIM=2
if [ "$(id -u)" = "0" ]; then
	PS1="\\[\\e[0;31m\\]\\w\\[\\e[0m\\] \\[\\e[0;97m\\]\\$\\[\\e[0m\\] "
else
	PS1="
\[\033[0;31m\]┌─[\[\033[1;34m\]$NAME\[\033[1;33m\]@\[\033[1;36m\]$H_NAME\[\033[0;31m\]]─[\[\033[0;32m\]\w\[\033[0;31m\]]
\[\033[0;31m\]└──╼ \[\e[1;31m\]❯\[\e[1;34m\]❯\[\e[1;90m\]❯\[\033[0m\] "
fi
PS2='> '
PS3='> '
PS4='+ '

case "$TERM" in
	xterm*|rxvt*)
		if [ "$(id -u)" = "0" ]; then
			PS1="\\[\\e]0;$H_NAME (root): \\w\\a\\]$PS1"
		else
			PS1="\\[\\e]0;$H_NAME: \\w\\a\\]$PS1"
		fi
		;;
	*)
		;;
esac

if [ -x "$PREFIX/bin/dircolors" ] && [ -n "$LOCAL_PREFIX" ]; then
	if [ -f "$LOCAL_PREFIX/etc/dircolors.conf" ]; then
		eval "$(dircolors -b "$LOCAL_PREFIX/etc/dircolors.conf")"
	fi
fi

alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto -h'

if [ -n "$(command -v bat)" ]; then
	alias cat='bat --color=never --decorations=never --paging=never'
fi

if command -v eza &>/dev/null; then
    alias ls='eza --icons --color=auto'
    alias ll='eza -l --icons --color=auto'
    alias l='eza --icons'
elif command -v exa &>/dev/null; then
    alias ls='exa --color=auto'
    alias ll='exa -l --color=auto'
    alias l='exa'
else
    alias l='ls --color=auto'
    alias ls='ls --color=auto'
    alias l.='ls --color=auto -d .*'
    alias la='ls --color=auto -a'
    alias ll='ls --color=auto -Fhl'
    alias ll.='ls --color=auto -Fhl -d .*'
fi

alias cp='cp -i'
alias ln='ln -i'
alias mv='mv -i'
alias rm='rm -i'

# restrict proot aliases to environments where proot-distro is present
command -v proot-distro &>/dev/null && alias nethunter='proot-distro login nethunter'
command -v proot-distro &>/dev/null && alias ubuntu='proot-distro login ubuntu'
