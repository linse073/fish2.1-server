local skynet_m = require "skynet_m"
local message = require "message"
local error_code = message.error_code

local string = string
local ipairs = ipairs
local assert = assert

local server_id = skynet_m.getenv_num("server_id")
local server_session = skynet_m.getenv("server_session")
local udp_send_address = skynet_m.getenv("udp_send_address")

local message_handle = {}
local cmd_handle = {}
local pack_message = {}
local pack_cmd = {}

local game_client
local room_mgr
local gate_mgr
local agent_mgr

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
    pack = string.pack("<I2<I2<s2", id, msg.tableid, pack)
    skynet_m.send_lua(game_client, "send_package", 13503, pack)
end

local function pack_link(msg)
    skynet_m.log(string.format("pack_link %d %s.", server_id, udp_send_address))
    local pack = string.pack("<I4", server_id)
    pack = pack .. pack_string(udp_send_address)
    local port = skynet_m.call_lua(gate_mgr, "get_port")
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
    return string.pack("<I2<I4", msg.seatid, msg.userid)
end

local function pack_leave_game(msg)
    return string.pack("<I2<I4", msg.seatid, msg.userid)
end

local function pack_use_prob(msg)
    return string.pack("<I2<I4<I4<I4", msg.seatid, msg.userid, msg.probid, msg.probCount)
end

