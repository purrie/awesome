local defaults = {}
local theme = require("theme-defaults")

for key, value in pairs(theme) do
  defaults[key] = value
end

-- This is used later as the default terminal and editor to run.
defaults.terminal = "alacritty"
defaults.editor = os.getenv("EDITOR") or "nvim"
defaults.editor_cmd = defaults.terminal .. " -e " .. defaults.editor
defaults.home = os.getenv("HOME")

-- Default modkey. Super key.
defaults.modkey = "Mod4"
defaults.altlkey = "Mod1"
defaults.altrkey = "Mod5"

return defaults
