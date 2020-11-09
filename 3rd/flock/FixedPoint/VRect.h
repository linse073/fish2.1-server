#ifndef __VRECT_H__
#define __VRECT_H__

#include "VInt3.h"

struct VRect
{
	int32_t x;

	int32_t y;

	int32_t width;

	int32_t height;

	VInt2 position() const
	{
		return VInt2(x, y);
	}

	void position(const VInt2& value)
	{
		x = value.x;
		y = value.y;
	}

	VInt2 center() const
	{
		return VInt2(x + (width >> 1), y + (height >> 1));
	}

	void center(const VInt2& value)
	{
		x = value.x - (width >> 1);
		y = value.y - (height >> 1);
	}

	VInt2 min() const
	{
		return VInt2(xMin(), yMin());
	}

	void min(const VInt2& value)
	{
		xMin(value.x);
		yMin(value.y);
	}

	VInt2 max() const
	{
		return VInt2(xMax(), yMax());
	}

	void max(const VInt2& value)
	{
		xMax(value.x);
		yMax(value.y);
	}

	VInt2 size() const
	{
		return VInt2(width, height);
	}

	void size(const VInt2& value)
	{
		width = value.x;
		height = value.y;
	}

	int32_t xMin() const
	{
		return x;
	}

	void xMin(int32_t value)
	{
		int32_t xMaxt = xMax();
		x = value;
		width = xMaxt - x;
	}

	int32_t yMin() const
	{
		return y;
	}

	void yMin(int32_t value)
	{
		int32_t yMaxt = yMax();
		y = value;
		height = yMaxt - y;
	}

	int32_t xMax() const
	{
		return width + x;
	}

	void xMax(int32_t value)
	{
		width = value - x;
	}

	int32_t yMax() const
	{
		return height + y;
	}

	void yMax(int32_t value)
	{
		height = value - y;
	}

	VRect(int32_t left, int32_t top, int32_t width, int32_t height)
	{
		x = left;
		y = top;
		width = width;
		height = height;
	}

	VRect(const VRect& source)
	{
		x = source.x;
		y = source.y;
		width = source.width;
		height = source.height;
	}

	static VRect MinMaxRect(int32_t left, int32_t top, int32_t right, int32_t bottom)
	{
		return VRect(left, top, right - left, bottom - top);
	}

	void Set(int32_t left, int32_t top, int32_t width, int32_t height)
	{
		x = left;
		y = top;
		width = width;
		height = height;
	}

	// string ToString()
	// {
	// 	object[] array = object[]
	// 	{
	// 		x,
	// 		y,
	// 		width,
	// 		height
	// 	};
	// 	return string.Format("(x:{0:F2}, y:{1:F2}, width:{2:F2}, height:{3:F2})", array);
	// }

	// string ToString(string format)
	// {
	// 	object[] array = object[]
	// 	{
	// 		x.ToString(format),
	// 		y.ToString(format),
	// 		width.ToString(format),
	// 		height.ToString(format)
	// 	};
	// 	return string.Format("(x:{0}, y:{1}, width:{2}, height:{3})", array);
	// }

	bool Contains(const VInt2& point) const
	{
		return point.x >= xMin() && point.x < xMax() && point.y >= yMin() && point.y < yMax();
	}

	bool Contains(const VInt3& point) const
	{
		return point.x >= xMin() && point.x < xMax() && point.y >= yMin() && point.y < yMax();
	}

	bool Contains(const VInt3& point, bool allowInverse) const
	{
		if (!allowInverse)
		{
			return Contains(point);
		}
		bool flag = false;
		if (((float)width < 0.f && point.x <= xMin() && point.x > xMax()) || ((float)width >= 0.f && point.x >= xMin() && point.x < xMax()))
		{
			flag = true;
		}
		return flag && (((float)height < 0.f && point.y <= yMin() && point.y > yMax()) || ((float)height >= 0.f && point.y >= yMin() && point.y < yMax()));
	}

	static VRect OrderMinMax(VRect& rect)
	{
		if (rect.xMin() > rect.xMax())
		{
			int32_t xMin = rect.xMin();
			rect.xMin(rect.xMax());
			rect.xMax(xMin);
		}
		if (rect.yMin() > rect.yMax())
		{
			int32_t yMin = rect.yMin();
			rect.yMin(rect.yMax());
			rect.yMax(yMin);
		}
		return rect;
	}

	bool Overlaps(const VRect& other) const
	{
		return other.xMax() > xMin() && other.xMin() < xMax() && other.yMax() > yMin() && other.yMin() < yMax();
	}

	bool Overlaps(VRect& other, bool allowInverse) const
	{
		VRect rect = *this;
		if (allowInverse)
		{
			rect = OrderMinMax(rect);
			other = OrderMinMax(other);
		}
		return rect.Overlaps(other);
	}

	int32_t GetHashCode() const
	{
		return x ^ width << 2 ^ y >> 2 ^ height >> 1;
	}

	bool operator !=(const VRect& rhs) const
	{
		return x != rhs.x || y != rhs.y || width != rhs.width || height != rhs.height;
	}

	bool operator ==(const VRect& rhs) const
	{
		return x == rhs.x && y == rhs.y && width == rhs.width && height == rhs.height;
	}
};

#endif // __VRECT_H__