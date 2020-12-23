#include <cstring>
#include <algorithm>
#include "Flock.h"
#include "FlockAgent.h"
#include "FlockPool.h"
#include "CompositeBehavior.h"
#include "FlockSphere.h"
#include "FlockCuboid.h"
#include "VInt4.h"
#include "FlockAsset.h"
#include "BulletWidget.h"
#include "BulletLayerWidget.h"
#include "FlockCommon.h"
#include "IntMath.h"
#include "ContextFilter.h"
#include "MemoryStreamLittle.h"
#include "FlockLeader.h"
#include "BossAsset.h"

extern void flock_callback(void* arg, uint8_t cbtype, KBEngine::MemoryStreamLittle& stream);

Flock::Flock(void* callback, uint32_t randSeed)
	:id_(1000),
	cameraPos_(VInt3::zero),
	cameraQuat_(VInt4::Identity),
	cameraRotator_(VInt3::zero),
	sphereCenter_(VInt3::zero),
	pool_(new FlockPool()),
	behavior_(new CompositeBehavior()),
	flockAsset_(nullptr),
	cameraStep_(0),
	screenSize(VInt2::zero),
	bulletLayer_(new UBulletLayerWidget()),
	callback_(callback),
	random_(new Random(randSeed))
{
	memset(fishCount_, 0, sizeof(fishCount_));
	memset(fortPos_, 0, sizeof(fortPos_));
}

Flock::~Flock()
{
	clear();
	KBE_SAFE_RELEASE(behavior_);
	KBE_SAFE_RELEASE(pool_);
	KBE_SAFE_RELEASE(bulletLayer_);
	KBE_SAFE_RELEASE(random_);
}

void Flock::init(const UFlockAsset* flockAsset)
{
	flockAsset_ = flockAsset;
	((CompositeBehavior*)behavior_)->Init(flockAsset_);
	for (auto& item : flockAsset_->NewFishAsset)
	{
		fishType_[int32_t(item->FishType)].push_back(item);
	}
	for (auto& item : flockAsset_->BossAsset)
	{
		BossInfo bossInfo;
		bossInfo.status = BossStatus_None;
		bossInfo.step = 0;
		bossInfo.totalStep = 0;
		bossInfo.asset = item;
		boss_.push_back(bossInfo);
		int32_t index = 0;
		for (auto& skillItem : item->SkillAsset)
		{
			skillItem->index = index;
			++index;
		}
	}
	FishCount& smallCount = fishCount_[int32_t(FishType_Small)];
	smallCount.maxCount = flockAsset_->SmallFishRatio;
	smallCount.minCount = flockAsset_->SmallFishRatio;
	FishCount& bigCount = fishCount_[int32_t(FishType_Big)];
	bigCount.maxCount = flockAsset_->BigFishRatio;
	bigCount.minCount = flockAsset_->BigFishRatio;
	FishCount& hugeCount = fishCount_[int32_t(FishType_Huge)];
	hugeCount.maxCount = flockAsset_->HugeFishRatio;
	hugeCount.minCount = flockAsset_->HugeFishRatio;
	FishCount& bossCount = fishCount_[int32_t(FishType_Boss)];
	bossCount.maxCount = 1;
	bossCount.minCount = 0;
	pool_->Init();
	bulletLayer_->Init();
	screenSize.x = flockAsset_->ScreenWidth;
	screenSize.y = flockAsset_->ScreenHight;
	fortPos_[0] = VInt2(flockAsset_->FortPositionX, screenSize.y);
	fortPos_[1] = VInt2(screenSize.x - flockAsset_->FortPositionX, screenSize.y);
	fortPos_[2] = VInt2(flockAsset_->FortPositionX, 0);
	fortPos_[3] = VInt2(screenSize.x - flockAsset_->FortPositionX, 0);
	id_ = 1000;
	cameraStep_ = 0;
}

