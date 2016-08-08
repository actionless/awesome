---------------------------------------------------------------------------
--- A specialised ratio layout with dynamic client layout features
--
-- @author Emmanuel Lepage Vallee &lt;elv1313@gmail.com&gt;
-- @copyright 2016 Emmanuel Lepage Vallee
-- @release @AWESOME_VERSION@
-- @module awful.layout.dynamic.base_layout
---------------------------------------------------------------------------

local origin = require( "wibox.layout.ratio" )
local w_base = require( "wibox.widget.base"  )

local module = {}

-- Push widget in the front and back of the layout
local function split_callback(wrapper, context, pos)
    if not context.client_widget or not context.source_root then return end

    -- Create a new splitter section unless it is a "root" laout
    local root_idx = context.source_root:index(wrapper)

    local new_col = nil

    if not root_idx then
        new_col = wrapper._private.dir == "x" and module.vertical() or module.horizontal()
    end

    context.source_root:remove_widgets(context.client_widget, true)

    if pos == "first" then
        wrapper:insert(1, new_col or context.client_widget)
    else
        local f = (wrapper._private.add or wrapper.add)
        f(wrapper, new_col or context.client_widget)
    end

    if new_col then
        new_col:add(context.client_widget)
    end

    wrapper:emit_signal("widget::redraw_needed")
end

-- Create splitting points to add insert widget at the front and back
local function splitting_points(wrapper, geometry)
    local ret = {}

    if wrapper._private.dir == "x" then
        table.insert(ret, {
            position  = "left",
            bounding_rect  = geometry,
            direction = "right",
            type      = "sides",
            callback  = function(_,c) split_callback(wrapper, c, "first") end
        })
        table.insert(ret, {
            position  = "right",
            bounding_rect  = geometry,
            direction = "left",
            type      = "sides",
            callback  = function(_,c) split_callback(wrapper, c, "last") end
        })
    else
        table.insert(ret, {
            position  = "top",
            bounding_rect  = geometry,
            direction = "bottom",
            type      = "sides",
            callback  = function(_,c) split_callback(wrapper, c, "first") end
        })
        table.insert(ret, {
            position  = "bottom",
            bounding_rect  = geometry,
            direction = "top",
            type      = "sides",
            callback  = function(_,c) split_callback(wrapper, c, "last") end
        })
    end

    return ret
end

--- As the layout may have random subdivisions, make sure to call their "raise" too
-- @param self   The layout
-- @param widget The widget
local function raise_widget(self, widget)
    w_base.check_widget(widget)

    assert(widget.index)

    local _, _, path = self:index(widget, true)
    -- Self is path[#path], avoid stack overflow
    for i= #path-1, 1, -1 do-- in ipairs(path) do
        local w = path[i]
        if w.raise_widget then
            w:raise_widget(widget)
        end
    end
end

--- Make sure all suspend functions are called
local function suspend(self)
    for _, v in ipairs(self.children) do
        if v.suspend then
            v:suspend()
        end
    end
end

--- Make sure all wake_up functions are called
local function wake_up(self)
    for _, v in ipairs(self.children) do
        if v.wake_up then
            v:wake_up()
        end
    end
end

local function get_layout(dir, widget1, ...)
    local ret = origin[dir](widget1, ...)

    rawset(ret, "splitting_points" , splitting_points)
    rawset(ret, "raise_widget"     , raise_widget    )
    rawset(ret, "suspend"          , suspend         )
    rawset(ret, "wake_up"          , wake_up         )

    -- Forward all changes.
    for _, s in ipairs {
        "widget::swapped",
        "widget::inserted",
        "widget::replaced",
        "widget::removed",
        "widget::added",
        "widget::reseted",
    } do
        ret:connect_signal(s, function(self, ...)
            ret:emit_signal_recursive(s.."_forward", ...)
        end)
    end

    ret.fill_space = nil

    return ret
end

--- Returns a new horizontal ratio layout. A ratio layout shares the available space
-- equally among all widgets. Widgets can be added via :add(widget).
-- @tparam widget ... Widgets that should be added to the layout.
function module.horizontal(...)
    return get_layout("horizontal", ...)
end

--- Returns a new vertical ratio layout. A ratio layout shares the available space
-- equally among all widgets. Widgets can be added via :add(widget).
-- @tparam widget ... Widgets that should be added to the layout.
function module.vertical(...)
    return get_layout("vertical", ...)
end

return module
