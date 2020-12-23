#ifndef __FISH_ASSET_H__
#define __FISH_ASSET_H__

#include <stdint.h>

namespace KBEngine
{
	class MemoryStream;
}

class UFishAsset
{
public:
	uint32_t ID;
	int32_t DriveFactor;
	int32_t MaxSpeed;
	int32_t NeighborRadius;
	int32_t AvoidanceRadius;
	int32_t VisionRadius;
	uint8_t FlockCamp;

	void Serialize(KBEngine::MemoryStream& stream);
	void Unserialize(KBEngine::MemoryStream& stream);
};

#endif // __FISH_ASSET_H__
