#ifndef __COMPOSiTE_BEHAVIOR_H__
#define __COMPOSiTE_BEHAVIOR_H__

#include <vector>
#include "FlockBehavior.h"

class UFlockAsset;

class CompositeBehavior : public FlockBehavior
{
public:
	CompositeBehavior();
	virtual ~CompositeBehavior();

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

#endif // __COMPOSiTE_BEHAVIOR_H__