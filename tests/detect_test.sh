#!/bin/bash
# Test harness: detect.sh package-manager detection (os-release parsing + binary fallback)

HERE="$(cd "$(dirname "$0")" && pwd)"
DETECT_SH="$HERE/../core/env/detect.sh"
export DETECT_SH

PASS=0
FAIL=0

run() {
    local name="$1"; local expect_pm="$2"; local expect_os="$3"; local script="$4"
    local out rc
    out=$(bash -c "$script" 2>&1); rc=$?
    if [[ "$rc" -eq 0 ]] && grep -qF "PM=$expect_pm OS=$expect_os" <<<"$out"; then
        PASS=$((PASS+1)); echo "PASS: $name"
    else
        FAIL=$((FAIL+1)); echo "FAIL: $name (expected PM=$expect_pm OS=$expect_os)"
        echo "$out"
    fi
}

# --- os-release parsing via detect_from_os_release ---
REL="$HERE/dfr_osrel"

# T1: standard Arch
printf 'NAME="Arch Linux"\nID=arch\nPRETTY_NAME="Arch Linux"\n' > "$REL"
run "standard Arch os-release" "pacman" "arch" '
source "$DETECT_SH"
detect_from_os_release "'"$REL"'"
echo "PM=$PKG_MNGR OS=$OS_TYPE"'

# T2: quoted ID (custom/minimal builds)
printf 'ID="arch"\n' > "$REL"
run "quoted ID=arch" "pacman" "arch" '
source "$DETECT_SH"
detect_from_os_release "'"$REL"'"
echo "PM=$PKG_MNGR OS=$OS_TYPE"'

# T3: Arch-based distro (ID=endeavouros, ID_LIKE=arch)
printf 'ID=endeavouros\nID_LIKE=arch\n' > "$REL"
run "ID_LIKE=arch (EndeavourOS)" "pacman" "arch" '
source "$DETECT_SH"
detect_from_os_release "'"$REL"'"
echo "PM=$PKG_MNGR OS=$OS_TYPE"'

# T4: Ubuntu
printf 'ID=ubuntu\n' > "$REL"
run "Ubuntu os-release" "apt" "debian" '
source "$DETECT_SH"
detect_from_os_release "'"$REL"'"
echo "PM=$PKG_MNGR OS=$OS_TYPE"'

# T5: unrecognized ID
printf 'ID=some-unknown-distro\n' > "$REL"
run "unrecognized os-release -> unknown" "unknown" "linux" '
source "$DETECT_SH"
detect_from_os_release "'"$REL"'"
echo "PM=$PKG_MNGR OS=$OS_TYPE"'

# T5b: Void Linux
printf 'NAME="Void"\nID=void\nPRETTY_NAME="Void Linux"\n' > "$REL"
run "Void Linux os-release" "xbps" "void" '
source "$DETECT_SH"
detect_from_os_release "'"$REL"'"
echo "PM=$PKG_MNGR OS=$OS_TYPE"'

# T5c: Slackware
printf 'NAME="Slackware"\nID=slackware\nPRETTY_NAME="Slackware 15.0"\n' > "$REL"
run "Slackware os-release" "slackpkg" "slackware" '
source "$DETECT_SH"
detect_from_os_release "'"$REL"'"
echo "PM=$PKG_MNGR OS=$OS_TYPE"'

rm -f "$REL"

# --- binary fallback via detect_pm_from_binaries ---
# The host already has pacman/apt-get on PATH, so shadow `command` to only
# "see" binaries in a fake dir, isolating each candidate.
COMMAND_MOCK='command() {
    if [[ "$1" == "-v" ]]; then
        [[ -x "$CM_DIR/$2" ]] && { echo "$CM_DIR/$2"; return 0; } || return 1
    fi
    return 1
}'

# T6: pacman only -> pacman/arch
CM_DIR="$HERE/cm_pacman"; mkdir -p "$CM_DIR"; ln -sf /bin/true "$CM_DIR/pacman"; export CM_DIR
run "binary fallback pacman" "pacman" "arch" '
source "$DETECT_SH"
PKG_MNGR="unknown"; OS_TYPE="linux"
'"$COMMAND_MOCK"'
detect_pm_from_binaries
echo "PM=$PKG_MNGR OS=$OS_TYPE"'
rm -rf "$CM_DIR"; unset CM_DIR

# T7: apt-get only -> apt/debian
CM_DIR="$HERE/cm_apt"; mkdir -p "$CM_DIR"; ln -sf /bin/true "$CM_DIR/apt-get"; export CM_DIR
run "binary fallback apt-get" "apt" "debian" '
source "$DETECT_SH"
PKG_MNGR="unknown"; OS_TYPE="linux"
'"$COMMAND_MOCK"'
detect_pm_from_binaries
echo "PM=$PKG_MNGR OS=$OS_TYPE"'
rm -rf "$CM_DIR"; unset CM_DIR

# T8: dnf only -> dnf/fedora
CM_DIR="$HERE/cm_dnf"; mkdir -p "$CM_DIR"; ln -sf /bin/true "$CM_DIR/dnf"; export CM_DIR
run "binary fallback dnf" "dnf" "fedora" '
source "$DETECT_SH"
PKG_MNGR="unknown"; OS_TYPE="linux"
'"$COMMAND_MOCK"'
detect_pm_from_binaries
echo "PM=$PKG_MNGR OS=$OS_TYPE"'
rm -rf "$CM_DIR"; unset CM_DIR

# T8b: xbps-install only -> xbps/void
CM_DIR="$HERE/cm_xbps"; mkdir -p "$CM_DIR"; ln -sf /bin/true "$CM_DIR/xbps-install"; export CM_DIR
run "binary fallback xbps-install" "xbps" "void" '
source "$DETECT_SH"
PKG_MNGR="unknown"; OS_TYPE="linux"
'"$COMMAND_MOCK"'
detect_pm_from_binaries
echo "PM=$PKG_MNGR OS=$OS_TYPE"'
rm -rf "$CM_DIR"; unset CM_DIR

# T8c: slackpkg only -> slackpkg/slackware
CM_DIR="$HERE/cm_slackpkg"; mkdir -p "$CM_DIR"; ln -sf /bin/true "$CM_DIR/slackpkg"; export CM_DIR
run "binary fallback slackpkg" "slackpkg" "slackware" '
source "$DETECT_SH"
PKG_MNGR="unknown"; OS_TYPE="linux"
'"$COMMAND_MOCK"'
detect_pm_from_binaries
echo "PM=$PKG_MNGR OS=$OS_TYPE"'
rm -rf "$CM_DIR"; unset CM_DIR

# T9: no pm binary -> stays unknown
CM_DIR="$HERE/cm_none"; mkdir -p "$CM_DIR"; export CM_DIR
run "no pm binary stays unknown" "unknown" "linux" '
source "$DETECT_SH"
PKG_MNGR="unknown"; OS_TYPE="linux"
'"$COMMAND_MOCK"'
detect_pm_from_binaries
echo "PM=$PKG_MNGR OS=$OS_TYPE"'
rm -rf "$CM_DIR"; unset CM_DIR

echo
echo "=== $PASS passed, $FAIL failed ==="
exit $(( FAIL > 0 ))
