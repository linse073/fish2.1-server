local skynet_m = require "skynet_m"

local max_client = 64

skynet_m.start(function()
	skynet_m.error("Server start")

	if not skynet_m.getenv "daemon" then
		local console = skynet_m.newservice("console")
	end
	skynet_m.newservice("debug_console", 8000)
	local watchdog = skynet_m.newservice("watchdog")
	skynet_m.call(watchdog, "lua", "start", {
		port = 9002,
		maxclient = max_client,
		nodelay = true,
	})
	skynet_m.error("Watchdog listen on", 9002)

	skynet_m.error("Server start finish")
	skynet_m.exit()
end)
