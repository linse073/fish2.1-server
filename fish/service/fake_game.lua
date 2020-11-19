local skynet_m = require "skynet_m"

local game_message

local CMD = {}

function CMD.send_package(id, pack)
    skynet_m.send_lua(game_message, "recv_msg", id, pack)
end

function CMD.start()
    game_message = skynet_m.queryservice("fake_message")
    skynet_m.send_lua(game_message, "send_link")
end

function CMD.on_link()
end

function CMD.on_heart_beat()
    -- timer.done_routine("heart_beat")
end

function CMD.stop()
end

function CMD.exit()
    skynet_m.exit()
end

skynet_m.start(function()
    skynet_m.dispatch_lua(CMD)
end)