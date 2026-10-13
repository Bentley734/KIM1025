-- A fullscreen scene must resolve the active sprite provider each frame.
-- 1025Dex's battle.mon_pic hook shares its native animation clock and signals
-- pending sheets with false; sampling battler.sprite alone freezes that clock
-- when the scene skips the native drawPicsLayer wrapper.
return function(mod, shinyFor)
  local ok, Runtime = pcall(require, "src.mods.Runtime")
  local warned = false
  local api = {}
  function api.resolve(battle, side, image, trimPlayer)
    local battler = battle and battle[side]
    local mon = battler and battler.mon
    if not (ok and Runtime and type(Runtime.call) == "function"
        and type(Runtime.wantsHook) == "function" and Runtime.wantsHook("battle.mon_pic")
        and type(mon) == "table") then return nil, false end
    local ctx = {species=mon.species, side=side == "enemy" and "front" or "back",
      kind="battle", mon=mon, battler=battler, battle=battle,
      shiny=type(shinyFor) == "function" and shinyFor(mon) or nil}
    if trimPlayer then
      -- A bottom-anchored scene needs visible feet, not native-box padding
      -- or pack offsets. 1025Dex natural mode supplies this ground contract.
      ctx.natural, ctx.scale, ctx.maxH = true, 1, 56
    end
    -- A provider falling through to next() has not claimed this sprite.
    -- Passing the current image still supports providers that inspect it.
    local success, result = pcall(Runtime.call, "battle.mon_pic", function() return nil end,
      image or battler.sprite, ctx)
    if not success then
      if not warned and mod.log and type(mod.log.warn) == "function" then
        mod.log:warn("battle sprite provider failed: %s", tostring(result))
      end
      warned = true
      return nil, false
    end
    if result == false then return nil, true end -- preparing art; never show vanilla
    if result and type(result.getDimensions) == "function" then
      return result, true, ctx.spriteLayout
    end
    return nil, false
  end
  return api
end
