---------------------------------------------------------------------------
--- Replace the stateless fair.
--
-- This is not a perfect clone, as the stateful property of this layout
-- allow to minimize the number of clients being moved. If a splot of left
-- empty, then it will be used next time a client is added rather than
-- "pop" a client from the next column/row and move everything. This is
-- intended, if you really wish to see the old behavior, a new layout will
-- be created.
--
-- This version also support resizing, the older one did not--
--
--@DOC_awful_layout_dynamic_suit_fair_fair_EXAMPLE@
--
-- **Client count scaling**:
--
-- The first row is the `fair` layout and the second one `fair.horizontal`
--
--@DOC_awful_layout_dynamic_suit_fair_scaling_EXAMPLE@
--
-- **master_count effect**:
--
-- Unused
--
-- **column_count effect**:
--
-- Unused
--
-- **master_width_factor effect**:
--
-- Unused
--
-- **gap effect**:
--
-- The "useless" gap tag property will change the spacing between clients.
--@DOC_awful_layout_dynamic_suit_fair_gap_EXAMPLE@
-- See `awful.tag.setgap`
-- See `awful.tag.getgap`
-- See `awful.tag.incgap`
--
-- **screen padding effect**:
--
--@DOC_awful_layout_dynamic_suit_fair_padding_EXAMPLE@
-- See `awful.screen.padding`
--
-- @author Emmanuel Lepage Vallee &lt;elv1313@gmail.com&gt;
-- @copyright 2016 Emmanuel Lepage Vallee
-- @release @AWESOME_VERSION@
-- @module awful.layout.dynamic.suit.fair
---------------------------------------------------------------------------
local dynamic     = require("awful.layout.dynamic.base")
local base_layout = require( "awful.layout.dynamic.base_layout" )

local function get_bounds(self)
    local lowest_idx    = -1
    local highest_count = 0
    local lowest_count  = 9999

    for i = 1, #self._cols do
        local col = self._cols[i]
        local count = #col:get_children()

        if count < lowest_count then
            lowest_idx   = i
            lowest_count = count
        end

        lowest_count  = count < lowest_count  and count or lowest_count
        highest_count = count > highest_count and count or highest_count
    end

    return lowest_count, highest_count, lowest_idx
end

-- local function get_smallest_candidate(self)
--     local lowest_count, highest_count, lowest_idx = get_bounds(self)
-- 
--     if lowest_idx == -1 then return nil end
-- 
--     local smallest_ratio, smallest_widget = 999, nil
-- 
--     local col = self._cols[lowest_idx]
--     for k, v in ipairs(col:get_children()) do
--         if col:get_ratio(k) < smallest_ratio then
--             smallest_ratio = col:get_ratio(k)
--             smallest_widget = v
--         end
--     end
-- 
--     return v
-- end

local function add(self, widget)
    if not widget then return end

    local lowest_count, highest_count, lowest_idx = get_bounds(self)

    local ncols = #self._cols

    if ncols > 0 and (highest_count == 0 or (lowest_count == highest_count and highest_count <= ncols)) then
        -- Add to the first existing row
        self._cols[1]:add(widget)
    elseif lowest_count == highest_count or ncols == 0 then
        -- Add a row
        local l = self._col_layout()
        table.insert(self._cols, l)
        self._private.add(self, l)
        l:add(widget)
    elseif lowest_idx ~= -1 then
        -- Add to the row with the least clients
        self._cols[lowest_idx]:add(widget)
    else
        -- There is an internal corruption
        assert(false)
    end
end

local function ctr(_, direction)
    local main_layout = base_layout[
        (direction == "left" or direction == "right")
            and "horizontal" or "vertical"
    ]()

    main_layout._col_layout = base_layout[
        (direction == "left" or direction == "right")
            and "vertical" or "horizontal"
    ]

    -- Using .widgets could create issue if external code decide to add some
    -- wibox
    main_layout._cols = {}

    main_layout._private.add = main_layout.add
    main_layout.add  = add

    --TODO rebalance when a client is closed, swap with packed, then close

    return main_layout
end

local module = dynamic("fair", function(t) return ctr(t, "right") end)

module.horizontal = dynamic("fairh",   function(t) return ctr(t, "top"  ) end)

--- A fair layout prioritizing horizontal space.
-- @name horizontal
-- @class function

return module
