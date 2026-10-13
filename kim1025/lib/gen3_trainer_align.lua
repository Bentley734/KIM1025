-- Trim transparent rows only for the native player trainer. All other battle
-- graphics retain their engine coordinates, including the trainer's throw motion.
local M={}
local measured=setmetatable({},{__mode='k'})
function M.bottom(image,quad)
  measured[image]=measured[image] or {}
  local x,y,w,h=quad:getViewport()
  local key=x..':'..y..':'..w..':'..h
  if measured[image][key] then return measured[image][key] end
  local G=love.graphics;local previous=G.getCanvas();local c=G.newCanvas(w,h,{dpiscale=1})
  G.push('all');G.setCanvas(c);G.origin();G.setShader();G.setScissor()
  G.clear();G.setColor(1,1,1,1);G.setBlendMode('replace');G.draw(image,quad,0,0)
  G.setCanvas(previous);G.pop()
  local d=c:newImageData();local bottom=0
  for py=h-1,0,-1 do
    for px=0,w-1 do if select(4,d:getPixel(px,py))>0 then bottom=py+1;break end end
    if bottom>0 then break end
  end
  d:release();c:release();measured[image][key]=bottom
  return bottom
end
function M.scope(fn,...)
  local P=require('src.core.game3.trainer_pic')
  local images={}
  for gender=0,1 do local e=P.back(gender);if e and e.image then images[e.image]=true end end
  local G=love.graphics;local draw=G.draw
  G.draw=function(...)
    local args={...};local image,quad,x,y=args[1],args[2],args[3],args[4]
    if images[image] and type(quad)~='number' and quad and quad.getViewport then
      -- Native backs start at y=48 and nominally end at112. The border's first
      -- opaque row is114; overlap it by one row to prevent a fractional seam.
      local bottom=M.bottom(image,quad)
      if bottom>0 then args[4]=y+115-48-bottom end
    end
    return draw((unpack or table.unpack)(args))
  end
  -- Measuring uses G.draw too: temporarily call the original during readback.
  local bottom=M.bottom
  M.bottom=function(...)local wrapper=G.draw;G.draw=draw
    local result={pcall(bottom,...)};G.draw=wrapper
    if not result[1]then error(result[2],0)end;return (unpack or table.unpack)(result,2)
  end
  local result={pcall(fn,...)};G.draw=draw;M.bottom=bottom
  if not result[1]then error(result[2],0)end;return (unpack or table.unpack)(result,2)
end
return M
