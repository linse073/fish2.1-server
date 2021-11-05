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
	kind 3 : integer(2)
	rotate 4 : integer(1)
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

.heart_beat {
}

.use_prop {
	prop_id 0 : integer
	prop_num 1 : integer(2)
}

.set_cannon {
	cannon 0 : integer
}

]]

proto.s2c = sprotoparser.parse [[

.event_info {
	mapid 0 : integer
	eventid 1 : integer
	event_time 2 : double
	event_phase 3 : integer(1)
}

.join_resp {
	code 0 : integer(2)
	info 1 : event_info
}

.kick {
	code 0 : integer(2)
}

.user_info {
	user_id 0 : integer
	pos 1 : integer(1)
	cannon 2 : integer(2)
}

.fish_info {
	id 0 : integer
	rule_id 1 : integer
	rule_index 2 : integer(2)
	fish_id 3 : integer
	spline_id 4 : integer
	group_id 5 : integer
	time 7 : double
	group_index 8 : integer(2)
}

.prop_info {
	prop_id 0 : integer
	num 1 : integer(2)
	user_id 2 : integer
	time 3 : double
}

.room_data {
	user 0 : *user_info
	pos 1 : integer(1)
	fish 2 : *fish_info
	prop 3 : *prop_info
	event 4 : event_info
}

.set_cannon {
	pos 0 : integer(1)
	cannon 1 : integer(2)
}

.simp_bullet {
	id 0 : integer
	multi 1 : integer
}

.catch_fish {
	pos 0 : integer(1)
	fishid 1 : integer
	fish_id 2 : integer
	multi 3 : integer
	bullet 4 : simp_bullet
}

.bullet_info {
	id 0 : integer
	my_id 1 : integer
	kind 2 : integer(2)
	angle 3 : double
	rotate 4 : integer(1)
	target 5 : integer
}

.fire {
	pos 0 : integer(1)
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

]]

return proto
