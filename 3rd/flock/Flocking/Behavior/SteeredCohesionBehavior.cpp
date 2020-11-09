#include "SteeredCohesionBehavior.h"
#include "FlockAgent.h"
#include "ContextFilter.h"
#include "IntMath.h"

VInt3 SteeredCohesionBehavior::CalcMove(const AFlockAgent& agent, const ContextFilter& filter)
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
	//cohesionMove = IntMath::VInterpNormalRotationTo(agent.GetDir(), cohesionMove, 1.f, 1.f);
	cohesionMove = IntMath::VInterpNormalRotationTo(agent.GetDir(), cohesionMove, filter.getFlockRotationDegreesPerStep());
	return cohesionMove;
}