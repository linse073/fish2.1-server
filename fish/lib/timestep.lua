local skynet_m = require "skynet_m"
local timer = require "timer"
local share = require "share"
local sprotoloader = require "sprotoloader"
local util = require "util"

local string = string
local pairs = pairs
local ipairs = ipairs
local table = table
local math = math
local assert = assert

local game_mode = skynet_m.getenv("game_mode")

local MAX_USER = 4
local ACTIVITY_TIMEOUT = 60 * 100 * 30
local FROZEN_TIME = 15
local MAX_FISH_TYPE_CD = 10
local SWITCH_MAP_DELAY = 2
local PENDING_DEAD_TIME = 2
local COMMON_AOE_DELAY = 10

local error_code
local fish_data
local spline_data
local map_data
local rule_data
local boss_data
local prop_type
local prop_id_map
local s2c_n2i
local fish_type
local max_type_fish
local fish_type_cd
local s2c

local agent_mgr
local game_message
local prop_function

local function immune_aoe(ftype)
    return ftype ~= fish_type.normal
end

local function immune_frozen(ftype)
    return ftype == fish_type.boss
end

skynet_m.init(function()
    agent_mgr = skynet_m.queryservice("agent_mgr")
    if game_mode == "fake_game" then
        game_message = skynet_m.queryservice("fake_message")
    else
        game_message = skynet_m.queryservice("game_message")
    end
    error_code = share.error_code
    fish_data = share.fish_data
    spline_data = share.spline_data
    map_data = share.map_data
    rule_data = share.rule_data
    boss_data = share.boss_data
    prop_type = share.prop_type
    prop_id_map = share.prop_id_map
    s2c_n2i = share.s2c_n2i
    fish_type = share.fish_type
    max_type_fish = share.max_type_fish
    fish_type_cd = share.fish_type_cd
    s2c = sprotoloader.load(2)
    prop_function = {
        [prop_type.frozen] = function(self, info)
            local prop_info = {
                prop_id = info.probid,
                num = info.probCount,
                time = 0,
                user_id = info.userid,
            }
            table.insert(self._prop, prop_info)
            self:broadcast("prop_info", prop_info)
            for k, v in pairs(self._fish) do
                if not immune_frozen(v.data.type) then
                    v.frozen = true
                end
            end
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

function timestep:join_info()
    if not self._mapid then
        local rand_map = {}
        for k, v in pairs(map_data) do
            table.insert(rand_map, k)
        end
        -- self._mapid = rand_map[math.random(#rand_map)]
        self._mapid = 1001
        self._next_mapid = nil
        self._map_info = map_data[self._mapid]
        self._event_index = 1
        self._event = self._map_info[self._event_index]
        self._event_time = 0
        if self._event.stay_time > 0 then
            self._event_phase = 1
            self._accel_count = 0
        else
            self._event_phase = 2
        end
    end
    return {
        mapid = self._mapid,
        eventid = self._event.event_id,
        event_time = self._event_time,
        event_phase = self._event_phase,
    }
end

function timestep:join(user_id, free_pos, agent)
    self:kick(user_id)
    if self._count >= MAX_USER then
        skynet_m.log("Max user.")
        return {code=error_code.room_full}
    end
    free_pos = free_pos + 1
    if free_pos <= 0 or free_pos > MAX_USER then
        skynet_m.log(string.format("Illegal pos %d.", free_pos))
        return {code=error_code.wrong_arg}
    end
    local now = skynet_m.now()
    local info = {
        user_id = user_id,
        agent = agent,
        ready = false,
        pos = free_pos,
        status_time = now,
        bullet = {},
        cannon = 0,
    }
    self._user[user_id] = info
    self._pos[free_pos] = info
    self._count = self._count + 1
    -- NOTICE: game server notify user leave
    -- timer.add_routine("timestep_check", self._check_func, 100)
    return {
        code = error_code.ok,
        info = self:join_info(),
    }
end

function timestep:join_01(user_id, agent)
    self:kick(user_id)
    if self._count >= MAX_USER then
        skynet_m.log("Max user.")
        return {code=error_code.room_full}
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
        return {code=error_code.room_full}
    end
    local now = skynet_m.now()
    local info = {
        user_id = user_id,
        agent = agent,
        ready = false,
        pos = free_pos,
        status_time = now,
        bullet = {},
        cannon = 0,
    }
    self._user[user_id] = info
    self._pos[free_pos] = info
    self._count = self._count + 1
    timer.add_routine("timestep_check", self._check_func, 100)
    return {
        code = error_code.ok,
        info = self:join_info(),
    }
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
    self._fish_id = 1000
    self._group_id = 0
    self._fish = {}
    self._prop = {}
    self._mapid = nil
    self._next_mapid = nil
    self._map_info = nil
    self._event_index = nil
    self._event = nil
    self._event_time = nil
    self._event_phase = nil
    self._delay_time = nil
    self._spline = nil
    self._koi_spline = nil
    self._boss = nil
    self._boss_index = nil
    self._fish_count = {
        [fish_type.normal] = 0,
        [fish_type.big] = 0,
        [fish_type.special] = 0,
        [fish_type.chest] = 0,
        [fish_type.koi] = 0,
        [fish_type.boss] = 0,
    }
    self._fish_type_time = {
        [fish_type.normal] = MAX_FISH_TYPE_CD,
        [fish_type.big] = MAX_FISH_TYPE_CD,
        [fish_type.special] = MAX_FISH_TYPE_CD,
        [fish_type.chest] = MAX_FISH_TYPE_CD,
        [fish_type.koi] = MAX_FISH_TYPE_CD,
        [fish_type.boss] = MAX_FISH_TYPE_CD,
    }
    self._koi_fish = {}
    self._accel_count = 0
    self._trigger_time = 0
    timer.del_all()
end

function timestep:new_fish_id()
    if self._fish_id >= 2147483648 then -- INT32_MAX: 2147483648
        self._fish_id = 1000
    end
    self._fish_id = self._fish_id + 1
    return self._fish_id
end

function timestep:new_bullet_id()
    if self._bullet_id >= 2147483648 then -- INT32_MAX: 2147483648
        self._bullet_id = 0
    end
    self._bullet_id = self._bullet_id + 1
    return self._bullet_id
end

function timestep:new_group_id()
    if self._group_id >= 2147483648 then -- INT32_MAX: 2147483648
        self._group_id = 0
    end
    self._group_id = self._group_id + 1
    return self._group_id
end

function timestep:start()
    self._last_time = skynet_m.now()
    timer.add_routine("timestep_update", self._update_func, 10)
    math.randomseed(self._last_time)
    self:update()
end

function timestep:delete_fish(info)
    self._fish[info.id] = nil
    self._koi_fish[info.id] = nil
    local ftype = info.data.type
    self._fish_count[ftype] = self._fish_count[ftype] - 1
end

local normal_status = function(info)
    if info.frozen then
        return false
    end
    local data = info.data
    if info.proxy_index and info.proxy_index <= #data.fish_proxy and not info.proxy_fish then
        return false
    end
    return true
end

function timestep:catch_fish(info)
    self:delete_fish(info)
    local host_fish = info.host_fish
    if host_fish then
        host_fish.proxy_fish = nil
        host_fish.proxy_id = nil
        info.host_fish = nil
        info.host_id = nil
        if host_fish.proxy_index > #host_fish.data.fish_proxy then
            self:delete_fish(host_fish)
        end
    end
end

function timestep:update()
    local now = skynet_m.now()
    local etime = (now - self._last_time) * 0.01
    self._last_time = now
    if self._delay_time then
        self._delay_time = self._delay_time - etime
        if self._delay_time <= 0 then
            etime = -self._delay_time
            self._delay_time = nil
        else
            return
        end
    end
    local new_fish = {}
    local del_fish = {}
    local new_proxy = {}
    for k, v in pairs(self._fish) do
        if normal_status(v) then
            local ndelta = etime
            if v.accel_time then
                v.accel_time = v.accel_time - etime
                if v.accel_time >= 0 then
                    ndelta = etime * 3
                else
                    ndelta = (etime + v.accel_time) * 3 - v.accel_time
                    v.accel_time = nil
                end
            end
            v.time = v.time + ndelta
        end
        if v.time >= v.life_time then
            if not v.proxy_id then
                table.insert(del_fish, {
                    id = k,
                    fish_id = v.fish_id,
                })
            end
            self:delete_fish(v)
        else
            local fish_proxy = v.data.fish_proxy
            if v.proxy_index and v.proxy_index <= #fish_proxy and not v.proxy_fish then
                v.proxy_time = v.proxy_time + etime
                if v.proxy_time >= fish_proxy[v.proxy_index].time then
                    table.insert(new_proxy, v)
                end
            end
        end
    end
    for k, v in ipairs(new_proxy) do
        local fish_id = v.data.fish_proxy[v.proxy_index].fish_id
        v.proxy_index = v.proxy_index + 1
        v.proxy_time = 0
        local proxy_fish = self:new_proxy_fish(fish_id, new_fish, v.life_time - v.time, v)
        v.proxy_fish = proxy_fish
        v.proxy_id = proxy_fish.id
    end
    local stop_time = false
    local prop = self._prop
    local frozen, frozen_timeout = false, false
    for i = #prop, 1, -1 do
        local v = prop[i]
        v.time = v.time + etime
        if v.prop_id == prop_type.frozen then
            stop_time = true
            if v.time >= FROZEN_TIME then
                table.remove(prop, i)
                frozen_timeout = true
            else
                frozen = true
            end
        end
    end
    if frozen_timeout and not frozen then
        for k, v in pairs(self._fish) do
            v.frozen = nil
        end
    end
    if not stop_time then
        self._event_time = self._event_time + etime
    end
    if self._trigger_time > 0 then
        self._trigger_time = self._trigger_time - etime
    end
    for k, v in pairs(self._user) do
        if v.trigger_time then
            v.trigger_time = v.trigger_time - etime
            if v.trigger_time <= 0 then
                v.trigger_time = nil
                skynet_m.send_lua(game_message, "send_skill_timeout", {
                    tableid = self._room_id,
                    seatid = v.pos - 1,
                    userid = v.user_id,
                })
            end
        end
    end
    local old_event = self._event
    if self._event_phase == 1 then
        if self._event_time >= old_event.stay_time and self._trigger_time <= 0 and not stop_time then
            self:clear_fish(del_fish)
            self._event_phase = 2
            self._event_time = 0
            if self._event_index == #self._map_info then
                local rand_map = {}
                for k, v in pairs(map_data) do
                    if k ~= self._mapid then
                        table.insert(rand_map, k)
                    end
                end
                self._next_mapid = rand_map[math.random(#rand_map)]
            end
            self:broadcast("event_info", {
                eventid = old_event.event_id,
                event_time = self._event_time,
                event_phase = self._event_phase,
                next_mapid = self._next_mapid,
                delay_time = self._delay_time,
            })
        else
            self:new_fish(etime, new_fish)
            self:new_koi_fish(etime, new_fish, del_fish)
        end
    elseif self._event_phase == 2 then
        if self._event_time >= old_event.switch_time then
            if self._event_index < #self._map_info then
                self._event_index = self._event_index + 1
                local new_event = self._map_info[self._event_index]
                self._event = new_event
                self._event_time = 0
                if new_event.stay_time > 0 then
                    self._event_phase = 1
                    self._accel_count = 0
                else
                    self._event_phase = 2
                end
                if self._event_phase == 2 and self._event_index == #self._map_info then
                    local rand_map = {}
                    for k, v in pairs(map_data) do
                        if k ~= self._mapid then
                            table.insert(rand_map, k)
                        end
                    end
                    self._next_mapid = rand_map[math.random(#rand_map)]
                end
                self:fish_rule()
                self:broadcast("event_info", {
                    eventid = new_event.event_id,
                    event_time = self._event_time,
                    event_phase = self._event_phase,
                    next_mapid = self._next_mapid,
                })
            else
                self._delay_time = SWITCH_MAP_DELAY

                self._mapid = self._next_mapid
                self._next_mapid = nil
                self._map_info = map_data[self._mapid]
                self._event_index = 1
                local new_event = self._map_info[self._event_index]
                self._event = new_event
                self._event_time = 0
                if self._event.stay_time > 0 then
                    self._event_phase = 1
                    self._accel_count = 0
                else
                    self._event_phase = 2
                end
                self:fish_rule()
                self:broadcast("event_info", {
                    mapid = self._mapid,
                    eventid = new_event.event_id,
                    event_time = self._event_time,
                    event_phase = self._event_phase,
                    delay_time = self._delay_time,
                })
            end
        end
    end
    local del_count = #del_fish
    if del_count > 0 then
        if del_count > 100 then
            skynet_m.log("Kill fish exceed max count.")
        end
        local kill_msg = ""
        for k, v in ipairs(del_fish) do
            kill_msg = kill_msg .. string.pack("<I4", v.id)
        end
        for i = del_count + 1, 100 do
            kill_msg = kill_msg .. string.pack("<I4", 0)
        end
        skynet_m.send_lua(game_message, "send_kill_fish", {
            tableid = self._room_id,
            fish = kill_msg,
        })
        self:broadcast("del_fish", {
            fish = del_fish,
        })
    end
    local new_num = #new_fish
    if new_num > 0 then
        if new_num > 100 then
            skynet_m.log("New fish exceed max count.")
        end
        local new_msg = ""
        for k, v in ipairs(new_fish) do
            -- NOTICE: define fish type with game server
            new_msg = new_msg .. string.pack("<I4<I2<I2", v.id, v.data.kind,
                                                math.ceil(v.life_time - v.time + 10))
        end
        for i = new_num + 1, 100 do
            new_msg = new_msg .. string.pack("<I4<I2<I2", 0, 0, 0)
        end
        skynet_m.send_lua(game_message, "send_build_fish", {
            tableid = self._room_id,
            fish = new_msg,
        })
        self:broadcast("new_fish", {
            fish = new_fish,
        })
    end
end

function timestep:clear_fish(del_fish)
    for k, v in pairs(self._fish) do
        if not v.proxy_id then
            table.insert(del_fish, {
                id = k,
                fish_id = v.fish_id,
            })
        end
        self:delete_fish(v)
    end
    self._delay_time = PENDING_DEAD_TIME
end

function timestep:mode_spline(ftype)
    if ftype == fish_type.Chest then
        local mode = self._mode
        if not mode or mode.rpt_mode then
            return false
        end
    end
    return true
end

function timestep:fish_rule()
    local spline = {}
    for k, v in ipairs(self._event.spline) do
        local spline_info = assert(spline_data[v], string.format("No spline[%d].", v))
        local time_rule = {}
        local normal_rule = {}
        local ftype = fish_type.normal
        for k1, v1 in ipairs(spline_info.rule) do
            local rule_info = assert(rule_data[v1], string.format("No rule[%d].", v1))
            for k2, v2 in ipairs(rule_info) do
                local fdata = assert(fish_data[v2.fish], string.format("No fish[%d].", v2.fish))
                if v2.time > 0 then
                    table.insert(time_rule, v2)
                else
                    table.insert(normal_rule, v2)
                end
                if fdata.type > ftype then
                    ftype = fdata.type
                end
            end
        end
        if self:mode_spline(ftype) then
            table.sort(time_rule, function(a, b)
                return a.time < b.time
            end)
            local type_spline = spline[ftype]
            if not type_spline then
                type_spline = {}
                spline[ftype] = type_spline
            end
            table.insert(type_spline, {
                spline_id = v,
                length = spline_info.length,
                time_rule = time_rule,
                normal_rule = normal_rule,
                cd = 10,
                time = 10,
                rule_index = 1,
                accel_time = spline_info.accel_time,
            })
        end
    end
    self._spline = spline
    self._koi_spline = spline[fish_type.koi]
    spline[fish_type.koi] = nil
    local boss = {}
    for k, v in ipairs(self._event.boss) do
        local boss_info = assert(boss_data[v], string.format("No boss[%d].", v))
        table.insert(boss, boss_info)
    end
    self._boss = boss
    self._boss_index = 1
end

function timestep:new_rule_fish(spline_info, rule_info, new_fish)
    local fish_id = rule_info.fish
    local data = assert(fish_data[fish_id], string.format("No fish[%d].", fish_id))
    local gid = self:new_group_id()
    local spline_id = spline_info.spline_id
    local life_time = rule_info.life_time
    if life_time <= 0 then
        assert(rule_info.speed > 0, string.format("Invalid rule fish[%d] speed.", fish_id))
        life_time = spline_info.length / rule_info.speed + 3
    end
    for i = 1, rule_info.count do
        local fid = self:new_fish_id()
        local f_id = fish_id
        local f_data = data
        local sfish_id = rule_info.special_rule[i]
        if sfish_id then
            f_id = sfish_id
            f_data = assert(fish_data[f_id], string.format("No fish[%d].", f_id))
        end
        local new_info = {
            id = fid,
            rule_id = rule_info.id,
            rule_index = rule_info.index,
            fish_id = f_id,
            spline_id = spline_id,
            group_id = gid,
            life_time = life_time,
            time = 0,
            data = f_data,
            group_index = i,
            rule_info = rule_info,
        }
        if self._accel_count < 50 then
            new_info.accel_time = spline_info.accel_time
        end
        if #f_data.fish_proxy > 0 then
            new_info.proxy_index = 1
            new_info.proxy_time = 0
        end
        table.insert(new_fish, new_info)
        self._fish[fid] = new_info
        local ftype = f_data.type
        if ftype == fish_type.koi then
            self._koi_fish[fid] = new_info
        end
        self._fish_count[ftype] = self._fish_count[ftype] + 1
    end
end

function timestep:new_proxy_fish(fish_id, new_fish, life_time, host_fish)
    local data = assert(fish_data[fish_id], string.format("No fish[%d].", fish_id))
    local fid = self:new_fish_id()
    local new_info = {
        id = fid,
        fish_id = fish_id,
        life_time = life_time,
        time = 0,
        data = data,
        host_fish = host_fish,
        host_id = host_fish.id,
        accel_time = host_fish.accel_time,
    }
    if #data.fish_proxy > 0 then
        new_info.proxy_index = 1
        new_info.proxy_time = 0
    end
    table.insert(new_fish, new_info)
    self._fish[fid] = new_info
    local ftype = data.type
    self._fish_count[ftype] = self._fish_count[ftype] + 1
    return new_info
end

function timestep:new_boss_fish(boss_info, new_fish)
    local fish_id = boss_info.fish_id
    local data = assert(fish_data[fish_id], string.format("No fish[%d].", fish_id))
    local fid = self:new_fish_id()
    local new_info = {
        id = fid,
        fish_id = fish_id,
        life_time = boss_info.life_time,
        time = 0,
        data = data,
        boss_id = boss_info.id,
        boss_info = boss_info,
    }
    if #data.fish_proxy > 0 then
        new_info.proxy_index = 1
        new_info.proxy_time = 0
    end
    table.insert(new_fish, new_info)
    self._fish[fid] = new_info
    local ftype = data.type
    self._fish_count[ftype] = self._fish_count[ftype] + 1
    return new_info
end

function timestep:new_fish(delta, new_fish)
    local fish_type_time = self._fish_type_time
    for k1, v1 in pairs(self._spline) do
        fish_type_time[k1] = fish_type_time[k1] + delta
        if fish_type_time[k1] >= fish_type_cd[k1] then
            local rand_spline = {}
            for k, v in ipairs(v1) do
                v.time = v.time + delta
                if self:new_time_fish(v, new_fish) then
                    fish_type_time[k1] = 0
                    v.time = 0
                elseif v.time >= v.cd then
                    if #v.normal_rule > 0 then
                        table.insert(rand_spline, v)
                    end
                end
            end
            if self._fish_count[k1] < max_type_fish[k1] then
                local count = 1
                if #rand_spline < count then
                    count = #rand_spline
                end
                for i = 1, count do
                    local index = math.random(#rand_spline)
                    local spline_info = rand_spline[index]
                    table.remove(rand_spline, index)

                    local rand_rule = spline_info.normal_rule[math.random(#spline_info.normal_rule)]
                    self:new_rule_fish(spline_info, rand_rule, new_fish)
                    self._accel_count = self._accel_count + rand_rule.count
                    spline_info.time = 0
                    fish_type_time[k1] = 0
                    if self._fish_count[k1] >= max_type_fish[k1] then
                        break
                    end
                end
            end
        end
    end
    if self._boss_index <= #self._boss then
        local boss_info = self._boss[self._boss_index]
        if boss_info.time >= self._event_time then
            self:new_boss_fish(boss_info, new_fish)
            self._boss_index = self._boss_index + 1
        end
    end
end

function timestep:new_koi_fish(delta, new_fish, del_fish)
    local mode = self._mode
    if not mode then
        return
    end
    if mode.koi_create then
        mode.koi_life = mode.koi_life - delta
        if mode.koi_life > 0 then
            if util.empty(self._koi_fish) and self._koi_spline then
                local koi_spline = util.copy(self._koi_spline)
                local len = #koi_spline
                if len > 2 then
                    len = 2
                end
                for i = 1, len do
                    local index = math.random(#koi_spline)
                    local spline_info = koi_spline[index]
                    table.remove(koi_spline, index)

                    local rand_rule = spline_info.normal_rule[math.random(#spline_info.normal_rule)]
                    self:new_rule_fish(spline_info, rand_rule, new_fish)
                end
            end
        else
            mode.koi_create = false
            mode.koi_wait = mode.koi_wait + mode.koi_life
            mode.koi_life = 0
            for k, v in pairs(self._koi_fish) do
                self:delete_fish(v)
                table.insert(del_fish, {
                    id = k,
                    fish_id = v.fish_id,
                })
            end
        end
    else
        if mode.koi_wait > 0 then
            mode.koi_wait = mode.koi_wait - delta
            if mode.koi_wait < 0 then
                mode.koi_wait = 0
            end
        end
    end
end

function timestep:new_time_fish(spline_info, new_fish)
    if spline_info.rule_index <= #spline_info.time_rule then
        local rule_info = spline_info.time_rule[spline_info.rule_index]
        if rule_info.time >= self._event_time then
            self:new_rule_fish(spline_info, rule_info, new_fish)
            return true
        elseif self._event_time - rule_info.time <= 2 then
            return true
        end
    end
end

function timestep:kick(user_id, agent)
    local info = self._user[user_id]
    if info and (not agent or info.agent == agent) then
        for k, v in ipairs(info.bullet) do
            self._bullet[v.id] = nil
        end
        self._user[user_id] = nil
        self._pos[info.pos] = nil
        self._count = self._count - 1
        if info.ready then
            self._ready_count = self._ready_count - 1
            self:broadcast("leave_room", {
                user_id = user_id,
            })
        end
        if info.trigger_time then
            skynet_m.send_lua(game_message, "send_skill_timeout", {
                tableid = self._room_id,
                seatid = info.pos - 1,
                userid = info.user_id,
            })
        end
        if self._count == 0 then
            self:clear()
            skynet_m.log(string.format("send clear table %d msg to game server.", self._room_id))
            skynet_m.send_lua(game_message, "send_clear", {
                tableid = self._room_id,
                flag = 0,
            })
            if game_mode == "fake_game" then
                self._mode = nil
            end
        end
    end
end

function timestep:process(user_id, msg_name, content)
    local info = self._user[user_id]
    if not info then
        skynet_m.log(string.format("Can't find user %d, but receive msg %s.", user_id, msg_name))
        return
    end
    local func = self["client_" .. msg_name]
    if func then
        func(self, info, content)
        info.status_time = skynet_m.now()
    else
        skynet_m.log(string.format("Receive illegal message %s from user %d.", msg_name, user_id))
    end
end

local function pack_msg(msg, info)
    local id = assert(s2c_n2i[msg], string.format("No s2c message %s.", msg))
    if s2c:exist_type(msg) then
        info = s2c:pencode(msg, info)
    end
    return string.pack(">I2", id) .. info
end

function timestep:broadcast(msg, info)
    local content = pack_msg(msg, info)
    for _, v in pairs(self._user) do
        if v.ready then
            skynet_m.send_lua(v.agent, "send_pack", content)
        end
    end
end

function timestep:broadcast_exclude(msg, info, id)
    local content = pack_msg(msg, info)
    for _, v in pairs(self._user) do
        if v.ready and v.user_id ~= id then
            skynet_m.send_lua(v.agent, "send_pack", content)
        end
    end
end

function timestep:client_ready(info, data)
    skynet_m.log(string.format("User %d ready.", info.user_id))
    if info.ready then
        skynet_m.log(string.format("User %d is ready.", info.user_id))
    else
        local cannon = data.cannon
        info.cannon = cannon
        self:broadcast("user_info", {
            user_id = info.user_id,
            pos = info.pos,
            cannon = info.cannon,
        })
        self._ready_count = self._ready_count + 1
        if self._ready_count == 1 then
            self:start()
        end
        info.ready = true
        local user_info = {}
        for _, v in pairs(self._user) do
            if v.ready then
                table.insert(user_info, {
                    user_id = v.user_id,
                    pos = v.pos,
                    cannon = v.cannon,
                })
            end
        end
        local fish_info = {}
        for k, v in pairs(self._fish) do
            table.insert(fish_info, {
                id = v.id,
                rule_id = v.rule_id,
                rule_index = v.rule_index,
                fish_id = v.fish_id,
                spline_id = v.spline_id,
                group_id = v.group_id,
                time = v.time,
                group_index = v.group_index,
                boss_id = v.boss_id,
                host_id = v.host_id,
                proxy_index = v.proxy_index,
                frozen = v.frozen,
                life_time = v.life_time,
                accel_time = v.accel_time,
            })
        end
        local prop_info = {}
        for k, v in ipairs(self._prop) do
            table.insert(prop_info, {
                prop_id = v.prop_id,
                num = v.num,
                user_id = v.user_id,
                time = v.time,
            })
        end
        skynet_m.send_lua(info.agent, "send", "room_data", {
            user = user_info,
            pos = info.pos,
            fish = fish_info,
            prop = prop_info,
            event = {
                mapid = self._mapid,
                eventid = self._event.event_id,
                event_time = self._event_time,
                event_phase = self._event_phase,
                delay_time = self._delay_time,
            },
            mode = self._mode,
        })
        skynet_m.log(string.format("Response user %d ready.", info.user_id))
    end
end

function timestep:client_quit(info, data)
    skynet_m.send_lua(agent_mgr, "quit", info.user_id, error_code.ok)
end

function timestep:client_fire(info, data)
    -- my_id, angle, multi, kind, rotate, target
    for k, v in ipairs(data.info) do
        local kind = v.kind
        if info.cannon ~= kind then
            info.cannon = kind
        end
        local bullet_id = self:new_bullet_id()
        v.id = bullet_id
        skynet_m.send_lua(game_message, "send_fire", {
            tableid = self._room_id,
            seatid = info.pos - 1,
            userid = info.user_id,
            bullet = {
                id = bullet_id,
                kind = kind,
                multi = v.multi,
                power = 1,
                expTime = 0,
            },
        })
        info.bullet[v.my_id] = v
        self._bullet[bullet_id] = v
    end
end

function timestep:client_hit(info, data)
    for k, v in ipairs(data.info) do
        local my_id, fishid, multi = v.my_id, v.fishid, v.multi
        local bullet = info.bullet[my_id]
        if not bullet then
            skynet_m.log(string.format("Can't find bullet %d when user %d hit fish %d.",
                                        my_id, info.user_id, fishid))
            return
        end
        info.bullet[my_id] = nil
        skynet_m.send_lua(game_message, "send_catch_fish", {
            tableid = self._room_id,
            seatid = info.pos - 1,
            userid = info.user_id,
            bulletid = bullet.id,
            fishid = fishid,
            bulletMulti = multi,
            fish = self._fish[fishid]~=nil,
        })
    end
end

function timestep:client_hit_bomb(info, data)
    local my_id, fishid, multi = data.my_id, data.fishid, data.multi
    local bullet = info.bullet[my_id]
    if not bullet then
        skynet_m.log(string.format("Can't find bullet %d when user %d hit bomb fish %d.",
                                    my_id, info.user_id, fishid))
        return
    end
    info.bullet[my_id] = nil
    local other = data.other
    local num = #other
    if num > 99 then
        num = 99
    end
    local msg = string.pack("<I4", fishid)
    local count = 1
    for i = 1, num do
        local fish_id = other[i]
        msg = msg .. string.pack("<I4", fish_id)
        count = count + 1
    end
    for i = count + 1, 100 do
        msg = msg .. string.pack("<I4", 0)
    end
    skynet_m.send_lua(game_message, "send_bomb_fish", {
        tableid = self._room_id,
        seatid = info.pos - 1,
        userid = info.user_id,
        bulletid = bullet.id,
        bulletMulti = multi,
        fish = msg,
        bomb_fish = self._fish[fishid]~=nil,
    })
end

function timestep:client_hit_trigger(info, data)
    local my_id, fishid, multi = data.my_id, data.fishid, data.multi
    local bullet = info.bullet[my_id]
    if not bullet then
        skynet_m.log(string.format("Can't find bullet %d when user %d hit trigger fish %d.",
                                    my_id, info.user_id, fishid))
        return
    end
    info.bullet[my_id] = nil
    local other = data.other
    local num = #other
    if num > 99 then
        num = 99
    end
    local msg = string.pack("<I4", fishid)
    local count = 1
    for i = 1, num do
        local fish_id = other[i]
        msg = msg .. string.pack("<I4", fish_id)
        count = count + 1
    end
    for i = count + 1, 100 do
        msg = msg .. string.pack("<I4", 0)
    end
    skynet_m.send_lua(game_message, "send_trigger_fish", {
        tableid = self._room_id,
        seatid = info.pos - 1,
        userid = info.user_id,
        bulletid = bullet.id,
        bulletMulti = multi,
        fish = msg,
        trigger_fish = self._fish[fishid]~=nil,
    })
end

function timestep:client_skill_damage(info, data)
    local other = data.other
    local num = #other
    if num > 100 then
        num = 100
    end
    local msg = ""
    local count = 0
    for i = 1, num do
        local fish_id = other[i]
        msg = msg .. string.pack("<I4", fish_id)
        count = count + 1
    end
    for i = count + 1, 100 do
        msg = msg .. string.pack("<I4", 0)
    end
    skynet_m.send_lua(game_message, "send_skill_damage", {
        tableid = self._room_id,
        seatid = info.pos - 1,
        userid = info.user_id,
        fish = msg,
    })
end

function timestep:client_heart_beat(info, data)
end

function timestep:client_use_prop(info, data)
    local prop_id, prop_num = data.prop_id, data.prop_num
    if not prop_id_map[prop_id] then
        skynet_m.log(string.format("Can't find prop %d when user %d use prop.",
                                    prop_id, info.user_id))
        return
    end
    skynet_m.send_lua(game_message, "send_use_prob", {
        tableid = self._room_id,
        seatid = info.pos - 1,
        userid = info.user_id,
        probid = prop_id,
        probCount = prop_num,
    })
end

function timestep:client_set_cannon(info, data)
    local cannon = data.cannon
    info.cannon = cannon
    self:broadcast("set_cannon", {
        pos = info.pos,
        cannon = cannon,
    })
end

function timestep:client_mode_info(info, data)
    self._info = {
        tableid = self._room_id,
        rpt_mode = false,
    }
    self:on_koi_info(data)
end

function timestep:client_open_chest(info, data)
    self:broadcast_exclude("open_chest", {
        pos = info.pos,
    }, info.user_id)
end

function timestep:on_fire(info)
    local binfo = info.bullet
    local bullet = self._bullet[binfo.id]
    if not bullet then
        skynet_m.log(string.format("Fire can't find bullet %d.", binfo.id))
        return
    end
    if binfo.kind ~= bullet.kind or binfo.multi ~= bullet.multi then
        skynet_m.log(string.format("Fire info is different."))
    end
    self._bullet[binfo.id] = nil
    if info.code ~= 0 then
        skynet_m.log(string.format("User %d fire bullet %d fail.", info.userid, binfo.id))
        return
    end
    local user_info = self._user[info.userid]
    if not user_info then
        skynet_m.log(string.format("Fire can't find user %d.", info.userid))
        return
    end
    info.cannon = binfo.kind
    bullet.multi = binfo.multi
    self:broadcast("fire", {
        pos = user_info.pos,
        bullet = bullet,
        cost_gold = info.costGold,
        fish_score = info.fishScore,
        award_pool = info.awardPool,
    })
end

function timestep:on_dead(info)
    local user_info = self._user[info.userid]
    if not user_info then
        skynet_m.log(string.format("Dead can't find user %d.", info.userid))
        return
    end
    -- NOTICE: no bullet my_id info
    local msg = {
        pos = user_info.pos,
        fishid = info.fishid,
        fish_id = 0,
        multi = info.multi,
        bullet = {
            id = info.bulletid,
            multi = info.bulletMulti,
        },
        win_gold = info.winGold,
        fish_score = info.fishScore,
        award_pool = info.awardPool,
        rpt = info.rpt,
    }
    local fish_info = self._fish[info.fishid]
    if fish_info then
        self:catch_fish(fish_info)
        msg.fish_id = fish_info.fish_id
    end
    self:broadcast("catch_fish", msg)
end

function timestep:on_set_cannon(info)
    local user_info = self._user[info.userid]
    if not user_info then
        skynet_m.log(string.format("Set cannon can't find user %d.", info.userid))
        return
    end
    user_info.cannon = info.cannon
    self:broadcast("set_cannon", {
        pos = user_info.pos,
        cannon = info.cannon,
    })
end

function timestep:on_use_prop(info)
    local user_info = self._user[info.userid]
    if not user_info then
        skynet_m.log(string.format("Use prop can't find user %d.", info.userid))
        return
    end
    local func = prop_function[info.probid]
    if func then
        func(self, info)
    else
        skynet_m.log(string.format("Use prop can't find prop data %d.", info.probid))
        return
    end
end

function timestep:on_bomb_fish(info)
    local user_info = self._user[info.userid]
    if not user_info then
        skynet_m.log(string.format("Bomb fish can't find user %d.", info.userid))
        return
    end
    local score = {}
    for k, v in ipairs(info.fish) do
        local sinfo = {
            id = v.fishid,
            fish_id = 0,
            score = v.score,
        }
        local fish_info = self._fish[v.fishid]
        if fish_info then
            self:catch_fish(fish_info)
            sinfo.fish_id = fish_info.fish_id
        end
        table.insert(score, sinfo)
    end
    self:broadcast("bomb_fish", {
        pos = user_info.pos,
        bullet = {
            id = info.bulletid,
            multi = info.bulletMulti,
        },
        win_gold = info.winGold,
        fish_score = info.fishScore,
        score = score,
    })
end

function timestep:on_init_info(info)
    self._mode = info
end

function timestep:on_koi_info(info)
    local mode = self._mode
    mode.koi_type, mode.koi_life, mode.koi_wait, mode.koi_create
        = info.koi_type, info.koi_life, info.koi_wait, info.koi_create
    self:broadcast("mode_info", mode)
end

function timestep:on_king_dead(info)
    local user_info = self._user[info.userid]
    if not user_info then
        skynet_m.log(string.format("King dead can't find user %d.", info.userid))
        return
    end
    -- NOTICE: no bullet my_id info
    local msg = {
        pos = user_info.pos,
        fishid = info.fishid,
        fish_id = 0,
        multi = info.multi,
        bullet = {
            id = info.bulletid,
            multi = info.bulletMulti,
        },
        win_gold = info.winGold,
        fish_score = info.fishScore,
        award_pool = info.awardPool,
        rpt = info.rpt,
        rpt_ratio = info.rpt_ratio,
        fish_multi = info.fishMultis,
    }
    local fish_info = self._fish[info.fishid]
    if fish_info then
        self:catch_fish(fish_info)
        msg.fish_id = fish_info.fish_id
    end
    self:broadcast("catch_fish", msg)
end

function timestep:on_trigger_dead(info)
    local user_info = self._user[info.userid]
    if not user_info then
        skynet_m.log(string.format("Trigger dead can't find user %d.", info.userid))
        return
    end
    -- NOTICE: no bullet my_id info
    local msg = {
        pos = user_info.pos,
        fishid = info.fishid,
        fish_id = 0,
        bullet = {
            id = info.bulletid,
            multi = info.bulletMulti,
        },
    }
    local trigger_time = COMMON_AOE_DELAY
    local fish_info = self._fish[info.fishid]
    if fish_info then
        self:catch_fish(fish_info)
        msg.fish_id = fish_info.fish_id
        trigger_time = fish_info.data.aoe_delay + 3
    end
    self:broadcast("catch_trigger", msg)
    user_info.trigger_time = trigger_time
    if trigger_time > self._trigger_time then
        self._trigger_time = trigger_time
    end
    if self._event_phase == 1 and self._event_time + self._trigger_time >= self._event.stay_time then
        self._spline[fish_type.special] = nil
    end
end

function timestep:on_skill_damage(info)
    local user_info = self._user[info.userid]
    if not user_info then
        skynet_m.log(string.format("Skill damage can't find user %d.", info.userid))
        return
    end
    local score = {}
    for k, v in ipairs(info.fish) do
        local sinfo = {
            id = v.fishid,
            fish_id = 0,
            score = v.score,
        }
        local fish_info = self._fish[v.fishid]
        if fish_info then
            self:catch_fish(fish_info)
            sinfo.fish_id = fish_info.fish_id
        end
        table.insert(score, sinfo)
    end
    self:broadcast("skill_damage", {
        pos = user_info.pos,
        win_gold = info.winGold,
        fish_score = info.fishScore,
        score = score,
    })
    user_info.trigger_time = nil
    if self._trigger_time < 5 then
        self._trigger_time = 5
    end
end

return {__index=timestep}