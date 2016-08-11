-------------------------------------------------------------------------
--- Tooltip module for awesome objects.
--
-- A tooltip is a small hint displayed when the mouse cursor
-- hovers a specific item.
-- In awesome, a tooltip can be linked with almost any
-- object having a `:connect_signal()` method and receiving
-- `mouse::enter` and `mouse::leave` signals.
--
-- How to create a tooltip?
-- ---
--
--     myclock = wibox.widget.textclock({}, "%T", 1)
--     myclock_t = awful.tooltip({
--         objects = { myclock },
--         timer_function = function()
--                 return os.date("Today is %A %B %d %Y\nThe time is %T")
--             end,
--         })
--
-- How to add the same tooltip to multiple objects?
-- ---
--
--     myclock_t:add_to_object(obj1)
--     myclock_t:add_to_object(obj2)
--
-- Now the same tooltip is attached to `myclock`, `obj1`, `obj2`.
--
-- How to remove a tooltip from several objects?
-- ---
--
--     myclock_t:remove_from_object(obj1)
--     myclock_t:remove_from_object(obj2)
--
-- Now the same tooltip is only attached to `myclock`.
--
-- @author Sébastien Gross &lt;seb•ɱɩɲʋʃ•awesome•ɑƬ•chezwam•ɖɵʈ•org&gt;
-- @copyright 2009 Sébastien Gross
-- @release @AWESOME_VERSION@
-- @classmod awful.tooltip
-------------------------------------------------------------------------

local mouse = mouse
local timer = require("gears.timer")
local util = require("awful.util")
local object = require("gears.object")
local wibox = require("wibox")
local a_placement = require("awful.placement")
local abutton = require("awful.button")
local beautiful = require("beautiful")
local textbox = require("wibox.widget.textbox")
local background = require("wibox.container.background")
local dpi = require("beautiful").xresources.apply_dpi
local setmetatable = setmetatable
local ipairs = ipairs
local capi = {mouse=mouse}

local tooltip = { mt = {}  }

-- The mouse point is 1x1, so anything aligned based on it as parent
-- geometry will go out of bound. To get the desired placement, it is
-- necessary to swap left with right and top with bottom
local align_convert = {
    top_left     = "bottom_right",
    left         = "right",
    bottom_left  = "top_right",
    right        = "left",
    top_right    = "bottom_left",
    bottom_right = "top_left",
    top          = "bottom",
    bottom       = "top",
}

-- If the wibox is under the cursor, it will trigger a mouse::leave
local offset = {
    top_left     = {x =  0, y =  0 },
    left         = {x =  0, y =  0 },
    bottom_left  = {x =  0, y =  0 },
    right        = {x =  1, y =  0 },
    top_right    = {x =  0, y =  0 },
    bottom_right = {x =  1, y =  1 },
    top          = {x =  0, y =  0 },
    bottom       = {x =  0, y =  1 },
}

-- Place the tooltip under the mouse.
--
-- @tparam tooltip self A tooltip object.
local function set_geometry(self)
    -- calculate width / height
    local n_w, n_h = self.textbox:get_preferred_size(mouse.screen)
    n_w = n_w + self.marginbox.left + self.marginbox.right
    n_h = n_h + self.marginbox.top + self.marginbox.bottom

    local w = self:get_wibox()
    w:geometry({ width = n_w, height = n_h })

    local align  = self._private.align

    local real_placement = align_convert[align]

    a_placement[real_placement](w, {
        parent = capi.mouse,
        offset = offset[align]
    })

    a_placement.no_offscreen(w)
end

-- Show a tooltip.
--
-- @tparam tooltip self The tooltip to show.
local function show(self)
    -- do nothing if the tooltip is already shown
    if self._private.visible then return end
    if self.timer then
        if not self.timer.started then
            self:timer_function()
            self.timer:start()
        end
    end
    self.wibox.visible = true

    set_geometry(self)
    self._private.visible = true
    self:emit_signal("property::visible")
end

-- Hide a tooltip.
--
-- @tparam tooltip self The tooltip to hide.
local function hide(self)
    -- do nothing if the tooltip is already hidden
    if not self._private.visible then return end
    if self.timer then
        if self.timer.started then
            self.timer:stop()
        end
    end
    self.wibox.visible = false
    self._private.visible = false
    self:emit_signal("property::visible")
end

--- The wibox.
-- @property wibox
-- @param `wibox`

function tooltip:get_wibox()
    if self._private.wibox then
        return self._private.wibox
    end

    local wb = wibox(self.wibox_properties)
    wb:set_widget(self.marginbox)

    -- Close the tooltip when clicking it.  This gets done on release, to not
    -- emit the release event on an underlying object, e.g. the titlebar icon.
    wb:buttons(abutton({}, 1, nil, self.hide))

    self._private.wibox = wb

    return wb
end

--- Is the tooltip visible?
-- @property visible
-- @param boolean

function tooltip:get_visible()
    return self._private.visible
end

function tooltip:set_visible(value)
    if self._private.visible == value then return end

    if value then
        show(self)
    else
        hide(self)
    end
end

--- The horizontal alignment.
--
-- The following values are valid:
--
-- * top_left
-- * left
-- * bottom_left
-- * right
-- * top_right
-- * bottom_right
-- * bottom
-- * top
--
-- @property align
-- @see beautiful.tooltip_align

