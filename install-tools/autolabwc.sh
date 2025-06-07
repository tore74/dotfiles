#!/bin/sh
# Debian Linux Post-Installation Script for Wayland
# Author: Speyll
# Last-update: 11-12-2024
# NOTE: As of Debian 12 (Bookworm Stable), while Waybar and Neovim settings function,
# the Waybar height is misconfigured and Lua scripts for Neovim fail to load due to outdated packages.
# For improved compatibility, consider using the Testing branch. Future Debian versions may not require this adjustment.


# Enable debugging output and exit on error
set -x

# Add user to sudo group
#sudo usermod -aG sudo $USER

# Backup the existing sources.list file
#sudo cp /etc/apt/sources.list.d/debian.sources /etc/apt/sources.list.d/debian.sources.bak

# Add contrib and non-free to the sources.list
#sudo sed -i '/^deb .* main/{s/main/main contrib non-free/;t;}' /etc/apt/sources.list.d/debian.sources

# installer ny firefox
sudo install -d -m 0755 /etc/apt/keyrings
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null
echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla 

# Update package lists and upgrade existing packages
sudo apt-get update -y
sudo apt-get upgrade -y

# Install GPU drivers
install_gpu_driver() {
  gpu_driver=""
  case "$(lspci | grep -E 'VGA|3D')" in
    *Intel*) gpu_driver="intel-media-va-driver intel-media-va-driver-non-free" ;;
    *AMD*)   gpu_driver="mesa-va-drivers libvdpau-va-gl1 vdpau-driver mesa-vdpau-drivers" ;;
    *NVIDIA*)gpu_driver="mesa-va-drivers nvidia-driver libvdpau-va-gl1 vdpau-driver-all nvidia-vdpau-driver libnvcuvid1 libnvidia-encode1" ;;
  esac
  for pkg in $gpu_driver; do
    [ -n "$pkg" ] && sudo apt-get install --no-install-recommends -y "$pkg"
  done
}

install_gpu_driver  # Call the function

# Install CPU microcode updates
if lspci | grep -q 'Intel'; then
  sudo apt-get install --no-install-recommends -y intel-microcode
fi

# Install other packages
install_core_packages() {
  for pkg in dbus tmux git curl gzip polkitd firefox 7zip jq \
             xdg-utils xdg-desktop-portal-gtk xdg-desktop-portal-wlr xdg-desktop-portal \
             pipewire gstreamer1.0-pipewire libspa-0.2-bluetooth rtkit pavucontrol \
             pipewire-alsa fonts-hack-otf fonts-font-awesome dmz-cursor-theme \
             grim slurp wl-clipboard cliphist pipewire-audio wireplumber \
             imv swaybg mpv ffmpeg yt-dlp poppler-utils fd-find ripgrep fzf zoxide imagemagick \
             fnott libnotify4 labwc wlrctl wlr-randr build-essential \
             nnn unzip p7zip unrar pcmanfm-qt ffmpegthumbnailer lxqt-archiver gvfs udisks2 \
             breeze-gtk-theme breeze-icon-theme breeze-cursor-theme qt5ct qt6ct qtwayland5 \
             bluez network-manager wlopm swayidle swaylock \
             sway foot waybar wlsunset fuzzel brightnessctl brightness-udev; do
    sudo apt-get install --no-install-recommends -y "$pkg" || echo "Failed to install $pkg"
  done
}

install_networking_packages() {
  for pkg in sshfs lynx rsync wireguard; do
    sudo apt-get install --no-install-recommends -y "$pkg"
  done
}

install_flatpak_packages() {
  sudo apt-get install --no-install-recommends -y flatpak
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  flatpak install flathub io.gitlab.librewolf-community
  flatpak install flathub com.github.tchx84.Flatseal
}

install_flatpak_gaming() {
  flatpak install flathub com.usebottles.bottles
  flatpak install flathub org.freedesktop.Platform.VulkanLayer.MangoHud
  flatpak install flathub org.freedesktop.Platform.VulkanLayer.gamescope 
}

# !IMPORTANT! here you can select what gets installed and what not by commenting
install_core_packages
install_networking_packages
#install_flatpak_packages
#install_flatpak_gaming
#install_gaming_packages

wget https://github.com/neovim/neovim-releases/releases/download/v0.11.1/nvim-linux-x86_64.deb
sudo apt install --no-install-recommends -y "$HOME/nvim-linux-x86_64.deb"

# Enable and start timesync service
sudo systemctl enable --now systemd-timesyncd

# Enable and start bluetooth service
sudo systemctl enable --now bluetooth

# Enable and start polkitd
#sudo systemctl enable --now polkitd

# Enable and start rtkit
#sudo systemctl enable --now rtkit

# Set up NetworkManager
sudo systemctl stop wpa_supplicant
sudo systemctl disable --now wpa_supplicant

sudo systemctl disable --now systemd-networkd
sudo systemctl mask systemd-networkd

sudo systemctl enable --now dbus
sudo systemctl enable --now NetworkManager

mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/share/bin"
mkdir -p "$HOME/.local/share/fonts"
mkdir -p "$HOME/.local/share/themes"

wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/DejaVuSansMono.zip
unzip "$HOME/DejaVuSansMono.zip" -d "$HOME/.local/share/fonts"

# Clone and set up dotfiles
git clone https://github.com/speyll/dotfiles "$HOME/speyll-dotfiles"
#git clone https://github.com/tore74/.dotfiles "$HOME"
#cp -r "$HOME/dotfiles/."* "$HOME/"
#rm -rf "$HOME/dotfiles"
#chmod -R +X "$HOME/.local/bin" "$HOME/.local/share/applications" "$HOME/.config/autostart/"
#chmod +x "$HOME/.config/yambar/sway-switch-keyboard.sh" "$HOME/.config/yambar/xkb-layout.sh" "$HOME/.config/autostart/*" "$HOME/.local/bin/*"
#ln -s "$HOME/.config/mimeapps.list" "$HOME/.local/share/applications/"

# Add user to sudo group for sudo access
echo "%sudo ALL=(ALL:ALL) NOPASSWD: /usr/bin/halt, /usr/bin/poweroff, /usr/bin/reboot, /usr/bin/shutdown, /usr/bin/zzz, /usr/bin/ZZZ" | sudo tee -a /etc/sudoers.d/wheel
