#ifndef __AVOIDANCE_BEHAVIOR_H__
#define __AVOIDANCE_BEHAVIOR_H__

#include "FlockBehavior.h"

class AvoidanceBehavior : public FlockBehavior
{
public:
	virtual VInt3 CalcMove(const AFlockAgent& agent, const ContextFilter& filter);
};

#endif // __AVOIDANCE_BEHAVIOR_H__