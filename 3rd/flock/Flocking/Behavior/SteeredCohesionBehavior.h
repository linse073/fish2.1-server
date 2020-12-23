#ifndef __STEERED_COHESION_BEHAVIOR_H__
#define __STEERED_COHESION_BEHAVIOR_H__

#include "FlockBehavior.h"

class SteeredCohesionBehavior : public FlockBehavior
{
public:
	virtual VInt3 CalcMove(AFlockAgent& agent, const ContextFilter& filter);
};

#endif // __STEERED_COHESION_BEHAVIOR_H__