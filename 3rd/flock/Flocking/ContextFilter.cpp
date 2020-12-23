#include "ContextFilter.h"
#include "FlockAgent.h"
#include "FlockShap.h"
#include "FishAsset.h"
#include "Flock.h"

ContextFilter::ContextFilter(const Flock* flock, const AFlockAgent& agent, const std::vector<AFlockAgent*>& context, const std::vector<FlockShap*>& obstacle)
	:flock_(flock)
{
	for (auto& item : context)
	{
		if (item->GetID() != agent.GetID())
		{
			VInt3 dis = agent.GetPos() - item->GetPos();
			if (dis.magnitude() - agent.GetAvoidanceRadius() <= item->GetNeighborRadius())
			{
				avoidance_.push_back(item);
				if (agent.GetCamp() == item->GetCamp())
				{
					neighbor_.push_back(item);
				}
			}
		}
	}
	const VInt3& sphereCenter = flock_->getSphereCenter();
	int32_t sphereRadius = flock_->getSphereRadius();
	for (auto& item : obstacle)
	{
		//if (item->InSphere(sphereCenter, sphereRadius))
		{
			obstacle_.push_back(item);
		}
	}
}

const std::vector<AFlockAgent*>& ContextFilter::getNeighbor() const
{
	return neighbor_;
}

const std::vector<AFlockAgent*>& ContextFilter::getAvoidance() const
{
	return avoidance_;
}

const std::vector<FlockShap*>& ContextFilter::getObstacle() const
{
	return obstacle_;
}

const VInt3& ContextFilter::getSphereCenter() const
{
	return flock_->getSphereCenter();
}

int32_t ContextFilter::getSphereRadius() const
{
	return flock_->getSphereRadius();
}

int32_t ContextFilter::getRotationDegreesPerStep() const
{
	return flock_->getRotationDegreesPerStep();
}

int32_t ContextFilter::getFlockRotationDegreesPerStep() const
{
	return flock_->getFlockRotationDegreesPerStep();
}

const Flock* ContextFilter::getFlock() const
{
	return flock_;
}