void Flock::clear()
{
	id_ = 1000;
	cameraPos_ = VInt3::zero;
	cameraQuat_ = VInt4::Identity;
	cameraRotator_ = VInt3::zero;
	sphereCenter_ = VInt3::zero;
	for (auto& item : agent_)
	{
		KBE_SAFE_RELEASE(item);
	}
	agent_.clear();
	pool_->Clear();
	bulletLayer_->Clear();
	KBE_SAFE_RELEASE(flockAsset_);
	for (int32_t i=0; i<FishType_Count; ++i)
	{
		fishType_[i].clear();
	}
	memset(fishCount_, 0, sizeof(fishCount_));
	cameraPath_.clear();
	cameraStep_ = 0;
	for (auto& item : obstacle_)
	{
		KBE_SAFE_RELEASE(item);
	}
	obstacle_.clear();
	
	memset(fortPos_, 0, sizeof(fortPos_));
	for (auto& item : bullet_)
	{
		KBE_SAFE_RELEASE(item);
	}
	bullet_.clear();
	agentMap_.clear();
	bulletMap_.clear();
	callback_ = nullptr;
	for (auto& item : pilot_)
	{
		KBE_SAFE_RELEASE(item);
	}
	pilot_.clear();
	boss_.clear();
}

const VInt3& Flock::getSphereCenter() const
{
	return sphereCenter_;
}

void Flock::onFire_fast(uint32_t id, uint32_t kind, uint8_t index, int32_t x, int32_t y, uint32_t multi, uint32_t costGold, uint64_t fishScore)
{
	VInt2 pos(x, y);
	const VInt2& fortPos = fortPos_[index];
	VInt2 dis = pos - fortPos;
	UBulletWidget* bullet = bulletLayer_->GetBullet();
	if (bullet)
	{
		VInt2 td = dis;
		td.NormalizeTo(flockAsset_->MuzzleLength);
		VInt2 bulletPos = fortPos + td;
		dis.NormalizeTo(flockAsset_->BulletSpeed);
		bullet->Init_fast(id, kind, dis, bulletPos, index, multi, costGold);
		bullet_.push_back(bullet);
		bulletMap_[id] = bullet;
	}
}

void Flock::onHit_fast(uint8_t index, uint32_t bulletid, uint32_t fishid)
{
	auto pBullet = bulletMap_.find(bulletid);
	bool findBullet = false;
	if (pBullet != bulletMap_.end())
	{
		UBulletWidget* bullet = pBullet->second;
		bullet->Clear();
		for (auto it = bullet_.begin(); it != bullet_.end(); ) 
		{
			if ((*it)->GetID() == bullet->GetID()) 
			{
				it = bullet_.erase(it);
				findBullet = true;
			} 
			else 
			{
				++it;
			}
		}
		// bullet_.erase(std::remove(std::begin(bullet_), std::end(bullet_), bullet), std::end(bullet_));
		bulletMap_.erase(pBullet);
		bulletLayer_->RecycleBullet(bullet);
	}
	if (!findBullet)
	{
		printf("Can't find bullet %d.\n", bulletid);
	}
	if (fishid > 1000)
	{
		auto pAgent = agentMap_.find(fishid);
		bool findAgent = false;
		if (pAgent != agentMap_.end())
		{
			AFlockAgent* agent = pAgent->second;
			if (!agent->IsDead())
			{
				agent->OnHit_fast(false);
				findAgent = true;
			}
			else
			{
				findAgent = true;
			}
		}
		if (!findAgent)
		{
			printf("Can't find agent %d.\n", fishid);
		}
	}
}

void Flock::onDead_fast(uint8_t index, uint32_t bulletid, uint32_t fishid, uint16_t multi, uint16_t bulletMulti, uint32_t winGold, uint64_t fishScore)
{
	auto pAgent = agentMap_.find(fishid);
	bool findAgent = false;
	if (pAgent != agentMap_.end())
	{
		AFlockAgent* agent = pAgent->second;
		if (!agent->IsDead())
		{
			agent->OnHit_fast(true);
			if (agent->IsDead())
			{
				fishCount_[int32_t(agent->GetFishType())].curCount -= 1;
				agent->Clear();
				for (auto it = agent_.begin(); it != agent_.end(); ) 
				{
					if ((*it)->GetID() == agent->GetID()) 
					{
						it = agent_.erase(it);
						findAgent = true;
					} 
					else 
					{
						++it;
					}
				}
				// agent_.erase(std::remove(std::begin(agent_), std::end(agent_), agent), std::end(agent_));
				agentMap_.erase(pAgent);
				pool_->RecycleAgent(agent);
			}
			else
			{
				findAgent = true;
			}	
		}
		else
		{
			findAgent = true;
		}
	}
	if (!findAgent)
	{
		printf("Can't find agent %d.\n", fishid);
	}
}

