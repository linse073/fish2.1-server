#include "AvoidObstacleBehavior.h"
#include "FlockAgent.h"
#include "ContextFilter.h"
#include "FlockShap.h"

VInt3 AvoidObstacleBehavior::CalcMove(const AFlockAgent& agent, const ContextFilter& filter)
{
	const std::vector<FlockShap*>& obstacle = filter.getObstacle();
	if (obstacle.empty())
		return VInt3::zero;
	VInt3 avoidanceMove;
	int32_t avoidCount = 0;
	for (auto& item : obstacle)
	{
		VInt3 dis = item->CalcMove(agent);
		if (dis != VInt3::zero)
		{
			++avoidCount;
			avoidanceMove = avoidanceMove + dis;
		}
	}
	if (avoidCount > 0)
		avoidanceMove = avoidanceMove / avoidCount;
	return avoidanceMove;
}