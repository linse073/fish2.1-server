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

local room_mgr
local agent_mgr

skynet_m.init(function()
    room_mgr = skynet_m.queryservice("room_mgr")
    agent_mgr = skynet_m.queryservice("agent_mgr")
end)

local channel = {}

function channel:init(session, from, func)
    self._from = from
    local kcp = lkcp.lkcp_create(session, func)
    kcp:lkcp_nodelay(1, 10, 2, 1)
    kcp:lkcp_wndsize(128, 128)
    self._kcp = kcp
    self._update_func = function()
        self:update()
    end
    self._next_update = false
    self:addUpdate()
    timer.add_routine("check_activity", function()
        self:checkActivity()
        timer.del_routine("check_activity")
    end, 3000)
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
    if self._room then
        skynet_m.send_lua(self._room, "process", self._user_id, data)
    else
        local msg_id, user_id, room_id = string.unpack(">I2>I4>I2", data)
        if msg_id == c_to_s.join then
            local room = skynet_m.call_lua(room_mgr, "get", room_id)
            if room then
                if skynet_m.call_lua(room, "join", user_id, skynet_m.self()) then
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
            skynet_m.log(string.format("Illegale message from %s.", util.udp_address(self._from)))
            self:joinFail(error_code.unknown_error)
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
        skynet_m.send_lua(self._room, "kick", self._user_id)
    end
    self:send(string.pack(">I2>I2", s_to_c.kick, code))
    skynet_m.log(string.format("Kick user %d, code %d.", self._user_id, code))
    self._kcp:lkcp_flush()
end

function channel:update()
    local now = floor(skynet_m.now()*10)
    self._kcp:lkcp_update(now)
    local nt = self._kcp:lkcp_check(now)-now
    if nt > 0 then
        timer.add_routine("kcp_update", self._update_func, nt/10)
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

return {__index=channel}