local skynet_m = require "skynet_m"

skynet_m.start(function()
    skynet_m.log("Server start.")

    -- debug service
    if not skynet_m.getenv("daemon") then
        skynet_m.newservice("console")
    end
    skynet_m.newservice("debug_console", skynet_m.getenv("debug_port"))

    -- service
    skynet_m.uniqueservice("cache")
    skynet_m.uniqueservice("routine")
    local agent_pool = skynet_m.uniqueservice("agent_pool")
    skynet_m.uniqueservice("agent_mgr")
    skynet_m.uniqueservice("gate_mgr")
    local game_client, game_message
    if skynet_m.getenv("game_mode") == "fake_game" then
        game_client = skynet_m.uniqueservice("fake_game")
        game_message = skynet_m.uniqueservice("fake_message")
    else
        game_client = skynet_m.uniqueservice("game_client")
        game_message = skynet_m.uniqueservice("game_message")
    end
    skynet_m.uniqueservice("room_mgr")
    skynet_m.call_lua(agent_pool, "start")
    skynet_m.call_lua(game_message, "start")
    skynet_m.call_lua(game_client, "start")

    skynet_m.log("Server start finish.")

    skynet_m.exit()
end)