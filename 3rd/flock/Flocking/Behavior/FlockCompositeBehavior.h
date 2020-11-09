#ifndef __FLOCK_COMPOSITE_BEHAVIOR_H__
#define __FLOCK_COMPOSITE_BEHAVIOR_H__

#include <vector>
#include "FlockBehavior.h"

class UFlockAsset;

class FlockCompositeBehavior : public FlockBehavior
{
public:
	FlockCompositeBehavior();
	virtual ~FlockCompositeBehavior();

	virtual VInt3 CalcMove(const AFlockAgent& agent, const ContextFilter& filter);

	void Init(const UFlockAsset* flockAsset);

private:
	struct Behavior
	{
		FlockBehavior* behavior;
		int32_t weight;
	};

	std::vector<Behavior> behavior_;
};

#endif // __FLOCK_COMPOSITE_BEHAVIOR_H__