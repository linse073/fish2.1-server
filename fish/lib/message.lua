
local message = {}

message.c_to_s = {
    join = 1001,
    ready = 1002,
    quit = 1003,
    op = 1004,
}

message.s_to_c = {
    join_resp = 2001,
    kick = 2002,
    leave_room = 2003,
    join_room = 2004,
    room_data = 2005,
    sync_data = 2006,
}

message.cmd = {
    idle = 1,
    fire = 2,
}

return message