void Flock::onSetCannon_fast(uint8_t index, uint16_t cannon)
{
	// TODO: set cannon
}

void Flock::update_fast()
{
	updateCamera_fast();
	updatePilot();
	newAgent_fast();
	updateBoss_fast();
	updateAgent_fast();
	updateBullet_fast();
}

int32_t Flock::getSphereRadius() const
{
	return flockAsset_->SphereRadius;
}

int32_t Flock::getRotationDegreesPerStep() const
{
	return flockAsset_->RotationDegreesPerStep;
}

int32_t Flock::getFlockRotationDegreesPerStep() const
{
	return flockAsset_->FlockRotationDegreesPerStep;
}

uint32_t Flock::getCameraStep() const
{
	if (cameraPath_.size() > 0)
	{
		return cameraStep_ % cameraPath_.size();
	}
	else
	{
		return 0;
	}
}

void* Flock::getCallback() const
{
	return callback_;
}

uint32_t Flock::getBulletMulti(uint32_t bulletid) const
{
	auto pBullet = bulletMap_.find(bulletid);
	if (pBullet != bulletMap_.end())
	{
		UBulletWidget* bullet = pBullet->second;
		return bullet->GetMulti();
	}
	else
	{
		printf("Can't find bullet %d.\n", bulletid);
		return 1;
	}
}

void Flock::loadFlockAssetData(const char* Result, uint32_t length)
{
	KBEngine::MemoryStream stream;
	stream.append(Result, length);

	UFlockAsset* flockAsset = new UFlockAsset();
	flockAsset->Unserialize(stream);
	init(flockAsset);
}

void Flock::loadCameraData(const char* Result, uint32_t length)
{
	KBEngine::MemoryStream stream;
	stream.append(Result, length);

	while (stream.length() > 0)
	{
		PathData data;
		stream >> data.pos.x >> data.pos.y >> data.pos.z;
		stream >> data.quat.X >> data.quat.Y >> data.quat.Z >> data.quat.W;
		cameraPath_.push_back(data);
	}
}

void Flock::loadObstacleData(const char* Result, uint32_t length)
{
	KBEngine::MemoryStream stream;
	stream.append(Result, length);

	obstacle_.push_back(new FlockSphere(VInt3::zero, flockAsset_->CameraObstacleSphereRadius));
	while (stream.length() > 0)
	{
		uint8_t type;
		stream >> type;
		switch (type)
		{
			case 1:
			{
				VInt3 center;
				stream >> center.x >> center.y >> center.z;
				int32_t radius;
				stream >> radius;
				obstacle_.push_back(new FlockSphere(center, radius));
			}
			break;
			case 2:
			{
				VInt3 center;
				stream >> center.x >> center.y >> center.z;
				int32_t l, w, h;
				stream >> l >> w >> h;
				obstacle_.push_back(new FlockCuboid(center, l, w, h));
			}
			break;
			default:
			{
				//ERROR_MSG("Unknown obstacle type.");
				//SCREEN_ERROR_MSG("Unknown obstacle type.");
			}
			break;
		}
	}
}

void Flock::loadPilotData(const char* Result, uint32_t length)
{
	KBEngine::MemoryStream stream;
	stream.append(Result, length);

	while (stream.length() > 0)
	{
		uint8_t type;
		stream >> type;
		switch (type)
		{
		case 1:
		{
			FlockPilot* pilot = new FlockLeader();
			pilot->Unserialize(stream);
			pilot_.push_back(pilot);
		}
		break;
		default:
		{
			//ERROR_MSG("Unknown pilot type.");
			//SCREEN_ERROR_MSG("Unknown pilot type.");
		}
		break;
		}
	}
}

void Flock::updateCamera_fast()
{
	for (auto& item : boss_)
	{
		if (item.status == BossStatus_None)
		{
			if (item.totalStep > 0)
			{
				item.totalStep = 0;
			}
		}
		else
		{
			return;
		}
	}
	if (cameraPath_.size() > 0)
	{
		uint32_t step = cameraStep_ % cameraPath_.size();
		const PathData& data = cameraPath_[step];
		cameraPos_ = data.pos;
		cameraQuat_ = data.quat;
		VInt3 cforward = cameraQuat_.GetForwardVector();
		sphereCenter_ = cameraPos_ + cforward.NormalizeTo(flockAsset_->SphereCenterByCameraForward);
		((FlockSphere*)obstacle_[0])->SetCenter(cameraPos_);
		++cameraStep_;
	}
}

