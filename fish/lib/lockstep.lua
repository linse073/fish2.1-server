local skynet_m = require "skynet_m"
local timer = require "timer"
local message = require "message"
local c_to_s = message.c_to_s
local s_to_c = message.s_to_c
local op_cmd = message.op_cmd
local error_code = message.error_code
local lflock = require "lflock"

local string = string
local pairs = pairs
local ipairs = ipairs
local table = table
local floor = math.floor
local assert = assert

local CMD = {
    [c_to_s.ready] = "ready",
    [c_to_s.quit] = "quit",
    [c_to_s.op] = "op",
}

local step_per_second = skynet_m.getenv_num("step_per_second")
local init_key_step = skynet_m.getenv_num("init_key_step")
local logic_step = skynet_m.getenv_num("logic_step")
local step_interval = 100/step_per_second
local half_step_interval = step_interval*0.5
local MAX_USER = 4

local agent_mgr

skynet_m.init(function()
    agent_mgr = skynet_m.queryservice("agent_mgr")
end)

local lockstep = {}

function lockstep:init()
    self._user = {}
    self._pos = {}
    self._count = 0
    self._ready_count = 0
    self:clear()
    self._update_func = function()
        self:update()
        timer.done_routine("lockstep_update")
    end
    self._check_func = function()
        self:checkActivity()
        timer.done_routine("lockstep_check")
    end
    self._flock_func = function()
    end
end

function lockstep:join(user_id, agent)
    self:kick(user_id)
    if self._count >= MAX_USER then
        return false
    end
    local free_pos = 0
    for i = 1, MAX_USER do
        if not self._pos[i] then
            free_pos = i
            break
        end
    end
    assert(free_pos~=0, "No free pos.")
    local now = skynet_m.now()
    local info = {
        user_id = user_id,
        agent = agent,
        ready = false,
        pos = free_pos,
        cmd_count = 0,
        key_cmd_count = nil,
        key_cmd = "",
        status_time = now,
    }
    self._user[user_id] = info
    self._pos[free_pos] = info
    self._count = self._count+1
    if not self._status_time then
        self._status_time = now
        timer.add_routine("lockstep_check", self._check_func, 100)
    end
    return true
end

function lockstep:checkActivity()
    local now = skynet_m.now()
    if now - self._status_time >= 6000 then
        for k, _ in pairs(self._user) do
            skynet_m.send_lua(agent_mgr, "quit", k, error_code.low_activity)
        end
        self._user = {}
        self._pos = {}
        self._count = 0
        self._ready_count = 0
        self:clear()
    else
        for k, v in pairs(self._user) do
            if now - v.status_time >= 6000 then
                skynet_m.send_lua(agent_mgr, "quit", k, error_code.low_activity)
            end
        end
    end
end

function lockstep:clear()
    self._history = {}
    self._cmd_count = 0
    self._cmd_rate = {}
    self._all_cmd_time = nil
    self._step = 0
    self._key_step = init_key_step
    self._next_key_step = self._key_step
    self._last_key_step = 0
    self._next_logic_step = logic_step
    self._time_scale = 1
    self._elapsed_time = 0
    self._last_time = 0
    self._next_step_time = step_interval
    self._next_scale_interval = (step_interval*self._key_step)*0.5
    self._next_scale_time = self._next_scale_interval
    self._next_sync_time = self._next_scale_time
    self._rand_seed = 0
    self._status_time = nil
    self._flock = nil
    timer.del_all()
end

function lockstep:start()
    self._last_time = skynet_m.now()
    self._rand_seed = floor(self._last_time)
    timer.add_routine("lockstep_update", self._update_func, 1)
    self._status_time = self._last_time

    local flock_file = assert(io.open("./fish/data/Flock_01.dat", "rb"))
    local flock_data = flock_file:read("*a")
    flock_file:close()
    local camera_file = assert(io.open("./fish/data/Camera_01.dat", "rb"))
    local camera_data = camera_file:read("*a")
    camera_file:close()
    local obstacle_file = assert(io.open("./fish/data/Obstacle_01.dat", "rb"))
    local obstacle_data = obstacle_file:read("*a")
    obstacle_file:close()
    self._flock = lflock.lflock_create(flock_data, camera_data, obstacle_data, self._rand_seed, self._flock_func)
