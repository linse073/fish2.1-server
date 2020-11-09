#include "StayInRadiusBehavior.h"
#include "FlockAgent.h"
#include "ContextFilter.h"
#include "IntMath.h"

VInt3 StayInRadiusBehavior::CalcMove(const AFlockAgent& agent, const ContextFilter& filter)
{
	VInt3 centerOffset = filter.getSphereCenter() - agent.GetPos();
	int32_t t = IntMath::Divide(centerOffset.magnitude(), filter.getSphereRadius() / 1000);
	if (t < 900)
	{
		return VInt3::zero;
	}
	VFactor ratio((int64_t)t, 1000LL);
	return centerOffset * ratio * ratio;
}