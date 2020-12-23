#ifndef __SKILL_ASSET_H__
#define __SKILL_ASSET_H__

#include <vector>
#include <stdint.h>

namespace KBEngine
{
	class MemoryStream;
}
class UNewFishAsset;

class USkillFishAsset
{
public:
	~USkillFishAsset();

	uint32_t Step = 0;
	int32_t PosX = 0;
	int32_t PosY = 0;
	int32_t PosZ = 0;
	UNewFishAsset* NewFishAsset;

	void Serialize(KBEngine::MemoryStream& stream);
	void Unserialize(KBEngine::MemoryStream& stream);
};

class USkillAsset
{
public:
	~USkillAsset();

	int32_t index = 0;
	uint32_t CD = 100;
	uint32_t Rate = 100;
	std::vector<USkillFishAsset*> SkillFishAsset;

	void Serialize(KBEngine::MemoryStream& stream);
	void Unserialize(KBEngine::MemoryStream& stream);
};

#endif // __SKILL_ASSET_H__