---------------------------------------------------------------------------
--- Querying current GTK+ 3 theme via GtkStyleContext.
--
-- @author Yauheni Kirylau &lt;yawghen@gmail.com&gt;
-- @copyright 2016-2017 Yauheni Kirylau
-- @module beautiful.gtk
---------------------------------------------------------------------------
local gears_debug = require("gears.debug")
local gears_math = require("gears.math")
local join = require("gears.table").join
local unpack = unpack or table.unpack -- luacheck: globals unpack (compatibility with Lua 5.1)


local gtk = {
  cached_theme_variables = nil
}


local function convert_gtk_channel_to_hex(channel_value)
  return string.format("%02x", gears_math.round(channel_value * 255))
end

local function convert_gtk_color_to_hex(gtk_color)
  return "#" ..
    convert_gtk_channel_to_hex(gtk_color.red) ..
    convert_gtk_channel_to_hex(gtk_color.green) ..
    convert_gtk_channel_to_hex(gtk_color.blue) --..
  --convert_gtk_channel_to_hex(gtk_color.alpha)
end

local function lookup_gtk_color_to_hex(_style_context, color_name)
  local gtk_color = _style_context:lookup_color(color_name)
  if not gtk_color then
    return nil
  end
  return convert_gtk_color_to_hex(gtk_color)
end

local function get_gtk_color_property_to_hex(_style_context, property_name)
  local state = _style_context:get_state()
  local property = _style_context:get_property(property_name, state)
  if not property then
    return nil
  end
  return convert_gtk_color_to_hex(property.value)
end

local function read_gtk_color_properties_from_widget(gtk_widget, properties)
  local _style_context = gtk_widget:get_style_context()
  local result = {}
  for result_key, style_context_property in pairs(properties) do
    result[result_key] = get_gtk_color_property_to_hex(
      _style_context, style_context_property
    )
  end
  return result
end


--- Get GTK+3 theme variables from GtkStyleContext
-- @treturn table subj
function gtk.get_theme_variables()
  if gtk.cached_theme_variables then
    return gtk.cached_theme_variables
  end

  local result = {}
  local lgi = require('lgi')
  local Gtk = lgi.Gtk
  local window
  pcall(function()
    window = Gtk.Window{
      --on_destroy = Gtk.main_quit,
    }
  end)
  if not window then
    gears_debug.print_warning(
      "Seems like GTK+3 theme is not set correctly or luajit was built with an incomptible GTK+3 version."
    )
    return nil
  end
  --window:set_override_redirect(true)
  local style_context = window:get_style_context()

  local font = style_context:get_font(Gtk.StateFlags.NORMAL)
  --result.font_family = font:get_family()
  --result.font_size = font:get_size()/1024
  result.font = font:to_string()

  result = join(result, read_gtk_color_properties_from_widget(
    window, {
      bg_color="background-color",
      fg_color="color",
    }
  ))
  result = join(result, read_gtk_color_properties_from_widget(
    Gtk.Entry(), {
      base_color="background-color",
      text_color="color",
    }
  ))
  result = join(result, read_gtk_color_properties_from_widget(
    Gtk.ToggleButton(), {
      selected_bg_color="background-color",
      selected_fg_color="color",
    }
  ))
  local button = Gtk.Button()
  result = join(result, read_gtk_color_properties_from_widget(
    button, {
      button_bg_color="background-color",
      button_fg_color="color",
    }
  ))
  local button_style_context = button:get_style_context()
  for result_key, style_context_property in pairs({
    border_radius="border-radius",
    border_width="border-top-width",
  }) do
    local state = style_context:get_state()
    local property = button_style_context:get_property(style_context_property, state)
    result[result_key] = property.value
    property:unset()
  end

  for _, color_data in ipairs({
    {"bg_color", "theme_bg_color"},
    {"fg_color", "theme_fg_color"},
    {"base_color", "theme_base_color"},
    {"text_color", "theme_text_color"},
    {"selected_bg_color", "theme_selected_bg_color"},
    {"selected_fg_color", "theme_selected_fg_color"},
    --
    {"tooltip_bg_color", "theme_tooltip_bg_color", "bg_color"},
    {"tooltip_fg_color", "theme_tooltip_fg_color", "fg_color"},
    {"osd_bg_color", "osd_bg", "tooltip_bg_color"},
    {"osd_fg_color", "osd_fg", "tooltip_fg_color"},
    {"osd_border_color", "osd_borders_color", "osd_fg_color"},
    {"menubar_bg_color", "menubar_bg_color", "bg_color"},
    {"menubar_fg_color", "menubar_fg_color", "fg_color"},
    --
    {"button_bg_color", "button_bg_color", "bg_color"},
    {"button_fg_color", "button_fg_color", "fg_color"},
    {"header_button_bg_color", "header_button_bg_color", "menubar_bg_color"},
    {"header_button_fg_color", "header_button_fg_color", "menubar_fg_color"},
    --
    {"wm_bg_color", "wm_bg", "menubar_bg_color"},
    {"wm_border_focused_color", "wm_border_focused", "selected_bg_color"},
    {"wm_title_focused_color", "wm_title_focused", "menubar_bg_color"},
    {"wm_icons_focused_color", "wm_icons_focused", "menubar_fg_color"},
    {"wm_border_unfocused_color", "wm_border_unfocused", "wm_bg_color"},
    {"wm_title_unfocused_color", "wm_title_unfocused", "menubar_bg_color"},
    {"wm_icons_unfocused_color", "wm_icons_unfocused", "menubar_fg_color"},
  }) do
    local result_key, style_context_key, fallback_key = unpack(color_data)
    result[result_key] = lookup_gtk_color_to_hex(style_context, style_context_key) or
      (result[result_key] ~= "#000000" and result[result_key] or result[fallback_key] or result[result_key])
    if not result[result_key] then
      gears_debug.print_warning("Can't read color '" .. style_context_key .. "' from GTK+3 theme.")
    end
  end

  window:destroy()
  gtk.cached_theme_variables = result
  return result
end


return gtk
