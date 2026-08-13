#!/bin/bash

# Doctor: 5-point verification of a Promptify install. Reports PASS/FAIL for
# each check and offers a quick fix where one exists.

doctor_menu() {
    clear
    promptify_header
    echo -e "\n\e[1;34m[*] Promptify Doctor — installation health check\e[0m"
    echo

    local pass=0 fail=0 note=0

    # 1. Layout / migration state
    if is_legacy_layout && [[ ! -f "$PFY_MANIFEST" ]]; then
        note=$((note + 1))
        echo -e " \e[1;33m[o]\e[0m Layout: \e[1;33mlegacy\e[0m — migrating to the new layout is recommended."
    elif [[ -f "$PFY_MANIFEST" ]]; then
        pass=$((pass + 1))
        echo -e " \e[1;32m[✔]\e[0m Layout: \e[1;32mnew (APK-style)\e[0m — $PFY_SYS_DIR"
    else
        fail=$((fail + 1))
        echo -e " \e[1;31m[✘]\e[0m Layout: \e[1;31mnot installed\e[0m — run Quick Setup first."
    fi

    # 2. Snapshot integrity (every captured file must exist in backup/system/files)
    if [[ -f "$PFY_MANIFEST" ]]; then
        local missing=0 total=0 kind path rel
        while IFS='|' read -r kind path rel _; do
            [[ "$kind" == "P" ]] || continue
            total=$((total + 1))
            [[ -f "$PFY_BACKUP_FILES/$rel" ]] || missing=$((missing + 1))
        done < "$PFY_MANIFEST"
        if [[ "$total" -eq 0 ]]; then
            pass=$((pass + 1))
            echo -e " \e[1;32m[✔]\e[0m Snapshot: \e[1;32mok\e[0m (nothing captured — fresh profile)"
        elif [[ "$missing" -eq 0 ]]; then
            pass=$((pass + 1))
            echo -e " \e[1;32m[✔]\e[0m Snapshot: \e[1;32mok\e[0m ($total original files backed up)"
        else
            fail=$((fail + 1))
            echo -e " \e[1;31m[✘]\e[0m Snapshot: \e[1;31m$missing of $total original files missing\e[0m — uninstall will be incomplete."
        fi
    fi

    # 3. Runtime shell config
    if [[ -f "$PFY_RUNTIME/zshrc" ]]; then
        if zsh -n "$PFY_RUNTIME/zshrc" &>/dev/null; then
            pass=$((pass + 1))
            echo -e " \e[1;32m[✔]\e[0m Runtime: \e[1;32mok\e[0m ($PFY_RUNTIME/zshrc)"
        else
            fail=$((fail + 1))
            echo -e " \e[1;31m[✘]\e[0m Runtime: \e[1;31mzsh syntax error\e[0m — re-run 'Reload & Apply UI'."
        fi
    else
        fail=$((fail + 1))
        echo -e " \e[1;31m[✘]\e[0m Runtime: \e[1;31mmissing\e[0m — re-run 'Reload & Apply UI'."
    fi

    # 4. Dependencies (bundled deps/)
    local deps_ok=false
    if [[ -d "$PFY_DEPS_PLUGINS" && -f "$PFY_DEPS_OMZ/oh-my-zsh.sh" ]]; then
        deps_ok=true
    elif [[ -f "/usr/share/oh-my-zsh/oh-my-zsh.sh" ]]; then
        deps_ok=true
    fi
    if [[ "$deps_ok" == "true" ]]; then
        pass=$((pass + 1))
        echo -e " \e[1;32m[✔]\e[0m Dependencies: \e[1;32mok\e[0m (Oh-My-Zsh + plugins)"
    else
        fail=$((fail + 1))
        echo -e " \e[1;31m[✘]\e[0m Dependencies: \e[1;31mincomplete\e[0m — run 'Dependencies' → Install."
    fi

    # 5. Managed profile line + global binary
    if grep -q "promptify/runtime/zshrc" "$HOME/.zshrc" 2>/dev/null; then
        pass=$((pass + 1))
        echo -e " \e[1;32m[✔]\e[0m Profile: \e[1;32mmanaged line present\e[0m in ~/.zshrc"
    else
        fail=$((fail + 1))
        echo -e " \e[1;31m[✘]\e[0m Profile: \e[1;31m~/.zshrc not managed\e[0m — re-run 'Reload & Apply UI'."
    fi

    if [[ -x "$PREFIX/bin/promptify" || -x "/usr/local/bin/promptify" ]]; then
        pass=$((pass + 1))
        echo -e " \e[1;32m[✔]\e[0m Binary: \e[1;32mok\e[0m (global 'promptify' available)"
    else
        fail=$((fail + 1))
        echo -e " \e[1;31m[✘]\e[0m Binary: \e[1;31m'promptify' command not installed\e[0m."
    fi

    # Junk check
    local junk=()
    [[ -e "$HOME/.zshrc.pre-promptify" ]] && junk+=("~/.zshrc.pre-promptify")
    [[ -e "$HOME/.promptify_font.flf" ]] && junk+=("~/.promptify_font.flf")
    if [[ ${#junk[@]} -gt 0 ]]; then
        note=$((note + 1))
        echo -e " \e[1;33m[o]\e[0m Junk: leftover files found — ${junk[*]}"
    fi

    echo
    echo -e " \e[1;36mResult:\e[0m \e[1;32m$pass passed\e[0m, \e[1;31m$fail failed\e[0m, \e[1;33m$note noted\e[0m"

    if [[ "$fail" -gt 0 ]]; then
        echo
        if confirm_action "Try to fix the failing checks now?" "n"; then
            refresh_ui
            center_print "\e[1;32m[✔] Repair attempt complete. Run Doctor again to re-verify.\e[0m"
        fi
    fi
    press_enter
}
