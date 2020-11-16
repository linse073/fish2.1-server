#ifndef __INT_MATH_H__
#define __INT_MATH_H__

#include "VInt4.h"
#include "Atan2LookupTable.h"
#include "AcosLookupTable.h"
#include "SinCosLookupTable.h"
#include "Random.h"

struct IntMath
{
	// TODO: there is ploblem if y==0 and x==0
	static VFactor atan2(int32_t y, int32_t x)
	{
		int32_t num;
		int32_t num2;
		if (x < 0)
		{
			if (y < 0)
			{
				x = -x;
				y = -y;
				num = 1;
			}
			else
			{
				x = -x;
				num = -1;
			}
			num2 = -31416;
		}
		else
		{
			if (y < 0)
			{
				y = -y;
				num = -1;
			}
			else
			{
				num = 1;
			}
			num2 = 0;
		}
		int32_t dIM = Atan2LookupTable::DIM;
		int64_t num3 = (int64_t)(dIM - 1);
		int64_t b = (int64_t)((x >= y) ? x : y);
		int32_t num4 = (int32_t)Divide((int64_t)x * num3, b);
		int32_t num5 = (int32_t)Divide((int64_t)y * num3, b);
		int32_t num6 = Atan2LookupTable::table[num5 * dIM + num4];
		return VFactor((int64_t)(num6 + num2) * (int64_t)num, 10000LL);
	}

	static VFactor acos(int64_t nom, int64_t den)
	{
		int32_t num = (int32_t)Divide(nom * (int64_t)AcosLookupTable::HALF_COUNT, den) + AcosLookupTable::HALF_COUNT;
		num = StdMath::Clamp(num, 0, AcosLookupTable::COUNT);
		return VFactor((int64_t)AcosLookupTable::table[num], 10000LL);
	}

	static VFactor sin(int64_t nom, int64_t den)
	{
		int32_t index = SinCosLookupTable::getIndex(nom, den);
		return VFactor((int64_t)SinCosLookupTable::sin_table[index], (int64_t)SinCosLookupTable::FACTOR);
	}

	static VFactor cos(int64_t nom, int64_t den)
	{
		int32_t index = SinCosLookupTable::getIndex(nom, den);
		return VFactor((int64_t)SinCosLookupTable::cos_table[index], (int64_t)SinCosLookupTable::FACTOR);
	}

	static void sincos(VFactor& s, VFactor& c, int64_t nom, int64_t den)
	{
		int32_t index = SinCosLookupTable::getIndex(nom, den);
		s = VFactor((int64_t)SinCosLookupTable::sin_table[index], (int64_t)SinCosLookupTable::FACTOR);
		c = VFactor((int64_t)SinCosLookupTable::cos_table[index], (int64_t)SinCosLookupTable::FACTOR);
	}

	static void sincos(VFactor& s, VFactor& c, const VFactor& angle)
	{
		int32_t index = SinCosLookupTable::getIndex(angle.nom, angle.den);
		s = VFactor((int64_t)SinCosLookupTable::sin_table[index], (int64_t)SinCosLookupTable::FACTOR);
		c = VFactor((int64_t)SinCosLookupTable::cos_table[index], (int64_t)SinCosLookupTable::FACTOR);
	}

	static int64_t Divide(int64_t a, int64_t b)
	{
		//int64_t num = (int64_t)((uint64_t)((a ^ b) & -9223372036854775808LL) >> 63);
		int64_t num = (int64_t)((uint64_t)((a ^ b) & 0xffffffffffffffffuLL) >> 63);
		int64_t num2 = num * -2LL + 1LL;
		return (a + b / 2LL * num2) / b;
	}

	static int32_t Divide(int32_t a, int32_t b)
	{
		//int32_t num = (int32_t)((uint32_t)((a ^ b) & -2147483648) >> 31);
		int32_t num = (int32_t)((uint32_t)((a ^ b) & 0xffffffffu) >> 31);
		int32_t num2 = num * -2 + 1;
		return (a + b / 2 * num2) / b;
	}

