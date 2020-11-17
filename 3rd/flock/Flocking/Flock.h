#ifndef __FLOCK_H__
#define __FLOCK_H__

#include <vector>
#include <map>
#include "VInt4.h"
#include "KBECommon.h"
#include "FishType.h"

class UFlockAsset;
class UNewFishAsset;
class FlockShap;
class UBulletWidget;
class AFlockAgent;

namespace KBEngine
{
	class MemoryStream;
}

static const int32_t FishType_Count = int32_t(FishType_Boss) + 1;

class Flock
{
public:
	Flock(void* callback, uint32_t randSeed);
	virtual ~Flock();

	void init(const UFlockAsset* flockAsset);
	void clear();

	void onFire_fast(uint32_t id, uint32_t kind, uint8_t index, int32_t x, int32_t y, uint32_t multi, uint32_t costGold);
	void onHit_fast(uint8_t index, uint32_t bulletid, uint32_t fishid);
	void onDead_fast(uint8_t index, uint32_t bulletid, uint32_t fishid, uint16_t multi, uint16_t bulletMulti, uint32_t winGold);
	void update_fast();

	void loadFlockAssetData(const char* Result, uint32_t length);
	void loadCameraData(const char* Result, uint32_t length);
	void loadObstacleData(const char* Result, uint32_t length);
	void doKeyStepCmd_fast(const char* Result, uint32_t length);
	void packData(KBEngine::MemoryStream& stream);
	void readData(KBEngine::MemoryStream& stream);

	const VInt3& getSphereCenter() const;
	int32_t getSphereRadius() const;
	int32_t getRotationDegreesPerStep() const;
	int32_t getFlockRotationDegreesPerStep() const;
	void* getCallback() const;
	uint32_t getBulletMulti(uint32_t bulletid) const;

private:
	struct FishCount
	{
		int32_t maxCount;
		int32_t minCount;
		int32_t curCount;
	};

	struct PathData
	{
		VInt3 pos;
		VInt4 quat;
	};

	enum OP
	{
		OP_idle = 1,
		OP_fire = 2,
		OP_hit = 3,
		OP_dead = 4,
	};

	void updateCamera_fast();
	void newAgent_fast();
	void newAgent_fast(const UNewFishAsset* newFishAsset);
	void updateAgent_fast();
	void updateBullet_fast();

	uint32_t id_;
	VInt3 cameraPos_;
	VInt4 cameraQuat_;
	VInt3 sphereCenter_;
	std::vector<AFlockAgent*> agent_;
	class FlockPool* pool_;
	class FlockBehavior* behavior_;
	const UFlockAsset* flockAsset_;
	std::vector<UNewFishAsset*> fishType_[FishType_Count];
	FishCount fishCount_[FishType_Count];
	std::vector<PathData> cameraPath_;
	uint32_t cameraStep_;
	std::vector<FlockShap*> obstacle_;
	VInt2 screenSize;
	class UBulletLayerWidget* bulletLayer_;
	VInt2 fortPos_[MAX_USER];
	std::vector<UBulletWidget*> bullet_;
	std::map<uint32_t, AFlockAgent*> agentMap_;
	std::map<uint32_t, UBulletWidget*> bulletMap_;
	void* callback_;
	class Random* random_;
};

#endif // __FLOCK_H__