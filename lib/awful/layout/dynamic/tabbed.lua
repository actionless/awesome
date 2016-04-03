---------------------------------------------------------------------------
--- A specialised stack layout with a tabbar on top
--
-- @todo The tab widget is currently hardcoded, but once well defined, it will
--   be possible to set a cusom one. Reusing `awful.widget.common` wasn't
--   really helpful, but could be possible
--
-- @author Emmanuel Lepage Vallee &lt;elv1313@gmail.com&gt;
-- @copyright 2016 Emmanuel Lepage Vallee
-- @release @AWESOME_VERSION@
-- @module awful.layout.dynamic.tabbed
---------------------------------------------------------------------------

local capi = {client = client}
local stack     = require( "awful.layout.dynamic.base_stack" )
local margins   = require( "wibox.layout.margin"             )
local wibox     = require( "wibox"                           )
local timer     = require( "gears.timer"                     )
local beautiful = require( "beautiful"                       )

local fct = {}

-- Keep only 1 version of each tab, use it in multiple tabbar to reduce the
-- number of signals
local tabs = setmetatable({},{__mode="k"})

local connected, old_focus = false, nil

local function focus_changed(c)
    local tab = tabs[c]
    if old_focus and tab ~= old_focus then
        old_focus:set_bg(beautiful.bg_normal)
        old_focus:set_fg(beautiful.fg_normal)
    end

    if tab then
        tab:set_bg(beautiful.bg_focus)
        tab:set_fg(beautiful.fg_focus)

        old_focus = tab
    end
end

--- Create a tab widget
local function create_tab(c)
    if tabs[c] then return tabs[c] end

    local ib = wibox.widget.imagebox(c.icon)
    local tb = wibox.widget.textbox(c.name)
    local l  = wibox.layout.fixed.horizontal(ib, tb)
    local bg = wibox.widget.background(l)
    bg._tb, bg._ib = tb, ib
    tabs[c] = bg

    bg:connect_signal("button::press",function()
        capi.client.focus = c
        c:raise()
    end)

    -- Connect only once
    if not connected then
        connected = true
        capi.client.connect_signal("focus", focus_changed)
        capi.client.connect_signal("property::name", function(c2)
            local tab = tabs[c2]
            if tab then
                tab._tb:set_text(c2.name)
            end
        end)
    end

    if capi.client.focus == c then
        focus_changed(c)
    end

    return bg
end

--- Create a rudimentary tabbar widget
local function create_tabbar(w, widgets)
    local flex = wibox.layout.flex.horizontal()

    for _, v in ipairs(widgets) do
        if v._client then
            flex:add(create_tab(v._client))
        end
    end

    w:set_widget(flex)
end

--- Move/resize the wibox to the right spot when the layout change
local function before_draw_child(self, context, index, child, cr, width, height) --luacheck: no unused_args
    if not self._wibox then
        self._wibox = wibox({})
        create_tabbar(self._wibox, self._s:get_children())
    end

    local matrix = cr:get_matrix()

    self._wibox.x = matrix.x0
    self._wibox.y = matrix.y0
    self._wibox.height  = math.ceil(beautiful.get_font_height() * 1.5)
    self._wibox.width   = width
    self._wibox.visible = true
end

--- Hide the wibox
local function suspend(self)
    self._wibox.visible = false
    self._s:suspend()
end

--- Display the wibox
local function wake_up(self)
    self._wibox.visible = true
    self._s:wake_up()
end

--- If there is only 1 tab left, self destruct
local function remove_widgets(self, widget)
    -- Self is the stack

    self._m._private.remove_widgets(self, widget)

    -- The delayed call is not really necessary, but it is safer to avoid
    -- messing with the hierarchy in nested calls
    if #self.children <= 1 then
        timer.delayed_call(function()
            -- Look for an handler, if none if found, then there is a bug
            -- somewhere
            local handler = widget._handler
            if not handler then
                local children = self._s:get_children(true)
                for _, w in ipairs(children) do
                    if w._handler then
                        handler = w._handler
                        break
                    end
                end
            end

            if not handler then return end

            local w = self.children[1]
            handler.widget:replace_widget(self._m, w, true)
        end)
    end
end

--- Construct a tabbed layout
local function ctr(_, _)
    local s = stack(false)

    local m = margins(s)
    m._s    = s
    s._m    = m
    m:set_top(math.ceil(beautiful.get_font_height() * 1.5))
    m:set_widget(s)

    m._private.remove_widgets  = s.remove_widgets
    rawset(m, "suspend"       , suspend       )
    rawset(m, "wake_up"       , wake_up       )
    rawset(s, "remove_widgets", remove_widgets)

    m.before_draw_child = before_draw_child

    -- "m" is a dumb proxy of "s", it only free the space for the tabbar
    if #fct == 0 then
        for k, f in pairs(s) do
            if type(f) == "function" and not m[k] then
                fct[k] = f
            end
        end
    end

    for name, func in pairs(fct) do
        rawset(m, name, function(_, ...) return func(s,...) end)
    end

    return m
end

return ctr
