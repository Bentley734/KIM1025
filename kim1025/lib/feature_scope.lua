-- The four retained features use the original saved option identifiers.
-- Removed feature flags are read as disabled even on upgraded installations.
-- Geometry preferences remain available internally to preserve calibrated
-- iOS/desktop positioning without restoring dozens of settings rows.
return function(mod)
  local options = assert(mod.options)
  if options._kimFocusedScope then return options._kimFocusedScope end
  local original = options.get
  local disabled = {
    battleSprites=true, menuIcons=true, integratedModernUi=true,
    gen2IntegratedModernUi=true, gen3IntegratedModernUi=true,
    battleUiWip=true, battleUiWIP=true, titleScreen=true,
    gen3MenuUi=true, gen3PokemonUi=true, gen3DialogueUi=true,
    pokemonUi=true, menuUi=true, dialogueUi=true, managerUi=true,
  }
  local constants = {
    animate=true, spriteAnimation=true, gen2MenuSpriteSource="kim",
    battleShadowQuality="off", battleShadowOpacity="0",
    battleShinyOdds="native", battleSystem=true,
    battleHudColor="color", battleHudOpacity="100",
  }
  local function saved(key) return original(options, key) end
  options.get = function(self, key)
    if disabled[key] then return false end
    if constants[key] ~= nil then return constants[key] end
    if key == "enabled" then
      local value = saved("animatedPokedex")
      return value ~= false
    end
    return original(self, key)
  end
  options._kimFocusedScope = { disabled=disabled, constants=constants }
  return options._kimFocusedScope
end
