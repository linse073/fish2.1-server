#include "BulletLayerWidget.h"
#include "BulletWidget.h"
#include "KBECommon.h"

void UBulletLayerWidget::Init()
{
	for (int32_t i = 0; i < 50; i++) 
	{
		UBulletWidget* bullet = new UBulletWidget();
		pool_.push_back(bullet);
	}
}

void UBulletLayerWidget::Clear()
{
	for (auto& item : pool_)
	{
		KBE_SAFE_RELEASE(item);
	}
	pool_.clear();
}

UBulletWidget* UBulletLayerWidget::GetBullet()
{
	UBulletWidget* bullet = nullptr;
	if (pool_.empty())
	{
		bullet = new UBulletWidget();
	}
	else
	{
		bullet = pool_.back();
		pool_.pop_back();
	}
	KBE_ASSERT(bullet);
	return bullet;
}

void UBulletLayerWidget::RecycleBullet(UBulletWidget* bullet)
{
	pool_.push_back(bullet);
}