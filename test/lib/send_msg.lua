local skynet_m = require "skynet_m"

local function send_msg()
    local game_message = skynet_m.queryservice("game_message")

    skynet_m.send_lua(game_message, "send_enter_game", {
        userid = 100,
        tableid = 10,
        seatid = 0,
    })
    skynet_m.sleep(200)

    skynet_m.send_lua(game_message, "send_build_fish", {
        tableid = 10,
        fish = {
            {
                id = 501,
                kind = 2,
            },
            {
                id = 502,
                kind = 3,
            },
            {
                id = 503,
                kind = 4,
            },
            {
                id = 504,
                kind = 5,
            },
            {
                id = 505,
                kind = 6,
            },
            {
                id = 506,
                kind = 7,
            },
        },
    })
    skynet_m.sleep(500)

    skynet_m.send_lua(game_message, "send_fire", {
        userid = 100,
        tableid = 10,
        seatid = 1,
        bullet = {
            id = 300,
            kind = 2,
            multi = 3,
            power = 3,
            expTime = 5,
        },
    })
    skynet_m.sleep(100)

    skynet_m.send_lua(game_message, "send_fire", {
        userid = 100,
        tableid = 10,
        seatid = 1,
        bullet = {
            id = 301,
            kind = 2,
            multi = 3,
            power = 3,
            expTime = 5,
        },
    })
    skynet_m.sleep(200)

    skynet_m.send_lua(game_message, "send_catch_fish", {
        userid = 100,
        tableid = 10,
        seatid = 1,
        bulletid = 300,
        fishid = 500,
        bulletMulti = 3,
    })
    skynet_m.sleep(200)

    skynet_m.send_lua(game_message, "send_catch_fish", {
        userid = 100,
        tableid = 10,
        seatid = 1,
        bulletid = 301,
        fishid = 503,
        bulletMulti = 3,
    })
    skynet_m.sleep(200)

    skynet_m.send_lua(game_message, "send_use_prob", {
        userid = 100,
        tableid = 10,
        seatid = 1,
        probid = 1000,
        probCount = 100,
    })

    skynet_m.send_lua(game_message, "send_leave_game", {
        userid = 100,
        tableid = 10,
        seatid = 1,
    })
end

return send_msg