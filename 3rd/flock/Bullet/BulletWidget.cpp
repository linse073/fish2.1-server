#include "BulletWidget.h"

UBulletWidget::UBulletWidget()
	:id_(0), 
	dir_(VInt2::zero), 
	pos_(VInt2::zero)
{
}

void UBulletWidget::Clear()
{
	id_ = 0;
	dir_ = VInt2::zero;
	pos_ = VInt2::zero;
}

void UBulletWidget::Init_fast(uint32_t id, const VInt2& dir, const VInt2& pos)
{
	id_ = id;

	SetPosition_fast(pos);
	SetDir_fast(dir);
}

void UBulletWidget::SetPosition_fast(const VInt2& pos)
{
	pos_ = pos;
}

void UBulletWidget::SetDir_fast(const VInt2& dir)
{
	dir_ = dir;
}

uint32_t UBulletWidget::GetID() const
{
	return id_;
}

const VInt2& UBulletWidget::GetDir() const
{
	return dir_;
}

const VInt2& UBulletWidget::GetPosition() const
{
	return pos_;
}