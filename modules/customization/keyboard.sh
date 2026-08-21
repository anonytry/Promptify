#!/bin/bash

# Keyboard Layout picker + Custom Layout editor (Termux-only).
# Fixed 2×8 = 16 buttons. User edits keys + popups per position.

CUSTOM_LAYOUT_FILE="$PFY_USERDATA/custom-layout.keys"
COLS=8
ROWS=2

# ─── Picker ──────────────────────────────────────────────────────────────────

manage_keyboard() {
    [[ "$OS_TYPE" == "termux" ]] || {
        center_print "\e[1;33m[!] Keyboard Layout is Termux-only.\e[0m"
        press_enter
        return
    }

    while true; do
        local cur_idx
        cur_idx=$(get_keyboard_idx "$CUR_KEYBOARD")

        KB_CHOICE=$(radio_menu "Keyboard Layout" "" "keyboard_preview" "$cur_idx" "$cur_idx" \
            "$(get_keyboard_label 0)" \
            "$(get_keyboard_label 1)" \
            "$(get_keyboard_label 2)" \
            "Back")

        [[ "$KB_CHOICE" == "CANCELLED" || "$KB_CHOICE" == 3 ]] && return

        local selected_kb
        selected_kb=$(get_keyboard_name "$KB_CHOICE")

        if [[ "$selected_kb" == "custom" ]]; then
            _kb_edit_layout
            continue
        fi

        if confirm_action "Use '$(get_keyboard_label "$KB_CHOICE")' layout?" "y"; then
            CUR_KEYBOARD="$selected_kb"
            set_pref KEYBOARD "$CUR_KEYBOARD"
            load_prefs
            refresh_ui
            center_print "\e[1;32m[✔] Applied!\e[0m"
            restart_shell
        fi
    done
}

# ─── Layout Editor (fixed 2×8) ──────────────────────────────────────────────

