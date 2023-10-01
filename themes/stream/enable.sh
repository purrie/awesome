#!/usr/bin/env bash

echo 'return {' > ~/.config/awesome/theme-defaults.lua
echo '  notification_screen = 2' >> ~/.config/awesome/theme-defaults.lua
echo '}' >> ~/.config/awesome/theme-defaults.lua

echo '[icon theme]' > ~/.icons/default/index.theme
echo 'Inherits=Catppuccin-Macchiato-Mauve-Cursors' >> ~/.icons/default/index.theme

echo '[Settings]' > ~/.config/gtk-3.0/settings.ini
echo 'gtk-application-prefer-dark-theme=1' >> ~/.config/gtk-3.0/settings.ini
echo 'gtk-theme-name=Catppuccin-Macchiato-Standard-Mauve-Dark' >> ~/.config/gtk-3.0/settings.ini
