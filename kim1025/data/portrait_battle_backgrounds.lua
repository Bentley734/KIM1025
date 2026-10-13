-- Portrait extension layers for KIM's HD battle backgrounds.
-- The landscape source remains authoritative: the runtime paints one of these
-- layers first, then draws the unchanged source image over its original band.
local M = {}

local function has(file, prefix)
  return type(file) == "string" and file:sub(1, #prefix) == prefix
end

function M.profile(file)
  file = tostring(file or "")
  -- Route 10 uses an outdoor river bank, not the plant's interior.
  if has(file, "power_plant_exterior") then return "field" end
  if has(file, "mt_moon") then return "cave" end
  if has(file, "silph_co") then return "lab" end
  if has(file, "viridian_forest") then return "forest" end
  if has(file, "grass_") then return "field" end
  if has(file, "road_") then return "road" end
  if has(file, "cave_") or file == "cave_dark" then return "cave" end
  if has(file, "sea_") then return "sea" end
  if has(file, "cerulean_bridge") then return "bridge" end
  if has(file, "gym_") then return "gym" end
  if has(file, "league_") then return "league" end
  if has(file, "oak_lab") then return "lab" end
  if has(file, "pokemon_mansion") then return "mansion" end
  if has(file, "pokemon_tower") then return "tower" end
  if has(file, "power_plant") then return "powerplant" end
  if has(file, "ss_anne") then return "ship" end
  if has(file, "rocket_hideout") then return "hideout" end
  if has(file, "safari") then return "safari" end
  return "field"
end

function M.isWide(vw, vh)
  vw, vh = tonumber(vw), tonumber(vh)
  return vw ~= nil and vh ~= nil and vh > 0 and vw / vh >= 1.6
end

function M.path(file, vw, vh)
  local profile = M.profile(file)
  if M.isWide(vw, vh) then
    return "assets/battle/backgrounds/widescreen/" .. profile .. ".png"
  end
  local suffix = ({field=true, gym=true, league=true})[profile] and ".png" or ".jpg"
  return "assets/battle/backgrounds/portrait/" .. profile .. suffix
end

function M.tint(file)
  file = tostring(file or "")
  if file:match("_night$") then return 0.52, 0.62, 0.86, 1 end
  if file:match("_sunrise$") then return 1.00, 0.83, 0.72, 1 end
  if file:match("_sunset$") then return 1.00, 0.70, 0.58, 1 end
  return 1, 1, 1, 1
end

-- Cover the whole portrait viewport without introducing letterbox bars.
-- Conservative ground/floor boundaries in the extension artwork. Anchoring
-- these above the original battlefield's grass prevents a second sky strip
-- from appearing through its feathered bottom edge. Uniform overscan keeps
-- the image undistorted and still covers every viewport edge.
local GROUND = {
  field=0.28, forest=0.47, road=0.51, safari=0.43, sea=0.48,
  bridge=0.49, cave=0.49, gym=0.49, league=0.52, lab=0.49,
  mansion=0.42, tower=0.52, powerplant=0.51, ship=0.53, hideout=0.47,
}
-- Measured floor/terrain boundaries of the dedicated horizontal images.
local WIDE_GROUND = {
  field=0.45, forest=0.53, road=0.65, safari=0.53, sea=0.60,
  bridge=0.60, cave=0.55, gym=0.54, league=0.55, lab=0.60,
  mansion=0.50, tower=0.62, powerplant=0.57, ship=0.56, hideout=0.54,
}
function M.cover(iw, ih, vw, vh, file, groundCeiling)
  iw, ih = tonumber(iw), tonumber(ih)
  vw, vh = tonumber(vw), tonumber(vh)
  if not (iw and ih and vw and vh and iw > 0 and ih > 0
      and vw > 0 and vh > 0) then return nil end
  local scale = math.max(vw / iw, vh / ih)
  local y = (vh - ih * scale) * 0.5
  if file then
    local ceiling = math.max(0, math.min(vh * 0.8, tonumber(groundCeiling) or vh * 0.40))
    -- Use the actual artwork's boundary, including when the window rotates.
    local groundProfile = M.isWide(iw, ih) and WIDE_GROUND or GROUND
    local ground = ih * (groundProfile[M.profile(file)] or 0.62)
    scale = math.max(scale, ceiling / ground, (vh - ceiling) / (ih - ground))
    y = ceiling - ground * scale
  end
  return (vw - iw * scale) * 0.5, y, scale
end

return M
