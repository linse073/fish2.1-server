local data = {
    [1001] = {
        interval = 5,       --boss技能间隔时间
        born_time = 12,      --boss出生到第一个技能开始时间
        skill = {
            {
                duration = 30, --技能持续时间
				hit_count = 1, --被命中几次打断技能
				fish = {
					{
						fish_id = 3000,
						spline_id = 0,
						time = 3,   --多少秒可以刷这个鱼
						in_count = true,
                        num = 1,   --多个boss目标点
						matrix_id = 0,  --鱼阵列ID
						speed = 0,
					},
					--第一条线6001
					{
						fish_id = 5011,
						spline_id = 6001,
						time = 3,   --多少秒可以刷这个鱼
						in_count = false,
                        num = 12,   --多个boss目标点
						matrix_id = 0,  --鱼阵列ID
						speed = 140,
					},
					{
						fish_id = 5011,
						spline_id = 6001,
						time = 18,   --多少秒可以刷这个鱼
						in_count = false,
                        num = 12,   --多个boss目标点
						matrix_id = 0,  --鱼阵列ID
						speed = 140,
					},
					{
						fish_id = 5011,
						spline_id = 6001,
						time = 33,   --多少秒可以刷这个鱼
						in_count = false,
                        num = 12,   --多个boss目标点
						matrix_id = 0,  --鱼阵列ID
						speed = 140,
					},
					{
						fish_id = 5011,
						spline_id = 6001,
						time = 48,   --多少秒可以刷这个鱼
						in_count = false,
                        num = 12,   --多个boss目标点
						matrix_id = 0,  --鱼阵列ID
						speed = 140,
					},
					--第二条线6002
					{
						fish_id = 5011,
						spline_id = 6002,
						time = 6,   --多少秒可以刷这个鱼
						in_count = false,
                        num = 12,   --多个boss目标点
						matrix_id = 0,  --鱼阵列ID
						speed = 140,
					},
					{
						fish_id = 5011,
						spline_id = 6002,
						time = 21,   --多少秒可以刷这个鱼
						in_count = false,
                        num = 12,   --多个boss目标点
						matrix_id = 0,  --鱼阵列ID
						speed = 140,
					},
					{
						fish_id = 5011,
						spline_id = 6002,
						time = 36,   --多少秒可以刷这个鱼
						in_count = false,
                        num = 12,   --多个boss目标点
						matrix_id = 0,  --鱼阵列ID
						speed = 140,
					},
					{
						fish_id = 5011,
						spline_id = 6002,
						time = 51,   --多少秒可以刷这个鱼
						in_count = false,
                        num = 12,   --多个boss目标点
						matrix_id = 0,  --鱼阵列ID
						speed = 140,
					},
					--第三条线6003
										{
						fish_id = 5011,
						spline_id = 6003,
						time = 5,   --多少秒可以刷这个鱼
						in_count = false,
                        num = 12,   --多个boss目标点
						matrix_id = 0,  --鱼阵列ID
						speed = 140,
					},
					{
						fish_id = 5011,
						spline_id = 6003,
						time = 20,   --多少秒可以刷这个鱼
						in_count = false,
                        num = 12,   --多个boss目标点
						matrix_id = 0,  --鱼阵列ID
						speed = 140,
					},
					{
						fish_id = 5011,
						spline_id = 6003,
						time = 35,   --多少秒可以刷这个鱼
						in_count = false,
                        num = 12,   --多个boss目标点
						matrix_id = 0,  --鱼阵列ID
						speed = 140,
					},
					{
						fish_id = 5011,
						spline_id = 6003,
						time = 50,   --多少秒可以刷这个鱼
						in_count = false,
                        num = 12,   --多个boss目标点
						matrix_id = 0,  --鱼阵列ID
						speed = 140,
					},
					--第四条线6004
										{
						fish_id = 5011,
						spline_id = 6004,
						time = 8,   --多少秒可以刷这个鱼
						in_count = false,
                        num = 12,   --多个boss目标点
						matrix_id = 0,  --鱼阵列ID
						speed = 140,
					},
					{
						fish_id = 5011,
						spline_id = 6004,
						time = 26,   --多少秒可以刷这个鱼
						in_count = false,
                        num = 12,   --多个boss目标点
						matrix_id = 0,  --鱼阵列ID
						speed = 140,
					},
					{
						fish_id = 5011,
						spline_id = 6004,
						time = 41,   --多少秒可以刷这个鱼
						in_count = false,
                        num = 12,   --多个boss目标点
						matrix_id = 0,  --鱼阵列ID
						speed = 140,
					},
					{
						fish_id = 5011,
						spline_id = 6004,
						time = 57,   --多少秒可以刷这个鱼
						in_count = false,
                        num = 12,   --多个boss目标点
						matrix_id = 0,  --鱼阵列ID
						speed = 140,
					},
				},
            },
            {
                duration = 30,
				hit_count = 3, --被命中几次打断技能
				fish = {
					{
						fish_id = 3001,
						spline_id = 0,
						time = 1,   --多少秒可以刷这个鱼
						in_count = true,
                        num = 1,   --多个boss目标点
						matrix_id = 0,  --鱼阵列ID
						speed = 0,
					},
					{
						fish_id = 3002,
						spline_id = 0,
						time = 1,   --多少秒可以刷这个鱼
						in_count = true,
                        num = 1,   --多个boss目标点
						matrix_id = 0,  --鱼阵列ID
						speed = 0,
					},
					{
						fish_id = 3003,
						spline_id = 0,
						time = 1,   --多少秒可以刷这个鱼
						in_count = true,
                        num = 1,   --多个boss目标点
						matrix_id = 0,  --鱼阵列ID
						speed = 0,
					},
				},
            },
            {
                duration = 30,
				hit_count = 2, --被命中几次打断技能
				fish = {
					{
						fish_id = 3004,
						spline_id = 0,
						time = 4,   --多少秒可以刷这个鱼
						in_count = true,
                        num = 1,   --多个boss目标点
						matrix_id = 0,  --鱼阵列ID
						speed = 0,
					},
					{
						fish_id = 3005,
						spline_id = 0,
						time = 4,   --多少秒可以刷这个鱼
						in_count = true,
                        num = 1,   --多个boss目标点
						matrix_id = 0,  --鱼阵列ID
						speed = 0,
					},
				},
            },
            {
                duration = 30,
				hit_count = 1, --被命中几次打断技能
				fish = {
					{
						fish_id = 3006,
						spline_id = 0,
						time = 2,   --多少秒可以刷这个鱼
						in_count = true,
                        num = 1,   --多个boss目标点
						matrix_id = 0,  --鱼阵列ID
						speed = 0,
					},
				},
            },
        }
    },
}

return data