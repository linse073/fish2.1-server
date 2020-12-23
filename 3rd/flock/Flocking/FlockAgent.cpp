#include "FlockAgent.h"
#include "VInt4.h"
#include "FishAsset.h"
#include "FlockCommon.h"
#include "Flock.h"
#include "MemoryStream.h"
#include "FlockPilot.h"

AFlockAgent::AFlockAgent()
	:fishAsset_(nullptr),
	id_(0),
	pos_(VInt3::zero),
	dir_(VInt3::zero),
	scale_(0),
	avoidanceRadius_(0),
	dead_(false),
	fishType_(EFishType::FishType_Small),
	pilot_(nullptr),
	pilotStep_(0)
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
	pilot_ = nullptr;
	pilotStep_ = 0;
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
	if (pilot_)
	{
		stream << pilot_->GetID();
	}
	else
	{
		stream << (uint32_t)0;
	}
	stream << pilotStep_;
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

void AFlockAgent::SetPilot(FlockPilot* pilot, bool init)
{
	if (pilot_ == nullptr)
	{
		pilot_ = pilot;
		if (init)
		{
			pilotStep_ = 0;
		}
	}
}

void AFlockAgent::ClearPilot()
{
	pilot_ = nullptr;
	pilotStep_ = 0;
}

void AFlockAgent::UpdatePilotStep(uint32_t step)
{
	pilotStep_ = step;
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

int32_t AFlockAgent::GetVisionRadius() const
{
	return fishAsset_->VisionRadius;
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
FlockPilot* AFlockAgent::GetPilot() const
{
	return pilot_;
}

uint32_t AFlockAgent::GetPilotStep() const
{
	return pilotStep_;
}