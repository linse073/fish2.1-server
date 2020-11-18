local skynet_m = require "skynet_m"

local ipairs = ipairs

local game_message
local msg_queue = {}
local init = false

local CMD = {}

local function send_package(id, pack)
    skynet_m.send_lua(game_message, "recv_msg", id, pack)
end

function CMD.send_package(id, pack)
    if init then
        send_package(id, pack)
    else
        msg_queue[#msg_queue+1] = {id, pack}
    end
end

function CMD.start()
    game_message = skynet_m.queryservice("fake_message")
    skynet_m.send_lua(game_message, "send_link")
end

function CMD.on_link()
    init = true
    for _, v in ipairs(msg_queue) do
        send_package(v[1], v[2])
    end
    msg_queue = {}
end

function CMD.on_heart_beat()
    -- timer.done_routine("heart_beat")
end

function CMD.stop()
    init = false
end

function CMD.exit()
    skynet_m.exit()
end

skynet_m.start(function()
    skynet_m.dispatch_lua(CMD)
end)