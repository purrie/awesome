local wibox = require("wibox")
local awful = require("awful")
-- local naughty = require("naughty")
local beautiful = require("beautiful")
local gears = require("gears")

local audio = {}
-- [[
-- List of sinks and sources, each has following fields:
-- @id - ID of the sink, used for commands
-- @name - human readable name
-- @volume
-- @muted
-- ]]
local sinks = {
  name = "Audio Sink",
  widget_root = nil,
  percent_widget = nil,
  graphic_widget = nil,
  selected = nil,
  wpctl_status = ".-Sinks:(.-)Sink endpoints.+",
  icon_muted = "🔇",
  icon_low = "🔈",
  icon_medium = "🔉",
  icon_high = "🔊",
  icon_over = "📢",
}

local sources = {
  name = "Audio Source",
  widget_root = nil,
  percent_widget = nil,
  graphic_widget = nil,
  selected = nil,
  wpctl_status = ".-Sources:(.-)Source endpoints.+",
  icon_muted = "🔇",
  icon_low = "🎤",
  icon_medium = "🎤",
  icon_high = "🎤",
  icon_over = "📢",
}

local popup = awful.popup{
    bg = beautiful.bg_normal,
    ontop = true,
    visible = false,
    shape = gears.shape.rounded_rect,
    border_width = beautiful.border_width,
    border_color = beautiful.bg_focus,
    maximum_width = 500,
    widget = {}
}
local popup_rows = nil

local subscriber_id = nil

---Utils---------------------------------------------------------------------
local function mod_shift(mods)
  for i = 1, #mods do
    local mod = mods[i]
    if mod == "Shift" then
      return true
    end
  end
  return false
end

---Signal Handlers-------------------------------------------------------------
local function background_normal(c)
  c.bg = beautiful.bg_normal
end

local function background_focus(c)
  c.bg = beautiful.bg_focus
end

---Control---------------------------------------------------------------------
local function get_by_id(devices, id)
  if id then
    for i = 1, #devices do
      local device = devices[i]
      if device.id == id then
        return device
      end
    end
  end

  return nil
end

local function get_by_name(devices, name)
  if name then
    for i = 1, #devices do
      local device = devices[i]
      if device.name == name then
        return device
      end
    end
  end

  return nil
end

local function create_device(devices, name)
  local device = get_by_name(devices, name)
  if device then
    device.active = true
    return device, false
  end

  device = {
    name = name,
    active = true,
  }

  local count = #devices + 1
  devices[count] = device

  return device, true
end

local function clear_devices(devices)
  local count = #devices;
  for i = 1, count do
    local index = count - i + 1
    if devices[index].active == false then
      for over = index, count do
        devices[over] = devices[over + 1]
      end
    end
  end
end

local function update_widget_text(devices)
  local device = get_by_id(devices, devices.selected)

  if device then
    if device.muted then
      if devices.graphic_widget.managed then
        devices.graphic_widget.text = devices.icon_muted
        devices.percent_widget.text = "---%"
      else
        devices.percent_widget.text = "Muted"
      end
    else
      local volume = device.volume
      if devices.graphic_widget.managed then
        if volume > 100 then
          devices.graphic_widget.text = devices.icon_over
        elseif volume > 75 then
          devices.graphic_widget.text = devices.icon_high
        elseif volume > 50 then
          devices.graphic_widget.text = devices.icon_low
        elseif volume <= 0 then
          devices.graphic_widget.text = devices.icon_muted
        else
          devices.graphic_widget.text = "🔈"
        end
      end

      devices.percent_widget.text = volume .. "%"
    end
  end
end

local function flush_volume(devices, device)
  devices.event = true
  awful.spawn.with_shell(
    "wpctl set-volume " .. device.id .. " " .. device.volume .. "%"
  )

  if device.id == devices.selected then
    update_widget_text(devices)
  end
end

local function volume_mute(devices, on_off, device)
  device = device or get_by_id(devices, devices.selected)

  if device then
    local cmd = "wpctl set-mute " .. device.id
    if type(on_off) == "boolean" then
      device.muted = on_off
    else
      device.muted = not device.muted
    end

    if device.muted then
      cmd = cmd .. " 1"
    else
      cmd = cmd .. " 0"
    end

    devices.event = true
    awful.spawn.with_shell(cmd)
    if device.id == devices.selected then
      update_widget_text(devices)
    end
  end
end

local function volume_up(devices, device, volume)
  device = device or get_by_id(devices, devices.selected)
  volume = volume or 1
  if device then
    device.volume = device.volume + volume
    flush_volume(devices, device)
  end
end

local function volume_down(devices, device, volume)
  device = device or get_by_id(devices, devices.selected)
  volume = volume or 1
  if device then
    device.volume = device.volume - volume
    if device.volume < 0 then
      device.volume = 0
    end
    flush_volume(devices, device)
  end
end

local function deactivate_devices(devices)
  for i=1, #devices do
    devices[i].active = false
  end
end

local function refresh_popup()
  local devices = popup_rows.showing
  for i = 1, #devices do
    local device = devices[i]
    local row = popup_rows[i]
    row.name.text = device.name
    row.checkbox.checked = device.id == devices.selected
  end

  if #devices < #popup_rows then
    for i = #devices + 1, #popup_rows do
      popup_rows[i] = nil
    end
  end
end

