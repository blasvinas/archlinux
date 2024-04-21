# Install Archlinux

## Boot
* Go to the Bios (F2) 
    * Disable Secure Boot 
    * Enable UEFI boot 

* Boot the laptop and hit F12 
 * Choose USB drive 

## Wireless Configuration
* For wireless connection 

    * $ iwctl  
    * [iwd]# device list  
    * [iwd]# station device scan  
    * [iwd]# station device get-networks  
    * [iwd]# station device connect SSID  
    * [iwd]# exit
    * ping google.com 

## Use the install script
* archinstall
* * Include the following packages: git networkmanager wpa_supplicant firefox cups thunderbird libreoffice-fresh bluez bluez-utils gnome-browser-connector  fprintd gnome-tweaks
* pacman -S networkmanager wpa_supplicant hplip
* exit
* reboot
* systemctl enable --now  NetworkManager 
* systemctl enable --now  bluetooth 
* No needed,  just in case. nmtui to configure wireless (you can try nmcli device wifi connect ATTF password <password>  
* sudo vim /etc/sudoers.d/00_blas and add: blas ALL=(ALL) NOPASSWD: ALL

For manual install follow the next steps in Manual Installation

# Install paru
git clone https://aur.archlinux.org/paru.git 
cd paru
makepkg -si 

## Install yay (no needed.  does the same as paru)
* sudo git clone https://aur.archlinux.org/yay.git 
* cd yay 
* makepkg yay 

## Install gnome terminal with transparency
* paru gnome-terminal-transparency

 
## Installer Scaner (no needed in Gnome should be an app called Document Scanner) 
* sudo pacman –S sane 
* Uncomment or add hpaio and hpoj to a new line in /etc/sane.d/dll.conf 
* https://wiki.archlinux.org/index.php/SANE/Scanner-specific_problems 
* paru –S simple-scan 
* paru sane-airscan
* Check the scanner running: hp-makeuri 192.168.1.94
* Scan a document running: scanimage --device "hpaio:/net/ENVY_4520_series?ip=192.168.1.94" --format=png > scan01.png


## Enable bluetooth
* pacman -S bluez bluez-utils
* systemctl start bluetooth
* systemctl enable bluetooth
    
## Install FUSE
Fuse is needed to run AppImages
pacman -S fuse

## Install Dropbox
* paru dropbox
* In Gnome: paru nautilus-dropbox
* In KDE: 
  * paru dolphin-plugins
  * Open dolphin
  * Go to Configure
  * Configure Dolphin
  * Context Menu
  * Click on the Dropbox checkbox

## Gnome extensions
paru extension-manager
sudo pacman -S gnome-browser-connector

## Printer
* sudo pacman -S cups hplip
* sudo systemctl enable --now cups
* In the apps run Manage Printing
* Click on Administration
* Add Printer
* In Dicovered Network Printers select: ENVY 4520 series (HP ENVY 4520 series)
* For the model select: HP Envy 4520 Series, hpcups 3.23.5 (en, en)

## Ledger
paru ledger-live-bin

## Visual Studio Code
* paru visual-studio-code-bin 

## Deja Dup Backup
* sudo pacman -Sy deja-dup
* sudo pacman -S python-requests-oauthlib

## Etcher
* paru polkit-gnomes
* paru etcher-bin

## OneDrive
* paru onedrive-abraunegg 
* From the terminal run:  onedrive --synchronize --verbose --dry-run
* Copy the link shown on the screen and paste it in the browser
* The browser URL will change,  copt the new URL and paste it in it terminal as the response for the URL
* Run onedrive --synchronize --verbose --dry-run to test the connection
* Run onedrive --synchronize to sync the files
* To upload only a specific directory run:  --synchronize --single-directory <directory-name> --upload-only
* To download a specific directory run: onedrive --synchronize --single-directory backup --download-only
* For help run onedrive --help


# Hyprland
* Configure wifi using nmtui
* Configure kitty
    * cp /usr/share/doc/kitty/kitty.conf /home/blas/.config/kitty
    * vim /home/blas/.config/kitty/kitty.conf
        ```
        background_opacity 0.8
        ```
* paru hyprpaper
  * vim .config/hypr/hyprpaper.conf
  ```
    preload = /home/blas/Dropbox/wallpapers/lake-sunrise.jpg
    wallpaper = HDMI-A-1,/home/blas/Dropbox/wallpapers/lake-sunrise.jpg
    wallpaper = eDP-1,/home/blas/Dropbox/wallpapers/lake-sunrise.jpg

    #enable splash text rendering over the wallpaper
    splash = true
  ```

  ## Enable copy in vim
Add the followinf lines to .vimrc
```a
autocmd TextYankPost * if (v:event.operator == 'y' || v:event.operator == 'd') | silent! execute 'call system("wl-copy", @")' | endif
nnoremap p :let @"=substitute(system("wl-paste --no-newline"), '<C-v><C-m>', '', 'g')<cr>p
```

* paru nautilus
* paru waybar
* paru dropbox dolphin-plugins
* paru nautilus-dropbox
* paru pipewire 
* paru pipewire-pulse
* paru pavucontrol
* paru wlogout
* Configure bluetooth runingpary
    * bluetoothctl
    * scan on
    * trust xx:xx:
    * pair xx:xx:
    * connect xx:xx:
    * unblock

* paru unzip
* paru nwg-drawer
* paru blueman
* paru ttf-font-awesome
* paru otf-font-awesome
* paru ttf-arimo-nerd
* paru noto-fonts
* chsh -S /usr/bin/fish
* paru hyprlock
* paru hypridle
* paru yad
* paru brightnessctl
* paru kwalletmanager  -> Disable kwallet
* paru brave-bin
* vim .config/hypr/hyprland.conf and add:
```
# Screen brightness
bind = , XF86MonBrightnessUp, exec, brightnessctl s +5%
bind = , XF86MonBrightnessDown, exec, brightnessctl s 5%- 
```

### fish
* paru fish
* paru fastfetch
* add the fastfetch command to ~/.config/fish/config.fish
* vim /home/blas/.config/fish/functions/fish_prompt and add the following lines:
```
function fish_prompt
   set_color green; echo (pwd)'> '
end
```

### Configure a theme
* Create a directory .themes in your home directory.  For example Sweet-Dark-v40
* gsettings set org.gnome.desktop.interface gtk-theme Sweet-Dark-v40
* gsettings get org.gnome.desktop.interface gtk-theme
* vim .config/hypr/hyprland.conf and add env = GTK_THEME, Sweet-Dark-v40

### Configure a SDDM theme
* Download theme to /usr/share/sddm/themes
* sudo vim /etc/sddm.conf and add
```
[Theme]
Current=<theme-name>
```
* To change the background:
  * copy the images to the theme images directory, for example: /usr/share/sddm/themes/elarun/images
  * cd to the theme directory, for example: /usr/share/sddm/themes/elarun
  * sudo vim theme.conf
  * change the background to the path of your image,  for example:

  ```
  [General]
  background=images/cyber.jpg
  ```
* To check the current theme configuration run:
```
sddm-greeter --test-mode --theme /usr/share/sddm/themes/elarun/
```

### Configure wlogout
The logout functionality does not work on wlogout.  The work around is to create a configuration file in .config/wlogout/layout.  Copy the file from Dropbox/Notes/hyprland.config/wlogout

### Paru in reverse order
* paru packgage --bottomup

### Screenshots
* paru grim
* paru eog
* paru slurp
* Add the following line to hyprland.conf
```
# Screenshots
bind = , Print, exec, grim
# with selection
bind = CTRL, Print, exec, grim -g "$(slurp)"
# current window (pos and size)
bind = ALT, Print, exec, grim -g "$(hyprctl activewindow | grep 'at:' | cut -d':' -f2 | tr -d ' ' | tail -n1) $(hyprctl activewindow | grep 'size:' | cut -d':' -f2 | tr -d ' ' | tail -n1 | sed s/,/x/g)"
```

# Install KDE

pacman -S plasma plasma-wayland-session konsole dolphin 

systemctl enable sddm.service 

## Configure KDE Wallet 

pacman -S kwallet-pam 

vi /etc/pam.d/sddm 

Add the following lines: 

-auth            optional        pam_kwallet5.so 
-session         optional        pam_kwallet5.so  

# Manual Installation

## Disk Configuration
* Check disk layout running lsblk 
* parted /dev/sda 
    * mklabel gpt 
    * mkpart ESP fat32 1MiB 513MiB 
    * set 1 boot on 
    * mkpart primary btrfs 513MiB 100% 
    * quit 
* mkfs.fat -F32 /dev/sda1 
* mkfs.btrfs /dev/sda2 
* mount /dev/sda2 /mnt 
* mkdir -p /mnt/boot 
* mount /dev/sda1 /mnt/boot 


## Install Packages
* pacstrap /mnt base linux linux-firmware vim 

## Configure fstab
* genfstab -U /mnt >> /mnt/etc/fstab 


## Locale Configuration
* arch-chroot /mnt 
* vim /etc/locale.gen and uncomment en_US.UTF-8 UTF-8 
* locale-gen 
* echo LANG=en_US.UTF-8 > /etc/locale.conf 
* export LANG=en_US.UTF-8 


## Configure Grub
* pacman -S grub efibootmgr 
* grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub 
* grub-mkconfig -o /boot/grub/grub.cfg  


## Timezone
* tzselect 
* ln -s /usr/share/zoneinfo/America/New_York /etc/localtime 
* hwclock --systohc 

## Additional steps

* passwd 
* pacman -S networkmanager wpa_supplicant 
* exit 
* umount -R /mnt 
* reboot 
* systemctl start NetworkManager 
* systemctl enable NetworkManager 
* nmtui to configure wireless (you can try nmcli device wifi connect ATTF password <password>  

+++++++++++  Manual steps end here +++++++++++++++++++++++++++++++