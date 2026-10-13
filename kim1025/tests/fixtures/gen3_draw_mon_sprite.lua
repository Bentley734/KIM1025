-- Gen1Recomp src/core/game3/battle/ui.lua native draw function.
-- Source: https://github.com/bryanthaboi/gen1recomp (retrieved 2026-10-02).
local function draw_mon_sprite(battler, base, back, id)
  if not battler then return end
  local side = back and "player" or "enemy"
  local key = id or side
  local pres = Anim.present(key)
  if pres and (pres.visible == false or pres.blinkHidden or pres.battlerInvisible or pres.invisible) then return end
  if id and Ui.targetHidden(id) then return end
  battler = Anim.shownBattler(key, battler) or battler

  local sp = battler.species
  if not sp and battler.mon and Pokemon.speciesOf then
    sp = Pokemon.speciesOf(battler.mon)
  elseif not sp and battler.mon then
    sp = battler.mon.species or battler.mon.speciesId
  end
  local tf = nil
  if battler.expTransform then
    tf = pres and pres.transformSpecies
    if not tf and not (pres and pres.pendingTransform) then tf = battler.expTransform.species end
  end
  if tf then sp = tf end
  local ghost = shows_ghost(side, Ui._st)
  local form = (tonumber(sp) == SPECIES_CASTFORM) and castform_form(side, battler) or 0
  local cx, cy = battler_sprite_center(id or side, sp, base, form, ghost)
  if pres then
    cx = cx + (pres.ox or 0)
    cy = cy + (pres.oy or 0)
  end
  cy = cy + Ui.bounceOffset("mon", id or (back and 0 or 1))
  local scale = (pres and pres.scale) or 1
  local darken = (pres and pres.darken) or 0
  local entry
  local dollImg = pres and pres.substitute and Anim.substituteImage(key)
  if dollImg then
    -- pokefirered/src/battle_gfx_sfx_util.c:794
    entry = { image = dollImg }
    cx = base.x + (pres.ox or 0)
    cy = (pres.substituteY or Anim.substituteY(key)) + (pres.oy or 0)
  end
  if not entry and ghost and Pokemon.ghostPic then
    entry = Pokemon.ghostPic()
  end
  local picSp, shiny, personality = pic_args(battler, sp)
  if not entry and back and Pokemon.backPic then
    entry = Pokemon.backPic(picSp, form, shiny)
  end
  if not entry then
    entry = Pokemon.frontPic and Pokemon.frontPic(picSp, form, shiny, personality)
  end
  if not back and not ghost and not dollImg and pres and (tonumber(pres.monFrame) or 0) ~= 0 then
    -- pokeemerald/src/sprite.c:917
    entry = require("src.core.game3.mon_anim").framePic(picSp, pres.monFrame, shiny) or entry
  end
  if entry and entry.image then
    local a = (pres and pres.alpha) or 1
    local flash = pres and (pres.flash or 0) or 0
    local shade = 1 - darken * (1 - 8 / 255)
    if flash > 0 then
      love.graphics.setColor(1, 1, 1, a * (0.4 + 0.6 * ((flash % 2 == 0) and 1 or 0.3)))
    else
      love.graphics.setColor(shade, shade, shade, a)
    end
    local hFlip = (pres and pres.hFlip) and true or false
    local sx = (hFlip and -1 or 1) * scale * ((pres and pres.sx) or 1)
    local sy = scale * ((pres and pres.sy) or 1)
    local rot = (pres and pres.rotation) or 0
    local blended
    if id then
      blended = BallOpen.setBlendShader(BallOpen.monBlend(id))
      if not blended and id < 2 then blended = BallOpen.setBlendShader(BallOpen.monBlend(side)) end
    else
      blended = BallOpen.setBlendShader(BallOpen.monBlend(side))
    end
    if not blended and pres then
      if pres.palAffine then
        blended = set_affine_shader(pres.palAffine)
      elseif (tonumber(pres.mosaic) or 0) > 0 then
        blended = set_mosaic_shader(entry.image, pres.mosaic)
      elseif pres.grayscale then
        blended = set_gray_shader()
      elseif (tonumber(pres.blendCoeff) or 0) > 0 then
        local c = pres.blendColor or { 1, 1, 1 }
        blended = BallOpen.setBlendShader(pres.blendCoeff * 16, (c[1] or 0) * 31, (c[2] or 0) * 31, (c[3] or 0) * 31)
      end
    end
    if not blended and tf and not dollImg then
      -- pokefirered/src/battle_gfx_sfx_util.c:747
      blended = BallOpen.setBlendShader(6, 31, 31, 31)
    end
    if not blended and id then
      local pc = Ui.previewCoeff(id)
      -- pokefirered/src/battle_controller_player.c:2987
      if pc > 0 then blended = BallOpen.setBlendShader(pc, 31, 31, 31) end
    end
    if pres and type(pres.hShift) == "table" and rot == 0 and sy == 1 then
      local img = entry.image
      local iw, ih = img:getDimensions()
      local top = math.floor(cy - 32 + 0.5)
      for r = 0, ih - 1 do
        local q = row_quad(iw, ih, r)
        local dx = tonumber(pres.hShift[top + r]) or 0
        love.graphics.draw(img, q, cx + dx, top + r, 0, sx, 1, 32, 0)
      end
    else
      love.graphics.draw(entry.image, cx, cy, rot, sx, sy, 32, 32)
    end
    if blended then love.graphics.setShader() end
    if pres and pres.statMask and not dollImg then draw_stat_mask(pres, entry.image, cx, cy, sx, sy) end
  else
    -- Placeholder silhouette so lunge/shake is visible before full pic extract.
    local a = (pres and pres.alpha) or 1
    local flash = pres and (pres.flash or 0) or 0
    if flash > 0 and flash % 2 == 0 then
      love.graphics.setColor(1, 1, 1, a)
    elseif back then
      love.graphics.setColor(0.35, 0.55, 0.95, a)
    else
      love.graphics.setColor(0.95, 0.45, 0.35, a)
    end
    local hw = 24 * scale
    local rot = (pres and pres.rotation) or 0
    local sx = (pres and pres.sx) or 1
    local sy = (pres and pres.sy) or 1
    if rot ~= 0 or sx ~= 1 or sy ~= 1 then
      love.graphics.push()
      love.graphics.translate(cx, cy)
      love.graphics.rotate(rot)
      love.graphics.scale(sx, sy)
      love.graphics.rectangle("fill", -hw, -hw, hw * 2, hw * 2)
      love.graphics.setColor(1, 1, 1, a * 0.9)
      love.graphics.rectangle("line", -hw, -hw, hw * 2, hw * 2)
      love.graphics.pop()
    else
      love.graphics.rectangle("fill", cx - hw, cy - hw, hw * 2, hw * 2)
      love.graphics.setColor(1, 1, 1, a * 0.9)
      love.graphics.rectangle("line", cx - hw, cy - hw, hw * 2, hw * 2)
    end
  end
end

return draw_mon_sprite
