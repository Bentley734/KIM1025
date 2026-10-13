-- Complete, baked HD arenas. Each includes both original battle platforms.
-- The embedded source rectangle maps back to the original 1920x950 geometry;
-- the original ground anchors and sprite transforms remain authoritative.
local M = {}
local frames = {
  portrait={x=480,y=1000,scale=0.5,width=1920,height=3413},
  widescreen={x=480,y=256,scale=0.5,width=1920,height=1080},
  ultrawide={x=1568,y=256,scale=0.5,width=4096,height=1152},
}
function M.frame(vw,vh)
  local ratio=(tonumber(vw) or 0)/math.max(1,tonumber(vh) or 1)
  return frames[ratio>=3 and 'ultrawide' or ratio>=1.6 and 'widescreen' or 'portrait']
end
function M.path(file,vw,vh)
  if type(file)~='string' or not file:match('^[%w_]+$') then return nil end
  local frame=M.frame(vw,vh)
  local aspect=frame==frames.ultrawide and 'ultrawide' or frame==frames.widescreen and 'widescreen' or 'portrait'
  return 'assets/battle/backgrounds/aspect/'..aspect..'/'..file..'.jpg'
end
function M.transform(vw,vh,stage)
  local f=M.frame(vw,vh)
  local sx=tonumber(stage.sx or stage.scale) or 1
  local sy=tonumber(stage.sy or stage.scale) or 1
  return {x=stage.x-f.x*sx/f.scale,y=stage.y-f.y*sy/f.scale,
    sx=sx/f.scale,sy=sy/f.scale}
end
return M
