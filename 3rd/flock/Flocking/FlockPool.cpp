#include "FlockPool.h"
#include "FlockAgent.h"
#include "KBECommon.h"

void FlockPool::Init()
{
	for (int32_t i = 0; i < 50; i++) 
	{
		AFlockAgent* agent = new AFlockAgent();
		pool_.push_back(agent);
	}
}

void FlockPool::Clear()
{
	for (auto& item : pool_)
	{
		KBE_SAFE_RELEASE(item);
	}
	pool_.clear();
}

AFlockAgent* FlockPool::GetAgent()
{
	AFlockAgent* agent = nullptr;
	if (pool_.empty())
	{
		agent = new AFlockAgent();
	}
	else
	{
		agent = pool_.back();
		pool_.pop_back();
	}
	KBE_ASSERT(agent);
	return agent;
}

void FlockPool::RecycleAgent(AFlockAgent* agent)
{
	pool_.push_back(agent);
}