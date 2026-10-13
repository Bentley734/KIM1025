-- Engine battler-centre function from Gen1Recomp v0.3.43, regression fixture.
-- src/core/game3/battle/ui.lua
local function battler_sprite_center(side, species, base, form, ghost)
  if type(side) == "number" then
    local id = side
    side = (id % 2 == 0) and "player" or "enemy"
    local _, st = live_battler(id)
    base = base or (PicCoords and PicCoords.battlerCoords and PicCoords.battlerCoords(is_double(st), id))
    if is_double(st) and side == "player" and PicCoords and species then
      local sp = tonumber(species) or 0
      local yo = (PicCoords.back and PicCoords.back[sp]) or 0
      if sp == SPECIES_CASTFORM then yo = CASTFORM_BACK_Y[form or 0] or 0 end
      -- pokefirered/src/battle_anim_mons.c:252
      local y = math.min(base.y + yo + 8, 160 - 64 + 8)
      return base.x, y - 4
    end
  end
  local cx, cy = base.x, (side == "player") and (base.y - 4) or base.y
  if not PicCoords or not species then return cx, cy end
  local sp = tonumber(species) or 0
  if ghost == nil or (form == nil and sp == SPECIES_CASTFORM) then
    local b, st = live_battler(side)
    if ghost == nil then ghost = shows_ghost(side, st) end
    if form == nil and sp == SPECIES_CASTFORM then form = castform_form(side, b) end
  end
  if side == "player" then
    local yo = (PicCoords.back and PicCoords.back[sp]) or 0
    if sp == SPECIES_CASTFORM then yo = CASTFORM_BACK_Y[form or 0] or 0 end
    cy = base.y + yo + 4 -- shifted up 4px
  elseif ghost then
    -- pokefirered/src/battle_anim_mons.c:297
    cy = base.y
  else
    local yo = (PicCoords.front and PicCoords.front[sp]) or 0
    local elev = (PicCoords.elev and PicCoords.elev[sp]) or 0
    if sp == SPECIES_CASTFORM then
      yo = CASTFORM_FRONT_Y[form or 0] or yo
      elev = CASTFORM_ELEV[form or 0] or elev
    end
    cy = base.y + yo - elev
  end
  return cx, cy
end

return battler_sprite_center
