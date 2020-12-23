#ifndef __FLOCK_AGENT_H__
#define __FLOCK_AGENT_H__

#include "VInt3.h"
#include "FishType.h"

class UFishAsset;
class FlockPilot;

namespace KBEngine
{
	class MemoryStream;
}

class AFlockAgent
{
public:
	AFlockAgent();

	void Clear();
void Pack_Data(KBEngine::MemoryStream& stream);

	void OnHit_fast(bool dead);
	void Init_fast(uint32_t id, int32_t scale, const VInt3& pos, const VInt3& dir, const UFishAsset* fishAsset, EFishType fishType);
	void Move_fast(VInt3 move);
	void SetPilot(FlockPilot* pilot, bool init);
	void ClearPilot();
	void UpdatePilotStep(uint32_t step);

	//const UFishAsset* GetFishAsset() const;
	const VInt3& GetPos() const;
	const VInt3& GetDir() const;
	uint32_t GetID() const;
	int32_t GetNeighborRadius() const;
	int32_t GetAvoidanceRadius() const;
	int32_t GetVisionRadius() const;
	int32_t GetMaxMove() const;
	uint8_t GetCamp() const;
	bool IsDead() const;
	EFishType GetFishType() const;
	FlockPilot* GetPilot() const;
	uint32_t GetPilotStep() const;

private:
	const UFishAsset* fishAsset_;
	uint32_t id_;
	VInt3 pos_;
	VInt3 dir_;
	int32_t scale_;
	int32_t avoidanceRadius_;
	bool dead_;
	EFishType fishType_;
	FlockPilot* pilot_;
	uint32_t pilotStep_;
};

#endif // __FLOCK_AGENT_H__