void Flock::newAgent_fast()
{
	for (int32_t i = 0; i < int32_t(FishType_Boss); ++i)
	{
		FishCount& fishCount = fishCount_[i];
		if (fishCount.curCount < fishCount.minCount)
		{
			std::vector<UNewFishAsset*>& newFishAsset = fishType_[i];
			if (newFishAsset.size() > 0)
			{
				newAgent_fast(newFishAsset[random_->Range(0, newFishAsset.size())]);
			}
		}
	}
	// TODO: new boss
}

void Flock::newAgent_fast(const UNewFishAsset* newFishAsset)
{
	VInt3 initPos = IntMath::SphereNormalPos(random_);
	initPos.NormalizeTo(flockAsset_->SphereRadius);
	initPos = sphereCenter_ + initPos;
	KBEngine::MemoryStreamLittle stream;
	uint8_t count = 0;
	if (newFishAsset->RandomPos)
	{
		int32_t randomRadius = newFishAsset->RandomRadius;
		VInt3 dir = IntMath::SphereNormalPos(random_);
		int32_t scale = 100;
		for (int32_t i = 0; i < newFishAsset->InitCount; ++i)
		{
			VInt3 pos;
			pos.x = random_->Range(-randomRadius, randomRadius + 1) * 1000;
			pos.y = random_->Range(-randomRadius, randomRadius + 1) * 1000;
			pos.z = random_->Range(-randomRadius, randomRadius + 1) * 1000;
			pos = initPos + pos;
			if (newFishAsset->RandomDir)
			{
				dir = IntMath::SphereNormalPos(random_);
			}
			if (newFishAsset->RandomScale)
			{
				scale = random_->Range(newFishAsset->MinScale, newFishAsset->MaxScale + 1);
			}
			AFlockAgent* agent = pool_->GetAgent();
			++id_;
			agent->Init_fast(id_, scale, pos, dir, newFishAsset->FishAsset, newFishAsset->FishType);
			agent_.push_back(agent);
			agentMap_[id_] = agent;
			++count;
			stream << id_ << (uint16_t)newFishAsset->FishAsset->ID;
		}
	}
	else
	{
		VInt3 dir = IntMath::SphereNormalPos(random_);
		int32_t scale = 100;
		for (int32_t i = 0; i < newFishAsset->InitCount; ++i)
		{
			if (newFishAsset->RandomDir)
			{
				dir = IntMath::SphereNormalPos(random_);
			}
			if (newFishAsset->RandomScale)
			{
				scale = random_->Range(newFishAsset->MinScale, newFishAsset->MaxScale + 1);
			}
			AFlockAgent* agent = pool_->GetAgent();
			++id_;
			agent->Init_fast(id_, scale, initPos, dir, newFishAsset->FishAsset, newFishAsset->FishType);
			agent_.push_back(agent);
			agentMap_[id_] = agent;
			++count;
			stream << id_ << (uint16_t)newFishAsset->FishAsset->ID;
		}
	}
	fishCount_[int32_t(newFishAsset->FishType)].curCount += newFishAsset->InitCount;
	KBE_ASSERT(count <= 100);
	for (uint8_t i = count; i < 100; i++)
	{
		stream << (uint32_t)0 << (uint16_t)0;
	}
	flock_callback(callback_, 1, stream);
}

