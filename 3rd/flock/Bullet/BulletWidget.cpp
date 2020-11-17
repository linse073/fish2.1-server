#include "BulletWidget.h"
#include "MemoryStream.h"

UBulletWidget::UBulletWidget()
	:id_(0),
	index_(0),
	dir_(VInt2::zero), 
	pos_(VInt2::zero),
	multi_(1)
{
}

void UBulletWidget::Clear()
{
	id_ = 0;
	index_ = 0;
	dir_ = VInt2::zero;
	pos_ = VInt2::zero;
	multi_ = 1;
}

void UBulletWidget::Init_fast(uint32_t id, const VInt2& dir, const VInt2& pos, uint8_t index, uint32_t multi)
{
	id_ = id;
	index_ = index;
	multi_ = multi;

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

void UBulletWidget::Pack_Data(KBEngine::MemoryStream& stream)
{
	stream << id_;
	stream << index_;
	stream << dir_.x << dir_.y;
	stream << pos_.x << pos_.y;
	stream << multi_;
}

void UBulletWidget::Read_Data(KBEngine::MemoryStream& stream)
{
	stream >> id_;
	stream >> index_;
	stream >> dir_.x >> dir_.y;
	stream >> pos_.x >> pos_.y;
	stream >> multi_;
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

uint32_t UBulletWidget::GetMulti() const
{
	return multi_;
}