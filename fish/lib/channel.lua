local skynet_m = require "skynet_m"
local lkcp = require "lkcp"
local timer = require "timer"
local util = require "util"
local message = require "message"
local s_to_c = message.s_to_c
local c_to_s = message.c_to_s
local error_code = message.error_code

local string = string
local floor = math.floor

local game_mode = skynet_m.getenv("game_mode")
local UDP_HELLO_ACK = "1432ad7c829170a76dd31982c3501eca"
local version = skynet_m.getenv("version")

local room_mgr
local agent_mgr

skynet_m.init(function()
    room_mgr = skynet_m.queryservice("room_mgr")
    agent_mgr = skynet_m.queryservice("agent_mgr")
end)

local channel = {}

function channel:init(session, from, func)
    self._from = from
    self._send_func = func
    self._session = session
    local kcp = lkcp.lkcp_create(session, func)
    kcp:lkcp_nodelay(1, 10, 2, 1)
    kcp:lkcp_wndsize(128, 128)
    self._kcp = kcp
    self._update_func = function()
        self:update()
    end
    self._next_update = false
    self:addUpdate()
    if game_mode == "fake_game" then
        timer.add_routine("check_activity", function()
            self:checkActivity()
            timer.del_routine("check_activity")
        end, 3000)
    end
    timer.add_routine("check_join", function()
        self:checkJoin()
        timer.done_routine("check_join")
    end, 200)
end

function channel:process(data)
    if self._kcp:lkcp_input(data) < 0 then
        skynet_m.log(string.format("Kcp input error from %s.", util.udp_address(self._from)))
        return
    end
    while true do
        local len, buff = self._kcp:lkcp_recv()
        if len > 0 then
            self:processPack(buff)
        else
            break
        end
    end
    self:addUpdate()
end

function channel:processPack(data)
    local msg_id, index = string.unpack(">I2", data)
    if msg_id == c_to_s.join then
        if game_mode == "fake_game" then
            local user_id, room_id = string.unpack(">I4>I2", data, index)
            local room = skynet_m.call_lua(room_mgr, "get", room_id)
            if room then
                if self._room then
                    skynet_m.send_lua(self._room, "kick", self._user_id, skynet_m.self())
                    skynet_m.log(string.format("Kick user %d.", self._user_id))
                end
                if skynet_m.call_lua(room, "join_01", user_id, skynet_m.self()) then
                    self._user_id = user_id
                    self._room = room
                    skynet_m.send_lua(agent_mgr, "bind", user_id, self._from)
                    self:send(string.pack(">I2>I2", s_to_c.join_resp, error_code.ok))
                    timer.del_routine("check_activity")
                    skynet_m.log(string.format("User %d join room %d successfully.", user_id, room_id))
                else
                    skynet_m.log(string.format("User %d join room %d fail.", user_id, room_id))
                    self:joinFail(error_code.room_full)
                end
            else
                skynet_m.log(string.format("Illegal room %d from %s.", room_id, util.udp_address(self._from)))
                self:joinFail(error_code.room_not_exist)
            end
        else
            local user_id = string.unpack(">I4", data, index)
            local info = skynet_m.call_lua(room_mgr, "get_user", user_id)
            if info then
                if info.room then
                    if self._room then
                        skynet_m.send_lua(self._room, "kick", self._user_id, skynet_m.self())
                        skynet_m.log(string.format("Kick user %d.", self._user_id))
                    end
                    if skynet_m.call_lua(info.room, "join", user_id, info.seatid, skynet_m.self()) then
                        self._user_id = user_id
                        self._room = info.room
                        skynet_m.send_lua(agent_mgr, "bind", user_id, self._from)
                        self:send(string.pack(">I2>I2", s_to_c.join_resp, error_code.ok))
                        timer.del_routine("check_activity")
                        skynet_m.log(string.format("User %d join room %d successfully.", user_id, info.tableid))
                    else
                        skynet_m.log(string.format("User %d join room %d fail.", user_id, info.tableid))
                        self:joinFail(error_code.room_full)
                    end
                else
                    skynet_m.log(string.format("Illegal room %d from %s.", info.tableid,
                                                util.udp_address(self._from)))
                    self:joinFail(error_code.room_not_exist)
                end
            else
                skynet_m.log(string.format("Not receive enter game message from %s %d.",
                                            util.udp_address(self._from), user_id))
                self:joinFail(error_code.unknown_error)
            end
        end
        timer.del_routine("check_join")
    else
        if self._room then
            skynet_m.send_lua(self._room, "process", self._user_id, data)
        else
            skynet_m.log(string.format("User %d don't join room.", self._user_id))
        end
    end
end

function channel:joinFail(code)
    self:send(string.pack(">I2>I2", s_to_c.join_resp, code))
    -- skynet_m.send_lua(agent_mgr, "kick", self._from, code)
end

function channel:send(data)
    if self._kcp:lkcp_send(data) < 0 then
        skynet_m.log(string.format("Kcp send error from %s.", util.udp_address(self._from)))
    end
    self:addUpdate()
end

function channel:kick(code)
    if self._room then
        skynet_m.send_lua(self._room, "kick", self._user_id, skynet_m.self())
        skynet_m.log(string.format("Kick user %d, code %d.", self._user_id, code))
    end
    self:send(string.pack(">I2>I2", s_to_c.kick, code))
    self._kcp:lkcp_flush()
end

function channel:update()
    local now = floor(skynet_m.now() * 10)
    self._kcp:lkcp_update(now)
    local nt = self._kcp:lkcp_check(now) - now
    if nt > 0 then
        timer.add_routine("kcp_update", self._update_func, nt / 10)
    end
    self._next_update = false
end

function channel:addUpdate()
    if not self._next_update then
        self._next_update = true
        timer.add_routine("kcp_update", self._update_func, 0)
    end
end

-- NOTICE: must use send_lua
function channel:checkActivity()
    if not self._room then
        skynet_m.send_lua(agent_mgr, "kick", self._from, error_code.low_activity)
    end
end

function channel:checkJoin()
    if not self._room then
        local ack = string.pack("zz>I4", UDP_HELLO_ACK, version, self._session)
        self._send_func(ack)
    end
end

return {__index=channel}