local skynet_m = require "skynet_m"
local share = require "share"

local assert = assert
local string = string

local agent_mgr
local error_code

local CMD = {}
local SOCKET = {}
local gate
local agent = {}

function SOCKET.open(fd, addr)
	skynet_m.log("New client from : " .. addr)
	local new_agent = skynet_m.call_lua(agent_mgr, "new", gate, fd)
	agent[fd] = new_agent
	skynet_m.call_lua(new_agent, "start", {
		gate = gate,
		client = fd,
		watchdog = skynet_m.self(),
	})
end

local function close_agent(fd)
	local a = agent[fd]
	agent[fd] = nil
	if a then
		skynet_m.call_lua(gate, "kick", fd)
		-- disconnect never return
		skynet_m.send_lua(agent_mgr, "kick", fd, error_code.disconnect)
	end
end

function SOCKET.close(fd)
	skynet_m.log("socket close", fd)
	close_agent(fd)
end

function SOCKET.error(fd, msg)
	skynet_m.log("socket error", fd, msg)
	close_agent(fd)
end

function SOCKET.warning(fd, size)
	-- size K bytes havn't send out in fd
	skynet_m.log("socket warning", fd, size)
end

function SOCKET.data(fd, msg)
end

function CMD.start(conf)
	skynet_m.call_lua(gate, "open" , conf)
end

function CMD.close(fd)
	close_agent(fd)
end

skynet_m.start(function()
	error_code = share.error_code
	agent_mgr = skynet_m.queryservice("agent_mgr")

	skynet_m.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd], string.format("Service %s without command %s.", SERVICE_NAME, cmd))
			skynet_m.retpack(f(subcmd, ...))
		end
	end)

	gate = skynet_m.newservice("gate")
end)
