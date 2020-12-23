#ifndef __FLOCK_PILOT_H__
#define __FLOCK_PILOT_H__

#include <vector>
#include "VInt4.h"

class Flock;
class AFlockAgent;

namespace KBEngine
{
	class MemoryStream;
}

struct PilotData
{
	VInt3 pos;
	VInt4 quat;
};

class FlockPilot
{
public:
	virtual ~FlockPilot() {}

	virtual void Serialize(KBEngine::MemoryStream& stream) = 0;
	virtual void Unserialize(KBEngine::MemoryStream& stream) = 0;
	virtual void Update(const Flock* flock, const std::vector<AFlockAgent*>& context) = 0;
	virtual uint32_t GetID() = 0;
	virtual VInt3 UpdateAgent(const Flock* flock, AFlockAgent& agent) = 0;
};

#endif // __FLOCK_PILOT_H__