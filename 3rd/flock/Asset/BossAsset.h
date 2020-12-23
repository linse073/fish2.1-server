#ifndef __BOSS_ASSET_H__
#define __BOSS_ASSET_H__

#include <vector>
#include <stdint.h>

namespace KBEngine
{
	class MemoryStream;
}
class USkillAsset;

class UBossAsset
{
public:
	~UBossAsset();

	uint32_t ID = 0;
	uint32_t BornStep = 0;
	uint32_t LiveStep = 1000;
	uint32_t BornCD = 100;
	uint32_t SwimCD = 100;
	uint32_t IdleCD = 100;
	uint32_t DieCD = 100;
	std::vector<USkillAsset*> SkillAsset;

	void Serialize(KBEngine::MemoryStream& stream);
	void Unserialize(KBEngine::MemoryStream& stream);
};

#endif // __BOSS_ASSET_H__