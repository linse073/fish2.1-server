local skynet_m = require "skynet_m"
local sharedata = require "skynet.sharedata"

local share = {}

skynet_m.init(function()
    -- share with all agent
    share.fish_data = sharedata.query("fish_data")
    share.spline_data = sharedata.query("spline_data")
    share.rule_data = sharedata.query("rule_data")
    share.map_data = sharedata.query("map_data")

    share.c2s_i2n = sharedata.query("c2s_i2n")
    share.c2s_n2i = sharedata.query("c2s_n2i")
    share.s2c_i2n = sharedata.query("s2c_i2n")
    share.s2c_n2i = sharedata.query("s2c_n2i")

    share.error_code = sharedata.query("error_code")
end)

return share