	static VInt3 Divide(const VInt3& a, int64_t m, int64_t b)
	{
		return VInt3((int32_t)Divide((int64_t)a.x * m, b), (int32_t)Divide((int64_t)a.y * m, b), (int32_t)Divide((int64_t)a.z * m, b));
	}

	static VInt2 Divide(const VInt2& a, int64_t m, int64_t b)
	{
		return VInt2((int32_t)Divide((int64_t)a.x * m, b), (int32_t)Divide((int64_t)a.y * m, b));
	}

	static VInt3 Divide(const VInt3& a, int32_t b)
	{
		return VInt3(Divide(a.x, b), Divide(a.y, b), Divide(a.z, b));
	}

	static VInt3 Divide(const VInt3& a, int64_t b)
	{
		return VInt3((int32_t)Divide((int64_t)a.x, b), (int32_t)Divide((int64_t)a.y, b), (int32_t)Divide((int64_t)a.z, b));
	}

	static VInt2 Divide(const VInt2& a, int64_t b)
	{
		return VInt2((int32_t)Divide((int64_t)a.x, b), (int32_t)Divide((int64_t)a.y, b));
	}

	static uint32_t Sqrt32(uint32_t a)
	{
		uint32_t num = 0u;
		uint32_t num2 = 0u;
		for (int32_t i = 0; i < 16; i++)
		{
			num2 <<= 1;
			num <<= 2;
			num += a >> 30;
			a <<= 2;
			if (num2 < num)
			{
				num2 += 1u;
				num -= num2;
				num2 += 1u;
			}
		}
		return num2 >> 1 & 65535u;
	}

	static uint64_t Sqrt64(uint64_t a)
	{
		uint64_t num = 0uLL;
		uint64_t num2 = 0uLL;
		for (int32_t i = 0; i < 32; i++)
		{
			num2 <<= 1;
			num <<= 2;
			num += a >> 62;
			a <<= 2;
			if (num2 < num)
			{
				num2 += 1uLL;
				num -= num2;
				num2 += 1uLL;
			}
        }
        return num2 >> 1 & 0xffffffffu;
    }

    static int64_t SqrtLong(int64_t a)
	{
		if (a <= 0LL)
		{
			return 0LL;
		}
		if (a <= (int64_t)(0xffffffffu))
		{
			return (int64_t)((uint64_t)Sqrt32((uint32_t)a));
		}
		return (int64_t)Sqrt64((uint64_t)a);
	}

	static int32_t Sqrt(int64_t a)
	{
		if (a <= 0LL)
		{
			return 0;
		}
		if (a <= (int64_t)(0xffffffffu))
		{
			return (int32_t)Sqrt32((uint32_t)a);
		}
		return (int32_t)Sqrt64((uint64_t)a);
	}

	static int64_t Clamp(int64_t a, int64_t min, int64_t max)
	{
		if (a < min)
		{
			return min;
		}
		if (a > max)
		{
			return max;
		}
		return a;
	}

	static VFactor Clamp(VFactor a, VFactor min, VFactor max)
	{
		if (a < min)
		{
			return min;
		}
		if (a > max)
		{
			return max;
		}
		return a;
	}

	static int64_t Max(int64_t a, int64_t b)
	{
		return (a <= b) ? b : a;
	}

	static VInt3 Transform(const VInt3& point, const VInt3& axis_x, const VInt3& axis_y, const VInt3& axis_z, const VInt3& trans)
	{
		return VInt3((int32_t)Divide((int64_t)axis_x.x * (int64_t)point.x + (int64_t)axis_y.x * (int64_t)point.y + (int64_t)axis_z.x * (int64_t)point.z, 1000LL) + trans.x,
			(int32_t)Divide((int64_t)axis_x.y * (int64_t)point.x + (int64_t)axis_y.y * (int64_t)point.y + (int64_t)axis_z.y * (int64_t)point.z, 1000LL) + trans.y,
			(int32_t)Divide((int64_t)axis_x.z * (int64_t)point.x + (int64_t)axis_y.z * (int64_t)point.y + (int64_t)axis_z.z * (int64_t)point.z, 1000LL) + trans.z);
	}

