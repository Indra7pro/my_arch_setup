# Arch Linux Setup Script

An interactive post-install script for Arch Linux. Pick which parts of the setup you want from a menu, and it installs and configures them: terminal, apps, dev tools, GNOME, Docker, Ollama, ROS 2, and optional hardware-specific extras.

> **Review before running.** This script installs software, adds repos, edits dotfiles and enables services. Read it first, and never run scripts from the internet blindly.

---

## Quick start

```bash
git clone https://github.com/<your-username>/<your-repo>.git
cd <your-repo>
chmod +x setup-arch.sh
./setup-arch.sh
```

Run it as your **normal user** (not root, not with `sudo`). It calls `sudo` itself when needed.

### Menu controls

```
 1) [x] Terminal   — zsh, Oh My Zsh + plugins, starship, kitty, fonts...
 2) [x] Brave      — stable + beta + nightly
 ...
11) [ ] NVIDIA     — driver + utils + prime
12) [ ] ASUS ROG   — g14 repo, asusctl, supergfxctl...
```

| Input | Action |
|-------|--------|
| `1 3 5` | Toggle sections 1, 3 and 5 |
| `2-6` | Toggle a range |
| `a` | Select all |
| `n` | Select none |
| `d` | Reset to defaults |
| `Enter` | Install the selection |
| `q` | Quit |

### Non-interactive usage

```bash
./setup-arch.sh --list                         # print section keys
./setup-arch.sh --all                          # install every section
./setup-arch.sh --only terminal,docker,ros     # install only these sections
```

---

## Sections

| # | Key | Default | Description |
|---|-----|:-------:|-------------|
| 1 | `terminal` | ✅ | zsh, Oh My Zsh + plugins, starship, zoxide, fzf, eza, bat, kitty, Nerd Fonts, fastfetch, lazygit, btop |
| 2 | `brave` | ✅ | Brave stable, beta and nightly |
| 3 | `vscode` | ✅ | VS Code (tarball in `/opt/vscode`), `update-vscode` helper, extensions |
| 4 | `flatpaks` | ✅ | Obsidian, Orca Slicer, Planify, GreenWithEnvy |
| 5 | `apps` | ✅ | Media, CAD, office, Arduino, audio and misc desktop apps |
| 6 | `gnome` | ✅ | Dark mode, Extension Manager, 11 GNOME extensions |
| 7 | `docker` | ✅ | Docker, Compose, Buildx (+ NVIDIA container toolkit if a GPU driver is present) |
| 8 | `ollama` | ✅ | Ollama (+ optional models and network exposure, asked at runtime) |
| 9 | `ros` | ✅ | ROS 2 Jazzy inside a distrobox Ubuntu 24.04 container |
| 10 | `ai` | ✅ | uv, Miniconda, Hugging Face CLI, Unsloth |
| 11 | `nvidia` | ❌ | NVIDIA open driver + utilities (hardware specific) |
| 12 | `asus` | ❌ | ASUS ROG tools from the g14 repo (ASUS laptops only) |
| 13 | `printing` | ❌ | CUPS + Epson inkjet driver |

A **base** step always runs first (see below).

---

## Full package list

### Base (always installed)

| Source | Packages |
|--------|----------|
| pacman | `git` `base-devel` `curl` `wget` `unzip` `flatpak` `python-pipx` `fontconfig` |
| AUR | `yay-bin` (bootstrapped with `makepkg`) |
| Flatpak | Flathub remote is added |

### 1. Terminal (`terminal`)

