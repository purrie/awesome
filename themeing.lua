-- local xresources = require("beautiful.xresources")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi
local awful = require("awful")
local gears = require("gears")

local current_theme = require("current-theme")
local theme = require("themes."..current_theme..".theme")

beautiful.init(theme)

local themeing = {}

themeing.set_wallpaper = function(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

themeing.set_theme_name = function(n)
    awful.spawn.with_shell("~/.config/awesome/themes/" .. n .. "/enable.sh" )
    awesome.restart()
end

themeing.update_gaps = function()
      local scr = awful.screen.focused()
      local tag = scr.selected_tag
      tag.gap = dpi(10)
      awful.layout.arrange(scr)
end

return themeing
