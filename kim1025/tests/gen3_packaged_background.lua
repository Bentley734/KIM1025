-- Exercise the complete bridge on all host/orientation paths with no PNG cache.
local f=assert(io.open('tests/portrait_battle.lua'));local s=f:read('*a');f:close()
s=s:gsub('_kimAssetProvider={image=function%(%)return bg end}',
 '_kimAssetProvider={image=function(path)if path:find("/aspect/",1,true)then return bg end end}')
s=s:gsub("if p=='data/hd_battle_backgrounds.lua'then return read%(p%)end",
 "if p=='data/hd_battle_backgrounds.lua' or p=='data/aspect_battle_backgrounds.lua'then return read(p)end")
assert(load(s,'full packaged background bridge','t'))()
