local skynet_m = require "skynet_m"
local message = require "message"
local error_code = message.error_code

local string = string
-- local ipairs = ipairs
local assert = assert
local math = math

local server_id = skynet_m.getenv_num("server_id")
local server_session = skynet_m.getenv("server_session")
local udp_address = skynet_m.getenv("udp_address")

local message_handle = {}
local cmd_handle = {}

local game_client
local room_mgr
local gate_mgr
local agent_mgr

local CMD = {}

-- NOTICE: send messag

local function send_msg(id, msg)
    skynet_m.send_lua(game_client, "send_package", id, msg)
end

local function send_cmd(id, msg)
    msg.id = id
    skynet_m.send_lua(game_client, "send_package", 13503, msg)
end

function CMD.send_link()
    send_msg(13501, {
        serverid = server_id,
        ip = udp_address,
        port = skynet_m.call_lua(gate_mgr, "get_port"),
        session = server_session,
    })
end

function CMD.send_heart_beat()
    send_msg(1, {
        active = 1,
    })
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
    -- NOTICE: cmd(1407) do nothing()
end

function CMD.send_bomb_fish(msg)
    send_cmd(1408, msg)
end

-- NOTICE: recv message

local message_map = {
    [13501] = 13502,
    [13503] = 13504,
    [1] = 1,
    [1401] = 1301,
    [1402] = 1302,
    [1403] = 1303,
    [1404] = 1304,
    [1405] = 1305,
    [1406] = 1306,
    [1408] = 1308,
}

local function recv_cmd(msg)
    assert(cmd_handle[message_map[msg.id]], string.format("No cmd %d handle.", msg.id))(msg.tableid, msg)
end

local function recv_link(msg)
    local code = 0
    local msg_info = "login successfully."
    skynet_m.log(string.format("RespLink: %d %s.", code, msg_info))
    skynet_m.send_lua(game_client, "on_link")
end

local function recv_heart_beat(msg)
    skynet_m.log(string.format("HeartBeat: %d.", msg.active))
    skynet_m.send_lua(game_client, "on_heart_beat")
end

local function recv_enter_game(tableid, info)
    info.sessionid = string.format("%d", info.userid)
    skynet_m.log(string.format("UserEnterGame: %d %d %d %s.", info.tableid, info.seatid, info.userid, info.sessionid))
    skynet_m.send_lua(room_mgr, "enter_game", info)
end

local function recv_leave_game(tableid, info)
    skynet_m.log(string.format("UserLeaveGame: %d %d %d.", info.tableid, info.seatid, info.userid))
    skynet_m.send_lua(room_mgr, "leave_game", info)
    skynet_m.send_lua(agent_mgr, "quit", info.userid, error_code.ok)
end

local function recv_use_prob(tableid, info)
    skynet_m.log(string.format("UserUseProb: %d %d %d %d %d.", info.tableid, info.seatid, info.userid, info.probid,
                                info.probCount))
    local room = skynet_m.call_lua(room_mgr, "get", info.tableid)
    skynet_m.send_lua(room, "on_use_item", info)
end

local function recv_build_fish(tableid, msg)
    local index = 1
    local fish = {}
    for i = 1, 100 do
        local info = {}
        info.id, info.kind, index = string.unpack("<I4<I2", msg.fish, index)
        if info.id > 0 then
            fish[#fish+1] = info
        else
            break
        end
    end
    local code = 0
    skynet_m.log(string.format("BuildFishs: %d %d.", tableid, code))
end

local function recv_fire(tableid, info)
    local bullet = info.bullet
    info.code, info.costGold, info.fishScore = 0, 1000, 10000
    skynet_m.log(string.format("UserFire: %d %d %d %d %d %d %d.", info.tableid, info.seatid, info.userid, bullet.id,
                                info.code, info.costGold, info.fishScore))
    local room = skynet_m.call_lua(room_mgr, "get", info.tableid)
    skynet_m.send_lua(room, "on_fire", info)
end

local function recv_catch_fish(tableid, info)
    if math.random(1000) <= 300 then
        info.fishKind, info.multi, info.winGold, info.fishScore, info.code = 1, 1, 10000, 100000, 0
        skynet_m.log(string.format("CatchFish: %d %d %d %d %d %d %d %d.", info.tableid, info.seatid, info.userid,
                                    info.bulletid, info.fishid, info.winGold, info.fishScore, info.code))
        local room = skynet_m.call_lua(room_mgr, "get", info.tableid)
        skynet_m.send_lua(room, "on_dead", info)
    end
end

local function recv_set_cannon(tableid, info)
    local room = skynet_m.call_lua(room_mgr, "get", info.tableid)
    skynet_m.send_lua(room, "on_set_cannon", info)
end

local function recv_bomb_fish(tableid, msg)
    local room = skynet_m.call_lua(room_mgr, "get", msg.tableid)
    local fish = {}
    local index = 1
    skynet_m.log(string.format("BombFish begin: %d %d %d.", msg.tableid, msg.seatid, msg.userid))
    for i = 1, 100 do
        local id
        id, index = string.unpack("<I4", msg.fish, index)
        if id > 0 then
            local info = {}
            info.fishid, info.fishKind, info.multi, info.winGold, info.fishScore = id, 1, 1, 10000, 100000
            skynet_m.log(string.format("BombFish: %d %d %d.", info.fishid, info.winGold, info.fishScore))
            fish[#fish+1] = info
        else
            break
        end
    end
    skynet_m.send_lua(room, "on_bomb_fish", {
        tableid = msg.tableid,
        seatid = msg.seatid,
        userid = msg.userid,
        fish = fish,
    })
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

function CMD.recv_msg(id, msg)
    assert(message_handle[message_map[id]], string.format("No message %d handle.", id))(msg)
end

function CMD.start()
    game_client = skynet_m.queryservice("fake_game")
    room_mgr = skynet_m.queryservice("room_mgr")
    gate_mgr = skynet_m.queryservice("gate_mgr")
    agent_mgr = skynet_m.queryservice("agent_mgr")
    math.randomseed(skynet_m.now())
end

function CMD.exit()
    skynet_m.exit()
end

skynet_m.start(function()
    skynet_m.dispatch_lua_queue(CMD)
end)