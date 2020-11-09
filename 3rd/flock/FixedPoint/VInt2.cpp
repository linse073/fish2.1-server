#include "VInt2.h"
#include "IntMath.h"

const VInt2 VInt2::zero = VInt2(0, 0);

const int32_t VInt2::Rotations[] =
{
    1,
    0,
    0,
    1,
    0,
    1,
    -1,
    0,
    -1,
    0,
    0,
    -1,
    0,
    -1,
    1,
    0
};

int32_t VInt2::magnitude() const
{
    int64_t num = (int64_t)x;
    int64_t num2 = (int64_t)y;
    return IntMath::Sqrt(num * num + num2 * num2);
}

void VInt2::Normalize()
{
    //int64_t num = (int64_t)(x * 100);
    //int64_t num2 = (int64_t)(y * 100);
	int64_t num = (int64_t)(x);
	int64_t num2 = (int64_t)(y);
    int64_t num3 = num * num + num2 * num2;
    if (num3 == 0LL)
    {
        return;
    }
    int64_t b = (int64_t)IntMath::Sqrt(num3);
    x = (int32_t)IntMath::Divide(num * 1000LL, b);
    y = (int32_t)IntMath::Divide(num2 * 1000LL, b);
}

void VInt2::NormalizeTo(int32_t newMagn)
{
	if (newMagn == 0)
	{
		*this = VInt2::zero;
	}
	else
	{
		int64_t num = (int64_t)(x);
		int64_t num2 = (int64_t)(y);
		int64_t num4 = num * num + num2 * num2;
		if (num4 == 0LL)
		{
			return;
		}
		int64_t b = (int64_t)IntMath::Sqrt(num4);
		int64_t num5 = (int64_t)newMagn;
		x = (int32_t)IntMath::Divide(num * num5, b);
		y = (int32_t)IntMath::Divide(num2 * num5, b);
	}
}

VInt2 VInt2::ClampMagnitude(const VInt2& v, int32_t maxLength)
{
    int64_t sqrMagnitudeLong = v.sqrMagnitudeLong();
    int64_t num = (int64_t)maxLength;
    if (sqrMagnitudeLong > num * num)
    {
        int64_t b = (int64_t)IntMath::Sqrt(sqrMagnitudeLong);
        int32_t num2 = (int32_t)IntMath::Divide((int64_t)(v.x) * num, b);
        int32_t num3 = (int32_t)IntMath::Divide((int64_t)(v.y) * num, b);
        return VInt2(num2, num3);
    }
    return v;
}

VInt2 VInt2::operator *(const VFactor& f) const
{
    return IntMath::Divide(*this, f.nom, f.den);
}

VInt2 VInt2::operator /(const VFactor& f) const
{
    return IntMath::Divide(*this, f.den, f.nom);
}