
local message = {}

local pairs = pairs

message.c_to_s = {
    join = 1001,
    ready = 1002,
    quit = 1003,
    fire = 1004,
    hit = 1005,
    heart_beat = 1006,
}

message.c_to_s_i = {}
for k, v in pairs(message.c_to_s) do
    message.c_to_s_i[v] = k
end

message.s_to_c = {
    join_resp = 2001,
    kick = 2002,
    leave_room = 2003,
    join_room = 2004,
    room_data = 2005,
    fire = 2006,
    dead = 2007,
    set_cannon = 2008,
    heart_beat = 2009,
    new_fish = 2010,
    delete_fish = 2011,
    trigger_event = 2012,
    cast_skill = 2013,
}

message.op_cmd = {
    idle = 1,
    fire = 2,
    hit = 3,
    dead = 4,
    set_cannon = 5,
}

message.error_code = {
    ok = 0,
    room_full = 3001,
    room_not_exist = 3002,
    unknown_error = 3003,
    login_conflict = 3004,
    low_activity = 3005,
}

return message