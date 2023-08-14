if [ "$(id -u)" = 0 ]; then
    echo "##################################################################"
    echo "This script MUST NOT be run as root user since it makes changes"
    echo "to the \$HOME directory of the \$USER executing this script."
    echo "The \$HOME directory of the root user is, of course, '/root'."
    echo "We don't want to mess around in there. So run this script as a"
    echo "normal user. You will be asked for a sudo password when necessary."
    echo "##################################################################"
    exit 1
fi

cd "$(dirname "$0")"

if [[ -f "/usr/bin/gnome-session" ]]; then
    gnome=true
else
    gnome=false
fi
if [[ -f "/usr/bin/plasma_session" ]]; then
    kde=true
else
    kde=false
fi

if [[ "$XDG_CURRENT_DESKTOP" = "" ]]; then
    current_desktop=$(echo "$XDG_DATA_DIRS" | sed 's/.*\(gnome\|kde\).*/\1/')
else
    current_desktop=$XDG_CURRENT_DESKTOP
fi
current_desktop=${current_desktop,,}

# How much "stuff" should be installed
# Possible values are 'full', 'lite', and 'base'
if [[ -z "$1" ]]; then
    if [[ -z "${complexity}" ]]; then
        complexity="lite"
    else
        complexity="${complexity}"
    fi
else
    complexity="$1"
fi

# Power Management
# Possible values are 'none', 'power-profiles-daemon', 'tlp', 'auto-cpufreq', 'auto-cpufreq+tlp', 'laptop-mode-tools', and 'powertop'
if [[ -z "$2" ]]; then
    if [[ -z "${power_management}" ]]; then
        power_management="auto-cpufreq+tlp"
    else
        power_management="${power_management}"
    fi
else
    power_management="$2"
fi
if [[ -z "$3" ]]; then
    if [[ -z "${install_thermald}" ]]; then
        install_thermald=true
    else
        install_thermald="${install_thermald}"
    fi
else
    install_thermald="$3"
fi

if [[ -z "$4" ]]; then
    if [[ -z "${parallel_downloads}" ]]; then
        parallel_downloads=7
    else
        parallel_downloads="${parallel_downloads}"
    fi
else
    parallel_downloads="$4"
fi

if [[ -z "$5" ]]; then
    if [[ -z "${ssh_port}" ]]; then
        ssh_port=22
    else
        ssh_port="${ssh_port}"
    fi
else
    ssh_port="$5"
fi

if [[ -z "$6" ]]; then
    if [[ -z "${install_vm}" ]]; then
        install_vm=true
    else
        install_vm="${install_vm}"
    fi
else
    install_vm="$6"
fi

if [[ -z "$7" ]]; then
    if [[ -z "${install_libreoffice}" ]]; then
        install_libreoffice=false
    else
        install_libreoffice="${install_libreoffice}"
    fi
else
    install_libreoffice="$7"
fi

if [[ -z "$8" ]]; then
    if [[ -z "${install_davinci_resolve}" ]]; then
        install_davinci_resolve=false
    else
        install_davinci_resolve="${install_davinci_resolve}"
    fi
else
    install_davinci_resolve="$8"
fi

if [[ -z "$9" ]]; then
    if [[ -z "${install_prismlauncher}" ]]; then
        install_prismlauncher=false
    else
        install_prismlauncher="${install_prismlauncher}"
    fi
else
    install_prismlauncher="$9"
fi

if [[ -z "${10}" ]]; then
    if [[ -z "${install_aseprite}" ]]; then
        install_aseprite=true
    else
        install_aseprite="${install_aseprite}"
    fi
else
    install_aseprite="${10}"
fi

if [[ -z "${11}" ]]; then
    if [[ -z "${install_pentablet}" ]]; then
        install_pentablet=true
    else
        install_pentablet="${install_pentablet}"
    fi
else
    install_pentablet="${11}"
fi

if [[ -z "${12}" ]]; then
    if [[ -z "${install_pop_shell}" ]]; then
        install_pop_shell=false
    else
        install_pop_shell="${install_pop_shell}"
    fi
else
    install_pop_shell="${12}"
fi


cd ~
mkdir Code/

sudo sed -i "s/#Color/Color/" /etc/pacman.conf
sudo sed -i "s/#ParallelDownloads = 5/ParallelDownloads = $parallel_downloads/" /etc/pacman.conf

