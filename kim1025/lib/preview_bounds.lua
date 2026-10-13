-- Centre visible artwork in script-picture windows. Use one union across the
-- animation, so the anchor stays fixed as frames change.
local cache=setmetatable({},{__mode='k'})
return function(source)
 local saved=cache[source];if saved then return saved[1],saved[2]end
 local G=love.graphics
 if not G.newCanvas then return 0,0 end
 local c=G.newCanvas(source.iw,source.ih,{dpiscale=1})
 G.push('all');G.setCanvas(c);G.origin();G.setShader();G.setScissor()
 G.setBlendMode('replace');G.clear(0,0,0,0);G.setColor(1,1,1,1);G.draw(source.image,0,0);G.pop()
 local data=c:newImageData();c:release()
 local left,top,right,bottom=source.width,source.height,-1,-1
 for frame=0,source.count-1 do
  local ax,ay=frame%source.columns*source.width,math.floor(frame/source.columns)*source.height
  for y=0,source.height-1 do for x=0,source.width-1 do
   local _,_,_,a=data:getPixel(ax+x,ay+y)
   if a>0 then left=math.min(left,x);right=math.max(right,x);top=math.min(top,y);bottom=math.max(bottom,y)end
  end end
 end
 data:release()
 local dx,dy=0,0
 if right>=left then dx=(source.width-left-right-1)/2;dy=(source.height-top-bottom-1)/2 end
 cache[source]={dx,dy};return dx,dy
end
