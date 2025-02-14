paru -R --noconfirm dolphin
paru -S --needed --noconfirm firefox
paru -S --needed --noconfirm cups
paru -S --needed --noconfirm hplip
paru -S --needed --noconfirm bluez
paru -S --needed --noconfirm bluez-utils
paru -S --needed --noconfirm ghostty
paru -S --needed --noconfirm neovim
paru -S --needed --noconfirm thunderbird
paru -S --needed --noconfirm libreoffice-fresh
paru -S --needed --noconfirm fish
paru -S --needed --noconfirm fastfetch
paru -S --needed --noconfirm starship
paru -S --needed --noconfirm 1password
paru -S --needed --noconfirm nautilus
paru -S --needed --noconfirm dropbox
paru -S --needed --noconfirm nautilus-dropbox
paru -S --needed --noconfirm pavucontrol
paru -S --needed --noconfirm unzip
paru -S --needed --noconfirm blueman
paru -S --needed --noconfirm ttf-jetbrains-mono-nerd
paru -S --needed --noconfirm ttf-font-awesome
paru -S --needed --noconfirm hyprlock
paru -S --needed --noconfirm hypridle
paru -S --needed --noconfirm brightnessctl
paru –S --needed --noconfirm simple-scan
paru -S --needed --noconfirm sane-airscan
paru -S --needed --noconfirm dracula-gtk-theme
paru -S --needed --noconfirm candy-icons
paru -S --needed --noconfirm polkit-gnome
paru -S --needed --noconfirm impression
paru -S --needed --noconfirm sddm-theme-sugar-candy-git
paru -S --needed --noconfirm rclone
paru -S --needed --noconfirm timeshift
paru -S --needed --noconfirm deja-dup
paru -S --needed --noconfirm python-requests-oauthlib
paru -S --needed --noconfirm gnome-keyring
paru -S --needed --noconfirm yazi
paru -S --needed --noconfirm wireplumber libgtop bluez bluez-utils btop networkmanager dart-sass wl-clipboard brightnessctl swww python upower pacman-contrib power-profiles-daemon gvfs
paru -S --needed --noconfirm aylurs-gtk-shell-git grimblast-git gpu-screen-recorder-git hyprpicker matugen-bin python-gpustat hyprsunset-git hypridle-git
paru -S --needed --noconfirm ags-hyprpanel-git
paru -R --noconfirm dunst
gsettings set org.gnome.desktop.interface gtk-theme Dracula
gsettings set org.gnome.desktop.interface icon-theme candy-icons
gsettings set org.gnome.desktop.interface font-name "JetBrainsMono Nerd"
git config --global user.email "blasvinas@gmail.com"
git config --global user.name "Blas Vinas"
paru -c
sudo systemctl enable --now bluetooth
sudo systemctl enable --now cups
sudo systemctl enable --now cronie.service
sudo mkdir /etc/sddm.conf.d/
sudo cp /usr/lib/sddm/sddm.conf.d/default.conf /etc/sddm.conf.d/sddm.conf
ssh-keygen
sudo pkexec env $(env) timeshift-launcher
