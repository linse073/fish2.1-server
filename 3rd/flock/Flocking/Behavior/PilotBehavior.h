#ifndef __PILOT_BEHAVIOR_H__
#define __PILOT_BEHAVIOR_H__

#include "FlockBehavior.h"

class PilotBehavior : public FlockBehavior
{
public:
	virtual VInt3 CalcMove(AFlockAgent& agent, const ContextFilter& filter);
};

#endif // __PILOT_BEHAVIOR_H__