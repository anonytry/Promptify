#!/bin/bash
# Test harness: pkgs.sh failure handling (no-sudo, admin probe, dep propagation, power tools)
# Each test runs in a fresh bash -c so mocks don't leak between scenarios.

HERE="$(cd "$(dirname "$0")" && pwd)"
PKGS_SH="$HERE/../core/install/pkgs.sh"
export PKGS_SH

PASS=0
FAIL=0

# run <expect_rc> <expect_substr> <script...>
run() {
    local expect_rc="$1"; local expect_sub="$2"; shift 2
    local out rc
    out=$(bash -c "$1" 2>&1); rc=$?
    if [[ "$rc" -eq "$expect_rc" ]] && [[ -n "$expect_sub" ]]; then
        if grep -qF "$expect_sub" <<<"$out"; then
            PASS=$((PASS+1)); echo "PASS: $2"
            return
        fi
        FAIL=$((FAIL+1)); echo "FAIL: $2 (rc=$rc ok, but missing '$expect_sub')"
        echo "$out"
        return
    fi
    if [[ "$rc" -ne "$expect_rc" ]]; then
        FAIL=$((FAIL+1)); echo "FAIL: $2 (expected rc=$expect_rc, got rc=$rc)"
        echo "$out"
    else
        PASS=$((PASS+1)); echo "PASS: $2 (rc=$rc, contains '$expect_sub')"
    fi
}

STUB_SOURCE='source "$PKGS_SH";
id() { echo 1000; }
sudo() {
    local rc=0
    case "$1" in
        -v) rc=${SUDO_V_RC:-0} ;;
        *)  "$@" ;;
    esac
    return $rc
}
sudo_notice() { :; }
is_installed() { return ${IS_MISSING:-1}; }'

# T1: system PM + non-root + no sudo -> loud error, rc=1
run 1 "no 'sudo' or 'doas' was found" '
source "$PKGS_SH"; id() { echo 1000; }; sudo_notice() { :; }
PKG_MNGR=pacman; SUDO=""; OS_TYPE=linux
install_dependencies; exit $?'

# T2: system PM + sudo probe fails -> admin error, rc=1
run 1 "Admin (sudo) access is required" '
source "$PKGS_SH"; id() { echo 1000; }; sudo_notice() { :; }
sudo() { return 1; }
PKG_MNGR=apt; SUDO=sudo; OS_TYPE=linux; CONFIRM_ALL=true
install_dependencies; exit $?'

# T3: all packages install ok -> rc=0, no failure banner
run 0 "ALL PACKAGES OK" '
source "$PKGS_SH"; id() { echo 1000; }; sudo_notice() { :; }
sudo() { case "$1" in -v) return 0;; *) "$@";; esac; }
apt() { case "$1" in update) :;; install) :;; esac }
is_installed() { return 1; }
PKG_MNGR=apt; SUDO=sudo; OS_TYPE=linux; CONFIRM_ALL=true
install_dependencies && echo "ALL PACKAGES OK"; exit $?'

# T4: required pkg (figlet) install fails -> dep_failed -> rc=1, messages
run 1 "Failed to install 'figlet'" '
source "$PKGS_SH"; id() { echo 1000; }; sudo_notice() { :; }
sudo() { case "$1" in -v) return 0;; *) "$@";; esac; }
apt() { if [[ "$1" == "install" && "$2" == "figlet" ]]; then return 1; fi; return 0; }
is_installed() { return 1; }
PKG_MNGR=apt; SUDO=sudo; OS_TYPE=linux; CONFIRM_ALL=true
install_dependencies; exit $?'

# T5: required pkg failure summary line present
run 1 "Some required packages failed to install" '
source "$PKGS_SH"; id() { echo 1000; }; sudo_notice() { :; }
sudo() { case "$1" in -v) return 0;; *) "$@";; esac; }
apt() { if [[ "$1" == "install" && "$2" == "zsh" ]]; then return 1; fi; return 0; }
is_installed() { return 1; }
PKG_MNGR=apt; SUDO=sudo; OS_TYPE=linux; CONFIRM_ALL=true
install_dependencies; exit $?'

# T6: unknown PM -> loud error, rc=1 (even though all "installed")
run 1 "No installer known" '
source "$PKGS_SH"; id() { echo 1000; }; sudo_notice() { :; }
is_installed() { return 1; }
PKG_MNGR=unknown; SUDO=""; OS_TYPE=linux; CONFIRM_ALL=true
install_dependencies; exit $?'

# T7: install_power_tools fails on bat -> rc=1
run 1 "Failed to install 'bat'" '
source "$PKGS_SH"; sudo_notice() { :; }
apt() { if [[ "$1" == "install" && "$2" == "bat" ]]; then return 1; fi; return 0; }
is_installed() { return 1; }
PKG_MNGR=apt; SUDO=sudo; OS_TYPE=linux
install_power_tools; exit $?'

# T8: install_power_tools all ok -> rc=0
run 0 "Eza/Exa already present" '
source "$PKGS_SH"; sudo_notice() { :; }
is_installed() { case "$1" in eza|exa|bat|batcat) return 0;; *) return 1;; esac; }
PKG_MNGR=apt; SUDO=sudo; OS_TYPE=linux
install_power_tools; exit $?'

# T9: xbps install succeeds -> rc=0 (Void)
run 0 "CMD=-y figlet" '
source "$PKGS_SH"; sudo_notice() { :; }
id() { echo 1000; }
sudo() { case "$1" in -v) return 0;; *) "$@";; esac; }
xbps-install() { echo "CMD=$*"; return 0; }
is_installed() { return 1; }
PKG_MNGR=xbps; SUDO=sudo; OS_TYPE=void; CONFIRM_ALL=true
install_dependencies; exit $?'

# T10: xbps install fails -> rc=1 with message
run 1 "Failed to install 'zsh'" '
source "$PKGS_SH"; sudo_notice() { :; }
id() { echo 1000; }
sudo() { case "$1" in -v) return 0;; *) "$@";; esac; }
xbps-install() { if [[ "$2" == "zsh" ]]; then return 1; fi; return 0; }
is_installed() { return 1; }
PKG_MNGR=xbps; SUDO=sudo; OS_TYPE=void; CONFIRM_ALL=true
install_dependencies; exit $?'

# T11: slackpkg install works -> rc=0 (Slackware), non-interactive flags used
run 0 "CMD=-batch=on -default_answer=y install figlet" '
source "$PKGS_SH"; sudo_notice() { :; }
id() { echo 1000; }
sudo() { case "$1" in -v) return 0;; *) "$@";; esac; }
slackpkg() { echo "CMD=$*"; return 0; }
is_installed() { return 1; }
PKG_MNGR=slackpkg; SUDO=sudo; OS_TYPE=slackware; CONFIRM_ALL=true
install_dependencies; exit $?'

# T12: slackpkg install fails -> rc=1 with message
run 1 "Failed to install 'git'" '
source "$PKGS_SH"; sudo_notice() { :; }
id() { echo 1000; }
sudo() { case "$1" in -v) return 0;; *) "$@";; esac; }
slackpkg() { if [[ "$4" == "git" ]]; then return 1; fi; return 0; }
is_installed() { return 1; }
PKG_MNGR=slackpkg; SUDO=sudo; OS_TYPE=slackware; CONFIRM_ALL=true
install_dependencies; exit $?'

echo
echo "=== $PASS passed, $FAIL failed ==="
exit $(( FAIL > 0 ))
