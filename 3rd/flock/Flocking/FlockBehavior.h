#ifndef __FLOCK_BEHAVIOR_H__
#define __FLOCK_BEHAVIOR_H__

#include "VInt3.h"

class AFlockAgent;
class ContextFilter;

class FlockBehavior
{
public:
	virtual ~FlockBehavior() {}

	virtual VInt3 CalcMove(AFlockAgent& agent, const ContextFilter& filter) = 0;
};

#endif // __FLOCK_BEHAVIOR_H__