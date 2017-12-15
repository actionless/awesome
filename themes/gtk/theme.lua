----------------------------------------------
-- Awesome theme which follows GTK+ 3 theme --
--   by Yauhen Kirylau                      --
----------------------------------------------

local theme_assets = require("beautiful.theme_assets")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
local gtk = require("beautiful.gtk")
local gfs = require("gears.filesystem")
local themes_path = gfs.get_themes_dir()


-- inherit xresources theme
local theme = dofile(themes_path.."xresources/theme.lua")

theme.gtk = gtk.get_theme_variables()
if not theme.gtk then
    local gears_debug = require("gears.debug")
    gears_debug.print_warning("Can't load GTK+3 theme. Using 'xresources' theme as a fallback.")
    return theme
end

theme.font          = theme.gtk.font

theme.bg_normal     = theme.gtk.menubar_bg_color
theme.bg_focus      = theme.gtk.selected_bg_color
theme.bg_urgent     = theme.xrdb.color9
theme.bg_minimize   = theme.gtk.wm_border_unfocused_color
theme.bg_systray    = theme.bg_normal

theme.fg_normal     = theme.gtk.menubar_fg_color
theme.fg_focus      = theme.gtk.selected_fg_color
theme.fg_urgent     = theme.bg_normal
theme.fg_minimize   = theme.bg_normal

theme.useless_gap   = dpi(3)
theme.border_width  = dpi(theme.gtk.border_width or 1)
theme.border_normal = theme.gtk.wm_border_unfocused_color
theme.border_focus  = theme.gtk.wm_border_focused_color
theme.border_marked = theme.xrdb.color10

-- There are other variable sets
-- overriding the default one when
-- defined, the sets are:
-- taglist_[bg|fg]_[focus|urgent|occupied|empty|volatile]
-- tasklist_[bg|fg]_[focus|urgent]
-- titlebar_[bg|fg]_[normal|focus]
-- tooltip_[font|opacity|fg_color|bg_color|border_width|border_color]
-- mouse_finder_[color|timeout|animate_timeout|radius|factor]
-- Example:
--theme.taglist_bg_focus = "#ff0000"

theme.taglist_bg_empty = theme.gtk.header_button_bg_color
theme.taglist_bg_occupied = theme.gtk.header_button_bg_color
theme.taglist_fg_empty = theme.gtk.header_button_fg_color
theme.taglist_fg_occupied = theme.gtk.header_button_fg_color

theme.titlebar_bg_normal = theme.gtk.wm_border_unfocused_color
theme.titlebar_bg_focus = theme.gtk.wm_border_focused_color

theme.tooltip_fg = theme.gtk.tooltip_fg_color
theme.tooltip_bg = theme.gtk.tooltip_bg_color

-- Variables set for theming the menu:
-- menu_[bg|fg]_[normal|focus]
-- menu_[border_color|border_width]
theme.menu_submenu_icon = themes_path.."default/submenu.png"
theme.menu_height = dpi(16)
theme.menu_width  = dpi(100)
theme.menu_border_width = theme.gtk.border_width

-- You can add as many variables as
-- you wish and access them by using
-- beautiful.variable in your rc.lua
--theme.bg_widget = "#cc0000"

-- Helper functions for modifying hex colors:
--
local hex_color_match = "[a-fA-F0-9][a-fA-F0-9]"
local function darker(color_value, darker_n)
    local result = "#"
    local channel_counter = 1
    for s in color_value:gmatch(hex_color_match) do
        local bg_numeric_value = tonumber("0x"..s)
        if channel_counter <= 3 then
            bg_numeric_value = bg_numeric_value - darker_n
        end
        if bg_numeric_value < 0 then bg_numeric_value = 0 end
        if bg_numeric_value > 255 then bg_numeric_value = 255 end
        result = result .. string.format("%02x", bg_numeric_value)
        channel_counter = channel_counter + 1
    end
    return result
end
local function is_dark(color_value)
    local bg_numeric_value = 0;
    local channel_counter = 1
    for s in color_value:gmatch(hex_color_match) do
        bg_numeric_value = bg_numeric_value + tonumber("0x"..s);
        if channel_counter == 3 then
            break
        end
        channel_counter = channel_counter + 1
    end
    local is_dark_bg = (bg_numeric_value < 383)
    return is_dark_bg
end
local function mix(color1, color2, ratio)
    ratio = ratio or 0.5
    local result = "#"
    local channels1 = color1:gmatch(hex_color_match)
    local channels2 = color2:gmatch(hex_color_match)
    for _ = 1,3 do
        local bg_numeric_value = math.ceil(
          tonumber("0x"..channels1())*ratio +
          tonumber("0x"..channels2())*(1-ratio)
        )
        if bg_numeric_value < 0 then bg_numeric_value = 0 end
        if bg_numeric_value > 255 then bg_numeric_value = 255 end
        result = result .. string.format("%02x", bg_numeric_value)
    end
    return result
end
local function reduce_contrast(color, ratio)
    ratio = ratio or 50
    return darker(color, is_dark(color) and -ratio or ratio)
end

-- Recolor Layout icons:
theme = theme_assets.recolor_layout(theme, theme.fg_normal)

-- Recolor titlebar icons:
--
theme = theme_assets.recolor_titlebar(
    theme, theme.fg_normal, "normal"
)
theme = theme_assets.recolor_titlebar(
    theme, reduce_contrast(theme.fg_normal, 50), "normal", "hover"
)
theme = theme_assets.recolor_titlebar(
    theme, theme.xrdb.color1, "normal", "press"
)
theme = theme_assets.recolor_titlebar(
    theme, theme.fg_focus, "focus"
)
theme = theme_assets.recolor_titlebar(
    theme, reduce_contrast(theme.fg_focus, 50), "focus", "hover"
)
theme = theme_assets.recolor_titlebar(
    theme, theme.xrdb.color1, "focus", "press"
)

-- Define the icon theme for application icons. If not set then the icons
-- from /usr/share/icons and /usr/share/icons/hicolor will be used.
theme.icon_theme = nil

-- Generate Awesome icon:
theme.awesome_icon = theme_assets.awesome_icon(
    theme.menu_height, theme.bg_focus, theme.fg_focus
)

-- Generate taglist squares:
local taglist_square_size = dpi(4)
theme.taglist_squares_sel = theme_assets.taglist_squares_sel(
    taglist_square_size, theme.fg_normal
)
theme.taglist_squares_unsel = theme_assets.taglist_squares_unsel(
    taglist_square_size, theme.fg_normal
)

-- Generate wallpaper:
local wallpaper_bg = theme.gtk.base_color
local wallpaper_fg = theme.gtk.bg_color
local wallpaper_alt_fg = theme.gtk.selected_bg_color
if not is_dark(theme.bg_normal) then
    wallpaper_bg, wallpaper_fg = wallpaper_fg, wallpaper_bg
end
wallpaper_bg = reduce_contrast(wallpaper_bg, 50)
wallpaper_fg = reduce_contrast(wallpaper_fg, 30)
wallpaper_fg = mix(wallpaper_fg, wallpaper_bg, 0.4)
wallpaper_alt_fg = mix(wallpaper_alt_fg, wallpaper_fg, 0.4)
theme.wallpaper = function(s)
    return theme_assets.wallpaper(wallpaper_bg, wallpaper_fg, wallpaper_alt_fg, s)
end

return theme

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
