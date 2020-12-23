#include "FlockLeader.h"
#include "MemoryStream.h"
#include "Flock.h"
#include "FlockAgent.h"
#include "FlockCommon.h"

FlockLeader::FlockLeader()
	:ID_(0),
	beginStep_(0),
	endStep_(0),
	radius_(0),
	range_(0),
	force_(0)
{
	memset(fishType_, 0, sizeof(fishType_));
}

void FlockLeader::Serialize(KBEngine::MemoryStream& stream)
{
	stream << uint8_t(1);
	stream << ID_;
	stream << beginStep_ << endStep_;
	stream << radius_ << range_;
	stream << force_;
	for (int32_t i=0; i<FishType_Count; ++i)
	{
		stream << (uint8_t)fishType_[i];
	}
	stream << (uint32_t)data_.size();
	for (auto& item : data_)
	{
		VInt3& pos = item.pos;
		stream << pos.x << pos.y << pos.z;
		VInt4& quat = item.quat;
		stream << quat.X << quat.Y << quat.Z << quat.W;
	}
}

void FlockLeader::Unserialize(KBEngine::MemoryStream& stream)
{
	stream >> ID_;
	stream >> beginStep_ >> endStep_;
	KBE_ASSERT(endStep_ > beginStep_);
	stream >> radius_ >> range_;
	stream >> force_;
	for (int32_t i=0; i<FishType_Count; ++i)
	{
		uint8_t ft = 0;
		stream >> ft;
		fishType_[i] = (bool)ft;
	}
	uint32_t len = 0;
	stream >> len;
	for (uint32_t i = 0; i < len; ++i)
	{
		PilotData data;
		VInt3& pos = data.pos;
		stream >> pos.x >> pos.y >> pos.z;
		VInt4& quat = data.quat;
		stream >> quat.X >> quat.Y >> quat.Z >> quat.W;
		data_.push_back(data);
	}
}

void FlockLeader::Update(const Flock* flock, const std::vector<AFlockAgent*>& context)
{
	uint32_t step = flock->getCameraStep();
	if (step >= beginStep_ && step <= endStep_)
	{
		if (data_.size() > 0)
		{
			VInt3& des = data_[0].pos;
			for (auto& item : context)
			{
				if (fishType_[(int32_t)item->GetFishType()] && item->GetPilot() == nullptr)
				{
					VInt3 dis = item->GetPos() - des;
					if (dis.magnitude() <= range_)
					{
						item->SetPilot(this, true);
					}
					//if (VInt3::DotLong(dis, data_[0].quat.GetForwardVector()) < 0)
					//{
					//	item->SetPilot(this, true);
					//}
				}
			}
		}
	}
}

uint32_t FlockLeader::GetID()
{
	return ID_;
}

VInt3 FlockLeader::UpdateAgent(const Flock* flock, AFlockAgent& agent)
{
	if (flock->getCameraStep() == endStep_)
	{
		agent.ClearPilot();
		return VInt3::zero;
	}
	uint32_t pilotStep = agent.GetPilotStep();
	uint32_t len = data_.size();
	if (pilotStep >= len - 1)
	{
		agent.ClearPilot();
		return VInt3::zero;
	}
	if (pilotStep == 0)
	{
		VInt3& des = data_[0].pos;
		VInt3 dis = des - agent.GetPos();
		if (dis.magnitude() <= radius_)
		{
			agent.UpdatePilotStep(1);
			return data_[0].quat.GetForwardVector().NormalizeTo(force_);
		}
		else
		{
			return dis;
		}
	}
	else
	{
		VInt3& des = data_[pilotStep].pos;
		VInt3 dis = des - agent.GetPos();
		int64_t dl = dis.sqrMagnitudeLong();
		uint32_t i = pilotStep + 1;
		for (; i <= len - 1; ++i)
		{
			VInt3& odes = data_[i].pos;
			VInt3 odis = odes - agent.GetPos();
			if (odis.sqrMagnitudeLong() > dl)
			{
				break;
			}
		}
		agent.UpdatePilotStep(i);
		if (i <= len - 1)
		{
			return data_[i].quat.GetForwardVector().NormalizeTo(force_);
			//VInt3& odes = data_[i].pos;
			//VInt3 odis = odes - agent.GetPos();
			//if (odis.magnitude() <= radius_)
			//{
			//	return data_[i].quat.GetForwardVector().NormalizeTo(force_);
			//}
			//else
			//{
			//	return data_[i].quat.GetForwardVector().NormalizeTo(force_) + odis;
			//}
		}
		else
		{
			return VInt3::zero;
		}
	}

	//if (pilotStep == 0)
	//{
	//	VInt3& des = data_[0].pos;
	//	VInt3 dis = des - agent.GetPos();
	//	if (dis.magnitude() <= radius_)
	//	{
	//		agent.UpdatePilotStep();
	//		return (data_[1].pos - des) * STEP_PER_SECOND;
	//	}
	//	else
	//	{
	//		return dis;
	//	}
	//}
	//else
	//{
	//	VInt3& des = data_[pilotStep].pos;
	//	VInt3 dis = des - agent.GetPos();
	//	agent.UpdatePilotStep();
	//	VInt3 dir = data_[pilotStep + 1].pos - des;
	//	if (dis.magnitude() <= radius_)
	//	{
	//		return dir * STEP_PER_SECOND;
	//	}
	//	else
	//	{
	//		return dis + dir;
	//	}
	//}
}