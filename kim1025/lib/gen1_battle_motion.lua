-- HD placement retains the engine's live per-picture effects and shake.
return function(battle,battler,frame,x,y,scale,unit)
 local G=love.graphics
 unit=math.max(.01,tonumber(unit)or scale or 1)
 local fx=battle.fx or{}
 local sx,sy=fx.shakeX or 0,fx.shakeY or 0
 if sx==0 and sy==0 and (fx.shake or 0)>0 then sx=(battle.frame or 0)%4<2 and 2 or -2 end
 local sprite,wide=battler.sprite,battle.wideRegion
 battler.sprite=frame;battle.wideRegion=true
 G.push('all');G.translate(x+sx*unit,y+sy*unit);G.scale(unit,unit)
 local ok,err=pcall(function()
  if type(battle.drawBattlerPic)=='function'then
   battle:drawBattlerPic(battler,0,0,scale/unit,0,0)
  else G.draw(frame,0,0,0,scale/unit,scale/unit)end
 end)
 G.pop();battler.sprite=sprite;battle.wideRegion=wide
 if not ok then error(err,0)end
 return true
end
