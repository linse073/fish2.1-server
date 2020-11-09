#ifndef __ATAN2_LOOKUP_TABLE_H__
#define __ATAN2_LOOKUP_TABLE_H__

#include <stdint.h>

struct Atan2LookupTable
{
	static const int32_t BITS;

	static const int32_t BITS2;

	static const int32_t MASK;

	static const int32_t COUNT;

	static const int32_t DIM;

	static const int32_t table[];
};

#endif // __ATAN2_LOOKUP_TABLE_H__