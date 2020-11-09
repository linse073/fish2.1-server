local skynet_m = require "skynet_m"
local timer = require "timer"
local lflock = require "lflock"

local flock

local function callback()
end

local function test()
    flock = lflock.lflock_create(callback, flock_data, camera_data, obstacle_data)
    timer.add_routine("updat_flock", function()
        flock:lflock_update();
    end, 10)
end

local CMD = {}

skynet_m.start(function()
    test()

    skynet_m.dispatch_lua(CMD)
end)