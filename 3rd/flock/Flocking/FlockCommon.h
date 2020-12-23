#ifndef __FLOCK_COMMON_H__
#define __FLOCK_COMMON_H__

#include "VFactor.h"
#include "FishType.h"

const static VFactor STEP_DELTA(1LL, 30LL);
const static int8_t STEP_PER_SECOND = 30;

static const int32_t FishType_Count = int32_t(EFishType::FishType_Boss) + 1;

#endif // __FLOCK_COMMON_H__