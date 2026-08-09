#!/bin/bash

# APK/AOSP-style ~/.promptify layout (v2, introduced in 1.5.0).
# Every directory has a fixed job, and updates never cross-write between them:
#
#   core/     the program (a full git clone). Update = archive + rm -rf + fresh.
#   deps/     oh-my-zsh + helper plugins. Write-once, updates never touch.
#   userdata/ user preferences (prefs.conf). Never touched by updates.
#   runtime/  generated shell configs (zshrc/bashrc). Regenerated on every apply.
#   backup/   system/  = 1st-install snapshot (MANIFEST + originals) + self-contained uninstaller
#             archives/ = tarballs of older core/ versions (for downgrade)
#
# The user's real ~/.zshrc is a single guarded source line into runtime/zshrc,
# and the pre-install config is snapshotted into backup/system/ so uninstall can
# restore the machine exactly ("time travel").

PFY_SYS_DIR="${SYS_DIR:-$HOME/.promptify}"

PFY_CORE="$PFY_SYS_DIR/core"
PFY_DEPS="$PFY_SYS_DIR/deps"
PFY_DEPS_OMZ="$PFY_DEPS/oh-my-zsh"
PFY_DEPS_PLUGINS="$PFY_DEPS/plugins"

PFY_USERDATA="$PFY_SYS_DIR/userdata"
PFY_PREFS="$PFY_USERDATA/prefs.conf"

PFY_RUNTIME="$PFY_SYS_DIR/runtime"
PFY_RUNTIME_ZSHRC="$PFY_RUNTIME/zshrc"
PFY_RUNTIME_BASHRC="$PFY_RUNTIME/bashrc"

PFY_BACKUP="$PFY_SYS_DIR/backup"
PFY_BACKUP_SYSTEM="$PFY_BACKUP/system"
PFY_BACKUP_FILES="$PFY_BACKUP_SYSTEM/files"
PFY_BACKUP_FIGLET="$PFY_BACKUP_SYSTEM/figlet"
PFY_MANIFEST="$PFY_BACKUP_SYSTEM/MANIFEST"
PFY_BACKUP_ARCHIVES="$PFY_BACKUP/archives"
PFY_UNINSTALLER="$PFY_BACKUP/uninstall.sh"

PFY_STATE="$PFY_SYS_DIR/.install-state"

# Legacy inline-block markers (pre-1.5.0 installs) — still recognised for
# detection and migration, never written anymore.
PFY_MARKER_ZSH="# --- Promptify Config ---"
PFY_MARKER_END="# --- End Promptify Config ---"

# The exact managed line(s) placed into the real profiles. Everything else in
# those files belongs to the user and is preserved (merged) on uninstall.
PFY_PROFILE_ZSHRC='source ~/.promptify/runtime/zshrc 2>/dev/null'
PFY_PROFILE_BASHRC='source ~/.promptify/runtime/bashrc 2>/dev/null'
PFY_PROFILE_COMMENT='# Promptify — managed shell config (remove with: promptify → Uninstall)'

export PFY_SYS_DIR PFY_CORE PFY_DEPS PFY_DEPS_OMZ PFY_DEPS_PLUGINS \
       PFY_USERDATA PFY_PREFS PFY_RUNTIME PFY_RUNTIME_ZSHRC PFY_RUNTIME_BASHRC \
       PFY_BACKUP PFY_BACKUP_SYSTEM PFY_BACKUP_FILES PFY_BACKUP_FIGLET \
       PFY_MANIFEST PFY_BACKUP_ARCHIVES PFY_UNINSTALLER PFY_STATE