end

function lockstep:kick(user_id, agent)
    local info = self._user[user_id]
    if info and (not agent or info.agent == agent) then
        self._user[user_id] = nil
        self._pos[info.pos] = nil
        self._count = self._count-1
        if info.ready then
            self._ready_count = self._ready_count-1
            self:broadcast(string.pack(">I2>I4", s_to_c.leave_room, user_id))
        end
        if self._count == 0 then
            self:clear()
        end
    end
end

function lockstep:process(user_id, data)
    local info = self._user[user_id]
    if not info then
        skynet_m.log(string.format("Can't find user %d.", user_id))
        return
    end
    local cmd = string.unpack(">I2", data)
    local func = CMD[cmd]
    if func then
        self[func](self, info, data)
        info.status_time = skynet_m.now()
    else
        skynet_m.log(string.format("Receive illegal cmd %d from user %d.", cmd, user_id))
    end
end

function lockstep:broadcast(msg)
    for _, v in pairs(self._user) do
        if v.ready then
            skynet_m.send_lua(v.agent, "send", msg)
        end
    end
end

function lockstep:update()
    local now = skynet_m.now()
    local etime = (now-self._last_time)*self._time_scale
    self._last_time = now
    self._elapsed_time = self._elapsed_time+etime
    if self._cmd_count > 0 then
        self:updateSyncCmd()
    else
        self:updateScaleTime()
    end
    self:updateStep(now)
end

function lockstep:updateSyncCmd()
    if self._next_sync_time and self._elapsed_time >= self._next_sync_time then
        local all_cmd, cmd_user_count = "", 0
        for k, v in pairs(self._user) do
            if v.key_cmd_count and v.key_cmd_count > 0 then
                assert(v.key_cmd_count < 255)
                all_cmd = all_cmd..string.pack(">I4BB", k, v.pos, v.key_cmd_count)..v.key_cmd
                cmd_user_count = cmd_user_count+1
            end
        end
        local cmd_rate = -1
        if self._all_cmd_time then
            if self._all_cmd_time <= self._next_sync_time-half_step_interval then
                cmd_rate = 1
            elseif self._all_cmd_time <= self._next_sync_time then
                cmd_rate = 0
            end
        end
        table.insert(self._cmd_rate, cmd_rate)
        local rate_len = #self._cmd_rate
        if rate_len >= 5 then
            local rate_value = 0
            for i = rate_len-4, rate_len do
                rate_value = rate_value+self._cmd_rate[i]
            end
            if rate_value >= 3 then
                if self._key_step > 1 then
                    self._key_step = self._key_step-1
                end
                self._cmd_rate = {}
            elseif rate_value <=-3 then
                if self._key_step < 5 then
                    self._key_step = self._key_step+1
                end
                self._cmd_rate = {}
            end
        end
        self._next_sync_time = nil
        self._next_scale_interval = nil
        self._next_scale_time = nil
        self._time_scale = 1
        -- TODO: sync data and key step
        local again_key_step = self._next_key_step+self._key_step
        local msg = string.pack(">I2>I4>I4", s_to_c.sync_data, self._next_key_step, again_key_step)
        local cmd_pack = string.pack("B", cmd_user_count)..all_cmd
        for _, v in pairs(self._user) do
            if v.ready then
                skynet_m.send_lua(v.agent, "send", msg..string.pack(">I4", v.cmd_count)..cmd_pack)
            end
            v.key_cmd_count = nil
            v.key_cmd = ""
        end
        table.insert(self._history, {self._next_key_step, again_key_step, cmd_pack})
        self._cmd_count = 0
        self._all_cmd_time = nil
        -- TODO: bullet collision detect
    end
end

