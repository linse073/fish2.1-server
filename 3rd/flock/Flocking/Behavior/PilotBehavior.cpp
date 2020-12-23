#include "PilotBehavior.h"
#include "FlockAgent.h"
#include "ContextFilter.h"
#include "FlockPilot.h"

VInt3 PilotBehavior::CalcMove(AFlockAgent& agent, const ContextFilter& filter)
{
	FlockPilot* pilot = agent.GetPilot();
	if (pilot == nullptr)
	{
		return VInt3::zero;
	}
	return pilot->UpdateAgent(filter.getFlock(), agent);
}