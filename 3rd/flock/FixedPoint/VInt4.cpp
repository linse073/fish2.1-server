#include "VInt4.h"
#include "IntMath.h"

const VInt4 VInt4::Identity(0, 0, 0, 1000);

VInt3 VInt4::operator*(const VInt3& V) const
{
	return RotateVector(V);
}

VInt4::VInt4(int32_t InX, int32_t InY, int32_t InZ, int32_t InW)
	:X(InX), Y(InY), Z(InZ), W(InW)
{
}

VInt4::VInt4(const VInt3& Axis, const VFactor& AngleRad)
{
	const VFactor half_a = AngleRad / 2LL;
	VFactor s, c;
	IntMath::sincos(s, c, half_a);

	X = (s * Axis.x).integer();
	Y = (s * Axis.y).integer();
	Z = (s * Axis.z).integer();
	W = (c * 1000LL).integer();
}

//FString VInt4::ToString() const
//{
//	return FString::Printf(TEXT("X=%d Y=%d Z=%d W=%d"), X, Y, Z, W);
//}

VInt4 VInt4::operator+(const VInt4& Q) const
{
	return VInt4(X + Q.X, Y + Q.Y, Z + Q.Z, W + Q.W);
}

VInt4 VInt4::operator-(const VInt4& Q) const
{
	return VInt4(X - Q.X, Y - Q.Y, Z - Q.Z, W - Q.W);
}

bool VInt4::operator==(const VInt4& Q) const
{
	return X == Q.X && Y == Q.Y && Z == Q.Z && W == Q.W;
}

bool VInt4::operator!=(const VInt4& Q) const
{
	return X != Q.X || Y != Q.Y || Z != Q.Z || W != Q.W;
}

VInt4 VInt4::GetNormalized() const
{
	VInt4 Result(*this);
	Result.Normalize();
	return Result;
}

int32_t VInt4::SizeSquared() const
{
	int64_t x_ = (int64_t)X;
	int64_t y_ = (int64_t)Y;
	int64_t z_ = (int64_t)Z;
	int64_t w_ = (int64_t)W;

	return (int32_t)(x_ * x_ + y_ * y_ + z_ * z_ + w_ * w_);
}

VInt3 VInt4::RotateVector(const VInt3& V) const
{
	// http://people.csail.mit.edu/bkph/articles/Quaternions.pdf
	// V' = V + 2w(Q x V) + (2Q x (Q x V))
	// refactor:
	// V' = V + w(2(Q x V)) + (Q x (2(Q x V)))
	// T = 2(Q x V);
	// V' = V + w*(T) + (Q x T)

	VInt3 Q(X, Y, Z);
	VInt3 T = VInt3::Cross(Q, V) * 2;
	VFactor factor((int64_t)W, 1000LL);
	VInt3 Result = V + (T * factor) + VInt3::Cross(Q, T);
	return Result;
}

VInt3 VInt4::UnrotateVector(const VInt3& V) const
{
	VInt3 Q(-X, -Y, -Z);
	VInt3 T = VInt3::Cross(Q, V) * 2;
	VFactor factor((int64_t)W, 1000LL);
	VInt3 Result = V + (T * factor) + VInt3::Cross(Q, T);
	return Result;
}

VInt4 VInt4::Inverse() const
{
	return VInt4(-X, -Y, -Z, W);
}

VInt3 VInt4::GetAxisX() const
{
	return RotateVector(VInt3(1000, 0, 0));
}

VInt3 VInt4::GetAxisY() const
{
	return RotateVector(VInt3(0, 1000, 0));
}

VInt3 VInt4::GetAxisZ() const
{
	return RotateVector(VInt3(0, 0, 1000));
}

VInt3 VInt4::GetForwardVector() const
{
	return GetAxisX();
}

VInt3 VInt4::GetRightVector() const
{
	return GetAxisY();
}

VInt3 VInt4::GetUpVector() const
{
	return GetAxisZ();
}

VInt3 VInt4::Vector() const
{
	return GetAxisX();
}

void VInt4::Normalize()
{
	int64_t x_ = (int64_t)X;
	int64_t y_ = (int64_t)Y;
	int64_t z_ = (int64_t)Z;
	int64_t w_ = (int64_t)W;

	int64_t squareSum = x_ * x_ + y_ * y_ + z_ * z_ + w_ * w_;
	int64_t scale = IntMath::SqrtLong(squareSum);
	X = (int32_t)((int64_t)X * 1000LL / scale);
	Y = (int32_t)((int64_t)Y * 1000LL / scale);
	Z = (int32_t)((int64_t)Z * 1000LL / scale);
	W = (int32_t)((int64_t)W * 1000LL / scale);
}

