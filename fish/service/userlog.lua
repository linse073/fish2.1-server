local skynet_m = require "skynet_m"

-- register protocol text before skynet.start would be better.
skynet_m.register_protocol {
	name = "text",
	id = skynet_m.PTYPE_TEXT,
	unpack = skynet_m.tostring,
	dispatch = function(_, address, msg)
		print(string.format(":%08x(%.2f): %s", address, skynet_m.time(), msg))
	end
}

skynet_m.start(function()
end)