_kb_edit_layout() {
    local -a layout_keys=()
    local -a layout_popups=()
    local ri ki

    local has_saved=false
    if [[ -f "$CUSTOM_LAYOUT_FILE" ]]; then
        local line_num=0
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            local -a row_items=()
            IFS=',' read -ra row_items <<< "$line"
            for ((ki = 0; ki < ${#row_items[@]}; ki++)); do
                local idx=$((line_num * COLS + ki))
                [[ $idx -ge $((ROWS * COLS)) ]] && break
                local raw="${row_items[$ki]}"
                if [[ "$raw" == *"popup:"* ]]; then
                    layout_keys[$idx]=$(echo "$raw" | sed -n 's/.*key:\([^;]*\).*/\1/p')
                    layout_popups[$idx]=$(echo "$raw" | sed -n 's/.*popup:\([^}]*\).*/\1/p')
                else
                    layout_keys[$idx]="$raw"
                    layout_popups[$idx]=""
                fi
                has_saved=true
            done
            ((line_num++))
        done < "$CUSTOM_LAYOUT_FILE"
    fi

    # Pad to 16
    while [[ ${#layout_keys[@]} -lt $((ROWS * COLS)) ]]; do
        layout_keys+=("")
        layout_popups+=("")
    done

    # Default if nothing saved
    if [[ "$has_saved" == false ]]; then
        local -a defaults=(
            ESC "|" "/" "HOME" "UP" "END" "PGUP" "DEL"
            "TAB" "CTRL" "ALT" "LEFT" "DOWN" "RIGHT" "PGDN" "BKSP"
        )
        for ((ri = 0; ri < $((ROWS * COLS)); ri++)); do
            layout_keys[$ri]="${defaults[$ri]}"
            layout_popups[$ri]=""
        done
    fi

    local cursor=0

    while true; do
        # Render
        local term_w
        term_w=$(tput cols)
        local cols=$COLS
        local box_w=$(( (term_w - 4) / cols ))
        [[ $box_w -lt 5 ]] && box_w=5
        local inner_w=$((box_w - 2))
        local rows=$((16 / cols))

        printf '\033[2J\033[H\n'
        printf '  \e[1;36mCUSTOM KEYBOARD LAYOUT\e[0m\n\n'

        printf '  \e[1;33m[\e[0m\e[1;97m←→↑↓\e[0m\e[1;33m]\e[0m Move'
        printf '  \e[1;33m[\e[0m\e[1;97mEnter\e[0m\e[1;33m]\e[0m Edit Key'
        printf '  \e[1;33m[\e[0m\e[1;97mP\e[0m\e[1;33m]\e[0m Popup'
        printf '  \e[1;33m[\e[0m\e[1;97mX\e[0m\e[1;33m]\e[0m Remove Popup\n'
        printf '  \e[1;33m[\e[0m\e[1;97mS\e[0m\e[1;33m]\e[0m Save'
        printf '  \e[1;33m[\e[0m\e[1;97mR\e[0m\e[1;33m]\e[0m Reset'
        printf '  \e[1;31m[\e[0m\e[1;31mESC\e[0m\e[1;31m]\e[0m Back\n\n'

        for ((ri = 0; ri < rows; ri++)); do
            printf '  '
            for ((ki = 0; ki < cols; ki++)); do
                local idx=$((ri * cols + ki))
                local key="${layout_keys[$idx]}"
                local popup="${layout_popups[$idx]}"
                local display
                display=$(key_display_name "$key")
                local marker=""
                [[ -n "$popup" ]] && marker="^$(key_display_name "$popup")"
                local full="${display}${marker}"
                [[ ${#full} -gt $inner_w ]] && full="${display:0:$((inner_w - 1))}${marker}"
                [[ ${#full} -gt $inner_w ]] && full="${full:0:$inner_w}"
                local pad_total=$(( inner_w - ${#full} ))
                [[ $pad_total -lt 0 ]] && pad_total=0
                local pad_l=$(( (pad_total + 1) / 2 ))
                local pad_r=$(( pad_total - pad_l ))

                if [[ $idx -eq $cursor ]]; then
                    printf '\e[46m\e[30m[\e[0m\e[46m\e[30m%*s\e[0m\e[46m\e[1;30m%s\e[0m\e[46m\e[30m%*s\e[0m\e[46m\e[30m]\e[0m\e[0m' \
                        "$pad_l" '' "$full" "$pad_r" ''
                elif [[ -n "$popup" ]]; then
                    printf '\e[1;33m[\e[0m\e[1;97m%*s%s%*s\e[0m\e[1;33m]\e[0m' \
                        "$pad_l" '' "$full" "$pad_r" ''
                else
                    printf '\e[1;97m[\e[0m\e[1;97m%*s%s%*s\e[0m\e[1;97m]\e[0m' \
                        "$pad_l" '' "$full" "$pad_r" ''
                fi
            done
            echo
        done

        # Legend
        printf '\n  \e[2;37m^name = popup on long-press  |  Yellow = has popup\e[0m\n'

        # Input
        local key
        if ! IFS= read -rsn1 key; then
            break
        fi

        case "$key" in
            $'\x1b')
                local ext
                if IFS= read -rsn2 -t 0.05 ext; then
                    case "$ext" in
                        '[A') [[ $cursor -ge $cols ]] && cursor=$((cursor - cols)) ;;
                        '[B') [[ $cursor -lt $(( (rows - 1) * cols )) ]] && cursor=$((cursor + cols)) ;;
                        '[D') [[ $cursor -gt 0 ]] && ((cursor--)) ;;
                        '[C') [[ $cursor -lt $((rows * cols - 1)) ]] && ((cursor++)) ;;
                    esac
                else
                    break
                fi
                ;;
            "")
                # Edit key at cursor
                local cur_key="${layout_keys[$cursor]}"
                local new_key
                new_key=$(key_picker "$cur_key" "Edit Key")
                if [[ -n "$new_key" ]]; then
                    layout_keys[$cursor]="$new_key"
                fi
                ;;
            "p"|"P")
                # Add/change popup
                local pkey="${layout_keys[$cursor]}"
                [[ -z "$pkey" ]] && continue
                if [[ "$pkey" == *"{"* ]]; then
                    center_print "\e[1;33m[!] Macros don't support popups.\e[0m"
                    sleep 1
                    continue
                fi
                local popup_key
                popup_key=$(key_picker "" "Add Popup")
                if [[ -n "$popup_key" ]]; then
                    layout_popups[$cursor]="$popup_key"
                fi
                ;;
            "x"|"X")
                # Remove popup
                if [[ -n "${layout_popups[$cursor]}" ]]; then
                    layout_popups[$cursor]=""
                    center_print "\e[1;32m[✔] Popup removed.\e[0m"
                    sleep 0.5
                fi
                ;;
            "s"|"S")
                _kb_save_layout "${layout_keys[@]}" "${layout_popups[@]}"
                break
                ;;
            "r"|"R")
                if confirm_action "Reset to default?" "n"; then
                    local -a defaults=(
                        ESC "|" "/" "HOME" "UP" "END" "PGUP" "DEL"
                        "TAB" "CTRL" "ALT" "LEFT" "DOWN" "RIGHT" "PGDN" "BKSP"
                    )
                    for ((ri = 0; ri < $((ROWS * COLS)); ri++)); do
                        layout_keys[$ri]="${defaults[$ri]}"
                        layout_popups[$ri]=""
                    done
                fi
                ;;
        esac
    done
}

_kb_save_layout() {
    local -a all=("$@")
    local total=${#all[@]}
    local half=$((total / 2))
    local -a keys=("${all[@]:0:$half}")
    local -a popups=("${all[@]:$half}")

    mkdir -p "$PFY_USERDATA"

    # Save layout file for future editing
    : > "$CUSTOM_LAYOUT_FILE"
    for ((ri = 0; ri < ROWS; ri++)); do
        local row_line=""
        for ((ki = 0; ki < COLS; ki++)); do
            local idx=$((ri * COLS + ki))
            local k="${keys[$idx]}"
            local p="${popups[$idx]}"
            [[ -z "$k" ]] && continue
            [[ -n "$row_line" ]] && row_line+=","
            if [[ -n "$p" ]]; then
                row_line+="{key:${k};popup:${p}}"
            else
                row_line+="$k"
            fi
        done
        [[ -n "$row_line" ]] && echo "$row_line" >> "$CUSTOM_LAYOUT_FILE"
    done

    CUR_KEYBOARD="custom"
    set_pref KEYBOARD "custom"
    load_prefs

    # Delegate properties generation to sync (handles snapshots, fingerprints)
    sync_termux_ui

    center_print "\e[1;32m[✔] Custom layout saved!\e[0m"
    sleep 1
}

# ─── Key Picker (Tabbed) ────────────────────────────────────────────────────

key_picker() {
    local current="$1"
    local pick_title="${2:-Select Key}"

    local -a nav_keys=("ESC" "TAB" "ENTER" "BKSP" "DEL" "INS" "HOME" "END" "PGUP" "PGDN" "UP" "DOWN" "LEFT" "RIGHT")
    local -a mod_keys=("CTRL" "ALT" "SHIFT" "FN" "KEYBOARD" "PASTE")
    local -a fn_keys=("F1" "F2" "F3" "F4" "F5" "F6" "F7" "F8" "F9" "F10" "F11" "F12")
    local -a sym_keys=("|" "/" "\\" "-" "_" "~" ":" "." ";" "=" "+" "*" "#" "@" "!" "?" "&" "%" "$" "^" "(" ")" "[" "]" "{" "}" "<" ">")

    local -a macro_disp=("CLR" "PUSH" "PULL" "GS" "GL" "SAVE" "Q" "CC" "CLS" "EXIT" "LA" "UPD" "Custom...")
    local -a macro_val=(
        "{macro:clear;display:CLR}"
        "{macro:git push origin HEAD:main;display:PUSH}"
        "{macro:git pull;display:PULL}"
        "{macro:git status;display:GS}"
        "{macro:git log --oneline -5;display:GL}"
        "{macro::wq;display:SAVE}"
        "{macro::q;display:Q}"
        "{macro:CTRL c;display:CC}"
        "{macro:CTRL l;display:CLS}"
        "{macro:CTRL d;display:EXIT}"
        "{macro:ls -la;display:LA}"
        "{macro:sudo apt update && sudo apt upgrade -y;display:UPD}"
        "__custom__"
    )

    while true; do
        local tab_choice
        tab_choice=$(radio_menu "$pick_title" "" "" 0 -1 \
            "Navigation" "Modifiers" "Fn Keys" "Symbols" "Macros" "Back")

        [[ "$tab_choice" == "CANCELLED" || "$tab_choice" == 5 ]] && return

        local -a opts=()
        case $tab_choice in
            0) opts=("${nav_keys[@]}") ;;
            1) opts=("${mod_keys[@]}") ;;
            2) opts=("${fn_keys[@]}") ;;
            3) opts=("${sym_keys[@]}") ;;
            4) opts=("${macro_disp[@]}") ;;
        esac

        local item_choice
        item_choice=$(radio_menu "Select Key" "" "" 0 -1 "${opts[@]}")

        [[ "$item_choice" == "CANCELLED" ]] && continue

        case $tab_choice in
            0) echo "${nav_keys[$item_choice]}" ;;
            1) echo "${mod_keys[$item_choice]}" ;;
            2) echo "${fn_keys[$item_choice]}" ;;
            3) echo "${sym_keys[$item_choice]}" ;;
            4)
                local mval="${macro_val[$item_choice]}"
                if [[ "$mval" == "__custom__" ]]; then
                    type_custom_key_or_macro
                else
                    echo "$mval"
                fi
                ;;
        esac
        return
    done
}

