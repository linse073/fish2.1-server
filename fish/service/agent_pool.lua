local skynet_m = require "skynet_m"

local ipairs = ipairs
local table = table
local pcall = pcall

local free_list = {}
local agent_list = {}
local session = 0
local new_fork = nil
local del_fork = nil

local function new_agent(num)
    local t = {}
    for i = 1, num do
        session = session + 1
        t[i] = skynet_m.newservice("agent", session)
    end
    local l = #free_list
    for k, v in ipairs(t) do
        l = l + 1
        free_list[l] = v
        agent_list[v] = l
    end
end

local function del_agent(num)
    local l = #free_list
    if num > l then
        num = l
    end
    local t = {}
    for i = 1, num do
        local agent = free_list[l]
        t[i] = agent
        table.remove(free_list, l)
        agent_list[agent] = nil
        l = l - 1
    end
    for _, v in ipairs(t) do
        skynet_m.send_lua(v, "exit")
    end
end

local CMD = {}

function CMD.get()
    local l = #free_list
    local agent
    if l > 0 then
        agent = free_list[l]
        table.remove(free_list, l)
        agent_list[agent] = 0
        if l <= 50 and not new_fork then
            new_fork = skynet_m.fork(function()
                pcall(new_agent, 50)
                new_fork = nil
            end)
        end
    else
        session = session + 1
        agent = skynet_m.newservice("agent", session)
        agent_list[agent] = 0
    end
    return agent
end

function CMD.free(agent)
    if agent_list[agent] == 0 then
        local l = #free_list + 1
        free_list[l] = agent
        agent_list[agent] = l
        if l >= 150 and not del_fork then
            del_fork = skynet_m.fork(function()
                pcall(del_agent, 50)
                del_fork = nil
            end)
        end
    end
end

function CMD.start()
    new_agent(100)
end

skynet_m.start(function()
	skynet_m.dispatch_lua(CMD)
end)
