#!/bin/bash
# Test: restart_shell reload flow (v1 restore + ORIGINAL_DIR cwd fix + guards).

PASS=0; FAIL=0
t() { if [[ "$1" == "$2" ]]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: $3 | expected '$2' got '$1'"; fi; }

HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../core/utils/prompts.sh"
source "$HERE/../core/utils/actions.sh"

CONFIRM_ALL=false
WORK=$(mktemp -d)
ORIG="$WORK/orig"; OTHER="$WORK/other"; mkdir -p "$ORIG" "$OTHER"

# Stub reload_shell: keep the real cd-back logic, replace only `exec zsh`
RELOAD_FLAG=""
reload_shell() {
    cd -- "${ORIGINAL_DIR:-$HOME}" 2>/dev/null
    RELOAD_FLAG="RELOAD pwd=$PWD"
    echo "$RELOAD_FLAG"
}
# Force interactive for tests that need the prompt path
is_interactive() { return 0; }

# --- Test 1: reload path (auto-confirm) starts in ORIGINAL_DIR ---
CONFIRM_ALL=true
ORIGINAL_DIR="$ORIG"; cd "$OTHER"
OUT1=$(restart_shell 2>&1 </dev/null)
echo "$OUT1" | grep -q "RELOAD pwd=$ORIG"; t "$?" "0" "reload in ORIGINAL_DIR"
echo "$OUT1" | grep -q "Restarting shell"; t "$?" "0" "restarting message"

# --- Test 2: N answer -> notice, no reload ---
CONFIRM_ALL=false
OUT2=$(printf 'n\n' | restart_shell 2>&1)
echo "$OUT2" | grep -q "Changes applied"; t "$?" "0" "N shows applied notice"
echo "$OUT2" | grep -q "RELOAD"; t "$?" "1" "N does not reload"

# --- Test 3: y answer -> reload ---
CONFIRM_ALL=false
OUT3=$(printf 'y\n' | restart_shell 2>&1)
echo "$OUT3" | grep -q "RELOAD"; t "$?" "0" "y reloads"

# --- Test 4: not interactive -> notice only, even if y is piped ---
is_interactive() { return 1; }
CONFIRM_ALL=false
OUT4=$(printf 'y\n' | restart_shell 2>&1)
echo "$OUT4" | grep -q "Changes applied"; t "$?" "0" "non-tty shows notice"
echo "$OUT4" | grep -q "RELOAD"; t "$?" "1" "non-tty does not reload"
is_interactive() { return 0; }

# --- Test 5: zsh missing -> notice only ---
mkdir -p "$WORK/emptybin"
OLD_PATH="$PATH"; PATH="$WORK/emptybin"
OUT5=$(printf 'y\n' | restart_shell 2>&1)
PATH="$OLD_PATH"
echo "$OUT5" | grep -q "Changes applied"; t "$?" "0" "no-zsh shows notice"
echo "$OUT5" | grep -q "RELOAD"; t "$?" "1" "no-zsh does not reload"

rm -rf "$WORK"
echo
echo "RESULT: $PASS pass, $FAIL fail"
[[ $FAIL -eq 0 ]]
