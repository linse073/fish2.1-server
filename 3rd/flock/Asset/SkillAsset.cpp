#include "SkillAsset.h"
#include "MemoryStream.h"
#include "FlockAsset.h"

USkillFishAsset::~USkillFishAsset()
{
	KBE_SAFE_RELEASE(NewFishAsset);
}

void USkillFishAsset::Serialize(KBEngine::MemoryStream& stream)
{
	stream << Step;
	stream << PosX;
	stream << PosY;
	stream << PosZ;
	KBE_ASSERT(NewFishAsset);
	NewFishAsset->Serialize(stream);
}

void USkillFishAsset::Unserialize(KBEngine::MemoryStream& stream)
{
	stream >> Step;
	stream >> PosX;
	stream >> PosY;
	stream >> PosZ;
	KBE_ASSERT(NewFishAsset == nullptr);
	NewFishAsset = new UNewFishAsset();
	NewFishAsset->Unserialize(stream);
}

USkillAsset::~USkillAsset()
{
	for (auto& item : SkillFishAsset)
		KBE_SAFE_RELEASE(item);
	SkillFishAsset.clear();	
}

void USkillAsset::Serialize(KBEngine::MemoryStream& stream)
{
	stream << CD;
	stream << Rate;
	stream << (uint8_t)SkillFishAsset.size();
	for (auto& item : SkillFishAsset)
		item->Serialize(stream);
}

void USkillAsset::Unserialize(KBEngine::MemoryStream& stream)
{
	stream >> CD;
	stream >> Rate;
	KBE_ASSERT(SkillFishAsset.empty());
	uint8_t size = stream.readUint8();
	for (uint8_t i = 0; i < size; ++i)
	{
		USkillFishAsset* item = new USkillFishAsset();
		item->Unserialize(stream);
		SkillFishAsset.push_back(item);
	}
}