| Source | Packages |
|--------|----------|
| pacman | `zsh` `fzf` `bat` `fd` `ripgrep` `zoxide` `eza` `btop` `starship` `fastfetch` `lazygit` `kitty` |
| pacman (fonts) | `ttf-jetbrains-mono-nerd` `ttf-fantasque-nerd` (falls back to the FantasqueSansMono Nerd Font zip from GitHub) |
| Git clone | Oh My Zsh, plus the plugins `zsh-autosuggestions` `zsh-syntax-highlighting` `zsh-completions` `zsh-history-substring-search` |
| Downloaded | fastfetch compact config from [JaKooLit/Hyprland-Dots](https://github.com/JaKooLit/Hyprland-Dots) |

Also configured: `~/.zshrc`, `~/.config/kitty/kitty.conf`, and zsh as the default shell.

### 2. Brave (`brave`)

| Source | Packages |
|--------|----------|
| Official script (`dl.brave.com/install.sh`) | Brave stable, beta, nightly |
| AUR (fallback if the script fails) | `brave-bin` `brave-beta-bin` `brave-nightly-bin` |

### 3. VS Code (`vscode`)

| Source | Packages |
|--------|----------|
| Official tarball | VS Code → `/opt/vscode`, symlinked to `/usr/local/bin/code` |
| Helper | `/usr/local/bin/update-vscode` (re-downloads the latest stable) |
| Extensions | `ms-python.python` `ms-python.vscode-pylance` `ms-toolsai.jupyter` `charliermarsh.ruff` |

### 4. Flatpaks (`flatpaks`)

| App | Flatpak ID |
|-----|-----------|
| Obsidian | `md.obsidian.Obsidian` |
| Orca Slicer | `com.orcaslicer.OrcaSlicer` |
| Planify | `io.github.alainm23.planify` |
| GreenWithEnvy | `com.leinardi.gst` |

### 5. Apps (`apps`)

| Source | Packages |
|--------|----------|
| pacman (media/office/CAD) | `vlc` `vlc-plugins-all` `mpv` `blender` `freecad` `libreoffice-fresh` |
| pacman (screenshot + OCR) | `flameshot` `tesseract` `tesseract-data-eng` `xclip` `wl-clipboard` |
| pacman (system/utility) | `ntfs-3g` `bluez` `bluez-utils` `upower` `usbutils` `unrar` `cyme` |
| pacman (audio) | `pavucontrol` `qpwgraph` `gromit-mpx` `pipewire-pulse` `wireplumber` `libpulse` `snapcast` |
| pacman (other) | `barrier` `arduino-cli` |
| AUR | `nautilus-admin` `arduino-ide-bin` `balena-etcher` `deskflow` |
| Downloaded | Ventoy 1.1.11 → `~/Downloads` |
| Script | `~/bin/img2txt.sh` (flameshot region → tesseract OCR → clipboard) |

Also: adds you to `uucp` (and `dialout` if it exists) for serial access, and enables `bluetooth.service`.

### 6. GNOME (`gnome`)

| Source | Packages |
|--------|----------|
| pacman | `extension-manager` |
| pipx | `gnome-extensions-cli` (`gext`) |
| Setting | `color-scheme` set to `prefer-dark` |

Extensions (installed with `gext`):

| Extension | UUID |
|-----------|------|
| AppIndicator Support | `appindicatorsupport@rgcjonas.gmail.com` |
| Bluetooth Battery Meter | `Bluetooth-Battery-Meter@maniacx.github.com` |
| Blur my Shell | `blur-my-shell@aunetx` |
| Caffeine | `caffeine@patapon.info` |
| Dash to Dock | `dash-to-dock@micxgx.gmail.com` |
| Desktop Cube | `desktop-cube@schneegans.github.com` |
| GSConnect | `gsconnect@andyholmes.github.io` |
| PiP on Top | `pip-on-top@rafostar.github.com` |
| Vitals | `Vitals@CoreCoding.com` |
| Ignore Lid | `ignore-lid@gnome-extensions.mfloto.com` |
| Nosleep | `nosleep@ilyasturki.com` |

### 7. Docker (`docker`)

| Source | Packages |
|--------|----------|
| pacman | `docker` `docker-compose` `docker-buildx` |
| pacman (only if `nvidia-smi` works) | `nvidia-container-toolkit` |

Also: enables `docker.service` and adds you to the `docker` group.

### 8. Ollama (`ollama`)

| Source | Packages |
|--------|----------|
| Official script (`ollama.com/install.sh`) | Ollama |
| Optional prompt: expose on LAN | systemd override setting `OLLAMA_HOST=0.0.0.0:11434` (default: **no**) |
| Optional prompt: models | `lfm2.5:8b` `granite4.1-guardian:8b` `qwen3:14b` `qwen3:8b`, plus a custom `qwen3-cad` model (default: **no**) |

### 9. ROS 2 (`ros`)

| Where | Packages |
|-------|----------|
| Host (pacman) | `podman` `distrobox` |
| Inside the `ros-jazzy` container (Ubuntu 24.04, apt) | `software-properties-common` `curl` `ros-jazzy-desktop` |

Enter it with `distrobox enter ros-jazzy`.

### 10. AI tools (`ai`)

| Source | Packages |
|--------|----------|
| pacman | `uv` |
| Installer | Miniconda → `~/miniconda3` (`auto_activate_base` set to false) |
| pipx | `huggingface_hub[cli]` (provides `hf`) |
| Installer script | Unsloth (`unsloth.ai/install.sh`) |

### 11. NVIDIA (`nvidia`)

| Condition | Packages |
|-----------|----------|
| Stock `linux` kernel | `nvidia-open` |
| Other kernels | `nvidia-open-dkms` `dkms` + the matching `*-headers` package |
| Always | `nvidia-utils` `nvidia-settings` `nvidia-prime` `lib32-nvidia-utils` (needs `[multilib]`) |

Also runs `mkinitcpio -P`. **Reboot afterwards.** Offload apps to the GPU with `prime-run <app>`.

> `nvidia-open` is used because RTX 50-series GPUs need the open kernel modules. If you have an older card and prefer the proprietary driver, swap the package in the script.

### 12. ASUS ROG (`asus`)

| Source | Packages |
|--------|----------|
| g14 repo (`arch.asus-linux.org`) | `asusctl` `rog-control-center` `supergfxctl` |
| pacman | `power-profiles-daemon` |

Also: imports the repo signing key, appends `[g14]` to `/etc/pacman.conf`, and enables `asusd`, `supergfxd` and `power-profiles-daemon`.

> This is the only section that runs `pacman -Sy`. Run `sudo pacman -Syu` first.

### 13. Printing (`printing`)

| Source | Packages |
|--------|----------|
| pacman | `cups` `cups-filters` |
| AUR | `epson-inkjet-printer-201601w` |

Also enables `cups.service`.

---

## What the script changes on your system

| Item | Location | Backed up? |
|------|----------|:----------:|
| Zsh config | `~/.zshrc` | ✅ `~/.zshrc.bak.<timestamp>` |
| kitty config | `~/.config/kitty/kitty.conf` | ✅ `kitty.conf.bak` |
| fastfetch config | `~/.config/fastfetch/config-compact.jsonc` | ❌ |
| VS Code | `/opt/vscode`, `/usr/local/bin/code`, `/usr/local/bin/update-vscode`, `/usr/share/applications/code.desktop` | ❌ |
| OCR helper | `~/bin/img2txt.sh` | ❌ |
| Default shell | `chsh` → zsh | ❌ |
| Groups | `docker`, `uucp`, `dialout` (if present) | ❌ |
| Pacman config | `/etc/pacman.conf` (ASUS section only) | ❌ |
| Ollama override | `/etc/systemd/system/ollama.service.d/override.conf` (only if you opt in) | ❌ |
| Services enabled | `docker`, `bluetooth`, `cups`, `asusd`, `supergfxd`, `power-profiles-daemon` (depending on sections) | ❌ |

---

## Safe by design

- **No system upgrade.** The script never runs `pacman -Syu` or `pacman -Sy` on its own, because partial upgrades break Arch. It uses `pacman -S --needed`, so already-installed packages are skipped. If you hit `404` errors from a stale database, run `sudo pacman -Syu` yourself and re-run.
- **Non-fatal steps.** A failed package doesn't stop the script. All failures are listed at the end.
- **Idempotent.** You can re-run it, or run only the sections you missed with `--only`.

---

## After installing

1. **Log out and back in** (or reboot) so zsh, group changes and GNOME extensions take effect.
2. Open **kitty** to see the starship prompt and fastfetch.
3. Verify Docker: `docker run hello-world`
4. If you installed NVIDIA: reboot, then check `nvidia-smi`.
5. Open **Extension Manager** and enable any extensions that show as disabled.

---

## Not included

These are deliberately left out because they are machine-specific:

- Btrfs swapfile and hibernation setup
- Windows dual-boot entry for systemd-boot
- Hyprland dotfiles
- Custom PipeWire/Snapcast audio sync scripts (the `snapcast` package itself is installed)

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `404` / `failed retrieving file` from pacman | `sudo pacman -Syu`, then re-run |
| `lib32-nvidia-utils` fails | Enable `[multilib]` in `/etc/pacman.conf`, then `sudo pacman -Syu` |
| GNOME extension fails to install | Make sure you run the script from inside a GNOME session (it needs D-Bus), or install it from Extension Manager |
| Fonts not showing in kitty | `fc-cache -f`, then restart kitty. Check with `kitten choose-fonts` |
| `docker: permission denied` | Log out and back in so the `docker` group applies, or run `newgrp docker` |
| Brave script fails | The script falls back to the AUR packages automatically; check the failure list at the end |

---

## License

Add your preferred license here (for example MIT).
