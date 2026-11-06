#!/usr/bin/env bash
# setup-arch.sh — rebuild Indranil's Arch apps + terminal, with a menu to pick which parts to install.
#
# Usage:
#   ./setup-arch.sh                       interactive menu
#   ./setup-arch.sh --all                 install every section (ignores defaults)
#   ./setup-arch.sh --only terminal,docker,ros
#   ./setup-arch.sh --list                list section keys
#
# Notes:
#   - Never runs `pacman -Syu` or `pacman -Sy` on its own (partial upgrades break Arch).
#     It uses `pacman -S --needed`. If you get 404s, run `sudo pacman -Syu` yourself first.
#     (Only the ASUS section syncs, because it adds a new repo.)
#   - Run as your normal user, not root. sudo is called when needed.
#   - Each step is non-fatal; failures are listed at the end.

set -uo pipefail

# ------------------------------ sections ------------------------------
KEYS=(terminal brave vscode flatpaks apps gnome docker ollama ros ai nvidia asus printing)
declare -A LABEL DEFAULT SEL

LABEL[terminal]="Terminal   — zsh, Oh My Zsh + plugins, starship, zoxide, fzf, eza, bat, fd, rg, kitty, Nerd fonts, fastfetch, lazygit, btop"
LABEL[brave]="Brave      — stable + beta + nightly"
LABEL[vscode]="VS Code    — /opt/vscode tarball + update-vscode + extensions (python, pylance, jupyter, ruff)"
LABEL[flatpaks]="Flatpaks   — Obsidian, Orca Slicer, Planify, GreenWithEnvy"
LABEL[apps]="Apps       — VLC, mpv, Blender, FreeCAD, LibreOffice, Flameshot+OCR, Arduino IDE/CLI, Snapcast, Barrier, Deskflow, Ventoy, etc."
LABEL[gnome]="GNOME      — dark mode, Extension Manager, your 11 extensions"
LABEL[docker]="Docker     — docker + compose (+ NVIDIA container toolkit if nvidia-smi works)"
LABEL[ollama]="Ollama     — install (+ optional models / network exposure prompts)"
LABEL[ros]="ROS 2      — Jazzy inside a distrobox Ubuntu 24.04 container (ros-jazzy)"
LABEL[ai]="AI tools   — uv, Miniconda, Hugging Face CLI, Unsloth"
LABEL[nvidia]="NVIDIA     — driver + utils + prime (hardware specific)"
LABEL[asus]="ASUS ROG   — g14 repo, asusctl, supergfxctl, rog-control-center (ASUS laptops only)"
LABEL[printing]="Printing   — CUPS + Epson inkjet driver (epson-inkjet-printer-201601w)"

for k in "${KEYS[@]}"; do DEFAULT[$k]=1; done
DEFAULT[nvidia]=0; DEFAULT[asus]=0; DEFAULT[printing]=0

reset_defaults() { for k in "${KEYS[@]}"; do SEL[$k]=${DEFAULT[$k]}; done; }
reset_defaults

# ------------------------------ args ------------------------------
INTERACTIVE=1
case "${1:-}" in
  --list) printf '%s\n' "${KEYS[@]}"; exit 0 ;;
  --all)  for k in "${KEYS[@]}"; do SEL[$k]=1; done; INTERACTIVE=0 ;;
  --only)
    for k in "${KEYS[@]}"; do SEL[$k]=0; done
    IFS=',' read -ra want <<< "${2:-}"
    for w in "${want[@]}"; do
      [[ -n "${LABEL[$w]:-}" ]] && SEL[$w]=1 || { echo "Unknown section: $w (see --list)"; exit 1; }
    done
    INTERACTIVE=0 ;;
  "" ) ;;
  *) echo "Unknown option: $1"; exit 1 ;;
esac

