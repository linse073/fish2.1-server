#include "FlockAsset.h"
#include "FishAsset.h"
#include "MemoryStream.h"
#include "BossAsset.h"

UNewFishAsset::~UNewFishAsset()
{
	KBE_SAFE_RELEASE(FishAsset);
}

void UNewFishAsset::Serialize(KBEngine::MemoryStream& stream)
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

void UNewFishAsset::Unserialize(KBEngine::MemoryStream& stream)
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

UFlockAsset::~UFlockAsset()
{
	for (auto& item : NewFishAsset)
		KBE_SAFE_RELEASE(item);
	NewFishAsset.clear();	
	for (auto& item : BossAsset)
		KBE_SAFE_RELEASE(item);
	BossAsset.clear();	
}

void UFlockAsset::Serialize(KBEngine::MemoryStream& stream)
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
	stream << PilotBehaviorWeight;
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
	KBE_ASSERT(!BossAsset.empty());
	stream << (uint8_t)BossAsset.size();
	for (auto& item : BossAsset)
		item->Serialize(stream);
}

void UFlockAsset::Unserialize(KBEngine::MemoryStream& stream)
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
	stream >> PilotBehaviorWeight;
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
	KBE_ASSERT(BossAsset.empty());
	uint8_t size = stream.readUint8();
	for (uint8_t i = 0; i < size; ++i)
	{
		UBossAsset* item = new UBossAsset();
		item->Unserialize(stream);
		BossAsset.push_back(item);
	}
}