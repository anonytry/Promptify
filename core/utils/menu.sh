#!/bin/bash

# Modular menu item drawing
draw_menu_item() {
    local label="$1"
    local index="$2"
    local cursor="$3"
    local active_idx="$4"
    local spacer="$5"
    local type="${6:-radio}" # Radio or checkbox
    local is_selected="${7:-false}"
    
    local content="$label"
    if [[ "$type" == "checkbox" ]]; then
        if [[ "$is_selected" == "true" ]]; then
            # Selected checkbox [X]
            if [[ $index -eq $cursor ]]; then
                printf '\033[2K\r%b \033[1;36m❯\033[0m [\033[1;32mX\033[0m] \033[1;36m%s\033[0m\n' "$spacer" "$label" >&2
            else
                printf '\033[2K\r%b   [\033[1;32mX\033[0m] \033[2;37m%s\033[0m\n' "$spacer" "$label" >&2
            fi
        else
            # Unselected checkbox [ ]
            if [[ $index -eq $cursor ]]; then
                printf '\033[2K\r%b \033[1;36m❯\033[0m [ ] \033[1;36m%s\033[0m\n' "$spacer" "$label" >&2
            else
                printf '\033[2K\r%b   [ ] \033[2;37m%s\033[0m\n' "$spacer" "$label" >&2
            fi
        fi
        return
    fi

    # Radio Logic
    if [[ $index -eq $cursor ]]; then
        # Highlighted
        printf '\033[2K\r%b \033[1;36m❯\033[0m \033[1;36m%s\033[0m\n' "$spacer" "$label" >&2
    elif [[ $index -eq $active_idx ]]; then
        # Active
        printf '\033[2K\r%b   \033[1;37m%s\033[0m\n' "$spacer" "$label" >&2
    else
        # Dimmed
        printf '\033[2K\r%b   \033[2;37m%s\033[0m\n' "$spacer" "$label" >&2
    fi
}

