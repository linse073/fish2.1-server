local skynet_m = require "skynet_m"
local timer = require "timer"
local lflock = require "lflock"

local assert = assert

local flock

local function callback()
end

local function test()
    local flock_file = assert(io.open("./fish/data/Flock_01.dat", "rb"))
    local flock_data = flock_file:read("*a")
    flock_file:close()
    local camera_file = assert(io.open("./fish/data/Camera_01.dat", "rb"))
    local camera_data = camera_file:read("*a")
    camera_file:close()
    local obstacle_file = assert(io.open("./fish/data/Obstacle_01.dat", "rb"))
    local obstacle_data = obstacle_file:read("*a")
    obstacle_file:close()
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