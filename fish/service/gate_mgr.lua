local skynet_m = require "skynet_m"

local tonumber = tonumber
local pairs = pairs
local table = table

local gate_list = {}

local function new_gate(addr, port)
    if not gate_list[port] then
        local gate = skynet_m.newservice("gate")
        skynet_m.send_lua(gate, "start", addr, port)
        gate_list[port] = gate
    end
end

local function create_gate()
    local udp_address = skynet_m.getenv("udp_address")
    local udp_port = skynet_m.getenv("udp_port")
    for port_str in udp_port:gmatch("([^,]+)") do
        local port = tonumber(port_str)
        if port then
            new_gate(udp_address, port)
        else
            local port_begin, port_end = port_str:match("(%d+)-(%d+)")
            if port_begin and port_end then
                for i = tonumber(port_begin), tonumber(port_end) do
                    new_gate(udp_address, i)
                end
            end
        end
    end
end

local CMD = {}

function CMD.get_port()
    local port = {}
    for k, _ in pairs(gate_list) do
        table.insert(port, k)
    end
    return port
end

skynet_m.start(function()
    create_gate()

    skynet_m.dispatch_lua(CMD)
end)