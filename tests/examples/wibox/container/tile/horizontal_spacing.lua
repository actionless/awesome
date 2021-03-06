--DOC_GEN_IMAGE --DOC_HIDE
local parent = ... --DOC_HIDE
local wibox  = require("wibox") --DOC_HIDE
local beautiful = require( "beautiful" )  --DOC_HIDE

local l = wibox.layout { --DOC_HIDE
    forced_width  = 240, --DOC_HIDE
    spacing       = 5, --DOC_HIDE
    layout        = wibox.layout.flex.vertical --DOC_HIDE
} --DOC_HIDE

for _, i in ipairs {0, 2, 5, 10} do
    local w = wibox.widget {
        {
            image         = beautiful.awesome_icon,
            forced_height = 30,
            forced_width  = 30,
            widget        = wibox.widget.imagebox
        },
        valign             = "top",
        halign             = "left",
        horizontal_spacing = i,
        widget             = wibox.container.tile
    }

    l:add(wibox.widget {--DOC_HIDE
        {--DOC_HIDE
            markup = "<b>`horizontal_spacing` = "..i.."</b>",--DOC_HIDE
            widget = wibox.widget.textbox,--DOC_HIDE
        },--DOC_HIDE
        w,--DOC_HIDE
        layout = wibox.layout.fixed.vertical,--DOC_HIDE
    }) --DOC_HIDE
end

parent:add(l) --DOC_HIDE

--DOC_HIDE vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