local function load_devices(devices, callback)
  deactivate_devices(devices)

  awful.spawn.easy_async_with_shell(
    "wpctl status",
    function(stdout)
      stdout = string.gsub(stdout, devices.wpctl_status, "%1")
      for default, id, name, volume, mute in string.gmatch(stdout, ".-  ([%* ]).-(%d-)%. (.-)%s+%[vol: (%S-) ?([MUTED]-)%]") do
        local device = create_device(devices, name)
        device.id = id

        local success, vol = pcall(tonumber, volume)
        if success then
          vol = math.floor(vol * 100)
          device.volume = vol
        end

        if default == "*" then
          devices.selected = id
        end

        if mute == "MUTED" then
          device.muted = true
        else
          device.muted = false
        end
      end

      clear_devices(devices)
      update_widget_text(devices)
      if callback then
        callback(devices)
      end

      if popup_rows then
        refresh_popup()
      end
    end
  )
end

local function set_default_device(devices, device)
  awful.spawn.easy_async("wpctl set-default " .. device.id, function() load_devices(devices) end)
end

local function setup_popup(devices)
  popup.visible = true;
  popup:move_next_to(mouse.current_widget_geometry)
  local ui = wibox.layout.fixed.vertical ()
  local title = wibox.widget.textbox ( devices.name, true )
  local title_line = wibox.container.place(title)
  ui:add(title_line)

  popup_rows = { showing = devices }
  for i=1, #devices do
    local device = devices[i]
    local row = wibox.layout.fixed.horizontal ()
    local checkbox = wibox.widget {
      checked = device.id == devices.selected,
      bg = beautiful.bg_normal,
      color = beautiful.bg_focus,
      check_color = beautiful.fg_focus,
      paddings = 2,
      shape = gears.shape.circle,
      widget = wibox.widget.checkbox,
      forced_width = 16,
      forced_height = 16,
    }
    local name = wibox.widget.textbox (device.name, true)

    table.insert(popup_rows, { name = name, checkbox = checkbox })
    row:add(checkbox)
    row:add(name)

    local line = wibox.container.background(row, beautiful.bg_normal)
    line:connect_signal("mouse::enter", background_focus)
    line:connect_signal("mouse::leave", background_normal)
    line:connect_signal("button::press", function() set_default_device(devices, device) end)

    ui:add(line)
  end

  local final_widget = wibox.container.margin (ui)
  final_widget.margins = 4
  popup.widget = final_widget
end

local function hide_popup()
  popup.visible = false
  popup_rows = nil
end

local function show_popup(devices)
  if popup.visible and popup_rows.showing == devices then
    hide_popup()
  else
    load_devices(devices, setup_popup)
  end
end

local function button_press(devices, _, _, _, button, mods)
  if button == 1 then
    volume_mute(devices, nil, nil)
  elseif button == 3 then
    show_popup(devices)
  elseif button == 4 then
    if mod_shift(mods) then
      volume_up(devices, nil, 10)
    else
      volume_up(devices, nil, 1)
    end
  elseif button == 5 then
    if mod_shift(mods) then
      volume_down(devices, nil, 10)
    else
      volume_down(devices, nil, 1)
    end
  end
end

local function setup(devices)
  devices.widget_root = wibox.layout.fixed.horizontal()
  devices.widget_root.spacing = 4

  if beautiful.icon_audio_speaker then
    devices.graphic_widget = wibox.widget.imagebox(beautiful.icon_audio_speaker, true, gears.shape.rectangle)
  else
    devices.graphic_widget = wibox.widget.textbox("⏳", true)
    devices.graphic_widget.managed = true
  end

  devices.percent_widget = wibox.widget.textbox("⏳", true)

  devices.widget_root:add(devices.graphic_widget)
  devices.widget_root:add(devices.percent_widget)

  devices.widget_root:connect_signal("button::press", function(...) button_press(devices, ...) end)

  load_devices(devices)
end

---Events---------------------------------------------------------------------
local function subscriber()
  if sinks.widget_root then
    load_devices(sinks)
  end

  if sources.widget_root then
    load_devices(sources)
  end
end

local function start_event_listening()
  -- TODO seems to not update when connecting or disconnecting wired headphones
  if subscriber_id == nil then
    subscriber_id = gears.timer {
      timeout = 60,
      call_now = false,
      autostart = true,
      callback = subscriber,
    }
  end
end

---Interface------------------------------------------------------------------
function audio.get_sound_widget()
  if sinks.widget_root == nil then
    setup(sinks)
    start_event_listening()
  end

  return sinks.widget_root
end

function audio.get_microphone_widget()
  if sources.widget_root == nil then
    setup(sources)
    start_event_listening()
  end

  return sources.widget_root
end

function audio.sound_volume_up(amount)
  local sink = get_by_id(sinks, sinks.selected)
  volume_up(sinks, sink, amount or 5)
end

function audio.sound_volume_down(amount)
  local sink = get_by_id(sinks, sinks.selected)
  volume_down(sinks, sink, amount or 5)
end

function audio.sound_mute(on_off)
  local sink = get_by_id(sinks, sinks.selected)
  volume_mute(sinks, on_off, sink)
end

function audio.microphone_volume_up(amount)
  local source = get_by_id(sources, sources.selected)
  volume_up(sources, source, amount or 5)
end

function audio.microphone_volume_down(amount)
  local source = get_by_id(sources, sources.selected)
  volume_down(sources, source, amount or 5)
end

function audio.microphone_mute(on_off)
  local source = get_by_id(sources, sources.selected)
  volume_mute(sources, on_off, source)
end

return audio
