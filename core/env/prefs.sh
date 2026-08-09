#!/bin/bash

# Preferences live in userdata/prefs.conf (never touched by updates).
# Reading falls back to the legacy ~/.username during/after migration.

get_pref() {
    local key="$1" file="$2" default="$3"
    local val
    val=$(grep "^${key}=" "$file" 2>/dev/null | head -1 | cut -d= -f2- | sed 's/^"//;s/"$//')
    echo "${val:-$default}"
}

# Upsert a KEY="value" line in prefs.conf without clobbering other keys.
set_pref() {
    local key="$1" value="$2"
    mkdir -p "$PFY_USERDATA"
    [[ -f "$PFY_PREFS" ]] || { echo "" > "$PFY_PREFS"; chmod 600 "$PFY_PREFS" 2>/dev/null; }
    if grep -q "^${key}=" "$PFY_PREFS" 2>/dev/null; then
        awk -v k="$key" -v v="$value" '
            BEGIN { done = 0 }
            $0 ~ "^" k "=" { printf "%s=\"%s\"\n", k, v; done = 1; next }
            { print }
            END { if (!done) printf "%s=\"%s\"\n", k, v }
        ' "$PFY_PREFS" > "$PFY_PREFS.tmp"
        mv "$PFY_PREFS.tmp" "$PFY_PREFS"
    else
        echo "$key=\"$value\"" >> "$PFY_PREFS"
    fi
}

# shellcheck disable=SC2034
load_prefs() {
    local prefs_file="$PFY_PREFS"
    [[ -f "$prefs_file" ]] || prefs_file="$HOME/.username"

    if [[ -f "$prefs_file" ]]; then
        BANNER_NAME=$(get_pref NAME "$prefs_file" "Promptify")
        CUR_FONT=$(get_pref FONT "$prefs_file" "random")
        CUR_CAT_STYLE=$(get_pref CAT "$prefs_file" "full")
        CUR_PROMPT_STYLE=$(get_pref STYLE "$prefs_file" "parrot")
        CUR_CHANNEL=$(get_pref CHANNEL "$prefs_file" "")
        SKIP_P10K=$(get_pref SKIP_P10K "$prefs_file" "false")

        local b t
        b=$(get_pref THEME_BORDER "$prefs_file" "")
        t=$(get_pref THEME_TAG "$prefs_file" "")
        [[ -n "$b" ]] && CUR_THEME_BORDER="$b"
        [[ -n "$t" ]] && CUR_THEME_TAG="$t"
        [[ -z "$CUR_CHANNEL" ]] && CUR_CHANNEL=$(resolve_channel)
    fi

    local is_installed=false
    is_promptify_installed && is_installed=true

    if [[ "$is_installed" == "true" ]]; then
        [[ ! -f "$HOME/.draw" ]] && USE_BANNER="false" || USE_BANNER="true"
    else
        # First run defaults: always enable banner
        USE_BANNER="true"
    fi

    # Theme index for menus, derived from the border/tag prefs
    if [[ "$CUR_THEME_BORDER" == "cyan" && "$CUR_THEME_TAG" == "blue" ]]; then CUR_THEME_IDX=0
    elif [[ "$CUR_THEME_BORDER" == "magenta" && "$CUR_THEME_TAG" == "cyan" ]]; then CUR_THEME_IDX=1
    elif [[ "$CUR_THEME_BORDER" == "green" && "$CUR_THEME_TAG" == "green" ]]; then CUR_THEME_IDX=2
    elif [[ "$CUR_THEME_BORDER" == "yellow" && "$CUR_THEME_TAG" == "white" ]]; then CUR_THEME_IDX=3
    elif [[ "$CUR_THEME_BORDER" == "red" && "$CUR_THEME_TAG" == "blue" ]]; then CUR_THEME_IDX=4
    fi
}
