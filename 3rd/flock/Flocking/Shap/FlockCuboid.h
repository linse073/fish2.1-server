#ifndef __FLOCK_CUBOID_H__
#define __FLOCK_CUBOID_H__

#include "FlockShap.h"

class FlockCuboid : public FlockShap
{
public:
	FlockCuboid(const VInt3& center, int32_t l, int32_t w, int32_t h);

	virtual VInt3 CalcMove(const AFlockAgent& agent);
	virtual bool InSphere(const VInt3& sphereCenter, int32_t radius);

private:
	VInt3 center_;
	int32_t l_;
	int32_t w_;
	int32_t h_;
};

#endif // __FLOCK_CUBOID_H__