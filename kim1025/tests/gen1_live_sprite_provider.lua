-- Run with an optional 1025Dex root to exercise its installed scene hook.
local function read(path)local f=assert(io.open(path));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local engine=arg[2] or '../work/engine/gen1recomp-0.3.71'
package.path=engine..'/?.lua;'..package.path
local Runtime=require('src.mods.Runtime')
local Hooks=require('src.mods.Hooks')
local hooks=Hooks.new();Runtime.install({},hooks,{})
local n=0
local function eq(a,b,m)n=n+1;assert(a==b,m..': '..tostring(a)..' ~= '..tostring(b))end
local function image(side,frame)return {side=side,frame=frame,getDimensions=function()return 56,56 end,setFilter=function()end}end
local front,back={},{}
for i=1,4 do front[i]=image('front',i);back[i]=image('back',i) end
back.__spriteLayout={x0=0,y0=0,x1=56,y1=48,ox=28,ground=56}
local tick,mode=0,'pending'
local function framesFor(isBack)
 if mode=='pending' then return nil,true end
 if mode=='missing' then return nil,false end
 return isBack and back or front,false
end
local function index(count)return math.floor(tick*20)%count+1 end
if arg[1] then
 local dex=read(arg[1]..'/sprites/main.lua')
 local a=assert(dex:find('  mod.hooks:wrap("battle.mon_pic"',1,true))
 local b=assert(dex:find('  -- A load-time census',a,true))
 local data={styleFor=function()return 3 end,playerView=function()return false,false end}
 local clockEnv=setmetatable({DATA=data,opt=function(_,default)return default end,
  now=function()return tick end,fpsValue=function()return 20 end,animateOn=function()return true end},{__index=_G})
 local ca=assert(dex:find('  function DATA.eeFrame(',1,true))
 local cb=assert(dex:find('  local function wantShiny()',ca,true))
 assert(load(dex:sub(ca,cb-1),'installed EE timing','t',clockEnv))()
 local ia=assert(dex:find('  local function frameIndex(count, frames)',1,true))
 local ib=assert(dex:find('  -- ---------------------------------------------------------------------------',ia,true))
 index=assert(load(dex:sub(ia,ib-1)..'\nreturn frameIndex','installed frame clock','t',clockEnv))()
 local env=setmetatable({battleLiteFullScreenActive=function()return false end,battleBackgroundMode=function()return 'fullscreen'end,mod={hooks=hooks,log={info=function()end}},
  wantEnabled=function()return true end,diag={stats={scene=0}},managedSpecies={},
  DATA=data,
  monStem=function(mon)return mon.species,false end,teraTypeOf=function()end,dynamaxOf=function()end,
  battleFormDeclared=function()end,declaredGimmickOf=function()end,getBattleFrames=framesFor,frameIndex=index,
  debugOn=function()return false end},{__index=_G})
 assert(load(dex:sub(a,b-1),'installed 1025Dex live scene hook','t',env))()
