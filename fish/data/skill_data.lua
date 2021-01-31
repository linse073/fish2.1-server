local data = {
    [1001] = {
        interval = 6,       --boss技能间隔时间
        born_time = 15,      --boss出生到第一个技能开始时间
        skill = {
            {
                duration = 50, --技能持续时间
				hit_count = 1, --被命中几次打断技能
				fish = {
					{
						fish_id = 3000,
						spline_id = 0,
						time = 3,   --多少秒可以刷这个鱼
						in_count = 1,
                        num = 1,   --多个boss目标点
						matrix_id = 0,  --鱼阵列ID
						speed = 0,
					},
				},
            },
            {
                duration = 50,
				hit_count = 3, --被命中几次打断技能
				fish = {
					{
						fish_id = 3001,
						spline_id = 0,
						time = 1,   --多少秒可以刷这个鱼
						in_count = 1,
                        num = 3,   --多个boss目标点
						matrix_id = 0,  --鱼阵列ID
						speed = 0,
					},
				},

            },
            {
                duration = 50,
				hit_count = 2, --被命中几次打断技能
				fish = {
					{
						fish_id = 3002,
						spline_id = 0,
						time = 4,   --多少秒可以刷这个鱼
						in_count = 1,
                        num = 2,   --多个boss目标点
						matrix_id = 0,  --鱼阵列ID
						speed = 0,
					},
				},

            },
            {
                duration = 50,
				hit_count = 1, --被命中几次打断技能
				fish = {
					{
						fish_id = 3003,
						spline_id = 0,
						time = 2,   --多少秒可以刷这个鱼
						in_count = 1,
                        num = 1,   --多个boss目标点
						matrix_id = 0,  --鱼阵列ID
						speed = 0,
					},
				},

            },
        }
    },
}