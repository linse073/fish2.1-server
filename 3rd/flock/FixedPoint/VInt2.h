#ifndef __VINT2_H__
#define __VINT2_H__

#include "Math.h"
#include "VFactor.h"

struct VInt2
{
    int32_t x;

    int32_t y;

    static const VInt2 zero;

    static const int32_t Rotations[];

    int32_t sqrMagnitude() const
    {
        return (int32_t)sqrMagnitudeLong();
    }

    int64_t sqrMagnitudeLong() const
    {
        int64_t num = (int64_t)x;
        int64_t num2 = (int64_t)y;
        return num * num + num2 * num2;
    }

    int32_t magnitude() const;

    VInt2 normalized() const
    {
        VInt2 result = VInt2(x, y);
        result.Normalize();
        return result;
    }

    VInt2(int32_t _x, int32_t _y) : x(_x), y(_y)
    {
    }

	VInt2() : x(0), y(0)
	{
	}

    static int32_t Dot(const VInt2& a, const VInt2& b)
    {
        return (int32_t)((int64_t)a.x * (int64_t)b.x + (int64_t)a.y * (int64_t)b.y);
    }

    static int64_t DotLong(const VInt2& a, const VInt2& b)
    {
        return (int64_t)a.x * (int64_t)b.x + (int64_t)a.y * (int64_t)b.y;
    }

    static int64_t DetLong(const VInt2& a, const VInt2& b)
    {
        return (int64_t)a.x * (int64_t)b.y - (int64_t)a.y * (int64_t)b.x;
    }

    int32_t GetHashCode() const
    {
        return x * 49157 + y * 98317;
    }

    static VInt2 Rotate(const VInt2& v, int32_t r)
    {
        r %= 4;
        return VInt2(v.x * Rotations[r * 4] + v.y * Rotations[r * 4 + 1], v.x * Rotations[r * 4 + 2] + v.y * Rotations[r * 4 + 3]);
    }

    static VInt2 Min(const VInt2& a, const VInt2& b)
    {
        return VInt2(Math::Min(a.x, b.x), Math::Min(a.y, b.y));
    }

    static VInt2 Max(const VInt2& a, const VInt2& b)
    {
        return VInt2(Math::Max(a.x, b.x), Math::Max(a.y, b.y));
    }

    // string ToString()
    // {
    //     return string.Concat(object[]
    //     {
    //         "(",
    //         x,
    //         ", ",
    //         y,
    //         ")"
    //     });
    // }

    void Min(const VInt2& r)
    {
        x = Math::Min(x, r.x);
        y = Math::Min(y, r.y);
    }

    void Max(const VInt2& r)
    {
        x = Math::Max(x, r.x);
        y = Math::Max(y, r.y);
    }

    void Normalize();
	void NormalizeTo(int32_t newMagn);

    static VInt2 ClampMagnitude(const VInt2& v, int32_t maxLength);

    VInt2 operator +(const VInt2& b) const
    {
        return VInt2(x + b.x, y + b.y);
    }

    VInt2 operator -(const VInt2& b) const
    {
        return VInt2(x - b.x, y - b.y);
    }

    bool operator ==(const VInt2& b) const
    {
        return x == b.x && y == b.y;
    }

    bool operator !=(const VInt2& b) const
    {
        return x != b.x || y != b.y;
    }

    VInt2 operator -() const
    {
        return VInt2(-x, -y);
    }

    VInt2 operator *(int32_t rhs) const
    {
        return VInt2(x * rhs, y * rhs);
    }

    VInt2 operator *(const VFactor& f) const;

    VInt2 operator /(const VFactor& f) const;
};

#endif // __VINT2_H__