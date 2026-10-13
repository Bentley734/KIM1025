local function read(p)local f=assert(io.open(p));local s=f:read('*a');f:close();return s end
local source=read('main.lua');local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function section(a,b)local i=assert(source:find(a,1,true));local j=assert(source:find(b,i+#a,true));return source:sub(i,j-1)end
for _,orientation in ipairs({'portrait','landscape','desktop'})do
 for _,native in ipairs({true,false})do for _,modal in ipairs({true,false})do
  local battle={phase='moveSelect',game={}};local game=battle.game
  local rects,texts,nextCalls=0,0,0;local wraps={};local G={}
  for _,k in ipairs({'push','pop','setCanvas','setBlendMode','setColor','clear'})do G[k]=function()end end
  G.rectangle=function(_,x,y,w,h)if y==96 and h==48 then rects=rects+1 end end
  local mod={hooks={wrap=function(_,name,fn)wraps[name]=fn end},exports={},options={get=function(_,k)if k=='battleSprites'then return false end end},_kantoInMotionNativeMobileHost=function()return orientation~='desktop'end,_kantoInMotionNativeMobileGen1=function()return orientation~='desktop'end}
  local env=setmetatable({mod=mod,love={graphics=G},require=function()return game end,
   unpackCompat=table.unpack,currentBattleState=function()return battle end,battleChildMenuOpen=function()return modal end,
   battleLiteFullScreenActive=function()return true end,battleBackgroundMode=function()return native and 'native' or 'fullscreen'end,
   touchBattleOrientation=function()return orientation~='desktop' and orientation or nil end,battleModernUiActive=function()return false end,
   battleSystemEnabled=function()return true end,externalBattleSceneOwnerRegistered=function()return false end,
   restoreBattleLayout=function()end,forceBattleLayoutOG=function()end,mobileBattleDialogRect=function()return {}end,
   battleWorldMetrics=function()end,drawNativeBattleOverlay=function()end,drawNativeBattleText=function()texts=texts+1 end,
   battleArt3DBattleEnabled=function()return false end,withTypedBattlePresentationSuppressed=function(_,f)return f()end,
   battleLiteHudActive=function()return false end},{__index=_G})
  local compose=section('    mod.hooks:wrap("render.compose", function(nextFn, renderer, ctx)','    -- Modern UI owns the lower command/message layer')
  local helpers=section('  local function menuBattleUi()','  local function battleOffsets(')
  assert(load(helpers..compose,'production compose','t',env))()
  wraps['render.compose'](function()end,{}, {uiCanvas={getDimensions=function()return 160,144 end}})
  if native and not modal then check(rects==1,'source move strip cleared '..orientation)end
  local hud=section('    mod.hooks:wrap("render.hud", function(nextFn, game, viewport)\n      local battle = currentBattleState(game)','  -- Colosseum Inspired UI')
  hud=hud:sub(1,assert(hud:find('    end, 20000)',1,true))+#'    end, 20000)'-1)
  assert(load(helpers..hud,'production final HUD','t',env))()
  wraps['render.hud'](function()nextCalls=nextCalls+1 end,game,{})
  check(texts==(modal and 0 or 1),'one final move panel '..orientation)
  check(nextCalls==1,'other HUD owners forwarded')
 end end
end
print('PASS: '..checks..' actual desktop / landscape / portrait move routing checks')
