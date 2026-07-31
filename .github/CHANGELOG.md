# Changelog

All notable changes to this project will be documented in this file.

## [1.2.0] - 2026-07-31

### Added
- **Cat Display Style**: New Customization option to toggle bat's display (Full / Filename only / Lines only / Plain). Disabled with a note when bat isn't installed.
- **Disabled Menu Items**: `radio_menu` now supports disabled options that are dimmed and skipped during navigation.
- **Others (Eza, Bat)**: New Dependencies option to install optional power tools skipped during setup.
- **Nerd Font Auto-Apply**: Installs JetBrainsMono Nerd Font on desktop and applies it in Kitty, Alacritty, GNOME Terminal, Konsole, and XFCE4 Terminal.
- **Live Install Output**: Installers now show live progress by default; output is only hidden with `--silent`.

### Fixed
- **Nerd Font Icons**: Replaced `font.ttf` with JetBrainsMono Nerd Font so `ls`/eza icons render correctly on Termux and PC.
- **dnf Update Check**: No longer fails the dependency step when no updates are available.

---

## [1.1.1] - 2026-07-31

### Added
- **Update Channels**: Choose between Stable and Testing update channels at first run or from the Updates menu, with channel-aware bootstrap (`--channel` flag supported).

### Fixed
- **Bootstrap cd Error**: Silenced the `/proc/<pid>/fd: No such file or directory` warning that appeared when running via `bash <(curl ...)`.
- **lolcat on Termux**: Gem install failed with "OpenSSL is not available". Now installs `openssl` first and reinstalls Ruby if it can't load OpenSSL.

---

## [1.1.0] - 2026-06-08

### Added
- **Pro-Cat Integration**: Replaced standard `cat` with `bat` (or `batcat` on PC) using a professional `full` style (Grid, Header, Line Numbers).
- **Dual Shell Support**: Configuration now applies consistently to both `.zshrc` and `.bashrc`.
- **Auto-Sync Engine**: Changes in the local repository are now automatically synced to the system directory (`~/.promptify`) during "Reload & Apply UI" or "Updates".
- **Global Command**: Promptify can now be installed as a system package. Use the `promptify`, `Promptify`, or `pty` command from any directory.
- **Persistent Installation**: Repository now migrates to `~/.promptify` for permanent system access.
- **Universal Bootstrap**: Real-time OS detection (Arch, Debian, Termux, etc.) with silent dependency installation.
- **Smart Setup Wizard**: Automated first-run detection that guides new users through the setup with a dedicated rollback system.
- **Improved Previews**: Real-time font and theme previews with active-item persistence and flicker-free rendering.
- **Fallback Engine**: Automatic "Promptify" text fallback in previews if no name is set.
- **Refactored Menu Core**: Modularized menu drawing for perfect alignment across all terminal widths.

### Changed
- **Config Hardening**: Improved shell profile cleaning logic to prevent duplicate or orphaned configuration blocks.
- **Resilient Installation**: Added auto-creation of missing shell profile files and graceful fallbacks for unsupported package managers.
- **Enhanced Aliases**: Standardized `ls`, `ll`, and `l` aliases across all shell environments.
- **Update Safety**: Added checks for uncommitted local changes and network connectivity before performing updates.
- **Optimized Dependencies**: Prioritized native `lolcat` packages for Termux and other distros to reduce installation time and size.
- **UI Refinement**: Switched from harsh green highlights to professional Bold Cyan/White for active settings.
- **Font Selection**: Streamlined options by removing the redundant 'Blocky' font, leaving clear choices: Default, Shadow, and Simple.
- **Input Handling**: Upgraded input prompts to use `readline` for better cursor control and escape key support.

### Fixed
- **Syntax Highlighting**: Resolved the issue where `cat` output was plain white; now forces color output in all terminal states.
- **Sync Lag**: Fixed the bug where code updates in the repo weren't reflecting in the installed system version.
- **Path Resolution**: Restored critical script path detection logic that was causing setup failures.
- **Checkbox Alignment**: Resolved the jitter issue where selecting items pushed text out of alignment.
- **Input Boundaries**: Fixed a bug where the cursor could overwrite the prompt prefix during text entry.
- **Memory Fix**: Customization changes now reflect in the dashboard instantly without a shell restart.

---

## [1.0.0] - 2026-05-10

### Added
- Initial Master Release.
- Modular shell customization engine.
- Interactive radio and checkbox menus.
- Support for Termux, Arch, and Debian.
- Basic font styles: Shadow, Big, Standard.
- Oh-My-Zsh integration and plugin support.
