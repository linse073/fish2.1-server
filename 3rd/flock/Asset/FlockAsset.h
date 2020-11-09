#ifndef __FLOCK_ASSET_H__
#define __FLOCK_ASSET_H__

#include <vector>
#include "FishType.h"
#include "FishAsset.h"
#include "MemoryStream.h"

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

	~UNewFishAsset()
	{
		KBE_SAFE_RELEASE(FishAsset);
	}

	void Serialize(KBEngine::MemoryStream& stream)
	{
		stream.writeUint8(FishType);
		stream << RandomScale;
		stream << MinScale;
		stream << MaxScale;
		stream << RandomPos;
		stream << RandomRadius;
		stream << InitCount;
		stream << RandomDir;
		KBE_ASSERT(FishAsset);
		FishAsset->Serialize(stream);
	}

	void Unserialize(KBEngine::MemoryStream& stream)
	{
		FishType = (EFishType)stream.readUint8();
		stream >> RandomScale;
		stream >> MinScale;
		stream >> MaxScale;
		stream >> RandomPos;
		stream >> RandomRadius;
		stream >> InitCount;
		stream >> RandomDir;
		KBE_ASSERT(FishAsset == nullptr);
		FishAsset = new UFishAsset();
		FishAsset->Unserialize(stream);
	}
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

	~UFlockAsset()
	{
		for (auto& item : NewFishAsset)
			KBE_SAFE_RELEASE(item);
		NewFishAsset.clear();	
	}

	void Serialize(KBEngine::MemoryStream& stream)
	{
		stream << TotalFishCount;
		stream << SmallFishRatio;
		stream << BigFishRatio;
		stream << HugeFishRatio;
		stream << AlignmentBehaviorWeight;
		stream << AvoidanceBehaviorWeight;
		stream << SteeredCohesionBehaviorWeight;
		stream << FlockCompositeBehaviorWeight;
		stream << StayInRadiusBehaviorWeight;
		stream << AvoidObstacleBehaviorWeight;
		stream << FlockRotationDegreesPerStep;
		stream << RotationDegreesPerStep;
		stream << CameraObstacleSphereRadius;
		stream << SphereCenterByCameraForward;
		stream << SphereRadius;
		stream << ScreenWidth;
		stream << ScreenHight;
		stream << FortPositionX;
		stream << MuzzleLength;
		stream << BulletSpeed;
		KBE_ASSERT(!NewFishAsset.empty());
		stream << (uint8_t)NewFishAsset.size();
		for (auto& item : NewFishAsset)
			item->Serialize(stream);
	}

	void Unserialize(KBEngine::MemoryStream& stream)
	{
		stream >> TotalFishCount;
		stream >> SmallFishRatio;
		stream >> BigFishRatio;
		stream >> HugeFishRatio;
		stream >> AlignmentBehaviorWeight;
		stream >> AvoidanceBehaviorWeight;
		stream >> SteeredCohesionBehaviorWeight;
		stream >> FlockCompositeBehaviorWeight;
		stream >> StayInRadiusBehaviorWeight;
		stream >> AvoidObstacleBehaviorWeight;
		stream >> FlockRotationDegreesPerStep;
		stream >> RotationDegreesPerStep;
		stream >> CameraObstacleSphereRadius;
		stream >> SphereCenterByCameraForward;
		stream >> SphereRadius;
		stream >> ScreenWidth;
		stream >> ScreenHight;
		stream >> FortPositionX;
		stream >> MuzzleLength;
		stream >> BulletSpeed;
		KBE_ASSERT(NewFishAsset.empty());
		uint8_t size = stream.readUint8();
		for (uint8_t i = 0; i < size; ++i)
		{
			UNewFishAsset* item = new UNewFishAsset();
			item->Unserialize(stream);
			NewFishAsset.push_back(item);
		}
	}
};

#endif // __FLOCK_ASSET_H__