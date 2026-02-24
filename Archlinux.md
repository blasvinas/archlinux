# Install Archlinux

## Boot

- Go to the Bios (F2)

  - Disable Secure Boot
  - Enable UEFI boot

- Boot the laptop and hit F12
- Choose USB drive

## Wireless Configuration

- For wireless connection

  - $ iwctl
  - [iwd]# device list
  - [iwd]# station device scan
  - [iwd]# station device get-networks
  - [iwd]# station device connect SSID
  - [iwd]# exit
  - ping google.com

## Use the install script

- archinstall
- - Include the following packages: git vim unzip neovim blueman networkmanager wpa_supplicant firefox cups thunderbird libreoffice-fresh bluez bluez-utils gnome-browser-connector fprintd gnome-tweaks
- pacman -S networkmanager wpa_supplicant hplip
- exit
- reboot
- systemctl enable --now NetworkManager
- systemctl enable --now bluetooth
- systemctl emable --now cups
- No needed, just in case. nmtui to configure wireless (you can try nmcli device wifi connect ATTF password <password>
- sudo vim /etc/sudoers.d/00_blas and add: blas ALL=(ALL) NOPASSWD: ALL

For manual install follow the next steps in Manual Installation

## Enable wifi

- Run nmtui

## Install paru

git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si

### Paru in reverse order

- paru packgage --bottomup

## Install 1password

- paru 1password

## Install Dropbox

- paru dropbox
- In Gnome: paru nautilus-dropbox
- In KDE:
  - paru dolphin-plugins
  - Open dolphin
  - Go to Configure
  - Configure Dolphin
  - Context Menu
  - Click on the Dropbox checkbox

## Notifycations

- paru libnotify

## Hyprland

- cp /home/blas/Dropbox/Notes/Archlinux/config/ /home/blas/.config
- paru wl-clipboard
- paru nautilus
- paru waybar
- paru dropbox dolphin-plugins
- paru nautilus-dropbox
- paru pipewire
- paru pipewire-pulse
- paru pavucontrol
- paru wlogout
- paru unzip
- paru nwg-drawer
- paru blueman
- paru ttf-meslo-nerd
- paru ttf-font-awesome
- paru otf-font-awesome
- paru ttf-arimo-nerd
- paru noto-fonts
- paru hyprpaper
- paru hyprlock
- paru hypridle
- paru yad
- paru brightnessctl
- paru kwalletmanager -> Disable kwallet
- paru brave-bin

### Screenshots

- paru grim
- paru eog
- paru slurp
- Add the following line to hyprland.conf

### Enable copy in vim

Add the following lines to .vimrc

```a
autocmd TextYankPost * if (v:event.operator == 'y' || v:event.operator == 'd') | silent! execute 'call system("wl-copy", @")' | endif
nnoremap p :let @"=substitute(system("wl-paste --no-newline"), '<C-v><C-m>', '', 'g')<cr>p
```

### Configure a theme

- paru dracula-gtk-theme
- (No needed) Create a directory .themes in your home directory. For example Sweet-Dark-v40
- gsettings set org.gnome.desktop.interface gtk-theme Dracula
- gsettings get org.gnome.desktop.interface gtk-theme
- vim .config/hypr/hyprland.conf and add env = GTK_THEME, Dracula

### Configure Icons

- paru candy-icons
- ( No needed) Create a directory .icons in your home directory. For example candy-icons
- gsettings set org.gnome.desktop.interface icon-theme candy-icons
- gsettings get org.gnome.desktop.interface icon-theme

### Configure Fonts

- gsettings set org.gnome.desktop.interface font-name "MesloLGS Nerd Font Mono"
- gsettings get org.gnome.desktop.interface font-name

### Configure a SDDM theme

#### Sugar Candy Theme

- paru sddm-theme-sugar-candy-git
- sudo mkdir /etc/sddm.conf.d/
- sudo cp /usr/lib/sddm/sddm.conf.d/default.conf /etc/sddm.conf.d/sddm.conf
- sudo vim /etc/sddm.conf

```
[Theme]
Current=Sugar-Candy
```

- To change the background:

  - sudo cp ~/Dropbox/wallpapers/background.jpg /usr/share/sddm/themes/Sugar-Candy/Backgrounds
  - sudo vim /usr/share/sddm/themes/Sugar-Candy/theme.conf
  - change the background to the path of your image, for example:

  ```
  [General]
  Background="Backgrounds/background.jpg"
  ```

- To check the current theme configuration run:

```
sddm-greeter --test-mode --theme /usr/share/sddm/themes/Sugar-Candy
```

## fish

- paru fish
- chsh -s /usr/bin/fish
- paru fastfetch
- add the fastfetch command to ~/.config/fish/config.fish
- vim /home/blas/.config/fish/functions/fish_prompt.fish and add the following lines:

```
function fish_prompt
   set_color green; echo (pwd)'> '
end
```

- alias --save paru="paru --bottomup"

## Printer

- sudo pacman -S cups hplip
- sudo systemctl enable --now cups
- In the apps run Manage Printing
- Click on Administration
- Add Printer
- In Dicovered Network Printers select: ENVY 4520 series (HP ENVY 4520 series)
- For the model select: HP Envy 4520 Series, hpcups 3.23.5 (en, en)

## Installer Scaner (no needed in Gnome should be an app called Document Scanner)

- paru –S simple-scan
- paru sane-airscan

## Ledger

paru ledger-live-bin

## Visual Studio Code

- paru visual-studio-code-bin

## Gnome Impression

- paru polkit-gnome
- paru impression

## Rclone

- paru rclone
- mkdir ~/OneDrive
- rclone config

## Virtual Manager

- sudo pacman -S virt-manager virt-viewer qemu bridge-utils libguestfs dnsmasq
- sudo vim /etc/libvirt/libvirtd.conf
  - uncomment lines: unix_sock_group and unix_sock_ro_perms
- sudo gpasswd -a $USER libvirt
- sudo systemctl enable --now libvirtd
- In virtual manager application go to Edit -> Connection Detail -> Virtual network and make sure that Autostart On Boot is selected
- Add the following line to .bashrc: export TERM=xterm

## Timeshift

- paru timeshift
- sudo systemctl enable --now cronie.service
- sudo pkexec env $(env) timeshift-launcher
- sudo timeshift --list

## Kitty

Configure kitty to use catppuchin theme

- kitten theme
- Search for catppuchin (using /)
- Select Catppuchin Mocha
- Type M to modify the theme

## Starship

- paru starship
- cp /home/blas/Dropbox/Notes/Archlinux/config/starship.toml ~/.config
- Add starship init fish | source to /home/blas/.config/fish/config.fish

## Deja Dup Backup

- paru deja-dup
- paru python-requests-oauthlib
- paru gnome-keyring

## rust-analyzer

- rustup component add rust-analyzer
- rust-analyzer --version

## Zed Editor

- paru zed
- paru xdg-desktop-portal-gtk

# Other

## Bluetooth not working

If bluetooth stops working after an update try the following steps:

- journalctl | grep BT_RAM. Look for an error message refering to a file with a name starting with BT_RAM_CODE_MT7961
- cd to /usr/lib/firmware/mediatek
- ln -s BT_RAM_CODE_MT7961_1_2_hdr.bin.zst /usr/lib/firmware/mediatek/<Name of file found in the journalctl output>
- Reboot

## Install yay (no needed. does the same as paru)

- sudo git clone https://aur.archlinux.org/yay.git
- cd yay
- makepkg yay

## Install gnome terminal with transparency

- paru gnome-terminal-transparency

## Install FUSE

Fuse is needed to run AppImages
pacman -S fuse

## Gnome extensions

paru extension-manager
sudo pacman -S gnome-browser-connector

# Install KDE

pacman -S plasma plasma-wayland-session konsole dolphin

systemctl enable sddm.service

## Configure KDE Wallet

pacman -S kwallet-pam

vi /etc/pam.d/sddm

Add the following lines:

-auth optional pam_kwallet5.so
-session optional pam_kwallet5.so

# Install skanpage

- paru skanpage

# Manual Installation

## Wireless Configuration

- For wireless connection

  - $ iwctl
  - [iwd]# device list
  - [iwd]# station device scan
  - [iwd]# station device get-networks
  - [iwd]# station device connect SSID
  - [iwd]# exit
  - ping google.com

## Disk Configuration

- Check disk configuration running fdisk -l
- fdisk /path_to_disk. For example: fdisk /dev/nvme0n1
- delete any existing partitions if needed typing d and when ask entering the partition number
- You can check the partition table entering p
- If you need to check the partition types enter l (lower case L)
- To change the type of a partition enter t
- To create a new partition enter n
- Create the boot partion:
  - Partition number: 1
  - First sector: 2048
  - Last sector: +1G
  - Type: EFI System
- Create the swap partition
  - Partition number: 2
  - First sector: Accept the default
  - Last sector: +4G
  - Type: Linux swap
- Create the root partition
  - Partition number: 3
  - First sector: accept the defaults
  - Last sector: accept the default
  - Type: Linux root (x86-64)
- Write changes to disk entering w

## Format the partitions

- Format root partition running: mkfs.btrfs /partition_path
- Format swap partition running mkswap /partition_path
- Format the boot partition running mkfs.fat -F 32 /partition_path

## Mount the file systems

- mount /path-root-partition /mnt
- mount --mkdir /path-boot-partition /mnt/boot
- swapon /path-swap-partition

## Install Packages

- pacstrap -K /mnt base linux linux-firmware

## Configure fstab

- genfstab -U /mnt >> /mnt/etc/fstab

## chroot

- arch-chroot /mnt

## Install vim

- pacman -S vim

## Locale Configuration

- vim /etc/locale.gen and uncomment en_US.UTF-8 UTF-8
- locale-gen
- echo LANG=en_US.UTF-8 > /etc/locale.conf
- export LANG=en_US.UTF-8

## Install network packages

pacman -S networkmanager wpa_supplicant

## Confugure boot loader

- bootctl install
- vim /boot/loader/loader.conf

```
default arch
timeout 5
editor  no
```

- Get the UUID of the root partition: blkid -s UUID -o value /dev/your_root_partition
- vim /boot/loader/entries/arch.conf

```
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=<your-root-partition-uuid> rw
```

## Hostname

- vim /etc/hostname
- Enter the hostname

## Timezone

- tzselect
- ln -s /usr/share/zoneinfo/America/New_York /etc/localtime
- hwclock --systohc

## root password

- passwd

## Reboot

- reboot

## Additional steps

- passwd
- pacman -S networkmanager wpa_supplicant
- pacman -S gcc debugedit fakeroot pkgconfig
- exit
- umount -R /mnt
- reboot
- systemctl start NetworkManager
- systemctl enable NetworkManager
- nmtui to configure wireless (you can try nmcli device wifi connect ATTF password <password>

## Install paru

git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si

### Paru in reverse order

- paru packgage --bottomup

## Install 1password

- paru 1password

## Install Dropbox

- paru dropbox
- In Gnome: paru nautilus-dropbox
- In KDE:
  - paru dolphin-plugins
  - Open dolphin
  - Go to Configure
  - Configure Dolphinnetwork-manager-applet
  - Context Menu
  - Click on the Dropbox checkbox

## Notifycations

- paru libnotify
- paru dunst

## Hyprland

- paru hyprland
- paru -S htop iwd kitty ghostty qt5-wayland uwsm wget wireless_tools wofi wget xdg-utils xdg-desktop-portal-hyprland
- paru network-manager-applet
- paru wl-clipboard
- paru nautilus
- paru waybar
- paru dropbox dolphin-plugins
- paru nautilus-dropbox
- paru pipewire
- paru pipewire-pulse
- paru pavucontrol
- paru wlogout
- paru unzip
- paru nwg-drawer
- paru blueman
- paru ttf-meslo-nerd
- paru ttf-font-awesome
- paru otf-font-awesome
- paru ttf-arimo-nerd
- paru noto-fonts
- paru hyprpaper
- paru hyprlock
- paru hypridle
- paru yad
- paru brightnessctl
- paru yazi
- paru kwalletmanager -> Disable kwallet
- paru brave-bin
