-- Exercise the production Gen 1/2 sprite renderer with a clock and clipped host.
local f = assert(io.open('main.lua')); local source = f:read('*a'); f:close()
local function section(first, last)
  local a = assert(source:find(first, 1, true))
  local b = assert(source:find(last, a + #first, true))
  return source:sub(a, b - 1)
end
local checks = 0
local function eq(a, b, label)
  checks = checks + 1
  assert(a == b, label .. ': ' .. tostring(a) .. ' ~= ' .. tostring(b))
end
for _, gen2 in ipairs({false, true}) do
  local tick, canvas, scissor = 0, nil, 'native player clip'
  local stack, reads = {}, 0
  local function image(w, h)
    return {getDimensions=function() return w,h end, setFilter=function() end}
  end
  local atlas = image(4,2)
  local rec = {image='back.png',width=2,height=2,columns=2,frames=2,
    durations={50,50},hdTest=true,displayScale=1}
  local options = {animate=true,battleSprites=true,battlePlayerSize='100'}
  local mod = {exports={},options={get=function(_,key) return options[key] end}}
  local G = {
    newCanvas=image,newQuad=function(x) return {frame=x/2+1} end,
    getCanvas=function() return canvas end,setCanvas=function(c) canvas=c end,
    push=function() stack[#stack+1]={canvas=canvas,scissor=scissor} end,
    pop=function() local s=table.remove(stack);canvas,scissor=s.canvas,s.scissor end,
    setScissor=function(s) scissor=s end,
    clear=function() if canvas and not scissor then canvas.frame=0 end end,
    draw=function(src,quad)
      if canvas and not scissor then
        canvas.frame=type(quad)=='table' and quad.frame or src.frame
      end
    end,
    origin=function() end,setShader=function() end,setColor=function() end,
    setBlendMode=function() end,
  }
  local env=setmetatable({IS_GEN2=gen2,mod=mod,
    love={graphics=G,timer={getTime=function() return tick end}},
    frameCache={},renderCache={},battleProxyCache={},BATTLE_BRIDGE_PREFIX='kim-battle/',
    atlasImage=function() reads=reads+1;return atlas end,
    battleLiteOwnsSprites=function() return true end,
    battleRecord=function(_,side,mon) return rec,'hd',mon.species,mon.shiny end,
    localBackRecord=function() return rec end,localShinyBackRecord=function() return rec end,
    localFrontRecord=function() return rec end,localShinyFrontRecord=function() return rec end,
    potatoMobileEnemyFactor=function() return 1 end,
  },{__index=_G})
  local core=section('  local function timingFor(', '  local function getSprite(')
  local bridge=section('  local function battleBridgePath(', '  -- KIM player battle-trainer system.')
  -- After moving the path producer below its renderer, include the decoder too.
  if source:find('  local function decodeBattleBridgePath(',1,true)
      < source:find('  local function battleBridgePath(',1,true) then
    bridge=section('  local function decodeBattleBridgePath(', '  -- KIM player battle-trainer system.')
  end
  local proxy,path,decode=assert(load(core..bridge..
    '\nreturn battleProxy,battleBridgePath,decodeBattleBridgePath','production sprites','t',env))()
  local spriteHook
  mod.hooks={wrap=function(_,name,fn) spriteHook=fn end}
  env.battleBridgePath=path
  env.menuSpritesEnabled=function() return false end
  local hookCode=section('  if mod.hooks and type(mod.hooks.wrap) == "function" then\n    mod.hooks:wrap("pokemon.sprite"', '  -- -----------------------------------------------------------------------\n  -- Battle Lite runtime')
  assert(load(hookCode,'production battle constructor hook','t',env))()
  for _,side in ipairs({'front','back'}) do
    local ctx={kind='battle',side=side,species='BULBASAUR',mon={species='BULBASAUR'}}
    local initial=spriteHook(function() return 'vanilla.png' end,'vanilla.png',ctx)
    eq(initial:sub(1,11),'kim-battle/','constructor starts with HD art')
    eq(ctx.trueColor,true,'constructor preserves HD colors')
  end
  local mon={species='BULBASAUR'}
  local first=proxy(rec,'hd','back','normal',mon.species)
  eq(first.frame,1,'first player frame with inherited scissor')
  tick=0.06
  local second=proxy(rec,'hd','back','normal',mon.species)
  eq(second==first,gen2,'Gen 1 immutable frames / Gen 2 live cached drawable')
  eq(second.frame,2,'cached player drawable advances')
  if not gen2 then eq(first.frame,1,'earlier native frame remains immutable') end
  local prepared = setmetatable({}, {__mode='k'})
  for cycle=1,5 do
    for phase=0,1 do
      tick=cycle*0.1+phase*0.05+0.001
      local pic=proxy(rec,'hd','back','normal',mon.species)
      prepared[pic]=prepared[pic] or pic.frame
      eq(gen2 and pic.frame or prepared[pic],phase+1,'animation loops through cached native processing')
    end
  end
  eq(scissor,'native player clip','host clipping restored')
  for _,side in ipairs({'front','back'}) do
    local virtual=path(mon.species,side,mon)
    local record,generation,decodedSide=decode(virtual)
    eq(record,rec,'virtual sprite resolves');eq(generation,'hd','generation')
    eq(decodedSide,side,'side retained')
  end
  eq(decode('kim-battle/hd/trainer/normal/BULBASAUR.png'),nil,'invalid side rejected')
  options.animate=false
  eq(proxy(rec,'hd','back','normal',mon.species).frame,1,'ANIMATION OFF holds frame one')
  options.battleSprites=false
  eq(mod.exports._kantoInMotionStagedBattleSprite,nil,'3D provider absent')
  eq(reads,1,'atlas is cached')
end
print('PASS: '..checks..' Gen 1/2 battle animation checks')
