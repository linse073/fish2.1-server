#ifndef __ACOS_LOOKUP_TABLE_H__
#define __ACOS_LOOKUP_TABLE_H__

#include <stdint.h>

struct AcosLookupTable
{
	static const int32_t COUNT;

	static const int32_t HALF_COUNT;

	static const int32_t table[];
};

#endif // __ACOS_LOOKUP_TABLE_H__