#include "AvoidanceBehavior.h"
#include "FlockAgent.h"
#include "ContextFilter.h"

VInt3 AvoidanceBehavior::CalcMove(const AFlockAgent& agent, const ContextFilter& filter)
{
	const std::vector<AFlockAgent*>& context = filter.getAvoidance();
	if (context.empty())
		return VInt3::zero;
	VInt3 avoidanceMove;
	int32_t avoidCount = 0;
	for (auto& item : context)
	{
		VInt3 dis = agent.GetPos() - item->GetPos();
		if (dis.magnitude() <= agent.GetAvoidanceRadius() + item->GetAvoidanceRadius())
		{
			++avoidCount;
			avoidanceMove = avoidanceMove + dis;
		}
	}
	if (avoidCount > 0)
		avoidanceMove = avoidanceMove / avoidCount;
	return avoidanceMove;
}