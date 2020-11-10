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
#include "MemoryStream.h"

Flock::Flock(void* callback, uint32_t randSeed)
	:id_(0),
	cameraPos_(VInt3::zero),
	cameraQuat_(VInt4::Identity),
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
	id_ = 0;
	cameraStep_ = 0;
}

void Flock::clear()
{
	id_ = 0;
	cameraPos_ = VInt3::zero;
	cameraQuat_ = VInt4::Identity;
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
}

const VInt3& Flock::getSphereCenter() const
{
	return sphereCenter_;
}

void Flock::onFire_fast(uint8_t index, int32_t x, int32_t y)
{
	VInt2 pos(x, y);
	const VInt2& fortPos = fortPos_[index];
	VInt2 dis = pos - fortPos;
	UBulletWidget* bullet = bulletLayer_->GetBullet();
	if (bullet)
	{
		++id_;
		VInt2 td = dis;
		td.NormalizeTo(flockAsset_->MuzzleLength);
		VInt2 bulletPos = fortPos + td;
		dis.NormalizeTo(flockAsset_->BulletSpeed);
		bullet->Init_fast(id_, dis, bulletPos);
		bullet_.push_back(bullet);
		bulletMap_[id_] = bullet;
	}
}

void Flock::onHit_fast(uint8_t index, uint32_t bulletid, uint32_t fishid)
{
	int32_t rate = random_->Range(0, 100);
	std::map<uint32_t, UBulletWidget*>::iterator pBullet = bulletMap_.find(bulletid);
	if (pBullet != bulletMap_.end())
	{
		UBulletWidget* bullet = pBullet->second;
		bullet->Clear();
		bullet_.erase(std::remove(std::begin(bullet_), std::end(bullet_), bullet), std::end(bullet_));
		bulletMap_.erase(pBullet);
		bulletLayer_->RecycleBullet(bullet);
	}
	std::map<uint32_t, AFlockAgent*>::iterator pAgent = agentMap_.find(fishid);
	if (pAgent != agentMap_.end())
	{
		AFlockAgent* agent = pAgent->second;
		agent->OnHit_fast(rate < 10);
		if (agent->IsDead())
		{
			fishCount_[int32_t(agent->GetFishType())].curCount -= 1;
			agent->Clear();
			agent_.erase(std::remove(std::begin(agent_), std::end(agent_), agent), std::end(agent_));
			agentMap_.erase(pAgent);
			pool_->RecycleAgent(agent);
		}
	}
}

void Flock::update_fast()
{
	updateCamera_fast();
	newAgent_fast();
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

void* Flock::getCallback() const
{
	return callback_;
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
		PathData data;
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

void Flock::updateCamera_fast()
{
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
	if (newFishAsset->RandomPos)
	{
		int32_t randomRadius = newFishAsset->RandomRadius;
		VInt3 dir = IntMath::SphereNormalPos(random_);
		int32_t scale = 100;
		for (int32_t i = 0; i < newFishAsset->InitCount; ++i)
		{
			VInt3 pos;
			pos.x = random_->Range(-randomRadius, randomRadius) * 1000;
			pos.y = random_->Range(-randomRadius, randomRadius) * 1000;
			pos.z = random_->Range(-randomRadius, randomRadius) * 1000;
			pos = initPos + pos;
			if (newFishAsset->RandomDir)
			{
				dir = IntMath::SphereNormalPos(random_);
			}
			if (newFishAsset->RandomScale)
			{
				scale = random_->Range(newFishAsset->MinScale, newFishAsset->MaxScale);
			}
			AFlockAgent* agent = pool_->GetAgent();
			++id_;
			agent->Init_fast(id_, scale, pos, dir, newFishAsset->FishAsset, newFishAsset->FishType);
			agent_.push_back(agent);
			agentMap_[id_] = agent;
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
				scale = random_->Range(newFishAsset->MinScale, newFishAsset->MaxScale);
			}
			AFlockAgent* agent = pool_->GetAgent();
			++id_;
			agent->Init_fast(id_, scale, initPos, dir, newFishAsset->FishAsset, newFishAsset->FishType);
			agent_.push_back(agent);
			agentMap_[id_] = agent;
		}
	}
	fishCount_[int32_t(newFishAsset->FishType)].curCount += newFishAsset->InitCount;
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
				stream >> x >> y;
				onFire_fast(userPos, x, y);
			}
			break;
			case uint8_t(OP_hit):
			{
				uint32_t bulletid, fishid;
				stream >> bulletid >> fishid;
				onHit_fast(userPos, bulletid, fishid);
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

void Flock::readData(KBEngine::MemoryStream& stream)
{
	stream >> id_;
	uint64_t randSeed = 0;
	stream >> randSeed;
	random_->SetSeed(randSeed);
	stream >> cameraStep_;
	if (cameraStep_ > 0 && cameraPath_.size() > 0)
	{
		uint32_t step = cameraStep_ % cameraPath_.size();
		const PathData& data = cameraPath_[step];
		cameraPos_ = data.pos;
		cameraQuat_ = data.quat;
		VInt3 cforward = cameraQuat_.GetForwardVector();
		sphereCenter_ = cameraPos_ + cforward.NormalizeTo(flockAsset_->SphereCenterByCameraForward);
		((FlockSphere*)obstacle_[0])->SetCenter(cameraPos_);
	}
	uint16_t agentSize = 0;
	stream >> agentSize;
	for (uint16_t i = 0; i < agentSize; i++)
	{
		AFlockAgent* agent = pool_->GetAgent();
		agent->Read_Data(stream);
		agent_.push_back(agent);
		agentMap_[agent->GetID()] = agent;
		fishCount_[int32_t(agent->GetFishType())].curCount++;
	}
	uint16_t bulletSize = 0;
	stream >> bulletSize;
	for (uint16_t i = 0; i < bulletSize; i++)
	{
		UBulletWidget* bullet = bulletLayer_->GetBullet();
		if (bullet)
		{
			bullet->Read_Data(stream);
			bullet_.push_back(bullet);
			bulletMap_[bullet->GetID()] = bullet;
		}
	}
}