#ifndef __AVOID_OBSTACLE_BEHAVIOR_H__
#define __AVOID_OBSTACLE_BEHAVIOR_H__

#include "FlockBehavior.h"

class AvoidObstacleBehavior : public FlockBehavior
{
public:
	virtual VInt3 CalcMove(const AFlockAgent& agent, const ContextFilter& filter);
};

#endif // __AVOID_OBSTACLE_BEHAVIOR_H__