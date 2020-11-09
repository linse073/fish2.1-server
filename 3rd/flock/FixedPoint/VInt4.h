#ifndef __VINT4_H__
#define __VINT4_H__

#include "VInt3.h"

struct VInt4
{
	int32_t X;

	int32_t Y;

	int32_t Z;

	int32_t W;

	static const VInt4 Identity;

	VInt4()
		:X(0), Y(0), Z(0), W(0)
	{}

	VInt4(int32_t InX, int32_t InY, int32_t InZ, int32_t InW);

	VInt4(const VInt3& Axis, const VFactor& AngleRad);

	VInt4 operator+(const VInt4& Q) const;

	VInt4 operator-(const VInt4& Q) const;

	VInt3 operator*(const VInt3& V) const;

	bool operator==(const VInt4& Q) const;

	bool operator!=(const VInt4& Q) const;

	void Normalize();

	VInt4 GetNormalized() const;

	int32_t Size() const;

	int32_t SizeSquared() const;

	VInt3 RotateVector(const VInt3& V) const;

	VInt3 UnrotateVector(const VInt3& V) const;

	VInt4 Inverse() const;

	VInt3 GetAxisX() const;

	VInt3 GetAxisY() const;

	VInt3 GetAxisZ() const;

	VInt3 GetForwardVector() const;

	VInt3 GetRightVector() const;

	VInt3 GetUpVector() const;

	VInt3 Vector() const;

	void ToAxisAndAngle(VInt3& Axis, VFactor& Angle) const;

	VFactor GetAngle() const;

	VInt3 GetRotationAxis() const;

	//FString ToString() const;

	static VInt4 FindBetween(const VInt3& Vector1, const VInt3& Vector2);
	static VInt4 FindBetweenVectors(const VInt3& A, const VInt3& B);
	static VInt4 FindBetween_Helper(const VInt3& A, const VInt3& B, int64_t NormAB);

	static VInt4 ToOrientationQuat(const VInt3& V);
	static VInt3 VInterpNormalRotationTo(const VInt3& Current, const VInt3& Target, int32_t RotationDegrees);
};

#endif // __VINT4_H__