int32_t VInt4::Size() const
{
	int64_t x_ = (int64_t)X;
	int64_t y_ = (int64_t)Y;
	int64_t z_ = (int64_t)Z;
	int64_t w_ = (int64_t)W;

	return IntMath::Sqrt(x_ * x_ + y_ * y_ + z_ * z_ + w_ * w_);
}

void VInt4::ToAxisAndAngle(VInt3& Axis, VFactor& Angle) const
{
	Angle = GetAngle();
	Axis = GetRotationAxis();
}

VFactor VInt4::GetAngle() const
{
	return IntMath::acos((int64_t)W, 1000LL) * 2LL;
}

VInt3 VInt4::GetRotationAxis() const
{
	// Ensure we never try to sqrt a neg number
	const int64_t S = IntMath::SqrtLong(Math::Max(int64_t(1000000LL - ((int64_t)W * (int64_t)W)), int64_t(0LL)));

	if (S > 0)
	{
		return VInt3(int32_t((int64_t)X * 1000LL / S), int32_t((int64_t)Y * 1000LL / S), int32_t((int64_t)Z * 1000LL / S));
	}

	return VInt3(1000, 0, 0);
}

VInt4 VInt4::FindBetween(const VInt3& Vector1, const VInt3& Vector2)
{
	return FindBetweenVectors(Vector1, Vector2);
}

VInt4 VInt4::FindBetweenVectors(const VInt3& A, const VInt3& B)
{
	const int64_t NormAB = IntMath::SqrtLong((A.sqrMagnitudeLong() / 1000LL) * (B.sqrMagnitudeLong() / 1000LL));
	return FindBetween_Helper(A, B, NormAB);
}

VInt4 VInt4::FindBetween_Helper(const VInt3& A, const VInt3& B, int64_t NormAB)
{
	int64_t W = NormAB + VInt3::DotLong(A, B) / 1000LL;
	VInt4 Result;

	//if (W >= NormAB / 1000000LL)
	if (W > NormAB / 1000000LL)
	{
		//Axis = FVector::CrossProduct(A, B);
		Result = VInt4(int32_t(((int64_t)A.y * (int64_t)B.z - (int64_t)A.z * (int64_t)B.y) / 1000LL),
			int32_t(((int64_t)A.z * (int64_t)B.x - (int64_t)A.x * (int64_t)B.z) / 1000LL),
			int32_t(((int64_t)A.x * (int64_t)B.y - (int64_t)A.y * (int64_t)B.x) / 1000LL),
			int32_t(W));
	}
	else
	{
		// A and B point in opposite directions
		W = 0;
		Result = Math::Abs(A.x) > Math::Abs(A.y)
			? VInt4(-A.z, 0, A.x, int32_t(W))
			: VInt4(0, -A.z, A.y, W);
	}

	Result.Normalize();
	return Result;
}

VInt4 VInt4::ToOrientationQuat(const VInt3& V)
{
	const VFactor YawRad = IntMath::atan2(V.y, V.x);
	const VFactor PitchRad = IntMath::atan2(V.z, IntMath::Sqrt((int64_t)V.x * (int64_t)V.x + (int64_t)V.y * (int64_t)V.y));

	const VFactor DIVIDE_BY_2(1LL, 2LL);
	VFactor SP, SY;
	VFactor CP, CY;

	IntMath::sincos(SP, CP, PitchRad * DIVIDE_BY_2);
	IntMath::sincos(SY, CY, YawRad * DIVIDE_BY_2);

	VInt4 RotationQuat;
	RotationQuat.X = ((SP * SY) * 1000LL).roundInt();
	RotationQuat.Y = ((-SP * CY) * 1000LL).roundInt();
	RotationQuat.Z = ((CP * SY) * 1000LL).roundInt();
	RotationQuat.W = ((CP * CY) * 1000LL).roundInt();
	return RotationQuat;
}

VInt3 VInt4::VInterpNormalRotationTo(const VInt3& Current, const VInt3& Target, int32_t RotationDegrees)
{
	// Find delta rotation between both normals.
	VInt4 DeltaQuat = VInt4::FindBetween(Current, Target);

	// Decompose into an axis and angle for rotation
	VInt3 DeltaAxis;
	VFactor DeltaAngle;
	DeltaQuat.ToAxisAndAngle(DeltaAxis, DeltaAngle);

	// Find rotation step for this frame
	const VFactor RotationStepRadians = (VFactor::pi / 180LL) * RotationDegrees;

	if (DeltaAngle.Abs() > RotationStepRadians)
	{
		DeltaAngle = IntMath::Clamp(DeltaAngle, -RotationStepRadians, RotationStepRadians);
		DeltaQuat = VInt4(DeltaAxis, DeltaAngle);
		return DeltaQuat.RotateVector(Current);
	}
	return Target;
}