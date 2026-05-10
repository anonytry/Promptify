# 🚀 Promptify

A modular shell customizer for **Termux**, **Arch Linux**, and **Debian/Ubuntu**. Promptify transforms your standard terminal into a high-performance, aesthetically pleasing workspace with zero configuration hassle.

---

## 🌟 Key Features

- **🎨 Dynamic Aesthetics:** Perfectly centered ASCII banners and rounded dashboard layouts.
- **⚡ High Performance:** Minimalist Zsh/Bash prompts with instant Git branch detection.
- **🖥️ Cross-Platform:** Native support for Termux, Arch (Pacman), and Debian/Ubuntu (APT) environments.
- **🛠️ Modular UI:** A high-performance interactive menu library with zero flicker.
- **📦 Smart Dependencies:** Automatically installs and configures `eza`, `bat`, `lolcat`, and essential fonts.
- **🔄 Auto-Centering:** Responsive UI that adapts to your terminal size, from mobile screens to large desktop monitors.

---

## 🛠️ Supported Environments & Package Managers

Promptify is built to be truly universal. It automatically detects your environment and uses the appropriate tools:

- **Termux:** Uses `pkg` and configures Android-specific properties.
- **Arch Linux:** Full `pacman` support with automated dependency resolution.
- **Debian / Ubuntu / Kali:** Robust `apt` integration with intelligent `sudo` handling.
- **General Linux:** Generic fallback for other distributions using standard shell primitives.

---

## 🚀 Installation

Fire up your terminal and paste this command:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/TopexGuy/promptify/refs/heads/main/promptify.sh)
```

### ⚡ Unattended Setup
For power users and scripts, Promptify supports several flags:

- **Auto-confirm:** `--yes` (Skips confirmation prompts)
- **Silent Mode:** `--silent` (Minimal output during installation)
- **Combined:** `--yes --silent` (Full unattended installation)

---

## 📂 Project Structure

- **`core/`**: The engine behind environment detection, UI rendering, and package management.
- **`modules/`**: Modular components for the dashboard, setup wizard, and customization.
- **`assets/`**: High-quality fonts, properties, and terminal configurations.

---

## 📜 Acknowledgments & Credits

Promptify stands on the shoulders of giants. Special thanks to the following projects:

- **[T-Header](https://github.com/remo7777/T-Header)**: For the inspiration and foundational ASCII drawing assets used in our modular header system.
- **[Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)**: The delightful framework for managing Zsh configuration.
- **[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)** & **[zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)**.

---

## 🗑️ Uninstallation

We value your system's integrity. To completely revert all changes, simply select **Uninstall** from the Promptify dashboard. The uninstaller offers granular control over what to remove:
- Revert Shell Profile (`.zshrc`/`.bashrc`)
- Remove Promptify System Directory
- Revert Termux UI settings
- Remove Home assets

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request or report bugs via the issue template.