	static VInt3 Transform(const VInt3& point, const VInt3& axis_x, const VInt3& axis_y, const VInt3& axis_z, const VInt3& trans, const VInt3& scale)
	{
		int64_t num = (int64_t)point.x * (int64_t)scale.x;
		int64_t num2 = (int64_t)point.y * (int64_t)scale.x;
		int64_t num3 = (int64_t)point.z * (int64_t)scale.x;
		return VInt3((int32_t)Divide((int64_t)axis_x.x * num + (int64_t)axis_y.x * num2 + (int64_t)axis_z.x * num3, 1000000LL) + trans.x, (int32_t)Divide((int64_t)axis_x.y * num + (int64_t)axis_y.y * num2 + (int64_t)axis_z.y * num3, 1000000LL) + trans.y, (int32_t)Divide((int64_t)axis_x.z * num + (int64_t)axis_y.z * num2 + (int64_t)axis_z.z * num3, 1000000LL) + trans.z);
	}

	static VInt3 Transform(const VInt3& point, const VInt3& forward, const VInt3& trans)
	{
		VInt3 up = VInt3::up;
		VInt3 vInt = VInt3::Cross(VInt3::up, forward);
		return Transform(point, vInt, up, forward, trans);
	}

	static VInt3 Transform(const VInt3& point, const VInt3& forward, const VInt3& trans, const VInt3& scale)
	{
		VInt3 up = VInt3::up;
		VInt3 vInt = VInt3::Cross(VInt3::up, forward);
		return Transform(point, vInt, up, forward, trans, scale);
	}

	static int32_t Lerp(int32_t src, int32_t dest, int32_t nom, int32_t den)
	{
		return Divide(src * den + (dest - src) * nom, den);
	}

	static int64_t Lerp(int64_t src, int64_t dest, int64_t nom, int64_t den)
	{
		return Divide(src * den + (dest - src) * nom, den);
	}

	static bool IsPowerOfTwo(int32_t x)
	{
		return (x & (x - 1)) == 0;
	}

	static int32_t CeilPowerOfTwo(int32_t x)
	{
		x--;
		x |= x >> 1;
		x |= x >> 2;
		x |= x >> 4;
		x |= x >> 8;
		x |= x >> 16;
		x++;
		return x;
	}

	static void SegvecToLinegen(const VInt2& segSrc, const VInt2& segVec, int64_t& a, int64_t& b, int64_t& c)
	{
		a = (int64_t)segVec.y;
		b = -(int64_t)segVec.x;
		c = (int64_t)segVec.x * (int64_t)segSrc.y - (int64_t)segSrc.x * (int64_t)segVec.y;
	}

	static bool IsPointOnSegment(const VInt2& segSrc, const VInt2& segVec, int64_t x, int64_t y)
	{
		int64_t num = x - (int64_t)segSrc.x;
		int64_t num2 = y - (int64_t)segSrc.y;
		return (int64_t)segVec.x * num + (int64_t)segVec.y * num2 >= 0LL && num * num + num2 * num2 <= segVec.sqrMagnitudeLong();
	}

	static bool IntersectSegment(const VInt2& seg1Src, const VInt2& seg1Vec, const VInt2& seg2Src, const VInt2& seg2Vec, VInt2& interPoint)
	{
		int64_t num;
		int64_t num2;
		int64_t num3;
		SegvecToLinegen(seg1Src, seg1Vec, num, num2, num3);
		int64_t num4;
		int64_t num5;
		int64_t num6;
		SegvecToLinegen(seg2Src, seg2Vec, num4, num5, num6);
		int64_t num7 = num * num5 - num4 * num2;
		if (num7 != 0LL)
		{
			int64_t num8 = Divide(num2 * num6 - num5 * num3, num7);
			int64_t num9 = Divide(num4 * num3 - num * num6, num7);
			bool result = IsPointOnSegment(seg1Src, seg1Vec, num8, num9) && IsPointOnSegment(seg2Src, seg2Vec, num8, num9);
			interPoint.x = (int32_t)num8;
			interPoint.y = (int32_t)num9;
			return result;
		}
		interPoint = VInt2::zero;
		return false;
	}

