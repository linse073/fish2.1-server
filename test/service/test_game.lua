local skynet_m = require "skynet_m"

skynet_m.start(function()
    skynet_m.log("Server start.")

    -- debug service
    if not skynet_m.getenv("daemon") then
        skynet_m.newservice("console")
    end

    -- service
    skynet_m.uniqueservice("routine")
    local game_client = skynet_m.uniqueservice("game_client")
    skynet_m.send_lua(game_client, "start")

    skynet_m.log("Server start finish.")

    skynet_m.exit()
end)