#include "FlockSphere.h"
#include "FlockAgent.h"
#include "FishAsset.h"

FlockSphere::FlockSphere(const VInt3& center, int32_t radius)
	:center_(center),
	radius_(radius)
{
}

VInt3 FlockSphere::CalcMove(const AFlockAgent& agent)
{
	VInt3 dis = agent.GetPos() - center_;
	if (dis.magnitude() <= agent.GetAvoidanceRadius() + radius_)
	{
		return dis;
	}
	return VInt3::zero;
}

bool FlockSphere::InSphere(const VInt3& sphereCenter, int32_t radius)
{
	VInt3 dis = center_ - sphereCenter;
	return dis.magnitude() <= radius + radius_;
}

void FlockSphere::SetCenter(const VInt3& center)
{
	center_ = center;
}