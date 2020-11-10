#include "FlockAgent.h"
#include "VInt4.h"
#include "FishAsset.h"
#include "FlockCommon.h"
#include "Flock.h"
#include "MemoryStream.h"

AFlockAgent::AFlockAgent()
	:fishAsset_(nullptr),
	id_(0),
	pos_(VInt3::zero),
	dir_(VInt3::zero),
	scale_(0),
	avoidanceRadius_(0),
	dead_(false),
	fishType_(EFishType::FishType_Small)
{
}

void AFlockAgent::Clear()
{
	fishAsset_ = nullptr;
	id_ = 0;
	pos_ = VInt3::zero;
	dir_ = VInt3::zero;
	scale_ = 0;
	avoidanceRadius_ = 0;
	dead_ = false;
	fishType_ = EFishType::FishType_Small;
}

void AFlockAgent::OnHit_fast(bool dead)
{
	if (!dead_)
	{
		if (dead)
		{
			dead_ = true;
		}
	}
}

void AFlockAgent::Init_fast(uint32_t id, int32_t scale, const VInt3& pos, const VInt3& dir, const UFishAsset* fishAsset, EFishType fishType)
{
	id_ = id;
	pos_ = pos;
	dir_ = dir;
	fishAsset_ = fishAsset;
	scale_ = scale;
	avoidanceRadius_ = fishAsset->AvoidanceRadius * scale / 100;
	fishType_ = fishType;
}

void AFlockAgent::Move_fast(VInt3 move)
{
	if (move == VInt3::zero)
	{
		move = dir_;
	}
	move = move * fishAsset_->DriveFactor;
	if (move.magnitude() > fishAsset_->MaxSpeed)
	{
		move.NormalizeTo(fishAsset_->MaxSpeed);
	}
	pos_ = pos_ + move * STEP_DELTA;
	// move.Normalize();
	dir_ = move;
}

void AFlockAgent::Pack_Data(KBEngine::MemoryStream& stream)
{
	stream << id_;
	stream << pos_.x << pos_.y << pos_.z;
	stream << dir_.x << dir_.y << dir_.z;
	stream << scale_;
	stream << avoidanceRadius_;
	stream << (uint8_t)fishType_;
	stream << fishAsset_->ID;
}

void AFlockAgent::Read_Data(KBEngine::MemoryStream& stream)
{
	stream >> id_;
	stream >> pos_.x >> pos_.y >> pos_.z;
	stream >> dir_.x >> dir_.y >> dir_.z;
	stream >> scale_;
	stream >> avoidanceRadius_;
	fishType_ = (EFishType)stream.readUint8();
	uint32_t ID;
	stream >> ID;
	// TODO: init fishAsset
}

//const UFishAsset* AFlockAgent::GetFishAsset() const
//{
//	return fishAsset_;
//}

const VInt3& AFlockAgent::GetPos() const
{
	return pos_;
}

const VInt3& AFlockAgent::GetDir() const
{
	return dir_;
}

uint32_t AFlockAgent::GetID() const
{
	return id_;
}

int32_t AFlockAgent::GetNeighborRadius() const
{
	return fishAsset_->NeighborRadius;
}

int32_t AFlockAgent::GetAvoidanceRadius() const
{
	return avoidanceRadius_;
}

int32_t AFlockAgent::GetMaxMove() const
{
	return fishAsset_->MaxSpeed / fishAsset_->DriveFactor;
}

uint8_t AFlockAgent::GetCamp() const
{
	return fishAsset_->FlockCamp;
}

bool AFlockAgent::IsDead() const
{
	return dead_;
}

EFishType AFlockAgent::GetFishType() const
{
	return fishType_;
}