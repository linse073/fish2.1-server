#ifndef __STAY_INRADIUS_BEHAVIOR_H__
#define __STAY_INRADIUS_BEHAVIOR_H__

#include "FlockBehavior.h"

class StayInRadiusBehavior : public FlockBehavior
{
public:
	virtual VInt3 CalcMove(AFlockAgent& agent, const ContextFilter& filter);
};

#endif // __STAY_INRADIUS_BEHAVIOR_H__