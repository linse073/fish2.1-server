local skynet_m = require "skynet_m"
local lockstep = require "lockstep"
local timer = require "timer"

local setmetatable = setmetatable

local room_id = tonumber(...)

local lockstep_i

local CMD = {}

CMD.routine = timer.call_routine

function CMD.join(user_id, agent)
    return lockstep_i:join(user_id, agent)
end

function CMD.kick(user_id, agent)
    lockstep_i:kick(user_id, agent)
end

function CMD.process(user_id, data)
    lockstep_i:process(user_id, data)
end

function CMD.fire(info)
    lockstep_i:fire(info)
end

skynet_m.start(function()
    lockstep_i = setmetatable({}, lockstep)
    lockstep_i:init(room_id)

    skynet_m.dispatch_lua_queue(CMD)
end)