-- Run from the mod directory: luatex --luaonly tests/portrait_battle.lua
local checks=0
local function eq(a,b,label) checks=checks+1;assert(a==b,label..': '..tostring(a)..' ~= '..tostring(b)) end
local function read(p)local f=assert(io.open(p));local s=f:read('*a');f:close();return s end
for _,host in ipairs({'Windows','Linux','OS X','Android','iOS'})do
 local active,hd,sprites,modal=true,true,true,false
 local width,height=480,990
 local hooks,draws={},{}
 local function canvas(kind)return {kind=kind,getWidth=function()return 240 end,getHeight=function()return 160 end,setFilter=function()end}end
 local plane,flat=canvas('plane'),canvas('flat')
 local Display={fit=function(w,h)local s=math.min(w/240,h/160);return s,0,76,240*s,160*s,s end,
  present=function()return 'plane'end,presentFlat=function()return 'flat'end,
  ensureCanvas=function(kind)eq(kind,'main','foreground slot');return flat end}
 local modules={['src.core.game3.pokemon']={__completeDexEnsurePics=function()end},
  ['src.core.game3.battle.init']={isActive=function()return active end,getState=function()return {}end},
  ['src.core.game3.display']=Display,['src.render.Renderer']={canvas=plane},
  ['src.ui.game3.stack']={fullscreen=function()return modal end},['src.core.game3.map']={current='FR_ROUTE1'}}
 local bg={kind='background',getWidth=function()return 1920 end,getHeight=function()return 950 end,setFilter=function()end}
 local graphics=setmetatable({getDimensions=function()return width,height end,
  draw=function(image,...)draws[#draws+1]={image=image,args={...}}end},{__index=function()return function()end end})
 local env=setmetatable({package={loaded=modules},require=function(n)if modules[n]then return modules[n]end;error(n)end,
  love={graphics=graphics,system={getOS=function()return host end}}},{__index=_G})
 env.load=function(s,n,m)return load(s,n,m or 't',env)end
 local mod={path='.',options={define=function()end,get=function(_,k)if k=='hdBattleBackgrounds'then return hd end;if k=='battleSprites'then return sprites end end},
  events={on=function()end},hooks={wrap=function(_,n,f)if n=='render.hud'then hooks[#hooks+1]=f end end},
  _kimAssetProvider={image=function()return bg end},read=function(_,p)if p=='data/hd_battle_backgrounds.lua'then return read(p)end end}
 assert(load(read('lib/gen3_frlg.lua'),'bridge','t',env))()(mod)
 local function render(w,h,expected)
  width,height=w,h;eq(Display.present({},w,h),expected,host..' presenter')
  local s,x,y,pw,ph=Display.fit(w,h);draws={}
  for _,f in ipairs(hooks)do f(function()end,{}, {gameX=x,gameY=y,gameWidth=pw,gameHeight=ph})end
  eq(#draws,2,host..' single background/foreground pair')
  eq(draws[1].image,bg,host..' background')
  eq(draws[2].image,expected=='flat'and flat or plane,host..' foreground canvas')
  eq(draws[2].args[1],x,host..' foreground x');eq(draws[2].args[2],y,host..' foreground y')
  eq(draws[2].args[4],s,host..' foreground scale')
 end
 local mobile=host=='Android'or host=='iOS'
 render(480,990,'flat');render(1280,720,mobile and 'flat'or'plane')
 render(390,844,'flat');render(720,720,mobile and 'flat'or'plane')
 width,height=480,990;eq(Display.present({}),'flat',host..' omitted dimensions')
 active=false;eq(Display.present({},480,990),'plane',host..' outside battle')
 active=true;hd=false;sprites=false;eq(Display.present({},480,990),'plane',host..' disabled')
 hd=true;modal=true;draws={};Display.present({},480,990)
 for _,f in ipairs(hooks)do f(function()end,{}, {gameX=0,gameY=76,gameWidth=480,gameHeight=320})end
 eq(#draws,0,host..' fullscreen menu ownership')
end
print('PASS: '..checks..' presenter/compositor assertions')
