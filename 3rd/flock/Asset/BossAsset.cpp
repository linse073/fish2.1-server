#include "BossAsset.h"
#include "MemoryStream.h"
#include "SkillAsset.h"

UBossAsset::~UBossAsset()
{
	for (auto& item : SkillAsset)
		KBE_SAFE_RELEASE(item);
	SkillAsset.clear();	
}

void UBossAsset::Serialize(KBEngine::MemoryStream& stream)
{
	stream << ID;
	stream << BornStep;
	stream << LiveStep;
	stream << BornCD;
	stream << SwimCD;
	stream << IdleCD;
	stream << DieCD;
	stream << (uint8_t)SkillAsset.size();
	for (auto& item : SkillAsset)
		item->Serialize(stream);
}

void UBossAsset::Unserialize(KBEngine::MemoryStream& stream)
{
	stream >> ID;
	stream >> BornStep;
	stream >> LiveStep;
	stream >> BornCD;
	stream >> SwimCD;
	stream >> IdleCD;
	stream >> DieCD;
	KBE_ASSERT(SkillAsset.empty());
	uint8_t size = stream.readUint8();
	for (uint8_t i = 0; i < size; ++i)
	{
		USkillAsset* item = new USkillAsset();
		item->Unserialize(stream);
		SkillAsset.push_back(item);
	}
}