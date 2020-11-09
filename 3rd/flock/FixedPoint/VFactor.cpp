#include "VFactor.h"
#include "IntMath.h"

const VFactor VFactor::zero = VFactor(0LL, 1LL);

const VFactor VFactor::one = VFactor(1LL, 1LL);

const VFactor VFactor::pi = VFactor(31416LL, 10000LL);

const VFactor VFactor::twoPi = VFactor(62832LL, 10000LL);

int32_t VFactor::roundInt() const
{
	return (int32_t)IntMath::Divide(nom, den);
}

int32_t operator *(int32_t i, const VFactor& f)
{
    return (int32_t)IntMath::Divide((int64_t)i * f.nom, f.den);
}