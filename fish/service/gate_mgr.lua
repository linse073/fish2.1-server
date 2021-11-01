local skynet_m = require "skynet_m"

local tonumber = tonumber
local pairs = pairs
local table = table

local max_client = 2048

local gate_list = {}

local function new_gate(port)
    if not gate_list[port] then
        local watchdog = skynet_m.newservice("watchdog")
        skynet_m.call_lua(watchdog, "start", {
            port = port,
            maxclient = max_client,
            nodelay = true,
        })
        gate_list[port] = watchdog
    end
end

local function create_gate()
    local gate_port = skynet_m.getenv("gate_port")
    for port_str in gate_port:gmatch("([^,]+)") do
        local port = tonumber(port_str)
        if port then
            new_gate(port)
        else
            local port_begin, port_end = port_str:match("(%d+)-(%d+)")
            if port_begin and port_end then
                for i = tonumber(port_begin), tonumber(port_end) do
                    new_gate(i)
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