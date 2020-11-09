#ifndef __ALIGNMENt_BEHAVIOR_H__
#define __ALIGNMENt_BEHAVIOR_H__

#include "FlockBehavior.h"

class AlignmentBehavior : public FlockBehavior
{
public:
	virtual VInt3 CalcMove(const AFlockAgent& agent, const ContextFilter& filter);
};

#endif // __ALIGNMENt_BEHAVIOR_H__