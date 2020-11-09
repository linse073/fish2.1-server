#ifndef __FLOCK_SPHERE_H__
#define __FLOCK_SPHERE_H__

#include "FlockShap.h"

class AFlockAgent;

class FlockSphere : public FlockShap
{
public:
	FlockSphere(const VInt3& center, int32_t radius);

	virtual VInt3 CalcMove(const AFlockAgent& agent);
	virtual bool InSphere(const VInt3& sphereCenter, int32_t radius);

	void SetCenter(const VInt3& center);

private:
	VInt3 center_;
	int32_t radius_;
};

#endif // __FLOCK_SPHERE_H__