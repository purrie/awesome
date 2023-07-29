---Load Core Libraries---------------------------------------------------------
pcall(require, "luarocks.loader")
local naughty = require("naughty")
local dpi = require("beautiful.xresources").apply_dpi
local menubar = require("menubar")
local defaults = require("defaults")
require("awful")
require("gears")
require("awful.autofocus")

-- Theme handling library
require("beautiful")
require("awful.hotkeys_popup")

-- Widget and layout library
require("wibox")

---Error Handling---------------------------------------------------------------
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end

---Defaults---------------------------------------------------------------------
menubar.utils.terminal = defaults.terminal -- Set the terminal for applications that require it

naughty.config.defaults = {
    timeout = 10,
    text = "",
    screen = defaults.notification_screen or 1,
    ontop = true,
    margin = dpi(10),
    border_width = dpi(2),
    position = "top_left"
}

-- setting up random seed for other modules
math.randomseed(os.time())

---Core Config------------------------------------------------------------------
require("themeing")
require("window-layouts")
require("top-bar")
require("key-bindings")
require("client-bindings")
require("window-rules")
require("client-signals")