function lockstep:updateScaleTime()
    while self._next_scale_time and self._elapsed_time >= self._next_scale_time do
        self._next_scale_interval = self._next_scale_interval*0.5
        if self._next_scale_interval > 1 then
            self._time_scale = self._time_scale*0.5
            self._next_scale_time = self._next_scale_time+self._next_scale_interval
        else
            self._time_scale = 0
            self._next_scale_interval = nil
            self._next_scale_time = nil
            break
        end
    end
end

function lockstep:updateStep(now)
    while self._elapsed_time >= self._next_step_time do
        local step = self._step+1
        if step == self._next_key_step then
            local cmd_num = #self._history
            if cmd_num <= 0 or self._history[cmd_num][1] ~= self._next_key_step then
                break
            end
        end
        local step_time = self._next_step_time
        self._next_step_time = step_time+step_interval
        self._step = step
        if step == self._next_key_step then
            assert(not self._next_sync_time, "Have not sync data.")
            self._next_key_step = step+self._key_step
            self._last_key_step = step
            self._next_scale_interval = (step_interval*self._key_step)*0.5
            self._next_scale_time = step_time+self._next_scale_interval
            self._next_sync_time = self._next_scale_time
            -- TODO: do cmd
            self._flock:lflock_oncmd(self._history[#self._history][3])
            if self._cmd_count > 0 then
                self:updateSyncCmd()
            else
                self:updateScaleTime()
            end
            self._status_time = now
        end
        if step == self._next_logic_step then
            self._next_logic_step = step+logic_step
            -- TODO: do logic
        end
        self._flock:lflock_update()
    end
end

function lockstep:ready(info, data)
    if info.ready then
        skynet_m.log(string.format("User %d is ready.", info.user_id))
    else
        self:broadcast(string.pack(">I2>I4B", s_to_c.join_room, info.user_id, info.pos))
        info.ready = true
        self._ready_count = self._ready_count+1
        if self._ready_count == 1 then
            self:start()
        end
        local msg = string.pack(">I2BB", s_to_c.room_data, info.pos, logic_step)
        msg = msg..string.pack(">I4>I4>I4", self._last_key_step, self._next_key_step, self._next_logic_step)
        msg = msg..string.pack("B", self._ready_count-1)
        for _, v in pairs(self._user) do
            if v.ready and v.user_id~=info.user_id then
                msg = msg..string.pack(">I4B", v.user_id, v.pos)
            end
        end
        -- msg = msg..string.pack(">I4", #self._history)
        -- for _, v in ipairs(self._history) do
        --     msg = msg..string.pack(">I4>I4>s4", v[1], v[2], v[3])
        -- end
        local num = #self._history
        if num > 0 then
            msg = msg..string.pack(">I4", 1)
            local last = self._history[num]
            msg = msg..string.pack(">I4>I4>s4", last[1], last[2], last[3])
        else
            msg = msg..string.pack(">I4", 0)
        end
        msg = msg..self._flock:lflock_pack()
        skynet_m.send_lua(info.agent, "send", msg)
        -- TODO: send room data to client
    end
end

function lockstep:quit(info, data)
    skynet_m.send_lua(agent_mgr, "quit", info.user_id, error_code.ok)
end

function lockstep:op(info, data)
    if not info.key_cmd_count then
        info.key_cmd_count = 0
        self._cmd_count = self._cmd_count+1
        if self._cmd_count == self._ready_count then
            self._all_cmd_time = self._elapsed_time
        end
    end
    local cmd_count, key_count, first_cmd, index = string.unpack(">I4BB", data, 3)
    if cmd_count > info.cmd_count then
        info.cmd_count = cmd_count
    end
    if first_cmd == op_cmd.idle then
        if key_count ~= 1 then
            skynet_m.log("Idle command count error.")
        end
    else
        info.key_cmd_count = info.key_cmd_count+key_count
        info.key_cmd = info.key_cmd..string.sub(data, index-1)
    end
end

return {__index=lockstep}