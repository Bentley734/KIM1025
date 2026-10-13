-- Executes KIM's real capture and composition code with isolated gameplay.
local kim=arg[1] or '.'
local f=assert(io.open(kim..'/main.lua','rb'));local source=f:read('*a');f:close()
local checks=0
local function eq(a,b,label)checks=checks+1;assert(a==b,label..': '..tostring(a)..' ~= '..tostring(b))end
local function between(first,last)
 local start=assert(source:find(first,1,true));local stop=assert(source:find(last,start+#first,true))
 return source:sub(start,stop-1)
end
local function compile(code,env)
 local fn
 if setfenv then fn=assert(loadstring(code));setfenv(fn,env)
 else fn=assert(load(code,'production KIM battle UI','t',env))end
 return fn()
end
local canvas,draws,rectangles,clears,captures,scaleCalls=nil,{}, {},0,0,{}
local ui={canDrawBottom=function(b)return b.phase=='menu' or b.phase=='messages'end}
local seenRect,direct=true,true
ui.drawBottom=function(b,rect)seenRect=rect;return direct and ui.canDrawBottom(b)end
local graphics={
 push=function()end,pop=function()end,translate=function()end,origin=function()end,setShader=function()end,setColor=function()end,
 getCanvas=function()return canvas end,setCanvas=function(c)canvas=c end,
 scale=function(x,y)scaleCalls[#scaleCalls+1]={x,y}end,
 clear=function()clears=clears+1 end,
 rectangle=function(_,x,y,w,h)rectangles[#rectangles+1]={x,y,w,h}end,
 setBlendMode=function()end,
 newQuad=function(...)return {...}end,
 draw=function(image,...)draws[#draws+1]={image=image,args={...}}end,
}
local width,height=1047,699
local battle={phase='menu',game={},colorMode=function()return true end}
local mod={find=function(id)eq(id,'gen3transparency','merged customizer lookup');return {exports={battleUi=ui}}end,
 _kantoInMotionNativeMobileGen1=function()return false end,
 options={get=function(_,key)return key=='battleSprites' end},
 _kimBattleMoveMenu={draw=function(b)return b.phase=='moveSelect'end}}
local env=setmetatable({love={graphics=graphics},mod=mod,IS_GEN2=false,
 battleUiViewportRect=function()return 0,0,width,height end,
 touchBattleOrientation=function()return nil end,battleWorldMetrics=function()end,
 captureBattleText=function()captures=captures+1;return 'native text'end,
 sizedBattleCanvas=function(_,w,h)return {getWidth=function()return w end,getHeight=function()return h end}end,
 unpackCompat=unpack or table.unpack,
},{__index=_G})
local helpers=between('  local function menuBattleUi()','  local function battleOffsets(')
local text=between('  local function drawNativeBattleText(','  if mod.hooks and type(mod.hooks.wrap)')
local bottom=compile(helpers..text..'return drawNativeBattleText',env)
for _,size in ipairs({{1047,699},{1280,720},{5120,1440},{390,844}})do
 width,height=size[1],size[2];captures=0;draws={};seenRect=nil
 eq(bottom(battle,{}),true,'final bottom handled')
 eq(captures,0,'Emerald bottom bypasses GB capture')
 eq(#draws,0,'no low-resolution layer enlarged')
 local scale=math.min(width/160,height/144)
 eq(seenRect.w,160*scale,'existing dialog width retained')
 eq(seenRect.h,48*scale,'existing dialog height retained')
 eq(seenRect.x,math.floor((width-160*scale)*.5+.5),'existing dialog center retained')
 eq(seenRect.y,math.floor(height-48*scale+.5),'existing dialog baseline retained')
end
direct=false;captures=0;draws={}
eq(bottom(battle,{}),true,'native fallback drawn')
eq(captures,1,'native fallback captured once')
eq(draws[1].image,'native text','native fallback layer used')
battle.phase='moveSelect';captures=0;draws={};seenRect=nil
eq(bottom(battle,{}),true,'existing final move presenter retained')
eq(captures,0,'move menu never captures low-resolution text')
eq(seenRect,nil,'move presenter precedes dialog presenter')
battle.phase='menu';direct=true

local compose
mod.hooks={wrap=function(_,name,fn)eq(name,'render.compose','compose hook selected');compose=fn end}
env.require=function(name)eq(name,'src.core.Game','active game lookup');return {}end
env.pendingFullscreenBattle=battle
env.currentBattleState=function()return battle end
env.battleChildMenuOpen=function()return false end
env.battleLiteFullScreenActive=function()return true end
env.battleModernUiActive=function()return false end
env.battleBackgroundMode=function()return 'hd'end
local composeCode=between('    mod.hooks:wrap("render.compose", function(nextFn, renderer, ctx)','    -- Modern UI owns the lower command/message layer when selected.')
compile(helpers..composeCode,env)
local ctx={uiCanvas={getDimensions=function()return 160,144 end}}
rectangles={};clears=0
compose(function()return 'compose result'end,{},ctx)
eq(clears,1,'old source erased when final Emerald presenter owns bottom')
eq(#rectangles,0,'no stale GB bottom retained')
ui.canDrawBottom=function()return false end
rectangles={};clears=0
compose(function()end,{},ctx)
eq(clears,0,'native ownership preserves source bottom')
eq(rectangles[1][4],96,'native ownership erases only upper source')

-- Real HUD capture must preserve half-size font pixels and party icon targets.
local hud=between('  local function captureBattleHud(','  local BATTLE_HUD_SHADER =')
env.menuBattleUi=function()return ui end
env.logicalCanvas=function()error('HUD must not use 160x144 capture')end
battle.drawHUDs=function(self)
 eq(canvas:getWidth(),320,'HUD capture width doubled')
 eq(canvas:getHeight(),296,'HUD capture height doubled')
 eq(self._kantoInMotionPartyBallCanvas:getWidth(),320,'party target shares high-resolution coordinates')
end
local capture=compile(hud..'return captureBattleHud',env)
scaleCalls={};canvas=nil
local captured,party=capture(battle,0)
eq(captured:getWidth(),320,'HUD returns doubled source')
eq(party:getHeight(),296,'party source height doubled')
eq(scaleCalls[1][1],2,'HUD preserves logical coordinates at two source pixels')
eq(battle._kantoInMotionHudCapture,nil,'capture ownership restored')
eq(battle._kantoInMotionPartyBallCanvas,nil,'party capture target restored')
local previousNames={sentinel=true};battle._kimHudNames=previousNames
local queueSeen
ui.hudNames={enabled=function(_,layout)return layout~=nil end}
battle.drawHUDs=function(self)queueSeen=self._kimHudNames end
local _,_,queue=capture(battle,0,{scaleX=4,scaleY=4})
eq(queueSeen,queue,'cooperative name queue supplied during native capture')
eq(queue.presenter,ui.hudNames,'name presenter travels with captured queue')
eq(battle._kimHudNames,previousNames,'prior name queue restored')
battle._kimHudNames=nil

env.battleHudGeometry=function()return {enemyBandX=8,enemyBandY=16,playerBandX=72,playerBandY=48,hudScale=4}end
env.captureBattleHud=function()return captured,party end
env.getBattleHudShaders=function()end
local drawHud=between('  local function hudQuads()','  local function captureBattleText(')
local present=compile(drawHud..'return drawBattleHud',env)
draws={};eq(present(battle,{},0),true,'HUD composed')
eq(draws[1].args[1][3],320,'enemy quad uses doubled width')
eq(draws[2].args[1][2],104,'player quad uses doubled y')
for _,call in ipairs(draws)do
 eq(call.args[5],2,'source scale divided by capture resolution')
 eq(call.args[6],2,'source vertical scale divided by capture resolution')
end
print('PASS: '..checks..' actual KIM battle resolution checks')
