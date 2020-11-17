local skynet_m = require "skynet_m"

local room_count = skynet_m.getenv_num("room_count")
local room_list = {}
local user_list = {}

local function create_room()
    for i = 1, room_count do
        room_list[i] = skynet_m.newservice("room")
    end
end

local CMD = {}

function CMD.get(room_id)
    return room_list[room_id]
end

function CMD.enter_game(info)
    if user_list[info.userid] then
        skynet_m.log(string.format("User %d already enter game.", info.userid))
    end
    user_list[info.userid] = info
end

function CMD.leave_game(info)
    local old = user_list[info.userid]
    if not old or old.talbeid ~= info.tableid or old.seatid ~= info.seatid then
        skynet_m.log("Leave game info differ from enter info.")
    end
    user_list[info.userid] = nil
end

function CMD.get_user(userid)
    return user_list[userid]
end

skynet_m.start(function()
    create_room()

    skynet_m.dispatch_lua(CMD)
end)