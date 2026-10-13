local root=arg[1];local f=assert(io.open(root..'/lib/gen3_frlg.lua'));local source=f:read('*a');f:close()
local a=assert(source:find('  local function frlgBackdrop(game, st)',1,true));local b=assert(source:find('  local function frlgBackdropImage',a,true))
local router=assert(loadfile(root..'/data/hoenn_battle_backgrounds.lua'))()
local current,terrain='EM_ROUTE_119',0;local T={GRASS=0,LONG_GRASS=1,SAND=2,UNDERWATER=3,WATER=4,POND=5,MOUNTAIN=6,CAVE=7,BUILDING=8,PLAIN=9,GROUDON=11,LEADER=14}
local env=setmetatable({mod={options={get=function()return true end}},okVersion=true,GameVersion={get=function()return 'emerald'end},
 okBg=true,BattleBg={TERRAIN=T,terrainId=function()return terrain end},hoennRouter=router,hoennBackdropCache=setmetatable({},{__mode='k'}),
 hdArenaRouter={resolve=function()error('Hoenn should not use Kanto map router')end,period=function()return 'night'end},
 currentFrlgMap=function()return current,{canonical=current,def={kind='route'}}end},{__index=_G})
local resolve=assert(load(source:sub(a,b-1)..'\nreturn frlgBackdrop','production backdrop bridge','t',env))()
local checks=0;local function eq(a,b)checks=checks+1;assert(a==b,tostring(a)..' ~= '..tostring(b))end
local function call(raw)return resolve({}, {terrain=raw or 0})end
eq(call().file,'grass_night');terrain=14;eq(call(0),nil);terrain=11;eq(call(0),nil)
terrain=3;current='EM_UNDERWATER_ROUTE_124';eq(call(),nil)
terrain=2;current='EM_ROUTE_111';eq(call(),nil)
terrain=7;current='EM_GRANITE_CAVE_B1F';eq(call().file,'cave_dark')
terrain=4;eq(call(7).file,'sea_night')
local state={terrain=0};terrain=0;current='EM_ROUTE_119';eq(resolve({},state).file,'grass_night')
terrain=4;eq(resolve({},state).file,'grass_night');eq(call().file,'sea_night')
print('KIM production bridge checks',checks)
