#ifndef __VINT_H__
#define __VINT_H__

#include <stdint.h>
#include "Math.h"

struct VInt
{
	int32_t i;

	float scalar() const
	{
		return (float)i * 0.001f;
	}

	VInt(int32_t _i) : i(_i)
	{
	}

	VInt(float f) : i((int32_t)Math::Round((double)(f * 1000.f)))
	{
	}

	VInt() : i(0)
	{
	}

	int32_t GetHashCode() const
	{
		return i;
	}

	static VInt Min(const VInt& a, const VInt& b)
	{
		return VInt(Math::Min(a.i, b.i));
	}

	static VInt Max(const VInt& a, const VInt& b)
	{
		return VInt(Math::Max(a.i, b.i));
	}

	// string ToString()
	// {
	// 	return scalar.ToString();
	// }

	operator float() const
	{
		return (float)i * 0.001f;
	}

	operator int64_t() const
	{
		return (int64_t)i;
	}

	VInt operator +(const VInt& b) const
	{
		return VInt(i + b.i);
	}

	VInt operator -(const VInt& b) const
	{
		return VInt(i - b.i);
	}

	bool operator ==(const VInt& b) const
	{
		return i == b.i;
	}

	bool operator !=(const VInt& b) const
	{
		return i != b.i;
	}
};

#endif // __VINT_H__