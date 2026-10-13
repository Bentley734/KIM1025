-- Auto fits the entire idle animation at its existing ground-contact anchor.
-- All coordinates are final-world pixels; the lower dialog is deliberately
-- not an obstacle because the world is composited underneath it.
local api = {}
local measured = setmetatable({}, { __mode = "k" })

local function pixels(image)
  if image.newImageData then
    local ok, data = pcall(image.newImageData, image)
    if ok and data then return data end
  end
  if image.getData then
    local ok, data = pcall(image.getData, image)
    if ok and data and data.getPixel then return data end
  end
  local g = love and love.graphics
  if not (g and g.newCanvas) then return nil end
  local canvas
  local previous = g.getCanvas()
  g.push("all")
  local ok, data = pcall(function()
    canvas = g.newCanvas(image:getDimensions())
    g.setCanvas(canvas); g.origin(); g.setScissor(); g.setShader()
    g.setBlendMode("replace"); g.setColor(1, 1, 1, 1); g.clear()
    g.draw(image, 0, 0)
    if previous then g.setCanvas(previous) else g.setCanvas() end
    return canvas:newImageData()
  end)
  if previous then g.setCanvas(previous) else g.setCanvas() end
  g.pop()
  if canvas and canvas.release then canvas:release() end
  if ok then return data end
end

-- Atlas union is measured once, never per pose. Transparent bottom padding
-- is removed from the origins. The visible union stays on the mound centre.
function api.measure(image, w, h, columns, count)
  local hit = measured[image]
  if hit then return hit end
  local data = pixels(image)
  if not (data and data.getPixel) then return nil end
  local x0, y0, x1, y1 = w, h, -1, -1
  for frame = 0, (count or 1) - 1 do
    local bx, by = (frame % (columns or 1)) * w,
      math.floor(frame / (columns or 1)) * h
    for y = 0, h - 1 do for x = 0, w - 1 do
      local a = select(4, data:getPixel(bx + x, by + y))
      if a and a > 0 then
        x0, y0 = math.min(x0, x), math.min(y0, y)
        x1, y1 = math.max(x1, x), math.max(y1, y)
      end
    end end
  end
  if data.release then data:release() end
  if x1 < x0 then return nil end -- a pending transparent proxy is not cached
  hit = {x0=x0, y0=y0, x1=x1+1, y1=y1+1,
    ox=(x0+x1+1)/2, ground=y1+1}
  measured[image] = hit
  return hit
end

function api.fit(bounds, ax, ay, vw, vh, obstacles, grow)
  if type(bounds) ~= "table" then return nil end
  for _, key in ipairs({"x0","y0","x1","y1","ox","ground"}) do
    local value = bounds[key]
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then return nil end
  end
  local left, right = bounds.ox - bounds.x0, bounds.x1 - bounds.ox
  local above, below = bounds.ground - bounds.y0, bounds.y1 - bounds.ground
  local width, height = bounds.x1-bounds.x0, bounds.y1-bounds.y0
  if width <= 0 or height <= 0 or vw <= 0 or vh <= 0 then return nil end
  -- Use every available pixel: window-fraction caps made Auto unnecessarily
  -- small, especially on ultrawide displays. Two pixels cover draw rounding.
  local pad = 2
  local s = math.huge
  local function limit(distance, extent)
    if extent > 0 then s = math.min(s, math.max(0, distance) / extent) end
  end
  limit(ax-pad, left); limit(vw-pad-ax, right)
  limit(ay-pad, above); limit(vh-pad-ay, below)
  -- The player belongs below the enemy's name/HP band even if there is room
  -- beside it. The first obstacle is that band's actual occupied 32 rows.
  local enemy = obstacles and obstacles[1]
  if enemy then limit(ay-enemy.y-enemy.h-pad, above) end
  for _, r in ipairs(obstacles or {}) do
    -- Any separating axis keeps the silhouette rectangle clear. Choose the
    -- largest valid scale, rather than unnecessarily applying all four caps.
    local cap = 0
    if ax > r.x+r.w+pad and left > 0 then
      cap = math.max(cap, (ax-r.x-r.w-pad)/left)
    end
    if ax < r.x-pad and right > 0 then
      cap = math.max(cap, (r.x-pad-ax)/right)
    end
    if ay > r.y+r.h+pad and above > 0 then
      cap = math.max(cap, (ay-r.y-r.h-pad)/above)
    end
    if ay < r.y-pad and below > 0 then
      cap = math.max(cap, (r.y-pad-ay)/below)
    end
    s = math.min(s, cap)
  end
  if s <= 0 then return nil end
  s = s * math.max(0, math.min(1, tonumber(grow) or 1))
  return {scale=s, x=ax-bounds.ox*s, y=ay-bounds.ground*s,
    centerX=ax, centerY=ay-(bounds.ground-(bounds.y0+bounds.y1)/2)*s,
    groundShift=0, groundPx=0}
end
return api
