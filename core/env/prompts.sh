#!/bin/bash

# Prompt layout definitions. Each style emits the complete zsh build_prompt()
# block (setopt + build_prompt + precmd hook) verbatim, so ~/.zshrc always
# receives exactly what was syntax-checked. Quoted heredocs are used so no
# bash expansion happens here -- every $ stays literal for zsh to interpret.
get_prompt_block() {
    local style="${1:-parrot}"
    case "$style" in
        fish)
            cat << 'PEOF'
setopt prompt_subst

build_prompt() {
    vcs_info
    local h_name="${HOST:-termux}"
    local short_tag="${TNAME%% *}"

    PROMPT="%F{$P_CLR_TAG}${short_tag}%f%F{white}@%F{$P_CLR_USER}${h_name}%f %F{$P_CLR_PATH}%(4~|/%2~|%~)%f${vcs_info_msg_0_} %F{$P_CLR_BORDER}❯%f "
}

[[ -z "${precmd_functions[(r)build_prompt]}" ]] && precmd_functions+=(build_prompt)
PEOF
            ;;
        minimal)
            cat << 'PEOF'
setopt prompt_subst

build_prompt() {
    vcs_info
    local h_name="${HOST:-termux}"

    PROMPT="%F{$P_CLR_PATH}%(4~|/%2~|%~)%f${vcs_info_msg_0_}> "
}

[[ -z "${precmd_functions[(r)build_prompt]}" ]] && precmd_functions+=(build_prompt)
PEOF
            ;;
        parrot|*)
            cat << 'PEOF'
setopt prompt_subst

build_prompt() {
    vcs_info
    local h_name="${HOST:-termux}"
    local short_tag="${TNAME%% *}"
    local admin_tag="%(#,%F{yellow}admin/%f,)"

    local line1="%F{$P_CLR_BORDER}┌─[${admin_tag}%B%F{$P_CLR_TAG}${short_tag:l}%F{white}@%F{$P_CLR_USER}${h_name}%b%F{$P_CLR_BORDER}]─[%F{$P_CLR_PATH}%(4~|/%2~|%~)%F{$P_CLR_BORDER}]%f${vcs_info_msg_0_}"
    PROMPT=$'\n'${line1}$'\n%F{$P_CLR_BORDER}└──╼ %B%F{red}❯%F{blue}❯%F{black}❯%f%b '
}

[[ -z "${precmd_functions[(r)build_prompt]}" ]] && precmd_functions+=(build_prompt)
PEOF
            ;;
    esac
}
