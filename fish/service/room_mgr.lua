local skynet_m = require "skynet_m"

local room_count = skynet_m.getenv_num("room_count")
local room_list = {}
local user_list = {}

local function create_room()
    for i = 1, room_count do
        room_list[i] = skynet_m.newservice("time_room", i)
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
    local room = room_list[info.tableid]
    if not room then
        skynet_m.log(string.format("No room %d.", info.tableid))
    end
    info.room = room
    user_list[info.userid] = info
end

function CMD.leave_game(info)
    local old = user_list[info.userid]
    if old then
        if old.tableid ~= info.tableid or old.seatid ~= info.seatid then
            skynet_m.log("Leave game info differ from enter info, old(%d, %d) new(%d, %d).", old.tableid, old.seatid,
                            info.tableid, info.seatid)
        end
    else
        skynet_m.log(string.format("Can't find info when user %d leave game.", info.userid))
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