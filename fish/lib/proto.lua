local sprotoparser = require "sprotoparser"

local proto = {}

proto.c2s = sprotoparser.parse [[

.join_room {
	user_id 0 : integer
	room_id 1 : integer
}

.ready {
	cannon 0 : integer
}

.quit {
}

.fire {
	self_id 0 : integer
	angle 1 : integer
	multi 2 : integer
	kind 3 : integer(2)
	rotate 4 : integer(1)
	target 5 : integer
}

.hit {
	self_id 0 : integer
	fishid 1 : integer
	multi 2 : integer
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
	event_time 2 : integer
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
	life_time 6 : integer
	time 7 : integer
	group_index 8 : integer(2)
}

.prop_info {
	prop_id 0 : integer
	num 1 : integer(2)
	user_id 2 : integer
}

.room_date {
	user 0 : *user_info
	fish 1 : *fish_info
	prop 2 : *prop_info
	event 3 : event_info
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
	self_id 1 : integer
	kind 2 : integer(2)
	angle 3 : integer
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
