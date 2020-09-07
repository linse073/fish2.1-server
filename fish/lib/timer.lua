local skynet_m = require "skynet_m"

local timer = {}

local routine
local routine_list = {}

skynet_m.init(function()
    routine = skynet_m.queryservice("routine")
end)

local function gen_key(key)
    return skynet_m.self() .. key
end

-- NOTICE: allow routine_list[key] exist
function timer.add_routine(key, func, interval)
    key = gen_key(key)
    routine_list[key] = func
    skynet_m.send_lua(routine, "add", skynet_m.self(), key, interval)
end

function timer.done_routine(key)
    key = gen_key(key)
    if routine_list[key] then
        skynet_m.send_lua(routine, "done", key)
    end
end

function timer.del_routine(key)
    key = gen_key(key)
    if routine_list[key] then
        skynet_m.send_lua(routine, "del", key)
        routine_list[key] = nil
    end
end

function timer.del_all()
    for k, _ in pairs(routine_list) do
        skynet_m.send_lua(routine, "del", k)
    end
    routine_list = {}
end

function timer.call_routine(key)
    local func = routine_list[key]
    if func then
        func()
    end
end

return timer
