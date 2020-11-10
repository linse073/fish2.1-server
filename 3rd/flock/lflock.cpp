#include <stdint.h>
#include <cstring>
#include <cstdlib>
#include "Flock.h"
#include "lua.hpp"
#include "MemoryStream.h"

#define check_flock(L, idx)\
	*(Flock**)luaL_checkudata(L, idx, "flock_meta")

struct Callback {
    uint64_t handle;
    lua_State* L;
};

// static int flock_callback(const char *buf, int len, ikcpcb *kcp, void *arg) {
//     struct Callback* c = (struct Callback*)arg;
//     lua_State* L = c -> L;
//     uint64_t handle = c -> handle;

//     lua_rawgeti(L, LUA_REGISTRYINDEX, handle);
//     lua_pushlstring(L, buf, len);
//     lua_call(L, 1, 0);

//     return 0;
// }

static int flock_gc(lua_State* L) {
	Flock* flock = check_flock(L, 1);
	if (flock == NULL) {
        return 0;
	}
    struct Callback* c = (struct Callback*)flock->getCallback();
    luaL_unref(L, LUA_REGISTRYINDEX, c->handle);
    free(c);
    KBE_SAFE_RELEASE(flock);
    return 0;
}

static int lflock_create(lua_State* L) {
    uint64_t handle = luaL_ref(L, LUA_REGISTRYINDEX);

    struct Callback* c = (struct Callback*)malloc(sizeof(struct Callback));
    memset(c, 0, sizeof(struct Callback));
    c->handle = handle;
    c->L = L;

    uint32_t randSeed = luaL_checkinteger(L, 4);
    Flock* flock = new Flock(c, randSeed);
    size_t flockSize = 0;
	const char* flockData = luaL_checklstring(L, 1, &flockSize);
    flock->loadFlockAssetData(flockData, flockSize);
    size_t cameraSize = 0;
    const char* cameraData = luaL_checklstring(L, 2, &cameraSize);
    flock->loadCameraData(cameraData, cameraSize);
    size_t obstacleSize = 0;
    const char* obstacleData = luaL_checklstring(L, 3, &obstacleSize);
    flock->loadObstacleData(obstacleData, obstacleSize);

    *(Flock**)lua_newuserdata(L, sizeof(void*)) = flock;
    luaL_getmetatable(L, "flock_meta");
    lua_setmetatable(L, -2);
    return 1;
}

static int lflock_update(lua_State* L) {
	Flock* flock = check_flock(L, 1);
	if (flock == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: flock not args");
        return 2;
	}
    flock->update_fast();
    return 0;
}

static int lflock_oncmd(lua_State* L) {
	Flock* flock = check_flock(L, 1);
	if (flock == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: flock not args");
        return 2;
	}
    size_t cmdSize = 0;
	const char* cmdData = luaL_checklstring(L, 2, &cmdSize);
    flock->doKeyStepCmd_fast(cmdData, cmdSize);
    return 0;
}

static int lflock_pack(lua_State* L) {
	Flock* flock = check_flock(L, 1);
	if (flock == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: flock not args");
        return 2;
	}
    KBEngine::MemoryStream stream;
    flock->packData(stream);
    lua_pushlstring(L, (const char *)stream.data(), stream.length());
    return 1;
}

static const struct luaL_Reg lflock_methods [] = {
    { "lflock_update" , lflock_update },
    { "lflock_onfire" , lflock_oncmd },
    { "lflock_pack" , lflock_pack },
	{NULL, NULL},
};

static const struct luaL_Reg l_methods[] = {
    { "lflock_create" , lflock_create },
    {NULL, NULL},
};

extern "C"
{
int luaopen_lflock(lua_State* L) {
    luaL_checkversion(L);

    luaL_newmetatable(L, "flock_meta");

    lua_newtable(L);
    luaL_setfuncs(L, lflock_methods, 0);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, flock_gc);
    lua_setfield(L, -2, "__gc");

    luaL_newlib(L, l_methods);

    return 1;
}
}

