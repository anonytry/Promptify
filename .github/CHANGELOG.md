# Changelog

All notable changes to this project will be documented in this file.

## [1.3.1] - 2026-08-02

### Fixed
- **Wrong Directory After Exit**: Running `promptify`/`pty` and exiting no longer leaves you stuck in the first clone directory. `restart_shell` no longer spawns a nested shell via `exec zsh`, bootstrap no longer `cd`s into the clone directory, and update checks run without changing the working directory.
- **Cat Preview (Filename Only)**: The "Filename Only" preview no longer shows line numbers — it now renders just the filename header plus content, matching real `bat` output.
- **Cringy Menu Labels**: Removed clunky parenthetical words from menu items (Cat styles, Themes, Dependencies, Power Tools, Uninstall) for clean, minimal labels.

---

## [1.3.0] - 2026-08-01

### Added
- **New Banner Fonts**: Slant, Banner, Poison, and Graffiti styles bundled as assets — all with proper lowercase letter support (Bubble removed).
- **Random Font Option**: The default banner option now picks a random style from Shadow/Simple/Slant/Banner/Poison/Graffiti on every terminal open.
- **Minimal Banner Box**: Removed the extra vertical padding rows so the banner box hugs the glyphs for a clean, compact look.
- **Live Cat Preview**: The Cat Display Style menu now renders a live preview of the highlighted style (Filename Only, Numbers Only, Plain) as you navigate.
- **Dependencies Status Dots**: The Dependencies menu shows unticked options with live status dots — ● Installed (green), ● Missing (red), ● Broken (amber), ● Outdated (dim green) — plus an on-screen legend.
- **Update Channel Auto-Detect**: The setup wizard no longer prompts for a channel; it derives the channel from the cloned repo's origin.

### Fixed
- **Random Shadow Alignment**: Choosing Random could pick Shadow without trimming its blank trailing row, shifting the banner up on terminal open. Descent is now derived from the selected font on every path (force, preference, and random).
- **Cat/Channel Prefs Preserved**: `~/.username` is now upserted key-by-key instead of rewritten, so operations like banner uninstall keep unrelated prefs (CAT, CHANNEL) intact.
- **ESC Cancels Input Cleanly**: Pressing ESC now cancels text prompts and restores your original readline ESC binding instead of clobbering it.
- **Rollback Only on Interrupt**: The setup wizard rolls back only on user interruption (SIGINT/SIGTERM), not on every failed sub-command.

---

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
