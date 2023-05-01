cd "$(dirname "$0")"

sudo rm -rf kde/
mkdir kde/
cd kde/
mkdir -p usr/share/
sudo cp -rf /usr/share/plasma/ usr/share/plasma/
sudo cp -rf /usr/share/wallpapers/ usr/share/wallpapers/
mkdir -p \$USER/.local/share/
sudo cp -rf ~/.local/share/plasma/ \$USER/.local/share/plasma/
sudo cp -rf ~/.local/share/latte-layouts/ \$USER/.local/share/latte-layouts/
mkdir -p \$USER/.config/
sudo cp -rf ~/.config/latte/ \$USER/.config/latte/
mkdir -p \$USER/.local/share/konsole
sudo cp -rf ~/.local/share/konsole/ \$USER/.local/share/konsole/
