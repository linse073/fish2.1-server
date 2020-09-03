local socket = require "skynet.socket"

local util = {}

function util.udp_address(from)
    local addr, port = socket.udp_address(from)
    return addr .. ":" .. port
end

return util