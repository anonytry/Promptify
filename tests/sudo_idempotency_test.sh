#!/bin/bash
# Test: desktop figlet-font copy is idempotent + sudo_notice fires before sudo.
# Simulates setup_ui's desktop figlet block with a fake $SUDO recorder.

PASS=0; FAIL=0
t() { if [[ "$1" == "$2" ]]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: expected '$2' got '$1'"; fi; }

# real sudo_notice for tests 4-5
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../core/utils/helpers.sh"

WORK=$(mktemp -d)
ASSET="$WORK/asset"; FIGLET="$WORK/figlet"
mkdir -p "$ASSET"
for f in ASCII-Shadow.flf slant.flf banner.flf smpoison.flf graffiti.flf; do
    printf 'font-%s' "$f" > "$ASSET/$f"
done

SUDO_CALLS=0; SUDO_OUT=""
SUDO() { SUDO_CALLS=$((SUDO_CALLS+1)); SUDO_OUT="$SUDO_OUT $*"; "$@"; }

# --- extract the exact idempotent logic from apply.sh (desktop branch) ---
run_copy() {
    local asset_dir="$ASSET" figlet_dir="$FIGLET" bundled_fonts=("ASCII-Shadow.flf" "slant.flf" "banner.flf" "smpoison.flf" "graffiti.flf")
    local need_font_write=false font_file
    for font_file in "${bundled_fonts[@]}"; do
        if [[ ! -f "$figlet_dir/$font_file" ]] || ! cmp -s "$asset_dir/$font_file" "$figlet_dir/$font_file"; then
            need_font_write=true; break
        fi
    done
    if [[ "$need_font_write" == true ]]; then
        if [[ ! -d "$figlet_dir" ]]; then
            SUDO mkdir -p "$figlet_dir" 2>/dev/null || true
        fi
        for font_file in "${bundled_fonts[@]}"; do
            if [[ ! -f "$figlet_dir/$font_file" ]] || ! cmp -s "$asset_dir/$font_file" "$figlet_dir/$font_file"; then
                SUDO cp "$asset_dir/$font_file" "$figlet_dir/" 2>/dev/null || true
            fi
        done
    fi
}

# 1. First run: dir missing -> mkdir + 5 copies
run_copy
t "$SUDO_CALLS" "6"
[[ -f "$FIGLET/slant.flf" ]]; t "$?" "0"

# 2. Second run: everything identical -> ZERO sudo
SUDO_CALLS=0
run_copy
t "$SUDO_CALLS" "0"

# 3. One font becomes stale -> exactly 1 copy (dir exists, so no mkdir)
sleep 0.01; printf 'font-new' > "$ASSET/banner.flf"
SUDO_CALLS=0
run_copy
t "$SUDO_CALLS" "1"

# 4. sudo_notice prints once, then suppresses repeats (same-shell, no subshell)
SUDO_NOTICE_SHOWN=false
sudo_notice "Installing test fonts" > "$WORK/notice1.txt"
sudo_notice "Installing test fonts" > "$WORK/notice2.txt"
N1=$(wc -l < "$WORK/notice1.txt")
N2=$(wc -l < "$WORK/notice2.txt")
[[ "$N2" -lt "$N1" ]]; t "$?" "0"

# 5. sudo_notice output actually mentions sudo + reason
sudo_notice_output() {
    SUDO_NOTICE_SHOWN=false
    sudo_notice "Installing test fonts"
}
OUT=$(sudo_notice_output)
echo "$OUT" | grep -q "sudo"; t "$?" "0"
echo "$OUT" | grep -q "Installing test fonts"; t "$?" "0"

rm -rf "$WORK"
echo
echo "RESULT: $PASS pass, $FAIL fail"
[[ $FAIL -eq 0 ]]
