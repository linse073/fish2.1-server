#ifndef __MATH_H__
#define __MATH_H__

#include <cmath>
#include <algorithm>
#include <stdint.h>

struct Math
{
  static double Round(double d)
  {
    return std::round(d);
  }

  static int32_t Min(int32_t a, int32_t b)
  {
    return std::min(a, b);
  }

  static int32_t Max(int32_t a, int32_t b)
  {
    return std::max(a, b);
  }

  static int64_t Max(int64_t a, int64_t b)
  {
    return std::max(a, b);
  }

  static double Acos(double a)
  {
    return std::acos(a);
  }

  static int32_t Abs(int32_t a)
  {
    return std::abs(a);
  }

  static int64_t Abs(int64_t a)
  {
    return std::abs(a);
  }

  static double Sqrt(double a)
  {
    return std::sqrt(a);
  }

  static int32_t RoundToInt(float d)
  {
    return std::lround(d);
  }

  static int32_t Clamp(int32_t value, int32_t min, int32_t max)
  {
    return std::clamp(value, min, max);
  }
};

#endif // __MATH_H__