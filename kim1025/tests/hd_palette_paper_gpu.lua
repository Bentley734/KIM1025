-- Native hit shakes over an HD scene must not introduce opaque zone paper.
local root=assert(os.getenv('KIM_PARTY_SOURCE_ROOT'))
local engine=assert(os.getenv('ENGINE_TEST_ROOT'))
local output=assert(os.getenv('KIM_PARTY_TEST_OUTPUT'))
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local function write(p,s)local f=assert(io.open(p,'wb'));f:write(s);f:close()end
function love.load()
 local ok,err=xpcall(function()
  local G=love.graphics;local source=read(root..'/main.lua')
  local native=read(engine..'/src/battle/BattleState.lua')
  local function between(s,first,last)
   local a=assert(s:find(first,1,true));local b=assert(s:find(last,a+#first,true));return s:sub(a,b-1)
  end
  local B={};local paperless=true
  local palette={shader=function()end,forcesRawGrays=function()return false end,
   permute=function(p)return p end,sendColors=function()end,sendShades=function()end}
  local env=setmetatable({BattleState=B,Timing=assert(loadstring(read(engine..'/src/core/Timing.lua')))(),
   hdBattleBackgroundsEnabled=function()return paperless end,unpackCompat=unpack,
   require=function(n)if n=='src.render.PaletteFX'then return palette end;return require(n)end},{__index=_G})
  local function compile(s)local f=assert(loadstring(s));setfenv(f,env);return f()end
  local zones=compile(between(native,'local BATTLE_ZONES =','-- the colorizer')..'return BATTLE_ZONES')
  env.BATTLE_ZONES=zones
  compile(between(native,'function BattleState:drawZonePass(','-- SetAnimationPalette'))
  compile(between(native,'local function fastShakeProg(','-- Route one AnimPlayer')..
    between(native,'function BattleState:applyHitFx(','-- Primary status effects'))
  B.sgbBattlePals=function()return {[0]={},[1]={},[2]={},[3]={}}end
  B.activeBgp=function()end
  local wrap=compile(between(source,'  local function withoutBattleBackgroundFill(','  -- Gen1 animated sprites')..'return withoutBattleBackgroundFill')
  local src=G.newCanvas(160,144)
  G.setCanvas(src);G.origin();G.clear(0,0,0,0);G.setColor(.2,.4,.6,1)
  -- Genuine foreground content crosses native palette-cell boundaries.
  for _,r in ipairs({{16,45,32,32},{101,10,31,31},{15,5,30,5},{97,67,41,5},{35,110,70,9}})do G.rectangle('fill',unpack(r))end
  G.setCanvas()
  local actual,expected=G.newCanvas(160,144),G.newCanvas(160,144)
  local rawZone=B.drawZonePass
  local nativeCalls,sceneCalls=0,0
  env.mod={_kantoInMotionGuardedMobileCall=function(_,fn,...)return pcall(fn,...)end}
  env.battleLiteFullScreenActive=function()return true end
  env.restoreBattleLayout=function()error('HD presentation must not yield to a vanilla screen')end
  env.setFlatBattleWorld=function()sceneCalls=sceneCalls+1 end
  env.withoutBattleBackgroundFill=wrap
  env.nativeBattleDraw=function(self)nativeCalls=nativeCalls+1;self:drawZonePass(src,self.sx,self.sy);return 'native' end
  local a=assert(source:find('        BattleState.draw = function(self, ...)',1,true))
  local b=assert(source:find('\n        end\n      end',a,true))+#'\n        end'
  compile(source:sub(a,b))
  local frames=0
  for attackType=1,6 do
   local state=setmetatable({game={},animPlaying=true,fx={},frame=1,sx=0,sy=0},{__index=B})
   state:applyHitFx({animType=attackType,blink={isPlayer=false}})
   local prog=state.fx.shakeProg or {{frames=60}}
   for _,step in ipairs(prog)do for n=1,step.frames do
    state.sx,state.sy=step.dx or 0,step.dy or 0
    G.setCanvas(actual);G.origin();G.clear(0,0,0,0)
    local before=sceneCalls;assert(B.draw(state)=='native');assert(sceneCalls==before+1,'HD scene remains owned throughout move feedback')
    assert(rawget(state,'drawZonePass')==nil and B.drawZonePass==rawZone,'native zone method restored')
    G.setCanvas(expected);G.origin();G.clear(0,0,0,0);G.setColor(1,1,1,1)
    -- Expected foreground: the same native zone clips/offsets, without paper.
    for _,z in ipairs(zones)do G.setScissor(z[1]*8,z[2]*8,(z[3]-z[1]+1)*8,(z[4]-z[2]+1)*8);G.draw(src,state.sx,state.sy)end
    G.setScissor();G.setCanvas()
    local pix,ref=actual:newImageData(),expected:newImageData()
    for y=0,143 do for x=0,159 do
     local r,g,b,al=pix:getPixel(x,y);local er,eg,eb,ea=ref:getPixel(x,y)
     assert(math.abs(r-er)<.002 and math.abs(g-eg)<.002 and math.abs(b-eb)<.002 and math.abs(al-ea)<.002,'opaque native paper at type '..attackType..' offset '..state.sx..','..state.sy..' pixel '..x..','..y)
    end end
    frames=frames+1
   end end
  end
  -- Actual flash rectangles outside the zone pass and unrelated canvases survive.
  local rect,clear=G.rectangle,G.clear
  local state=setmetatable({},{__index=B})
  G.setCanvas(actual);G.clear(0,0,0,0)
  wrap(state,function()G.setColor(1,1,1,.85);G.rectangle('fill',0,0,160,144)end)
  G.setCanvas();local _,_,_,alpha=actual:newImageData():getPixel(150,130);assert(alpha>.8,'native flash retained')
  local original=function()error('injected native draw error')end;state.drawZonePass=original
  assert(not pcall(wrap,state,function(s)s:drawZonePass()end),'native error propagates')
  assert(state.drawZonePass==original and G.rectangle==rect and G.clear==clear,'temporary interception restored after errors')
  assert(nativeCalls==sceneCalls and sceneCalls==frames)
  write(output..'/result.txt','PASS: '..frames..' native feedback frames, all six player/enemy hit/status types; transparent palette zones, stable HD ownership, foreground preservation, native flashes and error restoration\n')
 end,debug.traceback)
 if not ok then write(output..'/result.txt','FAIL: '..tostring(err)..'\n')end
 love.event.quit(ok and 0 or 1)
end
