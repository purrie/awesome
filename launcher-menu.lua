local awful = require("awful")
local beautiful = require("beautiful")
local hotkeys_popup = require("awful.hotkeys_popup")
local defaults = require("defaults")
local themeing = require("themeing")
local naughty = require("naughty")
local wibox = require("wibox")
local utils = require("utilities")
-- local gears = require("gears")

local launcher = {}

-- Create a launcher widget and a main menu
local myawesomemenu = {
   { "hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
   { "manual", defaults.terminal .. " -e man awesome" },
   { "configure", defaults.editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", function() awesome.quit() end },
   { "reboot", "systemctl reboot" },
   { "suspend", "systemctl suspend" },
   { "power off", "systemctl poweroff" },
}

local themes_menu = {}
local themes_folder = utils.get_dir_contents_blocking(defaults.home .. "/.config/awesome/themes")
for _, name in ipairs(themes_folder) do
	table.insert(themes_menu, { name, function() themeing.set_theme_name(name) end })
end

launcher.main_menu = awful.menu({
    items = {
      { "awesome", myawesomemenu, beautiful.awesome_icon },
      { "theme", themes_menu },
      { "terminal", defaults.terminal }
    }
})

launcher.launcher = awful.widget.launcher({
    image = beautiful.awesome_icon,
    menu = launcher.main_menu
})

--- @class SearchBox
--- @field visible (boolean)
--- @field geometry (function)
local search_box = nil
local input = nil
--- @class Hints
--- @field children (table)
--- @field swap (function)
local hints = nil

local function change_cwd (path)
  path = path:gsub("^%s*(.-)%s*$", "%1")
  if path:find("~") then
    path = path:gsub("~", os.getenv("HOME"))
  end

  local feedback = function (_, stderr, _, exit_code)
    if exit_code == 0 then
      naughty.notify {
        title = "Changed system CWD",
        text = "New CWD: " .. path
      }
    else
      naughty.notify {
        preset = naughty.config.presets.critical,
        title = "Failed to change system CWD",
        text = stderr,
      }
    end
  end

  local chdr = function (_, _, _, exit_code)
    if exit_code == 0 then
      awful.spawn.easy_async_with_shell("change-dir " .. path, feedback)
    else
      naughty.notify {
        preset = naughty.config.presets.critical,
        title = "Could not change CWD!",
        text = "Could not find path " .. path
      }
    end
  end

  awful.spawn.easy_async_with_shell("ls " .. path, chdr)
end

--- @param cmd (string)
local function run_in_terminal (cmd)
  cmd = cmd:gsub("^%s*(.-)%s*$", "%1")
  awful.spawn.with_shell(defaults.terminal .. " -e $SHELL -i -C " .. cmd)
end

--- @param cmd (string)
local function run_in_terminal_and_close (cmd)
  cmd = cmd:gsub("^%s*(.-)%s*$", "%1")
  awful.spawn.with_shell(defaults.terminal .. " -e $SHELL -c " .. cmd)
end

local function hide_search_box()
  search_box.visible = false
end

local function run_search(text)
  text = text:gsub("^%s*(.-)%s*$", "%1")
  if text:find(" ") then
    -- we have a lead command
    text = text:gsub("%w+%s+(.+)", "\"%1\"")
  end
  local c = hints.children[1]
  if type(c.cmd) == 'function' then
    c.cmd(text)
  elseif type(c.cmd) == 'string' then
    awful.spawn(c.cmd .. text)
  else
    naughty.notify {
      preset = naughty.config.presets.critical,
      title = "Unsupported command type",
      text = "Launcer was asked to perform command " .. type(c.cmd) .. " which it doesn't support"
    }
  end
end

local function add_hints(ui)
  hints = wibox.widget {
    layout = wibox.layout.fixed.vertical,
    {
      widget = wibox.widget.textbox,
      text = "Brave Search",
      cmd = "xdg-open https://search.brave.com/search?q=",
      short = "bs",
      priority = 100,
    },
    {
      widget = wibox.widget.textbox,
      text = "Translate en to pl",
      cmd = "xdg-open https://translate.google.com/?sl=en&tl=pl&text=",
      short = "e2p",
      priority = 10,
    },
    {
      widget = wibox.widget.textbox,
      text = "Translate pl to en",
      cmd = "xdg-open https://translate.google.com/?sl=pl&tl=en&text=",
      short = "p2e",
      priority = 10,
    },
    {
      widget = wibox.widget.textbox,
      text = "Wikipedia",
      cmd = "xdg-open https://en.wikipedia.org/w/index.php?search=",
      short = "wiki",
      priority = 1,
    },
    {
      widget = wibox.widget.textbox,
      text = "Files",
      cmd = defaults.terminal .. " --working-directory ",
      short = "cd",
      priority = 9,
    },
    {
      widget = wibox.widget.textbox,
      text = "Change current working directory",
      cmd = change_cwd,
      short = "cwd",
      priority = 10,
    },
    {
      widget = wibox.widget.textbox,
      text = "Run command in terminal",
      cmd = run_in_terminal,
      short = "cmd",
      priority = 11,
    },
    {
      widget = wibox.widget.textbox,
      text = "Run command and exit",
      cmd = run_in_terminal_and_close,
      short = "run",
      priority = 11,
    }
  }
  ui:add(hints)
end

local function reorder_hints(cmd)
  -- assign matching score or clear it if cmd is empty
  cmd = cmd:gsub("^%s*(.-)", "%1")
  if cmd:find(" ") then
    -- we have a lead command
    cmd = cmd:gsub("(%w+)%s+.*", "%1")
  else
    cmd = ""
  end

  for _, choice in ipairs(hints.children) do
    if cmd:len() > 0 then
      if choice.short == cmd then
        choice.score = 1000
      else
        choice.score = 0
        for chr in cmd:gmatch(".") do
          if choice.short:find(chr) then
            choice.score = choice.score + 1
          end
          if choice.text:find(chr) then
            choice.score = choice.score + 1
          end
        end
      end
    else
      choice.score = nil
    end
  end

  local target = 1
  local max = #hints.children
  local protect = 0

  while target < max do
    local a = hints.children[target].score or hints.children[target].priority
    local b = hints.children[target + 1].score or hints.children[target + 1].priority
    if b > a then
      hints:swap(target, target + 1)
      if target > 1 then
        target = target - 1
      else
        target = target + 1
      end
    else
      target = target + 1
    end
    protect = protect + 1
    if protect > 100 then
      naughty.notify { text = "Prevented infinite loop" }
      break
    end
  end

end

local function open_search_box(prompt)
  if search_box == nil then
    input = wibox.widget.textbox()
    search_box = wibox{
      type = "dialog",
      ontop = true,
      opacity = 0.9,
    }
    local ui = wibox.layout.fixed.vertical()
    local iw = wibox.widget { layout = wibox.container.place, input }
    ui:add(iw)
    add_hints(ui)
    search_box.widget = ui
  end

  local screen = mouse.screen
  local mysize = {
    x = screen.geometry.x + screen.geometry.width * 0.25,
    y = screen.geometry.y + screen.geometry.height * 0.25,
    width = screen.geometry.width * 0.5,
    height = screen.geometry.height * 0.5
  }

  search_box.screen = screen
  search_box:geometry(mysize)
  search_box.visible = true

  awful.prompt.run {
    prompt = prompt or "Run: ",
    textbox = input,
    completion_callback = require("awful.completion").shell,
    done_callback = hide_search_box,
    changed_callback = reorder_hints,
    exe_callback = run_search
  }
end

launcher.web_search = function()
  if search_box then
    if search_box.visible then
      hide_search_box()
    else
      open_search_box()
    end
  else
    open_search_box()
  end
end

return launcher
