#ifndef __VINT3_H__
#define __VINT3_H__

#include "StdMath.h"
#include "VFactor.h"
#include "VInt2.h"

struct VInt3
{
    static const int32_t Precision = 1000;

    static const float FloatPrecision;

    static const float PrecisionFactor;

    int32_t x;

    int32_t y;

    int32_t z;

    static const VInt3 zero;

    static const VInt3 one;

    static const VInt3 half;

    static const VInt3 forward;

    static const VInt3 up;

    static const VInt3 right;

    int32_t& operator [](int32_t i)
    {
        return (i != 0) ? ((i != 1) ? z : y) : x;
    }

    const int32_t& operator [](int32_t i) const
    {
        return (i != 0) ? ((i != 1) ? z : y) : x;
    }

    VInt2 xz() const
    {
        return VInt2(x, z);
    }

    int32_t magnitude() const;

    int32_t magnitude2D() const;

    int32_t costMagnitude() const
    {
        return magnitude();
    }

    float worldMagnitude() const
    {
        double num = (double)x;
        double num2 = (double)y;
        double num3 = (double)z;
        return (float)StdMath::Sqrt(num * num + num2 * num2 + num3 * num3) * 0.001f;
    }

    double sqrMagnitude() const
    {
        double num = (double)x;
        double num2 = (double)y;
        double num3 = (double)z;
        return num * num + num2 * num2 + num3 * num3;
    }

    int64_t sqrMagnitudeLong() const
    {
        int64_t num = (int64_t)x;
        int64_t num2 = (int64_t)y;
        int64_t num3 = (int64_t)z;
        return num * num + num2 * num2 + num3 * num3;
    }

    int64_t sqrMagnitudeLong2D() const
    {
        int64_t num = (int64_t)x;
        int64_t num2 = (int64_t)z;
        return num * num + num2 * num2;
    }

    int32_t unsafeSqrMagnitude() const
    {
		return (int32_t)sqrMagnitudeLong();
    }

    VInt3 abs() const
    {
        return VInt3(StdMath::Abs(x), StdMath::Abs(y), StdMath::Abs(z));
    }

    // [Obsolete("Same implementation as .magnitude")]
    float safeMagnitude() const
    {
        double num = (double)x;
        double num2 = (double)y;
        double num3 = (double)z;
        return (float)StdMath::Sqrt(num * num + num2 * num2 + num3 * num3);
    }

    // [Obsolete(".sqrMagnitude is now per default safe (.unsafeSqrMagnitude can be used for unsafe operations)")]
    float safeSqrMagnitude() const
    {
        float num = (float)x * 0.001f;
        float num2 = (float)y * 0.001f;
        float num3 = (float)z * 0.001f;
        return num * num + num2 * num2 + num3 * num3;
    }

    VInt3(int32_t _x, int32_t _y, int32_t _z) : x(_x), y(_y), z(_z)
    {
    }

	VInt3() : x(0), y(0), z(0)
	{
	}

    VInt3 DivBy2()
    {
        x >>= 1;
        y >>= 1;
        z >>= 1;
        return *this;
    }

    static float Angle(const VInt3& lhs, const VInt3& rhs)
    {
        // double num = (double)Dot(lhs, rhs) / ((double)lhs.magnitude() * (double)rhs.magnitude());
		double num = (double)DotLong(lhs, rhs) / ((double)lhs.magnitude() * (double)rhs.magnitude());
        num = ((num >= -1.0) ? ((num <= 1.0) ? num : 1.0) : -1.0);
        return (float)StdMath::Acos(num);
    }

    static VFactor AngleInt(const VInt3& lhs, const VInt3& rhs);

    static int32_t Dot(const VInt3& lhs, const VInt3& rhs)
    {
        return (int32_t)((int64_t)lhs.x * (int64_t)rhs.x + (int64_t)lhs.y * (int64_t)rhs.y + (int64_t)lhs.z * (int64_t)rhs.z);
    }

    static int64_t DotLong(const VInt3& lhs, const VInt3& rhs)
    {
        return (int64_t)lhs.x * (int64_t)rhs.x + (int64_t)lhs.y * (int64_t)rhs.y + (int64_t)lhs.z * (int64_t)rhs.z;
    }

    static int64_t DotXZLong(const VInt3& lhs, const VInt3& rhs)
    {
        return (int64_t)lhs.x * (int64_t)rhs.x + (int64_t)lhs.z * (int64_t)rhs.z;
    }

    static VInt3 Cross(const VInt3& lhs, const VInt3& rhs);

