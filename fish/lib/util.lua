local socket = require "skynet.socket"

local util = {}

function util.udp_address(from)
    local addr, port = socket.udp_address(from)
    return addr .. ":" .. port
end

function util.is_camera_spline(spline)
    return spline >= 2000 and spline < 3000
end

return util