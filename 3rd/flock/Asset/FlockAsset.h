#ifndef __FLOCK_ASSET_H__
#define __FLOCK_ASSET_H__

#include <vector>
#include "FishType.h"

namespace KBEngine
{
	class MemoryStream;
}
class UFishAsset;
class UBossAsset;

class UNewFishAsset
{
public:
	EFishType FishType;
	bool RandomScale;
	int32_t MinScale;
	int32_t MaxScale;
	bool RandomPos;
	int32_t RandomRadius;
	int32_t InitCount;
	bool RandomDir;
	UFishAsset* FishAsset;

	~UNewFishAsset();

	void Serialize(KBEngine::MemoryStream& stream);
	void Unserialize(KBEngine::MemoryStream& stream);
};

class UFlockAsset
{
public:
	int32_t TotalFishCount;
	uint8_t SmallFishRatio;
	uint8_t BigFishRatio;
	uint8_t HugeFishRatio;
	int32_t AlignmentBehaviorWeight;
	int32_t AvoidanceBehaviorWeight;
	int32_t SteeredCohesionBehaviorWeight;
	int32_t FlockCompositeBehaviorWeight;
	int32_t StayInRadiusBehaviorWeight;
	int32_t AvoidObstacleBehaviorWeight;
	int32_t PilotBehaviorWeight;
	int32_t FlockRotationDegreesPerStep;
	int32_t RotationDegreesPerStep;
	int32_t CameraObstacleSphereRadius;
	int32_t SphereCenterByCameraForward;
	int32_t SphereRadius;
	int32_t ScreenWidth;
	int32_t ScreenHight;
	int32_t FortPositionX;
	int32_t MuzzleLength;
	int32_t BulletSpeed;
	std::vector<UNewFishAsset*> NewFishAsset;
	std::vector<UBossAsset*> BossAsset;

	~UFlockAsset();

	void Serialize(KBEngine::MemoryStream& stream);

	void Unserialize(KBEngine::MemoryStream& stream);
};

#endif // __FLOCK_ASSET_H__