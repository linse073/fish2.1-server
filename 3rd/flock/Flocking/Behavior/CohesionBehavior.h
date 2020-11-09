#ifndef __COHESION_BEHAVIOR_H__
#define __COHESION_BEHAVIOR_H__

#include "FlockBehavior.h"

class CohesionBehavior : public FlockBehavior
{
public:
	virtual VInt3 CalcMove(const AFlockAgent& agent, const ContextFilter& filter);
};

#endif // __COHESION_BEHAVIOR_H__