local skynet_m = require "skynet_m"
local timer = require "timer"
local socket = require "client.socket"

local game_address = skynet_m.getenv("game_address")
local game_port = skynet_m.getenv_num("game_port")

local pcall = pcall
local string = string
local ipairs = ipairs
local error = error

local game_message
local game_fd
local last = ""
local msg_queue = {}
local start

local CMD = {}

CMD.routine = timer.call_routine

local function send_package(id, pack)
    local package = string.pack("<I2<I2", #pack, id) .. pack
	socket.send(game_fd, package)
end

local function unpack_package(text)
	local size = #text
	if size < 4 then
		return nil, text
	end
    local s = text:byte(2) * 256 + text:byte(1)
	if size < s+4 then
		return nil, text
	end
	return text:sub(1, 4+s), text:sub(5+s)
end

local function recv_package(last_pack)
	local result
	result, last_pack = unpack_package(last_pack)
	if result then
		return result, last_pack
	end
	local r = socket.recv(game_fd)
	if not r then
		return nil, last_pack
	end
	if r == "" then
		error "Game server closed"
	end
	return unpack_package(last_pack .. r)
end

local function dispatch_package()
	while true do
        local v, status
        status, v, last = pcall(recv_package, last)
        if status then
            if not v then
                break
            end
            -- TODO: process package
            skynet_m.send_lua(game_message, "recv_msg", v)
        else
            last = ""
            skynet_m.log(v)
            CMD.stop()
            start()
            break
        end
	end
end

local function process()
    dispatch_package()
    timer.done_routine("process_update")
end

local function heart_beat()
    -- TODO: send heart beat
    skynet_m.send_lua(game_message, "send_heart_beat")
    timer.done_routine("heart_beat")
end

start = function()
    local status
    status, game_fd = pcall(socket.connect, game_address, game_port)
    if status then
        skynet_m.log(string.format("Connect game server %s:%d successfully.", game_address, game_port))
        timer.del_routine("start_update")
        timer.add_routine("process_update", process, 1)
        -- TODO: send link message
        skynet_m.send_lua(game_message, "send_link")
        for _, v in ipairs(msg_queue) do
            send_package(v[1], v[2])
        end
        msg_queue = {}
    else
        game_fd = nil
        timer.add_routine("start_update", start, 300)
        -- skynet_m.log(string.format("Connect game server %s:%d fail.", game_address, game_port))
    end
end

function CMD.send_package(id, pack)
    if game_fd then
        send_package(id, pack)
    else
        msg_queue[#msg_queue+1] = {id, pack}
    end
end

function CMD.start()
    game_message = skynet_m.queryservice("game_message")
    start()
end

function CMD.on_link()
    timer.add_routine("heart_beat", heart_beat, 3000)
    -- for _, v in ipairs(msg_queue) do
    --     send_package(v[1], v[2])
    -- end
    -- msg_queue = {}
end

function CMD.on_heart_beat()
    -- timer.done_routine("heart_beat")
end

function CMD.stop()
    if game_fd then
        socket.close(game_fd)
        game_fd = nil
    end
    timer.del_all()
end

function CMD.exit()
    skynet_m.exit()
end

skynet_m.start(function()
    skynet_m.dispatch_lua(CMD)
end)