#include "FlockCompositeBehavior.h"
#include "AlignmentBehavior.h"
#include "AvoidanceBehavior.h"
#include "SteeredCohesionBehavior.h"
#include "CohesionBehavior.h"
#include "FlockAsset.h"
#include "KBECommon.h"
#include "IntMath.h"
#include "FlockAgent.h"
#include "ContextFilter.h"

FlockCompositeBehavior::FlockCompositeBehavior()
{
	behavior_.push_back({ new AlignmentBehavior(), 10 });
	behavior_.push_back({ new AvoidanceBehavior(), 3 });
	//behavior_.push_back({ new CohesionBehavior(), 2 });
	behavior_.push_back({ new SteeredCohesionBehavior(), 2 });
}

FlockCompositeBehavior::~FlockCompositeBehavior()
{
	for (auto& item : behavior_)
	{
		KBE_SAFE_RELEASE(item.behavior);
	}
}

VInt3 FlockCompositeBehavior::CalcMove(AFlockAgent& agent, const ContextFilter& filter)
{
	VInt3 move;
	for (auto& item : behavior_)
	{
		VInt3 partialMove = item.behavior->CalcMove(agent, filter) * item.weight;
		if (partialMove != VInt3::zero)
		{
			int64_t maxLen = int64_t(item.weight) * 1000LL;
			if (partialMove.sqrMagnitudeLong() > maxLen * maxLen)
			{
				partialMove.NormalizeTo(maxLen);
			}
			move = move + partialMove;
		}
	}
	//move = IntMath::VInterpNormalRotationTo(agent.GetDir(), tm, 1.f, 1.f);
	move = IntMath::VInterpNormalRotationTo(agent.GetDir(), move, filter.getFlockRotationDegreesPerStep());
	return move;
}

void FlockCompositeBehavior::Init(const UFlockAsset* flockAsset)
{
	behavior_[0].weight = flockAsset->AlignmentBehaviorWeight;
	behavior_[1].weight = flockAsset->AvoidanceBehaviorWeight;
	behavior_[2].weight = flockAsset->SteeredCohesionBehaviorWeight;
}