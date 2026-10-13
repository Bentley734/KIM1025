local api=assert(loadfile('lib/auto_player_size.lua'))()
local function read(p)local f=assert(io.open(p));local s=f:read('*a');f:close();return s end
local source=read('main.lua')
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function near(a,b,m)check(math.abs(a-b)<1e-6,m)end
-- Padding and every animation cell contribute to a single immutable union.
local reads=0
local atlas={newImageData=function()reads=reads+1;return {getPixel=function(_,x,y)
  return 1,1,1,((x>=3 and x<=10 and y>=2 and y<=12) or
    (x>=18 and x<=30 and y>=1 and y<=13)) and 1 or 0
end}end}
local bounds=assert(api.measure(atlas,16,16,2,2))
near(bounds.x0,2,'second frame left edge');near(bounds.x1,15,'second frame right edge')
near(bounds.y0,1,'animation top');near(bounds.ground,14,'feet instead of transparent bottom')
check(api.measure(atlas,16,16,2,2)==bounds and reads==1,'one scan per atlas')
local function intersect(a,b)return a.x<b.x+b.w and a.x+a.w>b.x and a.y<b.y+b.h and a.y+a.h>b.y end
local option='auto'
local pic={getDimensions=function()return 64,64 end,setFilter=function()end}
local env=setmetatable({mod={options={get=function(_,k)return k=='desktopPlayerSizeV2' and option or 100 end},
  _kimAutoPlayerSize=api,_kantoInMotionFlatNativeFrame=function()return pic,true,bounds end},
  touchBattleOrientation=function()end,battleRecord=function()end,battlerGrow=function(b)return b.grow or 1 end,
  shinyGroundOffset=function()return 0 end},{__index=_G})
env.mod.options.get=function(_,k)return k=='desktopPlayerSizeV2' and option or 100 end
local function compile(a,b,name)
 local i=assert(source:find(a,1,true));local j=assert(source:find(b,i+1,true))
 return assert(load(source:sub(i,j-1)..'\nreturn '..name,name,'t',env))()
end
env.mobilePortraitStageRectPx=function()end
env.battleHudGeometry=compile('  local function battleHudGeometry(',
 '  -- Native-resolution fullscreen battlers.','battleHudGeometry')
local metrics=compile('  local function directSideMetrics(',
 '  -- Live integrated KRBA session.','directSideMetrics')
local battle={game={},player={mon={species=34}},enemy={mon={species=402}}}
for _,size in ipairs({{1047,729},{1280,720},{1920,1080},{2560,1440},{5120,1440},{3840,2160}})do
 local vw,vh=table.unpack(size)
 local geo={hd=true,viewportWidth=vw,viewportHeight=vh,playerPixelScale=4,pixelScale=4,
   playerX=vw*.32,playerY=vh*.67,enemyX=vw*.72,enemyY=vh*.4}
 local hud=env.battleHudGeometry(vw,vh);local hs=hud.hudScale
 local obstacles={{x=hud.enemyBandX+8*hs,y=hud.enemyBandY,w=112*hs,h=32*hs},
   {x=hud.playerBandX+72*hs,y=hud.playerBandY+8*hs,w=88*hs,h=40*hs}}
 for _,shape in ipairs({{16,16,0},{12,64,0},{100,16,0},{64,64,8},{300,400,0}})do
  local w,h,hover=table.unpack(shape)
  bounds={x0=0,y0=0,x1=w,y1=h,ox=w/2,ground=h+hover}
  local m=assert(metrics(battle,'player',geo))
  local r={x=m.x+bounds.x0*m.scale,y=m.y+bounds.y0*m.scale,
    w=(bounds.x1-bounds.x0)*m.scale,h=(bounds.y1-bounds.y0)*m.scale}
  check(m.scale>0,'visible Auto fit')
  near(m.x+bounds.ox*m.scale,geo.playerX,'horizontal mound anchor retained')
  near(m.y+bounds.ground*m.scale,geo.playerY,'feet/hover ground anchor retained')
  check(r.x>=0 and r.x+r.w<=vw and r.y>=0 and r.y+r.h<=vh,'screen edges clear')
  for _,hudRect in ipairs(obstacles)do check(not intersect(r,hudRect),'status/name panels clear')end
  check(r.y>=obstacles[1].y+obstacles[1].h+2-1e-6,'always below enemy name/HP band')
  -- Clearance alone let the original 36%/38% caps pass. Prove maximality:
  -- even 0.1% more would cross the name/HP band, a screen edge or player HUD.
  local bigger=m.scale*1.001
  local larger={x=geo.playerX+(bounds.x0-bounds.ox)*bigger,
    y=geo.playerY+(bounds.y0-bounds.ground)*bigger,
    w=(bounds.x1-bounds.x0)*bigger,h=(bounds.y1-bounds.y0)*bigger}
  local blocked=larger.y<obstacles[1].y+obstacles[1].h+2
    or larger.x<2 or larger.x+larger.w>vw-2
    or larger.y<2 or larger.y+larger.h>vh-2
  for _,rect in ipairs(obstacles)do
    blocked=blocked or intersect(larger,{x=rect.x-2,y=rect.y-2,w=rect.w+4,h=rect.h+4})
  end
  check(blocked,'Auto consumes all available space, rather than a window percentage')
  battle.grow=.5;local growing=assert(metrics(battle,'player',geo));battle.grow=nil
  near(growing.scale,m.scale*.5,'send-out growth retained')
  near(growing.y+bounds.ground*growing.scale,geo.playerY,'send-out grounded')
  near(assert(metrics(battle,'enemy',geo)).scale,5,'enemy size unchanged')
 end
 option='130';local manual=assert(metrics(battle,'player',geo));option='auto'
 near(manual.scale,4*1.3*1.3,'manual percentage unchanged')
 near(manual.y+64*manual.scale,geo.playerY,'manual placement unchanged')
end
-- A deliberately offset 64px picture box must fit exactly like its tight art,
-- including when a ROM/provider has no KIM atlas record or layout metadata.
local padded={getDimensions=function()return 64,64 end,setFilter=function()end,
 newImageData=function()return {getPixel=function(_,x,y)
  return 1,1,1,(x>=10 and x<30 and y>=16 and y<46)and 1 or 0 end}end}
env.mod._kantoInMotionFlatNativeFrame=function()return padded,true end
local geo={hd=true,viewportWidth=1920,viewportHeight=1080,pixelScale=4,
 playerX=600,playerY=700,enemyX=1400,enemyY=400}
local paddedMetrics=assert(metrics(battle,'player',geo))
local tight={x0=0,y0=0,x1=20,y1=30,ox=10,ground=30}
env.mod._kantoInMotionFlatNativeFrame=function()return pic,true,tight end
local tightMetrics=assert(metrics(battle,'player',geo))
near(paddedMetrics.scale,tightMetrics.scale,'invisible padding never changes Auto size')
near(paddedMetrics.y+46*paddedMetrics.scale,geo.playerY,'actual opaque feet land on mound')
near(paddedMetrics.x+20*paddedMetrics.scale,geo.playerX,'visible union centred on mound')
env.mod._kantoInMotionFlatNativeFrame=function()return padded,false end
env.battleRecord=function()end
near(assert(metrics(battle,'player',geo)).scale,tightMetrics.scale,'unmanaged ROM fallback measured without atlas')
check(source:find('{ "AUTO", "auto" }',1,true),'AUTO selectable in existing menu')
check(source:find('viewportWidth=vw,viewportHeight=vh',1,true),'Native Fit receives final viewport')
print('PASS: '..checks..' Auto animation-union / HUD clearance / mound / manual regression checks')
