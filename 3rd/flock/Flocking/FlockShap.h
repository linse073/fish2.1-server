#ifndef __FLOCK_SHAP_H__
#define __FLOCK_SHAP_H__

#include "VInt3.h"

class AFlockAgent;

class FlockShap
{
public:
	virtual ~FlockShap() {}

	virtual VInt3 CalcMove(const AFlockAgent& agent) = 0;
	virtual bool InSphere(const VInt3& sphereCenter, int32_t radius) = 0;
};

#endif // __FLOCK_SHAP_H__