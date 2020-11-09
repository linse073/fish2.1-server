#include "CompositeBehavior.h"
#include "FlockCompositeBehavior.h"
#include "StayInRadiusBehavior.h"
#include "AvoidObstacleBehavior.h"
#include "FlockAsset.h"
#include "KBECommon.h"
#include "FlockAgent.h"
#include "IntMath.h"
#include "ContextFilter.h"

CompositeBehavior::CompositeBehavior()
{
	behavior_.push_back({ new FlockCompositeBehavior(), 10 + 3 + 2 });
	behavior_.push_back({ new StayInRadiusBehavior(), 5 });
	behavior_.push_back({ new AvoidObstacleBehavior(), 10 });
}

CompositeBehavior::~CompositeBehavior()
{
	for (auto& item : behavior_)
	{
		KBE_SAFE_RELEASE(item.behavior);
	}
}

VInt3 CompositeBehavior::CalcMove(const AFlockAgent& agent, const ContextFilter& filter)
{
	VInt3 move;
	for (auto& item : behavior_)
	{
		VInt3 partialMove = item.behavior->CalcMove(agent, filter) * item.weight;
		if (partialMove != VInt3::zero)
		{
			int32_t maxLen = item.weight * 1000LL;
			if (partialMove.magnitude() > maxLen)
			{
				partialMove.NormalizeTo(maxLen);
			}
			move = move + partialMove;
		}
	}
	while (move.sqrMagnitudeLong() < 0LL)
	{
		move = move / 1000;
	}
	int32_t maxMove = agent.GetMaxMove();
	if (move.magnitude() > maxMove)
	{
		move.NormalizeTo(maxMove);
	}
	//move = IntMath::VInterpNormalRotationTo(agent.GetDir(), tm, 1.f, 1.f);
	move = IntMath::VInterpNormalRotationTo(agent.GetDir(), move, filter.getRotationDegreesPerStep());
	return move;
}

void CompositeBehavior::Init(const UFlockAsset* flockAsset)
{
	((FlockCompositeBehavior*)behavior_[0].behavior)->Init(flockAsset);
	behavior_[0].weight = flockAsset->FlockCompositeBehaviorWeight;
	behavior_[1].weight = flockAsset->StayInRadiusBehaviorWeight;
	behavior_[2].weight = flockAsset->AvoidObstacleBehaviorWeight;
}