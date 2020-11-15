local skynet_m = require "skynet_m"

local assert = assert
local io = io
local load = load

skynet_m.start(function()
    local f = assert(io.open("./test/lib/send_msg.lua", "r"))
    local d = f:read("*a")
    f:close()
    load(d)()()

    skynet_m.exit()
end)