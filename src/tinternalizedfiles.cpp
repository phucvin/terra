//auto-generate files that defines the data for the internalized headers
#include "stdint.h"
#include "internalizedfiles.h"
#include "terra.h"
#include <string>

int terra_loadbytecodes(lua_State * L, const unsigned char * bytecodes, size_t size, const char * name) {
  int err = luaL_loadbuffer(L, (const char *) bytecodes, size, name);
  if(err)
    return err;
  
  lua_getglobal(L,"package");
  lua_getfield(L,-1,"preload");
  lua_pushvalue(L,-3);
  lua_setfield(L,-2,name);
  lua_pop(L,3);
  return 0;
}

int terra_registerinternalizedfiles(lua_State * L, int terratable) {
    for(int i = 0; luafile_indices[i] != -1; i++) {
        int idx = luafile_indices[i];
        std::string name = headerfile_names[idx];
        int err = terra_loadbytecodes(L,headerfile_contents[idx],headerfile_sizes[idx],name.substr(1,name.size() - 4).c_str());
        if(err)
            return err;
    }
    lua_getglobal(L,"require");
    lua_pushstring(L,"terralib");
    int err = lua_pcall(L,1,0,0);
    if(err)
        return err;
    
    lua_getfield(L,terratable,"registerinternalizedfiles");
    lua_pushlightuserdata(L,&headerfile_names[0]);
    lua_pushlightuserdata(L,&headerfile_contents[0]);
    lua_pushlightuserdata(L,&headerfile_sizes[0]);
    lua_call(L,3,0);
    
    return 0;
}