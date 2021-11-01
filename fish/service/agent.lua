local skynet_m = require "skynet_m"
local socket = require "skynet.socket"
local sprotoloader = require "sprotoloader"
local share = require "share"
local queue = require "skynet.queue"
local timer = require "timer"
local channel = require "channel"

local assert = assert
local string = string
local setmetatable = setmetatable

local session = tonumber(...)
local c2s
local c2s_i2n
local s2c
local s2c_n2i
local error_code

local WATCHDOG
local channel_i
local client_fd
local last = ""

skynet_m.register_protocol {
	name = "client",
	id = skynet_m.PTYPE_CLIENT,
	unpack = skynet_m.tostring,
}

local function send_package(msg, info)
    local id = assert(s2c_n2i[msg], string.format("No s2c message %s.", msg))
    if s2c:exist_type(msg) then
        info = s2c:pencode(msg, info)
    end
    local content = string.pack(">I2", id) .. info
    local package = string.pack(">s2", content)
    socket.write(client_fd, package)
end

local function clear_agent(code)
    skynet_m.log(string.format("Clear agent %d, code %d.", session, code))
    if channel_i then
        channel_i:kick(code)
    end
    channel_i = nil
    timer.del_all()
end

local CMD = {}

CMD.routine = timer.call_routine

function CMD.start(conf)
	local fd = conf.client
	local gate = conf.gate
	WATCHDOG = conf.watchdog

	client_fd = fd
	skynet_m.call_lua(gate, "forward", fd)

    if channel_i then
        skynet_m.log(string.format("Reset agent %d.", session))
        clear_agent(error_code.reset_agent)
    end
    channel_i = setmetatable({}, channel)
    channel_i:init(fd, send_package)
    last = ""
    skynet_m.log(string.format("Start agent %d.", session))
end

function CMD.send(msg, info)
    if channel_i then
        send_package(msg, info)
    else
        skynet_m.log(string.format("Agent %d has stop, but send message %s.", session, msg))
    end
end

function CMD.stop(code)
    clear_agent(code)
    if client_fd then
        skynet_m.call_lua(WATCHDOG, "close", client_fd)
    end
    client_fd = nil
    last = ""
end

function CMD.exit()
    CMD.stop(error_code.unknown_error)
    skynet_m.log(string.format("Agent %d exit.", session))
	skynet_m.exit()
end

local function unpack_package(text)
	local size = #text
	if size < 2 then
		return nil, text
	end
    local s = string.unpack(">I2", text)
	if size < s+2 then
		return nil, text
	end
	return text:sub(3, 2+s), text:sub(3+s)
end

skynet_m.start(function()
	-- slot 1,2 set at main.lua
	c2s = sprotoloader.load(1)
	c2s_i2n = share.c2s_i2n
    s2c = sprotoloader.load(2)
    s2c_n2i = share.s2c_n2i
    error_code = share.error_code

	skynet_m.dispatch_lua_queue(CMD)

	local lock = queue()
	skynet_m.dispatch("client", function(fd, _, content)
		assert(fd == client_fd)	-- You can use fd to reply message
		skynet_m.ignoreret()	-- session is fd, don't call skynet_m.ret
        while true do
            local msg
            msg, last = unpack_package(last .. content)
            if not msg then
                break
            end
            local id = string.unpack(msg, ">I2")
            local arg = msg:sub(3)
            local msg_name = assert(c2s_i2n[id], string.format("No c2s message %d.", id))
            if c2s:exist_type(msg_name) then
                arg = c2s:pdecode(msg_name, arg)
            end
            if channel_i then
                lock(channel_i.process, channel_i, msg_name, arg)
            else
                skynet_m.log(string.format("Agent %d has stop, but receive message %s.", session, msg_name))
            end
        end
	end)
end)
