local skynet_m = require "skynet_m"
local sharedata = require "skynet.sharedata"
local util = require "util"

local pairs = pairs

skynet_m.start(function()
    -- share data
    local event_data = require("event_data")
    sharedata.new("event_data", event_data)
    local fish_data = require("fish_data")
    sharedata.new("fish_data", fish_data)
    local loop_data = require("loop_data")
    sharedata.new("loop_data", loop_data)
    local spline_data = require("spline_data")
    sharedata.new("spline_data", spline_data)
    local message = require("message")
    sharedata.new("message", message)
    local define = require("define")
    sharedata.new("define", define)

    local camera_spline = {}
    for k, v in pairs(spline_data) do
        if util.is_camera_spline(k) then
            camera_spline[k] = v
        end
    end
    sharedata.new("camera_spline", camera_spline)
end)
