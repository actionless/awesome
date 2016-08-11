---------------------------------------------------------------------------
-- Display percentage in a circle.
--
-- Note that this widget makes no attempts to prevent overlapping labels or
-- labels drawn outside of the widget boundaries.
--
--@DOC_wibox_widget_defaults_piechart_EXAMPLE@
-- @author Emmanuel Lepage Valle
-- @copyright 2012 Emmanuel Lepage Vallee
-- @release @AWESOME_VERSION@
-- @classmod wibox.widget.piechart
---------------------------------------------------------------------------

local color     = require( "gears.color"       )
local base      = require( "wibox.widget.base" )
local beautiful = require( "beautiful"         )
local util      = require( "awful.util"        )
local cairo     = require( "lgi"               ).cairo
local pie       = require( "gears.shape"       ).pie
local unpack    = unpack or table.unpack -- luacheck: globals unpack (compatibility with Lua 5.1)

local module = {}

local piechart = {}

local function draw_label(cr,angle,radius,center_x,center_y,text,src)
    cr:move_to(center_x+(radius/2)*math.cos(angle),center_y+(radius/2)*math.sin(angle))
    cr:line_to(center_x+(1.5*radius)*math.cos(angle),center_y+(1.5*radius)*math.sin(angle))
    local x,y = cr:get_current_point()
    cr:line_to(x+(x>center_x and radius/2 or -radius/2),y)
    local extents = cr:font_extents()
    cr:move_to(x+(x>center_x and radius/2 + 5 or (-radius/2 - cr:text_extents(text).width - 5)),y+(extents.height/4))
    cr:show_text(text) --TODO port away from the toy API
    cr:stroke()
    cr:arc(center_x+(radius/2)*math.cos(angle),center_y+(radius/2)*math.sin(angle),2,0,2*math.pi)
    cr:arc(x+(x>center_x and radius/2 or -radius/2),y,2,0,2*math.pi)
    cr:fill()
end

local function compute_sum(data)
    local ret = 0
    for k,v in pairs(data) do ret = ret + v end

    return ret
end

local function draw(self, context, cr, width, height)
    if not self._private.data then return end

    local radius = (height > width and width or height) / 4
    local sum, start, count = compute_sum(self._private.data),0,0

    -- Labels need to be drawn later so the original source is kept
    -- use get_source() wont work are the reference cannot be set from Lua(?)
    local labels = {}

    local border_width = self:get_border_width() or 1
    local border_color = self:get_border_color()
    border_color       = border_color and color(border_color)

    -- Draw the pies
    cr:save()
    cr:set_line_width(border_width)

    -- Alternate from a given sets or colors
    local colors = self:get_colors()
    local col_count = colors and #colors or 0

    for k,v in pairs(self._private.data) do
        local end_angle = start + 2*math.pi*(v/sum)
        local center_x, center_y = width/2,height/2

        local col = colors and color(colors[math.mod(count,col_count)+1]) or nil

        pie(cr, width, height, start, end_angle, radius)

        if col then
            cr:save()
            cr:set_source(color(col))
        end

        if border_width > 0 then
            if col then
                cr:fill_preserve()
                cr:restore()
            end

            -- By default, it uses the fg color
            if border_color then
                cr:set_source(border_color)
            end
            cr:stroke()
        elseif col then
            cr:fill()
            cr:restore()
        end


        -- Store the label position for later
        table.insert(labels, {
            --[[angle   ]] start+(end_angle-start)/2,
            --[[radius  ]] radius,
            --[[center_x]] width/2,
            --[[center_y]] height/2,
            --[[text    ]] k,
        })
        start,count = end_angle,count+1
    end
    cr:restore()

    -- Draw the labels
    for _, v in ipairs(labels) do
        draw_label(cr, unpack(v))
    end
end

local function fit(self, context, width, height)
    return width, height
end

for _, prop in ipairs {"data", "border_color", "border_width", "colors" } do
    piechart["set_"..prop] = function(self, value)
        self._private[prop] = value
        self:emit_signal("property::"..prop)
        self:emit_signal("widget::redraw_needed")
    end
    piechart["get_"..prop] = function(self)
        return self._private[prop] or beautiful["checkbox_"..prop]
    end
end

local function new(data)

    local ret = base.make_widget(nil, nil, {
        enable_properties = true,
    })

    util.table.crush(ret, piechart)

    rawset(ret, "fit" , fit )
    rawset(ret, "draw", draw)

    return ret
end

--@DOC_widget_COMMON@

--@DOC_object_COMMON@

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 4; replace-tabs on;
