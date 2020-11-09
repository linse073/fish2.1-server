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
    flock = lflock.lflock_create(flock_data, camera_data, obstacle_data, callback)
end

local function update()
    timer.add_routine("updat_flock", function()
        flock:lflock_update();
        timer.done_routine("updat_flock")
    end, 10)
end

local CMD = {}

CMD.routine = timer.call_routine

skynet_m.start(function()
    test()
    skynet_m.dispatch_lua(CMD)
    update()
end)