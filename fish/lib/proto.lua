local sprotoparser = require "sprotoparser"

local proto = {}

proto.c2s = sprotoparser.parse [[

.join_room {
	user_id 0 : integer
	room_id 1 : integer
	session 2 : string
}

.ready {
	cannon 0 : integer
}

.quit {
}

.fire_info {
	my_id 0 : integer
	angle 1 : double
	multi 2 : integer
	kind 3 : integer
	rotate 4 : integer
	target 5 : integer
}

.fire {
	info 0 : *fire_info
}

.hit_info {
	my_id 0 : integer
	fishid 1 : integer
	multi 2 : integer
}

.hit {
	info 0 : *hit_info
}

.hit_bomb {
	my_id 0 : integer
	fishid 1 : integer
	multi 2 : integer
	other 3 : *integer
}

.heart_beat {
}

.use_prop {
	prop_id 0 : integer
	prop_num 1 : integer
}

.set_cannon {
	cannon 0 : integer
}

.mode_info {
	rpt_mode 0 : boolean
	koi_type 1 : integer
	koi_life 2 : double
	koi_wait 3 : double
	koi_create 4 : boolean
}

.open_chest {
}

]]

proto.s2c = sprotoparser.parse [[

.event_info {
	mapid 0 : integer
	eventid 1 : integer
	event_time 2 : double
	event_phase 3 : integer
}

.join_resp {
	code 0 : integer
	info 1 : event_info
}

.kick {
	code 0 : integer
}

.user_info {
	user_id 0 : integer
	pos 1 : integer
	cannon 2 : integer
}

.fish_info {
	id 0 : integer
	rule_id 1 : integer
	rule_index 2 : integer
	fish_id 3 : integer
	spline_id 4 : integer
	group_id 5 : integer
	time 7 : double
	group_index 8 : integer
	boss_id 9 : integer
	host_id 10 : integer
	proxy_index 11 : integer
	frozen 12 : boolean
}

.prop_info {
	prop_id 0 : integer
	num 1 : integer
	user_id 2 : integer
	time 3 : double
}

.mode_info {
	rpt_mode 0 : boolean
	koi_type 1 : integer
	koi_life 2 : double
	koi_wait 3 : double
	koi_create 4 : boolean
}

.room_data {
	user 0 : *user_info
	pos 1 : integer
	fish 2 : *fish_info
	prop 3 : *prop_info
	event 4 : event_info
	mode 5 : mode_info
}

.set_cannon {
	pos 0 : integer
	cannon 1 : integer
}

.simp_bullet {
	id 0 : integer
	multi 1 : integer
}

.catch_fish {
	pos 0 : integer
	fishid 1 : integer
	fish_id 2 : integer
	multi 3 : integer
	bullet 4 : simp_bullet
	win_gold 5 : integer
	fish_score 6 : integer
	award_pool 7 : integer
	rpt 8 : integer
	rpt_ratio 9 : integer
	fish_multi 10 : *integer
}

.score_info {
	id 1 : integer
	fish_id 2 : integer
	score 3 : integer
}

.bomb_fish {
	pos 0 : integer
	multi 1 : integer
	bullet 2 : simp_bullet
	win_gold 3 : integer
	fish_score 4 : integer
	score 5 : *score_info
}

.bullet_info {
	id 0 : integer
	my_id 1 : integer
	kind 2 : integer
	angle 3 : double
	rotate 4 : integer
	target 5 : integer
}

.fire {
	pos 0 : integer
	bullet 1 : bullet_info
}

.leave_room {
	user_id 0 : integer
}

.new_fish {
	fish 0 : *fish_info
}

.simp_fish {
	id 0 : integer
	fish_id 1 : integer
}

.del_fish {
	fish 0 : *simp_fish
}

.open_chest {
	pos 0 : integer
}

]]

return proto
