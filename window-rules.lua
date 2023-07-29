local awful = require("awful")
local beautiful = require("beautiful")
local client_bindings = require("client-bindings")

-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    {
        rule = { },
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = client_bindings.clientkeys,
            buttons = client_bindings.clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap + awful.placement.no_offscreen
        }
    },

    -- Floating clients.
    {
        rule_any = {
            instance = {
                "DTA",  -- Firefox addon DownThemAll.
                "copyq",  -- Includes session name in class.
                "pinentry",
            },
            class = {
                "Arandr",
                "Blueman-manager",
                "Gpick",
                "Kruler",
                "MessageWin",  -- kalarm.
                "Sxiv",
                "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
                "Wpa_gui",
                "veromix",
                "xtightvncviewer"
            },

            -- Note that the name property shown in xprop might be set slightly after creation of the client
            -- and the name shown there might not match defined rules here.
            name = {
                "Event Tester",  -- xev.
            },
            role = {
                "AlarmWindow",  -- Thunderbird's calendar.
                "ConfigManager",  -- Thunderbird's about:config.
                "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
            }
        },
        properties = { floating = true }
    },

    -- Add titlebars to normal clients and dialogs
    {
        rule_any = {
            type = { "normal" }
        },
        properties = {
            titlebars_enabled = false
        }
    },

    {
        rule_any = {
            type = { "dialog" }
        },
        properties = {
            placement = awful.placement.under_mouse + awful.placement.no_offscreen,
            titlebars_enabled = true,
            floating = true,
            ontop = true
        }
    },

    -- Rules for games
    {
        rule_any = {
            name = {
                "Deep Rock Galactic"
            }
        },
        properties = {
            screen = 1,
        }
    },

    -- Rules for steam subwindows
    {
        rule_any = {
            class = {
                "Steam",
                "steam",
            }
        },
        except_any = {
            name = {
                "Steam",
                "steam",
            }
        },
        properties = {
            floating = true,
            ontop = true,
        }
    }

    -- Set Firefox to always map on the tag named "2" on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = "2" } },
}

-- Gets rid of tmux hotkeys in help popup if the window doesn't have tmux in the title
local tmux = require("awful.hotkeys_popup.keys.tmux")
tmux.add_rules_for_terminal({ rule_any = { name = { "tmux" }}})
