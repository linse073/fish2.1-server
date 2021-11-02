local skynet_m = require "skynet_m"
local timer = require "timer"
local share = require "share"

local string = string

local game_mode = skynet_m.getenv("game_mode")
local ACTIVITY_TIMEOUT = 60 * 100 * 3

local room_mgr
local agent_mgr
local error_code

skynet_m.init(function()
    error_code = share.error_code
    room_mgr = skynet_m.queryservice("room_mgr")
    agent_mgr = skynet_m.queryservice("agent_mgr")
end)

local channel = {}

function channel:init(fd, func)
    self._fd = fd
    self._send = func
    self._check_activity_time = skynet_m.now()
    timer.add_routine("check_activity", function()
        self:checkActivity()
        timer.done_routine("check_activity")
    end, 3000)
end

function channel:process(msg_name, content)
    self._check_activity_time = skynet_m.now()
    if msg_name == "join_room" then
        if game_mode == "fake_game" then
            local user_id, room_id = content.user_id, content.room_id
            local room = skynet_m.call_lua(room_mgr, "get", room_id)
            if room then
                if self._room then
                    skynet_m.log(string.format("User old:%d new:%d rejoin room.", self._user_id, user_id))
                else
                    local ret_info = skynet_m.call_lua(room, "join_01", user_id, skynet_m.self())
                    if ret_info.code == error_code.ok then
                        self._user_id = user_id
                        self._room = room
                        skynet_m.send_lua(agent_mgr, "bind", user_id, self._fd)
                        self._send("join_resp", ret_info)
                        skynet_m.log(string.format("User %d join room %d successfully.", user_id, room_id))
                    else
                        skynet_m.log(string.format("User %d join room %d fail.", user_id, room_id))
                        self:joinFail(ret_info.code)
                    end
                end
            else
                skynet_m.log(string.format("Illegal room %d.", room_id))
                self:joinFail(error_code.room_not_exist)
            end
        else
            local user_id = content.user_id
            local info = skynet_m.call_lua(room_mgr, "get_user", user_id)
            if info then
                if info.room then
                    if self._room then
                        skynet_m.log(string.format("User old:%d new:%d rejoin room.", self._user_id, user_id))
                    else
                        if content.session == info.sessionid then
                            local ret_info = skynet_m.call_lua(info.room, "join", user_id, info.seatid, skynet_m.self())
                            if ret_info.code == error_code.ok then
                                self._user_id = user_id
                                self._room = info.room
                                skynet_m.send_lua(agent_mgr, "bind", user_id, self._fd)
                                self._send("join_resp", ret_info)
                                skynet_m.log(string.format("User %d join room %d successfully.", user_id, info.tableid))
                            else
                                skynet_m.log(string.format("User %d join room %d fail.", user_id, info.tableid))
                                self:joinFail(ret_info.code)
                            end
                        else
                            skynet_m.log(string.format("Join room session error, %s, %s.",
                                                        content.session, info.sessionid))
                            self:joinFail(error_code.session_error)
                        end
                    end
                else
                    skynet_m.log(string.format("Illegal room %d.", info.tableid))
                    self:joinFail(error_code.room_not_exist)
                end
            else
                skynet_m.log(string.format("Not receive enter game message from %d.", user_id))
                self:joinFail(error_code.unknown_error)
            end
        end
    else
        if self._room then
            skynet_m.send_lua(self._room, "process", self._user_id, msg_name, content)
        else
            skynet_m.log(string.format("User %d don't join room.", self._user_id))
        end
    end
end

function channel:joinFail(code)
    self._send("join_resp", {code = code})
    skynet_m.send_lua(agent_mgr, "kick", self._fd, code)
end

function channel:kick(code)
    if self._room then
        skynet_m.send_lua(self._room, "kick", self._user_id, skynet_m.self())
        skynet_m.log(string.format("Kick user %d, code %d.", self._user_id, code))
        self._room = nil
        self._user_id = nil
    end
    if code == error_code.ok then
        self._send("kick", {code = code})
    end
end

-- NOTICE: must use send_lua
function channel:checkActivity()
    local now = skynet_m.now()
    if now - self._check_activity_time >= ACTIVITY_TIMEOUT then
        skynet_m.send_lua(agent_mgr, "kick", self._fd, error_code.low_activity)
    end
end

return {__index=channel}