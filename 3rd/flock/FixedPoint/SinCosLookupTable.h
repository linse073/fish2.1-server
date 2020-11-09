#ifndef __SINCOS_LOOKUP_TABLE_H__
#define __SINCOS_LOOKUP_TABLE_H__

#include <stdint.h>

struct SinCosLookupTable
{
	static const int32_t BITS;

	static const int32_t MASK;

	static const int32_t COUNT;

	static const int32_t FACTOR;

	static const int32_t NOM_MUL;

	static const int32_t sin_table[];

	static const int32_t cos_table[];

	static int32_t getIndex(int64_t nom, int64_t den)
	{
		nom *= (int64_t)NOM_MUL;
		den *= 62832LL;
		int32_t num = (int32_t)(nom / den);
		return num & MASK;
	}
};

#endif // __SINCOS_LOOKUP_TABLE_H__