sudo pacman -S --needed git curl base-devel
if ! [ -x "$(command -v paru)" ]; then
    git clone https://aur.archlinux.org/paru-bin.git
    cd paru-bin/
    makepkg -si
    paru -Syu
    cd ..
    rm -rf paru-bin/
fi

paru -S --needed pacman-contrib wget linux-headers v4l2loopback-dkms
paru -S --needed man-db man-pages

paru -S --needed i2c-tools lm_sensors
sudo sh -c "echo i2c-dev > /etc/modules-load.d/i2c-dev.conf"
sudo modprobe i2c-dev

paru -S --needed bluez bluez-utils
if [ "$gnome" = true ]; then
    paru -S --needed gnome-bluetooth-3.0 nautilus-bluetooth
fi
sudo systemctl enable --now bluetooth.service

paru -S --needed easyeffects easyeffects-presets calf noisetorch noise-suppression-for-voice

if [ "$kde" = true ]; then
    if [[ $complexity = "full" ]] || [[ $complexity = "lite" ]]; then
        paru -S --needed packagekit-qt5 kwalletmanager ksshaskpass kwallet-pam kdeconnect
        git config --global core.askpass /usr/bin/ksshaskpass
    fi
    paru -S --needed latte-dock
fi

paru -S --needed rustup
rustup default stable

paru -S --needed make python python-pip python-pipx tk npm yarn
pipx ensurepath
eval "$(register-python-argcomplete pipx)"
. ~/.bashrc

if [[ $complexity = "full" ]] || [[ $complexity = "lite" ]]; then
    paru -S --needed jdk-temurin jdk16-adoptopenjdk jdk8-openjdk tk dart kotlin android-tools typescript docker docker-compose usbfluxd dotnet-sdk-6.0
    sudo gpasswd -a $USER flutterusers
fi
paru -S --needed neovim neofetch pfetch-rs cmatrix starship ffmpeg github-cli cdrkit rsync wl-clipboard
if [[ $ssh_port -ne -1 ]]; then
    paru -S --needed openssh sshuttle
fi
if [[ $complexity = "full" ]] || [[ $complexity = "lite" ]]; then
    paru -S --needed tmux openvpn networkmanager-openvpn network-manager-applet
fi
paru -S --needed resolvconf iio-sensor-proxy
paru -S --needed dconf-editor libappindicator-gtk3 gtk-engine-murrine

if [ "$gnome" = true ]; then
    paru -S --needed extension-manager gdm-tools gnome-browser-connector gnome-themes-standard libgda gsound
fi
if [[ $complexity = "full" ]] || [[ $complexity = "lite" ]]; then
    paru -S --needed gparted obsidian newsflash brave-beta-bin evince element-desktop
fi
if [ "$install_libreoffice" = true ]; then
    paru -S --needed libreoffice-fresh libreoffice-extension-texmaths libreoffice-extension-writer2latex libreoffice-extension-languagetool hunspell hunspell-en_us libmythes mythes-en
fi
paru -S --needed firefox firefox-extension-arch-search
if [ "$install_davinci_resolve" = true ]; then
    paru -S --needed davinci-resolve
fi
if [ "$install_prismlauncher" = true ]; then
    paru -S --needed prismlauncher
fi
if [ "$install_aseprite" = true ]; then
    paru -S --needed aseprite
fi
if [[ $complexity = "full" ]]; then
    paru -S --needed deskreen-bin krita
    paru -S --needed gamemode lutris steam steamcmd proton-ge-custom-bin wine-ge-custom
    paru -S --needed blender

    #paru -S --needed keyleds

    paru -S --needed libusb
    cd Code/
    git clone https://github.com/DaRubyMiner360/g810-led.git
    cd g810-led/
    make bin LIB=libusb
    sudo make install

    sudo modprobe uinput
    cd Code/
    git clone https://github.com/MR-R080T/g910-gkey-macro-support.git
    cd g910-gkey-macro-support/
    chmod +x installer-systemd.sh; sudo ./installer-systemd.sh
    sudo systemctl enable --now g910-gkeys.service
    cd ~

    paru -S --needed openrgb-git
    paru -S --needed openrazer-meta razergenie
    sudo gpasswd -a $USER plugdev
