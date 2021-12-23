local skynet_m = require "skynet_m"
local sharedata = require "skynet.sharedata"
local sprotoloader = require "sprotoloader"
local util = require "util"

local ipairs = ipairs
local pairs = pairs
local table = table
local assert = assert
local string = string

local function proto_map(pre, sp)
    local all_proto = sp:all_type_name()
    table.sort(all_proto)
    local i2n, n2i = {}, {}
    for k, v in ipairs(all_proto) do
        i2n[k] = v
        assert(not n2i[v], string.format("Protocol %s conflict.", v))
        n2i[v] = k
    end
    sharedata.new(pre .. "_i2n", i2n)
    sharedata.new(pre .. "_n2i", n2i)
end

skynet_m.start(function()
    -- share data
    local fish_data = require("fish_data")
    sharedata.new("fish_data", fish_data)
    local spline_data = require("spline_data")
    sharedata.new("spline_data", spline_data)
    local rule_data = require("rule_data")
    sharedata.new("rule_data", rule_data)
    local map_data = require("map_data")
    sharedata.new("map_data", map_data)
    local boss_data = require("boss_data")
    sharedata.new("boss_data", boss_data)

    proto_map("c2s", sprotoloader.load(1))
    proto_map("s2c", sprotoloader.load(2))

    local prop_type = {
        frozen = 132,
    }
    sharedata.new("prop_type", prop_type)
    local prop_id_map = {}
    for k, v in pairs(prop_type) do
        prop_id_map[v] = k
    end
    sharedata.new("prop_id_map", prop_id_map)

    local error_code, error_code_str = util.create_enum {
        "ok",
        "room_full",
        "room_not_exist",
        "unknown_error",
        "login_conflict",
        "low_activity",
        "reset_agent",
        "disconnect",
        "session_error",
        "wrong_arg",
    }
    sharedata.new("error_code", error_code)
    sharedata.new("error_code_str", error_code_str)

    local fish_type, fish_type_str = util.create_enum {
        "normal",
        "big",
        "special",
        "chest",
        "koi",
        "boss",
    }
    sharedata.new("fish_type", fish_type)
    sharedata.new("fish_type_str", fish_type_str)

    local max_type_fish = {
        [fish_type.normal] = 80,
        [fish_type.big] = 3,
        [fish_type.special] = 1,
        [fish_type.chest] = 2,
        [fish_type.koi] = 2,
        [fish_type.boss] = 1,
    }
    sharedata.new("max_type_fish", max_type_fish)

    local fish_type_cd = {
        [fish_type.normal] = 1,
        [fish_type.big] = 5,
        [fish_type.special] = 5,
        [fish_type.chest] = 5,
        [fish_type.koi] = 5,
        [fish_type.boss] = 10,
    }
    sharedata.new("fish_type_cd", fish_type_cd)
end)