	static bool PointInPolygon(const VInt2& pnt, const VInt2 plg[], int32_t length)
	{
		if (plg == nullptr || length < 3)
		{
			return false;
		}
		bool flag = false;
		int32_t i = 0;
		int32_t num = length - 1;
		while (i < length)
		{
			VInt2 vInt = plg[i];
			VInt2 vInt2 = plg[num];
			if ((vInt.y <= pnt.y && pnt.y < vInt2.y) || (vInt2.y <= pnt.y && pnt.y < vInt.y))
			{
				int32_t num2 = vInt2.y - vInt.y;
				int64_t num3 = (int64_t)(pnt.y - vInt.y) * (int64_t)(vInt2.x - vInt.x) - (int64_t)(pnt.x - vInt.x) * (int64_t)num2;
				if (num2 > 0)
				{
					if (num3 > 0LL)
					{
						flag = !flag;
					}
				}
				else if (num3 < 0LL)
				{
					flag = !flag;
				}
			}
			num = i++;
		}
		return flag;
	}

	static bool SegIntersectPlg(const VInt2& segSrc, const VInt2& segVec, const VInt2 plg[], int32_t length, VInt2& nearPoint, VInt2& projectVec)
	{
		nearPoint = VInt2::zero;
		projectVec = VInt2::zero;
		if (plg == nullptr || length < 2)
		{
			return false;
		}
		bool result = false;
		int64_t num = -1LL;
		int32_t num2 = -1;
		for (int32_t i = 0; i < length; i++)
		{
			VInt2 vInt = plg[(i + 1) % length] - plg[i];
			VInt2 vInt2;
			if (IntersectSegment(segSrc, segVec, plg[i], vInt, vInt2))
			{
				int64_t sqrMagnitudeLong = (vInt2 - segSrc).sqrMagnitudeLong();
				if (num < 0LL || sqrMagnitudeLong < num)
				{
					nearPoint = vInt2;
					num = sqrMagnitudeLong;
					num2 = i;
					result = true;
				}
			}
		}
		if (num2 >= 0)
		{
			VInt2 lhs = plg[(num2 + 1) % length] - plg[num2];
			VInt2 vInt3 = segSrc + segVec - nearPoint;
			int64_t num3 = (int64_t)vInt3.x * (int64_t)lhs.x + (int64_t)vInt3.y * (int64_t)lhs.y;
			if (num3 < 0LL)
			{
				num3 = -num3;
				lhs = -lhs;
			}
			int64_t sqrMagnitudeLong2 = lhs.sqrMagnitudeLong();
			projectVec.x = (int32_t)Divide((int64_t)lhs.x * num3, sqrMagnitudeLong2);
			projectVec.y = (int32_t)Divide((int64_t)lhs.y * num3, sqrMagnitudeLong2);
		}
		return result;
	}

	static VInt3 SphereNormalPos(Random* random)
	{
		VInt3 pos;
		pos.x = random->Range(-1000, 1000);
		pos.y = random->Range(-1000, 1000);
		pos.z = random->Range(-1000, 1000);
		int32_t r = pos.magnitude();
		pos.x = IntMath::Divide(pos.x * 1000, r);
		pos.y = IntMath::Divide(pos.y * 1000, r);
		pos.z = IntMath::Divide(pos.z * 1000, r);
		return pos;
	}

	static VInt3 VInterpNormalRotationTo(const VInt3& Current, const VInt3& Target, int32_t RotationDegrees)
	{
		int32_t size = Target.magnitude();
		VInt3 ret = VInt4::VInterpNormalRotationTo(Current, Target, RotationDegrees);
		return ret.NormalizeTo(size);
	}
};

#endif // __INT_MATH_H__