---------------------------------------------------------------------------
--- Split the focussed* client area in two
-- The `treesome` layout split it to maximize both client size
-- `treesome.vertical` and `treesome.horizontal` will always split the client
-- in the same axis. It is possible to change the layout mode during runtime
--
-- * Or, when there is none, the largest client
--
-- Based on https://github.com/RobSis/treesome
--
-- BUG, over very, very long period of time, this will create tons of empty
-- subdivision layout. They need to be GCed manually
--
-- @author Emmanuel Lepage Vallee &lt;elv1313@gmail.com&gt;
-- @copyright 2016 Emmanuel Lepage Vallee
-- @release @AWESOME_VERSION@
-- @module awful.layout.dynamic.suit.treesome
---------------------------------------------------------------------------

local dynamic = require("awful.layout.dynamic.base")
local base_layout = require( "awful.layout.dynamic.base_layout" )

local capi = {client = client}

local function add(self, widget)
    if not widget then return end

    local c = widget._client

    if c then
        self._clientmap[c] = widget
    end

    -- Add the first client, if there is other drawable, they don't count
    if not next(self._clientparentmap) then

        self._private.add(self, widget)

        if c then
            self._clientparentmap[c] = self
        end

        return
    end

    local best_c = capi.client.focus

    -- Get the largest client, only work if the tag is visible
    local current = 0
    if not best_c then
        for _, c2 in ipairs(self._tag:clients()) do
            local geo = c2:geometry()
            if geo.width*geo.height > current then
                best_c = c2
                current = geo.width*geo.height
            end
        end
    end

    if best_c then
        local to_split_w = self._clientmap[best_c]
        local layout = self._clientparentmap[best_c]

        local geo = best_c:geometry()
        local orientation = geo.width > geo.height and "vertical" or "horizontal"

        local l = base_layout[orientation]()

        local idx = 0

        --TODO replace swap be "replace"
        for k,v in ipairs(layout.widgets) do
            if v == to_split_w then
                idx = k
                break
            end
        end

        print(layout, idx, to_split_w)
        if idx > 0 then
            layout.widgets[idx] = l
            l:add(to_split_w)
            l:add(widget)
            self._clientparentmap[best_c] = l
            if c then
                self._clientparentmap[c] = l
            end

            layout:emit_signal("widget::layout_changed") --TODO use replace
        end
    end

    self:emit_signal("widget::layout_changed")
end

local function ctr(t, direction)
    local main_layout = base_layout.vertical()

    main_layout._col_layout = base_layout[
        (direction == "left" or direction == "right")
            and "vertical" or "horizontal"
    ]

    main_layout._clientmap       = {}
    main_layout._clientparentmap = {}

    main_layout._add = main_layout.add

    main_layout.add    = add

    main_layout._tag = t

    return main_layout
end

local module = dynamic("treesome", function(t) return ctr(t, "right") end)

module.horizontal   = dynamic("treesomeh",   function(t) return ctr(t, "treesomeh"  ) end)
module.horizontal   = dynamic("treesomev",   function(t) return ctr(t, "treesomev"  ) end)

return module
