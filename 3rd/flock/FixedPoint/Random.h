#ifndef __RANDOM_H__
#define __RANDOM_H__

#include <stdint.h>
#include "KBECommon.h"

class Random
{
private:
	static const uint64_t multiper = 1194211693uLL;
	static const uint64_t addValue = 12345uLL;
	static uint64_t seed_;

public:
	static uint64_t GetSeed()
	{
		return seed_;
	}

	static void SetSeed(uint64_t seed)
	{
		seed_ = seed;
	}

	static uint32_t Next()
	{
		seed_ = seed_ * multiper + addValue;
		return (uint32_t)(seed_ >> 16);
	}

	static uint32_t Next(uint32_t max)
	{
		if (max == 0u)
			return 0u;
		return Next() % max;
	}

	static int32_t Next(int32_t max)
	{
		if (max == 0)
			return 0;
		return (int32_t)(Next() % max);
	}

	static uint32_t Range(uint32_t min, uint32_t max)
	{
		if (min == max)
			return max;
		KBE_ASSERT(max > min);
		uint32_t num = max - min;
		return Next(num) + min;
	}

	static int32_t Range(int32_t min, int32_t max)
	{
		if (min == max)
			return max;
		KBE_ASSERT(max > min);
		int num = max - min;
		return Next(num) + min;
	}
};

#endif // __RANDOM_H__