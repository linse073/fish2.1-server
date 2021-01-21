
local define = {}

define.event_type = {
    camera_speed = 1,
    active_scene_spline = 2,
    deactive_scene_spline = 3,
    active_camera_spline = 4,
    deactive_camera_spline = 5,
    active_fish = 6,
    deactive_fish = 7,
    fight_boss = 8,
    max_small_fish = 9,
    max_big_fish = 10,
}

define.fish_type = {
    small_fish = 0,
    big_fish = 1,
    boss_fish = 2,
}

return define