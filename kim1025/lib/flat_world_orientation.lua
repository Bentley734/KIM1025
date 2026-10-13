-- KIM's 2D arena is authored in top-origin screen coordinates. Unlike the
-- voxel pipeline, it has no clip-space pre-flip. Keep its final blit upright
-- without copying the canvas or changing how other world providers render.
return function()
  local ok, Renderer = pcall(require, "src.render.Renderer")
  if not ok or type(Renderer) ~= "table"
      or type(Renderer.endFrame) ~= "function"
      or type(Renderer.mirrorsWorldOverride) ~= "function" then
    return function() end
  end
  if Renderer._kimFlatWorldOrientationV18 then
    return Renderer._kimFlatWorldOrientationV18
  end
  local mirrors = Renderer.mirrorsWorldOverride
  local endFrame = Renderer.endFrame
  local frames = {}
  local unpackFn = table.unpack or unpack
  local function pack(...) return { n = select("#", ...), ... } end
  Renderer.mirrorsWorldOverride = function(...)
    if frames[#frames] == true then return false end
    return mirrors(...)
  end
  function Renderer:endFrame(...)
    frames[#frames + 1] = self.worldOverride ~= nil
      and self.worldOverride == self._kimUprightWorldCanvas
    local results = pack(pcall(endFrame, self, ...))
    frames[#frames] = nil
    if not results[1] then error(results[2], 0) end
    return unpackFn(results, 2, results.n)
  end
  local function mark(renderer, canvas)
    renderer._kimUprightWorldCanvas = canvas
  end
  Renderer._kimFlatWorldOrientationV18 = mark
  return mark
end
