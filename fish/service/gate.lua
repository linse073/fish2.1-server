local skynet_m = require "skynet_m"
local socket = require "skynet.socket"
local util = require "util"

local string = string

local UDP_HELLO = "62a559f3fa7748bc22f8e0766019d498"
local UDP_HELLO_ACK = "1432ad7c829170a76dd31982c3501eca"
local version = skynet_m.getenv("version")
local agent_mgr
local udp

local function on_recv(data, from)
    local hello = string.unpack("z", data)
    if hello == UDP_HELLO then
        local session = skynet_m.call_lua(agent_mgr, "new", skynet_m.self(), from)
        local ack = string.pack("zz>I4", UDP_HELLO_ACK, version, session)
        socket.sendto(udp, from, ack)
        skynet_m.log(string.format("Reveive connect message from %s.", util.udp_address(from)))
    else
        local agent, gate = skynet_m.call_lua(agent_mgr, "get", from)
        if agent then
            if gate == skynet_m.self() then
                skynet_m.send_lua(agent, "process", data)
            else
                skynet_m.log(string.format("Agent %s receive message from different gate.", util.udp_address(from)))
            end
        else
            skynet_m.log(string.format("Reveive illegal message from %s.", util.udp_address(from)))
        end
    end
end

local CMD = {}

function CMD.start(addr, port)
    udp = socket.udp(on_recv, addr, port)
end

function CMD.send(from, data)
    socket.sendto(udp, from, data)
end

skynet_m.start(function()
    agent_mgr = skynet_m.queryservice("agent_mgr")

    skynet_m.dispatch_lua(CMD)
end)