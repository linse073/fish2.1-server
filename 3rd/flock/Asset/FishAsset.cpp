#include "FishAsset.h"
#include "MemoryStream.h"

void UFishAsset::Serialize(KBEngine::MemoryStream& stream)
{
	stream << ID;
	stream << DriveFactor;
	stream << MaxSpeed;
	stream << NeighborRadius;
	stream << AvoidanceRadius;
	stream << VisionRadius;
	stream << FlockCamp;
}

void UFishAsset::Unserialize(KBEngine::MemoryStream& stream)
{
	stream >> ID;
	stream >> DriveFactor;
	stream >> MaxSpeed;
	stream >> NeighborRadius;
	stream >> AvoidanceRadius;
	stream >> VisionRadius;
	stream >> FlockCamp;
}