# Promptify

---

Promptify is a premium terminal customization engine that transforms your standard shell into a clean, highly functional workspace. Designed for seamless compatibility across Termux and Linux distributions, it delivers a modern, responsive interface without the need for complex manual configuration.

## Why use Promptify?

- **Dynamic Typography**: Auto-centered ASCII banners that adapt to your terminal size with vibrant color gradients.
- **Global Integration**: Install once as a system package and manage your environment from any directory using `promptify`, `Promptify`, or `pty`.
- **Intelligent Configuration**: Automatically handles dependencies, sets up ZSH, and configures essential plugins silently.
- **Command Center**: A sleek dashboard to monitor your system environment and toolchain status.
- **Lightweight Design**: Built with pure bash and native utilities to ensure maximum performance with minimal overhead.

## Previews

Promptify scales perfectly from mobile screens to ultrawide PC monitors.

**Mobile Experience:**
| | |
|:---:|:---:|
| ![Mobile Main Menu](.github/assets/mobile1.png) | ![Mobile Setup](.github/assets/mobile2.png) |

**Desktop Experience:**
| | | |
|:---:|:---:|:---:|
| ![PC Themes](.github/assets/pc1.png) | ![PC Customization](.github/assets/pc2.png) | ![PC Dashboard](.github/assets/pc3.png) |

---

## Installation

Run this single command to start the transformation:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/TopexGuy/promptify/refs/heads/main/promptify.sh)
```

## Post-Installation Commands

| Command | Action |
|:---|:---|
| `promptify` / `pty` | Open the management menu and settings |
| `ls` / `l` | See your files with beautiful icons and colors |
| `cat` | Read files with professional code highlighting (Syntax Highlighting) |

## Customization

You can change your look anytime by running `promptify`:
- **Change Banner**: Update the name or text at the top of your terminal.
- **Switch Fonts**: Choose between Default, Shadow, or Simple styles.
- **Prompt Themes**: Switch between Neon, Matrix, Dracula, and more.

## What's New in v1.1.0?

- **Global Integration**: System-wide access via `promptify`, `Promptify`, and `pty` commands.
- **Pro-Cat Integration**: Built-in syntax highlighting for the `cat` command.
- **Auto-Sync Engine**: Local repository changes now sync automatically to the system directory.
- **Resilient Core**: Hardened configuration cleaning and automated profile creation.
- **Improved UI Performance**: Flicker-free previews and refactored menu alignment.

[See the full Changelog here](.github/CHANGELOG.md)

## Acknowledgments & Credits

Promptify stands on the shoulders of giants. Special thanks to the following projects:

- **[T-Header](https://github.com/remo7777/T-Header)**: For the inspiration and foundational ASCII drawing assets used in our modular header system.
- **[Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)**: The delightful framework for managing Zsh configuration.
- **[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)** & **[zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)**.

## Uninstall

Don't like it? No problem. Uninstalling is just as easy:
1. Type `promptify`.
2. Select **Uninstall**.
3. Your terminal will be back to original in seconds.

## License

This project is licensed under the MIT License.