# ------------------------------ menu ------------------------------
menu() {
  local ans tok k a b i
  while true; do
    clear
    echo "================  Arch setup — choose what to install  ================"
    echo
    i=1
    for k in "${KEYS[@]}"; do
      local mark=" "; [[ ${SEL[$k]} == 1 ]] && mark="x"
      printf ' %2d) [%s] %s\n' "$i" "$mark" "${LABEL[$k]}"
      ((i++))
    done
    echo
    echo " Base packages (git, base-devel, yay, flatpak, pipx) always install first."
    echo
    echo " Toggle: numbers (e.g. 1 3 5 or 2-6) | a = all | n = none | d = defaults"
    echo " Enter = install selection | q = quit"
    read -rp " > " ans
    case "$ans" in
      "") return 0 ;;
      q|Q) exit 0 ;;
      a|A) for k in "${KEYS[@]}"; do SEL[$k]=1; done ;;
      n|N) for k in "${KEYS[@]}"; do SEL[$k]=0; done ;;
      d|D) reset_defaults ;;
      *)
        for tok in $ans; do
          if [[ $tok =~ ^([0-9]+)-([0-9]+)$ ]]; then
            a=${BASH_REMATCH[1]}; b=${BASH_REMATCH[2]}
          elif [[ $tok =~ ^[0-9]+$ ]]; then
            a=$tok; b=$tok
          else
            continue
          fi
          for ((i=a; i<=b; i++)); do
            if ((i>=1 && i<=${#KEYS[@]})); then
              k=${KEYS[i-1]}; SEL[$k]=$(( 1 - SEL[$k] ))
            fi
          done
        done ;;
    esac
  done
}

# ------------------------------ helpers ------------------------------
if [[ $EUID -eq 0 ]]; then echo "Run as your normal user, not root/sudo." >&2; exit 1; fi
[[ -f /etc/arch-release ]] || { echo "This script is for Arch Linux." >&2; exit 1; }

FAILED=()
log()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m!! %s\033[0m\n' "$*" >&2; }
try()  { "$@" || { FAILED+=("$*"); warn "failed: $*"; }; }
have() { command -v "$1" >/dev/null 2>&1; }
ask()  { local a; read -rp "$1 [$2] " a; a=${a:-$2}; [[ $a =~ ^[Yy] ]]; }

pac_i()    { sudo pacman -S --needed --noconfirm "$@"; }
pac_each() { for p in "$@"; do pac_i "$p" || { FAILED+=("pacman:$p"); warn "pacman failed: $p"; }; done; }
aur_i()    { yay -S --needed --noconfirm --answerdiff None --answerclean None "$@"; }
aur_each() { for p in "$@"; do aur_i "$p" || { FAILED+=("aur:$p"); warn "AUR failed: $p"; }; done; }
sel()      { [[ ${SEL[$1]} == 1 ]]; }

mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications" "$HOME/.config" "$HOME/bin"
export PATH="$HOME/.local/bin:$PATH"

((INTERACTIVE)) && menu

echo
echo "Selected:"
any=0
for k in "${KEYS[@]}"; do sel "$k" && { echo "  - $k"; any=1; }; done
((any)) || { echo "Nothing selected."; exit 0; }
((INTERACTIVE)) && { read -rp "Proceed? [Y/n] " go; [[ ${go:-y} =~ ^[Yy] ]] || exit 0; }

sudo -v || exit 1

# ------------------------------ base ------------------------------
log "Base packages"
pac_each git base-devel curl wget unzip flatpak python-pipx fontconfig
pipx ensurepath >/dev/null 2>&1 || true

if ! have yay; then
  log "Bootstrapping yay (yay-bin)"
  rm -rf /tmp/yay-bin
  git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin \
    && (cd /tmp/yay-bin && makepkg -si --noconfirm) \
    || FAILED+=("yay bootstrap")
fi
try flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# ============================== TERMINAL ==============================
if sel terminal; then
  log "Terminal tools"
  pac_each zsh fzf bat fd ripgrep zoxide eza btop starship fastfetch lazygit kitty

  log "Nerd Fonts"
  pac_i ttf-jetbrains-mono-nerd || FAILED+=("font:jetbrains")
  if ! pac_i ttf-fantasque-nerd; then
    FONT_DIR="$HOME/.local/share/fonts/NerdFonts"; mkdir -p "$FONT_DIR"
    curl -fL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FantasqueSansMono.zip -o /tmp/Fantasque.zip \
      && unzip -oq /tmp/Fantasque.zip -d "$FONT_DIR/Fantasque" || FAILED+=("font:fantasque")
  fi
  fc-cache -f >/dev/null 2>&1

  log "kitty config"
  mkdir -p "$HOME/.config/kitty/kitty-themes"
  touch "$HOME/.config/kitty/kitty-themes/00-Default.conf"
  [[ -f $HOME/.config/kitty/kitty.conf ]] && cp "$HOME/.config/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf.bak"
  cat > "$HOME/.config/kitty/kitty.conf" <<'EOF'
# you can choose themes from $HOME/.config/kitty/kitty-themes/
include ./kitty-themes/00-Default.conf

font_family FantasqueSansM Nerd Font Mono Bold
font_size 12.0
bold_font auto
italic_font auto
bold_italic_font auto

background_opacity 0.9
dynamic_background_opacity 1
confirm_os_window_close 0

# Animated cursor
cursor_trail 1

# change to x11 or wayland or leave auto
linux_display_server auto

scrollback_lines 2000
wheel_scroll_min_lines 1
enable_audio_bell no
window_padding_width 4
selection_foreground none
selection_background none

foreground #dddddd
background #000000
cursor #dddddd
EOF

  log "fastfetch config"
  mkdir -p "$HOME/.config/fastfetch"
  curl -fLo "$HOME/.config/fastfetch/config-compact.jsonc" \
    https://raw.githubusercontent.com/JaKooLit/Hyprland-Dots/main/config/fastfetch/config-compact.jsonc \
    || FAILED+=("fastfetch config")

  log "Oh My Zsh + plugins"
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
      || FAILED+=("oh-my-zsh")
  fi
  ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  for repo in zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-history-substring-search; do
    [[ -d "$ZSH_CUSTOM_DIR/plugins/$repo" ]] || \
      git clone --depth=1 "https://github.com/zsh-users/$repo" "$ZSH_CUSTOM_DIR/plugins/$repo" || FAILED+=("plugin:$repo")
  done

  log "Writing ~/.zshrc (old one backed up)"
  [[ -f $HOME/.zshrc ]] && cp "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%Y%m%d-%H%M%S)"
  cat > "$HOME/.zshrc" <<'EOF'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""   # prompt is handled by starship
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

fpath+=${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-completions/src

# zsh-syntax-highlighting must stay last
plugins=(git zsh-autosuggestions zsh-completions zsh-history-substring-search zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# history substring search on up/down
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# fzf
[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
[ -f /usr/share/fzf/completion.zsh ]   && source /usr/share/fzf/completion.zsh

eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --group-directories-first'
alias la='eza -la --icons --group-directories-first'
alias update='sudo pacman -Syu'

# ROS 2 Jazzy (only exists inside the ros-jazzy distrobox)
[ -f /opt/ros/jazzy/setup.zsh ] && source /opt/ros/jazzy/setup.zsh

command -v fastfetch >/dev/null && fastfetch -c "$HOME/.config/fastfetch/config-compact.jsonc"
EOF

  log "Default shell -> zsh"
  try sudo chsh -s "$(command -v zsh)" "$USER"
fi

# ============================== BRAVE ==============================
if sel brave; then
  log "Brave (stable, beta, nightly)"
  if ! have brave; then
    curl -fsS https://dl.brave.com/install.sh | sh || { warn "Brave script failed, trying AUR"; aur_i brave-bin || FAILED+=("brave-bin"); }
  fi
  curl -fsS https://dl.brave.com/install.sh | CHANNEL=beta sh    || { aur_i brave-beta-bin    || FAILED+=("brave-beta"); }
  curl -fsS https://dl.brave.com/install.sh | CHANNEL=nightly sh || { aur_i brave-nightly-bin || FAILED+=("brave-nightly"); }
fi

# ============================== VS CODE ==============================
if sel vscode; then
  log "VS Code (/opt/vscode tarball)"
  if [[ ! -x /opt/vscode/bin/code ]]; then
    sudo mkdir -p /opt/vscode
    curl -L "https://update.code.visualstudio.com/latest/linux-x64/stable" -o /tmp/vscode.tar.gz \
      && sudo tar -xzf /tmp/vscode.tar.gz -C /opt/vscode --strip-components=1 \
      || FAILED+=("vscode download")
  fi
  if [[ -x /opt/vscode/bin/code ]]; then
    sudo ln -sf /opt/vscode/bin/code /usr/local/bin/code
    sudo tee /usr/share/applications/code.desktop >/dev/null <<'EOF'
[Desktop Entry]
Name=Visual Studio Code
GenericName=Text Editor , vs code
Comment=Code Editing. Redefined.
Exec=/usr/local/bin/code --unity-launch %F
Icon=/opt/vscode/resources/app/resources/linux/code.png
Type=Application
StartupNotify=true
Categories=Utility;TextEditor;Development;IDE;
MimeType=text/plain;application/x-code-workspace;inode/directory;
Actions=new-empty-window;

[Desktop Action new-empty-window]
Name=New Empty Window
Exec=/usr/local/bin/code --new-window %F
Icon=/opt/vscode/resources/app/resources/linux/code.png
EOF
    sudo tee /usr/local/bin/update-vscode >/dev/null <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
TMP="$(mktemp -d)"
cd "$TMP"
curl -L "https://update.code.visualstudio.com/latest/linux-x64/stable" -o vscode.tar.gz
sudo rm -rf /opt/vscode
sudo mkdir -p /opt/vscode
sudo tar -xzf vscode.tar.gz -C /opt/vscode --strip-components=1
echo "VS Code updated in /opt/vscode"
EOS
    sudo chmod +x /usr/local/bin/update-vscode
    update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true
    for ext in ms-python.python ms-python.vscode-pylance ms-toolsai.jupyter charliermarsh.ruff; do
      code --install-extension "$ext" >/dev/null 2>&1 || FAILED+=("vscode-ext:$ext")
    done
  fi
fi

# ============================== FLATPAKS ==============================
if sel flatpaks; then
  log "Flatpaks"
  for app in md.obsidian.Obsidian com.orcaslicer.OrcaSlicer io.github.alainm23.planify com.leinardi.gst; do
    try flatpak install -y --noninteractive flathub "$app"
  done
fi

# ============================== APPS ==============================
if sel apps; then
  log "Pacman apps"
  pac_each vlc vlc-plugins-all mpv blender freecad libreoffice-fresh \
           flameshot tesseract tesseract-data-eng xclip wl-clipboard \
           ntfs-3g bluez bluez-utils upower usbutils unrar \
           pavucontrol qpwgraph gromit-mpx pipewire-pulse wireplumber libpulse \
           snapcast barrier arduino-cli cyme

  log "AUR apps"
  aur_each nautilus-admin arduino-ide-bin balena-etcher deskflow

  log "Serial port access (uucp)"
  getent group uucp    >/dev/null && sudo usermod -aG uucp "$USER"
  getent group dialout >/dev/null && sudo usermod -aG dialout "$USER"
  sudo systemctl enable --now bluetooth.service 2>/dev/null || true

  log "Ventoy 1.1.11 -> ~/Downloads"
  mkdir -p "$HOME/Downloads"
  curl -fL "https://github.com/ventoy/Ventoy/releases/download/v1.1.11/ventoy-1.1.11-linux.tar.gz" -o /tmp/ventoy.tar.gz \
    && tar -xzf /tmp/ventoy.tar.gz -C "$HOME/Downloads" || FAILED+=("ventoy")

  log "OCR screenshot helper ~/bin/img2txt.sh"
  cat > "$HOME/bin/img2txt.sh" <<'EOF'
#!/usr/bin/env bash
# select region with flameshot -> OCR with tesseract -> clipboard
tmp="$(mktemp --suffix=.png)"
flameshot gui --raw > "$tmp"
text="$(tesseract "$tmp" - 2>/dev/null)"
rm -f "$tmp"
if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wl-copy >/dev/null; then
  printf '%s' "$text" | wl-copy
else
  printf '%s' "$text" | xclip -selection clipboard
fi
EOF
  chmod +x "$HOME/bin/img2txt.sh"
fi

# ============================== GNOME ==============================
if sel gnome; then
  log "GNOME dark mode + Extension Manager + extensions"
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
  pac_i extension-manager || FAILED+=("extension-manager")

  have gext || try pipx install gnome-extensions-cli --system-site-packages
  for uuid in \
    appindicatorsupport@rgcjonas.gmail.com \
    Bluetooth-Battery-Meter@maniacx.github.com \
    blur-my-shell@aunetx \
    caffeine@patapon.info \
    dash-to-dock@micxgx.gmail.com \
    desktop-cube@schneegans.github.com \
    gsconnect@andyholmes.github.io \
    pip-on-top@rafostar.github.com \
    Vitals@CoreCoding.com \
    ignore-lid@gnome-extensions.mfloto.com \
    nosleep@ilyasturki.com
  do
    gext install "$uuid" || { FAILED+=("gext:$uuid"); warn "extension failed: $uuid"; }
  done
fi

# ============================== DOCKER ==============================
if sel docker; then
  log "Docker"
  pac_each docker docker-compose docker-buildx
  sudo systemctl enable --now docker.service
  sudo usermod -aG docker "$USER"
  if have nvidia-smi; then
    pac_i nvidia-container-toolkit && {
      sudo nvidia-ctk runtime configure --runtime=docker
      sudo systemctl restart docker
    } || FAILED+=("nvidia-container-toolkit")
  else
    warn "nvidia-smi not found — skipped nvidia-container-toolkit (install NVIDIA section first, reboot, re-run docker)."
  fi
fi

# ============================== OLLAMA ==============================
if sel ollama; then
  log "Ollama"
  have ollama || try sh -c 'curl -fsSL https://ollama.com/install.sh | sh'

  if ask "Expose Ollama on 0.0.0.0:11434 (reachable from your LAN)?" n; then
    sudo mkdir -p /etc/systemd/system/ollama.service.d
    sudo tee /etc/systemd/system/ollama.service.d/override.conf >/dev/null <<'EOF'
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
EOF
    sudo systemctl daemon-reload
    sudo systemctl restart ollama
  fi

  if ask "Pull your models (lfm2.5:8b, granite4.1-guardian:8b, qwen3:14b, qwen3:8b + qwen3-cad)? Big downloads." n; then
    sleep 3
    for m in lfm2.5:8b granite4.1-guardian:8b qwen3:14b qwen3:8b; do try ollama pull "$m"; done
    cat > /tmp/Modelfile <<'EOF'
FROM qwen3:8b
PARAMETER num_ctx 8192
PARAMETER temperature 0.2
EOF
    try ollama create qwen3-cad -f /tmp/Modelfile
  fi
fi

# ============================== ROS 2 (distrobox) ==============================
if sel ros; then
  log "ROS 2 Jazzy in distrobox (ubuntu:24.04)"
  pac_each podman distrobox
  if ! distrobox list 2>/dev/null | grep -q 'ros-jazzy'; then
    try distrobox create --name ros-jazzy --image ubuntu:24.04 --yes
  fi
  ROS_SCRIPT=$(cat <<'EOF'
set -e
export DEBIAN_FRONTEND=noninteractive
sudo apt update
sudo apt install -y software-properties-common curl
sudo add-apt-repository -y universe
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list >/dev/null
sudo apt update
sudo apt install -y ros-jazzy-desktop
EOF
)
  try distrobox enter ros-jazzy -- bash -c "$ROS_SCRIPT"
  echo "Use it with:  distrobox enter ros-jazzy   (then: ros2 ...)"
fi

# ============================== AI TOOLS ==============================
if sel ai; then
  log "uv, Miniconda, HF CLI, Unsloth"
  pac_i uv || FAILED+=("uv")

  if [[ ! -x "$HOME/miniconda3/bin/conda" ]]; then
    mkdir -p "$HOME/miniconda3"
    wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O "$HOME/miniconda3/miniconda.sh" \
      && bash "$HOME/miniconda3/miniconda.sh" -b -u -p "$HOME/miniconda3" \
      && rm -f "$HOME/miniconda3/miniconda.sh" \
      || FAILED+=("miniconda")
  fi
  if [[ -x "$HOME/miniconda3/bin/conda" ]]; then
    "$HOME/miniconda3/bin/conda" init zsh bash >/dev/null
    "$HOME/miniconda3/bin/conda" config --set auto_activate_base false
  fi

  have hf || try pipx install "huggingface_hub[cli]"
  try sh -c 'curl -fsSL https://unsloth.ai/install.sh | sh'
fi

# ============================== NVIDIA ==============================
if sel nvidia; then
  log "NVIDIA driver"
  # RTX 50-series (Blackwell) needs the open kernel modules.
  if pacman -Qq linux >/dev/null 2>&1; then
    NV=(nvidia-open)
  else
    NV=(nvidia-open-dkms dkms)
    for k in linux-lts linux-zen linux-hardened; do
      pacman -Qq "$k" >/dev/null 2>&1 && NV+=("$k-headers")
    done
  fi
  NV+=(nvidia-utils nvidia-settings nvidia-prime)
  pac_each "${NV[@]}"
  pac_i lib32-nvidia-utils || warn "lib32-nvidia-utils failed (is [multilib] enabled in /etc/pacman.conf?)"
  try sudo mkinitcpio -P
  warn "Reboot required for the NVIDIA driver. Offload with:  prime-run <app>"
fi

# ============================== ASUS ==============================
if sel asus; then
  log "ASUS ROG tools (g14 repo)"
  warn "This syncs the package DB (-Sy). If you haven't run 'sudo pacman -Syu' recently, do that first."
  KEY=8F654886F17D497FEFE3DB448B15A6B0E9A3FA35
  try sudo pacman-key --recv-keys "$KEY" --keyserver keyserver.ubuntu.com
  try sudo pacman-key --lsign-key "$KEY"
  if ! grep -q '^\[g14\]' /etc/pacman.conf; then
    printf '\n[g14]\nSigLevel = DatabaseNever Optional TrustAll\nServer = https://arch.asus-linux.org\n' | sudo tee -a /etc/pacman.conf >/dev/null
  fi
  try sudo pacman -Sy --needed --noconfirm asusctl rog-control-center supergfxctl power-profiles-daemon
  try sudo systemctl enable --now asusd supergfxd power-profiles-daemon
fi

# ============================== PRINTING ==============================
if sel printing; then
  log "Printing"
  pac_each cups cups-filters
  sudo systemctl enable --now cups.service
  aur_each epson-inkjet-printer-201601w
fi

# ------------------------------ done ------------------------------
log "Done"
if ((${#FAILED[@]})); then
  warn "These steps failed (re-run that section or do them by hand):"
  printf '   - %s\n' "${FAILED[@]}"
else
  echo "Everything installed cleanly."
fi

cat <<'EOF'

Next:
  1. Log out and back in (or reboot): zsh login shell, docker/uucp groups, GNOME extensions.
  2. Open kitty to see starship + fastfetch.
  3. After re-login: docker run hello-world
EOF
