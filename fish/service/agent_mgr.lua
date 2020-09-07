local skynet_m = require "skynet_m"
local util = require "util"

local assert = assert
local string = string

local agent_pool
local agent_list = {}
local user_list = {}

local CMD = {}

function CMD.new(gate, from)
    local info = agent_list[from]
    local agent
    if info then
        agent = info.agent
        info.gate = gate
        if info.user_id then
            user_list[info.user_id] = nil
        end
        info.user_id = nil
    else
        agent = skynet_m.call_lua(agent_pool, "get")
        info = {agent=agent, gate=gate}
        agent_list[from] = info
    end
    return skynet_m.call_lua(agent, "start", gate, from)
end

function CMD.get(from)
    local info = agent_list[from]
    if info then
        return info.agent, info.gate
    end
end

function CMD.bind(user_id, from)
    local info = agent_list[from]
    assert(info and not info.user_id, string.format("Bind agent error from %s.", util.udp_address(from)))
    local user_from = user_list[user_id]
    if user_from then
        local old_info = agent_list[user_from]
        assert(old_info and old_info.user_id==user_id and info.agent~=old_info.agent,
            string.format("Unbind agent error from %s.", util.udp_address(user_from)))
        agent_list[user_from] = nil
        skynet_m.send_lua(old_info.agent, "stop")
        skynet_m.send_lua(agent_pool, "free", old_info.agent)
    end
    info.user_id = user_id
    user_list[user_id] = from
end

function CMD.kick(from)
    local info = agent_list[from]
    if info then
        agent_list[from] = nil
        if info.user_id then
            user_list[info.user_id] = nil
        end
        skynet_m.send_lua(info.agent, "stop")
        skynet_m.send_lua(agent_pool, "free", info.agent)
    end
end

-- TODO: finish
function CMD.quit(user_id)
    local from = user_list[user_id]
    if from then
        CMD.kick(from)
    end
end

skynet_m.start(function()
    agent_pool = skynet_m.queryservice("agent_pool")

    skynet_m.dispatch_lua_queue(CMD)
end)