void Flock::newAgent_fast(const VInt3& pos, const UNewFishAsset* newFishAsset)
{
	VInt3 dir = IntMath::SphereNormalPos(random_);
	int32_t scale = 100;
	KBEngine::MemoryStreamLittle stream;
	uint8_t count = 0;
	for (int32_t i = 0; i < newFishAsset->InitCount; ++i)
	{
		if (newFishAsset->RandomDir)
		{
			dir = IntMath::SphereNormalPos(random_);
		}
		if (newFishAsset->RandomScale)
		{
			scale = random_->Range(newFishAsset->MinScale, newFishAsset->MaxScale + 1);
		}
		AFlockAgent* agent = pool_->GetAgent();
		++id_;
		agent->Init_fast(id_, scale, pos, dir, newFishAsset->FishAsset, newFishAsset->FishType);
		agent_.push_back(agent);
		agentMap_[id_] = agent;
		++count;
		stream << id_ << (uint16_t)newFishAsset->FishAsset->ID;
	}
	fishCount_[int32_t(newFishAsset->FishType)].curCount += newFishAsset->InitCount;
	KBE_ASSERT(count <= 100);
	for (uint8_t i = count; i < 100; i++)
	{
		stream << (uint32_t)0 << (uint16_t)0;
	}
	flock_callback(callback_, 1, stream);
}

void Flock::updateAgent_fast()
{
	for (auto& item : agent_)
	{
		if (!item->IsDead())
		{
			ContextFilter filter(this, *item, agent_, obstacle_);
			item->Move_fast(behavior_->CalcMove(*item, filter));
		}
	}
}

void Flock::updateBullet_fast()
{
	for (auto& item : bullet_)
	{
		VInt2 dir = item->GetDir();
		VInt2 pos = item->GetPosition() + dir * STEP_DELTA;
		if (pos.x < 0)
		{
			pos.x = -pos.x;
			dir.x = -dir.x;
		}
		else if (pos.x > screenSize.x)
		{
			pos.x = screenSize.x - (pos.x - screenSize.x);
			dir.x = -dir.x;
		}
		if (pos.y < 0)
		{
			pos.y = -pos.y;
			dir.y = -dir.y;
		}
		else if (pos.y > screenSize.y)
		{
			pos.y = screenSize.y - (pos.y - screenSize.y);
			dir.y = -dir.y;
		}
		item->SetPosition_fast(pos);
		item->SetDir_fast(dir);
	}
}

void Flock::updateBoss_fast()
{
	uint32_t step = getCameraStep();
	for (auto& item : boss_)
	{
		UBossAsset* asset = item.asset;
		switch (item.status)
		{
		case BossStatus_None:
		{
			if (step == asset->BornStep)
			{
				changeBossStatus_fast(item);
			}
		}
		break;
		case BossStatus_Born:
		{
			++item.totalStep;
			if (item.totalStep >= asset->BornCD)
			{
				changeBossStatus_fast(item);
			}
			else
			{
				++item.step;
			}
		}
		break;
		case BossStatus_Swim:
		{
			++item.totalStep;
			if (item.totalStep >= asset->BornCD + asset->SwimCD)
			{
				changeBossStatus_fast(item);
			}
			else
			{
				++item.step;
			}
		}
		break;
		case BossStatus_Idle:
		{
			++item.totalStep;
			if (item.totalStep >= asset->BornCD + asset->SwimCD + asset->LiveStep)
			{
				changeBossStatus_fast(item);
			}
			else
			{
				uint32_t randNum = random_->Range(0u, asset->IdleCD);
				if (item.step >= randNum)
				{
					changeBossStatus_fast(item);
				}
				else
				{
					++item.step;
				}
			}
		}
		break;
		case BossStatus_Skill_0:
		case BossStatus_Skill_1:
		case BossStatus_Skill_2:
		{
			++item.totalStep;
			USkillAsset* skillAsset = asset->SkillAsset[item.status - BossStatus_Skill_0];
			if (item.step >= skillAsset->CD)
			{
				changeBossStatus_fast(item);
			}
			else
			{
				++item.step;
				// TODO: new fish
				for (auto& skillFish : skillAsset->SkillFishAsset)
				{
					if (skillFish->Step == item.step)
					{
						VInt3 pos(skillFish->PosX, skillFish->PosY, skillFish->PosZ);
						newAgent_fast(pos, skillFish->NewFishAsset);
					}
				}
			}
		}
		break;
		case BossStatus_Die:
		{
			++item.totalStep;
			if (item.totalStep >= asset->BornCD + asset->SwimCD + asset->LiveStep + asset->DieCD)
			{
				changeBossStatus_fast(item);
			}
			else
			{
				++item.step;
			}
		}
		break;
		default:
			break;
		}
	}
}

