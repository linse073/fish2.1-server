#include "AlignmentBehavior.h"
#include "FlockAgent.h"
#include "ContextFilter.h"

VInt3 AlignmentBehavior::CalcMove(AFlockAgent& agent, const ContextFilter& filter)
{
	const std::vector<AFlockAgent*>& context = filter.getNeighbor();
	if (context.empty())
		return agent.GetDir();
	VInt3 alignmentMove;
	for (auto& item : context)
	{
		alignmentMove = alignmentMove + item->GetDir();
	}
	alignmentMove = alignmentMove / (int32_t)context.size();
	return alignmentMove;
}