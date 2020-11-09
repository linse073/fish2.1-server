#ifndef __VFACTOR_H__
#define __VFACTOR_H__

#include <stdint.h>
#include "Math.h"

struct VFactor
{
	int64_t nom;

	int64_t den;

	static const VFactor zero;

	static const VFactor one;

	static const VFactor pi;

	static const VFactor twoPi;

	static const int64_t mask_ = 9223372036854775807LL;

	static const int64_t upper_ = 16777215LL;

	int32_t roundInt() const;

	int32_t integer() const
	{
		return (int32_t)(nom / den);
	}

	float single() const
	{
		double num = (double)nom / (double)den;
		return (float)num;
	}

	bool IsPositive() const
	{
/*		DebugHelper.Assert(den != 0LL, "VFactor: denominator is zero !");*/
		if (nom == 0LL)
		{
			return false;
		}
		bool flag = nom > 0LL;
		bool flag2 = den > 0LL;
		return !(flag ^ flag2);
	}

	bool IsNegative() const
	{
/*		DebugHelper.Assert(den != 0LL, "VFactor: denominator is zero !");*/
		if (nom == 0LL)
		{
			return false;
		}
		bool flag = nom > 0LL;
		bool flag2 = den > 0LL;
		return flag ^ flag2;
	}

	VFactor Abs() const
	{
		return VFactor(Math::Abs(nom), Math::Abs(den));
	}

	bool IsZero() const
	{
		return nom == 0LL;
	}

	VFactor Inverse() const
	{
		return VFactor(den, nom);
	}

	VFactor(int64_t n, int64_t d) :nom(n), den(d)
	{
	}

	VFactor() :nom(0LL), den(1LL)
	{
	}

	int32_t GetHashCode() const
	{
		// return base.GetHashCode();
		return (int32_t)(nom ^ den);
	}

	// string ToString()
	// {
	// 	return single.ToString();
	// }

	void strip()
	{
		while ((nom & mask_) > upper_ && (den & mask_) > upper_)
		{
			nom >>= 1;
			den >>= 1;
		}
	}

	bool operator <(const VFactor& b) const
	{
		int64_t num = nom * b.den;
		int64_t num2 = b.nom * den;
		bool flag = (b.den > 0LL) ^ (den > 0LL);
		return (!flag) ? (num < num2) : (num > num2);
	}

	bool operator >(const VFactor& b) const
	{
		int64_t num = nom * b.den;
		int64_t num2 = b.nom * den;
		bool flag = (b.den > 0LL) ^ (den > 0LL);
		return (!flag) ? (num > num2) : (num < num2);
	}

	bool operator <=(const VFactor& b) const
	{
		int64_t num = nom * b.den;
		int64_t num2 = b.nom * den;
		bool flag = (b.den > 0LL) ^ (den > 0LL);
		return (!flag) ? (num <= num2) : (num >= num2);
	}

	bool operator >=(const VFactor& b) const
	{
		int64_t num = nom * b.den;
		int64_t num2 = b.nom * den;
		bool flag = (b.den > 0LL) ^ (den > 0LL);
		return (!flag) ? (num >= num2) : (num <= num2);
	}

	bool operator ==(const VFactor& b) const
	{
		return nom * b.den == b.nom * den;
	}

	bool operator !=(const VFactor& b) const
	{
		return nom * b.den != b.nom * den;
	}

	bool operator <(int64_t b) const
	{
		int64_t num = nom;
		int64_t num2 = b * den;
		return (den <= 0LL) ? (num > num2) : (num < num2);
	}

	bool operator >(int64_t b) const
	{
		int64_t num = nom;
		int64_t num2 = b * den;
		return (den <= 0LL) ? (num < num2) : (num > num2);
	}

	bool operator <=(int64_t b) const
	{
		int64_t num = nom;
		int64_t num2 = b * den;
		return (den <= 0LL) ? (num >= num2) : (num <= num2);
	}

	bool operator >=(int64_t b) const
	{
		int64_t num = nom;
		int64_t num2 = b * den;
		return (den <= 0LL) ? (num <= num2) : (num >= num2);
	}

	bool operator ==(int64_t b) const
	{
		return nom == b * den;
	}

	bool operator !=(int64_t b) const
	{
		return nom != b * den;
	}

	VFactor operator +(const VFactor& b) const
	{
		return VFactor(nom * b.den + b.nom * den, den * b.den);
	}

	VFactor operator +(int64_t b) const
	{
		return VFactor(nom + b * den, den);
	}

	VFactor operator -(const VFactor& b) const
	{
		return VFactor(nom * b.den - b.nom * den, den * b.den);
	}

	VFactor operator -(int64_t b) const
	{
		return VFactor(nom - b * den, den);
	}

	VFactor operator *(int64_t b) const
	{
		return VFactor(nom * b, den);
	}

	VFactor operator /(int64_t b) const
	{
		return VFactor(nom, den * b);
	}

	VFactor operator -() const
	{
		return VFactor(-nom, den);
	}

	VFactor operator *(const VFactor& b) const
	{
		return VFactor(nom * b.nom, den * b.den);
	}

	VFactor operator /(const VFactor& b) const
	{
		return VFactor(nom * b.den, den * b.nom);
	}
};

int32_t operator *(int32_t i, const VFactor& f);

#endif // __VFACTOR_H__