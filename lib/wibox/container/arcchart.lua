---------------------------------------------------------------------------
--
-- A circular chart (arc chart).
--
-- It can contain a central widget (or not) and display multiple values.
--
--@DOC_wibox_container_defaults_arcchart_EXAMPLE@
-- @author Emmanuel Lepage Vallee &lt;elv1313@gmail.com&gt;
-- @copyright 2013 Emmanuel Lepage Vallee
-- @release @AWESOME_VERSION@
-- @classmod wibox.container.arcchart
---------------------------------------------------------------------------

local setmetatable = setmetatable
local base      = require("wibox.widget.base")
local shape     = require("gears.shape"      )
local util      = require( "awful.util"      )
local color     = require( "gears.color"     )
local beautiful = require("beautiful"        )


local arcchart = { mt = {} }

--- The progressbar border background color.
-- @beautiful beautiful.arcchart_border_color

--- The progressbar foreground color.
-- @beautiful beautiful.arcchart_color

--- The progressbar border width.
-- @beautiful beautiful.arcchart_border_width

--- The padding between the outline and the progressbar.
-- @beautiful beautiful.arcchart_paddings
-- @tparam[opt=0] table|number paddings A number or a table
-- @tparam[opt=0] number paddings.top
-- @tparam[opt=0] number paddings.bottom
-- @tparam[opt=0] number paddings.left
-- @tparam[opt=0] number paddings.right

local function outline_workarea(self, width, height)
    local border_width = self:get_border_width() or 0

    local x, y = 0, 0

    -- Make sure the border fit in the clip area
    local offset = border_width/2
    x, y = x + offset, y+offset
    width, height = width-2*offset, height-2*offset

    return {x=x, y=y, width=width, height=height}, offset
end

-- The child widget area
local function content_workarea(self, width, height)
    local padding = self._private.paddings or {}
    local wa, offset = outline_workarea(self, width, height)

    wa.x      = wa.x + (padding.left or 0)
    wa.y      = wa.y + (padding.top  or 0)
    wa.width  = wa.width  - (padding.left or 0) - (padding.right  or 0)
    wa.height = wa.height - (padding.top  or 0) - (padding.bottom or 0)

    return wa
end

