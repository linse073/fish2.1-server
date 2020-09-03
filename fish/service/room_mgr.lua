local skynet_m = require "skynet_m"

local room_count = skynet_m.getenv_num("room_count")
local room_list = {}

local function create_room()
    for i = 1, room_count do
        room_list = skynet_m.newservice("room")
    end
end

local CMD = {}

function CMD.get(room_id)
    return room_list[room_id]
end

skynet_m.start(function()
    create_room()

    skynet_m.dispatch_lua(CMD)
end)