#ifndef __CONTEXT_FILTER_H__
#define __CONTEXT_FILTER_H__

#include <vector>
#include "VInt3.h"

class AFlockAgent;
class FlockShap;
class Flock;

class ContextFilter
{
public:
	ContextFilter(const Flock* flock, const AFlockAgent& agent, const std::vector<AFlockAgent*>& context, const std::vector<FlockShap*>& obstacle);

	const std::vector<AFlockAgent*>& getNeighbor() const;
	const std::vector<AFlockAgent*>& getAvoidance() const;
	const std::vector<FlockShap*>& getObstacle() const;
	const VInt3& getSphereCenter() const;
	int32_t getSphereRadius() const;
	int32_t getRotationDegreesPerStep() const;
	int32_t getFlockRotationDegreesPerStep() const;

private:
	std::vector<AFlockAgent*> neighbor_;
	std::vector<AFlockAgent*> avoidance_;
	std::vector<FlockShap*> obstacle_;
	const Flock* flock_;
};

#endif // __CONTEXT_FILTER_H__