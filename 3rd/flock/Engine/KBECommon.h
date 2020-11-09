#ifndef __KBE_COMMON_H__
#define __KBE_COMMON_H__

#include <cassert>

#define KBE_ASSERT assert

/** 安全的释放一个指针内存 */
#define KBE_SAFE_RELEASE(i)									\
	if (i)													\
		{													\
			delete i;										\
			i = NULL;										\
		}

/** 安全的释放一个指针数组内存 */
#define KBE_SAFE_RELEASE_ARRAY(i)							\
	if (i)													\
		{													\
			delete[] i;										\
			i = NULL;										\
		}

#define MAX_USER 4

#endif // __KBE_COMMON_H__