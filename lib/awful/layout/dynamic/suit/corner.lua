---------------------------------------------------------------------------
--- Dynamic version of the fair layout.
-- This version emulate the stateless one, but try to maximize the space when
-- adding a new slave client.
--
--       1 client        2 clients        3 clients        4 clients
--    |-----------|    |-----|-----|    |-------|---|    |-------|---|
--    |           |    |     |     |    |       |1/3|    |       |   |
--    |           |    |     |     |    |       |   |    |       |   |
--    |           |    | 1/2 | 1/2 |    | 2/3   |---|    |-------|---|
--    |           |    |     |     |    |       |1/3|    |       |   |
--    |___________|    |_____|_____|    |_______|___|    |_______|___|
--    
--      5 clients
--    |-------|---|
--    |       |   |
--    |       |---|
--    |       |   |
--    |-------|---|
--    |_______|___|
--

-- @author Emmanuel Lepage Vallee &lt;elv1313@gmail.com&gt;
-- @copyright 2016 Emmanuel Lepage Vallee
-- @release @AWESOME_VERSION@
-- @module awful.layout.dynamic.suit.corner
---------------------------------------------------------------------------
local dynamic     = require("awful.layout.dynamic.base")
local wibox       = require("wibox")
local base_layout = require( "awful.layout.dynamic.base_layout" )

--- Support 'n' column and 'm' number of master per column
local function add(self, widget)
    if not widget then return end

    if #self:get_children_by_id("main_section")[1]:get_children() == 0 then
        self:get_children_by_id("main_section")[1]:add(widget)
    else
        -- The main will have to be replaced TODO
        if #self:get_children_by_id("column2")[1]:get_children() < 3 then
            self:get_children_by_id("column2")[1]:add(widget)
        else
            self:get_children_by_id("bottom_section")[1]:add(widget)
        end
    end
    self:emit_signal("widget::layout_changed")
    self:emit_signal("widget::redraw_needed")
end

local function ctr(_, direction) --luacheck: no unused_args
    --TODO implement directions
    local main_layout = wibox.widget.base.make_widget_declarative {
        {
            {
                id     = "main_section",
                layout = base_layout.vertical --main
            },
            {
                id     = "bottom_section",
                layout = base_layout.horizontal --bottom
            },
            id     = "column1",
            layout = base_layout.vertical --col1
        },
        {
            id     = "column2",
            layout = base_layout.vertical --col2
        },
        layout = base_layout.horizontal
    }

    main_layout.add = add

    return main_layout
end

-- FIXME IDEA, I could also use the rotation widget

local module = dynamic("corner"  , function(t) return ctr(t, "right") end)
module.nw    = dynamic("cornernw", function(t) return ctr(t, "right") end)
module.sw    = dynamic("cornersw", function(t) return ctr(t, "right") end)
module.ne    = dynamic("cornerne", function(t) return ctr(t, "right") end)
module.se    = dynamic("cornerse", function(t) return ctr(t, "right") end)

return module
-- kate: space-indent on; indent-width 4; replace-tabs on;