checkbox_menu() {
    local title="$1"
    shift
    local options=("$@")
    local selected=()
    local cursor=0
    local confirmed=false
    local cancelled=false

    for i in "${!options[@]}"; do
        if [[ "${options[i]}" == *"|selected" ]]; then
            selected[i]=true
            options[i]="${options[i]%|selected}"
        else
            selected[i]=false
        fi
    done

    tput civis >&2
    local bar_spacer=""
    local redraw=true
    local last_cursor=-1
    local old_trap
    old_trap=$(trap -p SIGWINCH)
    trap 'redraw=true; RESIZED=true' SIGWINCH

    while [[ "$confirmed" == false && "$cancelled" == false ]]; do
        if [[ "$redraw" == true ]]; then
            tput cup 0 0 >&2
            tput ed >&2
            
            local term_w
            term_w=$(tput cols)
            
            local max_opt_w=0
            for opt in "${options[@]}"; do
                local lw
                lw=$(get_clean_len "$opt")
                [[ $lw -gt $max_opt_w ]] && max_opt_w=$lw
            done

            local bar_w=$((max_opt_w + 14))
            [[ -n "$BOX_WIDTH" && $bar_w -lt "$BOX_WIDTH" ]] && bar_w="$BOX_WIDTH"
            [[ $bar_w -gt $((term_w - 2)) ]] && bar_w=$((term_w - 2))
            [[ $bar_w -lt 40 ]] && bar_w=40
            
            bar_spacer=$(get_spacer "$bar_w")

            # 1. ASCII Header
            promptify_header >&2

            # 2. Title and separator
            center_print "\e[1;34m$title\e[0m" >&2
            draw_separator "$bar_w" "$bar_spacer" >&2
            
            # 3. Menu hints (Shortened to fit)
            center_print "\e[1;33m [ SPACE ]\e[0m Select | \e[1;33m[ ENTER ]\e[0m Start | \e[1;33m[ ESC ]\e[0m Back" >&2
            draw_separator "$bar_w" "$bar_spacer" >&2
            printf '\n' >&2
            tput sc >&2
            redraw=false
            last_cursor=-1
        fi

        if [[ $cursor -ne $last_cursor ]]; then
            tput rc >&2
            tput ed >&2

            local opt_block_w=$((max_opt_w + 7))
            local opt_spacer
            opt_spacer=$(get_spacer "$opt_block_w")

            for i in "${!options[@]}"; do
                draw_menu_item "${options[i]}" "$i" "$cursor" -1 "$opt_spacer" "checkbox" "${selected[i]}"
            done
            last_cursor=$cursor
        fi
        
        if ! IFS= read -rsn1 -r key; then
            cancelled=true
            break
        fi

        case "$key" in
            $'\x1b')
                read -rsn2 -t 0.05 key_ext
                if [[ -z "$key_ext" ]]; then
                    cancelled=true
                    break
                fi
                case "$key_ext" in
                    '[A'|'OA') 
                        ((cursor--)); [[ $cursor -lt 0 ]] && cursor=$((${#options[@]}-1)) 
                        [[ "$p_type" == "header" ]] && redraw=true
                        ;;
                    '[B'|'OB') 
                        ((cursor++)); [[ $cursor -ge ${#options[@]} ]] && cursor=0 
                        [[ "$p_type" == "header" ]] && redraw=true
                        ;;
                esac
                ;;
            " ")
                if [[ "${selected[cursor]}" == "true" ]]; then
                    selected[cursor]="false"
                else
                    selected[cursor]="true"
                fi
                last_cursor=-1 # Force redraw on toggle
                ;;
            "") confirmed=true ;;
        esac
    done

    eval "$old_trap"
    tput cnorm >&2
    [[ "$cancelled" == true ]] && { echo "CANCELLED"; return; }

    local result=""
    for i in "${!selected[@]}"; do
        [[ "${selected[i]}" == true ]] && result+="$i "
    done
    echo "$result"
}

radio_menu() {
    local title="$1"
    local header_info="$2"
    local preview_cmd="$3"
    local cursor="${4:-0}"
    local active_idx="${5:--1}"
    shift 5
    local options=("$@")
    local confirmed=false
    local cancelled=false

    tput civis >&2
    local p_type=""
    [[ -n "$preview_cmd" ]] && p_type=$($preview_cmd 0 "" "type")

    local bar_spacer=""
    local redraw=true
    local last_cursor=-1
    local old_trap
    old_trap=$(trap -p SIGWINCH)
    trap 'redraw=true; RESIZED=true' SIGWINCH

    while [[ "$confirmed" == false && "$cancelled" == false ]]; do
        if [[ "$redraw" == true ]]; then
            tput cup 0 0 >&2
            tput ed >&2

            local term_w
            term_w=$(tput cols)
            
            local max_opt_w=0
            for i in "${!options[@]}"; do
                local opt="${options[i]}"
                local lw
                lw=$(get_clean_len "$opt")
                [[ $lw -gt $max_opt_w ]] && max_opt_w=$lw
            done

            local bar_w=$((max_opt_w + 12))
            [[ -n "$BOX_WIDTH" && $bar_w -lt "$BOX_WIDTH" ]] && bar_w="$BOX_WIDTH"
            [[ $bar_w -gt $((term_w - 2)) ]] && bar_w=$((term_w - 2))
            [[ $bar_w -lt 40 ]] && bar_w=40
            
            bar_spacer=$(get_spacer "$bar_w")

            [[ "$p_type" != "header" ]] && promptify_header >&2

            center_print "\e[1;34m$title\e[0m" >&2
            draw_separator "$bar_w" "$bar_spacer" >&2

            if [[ -n "$header_info" ]]; then
                if declare -F "$header_info" >/dev/null 2>&1; then
                    "$header_info"
                    # Synchronize width
                    bar_w=${BOX_WIDTH:-$bar_w}
                    bar_spacer=$(get_spacer "$bar_w")
                else
                    center_print "$header_info" >&2
                fi
            fi
            
            if [[ "$p_type" == "header" ]]; then
                $preview_cmd "$cursor" "$bar_spacer" >&2
                printf '\n' >&2
            fi

            # Navigation hints
            center_print "\e[1;33m [ ARROWS ]\e[0m Nav | \e[1;33m[ ENTER ]\e[0m Select | \e[1;33m[ ESC ]\e[0m Back" >&2
            draw_separator "$bar_w" "$bar_spacer" >&2
            printf '\n' >&2

            tput sc >&2
            redraw=false
            last_cursor=-1 # Force full update of lower section
        fi

        # Only redraw the options and preview if the cursor changed or a full redraw was forced
        if [[ $cursor -ne $last_cursor ]]; then
            tput rc >&2
            tput ed >&2

            local opt_block_w=$((max_opt_w + 5))
            local opt_spacer
            opt_spacer=$(get_spacer "$opt_block_w")

            for i in "${!options[@]}"; do
                draw_menu_item "${options[i]}" "$i" "$cursor" "$active_idx" "$opt_spacer" "radio"
            done
            
            if [[ "$p_type" == "footer" && "${options[cursor]}" != "Back" ]]; then
                printf '\n' >&2
                draw_separator "$bar_w" "$bar_spacer" >&2
                center_print "\033[1;35mPREVIEW\033[0m" >&2
                draw_separator "$bar_w" "$bar_spacer" >&2
                printf '\n' >&2
                $preview_cmd "$cursor" "$bar_spacer" >&2
            fi
            last_cursor=$cursor
        fi

        if ! IFS= read -rsn1 -r key; then
            cancelled=true
            break
        fi

        case "$key" in
            $'\x1b')
                read -rsn2 -t 0.05 key_ext
                if [[ -z "$key_ext" ]]; then
                    cancelled=true
                    break
                fi
                case "$key_ext" in
                    '[A'|'OA') 
                        ((cursor--)); [[ $cursor -lt 0 ]] && cursor=$((${#options[@]}-1)) 
                        [[ "$p_type" == "header" ]] && redraw=true # Force redraw
                        ;;
                    '[B'|'OB') 
                        ((cursor++)); [[ $cursor -ge ${#options[@]} ]] && cursor=0 
                        [[ "$p_type" == "header" ]] && redraw=true # Force redraw
                        ;;
                esac
                ;;
            "") confirmed=true ;;
        esac
    done

    eval "$old_trap"
    tput cnorm >&2
    [[ "$cancelled" == true ]] && echo "CANCELLED" || echo "$cursor"
}