-- Draw the radial outline and progress
function arcchart:after_draw_children(_, cr, width, height)
    cr:restore()

    local values  = self:get_values() or {}
    local thickness = self:get_thickness() or 5

    -- Draw a circular background
    local bg = self:get_bg()
    if bg then
        cr:save()
        cr:translate(thickness/2, thickness/2)
        shape.circle(cr, width-thickness, height-thickness)
        cr:set_line_width(thickness)
        cr:set_source(color(bg))
        cr:stroke()
        cr:restore()
    end

    if #values == 0 then
        return
    end

    local wa = outline_workarea(self, width, height)
    cr:translate(wa.x, wa.y)


    -- Get the min and max value
    local min_val = self:get_min_value() or 0
    local max_val = self:get_max_value()
    local sum = 0

    if not max_val then
        for _, v in ipairs(values) do
            sum = sum + v
        end
        max_val = sum
    end

    local use_rounded_edges = sum ~= max_value and self:get_rounded_edge()

    -- Fallback to the current foreground color
    local colors = self:get_colors() or {}

    -- Draw the outline
    local start_angle, end_angle = 0, 0

    for k, v in ipairs(values) do
        end_angle = start_angle + (v*2*math.pi) / max_val

        if colors[k] then
            cr:set_source(color(colors[k]))
        end

        shape.arc(cr, wa.width, wa.height,
            thickness, start_angle, end_angle,
            (use_rounded_edges and k == 1), (use_rounded_edges and k == #values)
        )

        cr:fill()
        start_angle = end_angle
    end


    -- Draw a border around all the values at once.
    local border_width = self:get_border_width()

    if border_width then
        local border_color = self:get_border_color()

        cr:set_source(color(border_color))
        cr:set_line_width(border_width)

        shape.arc(cr, wa.width, wa.height,
            thickness, 0, end_angle,
            use_rounded_edges, use_rounded_edges
        )
        cr:stroke()
    end
end

-- Set the clip
function arcchart:before_draw_children(_, cr, width, height)
    cr:save()
    local wa = content_workarea(self, width, height)
    local thickness = self:get_thickness() or 5
    cr:translate(wa.x, wa.y)
    shape.circle(cr, wa.width, wa.height, math.min(wa.width, wa.height)/2-thickness)
    cr:clip()
    cr:translate(-wa.x, -wa.y)
end

-- Layout this layout
function arcchart:layout(_, width, height)
    if self._private.widget then
        local wa = content_workarea(self, width, height)

        return { base.place_widget_at(
            self._private.widget, wa.x, wa.y, wa.width, wa.height
        ) }
    end
end

-- Fit this layout into the given area
function arcchart:fit(context, width, height)
    if self._private.widget then
        local wa = content_workarea(self, width, height)
        return base.fit_widget(self, context, self._private.widget, wa.width, wa.height)
    end

    return width, height
end

--- The widget to wrap in a radial proggressbar.
-- @property widget
-- @tparam widget widget The widget

function arcchart:set_widget(widget)
    if widget then
        base.check_widget(widget)
    end
    self._private.widget = widget
    self:emit_signal("widget::layout_changed")
end

--- Get the number of children element
-- @treturn table The children
function arcchart:get_children()
    return {self._private.widget}
end

--- Replace the layout children
-- This layout only accept one children, all others will be ignored
-- @tparam table children A table composed of valid widgets
function arcchart:set_children(children)
    self._private.widget = children and children[1]
    self:emit_signal("widget::layout_changed")
end

--- Reset this layout. The widget will be removed and the rotation reset.
function arcchart:reset()
    self:set_widget(nil)
end

for k,v in ipairs {"left", "right", "top", "bottom"} do
    arcchart["set_"..v.."_padding"] = function(self, val)
        self._private.paddings = self._private.paddings or {}
        self._private.paddings[v] = val
        self:emit_signal("widget::redraw_needed")
    end
end

--- The padding between the outline and the progressbar.
--@DOC_wibox_container_arcchart_padding_EXAMPLE@
-- @property paddings
-- @tparam[opt=0] table|number paddings A number or a table
-- @tparam[opt=0] number paddings.top
-- @tparam[opt=0] number paddings.bottom
-- @tparam[opt=0] number paddings.left
-- @tparam[opt=0] number paddings.right

--- The progressbar value.
--@DOC_wibox_container_arcchart_value_EXAMPLE@
-- @property value
-- @tparam number value Between min_value and max_value

function arcchart:set_value(val)
    if not val then self._percent = 0; return end

--     if val > 0 then
--         self:set_max_value(val)
--     elseif val < 0 then
--         self:set_min_value(val)
--     end

    local delta = 0 - 0

    self._percent = val/delta
    self:emit_signal("widget::redraw_needed")
end

--- The border background color.
--@DOC_wibox_container_arcchart_border_color_EXAMPLE@
-- @property border_color

--- The border foreground color.
--@DOC_wibox_container_arcchart_color_EXAMPLE@
-- @property color

--- The border width.
--@DOC_wibox_container_arcchart_border_width_EXAMPLE@
-- @property border_width
-- @tparam[opt=3] number border_width

--- The minimum value.
-- @property min_value

--- The maximum value.
-- @property max_value

for _, prop in ipairs {"border_width", "border_color", "paddings", "colors",
    "rounded_edge", "bg", "thickness", "values", "min_value", "max_value" } do
    arcchart["set_"..prop] = function(self, value)
        self._private[prop] = value
        self:emit_signal("property::"..prop)
        self:emit_signal("widget::redraw_needed")
    end
    arcchart["get_"..prop] = function(self)
        return self._private[prop] or beautiful["arcchart_"..prop]
    end
end

function arcchart:set_paddings(val)
    self._private.paddings = type(val) == "number" and {
        left   = val,
        right  = val,
        top    = val,
        bottom = val,
    } or val or {}
    self:emit_signal("property::paddings")
    self:emit_signal("widget::redraw_needed")
end

--- Returns a new arcchart layout. A arcchart layout arccharts a given widget. Use
-- :set_widget() to set the widget and :set_direction() for the direction.
-- The default direction is "north" which doesn't change anything.
-- @param[opt] widget The widget to display.
-- @function wibox.container.arcchart
local function new(widget)
    local ret = base.make_widget(nil, nil, {
        enable_properties = true,
    })

    util.table.crush(ret, arcchart)

    ret:set_widget(widget)

    return ret
end

function arcchart.mt:__call(...)
    return new(...)
end

--@DOC_widget_COMMON@

--@DOC_object_COMMON@

return setmetatable(arcchart, arcchart.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
