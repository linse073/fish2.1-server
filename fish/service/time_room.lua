local skynet_m = require "skynet_m"
local timestep = require "timestep"
local timer = require "timer"

local setmetatable = setmetatable

local room_id = tonumber(...)

local timestep_i

local CMD = {}

CMD.routine = timer.call_routine

function CMD.join(user_id, pos, agent)
    return timestep_i:join(user_id, pos, agent)
end

function CMD.join_01(user_id, agent)
    return timestep_i:join_01(user_id, agent)
end

function CMD.kick(user_id, agent)
    timestep_i:kick(user_id, agent)
end

function CMD.process(user_id, data)
    timestep_i:process(user_id, data)
end

function CMD.on_fire(info)
    timestep_i:on_fire(info)
end

function CMD.on_dead(info)
    timestep_i:on_dead(info)
end

function CMD.on_set_cannon(info)
    timestep_i:on_set_cannon(info)
end

function CMD.on_use_item(info)
    timestep_i:on_use_item(info)
end

function CMD.on_bomb_fish(info)
    timestep_i:on_bomb_fish(info)
end

skynet_m.start(function()
    timestep_i = setmetatable({}, timestep)
    timestep_i:init(room_id)

    skynet_m.dispatch_lua_queue(CMD)
end)