#include "FlockCuboid.h"
#include "FlockAgent.h"
#include "FishAsset.h"
#include "MemoryStream.h"

FlockCuboid::FlockCuboid(const VInt3& center, int32_t l, int32_t w, int32_t h)
	:center_(center),
	l_(l), w_(w), h_(h)
{
}

VInt3 FlockCuboid::CalcMove(const AFlockAgent& agent)
{
	VInt3 dis = agent.GetPos() - center_;
	if (StdMath::Abs(dis.x) <= agent.GetVisionRadius() + l_
		&& StdMath::Abs(dis.y) <= agent.GetVisionRadius() + w_
		&& StdMath::Abs(dis.z) <= agent.GetVisionRadius() + h_)
	{
		return dis;
	}
	return VInt3::zero;
}

bool FlockCuboid::InSphere(const VInt3& sphereCenter, int32_t radius)
{
	VInt3 dis = center_ - sphereCenter;
	return StdMath::Abs(dis.x) <= radius + l_
		&& StdMath::Abs(dis.y) <= radius + w_
		&& StdMath::Abs(dis.z) <= radius + h_;
}