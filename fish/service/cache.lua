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
    local spline_data = require("spline_data")
    sharedata.new("spline_data", spline_data)
    local message = require("message")
    sharedata.new("message", message)
    local define = require("define")
    sharedata.new("define", define)
    local matrix_data = require("matrix_data")
    sharedata.new("matrix_data", matrix_data)
    local skill_data = require("skill_data")
    sharedata.new("skill_data", skill_data)
    local fish_born = require("fish_born")
    sharedata.new("fish_born", fish_born)

    local camera_spline = {}
    local camera_boss_spline = {}
    for k, v in pairs(spline_data) do
        if util.is_camera_spline(k) then
            camera_spline[k] = v
        end
        if util.is_camera_boss_spline(k) then
            camera_boss_spline[k] = v
        end
    end
    sharedata.new("camera_spline", camera_spline)
    sharedata.new("camera_boss_spline", camera_boss_spline)
end)