# ─── Custom Key/Macro Input ──────────────────────────────────────────────────

type_custom_key_or_macro() {
    local sub_choice
    sub_choice=$(radio_menu "Custom Input" "" "" 0 -1 "Key Name" "Macro" "Back")

    [[ "$sub_choice" == "CANCELLED" || "$sub_choice" == 2 ]] && return

    if [[ "$sub_choice" == 0 ]]; then
        type_custom_key
    else
        type_custom_macro
    fi
}

type_custom_key() {
    local input
    input=$(input_prompt "Key name (e.g. ESC, a, /)" "" 12 "true")
    [[ "$input" == "CANCELLED" || -z "$input" ]] && return
    resolve_key_input "$input"
}

type_custom_macro() {
    local display_cmd
    display_cmd=$(input_prompt "Button label (max 5)" "" 5 "true")
    [[ "$display_cmd" == "CANCELLED" || -z "$display_cmd" ]] && return

    local macro_cmd
    macro_cmd=$(input_prompt "Command to type" "" 50 "true")
    [[ "$macro_cmd" == "CANCELLED" || -z "$macro_cmd" ]] && return

    echo "{macro:${macro_cmd};display:${display_cmd}}"
}

# ─── Preview for radio_menu ─────────────────────────────────────────────────

keyboard_preview() {
    local idx="$1"
    local spacer="$2"
    local mode="$3"

    [[ "$mode" == "type" ]] && { echo "footer"; return; }
    [[ $idx -ge $KEYBOARD_COUNT ]] && return

    local kb_name
    kb_name=$(get_keyboard_name "$idx")

        case "$kb_name" in
        advanced)
            printf '%b\e[1;34mAdvanced 8-Key (with popups)\e[0m\n' "$spacer"
            printf '%b\e[1;97m%-6s%-6s%-6s%-6s%-6s%-6s%-6s%-6s\e[0m\n' "$spacer" \
                "ESC" "|" "/" "-" "UP" "~" "HOME" "DEL"
            printf '%b\e[1;97m%-6s%-6s%-6s%-6s%-6s%-6s%-6s%-6s\e[0m\n' "$spacer" \
                "TAB" "CTL" "ALT" "LEFT" "DOWN" "RIGHT" "END" "BKSP"
            ;;
        simple)
            printf '%b\e[1;34mSimple 8-Key (Legacy)\e[0m\n' "$spacer"
            printf '%b\e[1;97m%-6s%-6s%-6s%-6s%-6s%-6s%-6s%-6s\e[0m\n' "$spacer" \
                "ESC" "|" "/" "HOME" "UP" "END" "PGUP" "DEL"
            printf '%b\e[1;97m%-6s%-6s%-6s%-6s%-6s%-6s%-6s%-6s\e[0m\n' "$spacer" \
                "TAB" "CTL" "ALT" "LEFT" "DOWN" "RIGHT" "PGDN" "BKSP"
            ;;
        custom)
            printf '%b\e[1;34mCustom 16-Key (tap to edit)\e[0m\n' "$spacer"
            if [[ -f "$CUSTOM_LAYOUT_FILE" ]]; then
                local line_num=0
                while IFS= read -r cline; do
                    [[ -z "$cline" ]] && continue
                    local -a ckeys=()
                    IFS=',' read -ra ckeys <<< "$cline"
                    local cline_out=""
                    local ck
                    for ck in "${ckeys[@]}"; do
                        local cname
                        if [[ "$ck" == *"popup:"* ]]; then
                            local bk pv
                            bk=$(echo "$ck" | sed -n 's/.*key:\([^;]*\).*/\1/p')
                            pv=$(echo "$ck" | sed -n 's/.*popup:\([^}]*\).*/\1/p')
                            cname="$(key_display_name "$bk")^${pv:0:3}"
                        else
                            cname="$(key_display_name "$ck")"
                        fi
                        [[ ${#cname} -gt 5 ]] && cname="${cname:0:5}"
                        local pad_r=$(( 5 - ${#cname} ))
                        [[ $pad_r -lt 0 ]] && pad_r=0
                        cline_out+="$cname$(printf '%*s' "$pad_r" '') "
                    done
                    printf '%b\e[1;97m%s\e[0m\n' "$spacer" "$cline_out"
                    ((line_num++))
                    [[ $line_num -ge 2 ]] && break
                done < "$CUSTOM_LAYOUT_FILE"
            else
                printf '%b\e[1;37mNo layout yet. Select to design.\e[0m\n' "$spacer"
            fi
            ;;
    esac
}
