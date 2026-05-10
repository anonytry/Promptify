#!/bin/bash

# shellcheck disable=SC2034
load_prefs() {
    # Check if already installed via markers
    local is_installed=false
    is_promptify_installed && is_installed=true

    if [[ -f ~/.username ]]; then
        BANNER_NAME=$(grep "^NAME=" ~/.username | cut -d= -f2- | sed 's/^"//;s/"$//')
        CUR_FONT=$(grep "^FONT=" ~/.username | cut -d= -f2- | sed 's/^"//;s/"$//')
        [[ -z "$BANNER_NAME" ]] && BANNER_NAME="Promptify"
        [[ -z "$CUR_FONT" ]] && CUR_FONT="auto"
    fi
    
    if [[ "$is_installed" == "true" ]]; then
        [[ ! -f "$HOME/.draw" ]] && USE_BANNER="false" || USE_BANNER="true"
    else
        # First run defaults: Always enable banner
        USE_BANNER="true"
    fi
    
    if [[ -f ~/.zshrc ]]; then
        local b_clr
        b_clr=$(grep "^P_CLR_BORDER=" ~/.zshrc | cut -d= -f2- | sed 's/^"//;s/"$//')
        local t_clr
        t_clr=$(grep "^P_CLR_TAG=" ~/.zshrc | cut -d= -f2- | sed 's/^"//;s/"$//')
        [[ -n "$b_clr" ]] && CUR_THEME_BORDER="$b_clr"
        [[ -n "$t_clr" ]] && CUR_THEME_TAG="$t_clr"

        # Auto-detect current theme index if possible
        if [[ "$CUR_THEME_BORDER" == "cyan" && "$CUR_THEME_TAG" == "blue" ]]; then CUR_THEME_IDX=0
        elif [[ "$CUR_THEME_BORDER" == "magenta" && "$CUR_THEME_TAG" == "cyan" ]]; then CUR_THEME_IDX=1
        elif [[ "$CUR_THEME_BORDER" == "green" && "$CUR_THEME_TAG" == "green" ]]; then CUR_THEME_IDX=2
        elif [[ "$CUR_THEME_BORDER" == "yellow" && "$CUR_THEME_TAG" == "white" ]]; then CUR_THEME_IDX=3
        elif [[ "$CUR_THEME_BORDER" == "red" && "$CUR_THEME_TAG" == "blue" ]]; then CUR_THEME_IDX=4
        fi
    fi
}
