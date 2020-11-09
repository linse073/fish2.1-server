#include "VInt3.h"
#include "IntMath.h"

const float VInt3::FloatPrecision = 1000.f;

const float VInt3::PrecisionFactor = 0.001f;

const VInt3 VInt3::zero = VInt3(0, 0, 0);

const VInt3 VInt3::one = VInt3(1000, 1000, 1000);

const VInt3 VInt3::half = VInt3(500, 500, 500);

const VInt3 VInt3::forward = VInt3(0, 0, 1000);

const VInt3 VInt3::up = VInt3(0, 1000, 0);

const VInt3 VInt3::right = VInt3(1000, 0, 0);

int32_t VInt3::magnitude() const
{
    int64_t num = (int64_t)x;
    int64_t num2 = (int64_t)y;
    int64_t num3 = (int64_t)z;
    return IntMath::Sqrt(num * num + num2 * num2 + num3 * num3);
}

int32_t VInt3::magnitude2D() const
{
    int64_t num = (int64_t)x;
    int64_t num2 = (int64_t)z;
    return IntMath::Sqrt(num * num + num2 * num2);
}

VInt3 VInt3::Cross(const VInt3& lhs, const VInt3& rhs)
{
    return VInt3((int32_t)IntMath::Divide((int64_t)lhs.y * (int64_t)rhs.z - (int64_t)lhs.z * (int64_t)rhs.y, 1000LL),
		(int32_t)IntMath::Divide((int64_t)lhs.z * (int64_t)rhs.x - (int64_t)lhs.x * (int64_t)rhs.z, 1000LL),
		(int32_t)IntMath::Divide((int64_t)lhs.x * (int64_t)rhs.y - (int64_t)lhs.y * (int64_t)rhs.x, 1000LL));
}

VInt3 VInt3::NormalizeTo(int32_t newMagn)
{
	//if (newMagn == 0)
	//{
	//	*this = VInt3::zero;
	//}
	//else
	//{
	//	int64_t num = (int64_t)(x) * 100LL;
	//	int64_t num2 = (int64_t)(y) * 100LL;
	//	int64_t num3 = (int64_t)(z) * 100LL;
	//	int64_t num4 = num * num + num2 * num2 + num3 * num3;
	//	if (num4 == 0LL)
	//	{
	//		return *this;
	//	}
	//	int64_t b = (int64_t)IntMath::Sqrt(num4);
	//	int64_t num5 = (int64_t)newMagn;
	//	x = (int32_t)IntMath::Divide(num * num5, b);
	//	y = (int32_t)IntMath::Divide(num2 * num5, b);
	//	z = (int32_t)IntMath::Divide(num3 * num5, b);
	//}
	//return *this;

	if (newMagn == 0)
	{
		*this = VInt3::zero;
	}
	else
	{
		int64_t num = (int64_t)(x);
		int64_t num2 = (int64_t)(y);
		int64_t num3 = (int64_t)(z);
		int64_t num4 = num * num + num2 * num2 + num3 * num3;
		if (num4 == 0LL)
		{
			return *this;
		}
		int64_t b = (int64_t)IntMath::Sqrt(num4);
		int64_t num5 = (int64_t)newMagn;
		x = (int32_t)IntMath::Divide(num * num5, b);
		y = (int32_t)IntMath::Divide(num2 * num5, b);
		z = (int32_t)IntMath::Divide(num3 * num5, b);
	}
	return *this;
}

int64_t VInt3::Normalize()
{
    //int64_t num = (int64_t)x << 7;
    //int64_t num2 = (int64_t)y << 7;
    //int64_t num3 = (int64_t)z << 7;
    //int64_t num4 = num * num + num2 * num2 + num3 * num3;
    //if (num4 == 0LL)
    //{
    //    return 0LL;
    //}
    //int64_t num5 = (int64_t)IntMath::Sqrt(num4);
    //int64_t num6 = 1000LL;
    //x = (int32_t)IntMath::Divide(num * num6, num5);
    //y = (int32_t)IntMath::Divide(num2 * num6, num5);
    //z = (int32_t)IntMath::Divide(num3 * num6, num5);
    //return num5 >> 7;

	int64_t num = (int64_t)x;
	int64_t num2 = (int64_t)y;
	int64_t num3 = (int64_t)z;
	int64_t num4 = num * num + num2 * num2 + num3 * num3;
	if (num4 == 0LL)
	{
		return 0LL;
	}
	int64_t num5 = (int64_t)IntMath::Sqrt(num4);
	int64_t num6 = 1000LL;
	x = (int32_t)IntMath::Divide(num * num6, num5);
	y = (int32_t)IntMath::Divide(num2 * num6, num5);
	z = (int32_t)IntMath::Divide(num3 * num6, num5);
	return num5;
}

