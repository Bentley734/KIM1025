local draw=assert(loadfile(arg[1]..'/lib/gen1_battle_motion.lua'))()
local x,y,s=0,0,1;local stack={};local observed={}
love={graphics={push=function()stack[#stack+1]={x,y,s}end,pop=function()local t=table.remove(stack);x,y,s=t[1],t[2],t[3]end,translate=function(a,b)x=x+a*s;y=y+b*s end,scale=function(n)s=s*n end}}
local old={};local frame={};local mon={sprite=old}
local battle={fx={shakeX=2,shakeY=-1},picFx={[mon]={ox=8,oy=3}}}
function battle:drawBattlerPic(b,px,py,scale)
 assert(b.sprite==frame and self.wideRegion)
 local fx=self.picFx[b];observed={x+(px+fx.ox)*s,y+(py+fx.oy)*s,scale*s}
end
draw(battle,mon,frame,100,200,4,3)
assert(observed[1]==130 and observed[2]==206 and observed[3]==4)
assert(mon.sprite==old and not battle.wideRegion and #stack==0)
battle.fx={shake=4};battle.frame=3;draw(battle,mon,frame,100,200,4,3);assert(observed[1]==118)
battle.drawBattlerPic=function()error('native error')end
assert(not pcall(draw,battle,mon,frame,0,0,4,3));assert(mon.sprite==old and not battle.wideRegion and #stack==0)
print('PASS native sprite effect delegation, scaled XY motion/shake, fallback shake and error restoration')
