#include "CohesionBehavior.h"
#include "FlockAgent.h"
#include "ContextFilter.h"

VInt3 CohesionBehavior::CalcMove(AFlockAgent& agent, const ContextFilter& filter)
{
	const std::vector<AFlockAgent*>& context = filter.getNeighbor();
	if (context.empty())
		return VInt3::zero;
	VInt3 cohesionMove;
	for (auto& item : context)
	{
		cohesionMove = cohesionMove + item->GetPos();
	}
	cohesionMove = cohesionMove / (int32_t)context.size();
	cohesionMove = cohesionMove - agent.GetPos();
	return cohesionMove;
}