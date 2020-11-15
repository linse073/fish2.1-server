local skynet_m = require "skynet_m"
-- local socket = require "skynet_m.socket"
-- local sproto = require "sproto"
-- local sprotoloader = require "sprotoloader"
local recv_msg = require "recv_msg"

local WATCHDOG
-- local host
-- local send_request

local CMD = {}
local REQUEST = {}
local client_fd

-- function REQUEST:get()
-- 	print("get", self.what)
-- 	local r = skynet_m.call("SIMPLEDB", "lua", "get", self.what)
-- 	return { result = r }
-- end

-- function REQUEST:set()
-- 	print("set", self.what, self.value)
-- 	local r = skynet_m.call("SIMPLEDB", "lua", "set", self.what, self.value)
-- end

-- function REQUEST:handshake()
-- 	return { msg = "Welcome to skynet_m, I will send heartbeat every 5 sec." }
-- end

-- function REQUEST:quit()
-- 	skynet_m.call(WATCHDOG, "lua", "close", client_fd)
-- end

-- local function request(name, args, response)
-- 	local f = assert(REQUEST[name])
-- 	local r = f(args)
-- 	if response then
-- 		return response(r)
-- 	end
-- end

-- local function send_package(pack)
-- 	local package = string.pack(">s2", pack)
-- 	socket.write(client_fd, package)
-- end

skynet_m.register_protocol {
	name = "client",
	id = skynet_m.PTYPE_CLIENT,
	unpack = skynet_m.tostring,
	-- unpack = function (msg, sz)
	-- 	return host:dispatch(msg, sz)
	-- end,
	-- dispatch = function (fd, _, type, ...)
	-- 	assert(fd == client_fd)	-- You can use fd to reply message
	-- 	skynet_m.ignoreret()	-- session is fd, don't call skynet_m.ret
	-- 	skynet_m.trace()
	-- 	skynet_m.log(_, type, ...)
	-- 	-- if type == "REQUEST" then
	-- 	-- 	local ok, result  = pcall(request, ...)
	-- 	-- 	if ok then
	-- 	-- 		if result then
	-- 	-- 			send_package(result)
	-- 	-- 		end
	-- 	-- 	else
	-- 	-- 		skynet_m.error(result)
	-- 	-- 	end
	-- 	-- else
	-- 	-- 	assert(type == "RESPONSE")
	-- 	-- 	error "This example doesn't support request client"
	-- 	-- end
	-- end
}

function CMD.start(conf)
	local fd = conf.client
	local gate = conf.gate
	WATCHDOG = conf.watchdog
	-- -- slot 1,2 set at main.lua
	-- host = sprotoloader.load(1):host "package"
	-- send_request = host:attach(sprotoloader.load(2))
	-- skynet_m.fork(function()
	-- 	while true do
	-- 		send_package(send_request "heartbeat")
	-- 		skynet_m.sleep(500)
	-- 	end
	-- end)

	client_fd = fd
	skynet_m.call(gate, "lua", "forward", fd)
end

function CMD.disconnect()
	-- todo: do something before exit
	skynet_m.exit()
end

skynet_m.start(function()
	skynet_m.dispatch("lua", function(_,_, command, ...)
		skynet_m.trace()
		local f = CMD[command]
		skynet_m.ret(skynet_m.pack(f(...)))
	end)

	skynet_m.dispatch("client", function(_,_, msg)
		recv_msg.recv_msg(msg)
		-- skynet_m.ret("")
	end)
end)
