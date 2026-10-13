local function read(p)local f=assert(io.open(p));local s=f:read('*a');f:close();return s end
local checks=0;local function check(v,m)checks=checks+1;assert(v,m)end
local texts,cursors,depth={},{},0
local boxes={}
local G={push=function()depth=depth+1 end,pop=function()depth=depth-1 end}
for _,n in ipairs({'origin','setShader','setScissor','translate','scale','setColor','rectangle'})do G[n]=function()end end
local font={drawBox=function(...)boxes[#boxes+1]={...}end,draw=function(t,x,y)texts[#texts+1]={t=t,x=x,y=y}end,drawCode=function(c,x,y)cursors[#cursors+1]={c,x,y}end}
local env=setmetatable({love={graphics=G},require=function(n)if n=='src.render.Font'then return font end;return {displayName=function(t)return t end}end},{__index=_G})
local api=assert(load(read('lib/battle_move_menu.lua'),'menu','t',env))()()
for _,case in ipairs({{1024,288,1,1},{1434,201,1,1},{478,67,3,3},{390,117,3,3},{640,144,1,1},{960,240,2,3}})do
 local w,h,dx,dy=table.unpack(case);local rect={x=20,y=30,w=w,h=h};local p=api.layout(rect,dx,dy)
 check(math.abs(p.sx*dx-p.sy*dy)<1e-6,'square physical glyphs')
 check(p.x>=rect.x and p.y>=rect.y-1e-6,'inside panel')
 check(p.x+336*p.sx<=rect.x+w+1e-6 and p.y+64*p.sy<=rect.y+h+1e-6,'fits panel')
 check(p.sx*dx<1 or p.sx*dx%1==0,'integer physical enlargement')
end
local b={phase='moveSelect',moveIndex=1,player={curMoves={{id='A',pp=29,ppUps=2},{id='B',pp=0},{id='A',pp=1}}},data={moves={A={name='THUNDERPUNCH',pp=35,type='ELECTRIC'},B={name='WATER GUN',pp=25,type='WATER'}}}}
for i=1,4 do
 texts,cursors={},{};b.moveIndex=i
 check(api.draw(b,{x=0,y=0,w=1008,h=192},{}),'move menu draws')
 check(#cursors==1,'one selected cursor');check(cursors[1][2]==7+((i-1)%2)*112,'cursor column');check(cursors[1][3]==14+math.floor((i-1)/2)*26,'cursor row')
 local pp,typeName
 for _,t in ipairs(texts)do if t.y==14 and t.x>264 then pp=t.t end;if t.y==46 then typeName=t.t end;check(t.x+#t.t*8<=336,'text within panel')end
 check(pp==({'29/49','0/25','1/35','--/--'})[i],'current / PP Ups maximum')
 check(typeName==({'ELECTRIC','WATER','ELECTRIC','--'})[i],'selected type')
 check(depth==0,'graphics state restored')
end
b.phase='messages';check(api.draw(b,{})==false,'messages use native panel')
b.phase='mimicSelect';check(api.draw(b,{})==false,'mimic retains native behavior')
local events,nativeCalls={},0
local B={drawTextArea=function()nativeCalls=nativeCalls+1 end}
local oldRequire=env.require
local theme={setting=function(k)return k=='style' and 2 or 50 end,
 panel=function()end,faded=function(fn)return fn()end}
local usedFrames=0;theme.panel=function()usedFrames=usedFrames+1 end
local moduleMod={find=function(id)return id=='battleuicustomizer' and {exports=theme}end,
 events={on=function(_,n,fn)events[n]=fn end}}
env.require=function(n)if n=='src.battle.BattleState'then return B end;return oldRequire(n)end
local withTheme=assert(load(read('lib/battle_move_menu.lua'),'menu integration','t',env))()(moduleMod)
local active=true;withTheme.installSourceGuard(function()return active end)
b.phase='moveSelect';B.drawTextArea(b);check(nativeCalls==0,'source move menu suppressed')
local kimGuard=B.drawTextArea
-- Simulate Customizer loading later and placing its own menu outside KIM.
B.drawTextArea=function(self)nativeCalls=nativeCalls+1;return kimGuard(self)end
events['mods.loaded']();B.drawTextArea(b);check(nativeCalls==0,'guard reinstalled outside late Customizer')
local once=B.drawTextArea;events['game.ready']();check(B.drawTextArea==once,'idempotent source guard')
active=false;B.drawTextArea(b);check(nativeCalls==2,'background-off forwards source owners')
active=true;b.phase='messages';B.drawTextArea(b);check(nativeCalls==4,'messages forward source owners')
b.phase='moveSelect';withTheme.draw(b,{x=0,y=0,w=1008,h=192},{})
check(#boxes==8,'Emerald avoids native frames')
check(usedFrames==0,'Emerald does not squeeze exported frames')
theme.setting=function()return 1 end
withTheme.draw(b,{x=0,y=0,w=1008,h=192},{})
check(#boxes==10,'Vanilla draws two native frames')
check(boxes[9][3]==30 and boxes[10][1]==30 and boxes[10][3]==12,'native frame tile geometry')
font.draw=function()error('font failure')end;b.phase='moveSelect';check(not pcall(api.draw,b,{x=0,y=0,w=336,h=64},{}),'error propagated');check(depth==0,'error restores graphics')
print('PASS: '..checks..' move panel / PP / selected type / physical scale checks')

local delegated=0
local merged={find=function(id)if id=='gen3transparency' then return {exports={battleUi={moveScreen={draw=function(battle,rect,viewport)
 delegated=delegated+1;check(battle==b and rect.w==336,'merged renderer receives exact original arguments');return true
end}}}}end end}
local bridge=assert(load(read('lib/battle_move_menu.lua'),'bridge','t',env))()(merged)
b.phase='moveSelect';check(bridge.draw(b,{w=336},{})==true and delegated==1,'merged customizer owns move styling')
