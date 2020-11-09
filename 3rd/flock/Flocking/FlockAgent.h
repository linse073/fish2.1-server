#ifndef __FLOCK_AGENT_H__
#define __FLOCK_AGENT_H__

#include "VInt3.h"
#include "FishType.h"

class UFishAsset;

class AFlockAgent
{
public:
	AFlockAgent();

	void Clear();

	void OnHit_fast(bool dead);
	void Init_fast(uint32_t id, int32_t scale, const VInt3& pos, const VInt3& dir, const UFishAsset* fishAsset, EFishType fishType);
	void Move_fast(VInt3 move);

	//const UFishAsset* GetFishAsset() const;
	const VInt3& GetPos() const;
	const VInt3& GetDir() const;
	uint32_t GetID() const;
	int32_t GetNeighborRadius() const;
	int32_t GetAvoidanceRadius() const;
	int32_t GetMaxMove() const;
	uint8_t GetCamp() const;
	bool IsDead() const;
	EFishType GetFishType() const;

private:
	const UFishAsset* fishAsset_;
	uint32_t id_;
	VInt3 pos_;
	VInt3 dir_;
	int32_t avoidanceRadius_;
	bool dead_;
	EFishType fishType_;
};

#endif // __FLOCK_AGENT_H__