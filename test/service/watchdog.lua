local skynet_m = require "skynet_m"

local CMD = {}
local SOCKET = {}
local gate
local agent = {}

function SOCKET.open(fd, addr)
	skynet_m.error("New client from : " .. addr)
	agent[fd] = skynet_m.newservice("agent")
	skynet_m.call(agent[fd], "lua", "start", { gate = gate, client = fd, watchdog = skynet_m.self() })
end

local function close_agent(fd)
	local a = agent[fd]
	agent[fd] = nil
	if a then
		skynet_m.call(gate, "lua", "kick", fd)
		-- disconnect never return
		skynet_m.send(a, "lua", "disconnect")
	end
end

function SOCKET.close(fd)
	print("socket close",fd)
	close_agent(fd)
end

function SOCKET.error(fd, msg)
	print("socket error",fd, msg)
	close_agent(fd)
end

function SOCKET.warning(fd, size)
	-- size K bytes havn't send out in fd
	print("socket warning", fd, size)
end

function SOCKET.data(fd, msg)
end

function CMD.start(conf)
	skynet_m.call(gate, "lua", "open" , conf)
end

function CMD.close(fd)
	close_agent(fd)
end

skynet_m.start(function()
	skynet_m.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			skynet_m.ret(skynet_m.pack(f(subcmd, ...)))
		end
	end)

	gate = skynet_m.newservice("gate")
end)
