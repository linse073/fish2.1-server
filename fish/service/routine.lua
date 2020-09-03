local skynet_m = require "skynet_m"

local pairs = pairs
local pcall = pcall

local routine_list = {}
local running = false

local function time_routine()
    local now = skynet_m.now()
    for k, v in pairs(routine_list) do
        if now >= v.time then
            v.time = v.time + v.interval
            if not v.loop then
                routine_list[k] = nil
            end
            skynet_m.send_lua(v.address, "routine", k)
        end
    end
end

local CMD = {}

function CMD.exit()
    running = false
end

-- NOTICE: allow routine[key] exist
function CMD.add(address, key, interval, loop)
    routine_list[key] = {
        address = address,
        interval = interval,
        loop = loop,
        time = skynet_m.now() + interval,
    }
end

function CMD.del(key)
    routine_list[key] = nil
end

skynet_m.start(function()
    running = true
    skynet_m.fork(function()
        while running do
            local succ, err = pcall(time_routine)
            if not succ then
                skynet_m.log(err)
                skynet_m.warn(err)
            end
            skynet_m.sleep(1)
        end
    end)

    skynet_m.dispatch_lua(CMD)
end)
