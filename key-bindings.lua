local gears = require("gears")
local awful = require("awful")
local hotkeys_popup = require("awful.hotkeys_popup")
local defaults = require("defaults")
local launcher = require("launcher-menu")
local menubar = require("menubar")
local audio = require("audio-widgets")

local modkey = defaults.modkey
local lalt   = defaults.altlkey

-- {{{ Key bindings
local globalkeys = gears.table.join(
    -- tag bindings
    awful.key(
        { modkey, "Shift" }, "/",
        hotkeys_popup.show_help,
        { description="show help", group="awesome" }
    ),
    awful.key(
        { modkey }, "Left",
        awful.tag.viewprev,
        { description = "view previous", group = "tag" }
    ),
    awful.key(
        { modkey }, "Right",
        awful.tag.viewnext,
        { description = "view next", group = "tag" }
    ),
    awful.key(
        { modkey }, "Escape",
        awful.tag.history.restore,
        { description = "go back", group = "tag" }
    ),

    -- client manipulation
    awful.key(
        { modkey }, "j",
        function ()
            awful.client.focus.byidx(1)
        end,
        { description = "focus next by index", group = "client" }
    ),
    awful.key(
        { modkey }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        { description = "focus previous by index", group = "client" }
    ),
    awful.key(
        { modkey, "Shift" }, "t",
        function ()
            local c = client.focus
            if c then
                awful.titlebar.toggle(c)
            end
        end,
        { description = "toggle client titlebar", group = "client" }
    ),
    awful.key(
        { modkey, "Shift" }, "f",
        function ()
            local c = client.focus
            if c then
                c.floating = not c.floating
                c.ontop = c.floating
            end
        end,
        { description = "toggle client titlebar", group = "client" }
    ),

    -- launcher menu
    awful.key(
        { modkey }, "w",
        function () launcher.main_menu:show() end,
        { description = "show main menu", group = "awesome" }
    ),

    -- Layout manipulation
    awful.key(
        { modkey, "Shift" }, "j",
        function () awful.client.swap.byidx(1)    end,
        { description = "swap with next client by index", group = "client" }
    ),
    awful.key(
        { modkey, "Shift"   }, "k",
        function () awful.client.swap.byidx(-1)    end,
        { description = "swap with previous client by index", group = "client" }
    ),

    -- focus switching
    awful.key(
        { modkey, "Control" }, "j",
        function () awful.screen.focus_relative(1) end,
        { description = "focus the next screen", group = "screen" }
    ),
    awful.key(
        { modkey, "Control" }, "k",
        function () awful.screen.focus_relative(-1) end,
        { description = "focus the previous screen", group = "screen" }
    ),
    awful.key(
        { modkey, }, "u",
        awful.client.urgent.jumpto,
        { description = "jump to urgent client", group = "client" }
    ),
    awful.key(
        { modkey, }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        { description = "go back", group = "client" }
    ),

    -- System commands
    awful.key(
        { modkey, }, "Return",
        function () awful.spawn(defaults.terminal) end,
        { description = "open a terminal", group = "system" }
    ),
    awful.key(
        { modkey, "Shift" }, "r",
        awesome.restart,
        { description = "reload awesome", group = "system" }
    ),
    awful.key(
        { modkey, "Shift" }, "q",
        awesome.quit,
        { description = "quit awesome", group = "system" }
    ),
    awful.key(
        { modkey, "Shift", "Control" }, "l",
        function ()
            awful.prompt.run {
                prompt       = "Run Lua code: ",
                textbox      = awful.screen.focused().mypromptbox.widget,
                exe_callback = awful.util.eval,
                history_path = awful.util.get_cache_dir() .. "/history_eval"
            }
        end,
        { description = "lua execute prompt", group = "system" }
    ),

    -- Launchers
    awful.key(
        { modkey }, "p",
        function() menubar.show() end,
        { description = "show the menubar", group = "launcher" }
    ),
    awful.key(
        { modkey }, "s",
        launcher.web_search,
        { description = "perform search", group = "launcher" }
    ),
    awful.key(
        { modkey }, "r",
        function () awful.screen.focused().mypromptbox:run() end,
        { description = "run prompt", group = "launcher" }
    ),

    -- Programs
    awful.key(
        { modkey }, "b",
        function() awful.spawn("brave") end,
        { description = "Open Brave web browser", group = "program" }
    ),
    awful.key(
        { modkey }, "x",
        function() awful.spawn("emacsclient -c -a emacs") end,
        { description = "Open emacs editor", group = "program" }
    ),

    -- Layouts
    awful.key(
        { modkey }, "l",
        function () awful.tag.incmwfact(0.05) end,
        { description = "increase master width factor", group = "layout" }
    ),
    awful.key(
        { modkey }, "h",
        function () awful.tag.incmwfact(-0.05) end,
        { description = "decrease master width factor", group = "layout" }
    ),
    awful.key(
        { modkey, "Shift" }, "h",
        function () awful.tag.incnmaster(1, nil, true) end,
        { description = "increase the number of master clients", group = "layout" }
    ),
    awful.key(
        { modkey, "Shift" }, "l",
        function () awful.tag.incnmaster(-1, nil, true) end,
        { description = "decrease the number of master clients", group = "layout" }
    ),
    awful.key(
        { modkey, "Control" }, "h",
        function () awful.tag.incncol(1, nil, true) end,
        { description = "increase the number of columns", group = "layout" }
    ),
    awful.key(
        { modkey, "Control" }, "l",
        function () awful.tag.incncol(-1, nil, true) end,
        { description = "decrease the number of columns", group = "layout" }
    ),
    awful.key(
        { modkey, }, "space",
        function () awful.layout.inc(1) end,
        { description = "select next", group = "layout" }
    ),
    awful.key(
        { modkey, "Shift" }, "space",
        function () awful.layout.inc(-1) end,
        { description = "select previous", group = "layout" }
    ),

    awful.key(
        { modkey, "Control" }, "n",
        function ()
            local c = awful.client.restore()
            -- Focus restored client
            if c then
                c:emit_signal(
                    "request::activate", "key.unminimize", {raise = true}
                )
            end
        end,
        { description = "restore minimized", group = "client" }
    ),

    -- Audio control
    awful.key(
        {}, "XF86AudioMute",
        audio.sound_mute,
        { description = "Mute audio", group = "media" }
    ),
    awful.key(
        {}, "XF86AudioLowerVolume",
        audio.sound_volume_down,
        { description = "Lower audio", group = "media" }
    ),
    awful.key(
        {}, "XF86AudioRaiseVolume",
        audio.sound_volume_up,
        { description = "Raise audio", group = "media" }
    ),

    awful.key(
        { lalt }, "XF86AudioMute",
        audio.microphone_mute,
        { description = "Mute microphone", group = "media" }
    ),
    awful.key(
        { lalt }, "XF86AudioLowerVolume",
        audio.microphone_volume_down,
        { description = "Lower microphone volume", group = "media" }
    ),
    awful.key(
        { lalt }, "XF86AudioRaiseVolume",
        audio.microphone_volume_up,
        { description = "Raise microphone volume", group = "media" }
    ),

    awful.key(
        {}, "XF86AudioPlay",
        function() awful.spawn.with_shell("media-player -t") end,
        { description = "Toggle play media player", group = "media" }
    ),
    awful.key(
        {}, "XF86AudioNext",
        function() awful.spawn.with_shell("media-player -f") end,
        { description = "Play next song", group = "media" }
    ),
    awful.key(
        {}, "XF86AudioPrev",
        function() awful.spawn.with_shell("media-player -r") end,
        { description = "Play previous song", group = "media" }
    ),
    awful.key(
        { lalt }, "XF86AudioNext",
        function() awful.spawn.with_shell("media-player --seek-by 10") end,
        { description = "Skip 10 seconds forward", group = "media" }
    ),
    awful.key(
        { lalt }, "XF86AudioPrev",
        function() awful.spawn.with_shell("media-player --seek-by -10") end,
        { description = "Rewind 10 seconds back", group = "media" }
    )
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key(
            { modkey }, "#" .. i + 9,
            function ()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                    tag:view_only()
                end
            end,
            { description = "view tag #"..i, group = "tag" }
        ),

        -- Toggle tag display.
        awful.key(
            { modkey, "Control" }, "#" .. i + 9,
            function ()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                    awful.tag.viewtoggle(tag)
                end
            end,
            { description = "toggle tag #" .. i, group = "tag" }
        ),

        -- Move client to tag.
        awful.key(
            { modkey, "Shift" }, "#" .. i + 9,
            function ()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:move_to_tag(tag)
                    end
                end
            end,
            { description = "move focused client to tag #"..i, group = "tag" }
        ),

        -- Toggle tag on focused client.
        awful.key(
            { modkey, "Control", "Shift" }, "#" .. i + 9,
            function ()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:toggle_tag(tag)
                    end
                end
            end,
            { description = "toggle focused client on tag #" .. i, group = "tag" }
        ),

        -- Move client to tag and switch to that tag
        awful.key(
            { modkey, defaults.altrkey }, "#" .. i + 9,
            function ()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:move_to_tag(tag)
                        tag:view_only()
                    end
                end
            end,
            {
                description = "Move focused client to tag #" .. i .. " and switch to this tag",
                group = "tag"
            }
        ),
        awful.key(
            { modkey, defaults.altlkey }, "#" .. i + 9,
            function ()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:move_to_tag(tag)
                        tag:view_only()
                    end
                end
            end,
            {
                description = "Move focused client to tag #" .. i .. " and switch to this tag",
                group = "tag"
            }
        )
    )
end

root.keys(globalkeys)

-- {{{ Mouse bindings for the desktop
-- root.buttons(gears.table.join(
--     awful.button({ }, 3, function () mymainmenu:toggle() end),
--     awful.button({ }, 4, awful.tag.viewnext),
--     awful.button({ }, 5, awful.tag.viewprev)
-- ))
-- }}}
