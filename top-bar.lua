local awful    = require("awful")
local wibox    = require("wibox")
local gears    = require("gears")
local defaults = require("defaults")
local themeing = require("themeing")
local launcher = require("launcher-menu")
local audio    = require("audio-widgets")

-- Keyboard map indicator and switcher
local mykeyboardlayout = awful.widget.keyboardlayout()

-- Create a textclock widget
local mytextclock = wibox.widget.textclock()

-- Extra widgets for the wibar
-- local volume_widget = require('awesome-wm-widgets.pactl-widget.volume')

-- Create a wibox for each screen and add it
local taglist_buttons =
  gears.table.join(
    awful.button({ }, 1, function(t) t:view_only() end),
    awful.button({ defaults.modkey }, 1, function(t)
        if client.focus then
          client.focus:move_to_tag(t)
        end
    end),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ defaults.modkey }, 3, function(t)
        if client.focus then
          client.focus:toggle_tag(t)
        end
    end),
    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
  )

local tasklist_buttons =
  gears.table.join(
    awful.button({ }, 1, function (c)
        if c == client.focus then
          c.minimized = true
        else
          c:emit_signal(
            "request::activate",
            "tasklist",
            {raise = true}
          )
        end
    end),
    awful.button({ }, 3, function()
        awful.menu.client_list({ theme = { width = 250 } })
    end),
    awful.button({ }, 4, function ()
        awful.client.focus.byidx(1)
    end),
    awful.button({ }, 5, function ()
        awful.client.focus.byidx(-1)
    end)
  )

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    themeing.set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

    local tags = s.tags
    for i=1, #tags do
      local tag = tags[i]
      tag.gap_single_client = false
    end

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()

    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(
        gears.table.join(
            awful.button({}, 1, function() awful.layout.inc(1) end),
            awful.button({}, 3, function() awful.layout.inc(-1) end),
            awful.button({}, 4, function() awful.layout.inc(1) end),
            awful.button({}, 5, function() awful.layout.inc(-1) end)
    ))

    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.noempty,
        buttons = taglist_buttons
    }

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons
    }

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s })

    -- Left widgets
    local lefts = {
        layout = wibox.layout.fixed.horizontal,
        mytextclock,
        wibox.widget.systray(),
        launcher.launcher,
        s.mypromptbox,
    }

    -- Right widgets
    local rights = {
        layout = wibox.layout.fixed.horizontal,
        spacing = 3,
        s.mytaglist,
        audio.get_microphone_widget(),
        audio.get_sound_widget(),
        mykeyboardlayout,
        s.mylayoutbox,
    }

    local top_bar = {
        layout = wibox.layout.align.horizontal,
        lefts,
        s.mytasklist,
        rights,
    }

    -- Add widgets to the wibox
    s.mywibox:setup (top_bar)
end)