    static VInt3 MoveTowards(const VInt3& from, const VInt3& to, int32_t dt)
    {
        if ((to - from).sqrMagnitudeLong() <= (int64_t)(dt * dt))
        {
            return to;
        }
        return from + (to - from).NormalizeTo(dt);
    }

    VInt3 Normal2D() const
    {
        return VInt3(z, y, -x);
    }

    VInt3 NormalizeTo(int32_t newMagn);

    int64_t Normalize();

    VInt3 RotateY(const VFactor& radians) const;

    VInt3 RotateY(int32_t degree) const;

    // string ToString()
    // {
    //     return string.Concat(object[]
    //     {
    //         "( ",
    //         x,
    //         ", ",
    //         y,
    //         ", ",
    //         z,
    //         ")"
    //     });
    // }

    int32_t GetHashCode() const
    {
        return x * 73856093 ^ y * 19349663 ^ z * 83492791;
    }

    static VInt3 Lerp(const VInt3& a, const VInt3& b, float f)
    {
        return VInt3(StdMath::RoundToInt((float)a.x * (1.f - f)) + StdMath::RoundToInt((float)b.x * f), StdMath::RoundToInt((float)a.y * (1.f - f)) + StdMath::RoundToInt((float)b.y * f), StdMath::RoundToInt((float)a.z * (1.f - f)) + StdMath::RoundToInt((float)b.z * f));
    }

    static VInt3 Lerp(const VInt3& a, const VInt3& b, const VFactor& f);

    static VInt3 Lerp(const VInt3& a, const VInt3& b, int32_t factorNom, int32_t factorDen);

    int64_t XZSqrMagnitude(const VInt3& rhs) const
    {
        int64_t num = (int64_t)(x - rhs.x);
        int64_t num2 = (int64_t)(z - rhs.z);
        return num * num + num2 * num2;
    }

    bool IsEqualXZ(const VInt3& rhs) const
    {
        return x == rhs.x && z == rhs.z;
    }

    bool operator ==(const VInt3& rhs) const
    {
        return x == rhs.x && y == rhs.y && z == rhs.z;
    }

    bool operator !=(const VInt3& rhs) const
    {
        return x != rhs.x || y != rhs.y || z != rhs.z;
    }

    VInt3 operator -(const VInt3& rhs) const
    {
        return VInt3(x - rhs.x, y - rhs.y, z - rhs.z);
    }

    VInt3 operator -() const
    {
        return VInt3(-x, -y, -z);
    }

    VInt3 operator +(const VInt3& rhs) const
    {
        return VInt3(x + rhs.x, y + rhs.y, z + rhs.z);
    }

    VInt3 operator *(int32_t rhs) const
    {
        return VInt3(x * rhs, y * rhs, z * rhs);
    }

    VInt3 operator *(float rhs) const
    {
        int32_t _x = (int32_t)StdMath::Round((double)((float)x * rhs));
        int32_t _y = (int32_t)StdMath::Round((double)((float)y * rhs));
        int32_t _z = (int32_t)StdMath::Round((double)((float)z * rhs));
        return VInt3(_x, _y, _z);
    }

    VInt3 operator *(double rhs) const
    {
        int32_t _x = (int32_t)StdMath::Round((double)x * rhs);
        int32_t _y = (int32_t)StdMath::Round((double)y * rhs);
        int32_t _z = (int32_t)StdMath::Round((double)z * rhs);
        return VInt3(_x, _y, _z);
    }

	VInt3 operator *(const VInt3& rhs) const;

    VInt3 operator /(float rhs) const
    {
        int32_t _x = (int32_t)StdMath::Round((double)((float)x / rhs));
        int32_t _y = (int32_t)StdMath::Round((double)((float)y / rhs));
        int32_t _z = (int32_t)StdMath::Round((double)((float)z / rhs));
        return VInt3(_x, _y, _z);
    }

	VInt3 operator /(int32_t rhs) const
	{
		int32_t _x = x / rhs;
		int32_t _y = y / rhs;
		int32_t _z = z / rhs;
		return VInt3(_x, _y, _z);
	}

    VInt3 operator *(const VFactor& f) const;

    VInt3 operator /(const VFactor& f) const;

    // static implicit operator string(VInt3 ob)
    // {
    //     return ob.ToString();
    // }

    // NOTICE: ͷ�ļ��������⣬�������ط�ʵ�֣�ԭ����VInt2��
    static VInt2 FromInt3XZ(const VInt3& o)
    {
        return VInt2(o.x, o.z);
    }

    static VInt3 ToInt3XZ(const VInt2& o)
    {
        return VInt3(o.x, 0, o.y);
    }
};

#endif // __VINT3_H__