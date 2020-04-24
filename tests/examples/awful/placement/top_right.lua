--DOC_GEN_IMAGE --DOC_HIDE
-- Align a client to the top right of the parent area. --DOC_HEADER
-- @tparam drawable d A drawable (like `client`, `mouse` or `wibox`) --DOC_HEADER
-- @tparam[opt={}] table args Other arguments") --DOC_HEADER
-- @treturn table The new geometry --DOC_HEADER
-- @staticfct awful.placement.top_right --DOC_HEADER

screen[1]._resize {width = 128, height = 96} --DOC_HIDE
local awful = {placement = require("awful.placement")} --DOC_HIDE
local c = client.gen_fake {x = 45, y = 35, width=40, height=30} --DOC_HIDE

awful.placement.top_right(client.focus)

assert(c.x == screen[1].geometry.width-40-2*c.border_width and c.y==0 --DOC_HIDE
       and c.width==40 and c.height==30)--DOC_HIDE

--DOC_HIDE vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
