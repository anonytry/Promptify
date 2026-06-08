#!/bin/bash

# Standard confirmation prompt
confirm_action() {
    local message="$1"
    local default="${2:-n}"
    local prompt
    
    [[ "$CONFIRM_ALL" == "true" ]] && return 0

    [[ "$default" == "y" ]] && prompt="(Y/n)" || prompt="(y/N)"

    echo >&2
    echo -ne " \e[1;33m❯\e[0m $message \e[1;37m$prompt\e[0m: " >&2
    if ! read -r choice; then
        return 1
    fi
    
    [[ -z "$choice" ]] && choice="$default"
    
    if [[ "$choice" == [Y/y] ]]; then
        return 0
    else
        return 1
    fi
}

# Standard input prompt with cancellation support
# Usage: result=$(input_prompt "Label" "Default" 12 "true")
input_prompt() {
    local label="$1"
    local default="$2"
    local max_len="$3"
    local allow_cancel="$4"
    local result=""

    if [[ "$CONFIRM_ALL" == "true" ]]; then
        echo "$default"
        return
    fi

    echo >&2
    echo >&2

    bind '"\e": "CANCEL_INPUT\n"' 2>/dev/null

    while true; do
        if ! read -ep " ❯ $label: " result; then
            echo "CANCELLED"
            bind -r '"\e"' 2>/dev/null
            return
        fi
        
        if [[ "$result" == "CANCEL_INPUT" ]]; then
             echo "CANCELLED"
             bind -r '"\e"' 2>/dev/null
             return
        fi

        if [[ "$allow_cancel" == "true" && ( "$result" == "c" || "$result" == "C" || "$result" == "cancel" ) ]]; then
            echo "CANCELLED"
            bind -r '"\e"' 2>/dev/null
            return
        fi

        [[ -z "$result" ]] && result="$default"
        [[ -n "$result" ]] && break
    done
    
    bind -r '"\e"' 2>/dev/null

    if [[ -n "$max_len" && ${#result} -gt $max_len ]]; then
        result="${result:0:$max_len}"
    fi
    echo "$result"
}

# Standardized "Press Enter" prompt
press_enter() {
    local msg="${1:-Enter to return...}"
    echo
    echo -ne " \e[1;33m❯\e[0m $msg" >&2
    if ! read -r; then
        return 1
    fi
    return 0
}
