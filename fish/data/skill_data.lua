local data = {
	[1001] = {
		total_time = 600,
		skill = {
			{
				duration = 20, -- 技能持续时间
				hit_count = 1, -- 被命中几次打断技能
				fish_id = 3000,
				damage_count = 2,
				fish = {
					{
						fish_id = 3000,
						spline_id = 0,
						time = 3, -- 多少秒可以刷这个鱼
						in_count = true,
						num = 1, -- 多个boss目标点
						matrix_id = 0, -- 鱼阵列ID
						speed = 0,
					},
				},
			},
			{
				duration = 20, -- 技能持续时间
				hit_count = 1, -- 被命中几次打断技能
				fish_id = 3000,
				damage_count = 2,
				fish = {
					{
						fish_id = 3000,
						spline_id = 0,
						time = 3, -- 多少秒可以刷这个鱼
						in_count = true,
						num = 1, -- 多个boss目标点
						matrix_id = 0, -- 鱼阵列ID
						speed = 0,
					},
				},
			},
			{
				duration = 20, -- 技能持续时间
				hit_count = 1, -- 被命中几次打断技能
				fish_id = 0,
				damage_count = 2,
				fish = {
					{
						fish_id = 3000,
						spline_id = 0,
						time = 3, -- 多少秒可以刷这个鱼
						in_count = true,
						num = 1, -- 多个boss目标点
						matrix_id = 0, -- 鱼阵列ID
						speed = 0,
					},
				},
			},
		},
	},
	[1006] = {
		total_time = 600,
		skill = {
			{
				duration = 20, -- 技能持续时间
				hit_count = 1, -- 被命中几次打断技能
				fish_id = 3000,
				damage_count = 2,
				fish = {
				},
			},
			{
				duration = 20, -- 技能持续时间
				hit_count = 1, -- 被命中几次打断技能
				fish_id = 3000,
				damage_count = 2,
				fish = {
				},
			},
			{
				duration = 20, -- 技能持续时间
				hit_count = 1, -- 被命中几次打断技能
				fish_id = 0,
				damage_count = 2,
				fish = {
				},
			},
		},
	},
}

return data