local function pack_build_fish(msg)
    -- local fish = msg.fish
    -- -- pack = pack .. string.pack("B", #fish)
    -- for _, v in ipairs(fish) do
    --     pack = pack .. string.pack("<I4<I2", v.id, v.kind)
    -- end
    -- for i = #fish+1, 100 do
    --     pack = pack .. string.pack("<I4<I2", 0, 0)
    -- end
    return msg.fish
end

local function pack_fire(msg)
    local pack = string.pack("<I2<I4", msg.seatid, msg.userid)
    local bullet = msg.bullet
    pack = pack .. string.pack("<I4<I4<I4<I4<I8", bullet.id, bullet.kind, bullet.multi, bullet.power, bullet.expTime)
    return pack
end

local function pack_catch_fish(msg)
    return string.pack("<I2<I4<I4<I4<I2", msg.seatid, msg.userid, msg.bulletid, msg.fishid, msg.bulletMulti)
end

local function pack_kill_fish(msg)
    return msg.fish
end

local function pack_bomb_fish(msg)
    return string.pack("<I2<I4<I4<I2", msg.seatid, msg.userid, msg.bulletid, msg.bulletMulti) .. msg.fish
end

local function pack_clear(msg)
    return string.pack("<I4", msg.flag)
end

local function pack_trigger_fish(msg)
    return string.pack("<I2<I4<I4<I2", msg.seatid, msg.userid, msg.bulletid, msg.bulletMulti) .. msg.fish
end

local function pack_skill_damage(msg)
    return string.pack("<I2<I4", msg.seatid, msg.userid) .. msg.fish
end

local function pack_skill_timeout(msg)
    return string.pack("<I2<I4", msg.seatid, msg.userid)
end

pack_message[13501] = pack_link
pack_message[1] = pack_heart_beat

pack_cmd[1401] = pack_enter_game
pack_cmd[1402] = pack_leave_game
pack_cmd[1403] = pack_use_prob
pack_cmd[1404] = pack_build_fish
pack_cmd[1405] = pack_fire
pack_cmd[1406] = pack_catch_fish
pack_cmd[1407] = pack_kill_fish
pack_cmd[1408] = pack_bomb_fish
pack_cmd[1409] = pack_clear
pack_cmd[1410] = pack_trigger_fish
pack_cmd[1411] = pack_skill_damage
pack_cmd[1411] = pack_skill_timeout

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

function CMD.send_kill_fish(msg)
    send_cmd(1407, msg)
end

function CMD.send_bomb_fish(msg)
    send_cmd(1408, msg)
end

function CMD.send_clear(msg)
    send_cmd(1409, msg)
end

function CMD.send_trigger_fish(msg)
    send_cmd(1410, msg)
end

function CMD.send_skill_damage(msg)
    send_cmd(1411, msg)
end

function CMD.send_skill_timeout(msg)
    send_cmd(1412, msg)
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
    local id, tableid, pack = string.unpack("<I2<I2<s2", msg)
    assert(cmd_handle[id], string.format("No cmd %d handle.", id))(tableid, pack)
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

local function recv_enter_game(tableid, msg)
    local info = {}
    info.tableid = tableid
    info.seatid, info.userid, info.sessionid = string.unpack("<I2<I4c32", msg)
    skynet_m.log(string.format("UserEnterGame: %d %d %d %s %d.", info.tableid, info.seatid, info.userid, info.sessionid,
                                #info.sessionid))
    skynet_m.send_lua(room_mgr, "enter_game", info)
    CMD.send_enter_game(info)
end

local function recv_leave_game(tableid, msg)
    local info = {}
    info.tableid = tableid
    info.seatid, info.userid = string.unpack("<I2<I4", msg)
    skynet_m.log(string.format("UserLeaveGame: %d %d %d.", info.tableid, info.seatid, info.userid))
    skynet_m.send_lua(room_mgr, "leave_game", info)
    skynet_m.send_lua(agent_mgr, "quit", info.userid, error_code.ok)
    CMD.send_leave_game(info)
end

local function recv_use_prob(tableid, msg)
    local info = {}
    info.tableid = tableid
    info.seatid, info.userid, info.probid, info.probCount = string.unpack("<I2<I4<I4<I4", msg)
    skynet_m.log(string.format("UserUseProb: %d %d %d %d %d.", info.tableid, info.seatid, info.userid, info.probid,
                                info.probCount))
    local room = skynet_m.call_lua(room_mgr, "get", info.tableid)
    skynet_m.send_lua(room, "on_use_item", info)
end

local function recv_build_fish(tableid, msg)
    -- local tableid, num, index = string.unpack("<I2B", msg)
    -- local fish = {}
    -- for i = 1, num do
    --     local info = {}
    --     info.id, info.kind, index = string.unpack("<I4<I2", msg, index)
    --     fish[#fish+1] = info
    -- end
    local index = 1
    local fish = {}
    for i = 1, 100 do
        local info = {}
        info.id, info.kind, index = string.unpack("<I4<I2", msg, index)
        if info.id > 0 then
            fish[#fish+1] = info
        else
            break
        end
    end
    local code = string.unpack("<I2", msg, index)
    -- skynet_m.log(string.format("BuildFishs: %d %d.", tableid, code))
end

local function recv_fire(tableid, msg)
    local info = {}
    info.tableid = tableid
    local index
    info.seatid, info.userid, index = string.unpack("<I2<I4", msg)
    local bullet = {}
    bullet.id, bullet.kind, bullet.multi, bullet.power, bullet.expTime, index = string.unpack("<I4<I4<I4<I4<I8", msg,
                                                                                                index)
    info.bullet = bullet
    info.code, info.costGold, info.fishScore = string.unpack("<I2<I4<I8", msg, index)
    -- skynet_m.log(string.format("UserFire: %d %d %d %d %d %d %d.", info.tableid, info.seatid, info.userid, bullet.id,
    --                             info.code, info.costGold, info.fishScore))
    local room = skynet_m.call_lua(room_mgr, "get", info.tableid)
    skynet_m.send_lua(room, "on_fire", info)
end

local function recv_catch_fish(tableid, msg)
    local info = {}
    info.tableid = tableid
    info.seatid, info.userid, info.bulletid, info.fishid, info.fishKind, info.multi, info.bulletMulti, info.winGold,
        info.fishScore, info.code = string.unpack("<I2<I4<I4<I4<I2<I2<I2<I4<I8<I2", msg)
    skynet_m.log(string.format("CatchFish: %d %d %d %d %d %d %d %d.", info.tableid, info.seatid, info.userid,
                                info.bulletid, info.fishid, info.winGold, info.fishScore, info.code))
    local room = skynet_m.call_lua(room_mgr, "get", info.tableid)
    skynet_m.send_lua(room, "on_dead", info)
end

local function recv_set_cannon(tableid, msg)
    local info = {}
    info.tableid = tableid
    info.seatid, info.userid, info.cannon = string.unpack("<I2<I4<I2", msg)
    local room = skynet_m.call_lua(room_mgr, "get", info.tableid)
    skynet_m.send_lua(room, "on_set_cannon", info)
end

local function recv_bomb_fish(tableid, msg)
    local info = {}
    info.tableid = tableid
    local fish, index = {}, 1
    info.seatid, info.userid, info.bulletid, info.bulletMulti, info.winGold, info.fishScore, index
        = string.unpack("<I2<I4<I4<I2<I4<I8", msg, index)
    for i = 1, 100 do
        local id
        id, index = string.unpack("<I4", msg, index)
        if id > 0 then
            fish[#fish+1] = {
                fishid = id,
            }
        end
    end
    for i = 1, 100 do
        local score
        score, index = string.unpack("<I4", msg, index)
        local fish_info = fish[i]
        if fish_info then
            fish_info.score = score
        else
            -- NOTICE: have no use for string.unpack
            break
        end
    end
    info.fish = fish
    skynet_m.log(string.format("BombFish begin: %d %d %d %d %d.", info.tableid, info.seatid, info.userid,
                                info.winGold, info.fishScore))
    local room = skynet_m.call_lua(room_mgr, "get", info.tableid)
    skynet_m.send_lua(room, "on_bomb_fish", info)
end

local function recv_trigger_fish(tableid, msg)
    local info = {}
    info.tableid = tableid
    info.seatid, info.userid, info.bulletid, info.bulletMulti, info.fishid, info.fishKind
        = string.unpack("<I2<I4<I4<I2<I4<I2", msg)
    skynet_m.log(string.format("TriggerFish: %d %d %d %d %d.", info.tableid, info.seatid, info.userid,
                                info.bulletid, info.fishid))
    local room = skynet_m.call_lua(room_mgr, "get", info.tableid)
    skynet_m.send_lua(room, "on_trigger_dead", info)
end

local function recv_skill_damage(tableid, msg)
    local info = {}
    info.tableid = tableid
    local fish, index = {}, 1
    info.seatid, info.userid, info.winGold, info.fishScore, index = string.unpack("<I2<I4<I4<I8", msg, index)
    for i = 1, 100 do
        local id
        id, index = string.unpack("<I4", msg, index)
        if id > 0 then
            fish[#fish+1] = {
                fishid = id,
            }
        end
    end
    for i = 1, 100 do
        local score
        score, index = string.unpack("<I4", msg, index)
        local fish_info = fish[i]
        if fish_info then
            fish_info.score = score
        else
            -- NOTICE: have no use for string.unpack
            break
        end
    end
    info.fish = fish
    skynet_m.log(string.format("SkillDamage begin: %d %d %d %d %d.", info.tableid, info.seatid, info.userid,
                                info.winGold, info.fishScore))
    local room = skynet_m.call_lua(room_mgr, "get", info.tableid)
    skynet_m.send_lua(room, "on_skill_damage", info)
end

message_handle[13502] = recv_link
message_handle[13504] = recv_cmd
message_handle[1] = recv_heart_beat

cmd_handle[1301] = recv_enter_game
cmd_handle[1302] = recv_leave_game
cmd_handle[1303] = recv_use_prob
cmd_handle[1304] = recv_build_fish
cmd_handle[1305] = recv_fire
cmd_handle[1306] = recv_catch_fish
cmd_handle[1307] = recv_set_cannon
cmd_handle[1308] = recv_bomb_fish
cmd_handle[1309] = recv_trigger_fish
cmd_handle[1310] = recv_skill_damage

function CMD.recv_msg(msg)
    local len, id, index = string.unpack("<I2<I2", msg)
    assert(message_handle[id], string.format("No message %d handle.", id))(msg:sub(index))
end

function CMD.start()
    game_client = skynet_m.queryservice("game_client")
    room_mgr = skynet_m.queryservice("room_mgr")
    gate_mgr = skynet_m.queryservice("gate_mgr")
    agent_mgr = skynet_m.queryservice("agent_mgr")
end

function CMD.exit()
    skynet_m.exit()
end

skynet_m.start(function()
    skynet_m.dispatch_lua_queue(CMD)
end)