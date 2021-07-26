local skynet_m = require "skynet_m"
local socket = require "skynet.socket"
local util = require "util"

local string = string

local UDP_HELLO = "62a559f3fa7748bc22f8e0766019d498"
local UDP_HELLO_ACK = "1432ad7c829170a76dd31982c3501eca"
local UDP_RECONNECT = "8d08ff7abe09aa764a8b3e92eab1a99f"
local version = skynet_m.getenv("version")
local agent_mgr
local udp

local CMD = {}

local function send_reconnect(from)
    local msg = string.pack("c32", UDP_RECONNECT)
    CMD.send(from, msg)
end

local function on_recv(data, from)
    local hello
    if #data == 32 then
        hello = string.unpack("c32", data)
    end
    if hello == UDP_HELLO then
        local session = skynet_m.call_lua(agent_mgr, "new", skynet_m.self(), from)
        local ack = string.pack("c32z>I4", UDP_HELLO_ACK, version, session)
        socket.sendto(udp, from, ack)
        skynet_m.log(string.format("Reveive connect message from %s, session is %d.", util.udp_address(from), session))
    else
        local agent, gate = skynet_m.call_lua(agent_mgr, "get", from)
        if agent then
            if gate == skynet_m.self() then
                skynet_m.send_lua(agent, "process", data)
            else
                skynet_m.log(string.format("Agent %s receive message from different gate.", util.udp_address(from)))
                send_reconnect(from)
            end
        else
            skynet_m.log(string.format("Reveive illegal message from %s.", util.udp_address(from)))
            send_reconnect(from)
        end
    end
end

function CMD.start(addr, port)
    skynet_m.log(string.format("start udp %s: %d", addr, port))
    udp = socket.udp(on_recv, addr, port)
end

function CMD.send(from, data)
    socket.sendto(udp, from, data)
end

skynet_m.start(function()
    agent_mgr = skynet_m.queryservice("agent_mgr")

    skynet_m.dispatch_lua(CMD)
end)