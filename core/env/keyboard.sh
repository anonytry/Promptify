#!/bin/bash

# Termux keyboard layout definitions (single source of truth).
# Sourced before install/ui/maintenance modules, so visible everywhere.

KEYBOARD_LAYOUTS=("advanced" "simple" "custom")
KEYBOARD_COUNT=${#KEYBOARD_LAYOUTS[@]}

get_keyboard_label() {
    case "$1" in
        0) echo "Advanced (Default)" ;;
        1) echo "Simple (Legacy)" ;;
        2) echo "Custom Layout" ;;
        *) echo "Advanced (Default)" ;;
    esac
}

get_keyboard_name() {
    case "$1" in
        0) echo "advanced" ;;
        1) echo "simple" ;;
        2) echo "custom" ;;
        *) echo "advanced" ;;
    esac
}

get_keyboard_idx() {
    case "$1" in
        "advanced") echo 0 ;;
        "simple")   echo 1 ;;
        "custom")   echo 2 ;;
        *)          echo 0 ;;
    esac
}

# Recognized Termux key names (for validation + key picker).
KEY_NAMES=(ESC TAB HOME END PGUP PGDN INS DEL BKSP ENTER
           UP DOWN LEFT RIGHT
           CTRL ALT SHIFT FN
           F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 F12
           KEYBOARD DRAWER PASTE SCROLL)

# Aliases that map to canonical names.
resolve_key_alias() {
    case "${1^^}" in
        ESCAPE)    echo "ESC" ;;
        CONTROL)   echo "CTRL" ;;
        SHFT)      echo "SHIFT" ;;
        RETURN)    echo "ENTER" ;;
        FUNCTION)  echo "FN" ;;
        LT)        echo "LEFT" ;;
        RT)        echo "RIGHT" ;;
        DN)        echo "DOWN" ;;
        PAGEUP|PAGE_UP)  echo "PGUP" ;;
        PAGEDOWN|PAGE_DOWN) echo "PGDN" ;;
        DELETE)    echo "DEL" ;;
        BACKSPACE) echo "BKSP" ;;
        *)         echo "$1" ;;
    esac
}

# Validate a key name. Returns 0 if recognized, 1 if not.
is_valid_key() {
    local key
    key=$(resolve_key_alias "$1")
    local k
    for k in "${KEY_NAMES[@]}"; do
        [[ "${key^^}" == "$k" ]] && return 0
    done
    return 1
}

# Resolve user input to a Termux key name or literal text.
# Handles: known key names, aliases, single chars, macros.
resolve_key_input() {
    local input="$1"
    [[ -z "$input" ]] && return

    # Already a macro format — pass through
    if [[ "$input" == *"{"* ]]; then
        echo "$input"
        return
    fi

    local resolved
    resolved=$(resolve_key_alias "$input")

    # Check against known key names
    if is_valid_key "$resolved"; then
        echo "${resolved^^}"
        return
    fi

    # Not a known key → treat as literal text
    echo "$input"
}

# Short display name for a key (max 5 chars for grid rendering).
key_display_name() {
    local token="$1"
    [[ -z "$token" ]] && return

    # Popup format: {key:ESC;popup:CTRL c}
    if [[ "$token" == *"key:"* ]]; then
        local key_val
        key_val=$(echo "$token" | sed -n 's/.*key:\([^;]*\).*/\1/p')
        if [[ -n "$key_val" ]]; then
            echo "${key_val:0:5}"
            return
        fi
    fi

    # Macro format: {macro:clear;display:CLR}
    if [[ "$token" == *"{"* ]]; then
        local display_val
        display_val=$(echo "$token" | sed -n 's/.*display:\([^}]*\).*/\1/p')
        echo "${display_val:0:5}"
        return
    fi

    echo "${token:0:5}"
}
