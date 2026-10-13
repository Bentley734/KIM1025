local f=assert(io.open('main.lua'));local source=f:read('*a');f:close()
local checks=0
local function eq(a,b,label)checks=checks+1;assert(a==b,label..': '..tostring(a)..' ~= '..tostring(b))end
local function near(a,b,label)checks=checks+1;assert(math.abs(a-b)<0.00001,label)end
eq(source:find('key = "battleEnemySize"',1,true),nil,'removed sizing control not exposed')
eq(source:find('mod.options:get("battleEnemySize")',1,true) ~= nil,true,'enemy size consumed')
local orientation,size='portrait',100
local sprites=true
local bgMode='auto'
local function image(w,h)return {getDimensions=function()return w,h end,setFilter=function()end}end
local pic=image(64,64)
local env=setmetatable({battleLiteFullScreenActive=function()return false end,battleBackgroundMode=function()return 'fullscreen'end,mod={exports={},options={get=function(_,key)if key=='battleSprites'then return sprites end;if key=='battleBgMode'then return bgMode end;return size end}},
 battleLiteDirectStageActive=function()return true end,battleLiteOwnsSprites=function()return sprites end,
 touchBattleOrientation=function()return orientation end,hdBattleBackgroundsEnabled=function()return true end,
 hdArenaImage=function()return pic,{file='grass_day'}end,
 hdArenaRouter=assert(loadfile('data/hd_battle_backgrounds.lua'))(),mobileScreenPositionLiftPx=function()return 0 end,
 HD_STAGE_LIFT_PX=172,HD_PLAYER_Y_COMPENSATE_PX=60,HD_ENEMY_EXTRA_LIFT_PX=8,hdEnemyNarrowShift=function()return 0 end,
 battleRecord=function()return nil end,battlerGrow=function()return 1 end,shinyGroundOffset=function()return 0 end,
 unpackCompat=table.unpack,transparentPic=function()return image(1,1)end,battleSystemEnabled=function()return true end}, {__index=_G})
local function compile(a,b,extra)
 local start=assert(source:find(a,1,true));local stop=assert(source:find(b,start,true))
 return assert(load(source:sub(start,stop-1)..(extra or ''),'actual KIM code','t',env))()
end
local transform,ground=compile('  local function hdArenaTransform(', '  -- Full-window 2D host', '\nreturn hdArenaTransform, hdArenaGroundGeometry')
env.hdArenaTransform=transform
local metrics=compile('  mod._kantoInMotionFlatNativeFrame = function','  -- Live integrated KRBA session.', '\nreturn directSideMetrics')
local battle={game={},player={mon={species=158},sprite=pic},enemy={mon={species=16},sprite=pic},picImage=function(_,img)return img end}
for _,width in ipairs({390,707,1170,2121})do
 for _,pct in ipairs({50,100,200})do
  size=pct
  local height=width*1.7
  local geo=ground(battle.game,battle,width,height,2);local t=transform(width,height,true)
  local m=assert(metrics(battle,'player',geo))
  near(m.centerX,t.x+604*t.scale,'player centered on platform')
  near(m.y+m.h*m.scale,t.y+672*t.scale,'feet anchored across size and DPI')
  eq(m.frame,pic,'provider art preserved');eq(m.nativeFallback,true,'fallback routed')
 end
end
local geo=ground(battle.game,battle,707,1200,2)
for _,flag in ipairs({'showPlayerBack','sendingOut','safari','demo'})do
 battle[flag]=true;eq(metrics(battle,'player',geo),nil,'native intro preserved '..flag);battle[flag]=nil
end
orientation='landscape'
local landscapeGeo=ground(battle.game,battle,1200,707,2)
local landscapePlayer=assert(metrics(battle,'player',landscapeGeo))
near(landscapePlayer.y+landscapePlayer.h*landscapePlayer.scale,landscapeGeo.hdTransform.y+672*landscapeGeo.hdScale,'landscape player feet on source anchor')
for _,orient in ipairs({'portrait','landscape'})do
 orientation=orient
 local g=ground(battle.game,battle,707,1200,2)
 size=100;local baseline=assert(metrics(battle,'enemy',g))
 for _,pct in ipairs({50,100,150,200})do
  size=pct;local m=assert(metrics(battle,'enemy',g))
  near(m.scale,baseline.scale*pct/100,orient..' enemy size applied')
  near(m.x+m.w*m.scale/2,g.enemyX,orient..' enemy centered')
  near(m.y+m.h*m.scale,g.enemyY,orient..' enemy grounded')
 end
end
size=100
orientation='portrait'
local captured
local nativeCalls=0
env.nativeDrawPicsLayer=function(self,...)
 nativeCalls=nativeCalls+1;self.player.sprite=pic;captured={...};return 'native'
