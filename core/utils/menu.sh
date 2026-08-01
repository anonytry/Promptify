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
    local is_disabled="${8:-false}"
    local status="${9:-}"
    
    # Status dot color map (green=installed, red=missing, amber=broken, dim green=outdated)
    local dot=""
    case "$status" in
        "ok")       dot=" \e[1;32m●\e[0m" ;;
        "missing")  dot=" \e[1;31m●\e[0m" ;;
        "broken")   dot=" \e[1;33m●\e[0m" ;;
        "outdated") dot=" \e[2;32m●\e[0m" ;;
    esac
    
    local content="$label"
    if [[ "$type" == "checkbox" ]]; then
        if [[ "$is_selected" == "true" ]]; then
            # Selected checkbox [X]
            if [[ $index -eq $cursor ]]; then
                printf '\033[2K\r%b \033[1;36m❯\033[0m [\033[1;32mX\033[0m] \033[1;36m%s\033[0m%b\n' "$spacer" "$label" "$dot" >&2
            else
                printf '\033[2K\r%b   [\033[1;32mX\033[0m] \033[2;37m%s\033[0m%b\n' "$spacer" "$label" "$dot" >&2
            fi
        else
            # Unselected checkbox [ ]
            if [[ $index -eq $cursor ]]; then
                printf '\033[2K\r%b \033[1;36m❯\033[0m [ ] \033[1;36m%s\033[0m%b\n' "$spacer" "$label" "$dot" >&2
            else
                printf '\033[2K\r%b   [ ] \033[2;37m%s\033[0m%b\n' "$spacer" "$label" "$dot" >&2
            fi
        fi
        return
    fi

    # Radio Logic
    if [[ "$is_disabled" == "true" ]]; then
        # Disabled (e.g. missing dependency) - dimmed, not navigable
        printf '\033[2K\r%b   \033[2;90m%s\033[0m\n' "$spacer" "$label" >&2
        return
    fi
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
    local status=()
    local cursor=0
    local confirmed=false
    local cancelled=false

    for i in "${!options[@]}"; do
        local opt="${options[i]}"
        if [[ "$opt" == *"|selected" ]]; then
            selected[i]=true
            opt="${opt%|selected}"
        else
            selected[i]=false
        fi
        # Optional status dot (installed / missing / broken / outdated)
        status[i]=""
        local st
        for st in ok missing broken outdated; do
            if [[ "$opt" == *"|$st" ]]; then
                status[i]="$st"
                opt="${opt%|$st}"
            fi
        done
        options[i]="$opt"
    done

    tput civis >&2
    local bar_spacer=""
    local redraw=true
    local last_cursor=-1
    local anchor_set=false
    local after_full=false
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
            # 3b. Status legend (only when any option carries a status dot)
            local has_status=false
            local st
            for st in "${status[@]}"; do
                [[ -n "$st" ]] && has_status=true
            done
            if [[ "$has_status" == "true" ]]; then
                center_print "\e[1;32m●\e[0m Installed  \e[1;31m●\e[0m Missing  \e[1;33m●\e[0m Broken  \e[2;32m●\e[0m Outdated" >&2
            fi
            draw_separator "$bar_w" "$bar_spacer" >&2
            printf '\n' >&2
            redraw=false
            last_cursor=-1
            after_full=true
        fi

        if [[ $cursor -ne $last_cursor ]]; then
            # Anchor back to the options block start using relative movement,
            # which stays correct even when the screen scrolled (menu taller than terminal).
            if [[ "$anchor_set" == true && "$after_full" == false ]]; then
                tput rc >&2
                tput cuu "${#options[@]}" >&2
            fi
            tput ed >&2

            local opt_block_w=$((max_opt_w + 7))
            local opt_spacer
            opt_spacer=$(get_spacer "$opt_block_w")

            for i in "${!options[@]}"; do
                draw_menu_item "${options[i]}" "$i" "$cursor" -1 "$opt_spacer" "checkbox" "${selected[i]}" "" "${status[i]}"
            done
            tput sc >&2
            anchor_set=true
            last_cursor=$cursor
            after_full=false
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
                        ;;
                    '[B'|'OB') 
                        ((cursor++)); [[ $cursor -ge ${#options[@]} ]] && cursor=0 
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

    # Parse disabled flags (e.g. "Label|disabled")
    local disabled=()
    for i in "${!options[@]}"; do
        if [[ "${options[i]}" == *"|disabled" ]]; then
            disabled[i]=true
            options[i]="${options[i]%|disabled}"
        else
            disabled[i]=false
        fi
    done

    # Never start on a disabled option
    while [[ "${disabled[$cursor]}" == "true" ]]; do
        ((cursor++)); [[ $cursor -ge ${#options[@]} ]] && cursor=0
    done

    tput civis >&2
    local p_type=""
    [[ -n "$preview_cmd" ]] && p_type=$($preview_cmd 0 "" "type")

    local bar_spacer=""
    local redraw=true
    local last_cursor=-1
    local anchor_set=false
    local after_full=false
    local last_footer_lines=0
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

            redraw=false
            last_cursor=-1 # Force full update of lower section
            after_full=true
        fi

        # Only redraw the options and preview if the cursor changed or a full redraw was forced
        if [[ $cursor -ne $last_cursor ]]; then
            # The anchor is saved at the very end of this block (after the footer
            # preview), so nothing is drawn after it and tput rc is always exact,
            # even when the menu is taller than the terminal and scrolling occurs.
            # Going up by (options + footer lines) lands exactly on the first option.
            if [[ "$anchor_set" == true && "$after_full" == false ]]; then
                tput rc >&2
                tput cuu $(( ${#options[@]} + last_footer_lines )) >&2
            fi
            tput ed >&2

            local opt_block_w=$((max_opt_w + 5))
            local opt_spacer
            opt_spacer=$(get_spacer "$opt_block_w")

            for i in "${!options[@]}"; do
                draw_menu_item "${options[i]}" "$i" "$cursor" "$active_idx" "$opt_spacer" "radio" "false" "${disabled[i]}"
            done

            last_footer_lines=0
            if [[ "$p_type" == "footer" && "${options[cursor]}" != "Back" ]]; then
                printf '\n' >&2
                draw_separator "$bar_w" "$bar_spacer" >&2
                center_print "\033[1;35mPREVIEW\033[0m" >&2
                draw_separator "$bar_w" "$bar_spacer" >&2
                printf '\n' >&2
                # Capture the preview to know exactly how many lines it occupies
                # (needed for the relative cuu anchor on the next redraw).
                local prev_out
                prev_out=$($preview_cmd "$cursor" "$bar_spacer" 2>&1)
                if [[ -n "$prev_out" ]]; then
                    printf '%s\n' "$prev_out" >&2
                    last_footer_lines=$(( 5 + $(printf '%s\n' "$prev_out" | wc -l) ))
                else
                    last_footer_lines=5
                fi
            fi
            tput sc >&2
            anchor_set=true
            last_cursor=$cursor
            after_full=false
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
                        while [[ "${disabled[$cursor]}" == "true" ]]; do
                            ((cursor--)); [[ $cursor -lt 0 ]] && cursor=$((${#options[@]}-1))
                        done
                        [[ "$p_type" == "header" ]] && redraw=true # Force redraw
                        ;;
                    '[B'|'OB') 
                        ((cursor++)); [[ $cursor -ge ${#options[@]} ]] && cursor=0 
                        while [[ "${disabled[$cursor]}" == "true" ]]; do
                            ((cursor++)); [[ $cursor -ge ${#options[@]} ]] && cursor=0
                        done
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
