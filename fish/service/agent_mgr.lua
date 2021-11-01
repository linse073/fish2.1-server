local skynet_m = require "skynet_m"
local util = require "util"
local share = require "share"

local assert = assert
local string = string

local error_code

local agent_pool
local agent_list = {}
local user_list = {}

local CMD = {}

function CMD.new(gate, fd)
    local info = agent_list[fd]
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
        info = {
            agent = agent,
            gate = gate,
        }
        agent_list[fd] = info
    end
    return agent
end

function CMD.get(fd)
    local info = agent_list[fd]
    if info then
        return info.agent, info.gate
    end
end

function CMD.bind(user_id, fd)
    local info = agent_list[fd]
    assert(info and not info.user_id, "Bind agent error.")
    local user_fd = user_list[user_id]
    if user_fd then
        local old_info = agent_list[user_fd]
        assert(old_info and old_info.user_id==user_id and info.agent~=old_info.agent,
            "Unbind agent error.")
        agent_list[user_fd] = nil
        skynet_m.send_lua(old_info.agent, "stop", error_code.login_conflict)
        skynet_m.send_lua(agent_pool, "free", old_info.agent)
    end
    info.user_id = user_id
    user_list[user_id] = fd
end

function CMD.kick(fd, code)
    local info = agent_list[fd]
    if info then
        agent_list[fd] = nil
        if info.user_id then
            user_list[info.user_id] = nil
        end
        skynet_m.send_lua(info.agent, "stop", code)
        skynet_m.send_lua(agent_pool, "free", info.agent)
    end
end

-- TODO: finish
function CMD.quit(user_id, code)
    local fd = user_list[user_id]
    if fd then
        CMD.kick(fd, code)
    end
end

skynet_m.start(function()
    error_code = share.error_code

    agent_pool = skynet_m.queryservice("agent_pool")

    skynet_m.dispatch_lua_queue(CMD)
end)