void Flock::changeBossStatus_fast(BossInfo& info)
{
	UBossAsset* asset = info.asset;
	if (info.totalStep < asset->BornCD)
	{
		info.status = BossStatus_Born;
		info.step = info.totalStep;
	}
	else if (info.totalStep < asset->BornCD + asset->SwimCD)
	{
		info.status = BossStatus_Swim;
		info.step = info.totalStep - asset->BornCD;
	}
	else if (info.totalStep < asset->BornCD + asset->SwimCD + asset->LiveStep)
	{
		uint32_t diffStep = info.totalStep - asset->BornCD - asset->SwimCD;
		if (info.status == BossStatus_Idle)
		{
			std::vector<USkillAsset*> randSkill;
			uint32_t totalRate = 0;
			for (auto& item : asset->SkillAsset)
			{
				if (item->CD < diffStep)
				{
					randSkill.push_back(item);
					totalRate += item->Rate;
				}
			}
			if (totalRate > 0)
			{
				uint32_t randRate = random_->Range(0u, totalRate);
				uint32_t rate = 0;
				for (auto& item : randSkill)
				{
					if (randRate < rate + item->Rate)
					{
						info.status = BossStatus(BossStatus_Skill_0 + item->index);
						info.step = 0;
						// TODO: new fish
						for (auto& skillFish : item->SkillFishAsset)
						{
							if (skillFish->Step == info.step)
							{
								VInt3 pos(skillFish->PosX, skillFish->PosY, skillFish->PosZ);
								newAgent_fast(pos, skillFish->NewFishAsset);
							}
						}
						break;
					}
					rate += item->Rate;
				}
			}
			else
			{
				info.status = BossStatus_Idle;
				info.step = 0;
			}
		}
		else
		{
			info.status = BossStatus_Idle;
			info.step = 0;
		}
	}
	else if (info.totalStep < asset->BornCD + asset->SwimCD + asset->LiveStep + asset->DieCD)
	{
		info.status = BossStatus_Die;
		info.step = info.totalStep - asset->BornCD - asset->SwimCD - asset->LiveStep;
	}
	else
	{
		info.status = BossStatus_None;
		info.step = 0;
	}
}

void Flock::doKeyStepCmd_fast(const char* Result, uint32_t length)
{
	KBEngine::MemoryStream stream;
	stream.append(Result, length);

	uint8_t cmdUserCount;
	stream >> cmdUserCount;
	for (uint8_t i = 0; i < cmdUserCount; ++i)
	{
		uint32_t userid;
		uint8_t userPos;
		uint8_t cmdCount;
		stream >> userid >> userPos >> cmdCount;
		--userPos;
		for (uint8_t j = 0; j < cmdCount; ++j)
		{
			uint8_t cmdType;
			stream >> cmdType;
			switch (cmdType)
			{
			case uint8_t(OP_fire):
			{
				int32_t x, y;
				uint32_t multi, id, kind, costGold;
				uint64_t fishScore;
				stream >> id >> kind >> x >> y >> multi >> costGold >> fishScore;
				onFire_fast(id, kind, userPos, x, y, multi, costGold, fishScore);
			}
			break;
			case uint8_t(OP_hit):
			{
				uint32_t bulletid, fishid;
				stream >> bulletid >> fishid;
				onHit_fast(userPos, bulletid, fishid);
			}
			break;
			case uint8_t(OP_dead):
			{
				uint32_t bulletid, fishid, winGold;
				uint16_t multi, bulletMulti;
				uint64_t fishScore;
				stream >> bulletid >> fishid >> multi >> bulletMulti >> winGold >> fishScore;
				onDead_fast(userPos, bulletid, fishid, multi, bulletMulti, winGold, fishScore);
			}
			break;
			case uint8_t(OP_set_cannon):
			{
				uint16_t cannon;
				stream >> cannon;
				onSetCannon_fast(userPos, cannon);
			}
			break;
			default:
			{
				KBE_ASSERT(false);
			}
			break;
			}
		}
	}
}

void Flock::packData(KBEngine::MemoryStream& stream)
{
	stream << id_;
	stream << random_->GetSeed();
	stream << cameraStep_;
	stream << (uint16_t)agent_.size();
	for (auto& item : agent_)
		item->Pack_Data(stream);
	stream << (uint16_t)bullet_.size();
	for (auto& item : bullet_)
		item->Pack_Data(stream);
}