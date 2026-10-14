-- Compare transparent native picture/OAM capture on every reported move frame.
local root=assert(os.getenv('KIM_PARTY_SOURCE_ROOT'))
local engine=assert(os.getenv('ENGINE_TEST_ROOT'))
local cache=assert(os.getenv('POKEMON_CACHE_ROOT'))
local output=assert(os.getenv('KIM_PARTY_TEST_OUTPUT'))
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local function write(p,s)local f=assert(io.open(p,'wb'));f:write(s);f:close()end
function love.load()
 local ok,err=xpcall(function()
  local G=love.graphics
  package.path=engine..'/?.lua;'..package.path
  local A=assert(loadstring(read(engine..'/src/battle/AnimPlayer.lua')))()
  local data=assert(loadstring(read(cache..'/red/data/generated/battle_anims.lua')))()
  local species=assert(loadstring(read(cache..'/red/data/generated/pokemon.lua')))()
  local function image(path)
   local img=G.newImage(love.filesystem.newFileData(read(cache..'/red/'..path),'native.png'));img:setFilter('nearest','nearest');return img
  end
  local nativeSource=read(engine..'/src/battle/BattleState.lua')
  local B={}
  local function install(first,last)
   local a=assert(nativeSource:find(first,1,true));local b=assert(nativeSource:find(last,a,true))
   local chunk=assert(loadstring(nativeSource:sub(a,b-1)));setfenv(chunk,setmetatable({BattleState=B},{__index=_G}));chunk()
  end
  install('function BattleState:picFxFor(', '-- transient pic effects')
  install('function BattleState:animFxBattler(', '-- a row\'s sound byte')
  install('function BattleState:applyAnimEffect(', '-- engine/battle/animations.asm:2639')
  install('function BattleState:drawBattlerPic(', '-- ------------------------------------------------------------------\n-- SGB battle colorization.')
  B.picImage=function(_,img)return img end
  B.fxFaintActive=function()return false end
  B.playAnimSound=function()end
  local function nativeDraw(self)
   G.setShader();G.setScissor();G.setColor(1,1,1,1)
   self:drawBattlerPic(self.player,8,40,2,0,0)
   self:drawBattlerPic(self.enemy,96,0,1,0,0)
   self.animPlayer:draw()
   return 'native-result',self.animName
  end
  local source=read(root..'/main.lua')
  B.drawPicsLayer=function(self)
   G.setColor(1,1,1,1)
   self:drawBattlerPic(self.player,8,40,2,0,0)
   self:drawBattlerPic(self.enemy,96,0,1,0,0)
  end
  B.drawAnimLayer=function(self)self.animPlayer:draw()end
  B.colorMode=function()return false end
  local a=assert(source:find('  local function captureBattleScene(',1,true))
  local b=assert(source:find('  local function drawNativeBattleOverlay(',a,true))
  local env=setmetatable({mod={_kantoInMotionNativeMobileGen1=function()return false end},
   logicalCanvas=function(c)return c or G.newCanvas(160,144)end,
   battleOffsets=function()return 0,0,0 end,battleLiteDirectStageActive=function()return false end,
   battleLiteOwnsSprites=function()return false end,
   require=function(n)if n=='src.mods.Runtime'then return {}end;return require(n)end},{__index=_G})
  local setup=assert(loadstring(source:sub(a,b-1)..'return captureBattleScene'));setfenv(setup,env);local capture=setup()
  local reference=G.newCanvas(160,144)
  local frames=0
  for _,id in ipairs({'TACKLE','GROWL','TAIL_WHIP'})do for _,side in ipairs({true,false})do
   local ap=A.new(data)
   for ts,sheet in pairs(data.tilesheets)do ap.images[ts]=image(sheet.path)end
   ap:start(id,side)
   local state=setmetatable({animPlaying=true,animName=id,animAttackerIsPlayer=side,animPlayer=ap,
    player={isPlayer=true,sprite=image(species.RATTATA.spriteBack)},
    enemy={isPlayer=false,sprite=image(species.PIDGEY.spriteFront)},game={}}, {__index=B})
   local n=0
   while not ap:isDone()do
    for _,ev in ipairs(ap:pollEffects())do state:applyAnimEffect(ev)end
    local actual=assert(capture(state,0,0),'transparent native layers captured')
    G.setCanvas(reference);G.origin();G.clear(0,0,0,0);nativeDraw(state);G.setCanvas()
    local pixels,expected=actual:newImageData(),reference:newImageData()
    for y=0,143 do for x=0,159 do
     local r,g,b,al=pixels:getPixel(x,y);local er,eg,eb,ea=expected:getPixel(x,y)
     assert(math.abs(r-er)<.002 and math.abs(g-eg)<.002 and math.abs(b-eb)<.002 and math.abs(al-ea)<.002,id..' native frame differs: '..tostring(side)..' '..n..' '..x..','..y)
    end end
    n=n+1;frames=frames+1;assert(n<500,'animation must complete');ap:update()
   end
   assert(n>0,'reported move must have frames')
  end end
  write(output..'/result.txt','PASS: '..frames..' pixel-identical transparent native picture/OAM frames for player/enemy Tackle, Growl and Tail Whip; native player unchanged\n')
 end,debug.traceback)
 if not ok then write(output..'/result.txt','FAIL: '..tostring(err)..'\n')end
 love.event.quit(ok and 0 or 1)
end
