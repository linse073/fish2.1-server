#ifndef __FLOCK_POOL_H__
#define __FLOCK_POOL_H__

#include <vector>

class AFlockAgent;

class FlockPool
{
public:
	void Init();
	void Clear();

	AFlockAgent* GetAgent();
	void RecycleAgent(AFlockAgent* agent);

private:
	std::vector<AFlockAgent*> pool_;
};

#endif // __FLOCK_POOL_H__