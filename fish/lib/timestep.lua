local skynet_m = require "skynet_m"
local timer = require "timer"
local share = require "share"
local loop_time = require "loop_data"
local util = require "util"

local string = string
local pairs = pairs
local ipairs = ipairs
local table = table
local math = math

local game_mode = skynet_m.getenv("game_mode")

local MAX_USER = 4
local ACTIVITY_TIMEOUT = 60 * 100 * 30

local message
local s_to_c
local c_to_s_i
local error_code
local fish_data
local spline_data
local event_data
local define
local event_type
local fish_type
local camera_spline

local agent_mgr
local game_message
local event_function

skynet_m.init(function()
    agent_mgr = skynet_m.queryservice("agent_mgr")
    if game_mode == "fake_game" then
        game_message = skynet_m.queryservice("fake_message")
    else
        game_message = skynet_m.queryservice("game_message")
    end
    message = share.message
    s_to_c = message.s_to_c
    c_to_s_i = message.c_to_s_i
    error_code = message.error_code
    fish_data = share.fish_data
    spline_data = share.spline_data
    event_data = share.event_data
    define = share.define
    event_type = define.event_type
    fish_type = define.fish_type
    camera_spline = share.camera_spline
    event_function = {
        [event_type.active_scene_spline] = function(self, info)
            self._spline[info.spline_id] = info
        end,
        [event_type.deactive_scene_spline] = function(self, info)
            self._spline[info.spline_id] = nil
        end,
        [event_type.active_camera_spline] = function(self, info)
            self._use_follow_spline = true
        end,
        [event_type.deactive_camera_spline] = function(self, info)
            self._use_follow_spline = false
        end,
        [event_type.active_fish] = function(self, info)
            local data = fish_data[info.fish_id]
            local pool = self._fish_pool[data.type].pool
            pool[#pool+1] = {info, data}
        end,
        [event_type.deactive_fish] = function(self, info)
            local data = fish_data[info.fish_id]
            local pool = self._fish_pool[data.type].pool
            for i = #pool, 1, -1 do
                if pool[i][1].fish_id == info.fish_id then
                    table.remove(pool, i)
                end
            end
        end,
        [event_type.fight_boss] = function(self, info)
            local event = self._event
            event.info = info
            event.time = self._game_time - info.time
            event.data = fish_data[info.fish_id]
            local msg = string.pack(">I2>I4>f", s_to_c.trigger_event, info.id, event.data.life_time - event.time)
            self:broadcast(msg)
        end,
        [event_type.max_small_fish] = function(self, info)
            self._fish_pool[fish_type.small_fish].max_count = info.num
        end,
        [event_type.max_big_fish] = function(self, info)
            self._fish_pool[fish_type.big_fish].max_count = info.num
        end,
    }
end)

local timestep = {}

function timestep:init(room_id)
    self._room_id = room_id
    self._user = {}
    self._pos = {}
    self._count = 0
    self._ready_count = 0
    self:clear()
    self._check_func = function()
        self:checkActivity()
        timer.done_routine("timestep_check")
    end
    self._update_func = function()
        self:update()
        timer.done_routine("timestep_update")
    end
end

function timestep:join(user_id, free_pos, agent)
    self:kick(user_id)
    if self._count >= MAX_USER then
        skynet_m.log("Max user.")
        return false
    end
    free_pos = free_pos + 1
    if free_pos <= 0 or free_pos > MAX_USER then
        skynet_m.log(string.format("Illegal pos %d.", free_pos))
        return false
    end
    local now = skynet_m.now()
    local info = {
        user_id = user_id,
        agent = agent,
        ready = false,
        pos = free_pos,
        status_time = now,
        bullet = {},
    }
    self._user[user_id] = info
    self._pos[free_pos] = info
    self._count = self._count + 1
    -- NOTICE: game server notify user leave
    -- timer.add_routine("timestep_check", self._check_func, 100)
    return true
end

function timestep:join_01(user_id, agent)
    self:kick(user_id)
    if self._count >= MAX_USER then
        skynet_m.log("Max user.")
        return false
    end
    local free_pos = 0
    for i = 1, MAX_USER do
        if not self._pos[i] then
            free_pos = i
            break
        end
    end
    if free_pos == 0 then
        skynet_m.log("No free pos.")
        return false
    end
    local now = skynet_m.now()
    local info = {
        user_id = user_id,
        agent = agent,
        ready = false,
        pos = free_pos,
        status_time = now,
        bullet_id = 0,
    }
    self._user[user_id] = info
    self._pos[free_pos] = info
    self._count = self._count+1
    timer.add_routine("timestep_check", self._check_func, 100)
    return true
end

function timestep:checkActivity()
    local now = skynet_m.now()
    for k, v in pairs(self._user) do
        if now - v.status_time >= ACTIVITY_TIMEOUT then
            skynet_m.send_lua(agent_mgr, "quit", k, error_code.low_activity)
        end
    end
end

function timestep:clear()
    self._last_time = 0
    self._bullet_id = 0
    self._bullet = {}
    self._game_time = 0
    self._fish_id = 0
    self._group_id = 0
    self._fish = {}
    self._spline = {}
    self._spline_cd = {}
    self._fish_pool = {
        [fish_type.small_fish] = {
            pool = {},
            count = 0,
            max_count = 1,
            time = 0,
            interval = 4,
            rand_min = 1,
            rand_max = 2,
        },
        [fish_type.big_fish] = {
            pool = {},
            count = 0,
            max_count = 1,
            time = 0,
            interval = 5,
            rand_min = 1,
            rand_max = 2,
        },
        [fish_type.boss_fish] = {
            pool = {},
            count = 0,
        },
    }
    self._event = {
        index = 1,
        time = 0,
        info = nil,
    }
    self._use_follow_spline = true
    timer.del_all()
end

function timestep:loop()
    self._event.index = 1
    local small_pool = self._fish_pool[fish_type.small_fish]
    small_pool.pool = {}
    small_pool.max_count = 50
    local big_pool = self._fish_pool[fish_type.big_fish]
    big_pool.pool = {}
    big_pool.max_count = 30
    self._spline = {}
    self._spline_cd = {}
    self._use_follow_spline = true
end

function timestep:start()
    self._last_time = skynet_m.now()
    timer.add_routine("timestep_update", self._update_func, 100)
    math.randomseed(self._last_time)
    self:update()
end

function timestep:new_fish(info, data, num, new_fish)
    local begin_time = self._game_time
    self._group_id = self._group_id + 1
    local spline_id = info.spline_id
    if spline_id == 0 and data.life_time == 0 then
        local rand_spline, all_spline = {}, {}
        for k, v in pairs(self._spline) do
            if not self._spline_cd[k] then
                rand_spline[#rand_spline+1] = k
            end
            all_spline[#all_spline+1] = k
        end
        if self._use_follow_spline then
            for k, v in pairs(camera_spline) do
                if not self._spline_cd[k] then
                    rand_spline[#rand_spline+1] = k
                end
                all_spline[#all_spline+1] = k
            end
        end
        if #rand_spline > 0 then
            spline_id = rand_spline[math.random(#rand_spline)]
        elseif #all_spline > 0 then
            spline_id = all_spline[math.random(#all_spline)]
        end
    end
    if spline_id > 0 then
        self._spline_cd[spline_id] = 10
    end
    local life_time = data.life_time
    if life_time == 0 and spline_id > 0 and info.speed > 0 then
        life_time = spline_data[spline_id].length / info.speed
    end
    for i = 1, num do
        self._fish_id = self._fish_id + 1
        local new_info = {
            id = self._fish_id,
            fish_id = info.fish_id,
            spline_id = spline_id,
            group_id = self._group_id,
            speed = info.speed,
            begin_time = begin_time,
            life_time = life_time,
            time = self._game_time - begin_time,
            data = data,
        }
        new_fish[#new_fish+1] = new_info
        self._fish[self._fish_id] = new_info
        begin_time = begin_time + 0.5
    end
end

function timestep:update_fish(etime, pool_info, new_fish)
    pool_info.time = pool_info.time + etime
    if (pool_info.time >= pool_info.interval and pool_info.count < pool_info.max_count) or pool_info.count < pool_info.max_count * 10 // 8 then
        local pool = pool_info.pool
        if #pool > 0 then
            local info = pool[math.random(#pool)]
            local num = math.random(pool_info.rand_min, pool_info.rand_max)
            self:new_fish(info[1], info[2], num, new_fish)
            pool_info.count = pool_info.count + num
        end
        pool.time = 0
    end
end

function timestep:update_boss(pool_info, new_fish)
    if #pool_info.pool > 0 then
        for k, v in ipairs(pool_info.pool) do
            local info, data = v[1], v[2]
            self._fish_id = self._fish_id + 1
            local new_info = {
                id = self._fish_id,
                fish_id = info.fish_id,
                spline_id = info.spline_id,
                group_id = 0,
                speed = info.speed,
                begin_time = info.time,
                life_time = data.life_time,
                time = self._game_time - info.time,
                data = data,
            }
            new_fish[#new_fish+1] = new_info
            self._fish[self._fish_id] = new_info
        end
        pool_info.count = pool_info.count + #pool_info.pool
        pool_info.pool = {}
    end
end

function timestep:delete_fish(info)
    self._fish[info.id] = nil
    local pool_info = self._fish_pool[info.data.type]
    pool_info.count = pool_info.count - 1
    local event = self._event
    if event.info and event.info.type == event_type.fight_boss and event.info.fish_id == info.fish_id then
        event.info = nil
        event.time = 0
        event.data = nil
    end
end

function timestep:update()
    local now = skynet_m.now()
    local etime = (now - self._last_time) * 0.01
    self._last_time = now
    for k, v in pairs(self._spline_cd) do
        v = v - etime
        if v <= 0 then
            self._spline_cd[k] = nil
        end
    end
    local del_count, del_msg = 0, ""
    for k, v in pairs(self._fish) do
        v.time = v.time + etime
        if v.time >= v.life_time then
            self:delete_fish(v)
            del_count = del_count + 1
            del_msg = del_msg .. string.pack(">I4", k)
        end
    end
    if del_count > 0 then
        -- TODO: send delete fish message to game server
        del_msg = string.pack(">I2>I2", s_to_c.delete_fish, del_count) .. del_msg
        self:broadcast(del_msg)
    end
    local event = self._event
    if event.info then
        event.time = event.time + etime
    else
        self._game_time = self._game_time + etime
    end
    if self._game_time >= loop_time then
        self._game_time = self._game_time - loop_time
        self:loop()
    end
    while event.index <= #event_data do
        local info = event_data[event.index]
        if self._game_time < info.time then
            break
        end
        event_function[info.type](self, info)
        event.index = event.index + 1
    end
    local new_fish = {}
    for k, v in ipairs({fish_type.small_fish, fish_type.big_fish}) do
        self:update_fish(etime, self._fish_pool[v], new_fish)
    end
    self:update_boss(self._fish_pool[fish_type.boss_fish], new_fish)
    -- util.dump(new_fish, "new_fish");
    -- util.dump(self._fish_pool, "fish_pool")
    local new_num = #new_fish
    if new_num > 0 then
        local new_msg = ""
        local client_msg = string.pack(">I2>I2", s_to_c.new_fish, new_num)
        for k, v in ipairs(new_fish) do
            new_msg = new_msg .. string.pack("<I4<I2", v.id, v.fish_id)
            client_msg = client_msg .. string.pack(">I4>I4>I4>I4>f>f", v.id, v.fish_id, v.spline_id, v.group_id, v.speed, v.begin_time)
        end
        self:broadcast(client_msg)
        for i = new_num + 1, 100 do
            new_msg = new_msg .. string.pack("<I4<I2", 0, 0)
        end
        skynet_m.send_lua(game_message, "send_build_fish", {
            tableid = self._room_id,
            fish = new_msg,
        })
    end
    util.dump(self._fish, "fish");
end

function timestep:kick(user_id, agent)
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

function timestep:process(user_id, data)
    local info = self._user[user_id]
    if not info then
        skynet_m.log(string.format("Can't find user %d.", user_id))
        return
    end
    local cmd = string.unpack(">I2", data)
    local func = c_to_s_i[cmd]
    if func then
        self[func](self, info, data)
        info.status_time = skynet_m.now()
    else
        skynet_m.log(string.format("Receive illegal cmd %d from user %d.", cmd, user_id))
    end
end

function timestep:broadcast(msg)
    for _, v in pairs(self._user) do
        if v.ready then
            skynet_m.send_lua(v.agent, "send", msg)
        end
    end
end

function timestep:ready(info, data)
    if info.ready then
        skynet_m.log(string.format("User %d is ready.", info.user_id))
    else
        self:broadcast(string.pack(">I2>I4B", s_to_c.join_room, info.user_id, info.pos))
        info.ready = true
        self._ready_count = self._ready_count + 1
        if self._ready_count == 1 then
            self:start()
        end
        local client_time = string.unpack(">d", data, 3)
        local msg = string.pack(">I2>d>fB", s_to_c.room_data, client_time, self._game_time, info.pos)
        msg = msg .. string.pack("B", self._ready_count - 1)
        for _, v in pairs(self._user) do
            if v.ready and v.user_id ~= info.user_id then
                msg = msg .. string.pack(">I4B", v.user_id, v.pos)
            end
        end
        local fish_msg, fish_count = "", 0
        for k, v in pairs(self._fish) do
            fish_msg = fish_msg .. string.pack(">I4>I4>I4>I4>f>f", v.id, v.fish_id, v.spline_id, v.group_id, v.speed, v.begin_time)
            fish_count = fish_count + 1
        end
        msg = msg .. string.pack(">I2", fish_count) .. fish_msg
        local event = self._event
        if event.info then
            if event.info.type == event_type.fight_boss then
                msg = msg .. string.pack(">I4>f", event.info.id, event.data.life_time - event.time)
            else
                skynet_m.log(string.format("Can't get trigger event %d left time.", event.info.id))
                msg = msg .. string.pack(">I4>f", event.info.id, 10)
            end
        else
            msg = msg .. string.pack(">I4>f", 0, 0)
        end
        skynet_m.send_lua(info.agent, "send", msg)
    end
end

function timestep:quit(info, data)
    skynet_m.send_lua(agent_mgr, "quit", info.user_id, error_code.ok)
end

function timestep:fire(info, data)
    local self_id, angle, multi, kind = string.unpack(">I4>f>I4>I4", data, 3)
    self._bullet_id = self._bullet_id + 1
    info.bullet[self_id] = self._bullet_id
    skynet_m.send_lua(game_message, "send_fire", {
        tableid = self._room_id,
        seatid = info.pos - 1,
        userid = info.user_id,
        bullet = {
            id = self._bullet_id,
            kind = kind,
            multi = multi,
            power = 1,
            expTime = 0,
        },
    })
    self._bullet[self._bullet_id] = {
        id = self._bullet_id,
        self_id = self_id,
        kind = kind,
        angle = angle,
        multi = multi,
    }
end

function timestep:hit(info, data)
    local self_id, fishid, multi = string.unpack(">I4>I4>I4", data, 3)
    local bulletid = info.bullet[self_id]
    if not bulletid then
        skynet_m.log(string.format("Can't find bullet %d when user %d hit fish %d.", self_id, info.user_id, fishid))
        return
    end
    info.bullet[self_id] = nil
    skynet_m.send_lua(game_message, "send_catch_fish", {
        tableid = self._room_id,
        seatid = info.pos - 1,
        userid = info.user_id,
        bulletid = bulletid,
        fishid = fishid,
        bulletMulti = multi,
    })
end

function timestep:heart_beat(info, data)
    local client_time = string.unpack(">d", data, 3)
    local msg = string.pack(">I2>d>f", s_to_c.heart_beat, client_time, self._game_time)
    skynet_m.send_lua(info.agent, "send", msg)
end

function timestep:on_fire(info)
    local binfo = info.bullet
    if info.code ~= 0 then
        skynet_m.log(string.format("User %d fire bullet %d fail.", info.userid, binfo.id))
        return
    end
    local user_info = self._user[info.userid]
    if not user_info then
        skynet_m.log(string.format("Fire can't find user %d.", info.userid))
        return
    end
    local bullet = self._bullet[binfo.id]
    if binfo.kind ~= bullet.kind or binfo.multi ~= bullet.multi then
        skynet_m.log(string.format("Fire info is different."))
    end
    self._bullet[binfo.id] = nil
    local msg = string.pack(">I2>I4>I4>I4B>f>I4>I4>I8", s_to_c.fire, bullet.id, bullet.self_id, binfo.kind, user_info.pos, bullet.angle, binfo.multi, info.costGold, info.fishScore)
    self:broadcast(msg)
end

function timestep:on_dead(info)
    local user_info = self._user[info.userid]
    if not user_info then
        skynet_m.log(string.format("Dead can't find user %d.", info.userid))
        return
    end
    local fish_info = self._fish[info.fishid]
    self:delete_fish(fish_info)
    -- NOTICE: no bullet self_id info
    local msg = string.pack(">I2B>I4>I4>I2>I2>I4>I8", s_to_c.dead, user_info.pos, info.bulletid, info.fishid, info.multi, info.bulletMulti, info.winGold, info.fishScore)
    self:broadcast(msg)
end

function timestep:on_set_cannon(info)
    local user_info = self._user[info.userid]
    if not user_info then
        skynet_m.log(string.format("Set cannon can't find user %d.", info.userid))
        return
    end
    local msg = string.pack(">I2>I2", s_to_c.set_cannon, info.cannon)
    self:broadcast(msg)
end

return {__index=timestep}