fi
if [ "$install_vm" = true ]; then
    paru -S --needed qemu-full virt-manager virt-viewer dnsmasq
    sudo systemctl enable --now libvirtd
fi

if [[ $ssh_port -ne -1 ]]; then
    sudo sed -i "s/#Port 22/Port $ssh_port/" /etc/ssh/sshd_config
    sudo systemctl enable --now sshd.service
fi

if [[ $complexity = "full" ]] || [[ $complexity = "lite" ]]; then
    paru -S --needed discord
    mkdir -p ~/.config/discord
    cat << EOT > ~/.config/discord/settings.json
{
  "IS_MAXIMIZED": true,
  "IS_MINIMIZED": false,
  "SKIP_HOST_UPDATE": true
}
EOT
fi

if [[ $complexity = "full" ]] || [[ $complexity = "lite" ]]; then
    paru -S --needed tilix

    cd Code/
    git clone https://github.com/Gogh-Co/Gogh.git gogh
    cd gogh/installs/
    export TERMINAL="tilix"
    ./afterglow.sh
    ./argonaut.sh
    ./atom.sh
    ./blazer.sh
    ./broadcast.sh
    ./chalk.sh
    ./chalkboard.sh
    ./ciapre.sh
    ./darkside.sh
    ./dimmed-monokai.sh
    ./dracula.sh
    ./flat-remix.sh
    ./hardcore.sh
    ./oceanic-next.sh
    ./tokyo-night-storm.sh
    ./tokyo-night.sh
    cd ~
fi

# none, power-profiles-daemon, tlp, auto-cpufreq, auto-cpufreq+tlp
if [[ $power_management = "power-profiles-daemon" ]]; then
    paru -S --needed power-profiles-daemon
    sudo systemctl enable --now power-profiles-daemon.service
elif [[ $power_management = "tlp" ]]; then
    paru -S --needed tlp tlpui
    sudo systemctl enable --now tlp.service
    sudo tlp start
elif [[ $power_management = "auto-cpufreq" ]]; then
    cd Code/
    git clone https://github.com/AdnanHodzic/auto-cpufreq.git
    cd auto-cpufreq/
    sudo ./auto-cpufreq-installer
    sudo auto-cpufreq --install
    cd ~
elif [[ $power_management = "auto-cpufreq+tlp" ]]; then
    paru -S --needed tlp tlpui
    sudo systemctl enable --now tlp.service
    sudo tlp start

    cd Code/
    git clone https://github.com/AdnanHodzic/auto-cpufreq.git
    cd auto-cpufreq/
    sudo ./auto-cpufreq-installer
    sudo auto-cpufreq --install
    cd ~
elif [[ $power_management = "laptop-mode-tools" ]]; then
    paru -S --needed laptop-mode-tools
    sudo systemctl enable --now laptop-mode.service
elif [[ $power_management = "powertop" ]]; then
    paru -S --needed powertop
    sudo sh -c "echo -e '[Unit]\nDescription=PowerTop\n\n[Service]\nType=oneshot\nRemainAfterExit=true\nExecStart=/usr/bin/powertop --auto-tune\n\n[Install]\nWantedBy=multi-user.target\n' > /etc/systemd/system/powertop.service"
    sudo systemctl enable --now powertop.service
fi
if [ "$install_thermald" = true ]; then
    paru -S --needed thermald
    sudo systemctl enable --now thermald.service
fi

if [[ $complexity = "full" ]] || [[ $complexity = "lite" ]]; then
    paru -S --needed distrobox
    xhost +si:localuser:$USER
    xhost -
fi

pip install Pillow

