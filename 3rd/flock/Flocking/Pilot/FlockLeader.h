#ifndef __FLOCK_LEADER_H__
#define __FLOCK_LEADER_H__

#include <vector>
#include "FlockPilot.h"
#include "FlockCommon.h"

class FlockLeader : public FlockPilot
{
public:
	FlockLeader();

	virtual void Serialize(KBEngine::MemoryStream& stream);
	virtual void Unserialize(KBEngine::MemoryStream& stream);
	virtual void Update(const Flock* flock, const std::vector<AFlockAgent*>& context);
	virtual uint32_t GetID();
	virtual VInt3 UpdateAgent(const Flock* flock, AFlockAgent& agent);

private:
	uint32_t ID_;
	uint32_t beginStep_;
	uint32_t endStep_;
	int32_t radius_;
	int32_t range_;
	int32_t force_;
	std::vector<PilotData> data_;
	bool fishType_[FishType_Count];
};

#endif // __FLOCK_LEADER_H__