local skynet_m = require "skynet_m"
local sprotoparser = require "sprotoparser"
local sprotoloader = require "sprotoloader"
local proto = require "proto"

skynet_m.start(function()
	sprotoloader.save(proto.c2s, 1)
	sprotoloader.save(proto.s2c, 2)
	-- don't call skynet_m.exit() , because sproto.core may unload and the global slot become invalid
end)
