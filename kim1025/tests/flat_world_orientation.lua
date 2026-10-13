-- Run from latest engine: luajit ../kim-source/tests/flat_world_orientation.lua ../kim-source
package.path='./?.lua;./?/init.lua;'..package.path
local kim=arg[1] or '../kim-source'
love=require('tests.love_stub')
local host,major='iOS',12
love.system={getOS=function()return host end};love.getVersion=function()return major end
local Renderer=require('src.render.Renderer')
Renderer:init()
local canvas=love.graphics.newCanvas(800,1200)
local unrelated=love.graphics.newCanvas(800,1200)
local calls={}
local draw=love.graphics.draw
love.graphics.draw=function(image,...)calls[#calls+1]={image=image,args={...}};return draw(image,...)end
local checks=0
local function eq(a,b,label)checks=checks+1;assert(a==b,label..': '..tostring(a)..' ~= '..tostring(b))end
local function render(c)
 calls={};Renderer:setWorldOverride(c);local result=Renderer:endFrame()
 local world,ui
 for _,call in ipairs(calls)do
  if call.image==c then world=call end
  if call.image==Renderer.canvas then ui=call end
 end
 assert(world and ui,'world and UI both composed')
 eq(ui.args[5]>0,true,'UI upright');eq(Renderer.worldOverride,nil,'override cleared')
 return world,result
end
local before=render(canvas);eq(before.args[5]<0,true,'reproduce flat scene inversion')
local mark=assert(loadfile(kim..'/lib/flat_world_orientation.lua'))()()
mark(Renderer,canvas)
for _,case in ipairs({{'iOS',12},{'iOS',11},{'Android',12},{'Windows',12},{'OS X',12}})do
 host,major=case[1],case[2]
 for frame=1,3 do
  local world,viewport=render(canvas)
  eq(world.args[5]>0,true,host..' KIM upright');eq(type(viewport),'table','viewport retained')
 end
 local other=render(unrelated)
 eq(other.args[5]<0,host=='iOS' and major>=12,'other provider preserved')
 eq(Renderer.mirrorsWorldOverride(),host=='iOS' and major>=12,'outside-frame policy')
end
host,major='iOS',12
local frameRects=Renderer.frameRects
Renderer.frameRects=function()error('injected frame failure')end
Renderer:setWorldOverride(canvas)
eq(pcall(Renderer.endFrame,Renderer),false,'error propagated')
eq(Renderer.mirrorsWorldOverride(),true,'scope unwound after error')
Renderer.frameRects=frameRects
eq(assert(loadfile(kim..'/lib/flat_world_orientation.lua'))()(),mark,'reload idempotent')
local world=render(canvas);eq(world.args[5]>0,true,'frame recovered')
local f=assert(io.open(kim..'/main.lua'));local s=f:read('*a');f:close()
assert(s:find('mod._kantoInMotionFlatWorldOrientation(game.renderer, flatBattleWorldCanvas)\n    game.renderer:setWorldOverride(flatBattleWorldCanvas)',1,true))
-- Execute the actual flat producer with assets and gameplay isolated.
local start=assert(s:find('  setFlatBattleWorld = function(game, battle)',1,true))
local stop=assert(s:find('  -- Shared with the integrated KRBA bridge.',start,true))
local image=love.graphics.newCanvas(1920,950)
local function readLua(path)
 local f=assert(io.open(path));local text=f:read('*a');f:close()
 return assert(load(text,'@'..path,'t'))()
end
local env=setmetatable({mod={_kantoInMotionFlatWorldOrientation=mark},love=love,
 hdArenaRouter={_aspectBackgrounds=readLua(kim..'/data/aspect_battle_backgrounds.lua')},
 aspectArenaImage=function()return image end,
 battleSystemEnabled=function()return true end,
 hdBattleBackgroundsEnabled=function()return true end,
 externalBattleSceneOwnerRegistered=function()return false end,
 forceBattleLayoutOG=function()end,battleLiteFullScreenActive=function()return true end,
 hdArenaImage=function()return image,{}end,
 battleWorldMetrics=function()return {width=800,height=1200}end,
 ensureBattleCanvas=function(c,w,h)return c or love.graphics.newCanvas(w,h)end,
 touchBattleOrientation=function()return 'portrait'end,
 battleBackgroundMode=function()return 'hd'end,
 hdArenaTransform=function()return {x=0,y=400,scale=800/1920}end,
 mobileScreenPositionLiftPx=function()return 0 end,
 activeKrbaSession=function()return nil end,
 battleLiteDirectStageActive=function()return false end}, {__index=_G})
local chunk
if setfenv then
 chunk=assert(loadstring(s:sub(start,stop-1),'production flat producer'))
 setfenv(chunk,env)
else
 chunk=assert(load(s:sub(start,stop-1),'production flat producer','t',env))
end
chunk()
for frame=1,3 do
 eq(env.setFlatBattleWorld({renderer=Renderer},nil),true,'producer active')
 eq(Renderer._kimUprightWorldCanvas,Renderer.worldOverride,'actual producer marked')
 local world=render(Renderer.worldOverride)
 eq(world.args[5]>0,true,'produced arena upright')
end
print('PASS: '..checks..' flat-world checks using actual Renderer:endFrame')
for _,orientation in ipairs({'portrait','landscape'})do
 env.touchBattleOrientation=function()return orientation end
 calls={}
 assert(env.setFlatBattleWorld({renderer=Renderer},nil))
 local n=0;for _,call in ipairs(calls)do if call.image==image then n=n+1 end end
 eq(n,1,orientation..' complete arena drawn once')
end
for _,platform in ipairs({'Windows','Linux','OS X','Android','iOS'})do
 host=platform
 for _,orientation in ipairs({'desktop','portrait','landscape'})do
  env.touchBattleOrientation=function()return orientation~='desktop' and orientation or nil end
  calls={}
  assert(env.setFlatBattleWorld({renderer=Renderer},nil))
  local n=0;for _,call in ipairs(calls)do if call.image==image then n=n+1 end end
  eq(n,1,platform..' '..orientation..' complete arena drawn once')
 end
end
-- A native menu may leave a clip active before the complete arena pass.
local setScissor=love.graphics.setScissor
local clipCleared=false
love.graphics.setScissor=function(...)
 if select('#',...)==0 then clipCleared=true end
 return setScissor(...)
end
env.battleWorldMetrics=function()return {width=5120,height=1440}end
env.touchBattleOrientation=function()return nil end
love.graphics.setScissor(400,0,1000,1440)
calls={};assert(env.setFlatBattleWorld({renderer=Renderer},nil))
eq(clipCleared,true,'ultrawide complete arena clears inherited native-menu clip')
local n=0;for _,call in ipairs(calls)do if call.image==image then n=n+1 end end
eq(n,1,'5120x1440 complete arena drawn once')
love.graphics.setScissor=setScissor

-- Native Fit must draw the trainer on the actual background platform even
-- though direct battler ownership is disabled by the focused feature scope.
local trainerCalls=0
env.battleHudGeometry=function()return {hudScale=1,battleScale=1,lx=0,ly=0,playerBandY=0}end
env.qolXpCompat={}
local previousMode=env.battleBackgroundMode
env.battleBackgroundMode=function()return 'native'end
env.nativeFitHdTransform=function()return {x=0,y=400,sx=1,sy=1}end
local previousGuard=env.mod._kantoInMotionGuardedMobileCall
env.mod._kantoInMotionGuardedMobileCall=function(label,fn,battle,geo,playerGeo)
 if label=='native-fit enemy mound draw' then
  eq(geo,'enemy','enemy relocated')
  eq(playerGeo.enemyX,1200,'enemy X uses painted mound transform')
  eq(playerGeo.enemyY,700,'enemy feet use painted mound transform')
  return
 end
 if label=='native-fit player mound draw' then
  eq(geo,'player','only player relocated')
  eq(playerGeo.playerX,604,'player X uses painted mound transform')
  eq(playerGeo.playerY,1100,'player feet use painted mound transform')
  eq(playerGeo.playerPixelScale,7,'player uses scene size instead of UI zoom')
  return
 end
 trainerCalls=trainerCalls+1
 eq(geo.playerX,604,'native-fit trainer X uses backdrop transform')
 eq(geo.playerY,1100,'native-fit trainer Y uses backdrop transform')
end
env.hdArenaRouter.groundAnchors=function()return {player={x=604,y=700},enemy={x=1200,y=300}}end
calls={};assert(env.setFlatBattleWorld({renderer=Renderer},{showPlayerBack=true}))
eq(trainerCalls,1,'native-fit trainer is painted exactly once')
local playerCalls=0
local replayBattle={drawPicsLayer=function(self,slide,sx,sy,side,skip)
 eq(self._kimReplayPlayerBehindMenu,true,'replay bypasses source suppression')
 eq(side,'player','only player replayed');eq(skip,true,'native menu clip bypassed')
 playerCalls=playerCalls+1
end}
local replayRenderer={frameRects=function()return {uox=10,uoy=20,vux=0,vuy=0,dpiX=2,dpiY=2,Up=4}end,
 setWorldOverride=function()end}
assert(env.setFlatBattleWorld({renderer=replayRenderer},replayBattle))
eq(playerCalls,0,'desktop player never replayed at enlarged native UI scale')
eq(replayBattle._kimReplayPlayerBehindMenu,nil,'replay flag restored')
env.mod._kantoInMotionGuardedMobileCall=previousGuard
env.battleBackgroundMode=previousMode

env.aspectArenaImage=function()return nil end
calls={};assert(env.setFlatBattleWorld({renderer=Renderer},nil))
local n=0;for _,call in ipairs(calls)do if call.image==image then n=n+1 end end
eq(n,1,'missing complete art falls back to one canonical draw')
print('PASS: '..checks..' flat-world and all-platform single-arena checks')
