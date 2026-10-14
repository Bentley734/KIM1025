-- Real GPU regression using the cartridge's ball atlas and native drawBallRow.
local root=assert(os.getenv('KIM_PARTY_SOURCE_ROOT'))
local engine=assert(os.getenv('ENGINE_TEST_ROOT'))
local cache=assert(os.getenv('POKEMON_CACHE_ROOT'))
local output=assert(os.getenv('KIM_PARTY_TEST_OUTPUT'))
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local function write(p,s)local f=assert(io.open(p,'wb'));f:write(s);f:close()end
function love.load()
 local ok,err=xpcall(function()
  local G=love.graphics
  local image=G.newImage(love.filesystem.newFileData(read(cache..'/red/assets/generated/battle/balls.png'),'balls.png'))
  image:setFilter('nearest','nearest')
  local quads={img=image};for i=0,3 do quads[i]=G.newQuad(i*8,0,8,8,image:getDimensions())end
  local native=read(engine..'/src/battle/BattleState.lua')
  local a=assert(native:find('function BattleState:drawBallRow(',1,true))
  local b=assert(native:find('\nend',a,true))+4
  local B={}
  local row=assert(loadstring(native:sub(a,b)))
  setfenv(row,setmetatable({BattleState=B,balls=function()return quads end,ballObpSheet=function()end},{__index=_G}));row()
  local source=read(root..'/main.lua')
  a=assert(source:find('  local function captureBattleHud(',1,true))
  b=assert(source:find('  local BATTLE_HUD_SHADER =',a,true))
  local mobile=false
  local mod={_kantoInMotionNativeMobileGen1=function()return mobile end,
   _kantoInMotionRestoreGraphicsDepth=function(depth)while G.getStackDepth()>depth do G.pop()end end}
  local env=setmetatable({love=love,mod=mod,menuBattleUi=function()end,
   sizedBattleCanvas=function(c,w,h)local out=c or G.newCanvas(w,h);out:setFilter('nearest','nearest');return out end},{__index=_G})
  local fn=assert(loadstring(source:sub(a,b-1)..'return captureBattleHud'));setfenv(fn,env);local capture=fn()
  local party={{hp=10},{hp=10,status='poison'},{hp=0}}
  local checks=0
  for _,host in ipairs({'Windows','Android'})do
   mobile=host=='Android'
   for _,case in ipairs({{kind='trainer',intro=true},{kind='link',intro=true},{kind='wild',intro=true},{kind='trainer',intro=false,enemy=true},{kind='trainer',intro=true,slide=3}})do
    local battle=setmetatable({game={},kind=case.kind,introBalls=case.intro,showEnemyBalls=case.enemy,enemyParty=party},{__index=B})
    function battle:drawHUDs(slide)
     if slide==0 and ((self.introBalls and self.kind~='wild') or self.showEnemyBalls)then self:drawBallRow(party,64,16,-8)end
     if slide==0 and self.introBalls then self:drawBallRow(party,88,80,8)end
     -- A live HP cell sharing the former player-ball row must also survive.
     if not self.introBalls then G.rectangle('fill',88,80,6,8)end
    end
    local actual,split=capture(battle,case.slide or 0)
    assert(actual,'native HUD must be captured')
    assert(battle.colorMode==nil and G.getCanvas()==nil and G.getStackDepth()==0,'capture restores battle and graphics state')
    local reference=G.newCanvas(320,296)
    G.push('all');G.setCanvas(reference);G.origin();G.scale(2,2);G.translate(0,4);G.clear(0,0,0,0);G.setShader();G.setColor(1,1,1,1)
    battle:drawHUDs(case.slide or 0);G.pop();G.setCanvas()
    local actualPixels,expected=actual:newImageData(),reference:newImageData()
    for y=0,295 do for x=0,319 do
     local ar,ag,ab,aa=actualPixels:getPixel(x,y);local er,eg,eb,ea=expected:getPixel(x,y)
     assert(math.abs(ar-er)<.002 and math.abs(ag-eg)<.002 and math.abs(ab-eb)<.002 and math.abs(aa-ea)<.002,host..' '..case.kind..' ball/HP pixel erased at '..x..','..y)
    end end
    checks=checks+1
    if host=='Windows' and case.kind=='trainer' and case.intro and not case.slide then
     write(output..'/native-party-balls.png',actualPixels:encode('png'):getString())
    end
   end
  end
  write(output..'/result.txt','PASS: '..checks..' real GPU/native cartridge party-ball captures; healthy/status/fainted/empty slots, both sides, wild/link/trainer, slides, HP preservation and desktop/mobile restoration\n')
 end,debug.traceback)
 if not ok then write(output..'/result.txt','FAIL: '..tostring(err)..'\n')end
 love.event.quit(ok and 0 or 1)
end
