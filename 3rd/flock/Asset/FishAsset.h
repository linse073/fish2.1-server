#ifndef __FISH_ASSET_H__
#define __FISH_ASSET_H__

#include <stdint.h>
#include "MemoryStream.h"

class UFishAsset
{
public:
	uint32_t ID;
	int32_t DriveFactor;
	int32_t MaxSpeed;
	int32_t NeighborRadius;
	int32_t AvoidanceRadius;
	uint8_t FlockCamp;

	void Serialize(KBEngine::MemoryStream& stream)
	{
		stream << ID;
		stream << DriveFactor;
		stream << MaxSpeed;
		stream << NeighborRadius;
		stream << AvoidanceRadius;
		stream << FlockCamp;
	}

	void Unserialize(KBEngine::MemoryStream& stream)
	{
		stream >> ID;
		stream >> DriveFactor;
		stream >> MaxSpeed;
		stream >> NeighborRadius;
		stream >> AvoidanceRadius;
		stream >> FlockCamp;
	}
};

#endif // __FISH_ASSET_H__