VInt3 VInt3::Lerp(const VInt3& a, const VInt3& b, int32_t factorNom, int32_t factorDen)
{
    return VInt3(IntMath::Divide((b.x - a.x) * factorNom, factorDen) + a.x, IntMath::Divide((b.y - a.y) * factorNom, factorDen) + a.y, IntMath::Divide((b.z - a.z) * factorNom, factorDen) + a.z);
}

VFactor VInt3::AngleInt(const VInt3& lhs, const VInt3& rhs)
{
    int64_t den = (int64_t)lhs.magnitude() * (int64_t)rhs.magnitude();
    // return IntMath::acos((int64_t)Dot(lhs, rhs), den);
	return IntMath::acos(DotLong(lhs, rhs), den);
}

VInt3 VInt3::RotateY(const VFactor& radians) const
{
    VFactor vFactor;
    VFactor vFactor2;
    IntMath::sincos(vFactor, vFactor2, radians.nom, radians.den);
    int64_t num = vFactor2.nom * vFactor.den;
    int64_t num2 = vFactor2.den * vFactor.nom;
    int64_t b = vFactor2.den * vFactor.den;
    VInt3 vInt;
    vInt.x = (int32_t)IntMath::Divide((int64_t)x * num + (int64_t)z * num2, b);
    vInt.z = (int32_t)IntMath::Divide(-(int64_t)x * num2 + (int64_t)z * num, b);
    vInt.y = 0;
    return vInt.NormalizeTo(1000);
}

VInt3 VInt3::RotateY(int32_t degree) const
{
    VFactor vFactor;
    VFactor vFactor2;
    IntMath::sincos(vFactor, vFactor2, 31416LL * (int64_t)degree, 1800000LL);
    int64_t num = vFactor2.nom * vFactor.den;
    int64_t num2 = vFactor2.den * vFactor.nom;
    int64_t b = vFactor2.den * vFactor.den;
    VInt3 vInt;
    vInt.x = (int32_t)IntMath::Divide((int64_t)x * num + (int64_t)z * num2, b);
    vInt.z = (int32_t)IntMath::Divide(-(int64_t)x * num2 + (int64_t)z * num, b);
    vInt.y = 0;
    return vInt.NormalizeTo(1000);
}

VInt3 VInt3::Lerp(const VInt3& a, const VInt3& b, const VFactor& f)
{
    return VInt3((int32_t)IntMath::Divide((int64_t)(b.x - a.x) * f.nom, f.den) + a.x, (int32_t)IntMath::Divide((int64_t)(b.y - a.y) * f.nom, f.den) + a.y, (int32_t)IntMath::Divide((int64_t)(b.z - a.z) * f.nom, f.den) + a.z);
}

VInt3 VInt3::operator *(const VFactor& f) const
{
    return IntMath::Divide(*this, f.nom, f.den);
}

VInt3 VInt3::operator /(const VFactor& f) const
{
    return IntMath::Divide(*this, f.den, f.nom);
}

VInt3 VInt3::operator *(const VInt3& rhs) const
{
	//return VInt3(x * rhs.x, y * rhs.y, z * rhs.z);
	// NOTICE: 上面实现感觉有问题
	return VInt3((int32_t)IntMath::Divide((int64_t)x * (int64_t)rhs.x, 1000LL),
		(int32_t)IntMath::Divide((int64_t)y * (int64_t)rhs.y, 1000LL),
		(int32_t)IntMath::Divide((int64_t)z * (int64_t)rhs.z, 1000LL));
}