else
 hooks:wrap('battle.mon_pic',function(next,img,ctx)
  local frames,pending=framesFor(ctx.side=='back')
  if frames then return frames[index(#frames)] end
  if pending then return false end
  return next(img,ctx)
 end)
end
local vanilla=image('vanilla',0)
local battle={game={},player={mon={species='BULBASAUR'},sprite=vanilla},
 enemy={mon={species='RATTATA'},sprite=vanilla},picImage=function(_,img)return img end}
local mod={path='.',exports={},options={get=function()return 100 end}}
mod._kimBattlePicProvider=assert(loadfile('lib/gen1_battle_pic_provider.lua'))()(mod,function()return false end)
local main=read(arg[3] or 'main.lua')
local env=setmetatable({battleLiteFullScreenActive=function()return false end,battleBackgroundMode=function()return 'fullscreen'end,mod=mod,battleLiteDirectStageActive=function()return true end,
 hdBattleBackgroundsEnabled=function()return true end,touchBattleOrientation=function()return 'portrait' end,
 hdArenaImage=function()return vanilla end,battleRecord=function()return {image='unavailable-kim.png'},'hd','TEST',false end,
 renderPresentationFrame=function()error('KIM artwork must not replace a claimed Dex sprite')end,
 battlerGrow=function()return 1 end,shinyGroundOffset=function()return 0 end},{__index=_G})
local a=assert(main:find('  mod._kantoInMotionFlatNativeFrame = function',1,true))
local b=assert(main:find('  -- Native battle animation timing and effects remain engine-owned.',a,true))
local metrics=assert(load(main:sub(a,b-1)..'\nreturn directSideMetrics','production sprite scene','t',env))()
local geo={hd=true,pixelScale=2,playerPixelScale=2,enemyX=120,enemyY=65,playerX=26,playerY=110}
for _,side in ipairs({'player','enemy'})do
 eq(metrics(battle,side,geo),nil,'pending sheet never flashes vanilla '..side)
 local img,managed=mod._kantoInMotionFlatNativeFrame(battle,side)
 eq(img,nil,'pending has no image');eq(managed,true,'pending claims source suppression')
end
mode='ready'
-- Native drawPicsLayer never runs; battler.sprite stays the initial vanilla
-- object. The scene must continue pulling fresh front AND back provider frames.
for cycle=0,7 do for phase=0,3 do
 tick=cycle*.2+phase*.05+.001
 for _,side in ipairs({'player','enemy'})do
  local m=assert(metrics(battle,side,geo))
  eq(m.frame,side=='player' and back[phase+1] or front[phase+1],'provider loops independently of native layer')
  eq(battle[side].sprite,vanilla,'native battler image need not mutate')
  eq(m.nativeFallback,true,'provider art uses native-size ground placement')
 end
end end
-- Run the source-suppression wrapper: provider clocks must keep advancing
-- even while the native sprite layer is skipped for both battlers.
local nativeCalls=0
env.BattleState={}
env.nativeDrawPicsLayer=function()nativeCalls=nativeCalls+1 end
env.battleLiteOwnsSprites=function()return true end
env.battleSystemEnabled=function()return true end
env.unpackCompat=table.unpack
env.transparentPic=function()return image('blank',0)end
local pa=assert(main:find('        BattleState.drawPicsLayer = function(self, ...)',1,true))
local pb=assert(main:find('\n      end\n\n      -- KIM captures the complete 48-row',pa,true))
assert(load(main:sub(pa,pb-1),'production source wrapper','t',env))()
for phase=0,3 do
 tick=phase*.05+.001
 env.BattleState.drawPicsLayer(battle)
 eq(nativeCalls,phase+1,'provider native clock is never skipped')
 eq(assert(metrics(battle,'player',geo)).frame,back[phase+1],'player live with native layer skipped')
 eq(assert(metrics(battle,'enemy',geo)).frame,front[phase+1],'enemy live with native layer skipped')
end
if arg[1] then
 front.__ee=true;back.__ee=true
 front.__eeStarted=nil;back.__eeStarted=nil
 tick=.001;metrics(battle,'player',geo);metrics(battle,'enemy',geo)
 for _,point in ipairs({{.056,2},{.456,1},{2.456,2},{3.056,1},{4.056,2},{8.056,2}})do
  tick=point[1]
  eq(assert(metrics(battle,'player',geo)).frame,back[point[2]],'EE back resumes after intended pause')
  eq(assert(metrics(battle,'enemy',geo)).frame,front[point[2]],'EE front resumes after intended pause')
 end
 front.__ee=nil;back.__ee=nil
end
-- The scoped source resolver is restored after every native call.
eq(battle:picImage(vanilla),vanilla,'native image resolver unchanged')
mode='missing'
local img,managed=mod._kimBattlePicProvider.resolve(battle,'enemy')
eq(img,nil,'missing species falls through');eq(managed,false,'missing species remains unclaimed')
-- Exercise the previously missed desktop Native Fit branch and the actual
-- scene/provider handoff, rather than only fullscreen/mobile rendering.
local observed
hooks:wrap('battle.mon_pic',function(next,img,ctx)observed=ctx;return next(img,ctx)end,10000)
mode='ready'
env.touchBattleOrientation=function()return nil end
env.battleLiteDirectStageActive=function()return false end
env.battleLiteFullScreenActive=function()return true end
env.battleBackgroundMode=function()return 'native' end
local nativePlayer,claimed,layout=mod._kantoInMotionFlatNativeFrame(battle,'player')
if arg[1] then eq(layout,back.__spriteLayout,'natural animation union metadata reaches final scene')end
eq(claimed,true,'Native Fit player claims live provider')
eq(nativePlayer~=nil,true,'Native Fit player has drawable image')
eq(observed.natural,true,'player requests feet-at-bottom natural frame')
eq(observed.scale,1,'provider does not bake scene/UI magnification')
eq(observed.maxH,56,'large back sprite bounded before scene draw')
local enemyFrame,enemyClaimed=mod._kantoInMotionFlatNativeFrame(battle,'enemy')
eq(enemyFrame~=nil,true,'Native Fit enemy has drawable live frame')
eq(enemyClaimed,true,'Native Fit enemy provider claimed')
eq(observed.natural,true,'enemy feet-at-bottom frame')
eq(observed.scale,1,'enemy excludes native UI magnification')
eq(observed.maxH,56,'enemy bounded before scene sizing')
print('PASS: '..n..' live provider checks'..(arg[1] and ' against installed 1025Dex hook' or ''))
