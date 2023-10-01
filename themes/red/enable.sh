#!/usr/bin/env bash

echo '[icon theme]' > ~/.icons/default/index.theme
echo 'Inherits=Catppuccin-Macchiato-Red-Cursors' >> ~/.icons/default/index.theme

echo '[Settings]' > ~/.config/gtk-3.0/settings.ini
echo 'gtk-application-prefer-dark-theme=1' >> ~/.config/gtk-3.0/settings.ini
echo 'gtk-theme-name=Catppuccin-Macchiato-Standard-Red-Dark' >> ~/.config/gtk-3.0/settings.ini
