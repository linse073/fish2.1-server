
local message = {}

message.c_to_s = {
    ready = 11,
    quit = 12,
    op = 13,
}

message.s_to_c = {
    join_resp = 51,
    kick = 52,
    leave_room = 53,
    join_room = 54,
    room_data = 55,
    sync_data = 56,
}

message.cmd = {
    idle = 1,
    fire = 2,
}

return message