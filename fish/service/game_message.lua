local skynet_m = require "skynet_m"

local string = string
local ipairs = ipairs
local assert = assert

local server_id = skynet_m.getenv_num("server_id")
local server_session = skynet_m.getenv("server_session")
local udp_address = skynet_m.getenv("udp_address")

local message_handle = {}
local cmd_handle = {}
local pack_message = {}
local pack_cmd = {}

local game_client
local room_mgr
local gate_mgr

local CMD = {}

-- NOTICE: send messag

local function pack_string(str)
    local len = #str
    if len < 255 then
        return string.pack("<s1", str)
    elseif len < 0xfffe then
        return string.pack("B<s2", 0xff, str)
    else
        return string.pack("B<I2<s4", 0xff, 0xffff, str)
    end
end

local function send_msg(id, msg)
    local pack = assert(pack_message[id], string.format("No pack message %d.", id))(msg)
    skynet_m.send_lua(game_client, "send_package", id, pack)
end

local function send_cmd(id, msg)
    local pack = assert(pack_cmd[id], string.format("No pack cmd %d.", id))(msg)
    pack = string.pack("<I2<s2", id, pack)
    skynet_m.send_lua(game_client, "send_package", 13503, pack)
end

local function pack_link(msg)
    local pack = string.pack("<I4", server_id)
    pack = pack .. pack_string(udp_address)
    local port = skynet_m.call_lua(gate_mgr, "get_port");
    pack = pack .. string.pack("<I4", #port)
    for _, v in ipairs(port) do
        pack = pack .. string.pack("<I4", v)
    end
    return pack .. pack_string(server_session)
end

local function pack_heart_beat(msg)
    return string.pack("<i2", 1)
end

local function pack_enter_game(msg)
    return string.pack("<I4<I2<I2", msg.userid, msg.tableid, msg.seatid)
end

local function pack_leave_game(msg)
    return string.pack("<I4<I2<I2", msg.userid, msg.tableid, msg.seatid)
end

local function pack_use_prop(msg)
    return string.pack("<I2<I2<I4<I4<I4", msg.tableid, msg.seatid, msg.userid, msg.probid, msg.probCount)
end

local function pack_build_fish(msg)
    local pack = string.pack("<I2", msg.tableid)
    local fish = msg.fish
    -- pack = pack .. string.pack("B", #fish)
    for _, v in ipairs(fish) do
        pack = pack .. string.pack("<I4<I2", v.id, v.kind)
    end
    for i = #fish+1, 100 do
        pack = pack .. string.pack("<I4<I2", 0, 0)
    end
    return pack
end

local function pack_fire(msg)
    local pack = string.pack("<I2<I2<I4", msg.tableid, msg.seatid, msg.userid)
    local bullet = msg.bullet
    pack = pack .. string.pack("<I4<I4<I4<I4<I8", bullet.id, bullet.kind, bullet.multi, bullet.power, bullet.expTime)
    return pack
end

local function pack_catch_fish(msg)
    return string.pack("<I2<I2<I4<I4<I4<I2", msg.tableid, msg.seatid, msg.userid, msg.bulletid, msg.fishid, msg.bulletMulti)
end

pack_message[13501] = pack_link
pack_message[1] = pack_heart_beat

pack_cmd[1401] = pack_enter_game
pack_cmd[1402] = pack_leave_game
pack_cmd[1403] = pack_use_prop
pack_cmd[1404] = pack_build_fish
pack_cmd[1405] = pack_fire
pack_cmd[1406] = pack_catch_fish

function CMD.send_link()
    send_msg(13501)
end

function CMD.send_heart_beat()
    send_msg(1)
end

function CMD.send_enter_game(msg)
    send_cmd(1401, msg)
end

function CMD.send_leave_game(msg)
    send_cmd(1402, msg)
end

function CMD.send_use_prob(msg)
    send_cmd(1403, msg)
end

function CMD.send_build_fish(msg)
    send_cmd(1404, msg)
end

function CMD.send_fire(msg)
    send_cmd(1405, msg)
end

function CMD.send_catch_fish(msg)
    send_cmd(1406, msg)
end

-- NOTICE: recv message

local function unpack_string(pack, index)
    local len = string.unpack("B", pack, index)
    if len < 255 then
        return string.unpack("<s1", pack, index)
    end
    len = string.unpack("<I2", pack, index+1)
    if len < 0xfffe then
        return string.unpack("<s2", pack, index+1)
    end
    len = string.unpack("<I4", pack, index+3)
    return string.unpack("<s4", pack, index+3)
end

local function recv_cmd(msg)
    local id, pack = string.pack("<I2<s2", msg)
    assert(cmd_handle[id], string.format("No cmd %d handle.", id))(pack)
end

local function recv_link(msg)
    local code, next_index = string.unpack("<i4", msg)
    local msg_info = unpack_string(msg, next_index)
    skynet_m.log(string.format("RespLink: %d %s.", code, msg_info))
    skynet_m.send_lua(game_client, "on_link")
end

local function recv_heart_beat(msg)
    local active = string.unpack("<i2", msg)
    skynet_m.log(string.format("HeartBeat: %d.", active))
    skynet_m.send_lua(game_client, "on_heart_beat")
end

local function recv_enter_game(msg)
    local info = {}
    info.tableid, info.seatid, info.userid, info.sessionid = string.unpack("<I2<I2<I4c32", msg)
    skynet_m.log(string.format("UserEnterGame: %d %d %d %s.", info.tableid, info.seatid, info.userid, info.sessionid))
end

local function recv_leave_game(msg)
    local tableid, seatid, userid = string.unpack("<I2<I2<I4", msg)
    skynet_m.log(string.format("UserLeaveGame: %d %d %d.", tableid, seatid, userid))
end

local function recv_use_prop(msg)
    local tableid, seatid, userid, probid, probCount = string.unpack("<I2<I2<I4<I4<I4", msg)
    skynet_m.log(string.format("UserUseProp: %d %d %d %d %d.", tableid, seatid, userid, probid, probCount))
end

local function recv_build_fish(msg)
    -- local tableid, num, index = string.unpack("<I2B", msg)
    -- local fish = {}
    -- for i = 1, num do
    --     local info = {}
    --     info.id, info.kind, index = string.unpack("<I4<I2", msg, index)
    --     fish[#fish+1] = info
    -- end
    local tableid, index = string.unpack("<I2", msg)
    local fish = {}
    for i = 1, 100 do
        local info = {}
        info.id, info.kind, index = string.unpack("<I4<I2", msg, index)
        if info.id > 0 then
            fish[#fish+1] = info
        end
    end
    local code = string.unpack("<I2", msg, index)
    skynet_m.log(string.format("BuildFishs: %d %d.", tableid, code))
end

local function recv_fire(msg)
    local tableid, seatid, userid, index = string.unpack("<I2<I2<I4", msg)
    local bullet = {}
    bullet.id, bullet.kind, bullet.multi, bullet.power, bullet.expTime, index = string.unpack("<I4<I4<I4<I4<I8", msg, index)
    local code, costGold = string.unpack("<I2<I4", msg, index)
    skynet_m.log(string.format("UserFire: %d %d %d %d %d %d.", tableid, seatid, userid, bullet.id, code, costGold))
end

local function recv_catch_fish(msg)
    local tableid, seatid, userid, bulletid, fishid, fishKind, multi, bulltMulti, winGold, code =
        string.unpack("<I2<I2<I4<I4<I4<I2<I2<I2<I4<I2", msg)
    skynet_m.log(string.format("CatchFish: %d %d %d %d %d %d %d %d.", tableid, seatid, userid, bulletid, fishid, winGold, code))
end

message_handle[13502] = recv_link
message_handle[13504] = recv_cmd
message_handle[1] = recv_heart_beat

cmd_handle[1301] = recv_enter_game
cmd_handle[1302] = recv_leave_game
cmd_handle[1303] = recv_use_prop
cmd_handle[1304] = recv_build_fish
cmd_handle[1305] = recv_fire
cmd_handle[1306] = recv_catch_fish

function CMD.recv_msg(msg)
    local len, id, index = string.unpack("<I2<I2", msg)
    assert(message_handle[id], string.format("No message %d handle.", id))(msg:sub(index))
end

skynet_m.start(function()
    game_client = skynet_m.queryservice("game_client")
    room_mgr = skynet_m.queryservice("room_mgr")
    gate_mgr = skynet_m.queryservice("gate_mgr")

    skynet_m.dispatch_lua(CMD)
end)