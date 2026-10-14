local f=assert(io.open('main.lua'));local source=f:read('*a');f:close()
local checks=0
local function near(a,b,label)checks=checks+1;assert(math.abs(a-b)<1e-6,label)end
local orientation,pct=nil,150
local desktopPct=100
local enemyPct=100
local pic={getDimensions=function()return 96,96 end,setFilter=function()end}
local env=setmetatable({mod={options={get=function(_,key)return key=='battlePlayerSize' and pct or key=='desktopPlayerSizeV2' and desktopPct or key=='desktopEnemySize' and enemyPct or 100 end},
 _kantoInMotionFlatNativeFrame=function()return pic,true end},
 touchBattleOrientation=function()return orientation end,battleRecord=function()end,
 battlerGrow=function()return 1 end,shinyGroundOffset=function()return 0 end},{__index=_G})
local a=assert(source:find('  local function directSideMetrics(',1,true))
local b=assert(source:find('  -- Native battle animation timing and effects remain engine-owned.',a,true))
local metrics=assert(load(source:sub(a,b-1)..'\nreturn directSideMetrics','production desktop provider scale','t',env))()
local battle={game={},player={mon={species=34}},enemy={mon={species=402}}}
for _,rung in ipairs({2,4,6,10})do
 local geo={hd=true,pixelScale=rung,playerPixelScale=rung,playerX=600,playerY=700,enemyX=1200,enemyY=300}
 for _,size in ipairs({50,100,130,200})do desktopPct=size
 for _,saved in ipairs({50,100,125,150,200})do
  pct=saved;orientation=nil
  local m=assert(metrics(battle,'player',geo))
  near(m.scale,rung*1.3*desktopPct/100,'desktop player size applies')
  near(m.x+m.w*m.scale/2,geo.playerX,'player centered')
  near(m.y+m.h*m.scale,geo.playerY,'player grounded')
  near(assert(metrics(battle,'enemy',geo)).scale,rung*1.25,'enemy calibration retained')
  for _,mobile in ipairs({'portrait','landscape'})do
   orientation=mobile
   near(assert(metrics(battle,'player',geo)).scale,rung*1.15*saved/100,'mobile calibration retained')
  end
 end
end
end
orientation=nil
local geo={hd=true,pixelScale=4,playerPixelScale=4,playerX=600,playerY=700,enemyX=1200,enemyY=300}
for _,v in ipairs({50,100,130,200})do
 enemyPct=v
 local m=assert(metrics(battle,'enemy',geo))
 near(m.scale,4*1.25*v/100,'enemy size control applies')
 near(m.x+m.w*m.scale/2,1200,'enemy remains centered')
 near(m.y+m.h*m.scale,300,'enemy remains grounded')
end
print('PASS: '..checks..' desktop player scale and mobile calibration checks')
