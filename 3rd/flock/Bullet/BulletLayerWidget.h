#ifndef __BULLET_LAYER_WIDGET_H__
#define __BULLET_LAYER_WIDGET_H__

#include <vector>

class UBulletWidget;

class UBulletLayerWidget
{
public:
	void Init();
	void Clear();

	UBulletWidget* GetBullet();
	void RecycleBullet(UBulletWidget* bullet);

private:
	std::vector<UBulletWidget*> pool_;
};

#endif // __BULLET_LAYER_WIDGET_H__