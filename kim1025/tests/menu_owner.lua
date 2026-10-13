local f=assert(io.open('lib/gen3_frlg.lua'));local s=f:read('*a');f:close()
local a=assert(s:find('  local function drawFullWidthPanelBacking',1,true));local b=assert(s:find('  local function battlerAt',a,true))
local draws=0;local owned=true;local handle={exports={battleUi={ownsGen3Panels=function()return owned end}}}
local mod={find=function(self,id)assert(id=='gen3transparency');return handle end}
local env=setmetatable({mod=mod,okChrome=true,BattleChrome={drawPanel=function()draws=draws+1 end},withNativeViewport=function(_,_,_,_,fn)return fn()end},{__index=_G})
local draw=assert(load(s:sub(a,b-1)..'return drawFullWidthPanelBacking','actual underlay','t',env))()
assert(not draw(0,0,1,1) and draws==0)
owned=false;assert(draw(0,0,1,1) and draws==1)
owned=true;mod.find=function(id)assert(id=='gen3transparency');return handle end
assert(not draw(0,0,1,1) and draws==1)
mod.find=nil;assert(draw(0,0,1,1) and draws==2)
print('PASS 4 Gen3 custom panel ownership / standalone fallback checks')