end
env.BattleState={}
compile('        BattleState.drawPicsLayer = function(self, ...)', '\n      end\n\n      -- KIM captures the complete 48-row')
battle.showEnemyTrainer=true
eq(env.BattleState.drawPicsLayer(battle,0,0,0,nil,true),'native','native return retained')
eq(captured[4],nil,'native arguments preserved while scoped pictures are suppressed')
eq(captured[5],true,'clip flag retained')
battle.showEnemyTrainer=nil
local before=nativeCalls
env.BattleState.drawPicsLayer(battle,0,0,0,nil,true)
eq(nativeCalls,before+1,'both providers continue native loading and animation')
battle.sendingOut=true
env.BattleState.drawPicsLayer(battle,0,0,0,'player',true)
eq(captured[4],'player','send-out native route retained')
-- Actual framing policy and actual flat draw entry point with sprites OFF.
env.mod._kantoInMotionPortraitBattleFraming=function()return orientation~='desktop'end
local mode=compile('  local function battleBackgroundMode()', '  local function battleLiteDirectStageActive()', '\nreturn battleBackgroundMode')
for _,on in ipairs({true,false})do
 sprites=on
 for _,orient in ipairs({'portrait','landscape','desktop'})do
  orientation=orient
  for _,selected in ipairs({'auto','fullscreen','native'})do
   bgMode=selected
   local expected=selected
   if selected=='auto'then expected=(orient~='desktop' or on)and'fullscreen'or'native'end
   eq(mode(),expected,'AUTO and explicit framing respect sprites/orientation')
  end
 end
end
orientation='portrait';sprites=false;bgMode='fullscreen'
battle.sendingOut=nil;battle.showEnemyTrainer=true
captured=nil
env.BattleState.drawPicsLayer(battle,0,0,0,nil,true)
eq(captured[4],nil,'sprites OFF retains native/provider draw call')
local draws=0
env.directStageGeometry=function()return geo end
env.drawDirectSide=function(_,side,g)draws=draws+1;eq(g,geo,'shared geometry');return true end
local direct=compile('  drawDirectBattleSprites = function', '  setFlatBattleWorld = function', '\nreturn drawDirectBattleSprites')
eq(direct(battle,707,1200),true,'sprites OFF still draws aligned native provider')
eq(draws,2,'both sides rendered')
orientation='landscape'
eq(direct(battle,1200,707),true,'landscape sprites OFF aligned')
orientation='portrait';sprites=false
-- Exercise both settings from the report using the actual AUTO resolver.
env.battleLiteDirectStageActive=function()return mode()=='fullscreen'end
for _,selected in ipairs({'auto','fullscreen'})do
 bgMode=selected
 eq(direct(battle,707,1200),true,'sprites OFF aligned with '..selected)
end
bgMode='native'
eq(direct(battle,707,1200),false,'explicit native fit preserved')
eq(env.mod._kantoInMotionFlatNativeFrame(battle,'player'),nil,'native-fit source retained')
print('PASS: '..checks..' portrait alignment checks')
-- Exercise the actual final Gen 1 draw with both KIM art and native/Dex art.
env.directSideMetrics=metrics
env.directSideVisible=function()return true end
env.activeKrbaSession=function()return nil end
local lastDraw
env.love={graphics={setShader=function()end,push=function()end,pop=function()end,
 setColor=function()end,draw=function(...)lastDraw={...}end}}
local drawSide=compile('  local function drawDirectSide(', '  local function drawDirectBattleTrainer(', '\nreturn drawDirectSide')
env.renderPresentationFrame=function()return pic end
env.battleLiteDirectStageActive=function()return true end
battle.showEnemyTrainer=nil;battle.sendingOut=nil
for _,provider in ipairs({'native','kim'})do
 env.battleRecord=function()if provider=='kim'then return {displayScale=.4},'hd',16,false end end
 for _,orient in ipairs({'portrait','landscape'})do
  orientation=orient
  local g=ground(battle.game,battle,orient=='portrait' and 707 or 1536,orient=='portrait' and 1536 or 707,2)
  size=100;assert(drawSide(battle,'enemy',g));local baseline=lastDraw[5]
  for _,pct in ipairs({50,100,150,200})do
   size=pct;assert(drawSide(battle,'enemy',g))
   near(lastDraw[5],baseline*pct/100,provider..' '..orient..' actual draw scale')
   eq(math.abs(lastDraw[3]+64*lastDraw[6]-g.enemyY)<=.5,true,provider..' '..orient..' actual draw feet')
  end
 end
end
print('PASS: '..checks..' alignment and actual Gen 1 draw checks')
