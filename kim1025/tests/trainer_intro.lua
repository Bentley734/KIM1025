local f=assert(io.open(arg[1] or 'main.lua'));local source=f:read('*a');f:close()
local checks=0
local function eq(a,b,label)checks=checks+1;assert(a==b,label..': '..tostring(a)..' ~= '..tostring(b))end
local function near(a,b,label)checks=checks+1;assert(math.abs(a-b)<1e-6,label..': '..tostring(a)..' ~= '..tostring(b))end
local function image(w,h)return {getDimensions=function()return w,h end}end
local custom,native=image(80,80),image(48,48)
local sprites,selected,orientation,active,hd=true,true,'portrait',true,true
local dpi,offset=3,0
local draws,nativeCalls={},{}
local trainerPct=100
local mod={options={get=function()return trainerPct end},exports={_kantoInMotionBattleTrainerFrame=function()if selected then return custom end end}}
local env=setmetatable({battleLiteFullScreenActive=function()return false end,battleBackgroundMode=function()return 'fullscreen'end,mod=mod,BattleState={},unpackCompat=table.unpack,
 battleLiteDirectStageActive=function()return active end,battleLiteFullScreenActive=function()return active end,battleLiteOwnsSprites=function()return sprites end,
 hdBattleBackgroundsEnabled=function()return hd end,touchBattleOrientation=function()return orientation end,
 hdArenaImage=function()if hd then return native end end,
 nativeBattlePlacementPx=function()return {sx=dpi,sy=dpi}end,
 battleRecord=function()return nil end,battleSystemEnabled=function()return true end,
 transparentPic=function()return image(1,1)end,
 nativeDrawPicsLayer=function(self,...)nativeCalls[#nativeCalls+1]={...};return 'native' end,
 love={graphics={push=function()end,pop=function()end,setShader=function()end,setColor=function()end,
 draw=function(...)draws[#draws+1]={...}end}}},{__index=_G})
local function compile(first,last,extra)
 local a=assert(source:find(first,1,true));local b=assert(source:find(last,a+1,true))
 return assert(load(source:sub(a,b-1)..(extra or ''),'production trainer intro','t',env))()
end
mod._kantoInMotionFlatTrainerFrame=function()return selected and custom or native end
local draw=compile('  local function drawDirectBattleTrainer(', '  drawDirectBattleSprites = function', '\nreturn drawDirectBattleTrainer')
local battle={game={},showPlayerBack=true,playerBackPic=native,
 picImage=function(_,pic)return pic end,picOffset=function()return offset end}
for _,width in ipairs({390,707,1320,2121})do
 local geo={hd=true,hdScale=width/1920,playerX=604*width/1920,playerY=672*width/1920}
 for _,retina in ipairs({1,2,3})do
  dpi=retina;offset=0;draws={}
  eq(draw(battle,geo,battle.game,width,width*2.17),true,'trainer drawn')
  local d=draws[1];near(d[5],10*geo.hdScale,'trainer follows HD arena scale across DPI')
  near(d[2]+80*d[5]/2,geo.playerX,'trainer centered on player platform')
  near(d[3]+80*d[6],geo.playerY+220*geo.hdScale,'trainer grounded on player platform')
  offset=-24;draws={};draw(battle,geo,battle.game,width,width*2.17)
  near(draws[1][2]-d[2],offset*dpi,'native intro slide timing retained')
 end
end
for _,mode in ipairs({'desktop','landscape'})do
 orientation=mode;if mode=='desktop' then orientation=nil end
 dpi=3;offset=0;draws={}
 local geo={hd=true,hdScale=1.5,playerX=900,playerY=700}
 draw(battle,geo,battle.game,2880,1400)
 near(draws[1][5],mode=='desktop' and 8*math.min(2880/1920,1400/1080)*trainerPct/100 or 12,'desktop height cap and landscape arena scale')
 near(draws[1][3]+80*draws[1][6],mode=='desktop' and (1400-48*(1400/144)) or 784,'orientation baseline')
end
orientation=nil;draws={}
battle.game.renderer={frameRects=function()return {uoy=50,Uy=4,dpiY=2,vuy=10}end}
draw(battle,{hd=true,hdScale=2,playerX=900,playerY=1200},battle.game,2880,1400)
near(draws[1][3]+80*draws[1][6],848,'desktop trainer bottom equals actual dialogue top in physical pixels')
battle.game.renderer=nil
-- Final-window Emerald dialogue starts at the continuous KIM lower-strip Y,
-- independently of the old renderer's native UI zoom/letterbox rectangle.
mod.find=function()return {exports={battleUi={canDrawBottom=function()return true end}}}end
local padded={x0=20,y0=32,x1=56,y1=76,ox=38,ground=76}
mod._kimAutoPlayerSize={measure=function()return padded end}
for _,size in ipairs({{1047,699},{1920,1080},{5120,1440},{960,720},{3840,2160}})do
 local width,height=size[1],size[2]
 local uiScale=math.min(width/160,height/144)
 local base=math.ceil(math.floor(height-48*uiScale+.5)+uiScale)+1
 for _,pct in ipairs({50,100,130,200})do
  trainerPct=pct;offset=0;draws={}
  battle.game.renderer={frameRects=function()return {uoy=-999,Uy=8,dpiY=3}end}
  local geo={hd=true,hdScale=3,playerX=width*.4,playerY=height*.8}
  draw(battle,geo,battle.game,width,height)
  local d=draws[1]
  near(d[3]+padded.ground*d[6],base,'opaque trainer bottom overlaps current frame without a gap')
  near(d[5],d[6],'trainer pixels keep uniform scale')
  near(d[2]+40*d[5],geo.playerX,'horizontal mound anchor unchanged')
  eq(d[3]+padded.y0*d[6]>=2,true,'trainer top remains inside window')
  local requested=8*math.min(width/1920,height/1080)*pct/100
  near(d[5],math.min(requested,(base-2)/(padded.ground-padded.y0)),'selected size respects height and visible-top caps')
 end
end
trainerPct=100;mod.find=nil;mod._kimAutoPlayerSize=nil;battle.game.renderer=nil
orientation='portrait' 
compile('  mod._kantoInMotionFlatTrainerFrame = function', '  local function drawDirectBattleTrainer(')
local resolve=assert(mod._kantoInMotionFlatTrainerFrame)
env.battleLiteDirectStageActive=function()return false end
eq(resolve(battle),custom,'Native Fit resolves relocated trainer')
env.battleLiteDirectStageActive=function()return active end
eq(resolve(battle),custom,'selected trainer resolved')
selected=false;eq(resolve(battle),native,'ROM/default trainer resolved')
selected=true;sprites=false;eq(resolve(battle),custom,'trainer selection independent of Pokemon sprites')
for _,flag in ipairs({'safari','demo','fieldCleared'})do
 battle[flag]=true;eq(resolve(battle),nil,'native special phase retained '..flag);battle[flag]=nil
end
battle.showPlayerBack=false;eq(resolve(battle),nil,'trainer hidden after send-out');battle.showPlayerBack=true
orientation=nil;eq(resolve(battle),custom,'desktop trainer uses arena path');orientation='portrait'
active=false;eq(resolve(battle),nil,'external/native stage retains ownership');active=true
hd=false;eq(resolve(battle),nil,'no HD background keeps native trainer');hd=true
mod._kantoInMotionFlatNativeFrame=function() return nil end
mod._kantoInMotionFlatTrainerFrame=function() return selected and custom or nil end
compile('        BattleState.drawPicsLayer = function(self, ...)', '\n      end\n\n      -- KIM captures the complete 48-row')
local upstreamImage=battle.picImage
local clock=0
local sourcePictures={}
env.nativeDrawPicsLayer=function(self,...)
 clock=clock+1
 sourcePictures={self:picImage(self.playerBackPic),self:picImage(self.enemy.sprite)}
 return 'native'
end
local enemyPic=image(56,56)
battle.enemy={sprite=enemyPic};battle.player={sprite=native}
selected=true;sprites=false
for i=1,8 do
 eq(env.BattleState.drawPicsLayer(battle,0,0,0,nil,true),'native','native/provider layer always called')
 eq(clock,i,'provider clock continues')
 eq(sourcePictures[1]:getDimensions(),1,'relocated trainer source hidden')
 eq(sourcePictures[2],enemyPic,'enemy source preserved')
 eq(battle.picImage,upstreamImage,'native resolver restored')
 eq(battle.playerBackPic,native,'trainer source restored')
end
mod._kantoInMotionFlatNativeFrame=function()return custom,true end
battle.showPlayerBack=false
for i=1,8 do
 env.BattleState.drawPicsLayer(battle)
 eq(clock,8+i,'both relocated providers still advance')
end
env.nativeDrawPicsLayer=function()error('injected native failure')end
eq(pcall(env.BattleState.drawPicsLayer,battle),false,'native error propagates')
eq(battle.picImage,upstreamImage,'resolver restored after native error')
eq(battle.playerBackPic,native,'trainer restored after native error')
print('PASS: '..checks..' trainer geometry and native provider clock assertions')