if [ "$install_pentablet" = true ]; then
    # Install drivers for my drawing tablet
    # TODO: Maybe find a solution for updates
    wget https://www.xp-pen.com/download/file/id/1936/pid/300/ext/gz.html -O xp-pen-pentablet.tar.gz
    tar -xvf xp-pen-pentablet.tar.gz --one-top-level
    cd xp-pen-pentablet/*
    sudo ./install.sh
    cd ../../
    rm -rf xp-pen-pentablet/
    rm xp-pen-pentablet.tar.gz
    sudo rm /etc/xdg/autostart/xppentablet.desktop
fi

git clone https://github.com/DaRubyMiner360/nvim.git ~/.config/nvim
nvim +PlugInstall +q2

if [ "$gnome" = true ]; then
    pipx install gnome-extensions-cli --system-site-packages

    gext disable apps-menu@gnome-shell-extensions.gcampax.github.com
    gext disable auto-move-windows@gnome-shell-extensions.gcampax.github.com
    gext disable launch-new-instance@gnome-shell-extensions.gcampax.github.com
    gext disable places-menu@gnome-shell-extensions.gcampax.github.com
    gext enable drive-menu@gnome-shell-extensions.gcampax.github.com
    gext disable screenshot-window-sizer@gnome-shell-extensions.gcampax.github.com
    gext enable user-theme@gnome-shell-extensions.gcampax.github.com
    gext disable window-list@gnome-shell-extensions.gcampax.github.com
    gext enable windowsNavigator@gnome-shell-extensions.gcampax.github.com
    gext disable workspace-indicator@gnome-shell-extensions.gcampax.github.com

    # Download AATWS - Advanced Alt-Tab Window Switcher
    gext install advanced-alt-tab@G-dH.github.com
    gext disable advanced-alt-tab@G-dH.github.com
    # Download AppIndicator and KStatusNotifierItem Support
    gext install appindicatorsupport@rgcjonas.gmail.com
    gext enable appindicatorsupport@rgcjonas.gmail.com
    # Download Aylur's Widgets
    gext install widgets@aylur
    gext disable widgets@aylur
    # Download Blur my Shell
    gext install blur-my-shell@aunetx
    gext enable blur-my-shell@aunetx
    # Download Burn My Windows
    gext install burn-my-windows@schneegans.github.com
    gext disable burn-my-windows@schneegans.github.com
    # Download Click to close overview
    gext install click-to-close-overview@l3nn4rt.github.io
    gext enable click-to-close-overview@l3nn4rt.github.io
    # Download Clipboard Indicator
    gext install clipboard-indicator@tudmotu.com
    gext enable clipboard-indicator@tudmotu.com
    # Download Compiz alike magic lamp effect
    gext install compiz-alike-magic-lamp-effect@hermes83.github.com
    gext disable compiz-alike-magic-lamp-effect@hermes83.github.com
    # Download Compiz windows effect
    gext install compiz-windows-effect@hermes83.github.com
    gext disable compiz-windows-effect@hermes83.github.com
    # Download Coverflow Alt-Tab
    gext install CoverflowAltTab@palatis.blogspot.com
    gext disable CoverflowAltTab@palatis.blogspot.com
    # Download Custom Accent Colors
    gext install custom-accent-colors@demiskp
    gext disable custom-accent-colors@demiskp
    # Download Desktop Cube
    gext install desktop-cube@schneegans.github.com
    gext disable desktop-cube@schneegans.github.com
    # Download Fly-Pie
    gext install flypie@schneegans.github.com
    gext disable flypie@schneegans.github.com
    # Download Forge
    gext install forge@jmmaranan.com
    gext disable forge@jmmaranan.com
    # Download Gesture Improvements
    gext install gestureImprovements@gestures
    gext enable gestureImprovements@gestures
    # Download Gnome 4x UI Improvements
    gext install gnome-ui-tune@itstime.tech
    gext enable gnome-ui-tune@itstime.tech
    # Download GSConnect
    gext install gsconnect@andyholmes.github.io
    gext disable gsconnect@andyholmes.github.io
    # Download Gtk4 Desktop Icons NG
    gext install gtk4-ding@smedius.gitlab.com
    gext disable gtk4-ding@smedius.gitlab.com
    # Download Just Perfection
    gext install just-perfection-desktop@just-perfection
    gext enable just-perfection-desktop@just-perfection
    # Download Lock Keys
    gext install lockkeys@vaina.lt
    gext enable lockkeys@vaina.lt
    # Download Looking Glass Button
    gext install lgbutton@glerro.gnome.gitlab.io
    gext disable lgbutton@glerro.gnome.gitlab.io
    # Download Native Window Placement
    gext install native-window-placement@gnome-shell-extensions.gcampax.github.com
    gext disable native-window-placement@gnome-shell-extensions.gcampax.github.com
    # Download Night Theme Switcher
    gext install nightthemeswitcher@romainvigier.fr
    gext disable nightthemeswitcher@romainvigier.fr
    # Download Order Gnome Shell extensions
    gext install order-extensions@wa4557.github.com
    gext enable order-extensions@wa4557.github.com
    # Download Quick Close in Overview
    gext install middleclickclose@paolo.tranquilli.gmail.com
    gext enable middleclickclose@paolo.tranquilli.gmail.com
    # Download Rounded Window Corners
    gext install rounded-window-corners@yilozt
    gext enable rounded-window-corners@yilozt
    # Download Space Bar
    gext install space-bar@luchrioh
    gext enable space-bar@luchrioh
    # Download Status Area Horizontal Spacing
    gext install status-area-horizontal-spacing@mathematical.coffee.gmail.com
    gext enable status-area-horizontal-spacing@mathematical.coffee.gmail.com
    # Download Transparent Window Moving
    gext install transparent-window-moving@noobsai.github.com
    gext enable transparent-window-moving@noobsai.github.com
    # Download Tray Icons: Reloaded
    gext install trayIconsReloaded@selfmade.pl
    gext disable trayIconsReloaded@selfmade.pl
    # Download Unblank lock screen
    gext install unblank@sun.wxg@gmail.com
    gext enable unblank@sun.wxg@gmail.com
    # Download Vitals
    gext install Vitals@CoreCoding.com
    gext disable Vitals@CoreCoding.com
    # Download V-Shell (Vertical Workspaces)
    gext install vertical-workspaces@G-dH.github.com
    gext disable vertical-workspaces@G-dH.github.com
    # Download Workspace Matarix
    gext install wsmatrix@martin.zurowietz.de
    gext disable wsmatrix@martin.zurowietz.de

    cd Code/
    git clone https://github.com/DaRubyMiner360/soft-brightness.git
    cd soft-brightness/
    meson build
    ninja -C build install
    gext enable soft-brightness@fifi.org
    cd ~/Code/
    rm -rf soft-brightness/
    cd ~

    cd Code/
    git clone https://github.com/DaRubyMiner360/dash2dock-lite.git
    cd dash2dock-lite/
    make
    gext enable dash2dock-lite@icedman.github.com
    cd ~/Code/
    rm -rf dash2dock-lite/
    cd ~

    cd Code/
    git clone https://github.com/lofilobzik/gdm-auto-blur.git
    cd gdm-auto-blur/
    mkdir -p ~/.local/bin/
    cp gdm-auto-blur.py ~/.local/bin/gdm-auto-blur
    cd ~/.local/bin/
    chmod +x gdm-auto-blur
    cd ~/Code/
    rm -rf gdm-auto-blur/
    cd ~

    git clone https://github.com/DaRubyMiner360/AutoGDMWallpaper.git ~/.local/share/gnome-shell/extensions/autogdmwallpaper@darubyminer360.github.com/

    git clone https://github.com/DaRubyMiner360/GNOME-LockdownMode.git ~/.local/share/gnome-shell/extensions/lockdown-mode@darubyminer360.github.com/
    cd ~/.local/share/gnome-shell/extensions/lockdown-mode@darubyminer360.github.com/
    sudo ./compile_schemas.sh
    gext enable lockdown-mode@darubyminer360.github.com
    cd ~
    
    if [ "$install_pop_shell" = true ]; then
        echo ""
        echo ""
        tput bold
        echo "NOTICE: For some currently unknown reason, Pop Shell might break your GNOME session on first install. If it does, press CTRL+C to restart GNOME when you get to a black screen, and then rerun the script to continue from where you left off. If you have already seen this message during this installation, you should be fine."
        tput sgr0
        read -s -n 1 -p "Press any key to continue..." && echo ""
        paru -S --needed gnome-shell-extension-pop-shell
        gsettings --schemadir ~/.local/share/gnome-shell/extensions/pop-shell@system76.com/schemas set org.gnome.shell.extensions.pop-shell activate-launcher "['<Super>space']"
        gext disable pop-shell@system76.com
    fi

    cd Code/
    git clone https://github.com/vinceliuice/Colloid-icon-theme
    cd Colloid-icon-theme/
    ./install.sh
    cd ~/Code/
    rm -rf Colloid-icon-theme/
    cd ~

    cd Code/
    git clone https://github.com/vinceliuice/Lavanda-gtk-theme
    cd Lavanda-gtk-theme/
    ./install.sh
    cd ~/Code/
    rm -rf Lavanda-gtk-theme/
    cd ~

    cd Code/
    git clone https://github.com/4e6anenk0/Rowaita-icon-theme
    cd Rowaita-icon-theme/
    cp -r Rowaita/ ~/.local/share/icons/
    cp -r Rowaita-Default-Dark/ ~/.local/share/icons/
    cp -r Rowaita-Default-Light/ ~/.local/share/icons/
    cp -r Rowaita-Adw-Dark/ ~/.local/share/icons/
    cp -r Rowaita-Adw-Light/ ~/.local/share/icons/
    cp -r Rowaita-Manjaro-Dark/ ~/.local/share/icons/
    cp -r Rowaita-Manjaro-Light/ ~/.local/share/icons/
    cd ~/Code/
    rm -rf Rowaita-icon-theme/
    cd ~

    cd Code/
    git clone https://github.com/imarkoff/Marble-shell-theme.git
    cd Marble-shell-theme/
    python install.py -a
    cd ~/Code/
    rm -rf Marble-shell-theme/
    cd ~

    sudo cp -r ~/.themes/* /usr/share/themes/
    sudo cp -r ~/.local/share/icons/* /usr/share/icons/
fi

cd Code/
git clone https://github.com/vinceliuice/grub2-themes.git
cd grub2-themes/
sudo ./install.sh -t tela -i color -s 1080p
cd ~

cd Code/
git clone https://github.com/DaRubyMiner360/PrettyBash.git
cd PrettyBash/
yes | ./setup-arch.sh
cd ~


if ! grep -q "source $HOME/rubyarch.bashrc" ~/.bashrc; then
  cat <<EOT >> ~/.bashrc
source $HOME/rubyarch.bashrc
EOT
fi
rm -f ~/rubyarch.bashrc
cat <<EOT > ~/rubyarch.bashrc
EOT
if [ "$install_pentablet" = true ]; then
    cat <<EOT >> ~/rubyarch.bashrc
alias pentablet="/usr/lib/pentablet/pentablet"
alias xppentablet="pentablet"

EOT
fi
cat <<EOT >> ~/rubyarch.bashrc
alias ls="ls --color=auto -a"
alias grep="grep --color=auto"

alias cpa="rsync -ah --progress"
alias cpab="rsync -ah --info=progress2 --no-inc-recursive --progress"
alias cpap="rsync -ah --progress --partial --append"
alias cpapb="rsync -ah --info=progress2 --no-inc-recursive --progress --partial --append"

alias clipboard="wl-copy --trim-newline"
alias clipboardn="wl-copy"
alias clip="clipboard"
alias clipn="clipboardn"

export TERMINAL="tilix"

EOT
if [[ $complexity = "full" ]] || [[ $complexity = "lite" ]]; then
    cat <<EOT >> ~/rubyarch.bashrc
alias parrotdance="curl parrot.live"
alias rick="curl -L https://raw.githubusercontent.com/keroserene/rickrollrc/master/roll.sh | bash"

EOT
fi
cat <<EOT >> ~/rubyarch.bashrc
echo ""
# neofetch
pfetch
EOT

mkdir ~/.fonts/
cd ~/.fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip
unzip Meslo.zip
rm Meslo.zip
fc-cache -vf
cd ~
paru -S --needed noto-fonts-emoji ttf-joypixels ttf-twemoji otf-openmoji ttf-symbola ttf-twemoji-color-git vscode-codicons-git

wget https://gist.githubusercontent.com/DaRubyMiner360/cc707b5ba7ed68e31f7fb8fc99def457/raw/full-backup
dconf load / < full-backup
bash ~/.local/share/gnome-shell/extensions/autogdmwallpaper@darubyminer360.github.com/switch.sh
rm full-backup

if [ "$kde" = true ]; then
    cd "$(dirname "$0")"

    sudo cp -r kde/* /
    sudo mv /home/\$USER /home/$USER
fi

echo "Done!"
echo "Don't worry if the terminal font's spacing is acting up."
echo "You should probably reboot now to fix some potential issues."