--- The default tooltip alignment.
-- @beautiful beautiful.tooltip_align
-- @param string
-- @see align

function tooltip:get_align()
    return self._private.align
end

function tooltip:set_align(value)
    if not align_convert[value] then
        return
    end

    self._private.align = value

    set_geometry(self)
    self:emit_signal("property::align")
end

--- Change displayed text.
--
-- @property text
-- @tparam tooltip self The tooltip object.
-- @tparam string  text New tooltip text, passed to
--   `wibox.widget.textbox.set_text`.

function tooltip:set_text(text)
    self.textbox:set_text(text)
    if self._private.visible then
        set_geometry(self)
    end
end

--- Change displayed markup.
--
-- @property markup
-- @tparam tooltip self The tooltip object.
-- @tparam string  text New tooltip markup, passed to
--   `wibox.widget.textbox.set_markup`.

function tooltip:set_markup(text)
    self.textbox:set_markup(text)
    if self._private.visible then
        set_geometry(self)
    end
end

--- Change the tooltip's update interval.
--
-- @property timeout
-- @tparam tooltip self A tooltip object.
-- @tparam number timeout The timeout value.

function tooltip:set_timeout(timeout)
    if self.timer then
        self.timer.timeout = timeout
    end
end

--- Add tooltip to an object.
--
-- @tparam tooltip self The tooltip.
-- @tparam gears.object obj An object with `mouse::enter` and
--   `mouse::leave` signals.
-- @function add_to_object
function tooltip:add_to_object(obj)
    obj:connect_signal("mouse::enter", self.show)
    obj:connect_signal("mouse::leave", self.hide)
end

--- Remove tooltip from an object.
--
-- @tparam tooltip self The tooltip.
-- @tparam gears.object obj An object with `mouse::enter` and
--   `mouse::leave` signals.
-- @function remove_from_object
function tooltip:remove_from_object(obj)
    obj:disconnect_signal("mouse::enter", self.show)
    obj:disconnect_signal("mouse::leave", self.hide)
end


--- Create a new tooltip and link it to a widget.
-- Tooltips emit `property::visible` when their visibility changes.
-- @tparam table args Arguments for tooltip creation.
-- @tparam function args.timer_function A function to dynamically set the
--   tooltip text.  Its return value will be passed to
--   `wibox.widget.textbox.set_markup`.
-- @tparam[opt=1] number args.timeout The timeout value for
--   `timer_function`.
-- @tparam[opt] table args.objects A list of objects linked to the tooltip.
-- @tparam[opt] number args.delay_show Delay showing the tooltip by this many
--   seconds.
-- @tparam[opt=apply_dpi(5)] integer args.margin_leftright The left/right margin for the text.
-- @tparam[opt=apply_dpi(3)] integer args.margin_topbottom The top/bottom margin for the text.
-- @treturn awful.tooltip The created tooltip.
-- @see add_to_object
-- @see timeout
-- @see text
-- @see markup
-- @function awful.tooltip
function tooltip.new(args)
    local self = object {
        enable_properties = true,
    }

    rawset(self,"_private", {})

    self:add_signal("property::visible")
    self:add_signal("property::align")

    self._private.visible = false
    self._private.align   = beautiful.tooltip_align  or "right"

    -- private data
    if args.delay_show then
        local delay_timeout

        delay_timeout = timer { timeout = args.delay_show }
        delay_timeout:connect_signal("timeout", function ()
            show(self)
            delay_timeout:stop()
        end)

        function self.show()
            if not delay_timeout.started then
                delay_timeout:start()
            end
        end
        function self.hide()
            if delay_timeout.started then
                delay_timeout:stop()
            end
            hide(self)
        end
    else
        function self.show()
            show(self)
        end
        function self.hide()
            hide(self)
        end
    end

    -- export functions
    util.table.crush(self, tooltip, true)

    -- setup the timer action only if needed
    if args.timer_function then
        self.timer = timer { timeout = args.timeout and args.timeout or 1 }
        self.timer_function = function()
                self:set_markup(args.timer_function())
            end
        self.timer:connect_signal("timeout", self.timer_function)
    end

    -- Set default properties
    self.wibox_properties = {
        visible = false,
        ontop = true,
        border_width = beautiful.tooltip_border_width or beautiful.border_width or 1,
        border_color = beautiful.tooltip_border_color or beautiful.border_normal or "#ffcb60",
        opacity = beautiful.tooltip_opacity or 1,
        bg = beautiful.tooltip_bg_color or beautiful.bg_focus or "#ffcb60"
    }
    local fg = beautiful.tooltip_fg_color or beautiful.fg_focus or "#000000"
    local font = beautiful.tooltip_font or beautiful.font or "terminus 6"

    self.textbox = textbox()
    self.textbox:set_font(font)
    self.background = background(self.textbox)
    self.background:set_fg(fg)

    -- Add margin.
    local m_lr = args.margin_leftright or dpi(5)
    local m_tb = args.margin_topbottom or dpi(3)
    self.marginbox = wibox.container.margin(self.background, m_lr, m_lr, m_tb, m_tb)

    -- Add tooltip to objects
    if args.objects then
        for _, obj in ipairs(args.objects) do
            self:add_to_object(obj)
        end
    end

    return self
end

function tooltip.mt:__call(...)
    return tooltip.new(...)
end

return setmetatable(tooltip, tooltip.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
