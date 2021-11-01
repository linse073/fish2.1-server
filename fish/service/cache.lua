local skynet_m = require "skynet_m"
local sharedata = require "skynet.sharedata"
local sprotoloader = require "sprotoloader"

local ipairs = ipairs

local function proto_map(pre, sp)
    local all_proto = sp:allproto()
    local i2n, n2i = {}, {}
    for k, v in ipairs(all_proto) do
        i2n[k] = v
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

    proto_map("c2s", sprotoloader.load(1))
    proto_map("s2c", sprotoloader.load(2))

    local error_code = require("error_code")
    sharedata.new("error_code", error_code)
end)
