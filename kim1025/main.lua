-- Kanto in Motion
-- Animated Pokedex sprites, HD battle backgrounds, trainer choices and move animations.
-- GIF source packs are converted locally into optimized sprite sheets with
-- tools/import_hd_pokemon.py.
return function(mod)
  -- LuaJIT/Lua 5.1 compatibility. Some Gen1Recomp dev builds still expose
  -- the legacy global unpack() without table.unpack(). KIM uses both engine
  -- hooks and its own multi-return wrappers, so normalize the standard table
  -- helper before registering any battle hooks.
  if type(table) == "table" and type(table.unpack) ~= "function"
      and type(unpack) == "function" then
    table.unpack = unpack
  end
  local unpackCompat = (type(table) == "table" and table.unpack) or unpack

  do
    local source = assert(mod:read("lib/feature_scope.lua"))
    assert((loadstring or load)(source, "@" .. mod.path .. "/lib/feature_scope.lua"))()(mod)
  end

  -- Downloadable HD asset manager. The large Pokemon battle sprite sheets and
  -- HD battle backgrounds live in HaseoSora/Kanto-in-Motion-Assets and are
  -- cached by KIM after a one-time in-game download.
  local assetManager = nil
  do
    local source, err = mod:read("lib/asset_download_manager.lua")
    if source then
      local loader, compileErr = load(source, "@" .. tostring(mod.path) .. "/lib/asset_download_manager.lua")
      if loader then
        local okLoad, installer = pcall(loader)
        if okLoad and type(installer) == "function" then
          local okInstall, value = pcall(function()
            local hubSource = assert(mod:read("lib/asset_download_hub.lua"))
            local hubLoader = assert(load(hubSource, "@" .. tostring(mod.path) .. "/lib/asset_download_hub.lua"))
            return hubLoader()(mod, installer)
          end)
          if okInstall then
            assetManager = value
          elseif mod.log and mod.log.error then
            mod.log:error("KIM asset manager failed: %s", tostring(value))
          end
        elseif mod.log and mod.log.error then
          mod.log:error("KIM asset manager could not load: %s", tostring(installer))
        end
      elseif mod.log and mod.log.error then
        mod.log:error("KIM asset manager could not compile: %s", tostring(compileErr))
      end
    elseif mod.log and mod.log.error then
      mod.log:error("KIM asset manager missing: %s", tostring(err))
    end
    mod._kimAssetManager = assetManager
  end

  -- Central asset resolver used by Gen 1, Gen 2 and FR/LG. Downloaded heavy
  -- artwork is read from mod.cache; packaged files remain a development and
  -- migration fallback.
  do
    local MANAGED_PREFIXES = {
      "assets/battle/hd-pokemon/",
      "assets/battle/backgrounds/hd/",
      "assets/battle/backgrounds/aspect/",
    }
    local function isManaged(relative)
      if type(relative) ~= "string" then return false end
      relative = relative:gsub("\\", "/"):gsub("^%./", "")
      for _, prefix in ipairs(MANAGED_PREFIXES) do
        if relative:sub(1, #prefix) == prefix then return true end
      end
      return false
    end

    mod._kimAssetProvider = {
      isManagedAsset = isManaged,
    }

    function mod._kimAssetProvider.image(relative)
      if isManaged(relative) and assetManager and type(assetManager.image) == "function" then
        local ok, image = pcall(assetManager.image, assetManager, relative)
        if ok and image then return image, "downloaded" end
      end
      if mod.assets and type(mod.assets.image) == "function" then
        local ok, image = pcall(function() return mod.assets:image(relative) end)
        if ok and image then return image, "local" end
      end
      return nil
    end

    function mod._kimAssetProvider.exists(relative)
      if isManaged(relative) and assetManager and type(assetManager.exists) == "function" then
        local ok, exists = pcall(assetManager.exists, assetManager, relative)
        if ok and exists == true then return true, "downloaded" end
      end
      if type(mod.info) == "function" then
        local ok, info = pcall(function() return mod:info(relative) end)
        if ok and info ~= nil then return true, "local" end
      end
      return false
    end

    function mod._kimAssetProvider.read(relative)
      if isManaged(relative) and assetManager and type(assetManager.read) == "function" then
        local bytes = assetManager:read(relative)
        if type(bytes) == "string" and #bytes > 0 then return bytes, "downloaded" end
      end
      return mod:read(relative)
    end

    function mod._kimAssetProvider.path(relative)
      -- mod.cache deliberately has no physical path. Keep this helper for the
      -- small packaged assets and legacy callers; heavy art uses image().
      if mod.assets and type(mod.assets.path) == "function" then
        local ok, path = pcall(function() return mod.assets:path(relative) end)
        if ok and path then return path, "local" end
      end
      return nil
    end

    function mod._kimAssetProvider.revision()
      if assetManager and type(assetManager.sourceRevision) == "function" then
        local ok, rev = pcall(assetManager.sourceRevision, assetManager)
        if ok then return tonumber(rev) or 0 end
      end
      return 0
    end
  end
  assert((loadstring or load)(assert(mod:read('lib/dex_sprite_provider.lua'))))()(mod)
  -- Share grouped navigation across native and modern option presenters.
  do
    local chunk = assert((loadstring or load)(assert(mod:read("lib/settings_groups.lua")),
      "@" .. mod.path .. "/lib/settings_groups.lua"))
    chunk()(mod)
  end
  -- FireRed / LeafGreen run on Gen1Recomp's separate Game3 engine.  Keep the
  -- existing R/B/Y implementation isolated: Gen 3 gets its own provider and
  -- returns before any Gen 1 BattleState / Modern UI code is loaded.
  if tonumber(mod.generation) == 3 then
    local source, err = mod:read("lib/gen3_frlg.lua")
    if not source then
      if mod.log and mod.log.error then
        mod.log:error("cannot read FireRed/LeafGreen bridge: %s", tostring(err))
      end
      return
    end
    local loader, compileErr = load(source, "@" .. mod.path .. "/lib/gen3_frlg.lua")
    if not loader then
      if mod.log and mod.log.error then
        mod.log:error("cannot compile FireRed/LeafGreen bridge: %s", tostring(compileErr))
      end
      return
    end
    local ok, bridge = pcall(loader)
    if not ok or type(bridge) ~= "function" then
      if mod.log and mod.log.error then
        mod.log:error("cannot load FireRed/LeafGreen bridge: %s", tostring(bridge))
      end
      return
    end
    local okRun, runErr = pcall(bridge, mod)
    if not okRun and mod.log and mod.log.error then
      mod.log:error("FireRed/LeafGreen bridge failed: %s", tostring(runErr))
    end
    return
  end
  -- Red/Blue/Yellow and Gold/Silver/Crystal share KIM's long-standing
  -- animated-provider path. FireRed/LeafGreen already returned through the
  -- isolated Game3 bridge above.
  --
  -- IMPORTANT: Gen 2 must continue through this file. KIM's proven Gen 2
  -- Summary/Pokedex/Clean-UI bridges live below and are deliberately guarded
  -- by IS_GEN2. Returning early here disables all of that working support.
  local IS_GEN2 = tonumber(mod.generation) == 2
  local MOD_ID = "kim1025"

  -- Keep the live game handle explicitly. Some mobile Gen 2 builds do not
  -- expose it as mod.game, which previously made National-Dex lookup for
  -- #152-251 fail even though the downloaded atlas was present in mod.cache.
  mod._kantoInMotionActiveGame = mod._kantoInMotionActiveGame or nil
  if mod.events and type(mod.events.on) == "function" then
    mod.events:on("game.ready", function(ev)
      if ev and ev.game then mod._kantoInMotionActiveGame = ev.game end
    end)
  end

  -- Gen 1 mobile graphics-transaction guard. It never adds its own graphics
  -- state: it only remembers the caller's depth/canvas, runs the same function
  -- through pcall(), and removes states that the callee leaked before returning
  -- or throwing. Store helpers on mod instead of consuming outer locals because
  -- this long installer is already close to Lua's 200-local function limit.
  function mod._kantoInMotionNativeMobileGen1()
    if IS_GEN2 then return false end
    local system = love and love.system
    if not (system and type(system.getOS) == "function") then return false end
    local ok, host = pcall(system.getOS)
    return ok and (host == "Android" or host == "iOS")
  end

  function mod._kantoInMotionGraphicsDepth()
    local g = love and love.graphics
    if not (g and type(g.getStackDepth) == "function") then return nil end
    local ok, depth = pcall(g.getStackDepth)
    return ok and tonumber(depth) or nil
  end

  function mod._kantoInMotionRestoreGraphicsDepth(baseDepth)
    local g = love and love.graphics
    baseDepth = tonumber(baseDepth)
    if baseDepth == nil or not (g and type(g.getStackDepth) == "function"
        and type(g.pop) == "function") then return 0 end
    local repaired = 0
    for _ = 1, 256 do
      local ok, depth = pcall(g.getStackDepth)
      depth = ok and tonumber(depth) or nil
      if not depth or depth <= baseDepth then break end
      if not pcall(g.pop) then break end
      repaired = repaired + 1
    end
    return repaired
  end

  mod._kantoInMotionGen1GuardWarnings =
    mod._kantoInMotionGen1GuardWarnings or {}
  function mod._kantoInMotionGuardedMobileCall(label, fn, ...)
    if type(fn) ~= "function" then return false, "missing function" end
    if not mod._kantoInMotionNativeMobileGen1() then return pcall(fn, ...) end
    local g = love and love.graphics
    local baseDepth = mod._kantoInMotionGraphicsDepth()
    local entryCanvas = nil
    if g and type(g.getCanvas) == "function" then
      local okCanvas, canvas = pcall(g.getCanvas)
      if okCanvas then entryCanvas = canvas end
    end
    local result = { pcall(fn, ...) }
    if baseDepth ~= nil then mod._kantoInMotionRestoreGraphicsDepth(baseDepth) end
    if g and type(g.setCanvas) == "function" then
      if entryCanvas then pcall(g.setCanvas, entryCanvas) else pcall(g.setCanvas) end
    end
    local ok = table.remove(result, 1)
    if not ok and not mod._kantoInMotionGen1GuardWarnings[label] then
      mod._kantoInMotionGen1GuardWarnings[label] = true
      if mod.log and type(mod.log.warn) == "function" then
        mod.log:warn("Gen1 mobile %s failed safely: %s",
          tostring(label), tostring(result[1]))
      end
    end
    return ok, unpackCompat(result)
  end

  -- Open compatibility registry. Third-party UI and battle mods can register
  -- ownership without Kanto in Motion knowing their mod ID ahead of time.
  -- Registrations are advisory and fail-open: a missing/errored callback never
  -- causes KIM to blank another mod's presentation.
  mod.exports = mod.exports or {}
  mod._kantoInMotionInterop = {
    apiVersion = 1,
    uiOwners = {},
    battleOwners = {},
  }

  function mod._kantoInMotionInterop:ownerAlive(owner)
    if type(owner) ~= "string" or owner == "" or owner == MOD_ID then return false end
    if type(mod.find) ~= "function" then return true end
    local ok, handle = pcall(mod.find, owner)
    return ok and handle ~= nil
  end

  function mod._kantoInMotionInterop:registerUi(spec)
    if type(spec) ~= "table" then return false, "UI compatibility spec must be a table" end
    local owner = spec.owner or spec.modId or spec.sourceModId
    if type(owner) ~= "string" or owner == "" or owner == MOD_ID then
      return false, "UI compatibility owner must be the source mod id"
    end
    if spec.active ~= nil and type(spec.active) ~= "function" and type(spec.active) ~= "boolean" then
      return false, "UI compatibility active must be a function or boolean"
    end
    if spec.match ~= nil and type(spec.match) ~= "function" then
      return false, "UI compatibility match must be a function"
    end
    if spec.kinds ~= nil and type(spec.kinds) ~= "table" and type(spec.kinds) ~= "string" then
      return false, "UI compatibility kinds must be a table or string"
    end
    spec.owner = owner
    spec.priority = tonumber(spec.priority) or 0
    self.uiOwners[owner] = spec
    return true
  end

  function mod._kantoInMotionInterop:registerBattle()
    return false, "3D stage integration has been removed"
  end

  function mod._kantoInMotionInterop:unregister(owner)
    self.uiOwners[owner] = nil
    self.battleOwners[owner] = nil
    return true
  end

  function mod._kantoInMotionInterop:_active(spec, game, state, kind)
    if type(spec) ~= "table" then return false end
    if not self:ownerAlive(spec.owner) then return false end
    local probe = spec.match or spec.active
    if type(probe) == "function" then
      local ok, value = pcall(probe, game, state, kind)
      return ok and value == true
    end
    if type(probe) == "boolean" then return probe end
    return true
  end

  function mod._kantoInMotionInterop:_uiKindClaimed(spec, kind)
    local kinds = spec and spec.kinds
    if kinds == nil then return true end
    if type(kinds) == "string" then kinds = { [kinds] = true } end
    if type(kinds) ~= "table" then return false end
    local claimed = {}
    for key, value in pairs(kinds) do
      if type(key) == "number" then claimed[tostring(value):lower()] = true
      elseif value == true then claimed[tostring(key):lower()] = true end
    end
    local k = tostring(kind or ""):lower()
    if claimed.all or claimed["*"] or claimed[k] then return true end
    if claimed.battle and k == "battle" then return true end
    if claimed.dialogue and (k == "text" or k == "choice" or k == "quantity" or k == "save_panel") then
      return true
    end
    if claimed.pokemon and (k == "party" or k == "pokedex" or k == "summary"
        or k == "trainer_card" or k == "dex_entry" or k == "box_mon_list"
        or k == "box_root" or k == "gen3_box" or k == "evolution"
        or k == "levelup") then
      return true
    end
    if claimed.manager and (k == "mod_manager" or k == "mod_options") then return true end
    if claimed.title and (k == "title_continue" or k == "voxel_precache" or k == "voxel_cache_load") then
      return true
    end
    if claimed.menus and (k == "bag" or k == "options" or k == "move_learn"
        or k == "pic_box" or k == "naming" or k == "town_map"
        or k == "quarantine_report" or k == "rby_mmo_profile"
        or k == "rby_mmo_rank" or k == "rby_mmo_char_pick"
        or k == "shop_list" or k == "pc_list" or k == "list"
        or k == "menu" or k == "link") then
      return true
    end
    return false
  end

  function mod._kantoInMotionInterop:uiOwnerFor(game, state, kind)
    local best, bestPriority = nil, -math.huge
    for _, spec in pairs(self.uiOwners) do
      if self:_uiKindClaimed(spec, kind) and self:_active(spec, game, state, kind)
          and spec.priority >= bestPriority then
        best, bestPriority = spec, spec.priority
      end
    end
    return best
  end

  function mod._kantoInMotionInterop:battleOwnerFor(game, battle)
    local best, bestPriority = nil, -math.huge
    for _, spec in pairs(self.battleOwners) do
      if self:_active(spec, game, battle, "battle") and spec.priority >= bestPriority then
        best, bestPriority = spec, spec.priority
      end
    end
    return best
  end

  function mod._kantoInMotionInterop:hasBattleSceneOwner(game, battle)
    for _, spec in pairs(self.battleOwners) do
      if spec.sceneOwner ~= false and self:ownerAlive(spec.owner)
          and self:_active(spec, game, battle, "battle") then
        return true
      end
    end
    return false
  end

  function mod._kantoInMotionInterop:blocksBattleFeature(feature, game, battle)
    local optIn = feature == "sprites" and "allowKIMSprites"
      or feature == "animations" and "allowKIMAnimations" or nil
    for _, spec in pairs(self.battleOwners) do
      if spec.sceneOwner ~= false and self:ownerAlive(spec.owner)
          and self:_active(spec, game, battle, "battle")
          and (not optIn or spec[optIn] ~= true) then
        return true
      end
    end
    return false
  end

  function mod._kantoInMotionInterop:hasPokemonSpriteBridgeUi()
    for _, spec in pairs(self.uiOwners) do
      if spec.pokemonSpriteBridge == true and self:ownerAlive(spec.owner) then
        return true
      end
    end
    return false
  end

  mod.exports.kantoInMotionCompatibility = {
    apiVersion = 1,
    registerUiOwner = function(spec) return mod._kantoInMotionInterop:registerUi(spec) end,
    -- Old external integrations cannot re-enable staged model ownership.
    registerBattleOwner = function() return false end,
    unregisterOwner = function(owner) return mod._kantoInMotionInterop:unregister(owner) end,
    modes = { "native", "lower", "full" },
  }
  -- Convenience aliases for small mods that do not need the namespaced table.
  mod.exports.registerUiCompatibility = mod.exports.kantoInMotionCompatibility.registerUiOwner
  mod.exports.registerBattleCompatibility = mod.exports.kantoInMotionCompatibility.registerBattleOwner
  local HD_SPRITE_DATA_FILE = "data/hd_pokemon_sprites.lua"


  -- Only the requested features are public options. Old saved feature flags
  -- cannot re-enable removed presenters; alignment values remain readable.
  local optionSchema = {
    { key = "animatedPokedex", label = "ANIMATED POKEDEX", type = "toggle", default = true },
  }
  local gen2UiOptionSchema = {}
  local battleOptionSchema = {}
  if not IS_GEN2 then
    battleOptionSchema = {
      { key = "hdBattleBackgrounds", label = "HD BATTLE BACKGROUNDS", type = "toggle", default = true },
    { key = "battleTrainerSprite", label = "PLAYER TRAINER", type = "choice",
      default = "red", choices = {
        { "RED", "red" },
        { "DEFAULT / ROM", "rom" },
        { "GEN 1", "gen1" }, { "GEN 2", "gen2" },
        { "GEN 3", "gen3" }, { "GEN 4", "gen4" },
        { "GEN 5", "gen5" }, { "ASH", "ash" },
        { "GARY", "gary" },
        { "ASH FRONT", "ash_front" }, { "MISTY FRONT", "misty_front" },
        { "BROCK FRONT", "brock_front" }, { "BULMA FRONT", "bulma_front" },
        { "GARY FRONT", "gary_front" },
      }, description = "Choose the player trainer shown during the battle intro/send-out. RED (redplayer.png) is the default. ANIMATION ON plays the supplied five-frame trainer atlas; ANIMATION OFF holds frame 1. Cooperative scenes such as PotatoVoxel use this same KIM selection. DEFAULT / ROM yields to the game or another trainer provider." },
      { key = "desktopTrainerSizeV2", label = "TRAINER SIZE", type = "choice", default = "100", choices = { { "50%", "50" }, { "60%", "60" }, { "70%", "70" }, { "80%", "80" }, { "90%", "90" }, { "100%", "100" }, { "110%", "110" }, { "120%", "120" }, { "130%", "130" }, { "140%", "140" }, { "150%", "150" }, { "160%", "160" }, { "170%", "170" }, { "180%", "180" }, { "190%", "190" }, { "200%", "200" } }, description = "Desktop trainer size percentage. Fits window width and height, with a cap that keeps the visible trainer on-screen." },
      { key = "desktopPlayerSizeV2", label = "PLAYER POKEMON SIZE", type = "choice", default = "100", choices = { { "AUTO", "auto" }, { "50%", "50" }, { "60%", "60" }, { "70%", "70" }, { "80%", "80" }, { "90%", "90" }, { "100%", "100" }, { "110%", "110" }, { "120%", "120" }, { "130%", "130" }, { "140%", "140" }, { "150%", "150" }, { "160%", "160" }, { "170%", "170" }, { "180%", "180" }, { "190%", "190" }, { "200%", "200" } }, description = "AUTO fills the available space above the mound and below enemy name/HP, using visible sprite bounds. Percentages retain manual size. Desktop HD battles only." },
      { key = "desktopEnemySize", label = "ENEMY POKEMON SIZE", type = "choice", default = "100", choices = { { "50%", "50" }, { "60%", "60" }, { "70%", "70" }, { "80%", "80" }, { "90%", "90" }, { "100%", "100" }, { "110%", "110" }, { "120%", "120" }, { "130%", "130" }, { "140%", "140" }, { "150%", "150" }, { "160%", "160" }, { "170%", "170" }, { "180%", "180" }, { "190%", "190" }, { "200%", "200" } }, description = "Desktop battle size percentage. Changes size while retaining the current anchor." },
      { key = "battleAnimations", label = "MOVE ANIMATIONS", type = "toggle", default = true },
    }
  end
  local combinedKantoOptionSchema = {}
  for _, row in ipairs(optionSchema) do combinedKantoOptionSchema[#combinedKantoOptionSchema+1] = row end
  for _, row in ipairs(battleOptionSchema) do combinedKantoOptionSchema[#combinedKantoOptionSchema+1] = row end
  mod._kantoInMotionOptionSchema = combinedKantoOptionSchema
  mod.options:define(combinedKantoOptionSchema)
  local function integratedModernUiEnabled() return false end

  local hdSprites = {}
  local imageCache = {}
  local frameCache = {}
  local renderCache = {}

  local function loadTable(relative, quiet)
    local source, err = mod:read(relative)
    if not source then
      if not quiet then mod.log:error("cannot read %s: %s", relative, tostring(err)) end
      return {}
    end
    local chunk, compileErr = load(source, "@" .. mod.path .. "/" .. relative)
    if not chunk then
      mod.log:error("cannot compile %s: %s", relative, tostring(compileErr))
      return {}
    end
    local ok, data = pcall(chunk)
    if not ok or type(data) ~= "table" then
      mod.log:error("cannot load %s: %s", relative, tostring(data))
      return {}
    end
    return data
  end

  -- HD sprite sheets/metadata are generated locally from the supplied GIFs by
  -- tools/import_hd_pokemon.py. Missing local assets are safe: KIM falls back
  -- to the game's native sprite for that surface.
  hdSprites = loadTable(HD_SPRITE_DATA_FILE, true)
  local nationalHdSprites = loadTable("data/hd_pokemon_national.lua", true)
  mod._kimHdUnownForms = IS_GEN2 and loadTable("data/hd_unown_forms.lua", true) or {}

  local function selectedGeneration()
    return "hd"
  end

  local SPECIES_KEY_ALIASES = {
    FARFETCH_D = "FARFETCHD",
    MR__MIME = "MR_MIME",
    MRMIME = "MR_MIME",
  }

  local function normalizedSpecies(species)
    if type(species) ~= "string" then return nil end
    local key = species:upper():gsub("[^A-Z0-9_]", "")
    return SPECIES_KEY_ALIASES[key] or key
  end

  local function monGender(mon)
    if type(mon) ~= "table" then return nil end
    local value = mon.gender
    if type(value) == "function" then
      local ok, resolved = pcall(value, mon)
      if ok then value = resolved end
    end
    if value == nil then value = mon.sex end
    if type(value) == "string" then
      local key = value:upper():gsub("[^A-Z]", "")
      if key == "F" or key == "FEMALE" or key == "GIRL" then return "female" end
      if key == "M" or key == "MALE" or key == "BOY" then return "male" end
    elseif type(value) == "number" then
      if value == 1 then return "female" end
      if value == 0 then return "male" end
    end
    return nil
  end

  local function chooseHdVariant(variants, mon)
    if type(variants) ~= "table" then return nil end
    local gender = monGender(mon)
    if gender and type(variants[gender]) == "table" then return variants[gender] end
    return type(variants.default) == "table" and variants.default
      or type(variants.male) == "table" and variants.male
      or type(variants.female) == "table" and variants.female
      or nil
  end

  local function gen2NationalDex(species, normalized)
    if not IS_GEN2 then return nil end

    -- Gen 2's numeric species ids already follow the National-Dex range.
    -- Take that fast path first so battle/menu objects do not depend on a
    -- game handle merely to resolve #152-251.
    local numeric = tonumber(species)
    if numeric and numeric >= 1 and numeric <= 251 then
      return math.floor(numeric)
    end

    local game = mod._kantoInMotionActiveGame or mod.game
    if not game and mod._kimAssetManager then game = mod._kimAssetManager.game end
    local pokemon = game and game.data and game.data.pokemon
    if type(pokemon) ~= "table" then return nil end

    local def = pokemon[species]
    if type(def) ~= "table" and normalized then
      def = pokemon[normalized]
    end
    local dex = type(def) == "table"
      and tonumber(def.dex or def.index or def.nationalDex) or nil
    if dex and dex >= 1 and dex <= 251 then return math.floor(dex) end
    return nil
  end

  -- Crystal Unown is one species (#201) with 26 letter forms. The game
  -- remains authoritative for the form; KIM maps that form to matching HD art.
  mod._kimUnownCompat = mod._kimUnownCompat or {}
  if IS_GEN2 then
    local okUnown, value = pcall(require, "src.core.gen2.Unown")
    if okUnown and type(value) == "table" then mod._kimUnownCompat.engine = value end
  end
  mod._kimUnownCompat.index = function(value)
    if type(value) == "number" then
      value = math.floor(value)
      if value >= 1 and value <= 26 then return value end
      return nil
    end
    if type(value) ~= "string" then return nil end
    if #value == 1 then
      local at = ("ABCDEFGHIJKLMNOPQRSTUVWXYZ"):find(value:upper(), 1, true)
      if at then return at end
    end
    local numeric = tonumber(value)
    if numeric then return mod._kimUnownCompat.index(numeric) end
    return nil
  end
  mod._kimUnownCompat.isSpecies = function(species, normalized)
    if not IS_GEN2 then return false end
    local numeric = tonumber(species)
    if numeric and math.floor(numeric) == 201 then return true end
    normalized = normalized or normalizedSpecies(species)
    return normalized == "UNOWN"
  end
  mod._kimUnownCompat.letterForMon = function(mon)
    if type(mon) ~= "table" then return nil end
    local engine = mod._kimUnownCompat.engine
    if engine and type(engine.monLetter) == "function" then
      local ok, letter = pcall(engine.monLetter, mon)
      if ok then
        letter = mod._kimUnownCompat.index(letter)
        if letter then return letter end
      end
    end
    local stored = mod._kimUnownCompat.index(mon.unownLetter or mon.form or mon.letter)
    if stored then return stored end
    local dvs = mon.dvs
    if type(dvs) ~= "table" then return nil end
    local function middleBits(dv) return math.floor((tonumber(dv) or 0) / 2) % 4 end
    local packed = middleBits(dvs.attack) * 64 + middleBits(dvs.defense) * 16
      + middleBits(dvs.speed) * 4 + middleBits(dvs.special)
    return math.floor(packed / 10) + 1
  end

  local function hdRecord(species, side, color, mon, form)
    local originalSpecies = species
    local normalized = normalizedSpecies(species)
    local cacheSpecies = normalized
    local entry = normalized and hdSprites and hdSprites[normalized]

    if IS_GEN2 and mod._kimUnownCompat.isSpecies(originalSpecies, normalized) then
      local letter = mod._kimUnownCompat.index(form) or mod._kimUnownCompat.letterForMon(mon) or 1
      if letter == 1 then
        entry = nationalHdSprites and nationalHdSprites[201] or entry
      else
        entry = mod._kimHdUnownForms and mod._kimHdUnownForms[letter] or nil
      end
      cacheSpecies = "UNOWN_" .. tostring(letter)
    elseif type(entry) ~= "table" and IS_GEN2 then
      -- Gen 2's HD import is National-Dex keyed for #152-251.
      local dex = gen2NationalDex(originalSpecies, normalized)
      local national = dex and nationalHdSprites and nationalHdSprites[dex]
      if type(national) == "table" then entry = national end
    end

    local sideData = type(entry) == "table" and entry[side] or nil
    local variants = type(sideData) == "table" and sideData[color] or nil
    local record = chooseHdVariant(variants, mon)
    if type(record) ~= "table" or type(record.image) ~= "string" then return nil end
    return record, "hd", cacheSpecies
  end

  local function localFrontRecord(species, generation, mon, form)
    return hdRecord(species, "front", "normal", mon, form)
  end

  local function localShinyFrontRecord(species, generation, mon, form)
    return hdRecord(species, "front", "shiny", mon, form)
  end

  local function localBackRecord(species, generation, mon, form)
    return hdRecord(species, "back", "normal", mon, form)
  end

  local function localShinyBackRecord(species, generation, mon, form)
    return hdRecord(species, "back", "shiny", mon, form)
  end

  local function presentationSize(generation, species, side, fallback)
    fallback = fallback or {}
    return math.max(1, math.floor(tonumber(fallback.width) or 1)),
      math.max(1, math.floor(tonumber(fallback.height) or 1))
  end

  local function battleFrontGeneration() return "hd" end
  local function battleBackGeneration() return "hd" end

  -- Gen 1 already stores the four DVs used by the canonical Gen 2 shiny
  -- rule. Keep an explicit mon.shiny flag as a compatibility fast path for
  -- a compatibility fast path for engines/mods that publish it directly.
  local SHINY_ATTACK = {
    [2] = true, [3] = true, [6] = true, [7] = true,
    [10] = true, [11] = true, [14] = true, [15] = true,
  }
  local function isBattleShiny(mon)
    if type(mon) ~= "table" then return false end
    if mon.shiny == true then return true end
    local dvs = mon.dvs
    if type(dvs) ~= "table" then return false end
    local attack = tonumber(dvs.attack)
    local defense = tonumber(dvs.defense)
    local speed = tonumber(dvs.speed)
    local special = tonumber(dvs.special)
    if defense ~= 10 or speed ~= 10 or special ~= 10
        or SHINY_ATTACK[attack] ~= true then
      return false
    end
    -- Preserve the derived HP DV when a mod stores it explicitly.
    local hp = (attack % 2) * 8 + (defense % 2) * 4
      + (speed % 2) * 2 + (special % 2)
    return dvs.hp == nil or tonumber(dvs.hp) == hp
  end

  local function battleRecord(species, side, mon)
    if mod._kimDexSelected and not mod._kimDexSelected(side,true)then return nil end
    if IS_GEN2 then
      -- Gen 2 menu artwork and battle artwork are independent choices.
      -- MENU SPRITES may be VANILLA while BATTLE SPRITES stays ON.
      if mod.options:get("battleSprites") == false then return nil end
    elseif mod.options:get("battleSprites") == false then
      return nil
    end
    if side == "back" then
      local generation = battleBackGeneration()
      if isBattleShiny(mon) then
        local shiny, actual, normalized = localShinyBackRecord(species, generation, mon)
        if shiny then return shiny, actual, normalized, true end
      end
      local back, actual, normalized = localBackRecord(species, generation, mon)
      if back then return back, actual, normalized, false end
      return nil
    end
    local generation = battleFrontGeneration()
    if isBattleShiny(mon) then
      local shiny, actual, normalized = localShinyFrontRecord(species, generation, mon)
      if shiny then return shiny, actual, normalized, true end
    end
    local front, actual, normalized = localFrontRecord(species, generation, mon)
    if front then return front, actual, normalized, false end
    return nil
  end

  do
    local source = assert(mod:read("lib/gen1_battle_pic_provider.lua"))
    mod._kimBattlePicProvider = assert((loadstring or load)(source,
      "@" .. mod.path .. "/lib/gen1_battle_pic_provider.lua"))()(mod, isBattleShiny)
  end

  local function shinyGroundOffset(generation, side, species, shiny)
    return 0
  end

  local function localHasSprite(species, generation)
    return localFrontRecord(species, generation) ~= nil
  end

  local imageMissRevision = {}
  local function assetProviderRevision()
    if mod._kimAssetProvider and type(mod._kimAssetProvider.revision) == "function" then
      local ok, value = pcall(mod._kimAssetProvider.revision)
      if ok then return tonumber(value) or 0 end
    end
    return 0
  end
  local function atlasImage(path)
    local revision = assetProviderRevision()
    if imageCache[path] == false then
      if imageMissRevision[path] == revision then return nil end
      imageCache[path] = nil
    end
    if imageCache[path] then return imageCache[path] end

    local image
    if mod._kimAssetProvider and type(mod._kimAssetProvider.image) == "function" then
      local ok, value = pcall(function() return mod._kimAssetProvider.image(path) end)
      if ok then image = value end
    end
    -- Test/recovery supplements can live inside the mod package.  The
    -- persistent external provider still wins whenever it owns the path.
    if not image and mod.assets and type(mod.assets.image) == "function" then
      local ok, value = pcall(mod.assets.image, mod.assets, path)
      if not ok then ok, value = pcall(mod.assets.image, path) end
      if ok then image = value end
    end
    if not image then
      imageCache[path] = false
      imageMissRevision[path] = revision
      return nil
    end
    if image.setFilter then pcall(image.setFilter, image, "nearest", "nearest") end
    imageCache[path] = image
    imageMissRevision[path] = nil
    return image
  end

  local function timingFor(front)
    local hit = frameCache[front]
    if hit then return hit end
    local frames = math.max(1, math.floor(tonumber(front.frames) or 1))
    local durations = type(front.durations) == "table" and front.durations or {}
    local cumulative, total = {}, 0
    for i = 1, frames do
      local d = tonumber(durations[i]) or 100
      if d < 1 then d = 1 end
      total = total + d
      cumulative[i] = total
    end
    hit = { frames = frames, cumulative = cumulative, total = math.max(total, 1) }
    frameCache[front] = hit
    return hit
  end

  local function currentFrame(front)
    local timing = timingFor(front)
    if not mod.options:get("animate") or timing.frames <= 1 then return 1 end
    local now = love.timer and love.timer.getTime and love.timer.getTime() or 0
    local t = (now * 1000) % timing.total
    for i = 1, timing.frames do
      if t < timing.cumulative[i] then return i end
    end
    return timing.frames
  end

  local function cacheEntry(front, generation, species)
    local width = math.max(1, math.floor(tonumber(front.width) or 1))
    local height = math.max(1, math.floor(tonumber(front.height) or 1))
    local columns = math.max(1, math.floor(tonumber(front.columns) or 1))
    local frames = math.max(1, math.floor(tonumber(front.frames) or 1))
    local key = table.concat({ generation, species, tostring(front.image or ""),
      tostring(width), tostring(height), tostring(columns), tostring(frames) }, ":")
    local hit = renderCache[key]
    if hit == false then return nil end
    if hit then return hit end
    local atlas = atlasImage(front.image)
    if not atlas or not love.graphics or not love.graphics.newCanvas
        or not love.graphics.newQuad then return nil end

    -- Validate every imported atlas, regardless of selected generation or
    -- color variant, before creating quads. Gen 2/3/5 alternate-color atlases
    -- are not guaranteed to share the normal sprite's frame grid. If metadata
    -- and PNG dimensions disagree, fail closed and let the caller fall back to
    -- the normal animated sprite (or the stock Gen1 title sprite) instead of
    -- displaying a quartered/cropped frame.
    local iw, ih = atlas:getDimensions()
    local expectedW = columns * width
    local expectedH = math.ceil(frames / columns) * height
    if iw ~= expectedW or ih ~= expectedH then
      renderCache[key] = false
      if mod.log and type(mod.log.warn) == "function" then
        mod.log:warn("ignoring incompatible animated atlas %s (%dx%d; expected %dx%d)",
          tostring(front.image), iw, ih, expectedW, expectedH)
      end
      return nil
    end

    local okCanvas, canvas = pcall(love.graphics.newCanvas, width, height)
    if not okCanvas or not canvas then return nil end
    if canvas.setFilter then pcall(canvas.setFilter, canvas, "nearest", "nearest") end
    hit = {
      atlas = atlas, canvas = canvas, width = width, height = height,
      columns = columns, imageWidth = iw, imageHeight = ih,
      quads = {}, stableFrames = {}, lastFrame = 0,
    }
    renderCache[key] = hit
    return hit
  end

  local function quadFor(entry, frame)
    local q = entry.quads[frame]
    if q then return q end
    local index = frame - 1
    local col = index % entry.columns
    local row = math.floor(index / entry.columns)
    local ok, quad = pcall(love.graphics.newQuad,
      col * entry.width, row * entry.height,
      entry.width, entry.height, entry.imageWidth, entry.imageHeight)
    if not ok then return nil end
    entry.quads[frame] = quad
    return quad
  end

  local function renderFrame(front, generation, species, forcedFrame)
    local entry = cacheEntry(front, generation, species)
    if not entry then return nil end
    local frame = tonumber(forcedFrame) or currentFrame(front)
    local frameCount = math.max(1, math.floor(tonumber(front.frames) or 1))
    frame = math.max(1, math.min(math.floor(frame), frameCount))
    if entry.lastFrame == frame then return entry.canvas end
    local quad = quadFor(entry, frame)
    if not quad then return nil end

    local previousCanvas = love.graphics.getCanvas and love.graphics.getCanvas() or nil
    love.graphics.push("all")
    love.graphics.setCanvas(entry.canvas)
    love.graphics.origin()
    -- Gen1Recomp 0.2.56 can leave a battle/UI scissor active at the end of
    -- the desktop frame. KIM renders animation cells from BattleState:update,
    -- so inheriting that scissor here clips BOTH the transparent clear and the
    -- atlas draw before any downstream consumer sees the frame. Reset all draw state
    -- that can affect this private sprite canvas; push/pop restores the host
    -- state immediately afterwards.
    love.graphics.setScissor()
    love.graphics.setShader()
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.draw(entry.atlas, quad, 0, 0)
    if previousCanvas then love.graphics.setCanvas(previousCanvas) else love.graphics.setCanvas() end
    love.graphics.pop()
    entry.lastFrame = frame
    return entry.canvas
  end

  -- Render a frame into a frame-specific Canvas. Unlike renderFrame(), this
  -- object never changes after creation. Third-party UI overhauls commonly
  -- cache resolved images and/or preprocess alpha bounds by image identity; a
  -- stable object per animation frame lets those caches coexist with animation
  -- instead of freezing on the first frame or reusing stale prepared pixels.
  local function renderStableFrame(front, generation, species, forcedFrame)
    local entry = cacheEntry(front, generation, species)
    if not entry then return nil end
    local frame = tonumber(forcedFrame) or currentFrame(front)
    local frameCount = math.max(1, math.floor(tonumber(front.frames) or 1))
    frame = math.max(1, math.min(math.floor(frame), frameCount))
    local cached = entry.stableFrames and entry.stableFrames[frame]
    if cached then return cached end
    local quad = quadFor(entry, frame)
    if not quad then return nil end
    local okCanvas, canvas = pcall(love.graphics.newCanvas, entry.width, entry.height)
    if not okCanvas or not canvas then return nil end
    if canvas.setFilter then pcall(canvas.setFilter, canvas, "nearest", "nearest") end
    local previousCanvas = love.graphics.getCanvas and love.graphics.getCanvas() or nil
    love.graphics.push("all")
    love.graphics.setCanvas(canvas)
    love.graphics.origin()
    -- Stable cached frames must be built from the whole atlas cell, not
    -- from whatever clip rectangle the previous desktop pass happened to
    -- leave active. Clear the scissor at the private atlas-render step,
    -- so clearing the scissor there (the v12 experiment) was too late.
    love.graphics.setScissor()
    love.graphics.setShader()
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.draw(entry.atlas, quad, 0, 0)
    if previousCanvas then love.graphics.setCanvas(previousCanvas) else love.graphics.setCanvas() end
    love.graphics.pop()
    entry.stableFrames = entry.stableFrames or {}
    entry.stableFrames[frame] = canvas
    return canvas
  end

  local function menuSpritesEnabled()
    if mod._kimDexSelected and not mod._kimDexSelected('front',false)then return false end
    if IS_GEN2 then
      return tostring(mod.options:get("gen2MenuSpriteSource") or "kim") == "kim"
    end
    return mod.options:get("enabled") ~= false
  end

  -- HD sheets are already authored at their intended presentation size, so
  -- no cross-generation normalization or resampling is required.
  local function renderPresentationFrame(front, generation, species, forcedFrame,
      side, variant, stable)
    if stable then return renderStableFrame(front, generation, species, forcedFrame) end
    return renderFrame(front, generation, species, forcedFrame)
  end

  local function getSprite(species, opts)
    local kind = opts and opts.kind
    if kind ~= "dex" and kind ~= "pokedex" and kind ~= "unown-dex" then return nil end
    if not menuSpritesEnabled() then return nil end
    local generation = opts and opts.generation or selectedGeneration()
    local mon = opts and opts.mon
    local form = opts and (opts.form or opts.letter)
    local forcedFrame = nil
    -- Gen 2's SPRITE ANIMATION setting is presentation-only: it freezes KIM
    -- menu/Pokedex/party artwork on frame 1 without changing battle animation.
    if IS_GEN2 and mod.options:get("spriteAnimation") == false then forcedFrame = 1 end
    if isBattleShiny(mon) then
      local shiny, actualGeneration, normalized = localShinyFrontRecord(species, generation, mon, form)
      if shiny then
        return renderPresentationFrame(shiny, actualGeneration, normalized,
          forcedFrame, "front", "shiny", false)
      end
    end
    local front, actualGeneration, normalized = localFrontRecord(species, generation, mon, form)
    if not front then return nil end
    return renderPresentationFrame(front, actualGeneration, normalized,
      forcedFrame, "front", "normal", false)
  end

  if IS_GEN2 then
    mod.exports.getGen2UnownSprite = function(letter, opts)
      opts = opts or {}
      return getSprite(201, {
        generation = "hd",
        kind = opts.kind or "unown-dex",
        form = letter,
        mon = opts.mon,
      })
    end
  end

  -- Title-only alternate-color lookup uses the same HD metadata as battles.
  local function getTitleShinySprite(species, generation)
    if not menuSpritesEnabled() then return nil end
    local shinyFront, actualGeneration, normalized = localShinyFrontRecord(species, "hd")
    if not shinyFront then return nil end
    return renderPresentationFrame(shinyFront, actualGeneration, normalized,
      nil, "front", "shiny", false)
  end

  local function getFrontRecord(species, generation)
    generation = generation or selectedGeneration()
    local front = localFrontRecord(species, generation)
    if not front then return nil end
    local width, height = presentationSize(generation, species, "front", front)
    return {
      width = width, height = height, columns = front.columns,
      frames = front.frames, durations = front.durations,
    }
  end

  -- Public export consumed by compatible UI mods such as Gen1 Modern UI.
  -- Kanto in Motion is the provider here; it does not depend on another mod.
  -- Preserve the early compatibility registration exports while adding the
  -- long-standing animated-sprite provider API.
  mod.exports.apiVersion = 1
  mod.exports.generations = { "hd" }
  mod.exports.defaultGeneration = "hd"
  mod.exports.getGeneration = selectedGeneration
  mod.exports.getSourcePreference = function() return "local" end
  mod.exports.getActiveSource = function(species, generation)
    return localHasSprite(species, generation or selectedGeneration()) and "local" or "vanilla"
  end
  mod.exports.hasSprite = function(species, generation)
    return localHasSprite(species, generation or selectedGeneration())
  end
  mod.exports.getSprite = getSprite
  mod.exports.getFrontRecord = getFrontRecord

  -- The stock Gen 1 Summary and Pokedex layouts reserve roughly a 7x7-tile
  -- portrait box. Imported Gen 2-5 animation frames are tightly cropped and
  -- some (Charizard is a common example) are substantially larger than that.
  -- Downscale only frames that exceed the native box; smaller sprites retain
  -- their authored pixel size. The scratch Canvas is redrawn every call so a
  -- live animated source Canvas stays animated instead of freezing.
  local stockPortraitCache = setmetatable({}, { __mode = "k" })
  local function fitStockPortrait(image, maxW, maxH)
    if not image or type(image.getDimensions) ~= "function" then return image end
    maxW, maxH = tonumber(maxW) or 56, tonumber(maxH) or 56
    local w, h = image:getDimensions()
    if not w or not h or w <= 0 or h <= 0 then return image end
    if w <= maxW and h <= maxH then return image end
    if not (love.graphics and love.graphics.newCanvas) then return image end

    local slot = stockPortraitCache[image]
    if not slot or slot.w ~= maxW or slot.h ~= maxH then
      local okCanvas, canvas = pcall(love.graphics.newCanvas, maxW, maxH)
      if not okCanvas or not canvas then return image end
      if canvas.setFilter then pcall(canvas.setFilter, canvas, "nearest", "nearest") end
      slot = { canvas = canvas, w = maxW, h = maxH }
      stockPortraitCache[image] = slot
    end

    local scale = math.min(maxW / w, maxH / h, 1)
    local dw, dh = w * scale, h * scale
    local dx, dy = (maxW - dw) * 0.5, maxH - dh
    local previousCanvas = love.graphics.getCanvas and love.graphics.getCanvas() or nil
    love.graphics.push("all")
    love.graphics.setCanvas(slot.canvas)
    love.graphics.origin()
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setShader()
    love.graphics.setColor(1, 1, 1, 1)
    if image.setFilter then pcall(image.setFilter, image, "nearest", "nearest") end
    love.graphics.draw(image, dx, dy, 0, scale, scale)
    if previousCanvas then love.graphics.setCanvas(previousCanvas) else love.graphics.setCanvas() end
    love.graphics.pop()
    return slot.canvas
  end

  -- Battle Lite live sprite bridge. The path is constant for a species/side,
  -- Gen 1 uses immutable frame images; Gen 2 keeps a mutable Canvas refreshed
  -- from the selected animation frame. Gen 2's BattleState loads through
  -- Assets.image(), so it can cache this Canvas directly. Gen 1 loads battle
  -- art through ImageData and would freeze it; the narrow drawPicsLayer wrapper
  -- below swaps the Canvas in only for the source draw and restores the native
  -- battler immediately afterward.
  local BATTLE_BRIDGE_PREFIX = "__kanto_in_motion_battle__/"
  local battleProxyCache = {}
  -- PotatoVoxel BACK SPRITES leaves the player on Gen1Recomp's flat pic
  -- layer. Its picImage wrapper caches processed images by object identity, so
  -- the normal mutable 48x48 KIM proxy can freeze/corrupt an animated frame.
  -- Keep one immutable, frame-specific pinned drawable instead.
  mod._kantoInMotionPotatoPinnedBackCache = {}
  mod._kantoInMotionPotatoPinnedBackScaleActive = false
  -- Separate from the pinned Pokemon scale seam. A selected KIM trainer
  -- is authored as an 80x80 native-logical image and must be drawn at 1x
  -- while PotatoVoxel BACK SPRITES keeps it in Gen1Recomp's flat back slot.
  mod._kantoInMotionPotatoPinnedTrainerScaleActive = false
  -- Generic selected KIM battle-trainer raw-frame draw. This is separate
  -- from Potato's pinned path because mobile needs different logical scales:
  -- normal KIM trainer = 65%, Potato pinned trainer = 85%.
  mod._kantoInMotionKimTrainerScaleActive = false

  local function battleSystemEnabled()
    return not IS_GEN2 and mod.options:get("battleSystem") ~= false
  end

  -- KIM no longer integrates with 3D battle stages.
  local function battleArt3DBattleEnabled() return false end
  -- Generic feature-level handoff for cooperating external battle renderers.
  -- KIM contains no legacy staged-battle asset packs, code, or runtime
  -- detection. External renderers can opt in through the public compatibility
  -- registry and independently decide whether KIM may supply animated Pokemon.
  local function externalBattleSceneOwnerRegistered(game,battle)
    return mod._kantoInMotionInterop
      and mod._kantoInMotionInterop:hasBattleSceneOwner(game,battle) or false
  end

  local function externalBattleSpritesBlocked(game,battle)
    return mod._kantoInMotionInterop
      and mod._kantoInMotionInterop:blocksBattleFeature("sprites",game,battle) or false
  end

  local function battleLiteOwnsSprites()
    if IS_GEN2 then
      -- Gen 2 keeps the native G/S/C battle system. KIM supplies only the
      -- Pokemon image through Gen1Recomp's existing pokemon.sprite seam.
      return mod.options:get("battleSprites") ~= false
    end
    return mod.options:get("battleSprites") ~= false
      and not externalBattleSpritesBlocked()
  end

  -- Full-screen KIM presentation is used only when the new HD background
  -- system is enabled. Turning HD BATTLE BACKGROUNDS OFF leaves the animated
  -- Pokemon/HUD bridge available while yielding arena art to the game or a
  -- cooperating scene owner.
  local function hdBattleBackgroundsEnabled()
    return not IS_GEN2 and mod.options:get("hdBattleBackgrounds") ~= false
  end

  local function battleLiteFullScreenActive()
    return battleSystemEnabled() and hdBattleBackgroundsEnabled()
      and not externalBattleSceneOwnerRegistered()
  end

  -- Background framing is independent from battle-system ownership. AUTO keeps
  -- KIM's established edge-to-edge stage while HD sprites are enabled, but
  -- automatically switches the scenery to the native Gen 1 battler geometry
  -- when BATTLE SPRITES is OFF so vanilla/default sprites still stand on the
  -- authored ground points.
  local function battleBackgroundMode()
    local mode = tostring(mod.options:get("battleBgMode") or "auto"):lower()
    if mode ~= "fullscreen" and mode ~= "native" then
      -- Portrait AUTO keeps the width-contained arena independent of which
      -- sprite provider is enabled. Explicit NATIVE FIT still wins above.
      if type(mod._kantoInMotionPortraitBattleFraming) == "function"
          and mod._kantoInMotionPortraitBattleFraming() then
        return "fullscreen"
      end
      return mod.options:get("battleSprites") == false and "native" or "fullscreen"
    end
    return mode
  end

  local function battleLiteDirectStageActive()
    return battleLiteFullScreenActive() and battleBackgroundMode() == "fullscreen"
  end

  local function battleLiteHudActive()
    local externalKimHud = type(mod._kantoInMotionExternalStageUsesKimHud) == "function"
      and mod._kantoInMotionExternalStageUsesKimHud() == true
    local mobileBattleArtStageOnly =
      type(mod._kantoInMotionMobileBattleArtStageOnlyActive) == "function"
      and mod._kantoInMotionMobileBattleArtStageOnlyActive() == true
    return battleSystemEnabled()
      and (not externalBattleSceneOwnerRegistered()
        or externalKimHud or mobileBattleArtStageOnly)
  end

  local function decodeBattleBridgePath(path)
    if type(path) ~= "string" or path:sub(1, #BATTLE_BRIDGE_PREFIX) ~= BATTLE_BRIDGE_PREFIX then
      return nil
    end
    local tail = path:sub(#BATTLE_BRIDGE_PREFIX + 1)
    local generation, side, variant, species = tail:match(
      "^(hd)/([a-z]+)/([a-z]+)/([A-Z0-9_]+)%.png$")
    if not generation or (side ~= "front" and side ~= "back")
        or (variant ~= "normal" and variant ~= "shiny") then return nil end
    local record
    if side == "back" then
      if variant == "shiny" then record = localShinyBackRecord(species, generation)
      else record = localBackRecord(species, generation) end
    else
      if variant == "shiny" then record = localShinyFrontRecord(species, generation)
      else record = localFrontRecord(species, generation) end
    end
    if not record then return nil end
    return record, generation, side, variant, species
  end

  local function drawBattleProxy(proxy)
    local record = proxy.record
    if not record then return nil end
    local source = renderPresentationFrame(record, proxy.generation, proxy.species,
      proxy.frame, proxy.side, proxy.variant or "normal", proxy.frame ~= nil)
    if not source then return nil end
    local sw, sh = source:getDimensions()
    -- Imported HD frames are already display art. Fit them into the selected
    -- native slot and allow clean nearest-neighbour enlargement when
    -- PLAYER PKMN SIZE is above 100%; the engine's battle placement helpers
    -- keep the resulting image bottom-centred on the authored player anchor.
    local scale = math.min(proxy.width / math.max(1, sw),
      proxy.height / math.max(1, sh))
    local dw, dh = sw * scale, sh * scale
    local dx, dy = (proxy.width - dw) * 0.5, proxy.height - dh
    local previousCanvas = love.graphics.getCanvas and love.graphics.getCanvas() or nil
    love.graphics.push("all")
    love.graphics.setCanvas(proxy.canvas)
    love.graphics.origin()
    -- The native player slot can leave a clip active. Private sprite canvases
    -- must receive the whole new frame; push/pop preserves the host clip.
    love.graphics.setScissor()
    love.graphics.setBlendMode("alpha")
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setShader()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(source, dx, dy, 0, scale, scale)
    if previousCanvas then love.graphics.setCanvas(previousCanvas) else love.graphics.setCanvas() end
    love.graphics.pop()
    return proxy.canvas
  end

  local function battleProxy(record, generation, side, variant, species)
    if not (record and love.graphics and love.graphics.newCanvas) then return nil end
    -- Keep the replacement drawable at one stable authored slot size. The
    -- engine's resolveBattleScale seam below owns PLAYER PKMN SIZE directly;
    -- changing the Canvas dimensions here lets the engine's own placement
    -- compensation cancel part of the requested scale on some battle paths.
    -- Gen 1 consumers can preprocess/cache a drawable by identity. Give each
    -- frame an immutable slot image; Gen 2 needs one refreshed cached Canvas.
    local frame = not IS_GEN2 and currentFrame(record) or nil
    local key = table.concat({ generation, side, variant or "normal", species,
      frame and tostring(frame) or "live" }, ":")
    local proxy = battleProxyCache[key]
    if proxy and frame then return proxy.canvas end
    local width = side == "back" and 48 or 56
    local height = side == "back" and 48 or 56
    if not proxy then
      local ok, canvas = pcall(love.graphics.newCanvas, width, height)
      if not ok or not canvas then return nil end
      if canvas.setFilter then pcall(canvas.setFilter, canvas, "nearest", "nearest") end
      proxy = { canvas=canvas, width=width, height=height, record=record,
        generation=generation, side=side, variant=variant, species=species, frame=frame }
      battleProxyCache[key] = proxy
    else
      proxy.record = record
    end
    return drawBattleProxy(proxy)
  end

  local function battleBridgePath(species, side, mon)
    if not battleLiteOwnsSprites() then return nil end
    local record, generation, normalized, shiny = battleRecord(species, side, mon)
    if not record then return nil end

    local variant = shiny and "shiny" or "normal"

    -- BattleState:pic() asks pokemon.sprite every draw but caches the drawable
    -- returned by Assets.image(path). Refresh KIM's mutable native-slot Canvas
    -- here before returning the stable virtual path, so that cached object keeps
    -- advancing through the HD animation frames.
    -- Seed the constructor with HD art too, before its first live draw. Only
    -- publish a virtual path once the source exists, so missing assets retain
    -- the engine's normal fallback instead of failing ImageData loading.
    if not battleProxy(record, generation, side, variant, normalized) then return nil end

    return BATTLE_BRIDGE_PREFIX .. generation .. "/" .. side .. "/"
      .. variant .. "/" .. normalized .. ".png"
  end

  -- KIM player battle-trainer system.
  --
  -- PLAYER TRAINER selects the identity. The global ANIMATION toggle controls
  -- whether the supplied five-frame atlas advances during the intro.
  -- PotatoVoxel and other cooperative stages consume the same resolver instead
  -- of maintaining their own trainer assets/settings.
  do
    local BATTLE_TRAINERS = {
      gen1={animated="gen1player.png"},
      gen2={animated="gen2player.png"},
      gen3={animated="gen3player.png"},
      gen4={animated="gen4player.png"},
      gen5={animated="gen5player.png"},
      ash={animated="ashplayer.png"},
      gary={animated="garyplayer.png"},
      red={animated="redplayer.png"},
      ash_front={animated="ashfrontplayer.png"},
      misty_front={animated="mistyfrontplayer.png"},
      brock_front={animated="brockfrontplayer.png"},
      bulma_front={animated="bulmafrontplayer.png"},
      gary_front={animated="garyfrontplayer.png"},
    }

    local function packagedTrainerPath(relative)
      if not (mod.assets and type(mod.assets.path)=="function") then return nil end
      -- mod.assets:path() can return a syntactically valid path even when the
      -- package accidentally omitted the file. Verify it first so the engine
      -- never receives a nonexistent trainer path.
      if type(mod.info)=="function" then
        local okInfo, info=pcall(function() return mod:info(relative) end)
        if not (okInfo and info~=nil) then return nil end
      end
      local okPath, path=pcall(function() return mod.assets:path(relative) end)
      return okPath and path or nil
    end

    local function staticPath(choice)
      local def=BATTLE_TRAINERS[choice]
      if not (def and def.animated) then return nil end
      return packagedTrainerPath("assets/battle/player-trainers-frames/"..def.animated)
    end

    local function animatedPath(choice)
      local def=BATTLE_TRAINERS[choice]
      if not (def and def.animated) then return nil end
      return packagedTrainerPath("assets/battle/player-trainers-animated/"..def.animated)
    end

    -- Decode the supplied 5x80x80 horizontal trainer sheets once per choice.
    local frameCache={}
    local function frames(choice)
      local hit=frameCache[choice]
      if hit~=nil then return hit or nil end
      local path=animatedPath(choice)
      if not path or not (love.image and love.image.newImageData
          and love.graphics and love.graphics.newImage) then
        frameCache[choice]=false
        return nil
      end
      local made
      local ok=pcall(function()
        local sheet=love.image.newImageData(path)
        if not sheet then return end
        local sw,sh=sheet:getDimensions()
        if sw~=400 or sh~=80 then return end
        local out={}
        for i=0,4 do
          local cell=love.image.newImageData(80,80)
          cell:paste(sheet,0,0,i*80,0,80,80)
          local img=love.graphics.newImage(cell)
          if img and type(img.setFilter)=="function" then
            img:setFilter("nearest","nearest")
          end
          out[#out+1]=img
        end
        if #out==5 then made=out end
      end)
      frameCache[choice]=(ok and made) or false
      return (ok and made) or nil
    end

    local function currentTrainerFrame(battle,choice)
      local set=frames(choice)
      if not set then return nil end
      if mod.options:get("animate")==false then return set[1] end
      local offset=0
      if battle and type(battle.picOffset)=="function" then
        local ok,got=pcall(battle.picOffset,battle,"back")
        if ok then offset=tonumber(got) or 0 end
      end
      local progress=math.max(0,math.min(72,-offset))
      if progress<=0 then return set[1] end
      local moving=math.max(1,#set-1)
      local index=math.min(#set,2+
        math.floor(math.max(0,progress-1)*moving/72))
      return set[index]
    end

    local staticCache={}
    local function staticImage(choice)
      local hit=staticCache[choice]
      if hit~=nil then return hit or nil end
      local path=staticPath(choice)
      if not path or not (love and love.graphics
          and type(love.graphics.newImage)=="function") then
        staticCache[choice]=false
        return nil
      end
      local image
      local ok=pcall(function()
        image=love.graphics.newImage(path)
        if image and type(image.setFilter)=="function" then
          image:setFilter("nearest","nearest")
        end
      end)
      staticCache[choice]=(ok and image) or false
      return (ok and image) or nil
    end

    -- Finished 160x144 trainer card for cooperative staged renderers.
    local stagedCanvas=nil
    mod.exports._kantoInMotionStagedBattleTrainer=function(battle,side)
      if type(battle)~="table" or (side~=nil and side~="player") then return nil end
      if not battle.showPlayerBack or battle.safari or battle.demo then return nil end
      local choice=mod.options:get("battleTrainerSprite") or "red"
      if choice=="rom" then return nil end
      local frame=currentTrainerFrame(battle,choice) or staticImage(choice)
      if not frame then return nil end
      if not stagedCanvas then
        local ok,canvas=pcall(love.graphics.newCanvas,160,144,{dpiscale=1})
        if not ok or not canvas then
          ok,canvas=pcall(love.graphics.newCanvas,160,144)
        end
        if not (ok and canvas) then return nil end
        if type(canvas.setFilter)=="function" then
          pcall(canvas.setFilter,canvas,"nearest","nearest")
        end
        stagedCanvas=canvas
      end
      local picOffset=0
      if type(battle.picOffset)=="function" then
        local ok,got=pcall(battle.picOffset,battle,"back")
        if ok then picOffset=tonumber(got) or 0 end
      end
      local g=love.graphics
      local previous=g.getCanvas and g.getCanvas() or nil
      g.push("all")
      local ok=pcall(function()
        g.setCanvas(stagedCanvas)
        g.origin()
        g.clear(0,0,0,0)
        g.setShader()
        g.setBlendMode("alpha","alphamultiply")
        g.setColor(1,1,1,1)
        local w,h=frame:getDimensions()
        g.draw(frame,80-w*0.5+picOffset,96-h)
      end)
      if previous then g.setCanvas(previous) else g.setCanvas() end
      g.pop()
      if not ok then return nil end
      return stagedCanvas,1,
        {trainer=true,captureW=160,captureH=144,ax=80,ay=96}
    end

    -- Raw selected frame for a cooperative renderer that performs its own
    -- capture/placement.
    mod.exports._kantoInMotionBattleTrainerFrame=function(battle)
      if type(battle)~="table" or not battle.showPlayerBack
          or battle.safari or battle.demo then return nil end
      local choice=mod.options:get("battleTrainerSprite") or "red"
      if choice=="rom" then return nil end
      return currentTrainerFrame(battle,choice) or staticImage(choice)
    end

    -- Gen 1's first Oak's Lab rival battle is a special case: KIM's HD stage
    -- draws the player trainer directly, while the source enemy-trainer picture
    -- can be lost when the native 160x144 layer is reconstructed on Android.
    -- Resolve only that exact encounter to the packaged Gary front frame. Keep
    -- every later trainer battle on the engine/native trainer pipeline.
    mod.exports._kantoInMotionEnemyTrainerFrame=function(battle)
      if type(battle)~="table" or battle.showEnemyTrainer~=true then return nil end
      local isLabRival=false
      if type(battle.isOaksLabStarterRival)=="function" then
        local ok,value=pcall(battle.isOaksLabStarterRival,battle)
        if ok and value==true then isLabRival=true end
      end
      if not isLabRival and battle.oppClass=="OPP_RIVAL1" then
        local game=battle.game
        local map=game and game.overworld and game.overworld.map or nil
        local mapId=type(map)=="table" and (map.id or map.mapId or map.key) or map
        if mapId==nil and game and game.save and game.save.player then
          mapId=game.save.player.map or game.save.player.mapId
        end
        isLabRival=tostring(mapId or "")=="OAKS_LAB"
      end
      if not isLabRival then return nil end
      return staticImage("gary_front")
    end

    -- Register the generated first-frame files at native 1x battle-pic scale.
    -- Without this seam Gen1Recomp treats custom trainer art like the tiny ROM
    -- back picture and blows it up/crops it.
    if mod.content and mod.content.battle_sprite_scales
        and type(mod.content.battle_sprite_scales.register)=="function" then
      for key in pairs(BATTLE_TRAINERS) do
        local path=staticPath(key)
        if path then
          pcall(mod.content.battle_sprite_scales.register,
            mod.content.battle_sprite_scales,
            "kim_player_trainer_"..key,{path=path,scale=1})
        end
      end
    end

    -- Select the trainer at the engine seam BEFORE BattleState caches
    -- playerBackPic. This is the proven PotatoVoxel-compatible architecture.
    if mod.hooks and type(mod.hooks.wrap)=="function" and not IS_GEN2
        and not mod._kantoInMotionTrainerResolverV14 then
      mod._kantoInMotionTrainerResolverV14=true
      mod.hooks:wrap("player.sprite",function(nextFn,path,ctx)
        local resolved=nextFn(path,ctx)
        if type(ctx)~="table" or ctx.kind~="battle" or ctx.side~="back"
            or ctx.demo or ctx.oakDemo then return resolved end

        local ownsTrainer=battleSystemEnabled()
          and not externalBattleSceneOwnerRegistered()
        if not ownsTrainer then
          local probe=mod._kantoInMotionExternalStageAllowsKimTrainer
          if type(probe)=="function" then
            local ok,value=pcall(probe,ctx.battle)
            ownsTrainer=ok and value==true
          end
        end
        if not ownsTrainer then return resolved end

        local choice=mod.options:get("battleTrainerSprite") or "red"
        if choice=="rom" then return resolved end
        local custom=staticPath(choice)
        if not custom then return resolved end
        ctx.trueColor=true
        return custom
      end,9000)
    end
  end

  local function resolveBattleBridge(path, mode)
    local record, generation, side, variant, species = decodeBattleBridgePath(path)
    if not record then return nil end
    if mode == "exists" then return true end
    local image = battleProxy(record, generation, side, variant, species)
    if not image then return nil end
    if mode == true then
      if type(image.newImageData) == "function" then
        local ok, data = pcall(image.newImageData, image)
        if ok then return data end
      end
      return nil
    end
    return image
  end

  -- Standard resolved-sprite bridge for stock and third-party UI overhauls.
  -- Some complete UI replacements do not consume mod.exports directly; they
  -- correctly ask Gen1Recomp's pokemon.sprite seam for the selected front art
  -- and then load that path through src.render.Assets. Return a private virtual
  -- frame path for non-battle presentation surfaces and teach Assets how to
  -- resolve that path to Kanto in Motion's live frame Canvas. This keeps the
  -- animation provider independent from the bundled Modern UI without taking
  -- ownership of battle sprites, camera, or attack presentation.
  local FRAME_BRIDGE_PREFIX = "__kanto_in_motion_frame__/"
  local FRAME_BRIDGE_KINDS = { dex = true, pokedex = true, ["unown-dex"] = true }

  local function bridgeFront(species, generation, mon)
    generation = generation or selectedGeneration()
    if isBattleShiny(mon) then
      local shiny, actualGeneration, normalized = localShinyFrontRecord(species, generation, mon)
      if shiny then return shiny, actualGeneration, normalized, true end
    end
    local front, actualGeneration, normalized = localFrontRecord(species, generation, mon)
    if front then return front, actualGeneration, normalized, false end
    return nil
  end

  local function menuPresentationFrame(front)
    if IS_GEN2 and mod.options:get("spriteAnimation") == false then return 1 end
    return currentFrame(front)
  end

  local function bridgePath(species, generation, mon)
    local front, actualGeneration, normalized, shiny = bridgeFront(species, generation, mon)
    if not front then return nil end
    local frame = menuPresentationFrame(front)
    return FRAME_BRIDGE_PREFIX .. actualGeneration .. "/"
      .. (shiny and "shiny" or "normal") .. "/" .. normalized .. "/"
      .. tostring(frame) .. ".png"
  end

  local function decodeBridgePath(path)
    if type(path) ~= "string" or path:sub(1, #FRAME_BRIDGE_PREFIX) ~= FRAME_BRIDGE_PREFIX then
      return nil
    end
    local tail = path:sub(#FRAME_BRIDGE_PREFIX + 1)
    local generation, variant, species, frame = tail:match("^(hd)/([a-z]+)/([A-Z0-9_]+)/(%d+)%.png$")
    if not generation or (variant ~= "normal" and variant ~= "shiny") then return nil end
    local front
    if variant == "shiny" then
      front = localShinyFrontRecord(species, generation)
    else
      front = localFrontRecord(species, generation)
    end
    if not front then return nil end
    return front, generation, species, tonumber(frame), variant
  end


  -- Forward declaration: the stock Clean UI bridge below calls this
  -- before its implementation appears later in the file. Without this local
  -- declaration Lua resolves those calls as a global and the pcall-wrapped
  -- bridge install silently fails.
  local gen2CleanUiHandle

  -- Stock Gen2 Clean UI 0.4.1 compatibility without modifying that mod.
  --
  -- Clean UI intentionally accepts only assets/generated/*.png portrait paths
  -- and caches the loaded drawable by path.  Kanto in Motion therefore gives
  -- the live Gen2 Pokemon definitions a TEMPORARY generated-looking path only
  -- while Clean UI prepares its frame. A very narrow love.graphics.newImage
  -- bridge resolves only our reserved path prefix to a mutable Canvas. Clean
  -- UI caches that Canvas normally; Kanto in Motion updates its pixels each
  -- frame as the selected animation advances. The original Pokemon definitions
  -- are restored immediately after Clean UI finishes preparing, so battles,
  -- scripts and other UI mods never inherit the temporary path.
  local CLEAN_UI_LIVE_PREFIX = "assets/generated/kanto_in_motion_live/"
  local cleanUiProxies = {}
  local cleanUiVariantBySpecies = {}

  local function cleanUiLivePath(species, generation)
    species = normalizedSpecies(species)
    generation = generation or selectedGeneration()
    if not species or not localFrontRecord(species, generation) then return nil end
    return CLEAN_UI_LIVE_PREFIX .. generation .. "/" .. species .. ".png"
  end

  local function decodeCleanUiLivePath(path)
    if type(path) ~= "string" then return nil end

    -- Stock Gen2 Clean UI does not pass the generated descriptor path straight
    -- to love.graphics.newImage(). Its mod.assets:image() first expands that
    -- descriptor underneath Clean UI's own mod directory, so on Windows the
    -- renderer reaches us with something like:
    --
    --   .../gen2_clean_ui/assets/generated/kanto_in_motion_live/hd/PIKACHU.png
    --
    -- The modified Clean UI test build intercepted the descriptor *before*
    -- that expansion, which is why animation worked there while stock Clean
    -- UI remained static. Match our reserved namespace anywhere in the final
    -- normalized path rather than requiring it at character one.
    local normalized = path:gsub("\\", "/")
    local at = normalized:find(CLEAN_UI_LIVE_PREFIX, 1, true)
    if not at then return nil end
    local tail = normalized:sub(at + #CLEAN_UI_LIVE_PREFIX)
    local generation, species = tail:match("^(hd)/([A-Z0-9_]+)%.png$")
    if not generation or not species then return nil end
    local normal = localFrontRecord(species, generation)
    if not normal then return nil end
    return generation, species
  end

  local function frontForCleanUi(generation, species)
    local wantShiny = cleanUiVariantBySpecies[species] == true
    if wantShiny then
      local shiny = localShinyFrontRecord(species, generation)
      if shiny then return shiny, true end
    end
    local front = localFrontRecord(species, generation)
    return front, false
  end

  local function proxySize(generation, species)
    local normal = localFrontRecord(species, generation)
    return presentationSize(generation, species, "front", normal)
  end

  local function drawCleanUiProxy(proxy)
    if not (proxy and love.graphics and love.graphics.setCanvas) then return nil end
    local front, shiny = frontForCleanUi(proxy.generation, proxy.species)
    if type(front) ~= "table" then return proxy.canvas end
    local source = renderPresentationFrame(front, proxy.generation, proxy.species,
      menuPresentationFrame(front), "front", shiny and "shiny" or "normal", false)
    if not source then return proxy.canvas end
    local sw, sh = source:getDimensions()
    local dx = math.floor((proxy.width - sw) / 2)
    local dy = proxy.height - sh
    local previous = love.graphics.getCanvas and love.graphics.getCanvas() or nil
    love.graphics.push("all")
    love.graphics.setCanvas(proxy.canvas)
    love.graphics.origin()
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setShader()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(source, dx, dy)
    if previous then love.graphics.setCanvas(previous) else love.graphics.setCanvas() end
    love.graphics.pop()
    return proxy.canvas
  end

  local function cleanUiProxy(path)
    local generation, species = decodeCleanUiLivePath(path)
    if not generation then return nil end
    local hit = cleanUiProxies[path]
    if not hit then
      if not (love.graphics and love.graphics.newCanvas) then return nil end
      local w, h = proxySize(generation, species)
      local ok, canvas = pcall(love.graphics.newCanvas, w, h)
      if not ok or not canvas then return nil end
      if canvas.setFilter then pcall(canvas.setFilter, canvas, "nearest", "nearest") end
      hit = { canvas=canvas, width=w, height=h,
        generation=generation, species=species }
      cleanUiProxies[path] = hit
      if mod.log and type(mod.log.info) == "function"
          and not mod._kantoInMotionCleanUiProxyConfirmed then
        mod._kantoInMotionCleanUiProxyConfirmed = true
        mod.log:info("stock Gen2 Clean UI requested Kanto in Motion live portrait; animation proxy active")
      end
    end
    return drawCleanUiProxy(hit)
  end

  local function refreshCleanUiProxies()
    for _, proxy in pairs(cleanUiProxies) do drawCleanUiProxy(proxy) end
  end

  local function markVisibleShiny(game)
    cleanUiVariantBySpecies = {}
    local stack = game and game.stack
    local top = stack and type(stack.top) == "function" and stack:top() or nil
    if type(top) ~= "table" then return end
    local function mark(mon)
      if type(mon) == "table" and mon.species then
        cleanUiVariantBySpecies[normalizedSpecies(mon.species)] = isBattleShiny(mon)
      end
    end
    mark(rawget(top, "mon"))
    local party = rawget(top, "party")
    local index = tonumber(rawget(top, "index"))
    if type(party) == "table" and index then mark(rawget(party, index)) end
  end

  local function installStockGen2CleanUiBridge()
    if not IS_GEN2 or not gen2CleanUiHandle()
        or not (love and love.graphics and type(love.graphics.newImage) == "function") then
      return false
    end

    -- The graphics table itself is engine-owned and shared. Keep exactly one
    -- narrow wrapper across hot reloads; only its resolver closure is replaced.
    local g = love.graphics
    local bridge = rawget(g, "__kantoInMotionCleanUiImageBridge")
    if type(bridge) ~= "table" then
      bridge = { original = g.newImage }
      rawset(g, "__kantoInMotionCleanUiImageBridge", bridge)
      g.newImage = function(path, ...)
        local resolver = bridge.resolver
        if resolver then
          local ok, image = pcall(resolver, path)
          if ok and image then return image end
        end
        return bridge.original(path, ...)
      end
    end
    bridge.resolver = cleanUiProxy

    local function withCleanUiPokemonDefinitions(game, nextFn, ...)
      if not menuSpritesEnabled() or not gen2CleanUiHandle() then
        return nextFn(...)
      end

      markVisibleShiny(game)
      refreshCleanUiProxies()

      local generation = selectedGeneration()
      local pokemon = game and game.data and game.data.pokemon
      if type(pokemon) ~= "table" then return nextFn(...) end

      local restore = {}
      for species, def in pairs(pokemon) do
        if type(def) == "table" then
          local path = cleanUiLivePath(species, generation)
          if path then
            restore[#restore + 1] = {
              def=def, spriteFront=rawget(def, "spriteFront"),
              trueColor=rawget(def, "trueColor"),
            }
            rawset(def, "spriteFront", path)
            rawset(def, "trueColor", true)
          end
        end
      end

      if #restore > 0 and mod.log and type(mod.log.info) == "function"
          and not mod._kantoInMotionCleanUiDefinitionsConfirmed then
        mod._kantoInMotionCleanUiDefinitionsConfirmed = true
        mod.log:info("stock Gen2 Clean UI prepare sees Kanto in Motion animated sprite descriptors")
      end

      local result = { pcall(nextFn, ...) }
      for i = #restore, 1, -1 do
        local row = restore[i]
        rawset(row.def, "spriteFront", row.spriteFront)
        rawset(row.def, "trueColor", row.trueColor)
      end
      local ok = table.remove(result, 1)
      if not ok then error(result[1], 0) end
      return unpackCompat(result)
    end

    if mod.hooks and type(mod.hooks.wrap) == "function" then
      -- Newer/Gen1-style hosts prepare here.
      if not mod._kantoInMotionCleanUiPrepareHook then
        mod._kantoInMotionCleanUiPrepareHook = mod.hooks:wrap(
          "render.ui.prepare",
          function(nextFn, game, viewport)
            return withCleanUiPokemonDefinitions(game, nextFn, game, viewport)
          end, 95000)
      end

      -- Gen1Recomp 0.2.24's Gen2 Clean UI can prepare from its
      -- screen.render_visible fallback instead. KIM must be the outer wrapper
      -- (95000 > Clean UI's 90000) so the temporary definitions remain active
      -- while Clean UI snapshots and renders the model.
      if not mod._kantoInMotionCleanUiVisibleHook then
        mod._kantoInMotionCleanUiVisibleHook = mod.hooks:wrap(
          "screen.render_visible",
          function(nextFn, state)
            local game = type(state) == "table" and rawget(state, "game") or nil
            if not game then return nextFn(state) end
            return withCleanUiPokemonDefinitions(game, nextFn, state)
          end, 95000)
      end

      -- Clean UI intentionally caches source images by descriptor path. The
      -- cached object is our mutable Canvas, so refresh its pixels every frame
      -- immediately before Clean UI's lower-priority render.hud wrapper
      -- composites its already-built candidate.
      if not mod._kantoInMotionCleanUiHudHook then
        mod._kantoInMotionCleanUiHudHook = mod.hooks:wrap(
          "render.hud",
          function(nextFn, game, viewport)
            if menuSpritesEnabled() and gen2CleanUiHandle() then
              markVisibleShiny(game)
              refreshCleanUiProxies()
            end
            return nextFn(game, viewport)
          end, 95000)
      end
    end

    if mod.log and type(mod.log.info) == "function" then
      mod.log:info("stock Gen2 Clean UI animated portrait bridge enabled")
    end
    return true
  end

  local okAssets, Assets = pcall(require, "src.render.Assets")
  if okAssets and type(Assets) == "table" then
    -- Keep one engine-level wrapper across dev hot reloads; only the resolver
    -- closure is refreshed so stale Kanto in Motion state cannot accumulate.
    if not Assets.__kantoInMotionFrameBridge then
      Assets.__kantoInMotionFrameBridge = {
        image = Assets.image, imageData = Assets.imageData, exists = Assets.exists,
      }
      Assets.image = function(path)
        local resolver = Assets.__kantoInMotionFrameResolver
        if resolver then
          local image = resolver(path, false)
          if image then return image end
        end
        return Assets.__kantoInMotionFrameBridge.image(path)
      end
      Assets.imageData = function(path)
        local resolver = Assets.__kantoInMotionFrameResolver
        if resolver then
          local image = resolver(path, true)
          if image then return image end
        end
        return Assets.__kantoInMotionFrameBridge.imageData(path)
      end
      Assets.exists = function(path)
        local resolver = Assets.__kantoInMotionFrameResolver
        if resolver and resolver(path, "exists") then return true end
        return Assets.__kantoInMotionFrameBridge.exists(path)
      end
    end

    Assets.__kantoInMotionFrameResolver = function(path, mode)
      local battleImage = resolveBattleBridge(path, mode)
      if battleImage then return battleImage end
      local front, generation, species, frame, variant = decodeBridgePath(path)
      if not front then return nil end
      if mode == "exists" then return true end
      local image = renderPresentationFrame(front, generation, species, frame,
        "front", variant or "normal", true)
      if not image then return nil end
      if mode == true then
        if type(image.newImageData) == "function" then
          local ok, data = pcall(image.newImageData, image)
          if ok then return data end
        end
        return nil
      end
      return image
    end
  end

  local STOCK_DIRECT_IMAGE_KINDS = {
    summary = true, status = true, dex = true, pokedex = true,
  }

  gen2CleanUiHandle = function()
    if not IS_GEN2 or type(mod.find) ~= "function" then return nil end
    local ok, handle = pcall(mod.find, "gen2_clean_ui")
    if ok and type(handle) == "table" then return handle end
    return nil
  end

  local function knownExternalUiPresent()
    if gen2CleanUiHandle() then return true end
    if mod._kantoInMotionInterop
        and mod._kantoInMotionInterop:hasPokemonSpriteBridgeUi() then
      return true
    end
    if type(mod.find) ~= "function" then return false end
    for _, id in ipairs({ "gen3_battle_ui", "colosseum_ui_overhaul" }) do
      local ok, handle = pcall(mod.find, id)
      if ok and handle then return true end
    end
    return false
  end

  if mod.hooks and type(mod.hooks.wrap) == "function" then
    mod.hooks:wrap("pokemon.sprite", function(next, path, ctx)
      local resolved = next(path, ctx)
      local kind = type(ctx) == "table" and tostring(ctx.kind or ""):lower() or ""
      if type(ctx) == "table" and kind == "battle"
          and (ctx.side == "front" or ctx.side == "back")
          and battleLiteOwnsSprites() then
        -- Gen 1 gets an HD snapshot for its constructor, then the live pics
        -- wrapper supplies immutable frame images on every draw. Gen 2 keeps
        -- its mutable Canvas bridge.
        local virtual = battleBridgePath(ctx.species, ctx.side, ctx.mon)
        if virtual then
          ctx.trueColor = true
          return virtual
        end
        return resolved
      end
      if not menuSpritesEnabled() or type(ctx) ~= "table"
          or ctx.side ~= "front" or not FRAME_BRIDGE_KINDS[kind] then
        return resolved
      end

      -- Stock Gen1Recomp's SummaryMenu and DexEntryMenu call
      -- love.graphics.newImage() directly on the path returned by
      -- pokemon.sprite.  Kanto in Motion's virtual frame paths are resolved by
      -- src.render.Assets and therefore cannot be opened by newImage().  When
      -- the stock UI owns these screens, leave their constructor path vanilla;
      -- patchVanillaScreens() below injects the live animated Canvas at draw
      -- time.  Known external UI overhauls use Assets and keep the bridge.
      if STOCK_DIRECT_IMAGE_KINDS[kind] and not knownExternalUiPresent() then
        return resolved
      end

      local virtual = bridgePath(ctx.species, selectedGeneration(), ctx.mon)
      if not virtual then return resolved end
      ctx.trueColor = true
      return virtual
    end, 650)
  end

  -- -----------------------------------------------------------------------
  -- Battle Lite runtime
  -- -----------------------------------------------------------------------
  -- When the fullscreen Battle Lite path owns a Gen1 battle, remember the
  -- BattleState draw for the matching render.compose call. The fullscreen host
  -- removes the stock 160x144 paper before it is composited; this pending
  -- token lets Kanto in Motion do the same at the renderer's explicit UI
  -- canvas seam without guessing at final-window rectangles afterward.
  -- Flat HD battle host. The authored background is installed as the
  -- renderer world layer while the engine's own 160x144 battle canvas remains
  -- a transparent overlay. Pokemon, move effects, send-out/faint motion and
  -- the native battle menu therefore keep their original draw order/anchors.
  local setFlatBattleWorld = nil
  local drawDirectBattleSprites = nil
  -- Fullscreen source-ownership token. BattleState:draw marks the live
  -- top-level fullscreen battle; render.compose then removes the finished
  -- native 160x144 UI surface before the engine can scale/letterbox it over
  -- KIM's arena. render.hud clears the token after rebuilding the transparent
  -- native overlay pieces that we still want.
  local pendingFullscreenBattle = nil
  local forcedBattleLayoutPrevious = nil
  local forcedBattleLayoutActive = false

  -- KIM stages against the original 160x144 layout, never WIDE. WIDE
  -- moves the Pokemon/menu anchors onto a 304x144 surface and is exactly what
  -- produced the small centered battle seen in the earlier tests. Keep the
  -- user's previous value in memory and restore it when Kanto in Motion no
  -- longer owns a battle instead of permanently rewriting their preference.
  local function forceBattleLayoutOG(game)
    if not game then
      local okGame, Game = pcall(require, "src.core.Game")
      if okGame then game = Game end
    end
    local opts = game and game.save and game.save.options
    if not opts then return false end
    if not forcedBattleLayoutActive then
      forcedBattleLayoutPrevious = opts.battleLayout
      forcedBattleLayoutActive = true
    end
    opts.battleLayout = "og"
    return true
  end

  local function restoreBattleLayout(game)
    if not forcedBattleLayoutActive then return end
    if not game then
      local okGame, Game = pcall(require, "src.core.Game")
      if okGame then game = Game end
    end
    local opts = game and game.save and game.save.options
    if opts then opts.battleLayout = forcedBattleLayoutPrevious end
    forcedBattleLayoutPrevious = nil
    forcedBattleLayoutActive = false
  end

  -- KIM suppresses only the opaque full-frame white fill emitted
  -- by BattleState:draw. Text boxes, flashes, move effects and every other
  -- rectangle pass through unchanged. This is the critical seam that lets the
  -- world/background show through without throwing away the UI canvas itself.
  local function withoutBattleBackgroundFill(battle, fn, ...)
    local g = love.graphics
    local rectangle = g.rectangle
    local clear = g.clear
    -- The active Gen1 battle UI canvas is the one KIM wants to remain
    -- transparent over the fullscreen KRS arena. Some battle-animation paths
    -- clear that canvas back to Gen1's white paper instead of drawing a white
    -- rectangle. At 1920x1080 the 160x144 surface is scaled 7x, producing the
    -- 1120x1008 white block visible in the user's capture. Restrict the clear
    -- shim to this exact canvas so temporary effect canvases keep their own clears.
    local sourceCanvas = g.getCanvas and g.getCanvas() or nil
    local fullscreenPaperless = hdBattleBackgroundsEnabled()
    local function isWhiteClear(r, gr, b, a)
      if type(r) == "table" then
        local t = r
        r, gr, b, a = t[1] or t.r, t[2] or t.g, t[3] or t.b, t[4] or t.a
      end
      r, gr, b = tonumber(r), tonumber(gr), tonumber(b)
      if not (r and gr and b) then return false end
      a = tonumber(a)
      if a == nil then a = 1 end
      return r > 0.95 and gr > 0.95 and b > 0.95 and a > 0.05
    end
    if fullscreenPaperless and type(clear) == "function" then
      g.clear = function(r, gr, b, a, ...)
        local target = g.getCanvas and g.getCanvas() or nil
        if target == sourceCanvas and isWhiteClear(r, gr, b, a) then
          return clear(0, 0, 0, 0)
        end
        return clear(r, gr, b, a, ...)
      end
    end
    g.rectangle = function(mode, x, y, w, h, ...)
      if mode == "fill" and x == 0 and y == 0 and w == 160 and h == 144 then
        local r, gr, b, a = g.getColor()
        local fullWhite = r > 0.95 and gr > 0.95 and b > 0.95 and a > 0.05
        if fullWhite then
          if a > 0.99 then
            -- Native battle paper: the fullscreen KIM arena already owns the
            -- background, so keep the source layer transparent as before.
            local target = g.getCanvas and g.getCanvas() or nil
            if target ~= nil then clear(0, 0, 0, 0) end
            return
          end
          if fullscreenPaperless then return end
        end
      end
      return rectangle(mode, x, y, w, h, ...)
    end
    local result = { pcall(fn, battle, ...) }
    g.rectangle = rectangle
    g.clear = clear
    local ok = table.remove(result, 1)
    if not ok then error(result[1], 0) end
    return unpackCompat(result)
  end

  -- Gen1 animated sprites are substituted only during drawPicsLayer so battle
  -- state, Transform, faint/send-out state and third-party mechanics retain
  -- the exact native battler tables. A registered external scene owner wins outright.
  if not IS_GEN2 then
    local okOW, OverworldController = pcall(require, "src.world.OverworldController")
    if okOW and type(OverworldController) == "table"
        and type(OverworldController.pushBattle) == "function"
        and not OverworldController._kantoInMotionBattleLayout then
      local nativePushBattle = OverworldController.pushBattle
      OverworldController._kantoInMotionBattleLayout = nativePushBattle
      OverworldController.pushBattle = function(self, battle, ...)
        if battleSystemEnabled() and hdBattleBackgroundsEnabled() and not externalBattleSceneOwnerRegistered() then
          forceBattleLayoutOG(self and self.game)
        end
        return nativePushBattle(self, battle, ...)
      end
    end

    local okBattle, BattleState = pcall(require, "src.battle.BattleState")
    if okBattle and type(BattleState) == "table" then
      if type(BattleState.drawPicsLayer) == "function"
          and not BattleState._kantoInMotionBattlePics then
        local nativeDrawPicsLayer = BattleState.drawPicsLayer
        BattleState._kantoInMotionBattlePics = nativeDrawPicsLayer
        local transparentBattlePic = nil
        local function transparentPic()
          if transparentBattlePic then return transparentBattlePic end
          if not (love and love.graphics and type(love.graphics.newCanvas) == "function") then
            return nil
          end
          local ok, canvas = pcall(love.graphics.newCanvas, 1, 1, { dpiscale = 1 })
          if not ok or not canvas then return nil end
          if canvas.setFilter then pcall(canvas.setFilter, canvas, "nearest", "nearest") end
          local prev = love.graphics.getCanvas and love.graphics.getCanvas() or nil
          love.graphics.push("all")
          love.graphics.setCanvas(canvas)
          love.graphics.clear(0, 0, 0, 0)
          if prev then love.graphics.setCanvas(prev) else love.graphics.setCanvas() end
          love.graphics.pop()
          transparentBattlePic = canvas
          return canvas
        end
        BattleState.drawPicsLayer = function(self, ...)
          local player, playerManaged = mod._kantoInMotionFlatNativeFrame(self, "player")
          local enemy, enemyManaged = mod._kantoInMotionFlatNativeFrame(self, "enemy")
          local trainer = type(mod._kantoInMotionFlatTrainerFrame) == "function"
            and mod._kantoInMotionFlatTrainerFrame(self) or nil
          local nativeFitPlayer = battleLiteFullScreenActive() and battleBackgroundMode()=="native"
            and not self._kimReplayPlayerBehindMenu and not self.showPlayerBack
            and not self.safari and not self.demo
          local hidePlayer = playerManaged or player ~= nil or trainer ~= nil or nativeFitPlayer
          local hideEnemy = enemyManaged or enemy ~= nil
          local oldPicImage, oldTrainer = self.picImage, self.playerBackPic
          local getter = mod.exports and mod.exports._kantoInMotionBattleTrainerFrame
          if self.showPlayerBack and not self.safari and not self.demo and type(getter) == "function" then
            local ok, selected = pcall(getter, self)
            if ok and selected then self.playerBackPic = selected end
          end
          -- Always call the native/provider layer, including while both
          -- sprites are replayed at HD ground anchors. 1025Dex owns its own
          -- loading and animation clocks inside this layer. Suppress only the
          -- relocated pictures at the last draw seam, never its update pass.
          self.picImage = function(state, image, ...)
            if hideEnemy and state.enemy and image == state.enemy.sprite
                and not state.showEnemyTrainer then return transparentPic() end
            if hidePlayer and ((state.player and image == state.player.sprite)
                or (state.showPlayerBack and image == state.playerBackPic)) then
              return transparentPic()
            end
            return oldPicImage(state, image, ...)
          end
          local result = {pcall(nativeDrawPicsLayer, self, ...)}
          self.picImage, self.playerBackPic = oldPicImage, oldTrainer
          if not result[1] then error(result[2], 0) end
          return unpackCompat(result, 2)
        end
      end

      -- KIM captures the complete 48-row HP/status bands, including Pokeball
      -- Colorfix party rows. Suppress the source copy while the HD fullscreen
      -- battle scene is active so the bands are drawn exactly once.
      if type(BattleState.drawHUDs) == "function"
          and not BattleState._kantoInMotionSourceHudBands then
        local nativeDrawHUDs = BattleState.drawHUDs
        BattleState._kantoInMotionSourceHudBands = nativeDrawHUDs
        BattleState.drawHUDs = function(self, ...)
          if battleLiteFullScreenActive() and not self._kantoInMotionHudCapture then
            return
          end
          return nativeDrawHUDs(self, ...)
        end
      end

      if type(BattleState.draw) == "function"
          and not BattleState._kantoInMotionBattleDraw then
        local nativeBattleDraw = BattleState.draw
        BattleState._kantoInMotionBattleDraw = nativeBattleDraw
        BattleState.draw = function(self, ...)
          local ownsFullscreen = battleLiteFullScreenActive()
          local ownsExternalMobileStageUi = false
          if type(mod._kantoInMotionNativeMobileHost) == "function"
              and mod._kantoInMotionNativeMobileHost()
              and type(mod._kantoInMotionExternalStageUsesKimHud) == "function" then
            local okExternal, value = pcall(mod._kantoInMotionExternalStageUsesKimHud, self)
            ownsExternalMobileStageUi = okExternal and value == true
          end
          if not ownsFullscreen then
            if pendingFullscreenBattle == self then pendingFullscreenBattle = nil end
            -- A cooperative external stage can own the world without owning
            -- KIM's lower battle UI. Keep the hybrid marker live on mobile so
            -- Modern UI sees the same contract before render.compose.
            self._kantoInMotionBattleLite = ownsExternalMobileStageUi and true or nil
            if self._kantoInMotionOwnsBattlePaper then
              self.letterboxWhite = nil
              self._kantoInMotionOwnsBattlePaper = nil
            end
            local shot = rawget(self, "dramaticShapeShot")
            if type(shot) == "table" and shot.kantoInMotion2D then
              self.dramaticShapeShot = nil
              self._kantoInMotionFlatShot = nil
            end
            return nativeBattleDraw(self, ...)
          end

          -- Publish ownership before render.zones/render.compose so the
          -- integrated Modern UI can modernize only KIM's lower battle panel
          -- without ever claiming another mod's battle scene. Mark only a
          -- genuinely top-level BattleState for source-canvas removal; child
          -- Bag/Party/etc. screens must keep their own UI canvas intact.
          self._kantoInMotionBattleLite = true
          local stack = self.game and self.game.stack
          local top = stack and type(stack.top) == "function" and stack:top() or nil
          if top == nil or top == self then pendingFullscreenBattle = self end

          -- KIM owns one full-window HD battle scene. beginFrame has already
          -- bound the UI canvas here, so clear that source canvas to alpha,
          -- disable the white letterbox, and suppress only the source 160x144
          -- white background fill. The engine still draws Pokemon, attack
          -- effects and the lower battle UI normally into this transparent
          -- overlay.
          if type(setFlatBattleWorld) == "function" then
            mod._kantoInMotionGuardedMobileCall("flat battle world",
              setFlatBattleWorld, self.game, self)
          end
          self.letterboxWhite = false
          self._kantoInMotionOwnsBattlePaper = true
          love.graphics.clear(0, 0, 0, 0)

          -- KIM no longer ships a replacement move-animation system. Native
          -- Gen1Recomp flashes/effects remain authoritative; only the opaque
          -- source battle paper is suppressed over the HD scene.
          local result = { mod._kantoInMotionGuardedMobileCall("native battle source draw",
            withoutBattleBackgroundFill, self, nativeBattleDraw, ...) }

          local ok = table.remove(result, 1)
          if not ok then error(result[1], 0) end

          -- Quality of Life checks dramaticShapeShot after BattleState:draw.
          -- KIM owns the fullscreen scene here, so reassert the already-published
          -- flat-shot contract after the native source draw. This keeps QOL EXP
          -- and caught indicators attached to KIM's final-resolution HUD geometry.
          local flatShot = rawget(self, "_kantoInMotionFlatShot")
          local desktopHost = not (type(mod._kantoInMotionNativeMobileHost) == "function"
            and mod._kantoInMotionNativeMobileHost())
          if desktopHost and type(flatShot) == "table" and flatShot.kantoInMotion2D then
            self.dramaticShapeShot = flatShot
            self.__qolDramaticShapeHudSnapped = true
          end

          return unpackCompat(result)
        end
      end

      if type(BattleState.resolveBattleScale) == "function"
          and not BattleState._kantoInMotionBattleScale then
        local nativeResolveScale = BattleState.resolveBattleScale
        BattleState._kantoInMotionBattleScale = nativeResolveScale
        BattleState.resolveBattleScale = function(data, side, path, species)
          local base = nativeResolveScale(data, side, path, species)

          local mobileHost = false
          if type(mod._kantoInMotionNativeMobileHost) == "function" then
            local okMobile, valueMobile = pcall(mod._kantoInMotionNativeMobileHost)
            mobileHost = okMobile and valueMobile == true
          end

          local kimTrainerPath = false
          if side == "back" and type(path) == "string" then
            kimTrainerPath =
              path:find("assets/battle/player-trainers-frames/", 1, true) ~= nil
          end

          if side == "back"
              and mod._kantoInMotionPotatoPinnedTrainerScaleActive then
            -- Potato's pinned trainer was too small at v23's shared 65%.
            -- Keep desktop v22 at 1x, but use an 85% mobile logical size for
            -- this path only.
            return mobileHost and 0.95 or 1
          end

          if side == "back"
              and (mod._kantoInMotionKimTrainerScaleActive or kimTrainerPath) then
            -- v23's effective 1.00x was too large; v24's 0.65x was too small.
            -- Use the midpoint-ish 0.80x only on Android/iOS. Desktop keeps
            -- the confirmed v22 1x trainer size and Potato's pinned trainer
            -- continues to use its separate 0.85x mobile rule above.
            return mobileHost and 0.95 or 1
          end
          if side == "back" and mod._kantoInMotionPotatoPinnedBackScaleActive then
            -- The Potato-pinned KIM drawable is now a normal 48x48 logical
            -- back slot, so preserve Gen1Recomp/Potato's native scale instead
            -- of forcing 1x. This keeps the full fitted sprite at the same
            -- authored size/anchor as an ordinary back pic.
            return base
          end
          if not (battleSystemEnabled() and not externalBattleSceneOwnerRegistered() and species) then
            -- Cooperative Potato sprite replacement intentionally leaves this
            -- scale seam native. v51 used that path and rendered large back
            -- sprites such as Charizard correctly; forcing a 1.25x logical
            -- scale here shrank the already display-sized KIM proxy into the
            -- clipped fragment seen in v53/v54.
            return base
          end

          -- Fullscreen animated Pokemon are now painted at native atlas
          -- resolution directly into the world canvas. Do not pre-shrink them
          -- here: doing so resamples once into the 160x144 UI and a second time
          -- when that UI reaches the window, which is what made v7.3 look
          -- extremely blocky. This seam remains only for the non-fullscreen
          -- fallback path.
          if battleLiteDirectStageActive() then
            -- The fullscreen compositor owns the visible sprite, but some
            -- native battle paths still ask for this scale before their
            -- source layer is blanked. Keep the enemy control effective for
            -- those paths without changing the player/native handoff.
            if side ~= "back" then
              local pct = tonumber(mod.options:get("battleEnemySize")) or 100
              pct = math.max(50, math.min(200, pct))
              local host=love and love.system and love.system.getOS and love.system.getOS()
          local desktopPct=100
          if host=="Windows" or host=="OS X" or host=="Linux" then
            desktopPct=tonumber(mod.options:get("desktopEnemySize")) or 100
          end
          return base * pct / 100 * math.max(50,math.min(200,desktopPct))/100
            end
            return base
          end

          if side == "back" then
            local record = battleLiteOwnsSprites() and battleRecord(species, side, nil) or nil
            local authored = record and 1 or (tonumber(base) or 1)
            local pct = tonumber(mod.options:get("battlePlayerSize")) or 100
            pct = math.max(50, math.min(200, pct))
            return authored * 1.15 * pct / 100
          end
          local pct = tonumber(mod.options:get("battleEnemySize")) or 100
          pct = math.max(50, math.min(200, pct))
          return base * pct / 100
        end
      end

    end
  end

  -- Platform probe used by the HD battle presentation and mobile HUD paths.
  mod._kantoInMotionNativeMobileHost = function()
    local system = love and love.system
    if not system or type(system.getOS) ~= "function" then return false end
    local ok, host = pcall(system.getOS)
    return ok and (host == "Android" or host == "iOS")
  end

  -- Gen 1 mobile HUD boundary: preserve the exact engine-owned entry state and
  -- remove only pushes leaked during render.hud. This mirrors the proven
  -- PotatoVoxel mobile strategy without resetting or rebinding the viewport.
  do
    if not IS_GEN2 and mod._kantoInMotionNativeMobileGen1() and mod.hooks
        and type(mod.hooks.wrap) == "function" then
      local warnedHud = false
      mod.hooks:wrap("render.hud", function(nextFn, game, viewport)
        if not battleSystemEnabled() then return nextFn(game, viewport) end
        local baseDepth = mod._kantoInMotionGraphicsDepth()
        local result = { pcall(nextFn, game, viewport) }
        local repaired = baseDepth ~= nil and mod._kantoInMotionRestoreGraphicsDepth(baseDepth) or 0
        if repaired > 0 and not warnedHud and mod.log
            and type(mod.log.warn) == "function" then
          warnedHud = true
          mod.log:warn(
            "Gen1 mobile render.hud leaked %d graphics state(s); repaired", repaired)
        end
        local ok = table.remove(result, 1)
        if not ok then error(result[1], 0) end
        return unpackCompat(result)
      end, 115000)
    end
  end

  -- Final boundary. GameViewport.finish() has completed before TouchControls,
  -- so LOVE's graphics stack is expected to be depth zero. This is only a
  -- fail-safe for a presentation leak missed above; it never lays out a scene.
  do
    if not IS_GEN2 and mod._kantoInMotionNativeMobileGen1() then
      local okTouch, TouchControls = pcall(require, "src.core.TouchControls")
      if okTouch and type(TouchControls) == "table"
          and type(TouchControls.draw) == "function"
          and not TouchControls._kantoInMotionGen1BoundaryV6 then
        local originalTouchDraw = TouchControls.draw
        TouchControls._kantoInMotionGen1BoundaryV6 = originalTouchDraw
        local warnedTouch = false
        TouchControls.draw = function(self, ...)
          local repaired = battleSystemEnabled() and mod._kantoInMotionRestoreGraphicsDepth(0) or 0
          if repaired > 0 and not warnedTouch and mod.log
              and type(mod.log.warn) == "function" then
            warnedTouch = true
            mod.log:warn(
              "Gen1 mobile repaired %d leaked graphics state(s) before TouchControls",
              repaired)
          end
          return originalTouchDraw(self, ...)
        end
      end
    end
  end


  -- Mobile battle presentation policy. Kanto in Motion keeps its desktop
  -- presentation whenever the virtual controls are hidden. When Android/iOS
  -- TouchControls are actually visible, the base battle UI yields to the
  -- source/native presenter so the d-pad and A/B buttons never sit over a
  -- second full-screen command surface. Portrait additionally uses a contained
  -- arena stage below so the landscape HD art keeps its authored aspect.
  local function touchBattleOrientation(game)
    -- The mobile battle compositor is native-mobile only. Windows handhelds
    -- can expose TouchControls too, but must stay on the desktop battle path.
    local system = love and love.system
    if not system or type(system.getOS) ~= "function" then return nil end
    local okOs, hostOs = pcall(system.getOS)
    if not okOs or (hostOs ~= "Android" and hostOs ~= "iOS") then return nil end

    local touch = game and game.touchControls
    local stack = game and game.stack
    if not touch or (stack and type(stack.touchControlsHidden) == "function"
        and stack:touchControlsHidden()) then return nil end
    if type(touch.visible) ~= "function" then return nil end
    local okVisible, visible = pcall(touch.visible, touch)
    if not okVisible or not visible then return nil end
    local g = love and love.graphics
    local w, h = 0, 0
    if g and type(g.getPixelDimensions) == "function" then
      local ok, pw, ph = pcall(g.getPixelDimensions)
      if ok then w, h = tonumber(pw) or 0, tonumber(ph) or 0 end
    end
    if not (w > 0 and h > 0) and g and type(g.getDimensions) == "function" then
      local ok, uw, uh = pcall(g.getDimensions)
      if ok then w, h = tonumber(uw) or 0, tonumber(uh) or 0 end
    end
    if not (w > 0 and h > 0) then return "landscape" end
    return h > w and "portrait" or "landscape"
  end
  mod._kantoInMotionPortraitBattleFraming = function()
    local ok, game = pcall(require, "src.core.Game")
    return ok and touchBattleOrientation(game) ~= nil
  end

  -- Mobile landscape keeps Gen1's native 48-row command/dialog strip at the
  -- bottom of the battle. OAM animation sprites (notably the player send-out
  -- POOF/Poke Ball opening) can extend a few pixels below logical row 96.
  -- KIM reconstructs that animation layer over the fullscreen arena, so those
  -- pixels would otherwise land on top of the preserved dialog frame. Clip
  -- only the native animation layer to the battlefield while the landscape
  -- touch presentation is active. The animation itself, trainer, HUD, dialog,
  -- Party and Bag paths are otherwise unchanged.
  do
    local okBattle, BattleState = pcall(require, "src.battle.BattleState")
    if okBattle and type(BattleState) == "table"
        and type(BattleState.drawAnimLayer) == "function"
        and not BattleState._kantoInMotionLandscapeAnimClip then
      local nativeDrawAnimLayer = BattleState.drawAnimLayer
      BattleState._kantoInMotionLandscapeAnimClip = nativeDrawAnimLayer
      BattleState.drawAnimLayer = function(self, ...)
        local g = love and love.graphics
        local clip = self and self._kantoInMotionBattleLite
          and touchBattleOrientation(self.game) == "landscape"
          and g and type(g.getScissor) == "function"
          and type(g.setScissor) == "function"
        if not clip then return nativeDrawAnimLayer(self, ...) end

        local oldX, oldY, oldW, oldH = g.getScissor()
        if type(g.intersectScissor) == "function" then
          g.intersectScissor(0, 0, 160, 96)
        else
          g.setScissor(0, 0, 160, 96)
        end
        local result = { pcall(nativeDrawAnimLayer, self, ...) }
        if oldX ~= nil then
          g.setScissor(oldX, oldY, oldW, oldH)
        else
          g.setScissor()
        end
        local ok = table.remove(result, 1)
        if not ok then error(result[1], 0) end
        return unpackCompat(result)
      end
    end
  end

  -- New 1920x950 HD battle arenas. The router reads the live Gen1 map/terrain/time
  -- state and chooses a complete authored sunrise/day/sunset/night image. Caves
  -- and other fixed locations stay static; there is no runtime shadow blending.
  local hdArenaRouter = not IS_GEN2 and loadTable("data/hd_battle_backgrounds.lua", true) or {}
  if type(hdArenaRouter.bindMod)=="function" then pcall(hdArenaRouter.bindMod, mod) end
  hdArenaRouter._aspectBackgrounds = not IS_GEN2
    and loadTable("data/aspect_battle_backgrounds.lua", true) or {}
  local hdArenaImageCache = {}
  local function hdArenaBackdrop(game,battle)
    if type(hdArenaRouter.resolve)~="function" then return nil end
    local ok,value=pcall(hdArenaRouter.resolve,game,battle)
    return ok and type(value)=="table" and value or nil
  end
  local function hdArenaImage(game,battle)
    local backdrop=hdArenaBackdrop(game,battle)
    local file=backdrop and backdrop.file
    if not file then return nil,backdrop end
    local path="assets/battle/backgrounds/hd/"..tostring(file)..".png"
    if not hdArenaImageCache[path] then
      local image=atlasImage(path)
      if image then hdArenaImageCache[path]=image end
    end
    return hdArenaImageCache[path] or nil,backdrop
  end
  -- Keep just the active complete arena in GPU memory. Packaged aspect art
  -- bypasses the unbounded atlas cache and does not need the HD asset download.
  local aspectArenaCache = {}
  local function aspectArenaImage(backdrop,vw,vh)
    local A=hdArenaRouter._aspectBackgrounds
    if type(A.path)~="function" or not backdrop then return nil end
    local path=A.path(backdrop.file,vw,vh)
    if not path then return nil end
    if aspectArenaCache.path==path then return aspectArenaCache.image end
    local bytes=mod._kimAssetProvider.read(path)
    if type(bytes)~="string" or #bytes==0 then return nil end
    local g,fs=love and love.graphics,love and love.filesystem
    if not (g and g.newImage and fs and fs.newFileData) then return nil end
    local ok,image=pcall(function()
      return g.newImage(fs.newFileData(bytes,path))
    end)
    if not ok or not image then return nil end
    if image.setFilter then pcall(image.setFilter,image,"linear","linear") end
    local old=aspectArenaCache.image
    aspectArenaCache={path=path,image=image}
    if old and old.release then pcall(old.release,old) end
    return image
  end
  -- HD backgrounds are authored at 1920x950 while common desktop play is
  -- 1920x1080 (and 4:3 is taller still relative to the source artwork).  The
  -- user-approved v8.6.4 enemy placement now looks correct, but the field
  -- itself still wants a hair more lift.  Nudge only the KRS scenery upward a
  -- little further while compensating the battler anchors so player/enemy stay
  -- at the accepted on-screen heights.
  local HD_STAGE_LIFT_PX = 172
  local HD_PLAYER_Y_COMPENSATE_PX = 60
  local HD_ENEMY_EXTRA_LIFT_PX = 8
  -- The HD enemy stance point was tuned at 16:9. On 4:3 the cover-scaled
  -- 1920x950 arena crops heavily at the sides, leaving larger enemy sprites
  -- uncomfortably close to the right edge. Preserve the accepted widescreen
  -- placement, then ease the enemy left only once the viewport becomes
  -- narrower than 3:2. At 4:3 (and narrower) the correction tops out at 72px.
  local HD_ENEMY_NARROW_SHIFT_PX = 72
  -- SCREEN POS (CENTER / UPPER / TOP) shifts Gen1Recomp's native 160x144
  -- presentation upward inside unused vertical space. Renderer.worldOverride
  -- itself always fills the playfield, so a custom HD scene has to apply
  -- that same physical-pixel lift to its contained content explicitly. This is
  -- active only while mobile touch controls are visible; desktop layouts keep
  -- their already-tuned placement.
  local function mobileScreenPositionLiftPx(game,vw,vh)
    if not touchBattleOrientation(game) then return 0 end
    local okSp,ScreenPosition=pcall(require,"src.core.ScreenPosition")
    if not okSp or not ScreenPosition or type(ScreenPosition.lift)~="function" then
      return 0
    end
    if type(ScreenPosition.skinActive)=="function" then
      local okSkin,skin=pcall(ScreenPosition.skinActive)
      if okSkin and skin then return 0 end
    end
    local s=math.max(1,math.floor(math.min((tonumber(vw) or 160)/160,
      (tonumber(vh) or 144)/144)))
    local dpiY=1
    if love and love.graphics and type(love.graphics.getDimensions)=="function"
        and type(love.graphics.getPixelDimensions)=="function" then
      local okU,_,uh=pcall(love.graphics.getDimensions)
      local okP,_,ph=pcall(love.graphics.getPixelDimensions)
      if okU and okP and tonumber(uh) and tonumber(ph) and uh>0 and ph>0 then
        dpiY=ph/uh
      end
    end
    local safe=0
    if type(ScreenPosition.safeTop)=="function" then
      local ok,value=pcall(ScreenPosition.safeTop)
      if ok then safe=(tonumber(value) or 0)*dpiY end
    end
    local ok,value=pcall(ScreenPosition.lift,vh,144*s,safe)
    return ok and math.max(0,tonumber(value) or 0) or 0
  end

  -- Physical-pixel rectangle occupied by the contained 1920x950 battlefield
  -- on a portrait touch layout. Every portrait-only screen-space element uses
  -- this same rectangle so the arena, trainer, HUD and native text can be
  -- stacked without overlapping the Pokemon.
  local function mobilePortraitStageRectPx(game,vw,vh)
    if touchBattleOrientation(game)~="portrait" then return nil end
    vw,vh=tonumber(vw) or 0,tonumber(vh) or 0
    if not (vw>0 and vh>0) then return nil end
    local aspect=1920/950
    local stageW=vw
    local stageH=stageW/aspect
    if stageH>vh then stageH=vh; stageW=stageH*aspect end
    local lift=mobileScreenPositionLiftPx(game,vw,vh)
    local x=(vw-stageW)*0.5
    local y=(vh-stageH)*0.5-lift
    return {x=x,y=y,width=stageW,height=stageH,bottom=y+stageH,lift=lift}
  end

  local function hdEnemyNarrowShift(vw,vh)
    vw, vh = tonumber(vw) or 0, tonumber(vh) or 0
    if not (vw>0 and vh>0) then return 0 end
    local aspect=vw/vh
    local startAspect=3/2
    local fullAspect=4/3
    if aspect>=startAspect then return 0 end
    if aspect<=fullAspect then return HD_ENEMY_NARROW_SHIFT_PX end
    local t=(startAspect-aspect)/(startAspect-fullAspect)
    return HD_ENEMY_NARROW_SHIFT_PX*math.max(0,math.min(1,t))
  end
  local function hdArenaTransform(vw,vh,contain)
    if contain then
      local scale=math.min(vw/1920,vh/950)
      if not (scale>0) then scale=1 end
      return {
        x=(vw-1920*scale)*0.5, y=(vh-950*scale)*0.5,
        r=0,sx=scale,sy=scale,ox=0,oy=0,kx=0,ky=0,scale=scale,
        contained=true,
      }
    end
    local scale=math.max(vw/1920,vh/950)
    return {x=(vw-1920*scale)*0.5,y=(vh-950*scale)*0.5-HD_STAGE_LIFT_PX,r=0,sx=scale,sy=scale,ox=0,oy=0,kx=0,ky=0,scale=scale}
  end
  local function hdArenaGroundGeometry(game,battle,vw,vh,pixelScale)
    local image,backdrop=hdArenaImage(game,battle)
    if not image then return nil,nil,nil end
    local anchors=type(hdArenaRouter.groundAnchors)=="function" and hdArenaRouter.groundAnchors(backdrop) or nil
    if type(anchors)~="table" then return nil,nil,nil end
    local portraitTouch=touchBattleOrientation(game)=="portrait"
    local t=hdArenaTransform(vw,vh,portraitTouch)
    if portraitTouch then
      t.y=t.y-mobileScreenPositionLiftPx(game,vw,vh)
    end
    -- The desktop compensation values were tuned in final pixels. Scale them
    -- down with a contained portrait stage instead of letting a 60px desktop
    -- nudge become a huge fraction of a phone-width battlefield.
    local mobileTouch=touchBattleOrientation(game)~=nil
    local compScale=mobileTouch and math.min(1,t.scale) or 1
    local enemyShift=portraitTouch and 0 or hdEnemyNarrowShift(vw,vh)
    return {
      pixelScale=pixelScale,
      playerX=t.x+(anchors.player.x or 630)*t.scale,
      playerY=t.y+(anchors.player.y or 704)*t.scale
        +HD_PLAYER_Y_COMPENSATE_PX*(mobileTouch and 0 or compScale),
      enemyX=t.x+(anchors.enemy.x or 1400)*t.scale-enemyShift,
      enemyY=t.y+(anchors.enemy.y or 484)*t.scale
        -HD_ENEMY_EXTRA_LIFT_PX*compScale,
      hd=true,hdScale=t.scale,hdTransform=t,hdBackdrop=backdrop,
      mobilePortrait=portraitTouch,
    },image,backdrop
  end
  -- Full-window 2D host for the authored HD battle scene.
  -- Renderer:setWorldOverride is Gen1Recomp's final-world compositor seam for
  -- an alternate battle arena; this canvas contains the authored HD image.
  local flatBattleWorldCanvas = nil
  mod._kantoInMotionFlatWorldOrientation = (assert(load(assert(
    mod:read("lib/flat_world_orientation.lua")),
    "@" .. mod.path .. "/lib/flat_world_orientation.lua")))()()

  -- Quality of Life draws its EXP bar and caught/Pokedex marker directly into
  -- dramaticShapeShot.canvas. KIM keeps QOL source-owned, then translates only
  -- those tiny final primitives when the visible HUD geometry differs from
  -- QOL's source coordinates. EXP follows the live player-band row. The caught
  -- marker is decoded relative to QOL's name-dependent source anchor and replayed
  -- at one fixed enemy-HUD anchor, matching the confirmed staged-3D behavior.
  local qolXpCompat = { active = false }
  local qolCompatHandle = nil

  local function qolCompatOption(game, key)
    if not qolCompatHandle and type(mod.find) == "function" then
      local ok, handle = pcall(mod.find, mod, "quality_of_life")
      if not ok or not handle then ok, handle = pcall(mod.find, "quality_of_life") end
      if ok then qolCompatHandle = handle end
    end
    local exports = qolCompatHandle and type(qolCompatHandle.exports) == "table"
      and qolCompatHandle.exports or nil
    if exports and type(exports.optionValue) == "function" then
      local ok, value = pcall(exports.optionValue, game, key)
      if ok then return value end
    end
    return nil
  end

  local function qolCompatEnemyNameX(battle)
    local name = battle and battle.enemy and battle.enemy.name or ""
    local glyphs = #tostring(name)
    local Font = mod and mod.ui and mod.ui.Font
    if Font and type(Font.split) == "function" then
      local ok, parts = pcall(Font.split, tostring(name))
      if ok and type(parts) == "table" then glyphs = #parts end
    end
    return 8 + (glyphs <= 2 and 16 or glyphs <= 4 and 8 or 0)
  end
  local function installQolXpRectangleCompat()
    local g = love and love.graphics
    if not (g and type(g.rectangle) == "function") or g._kantoInMotionQolXpCompat then
      return
    end
    local nativeRectangle = g.rectangle
    g._kantoInMotionQolXpCompat = nativeRectangle
    g.rectangle = function(mode, x, y, w, h, ...)
      local c = qolXpCompat
      if (c.active or c.caughtActive) and mode == "fill" and c.canvas
          and g.getCanvas and g.getCanvas() == c.canvas then
        local nx, ny, nw, nh = tonumber(x), tonumber(y), tonumber(w), tonumber(h)
        if nx and ny and nw and nh then
          -- Desktop KIM / 3D-BTL-OFF caught indicator. QOL's source X follows
          -- the enemy-name centering rule, so a simple fixed X shift still lets
          -- short names (ABRA/MEW/etc.) move the final icon. Decode each source
          -- pixel relative to QOL's dynamic anchor, then replay it at the same
          -- fixed enemy-band +8/+9 anchor used by the confirmed 3D bridges.
          if c.caughtActive and c.battle and c.battle.kind == "wild"
              and math.abs(nw - c.scale) < 0.51
              and math.abs(nh - c.scale) < 0.51 then
            local caughtMode = qolCompatOption(c.battle.game or c.game,
              "qol_caught_indicator")
            if caughtMode == "gen2" or caughtMode == "red" or caughtMode == "grey" then
              local sourceAnchorX = (qolCompatEnemyNameX(c.battle) - 9) * c.scale
              local sourceAnchorY = (c.ly or 0) + 7 * c.scale
              if caughtMode == "gen2" then
                sourceAnchorX = sourceAnchorX + 2 * c.scale
                sourceAnchorY = sourceAnchorY + 2 * c.scale
              else
                sourceAnchorX = sourceAnchorX + c.scale
                sourceAnchorY = sourceAnchorY + c.scale
              end
              local side = caughtMode == "gen2" and 6 or 7
              local ux = (nx - sourceAnchorX) / c.scale
              local uy = (ny - sourceAnchorY) / c.scale
              if ux >= -0.01 and ux <= side - 1 + 0.01
                  and uy >= -0.01 and uy <= side - 1 + 0.01
                  and c.enemyBandX and c.enemyBandY then
                local targetAnchor = caughtMode == "gen2" and 9 or 8
                local tx = c.enemyBandX + (targetAnchor + ux) * c.scale
                local ty = c.enemyBandY + (targetAnchor + uy) * c.scale
                return nativeRectangle(mode, tx, ty, nw, nh, ...)
              end
            end
          end

          if c.active and nx >= (c.minX or 0) then
            -- Main QOL EXP fill: exactly 2 logical pixels tall.
            if math.abs(ny - c.baseY) < 0.51
                and math.abs(nh - 2 * c.scale) < 0.51 then
              y = ny + c.shiftY
            -- Level-up burst particles are 1 logical pixel blocks expanded by
            -- the same scale. Shift those with the bar so the celebration stays
            -- attached to it in SCALED/portrait compatibility mode.
            elseif math.abs(nw - c.scale) < 0.51
                and math.abs(nh - c.scale) < 0.51
                and ny >= c.baseY - 24 * c.scale
                and ny <= c.baseY + 24 * c.scale then
              y = ny + c.shiftY
            end
          end
        end
      end
      return nativeRectangle(mode, x, y, w, h, ...)
    end
  end
  installQolXpRectangleCompat()


  local function ensureBattleCanvas(canvas, w, h, filter)
    if canvas and canvas:getWidth() == w and canvas:getHeight() == h then return canvas end
    local ok, fresh = pcall(love.graphics.newCanvas, w, h, { dpiscale = 1 })
    if not ok or not fresh then return nil end
    if fresh.setFilter then pcall(fresh.setFilter, fresh, filter or "nearest", filter or "nearest") end
    return fresh
  end

  -- Renderer:setWorldOverride consumes a *physical-pixel* image. Desktop has
  -- historically hidden that contract because window units and framebuffer
  -- pixels are normally 1:1 there. Android/iOS high-DPI windows are not: a
  -- 1800px-wide phone can report only ~640 LOVE units. A dpiscale=1 canvas
  -- sized with love.graphics.getDimensions() therefore covers only ~1/DPI of
  -- the phone when Renderer:endFrame performs its documented 1/dpi blit.
  --
  -- Mirror Gen1Recomp 0.2.38 Renderer.displayMetrics here: start from the live
  -- framebuffer size and then honor Playfield's TouchSkin cutout. The returned
  -- width/height are the exact pixel dimensions worldOverride must own; x/y
  -- and dpi let screen-space consumers translate a world-canvas edge back to
  -- LOVE units when needed (the KRS footer handoff below).
  local function battleWorldMetrics()
    local g = love and love.graphics
    if not g then return nil end

    -- Renderer.displayMetrics starts from GameViewport, not directly from the
    -- OS window. This distinction matters on Android when SCREEN LOCATION or
    -- another layout provider captures/moves the game rectangle: the HUD was
    -- already drawing in GameViewport-local coordinates, while KIM's physical
    -- worldOverride was still being sized from the full phone framebuffer.
    -- Mirror the renderer contract exactly so arena, battlers and HUD all move
    -- as one presentation.
    local uw, uh, pw, ph
    local okViewport, GameViewport = pcall(require, "src.render.GameViewport")
    if okViewport and GameViewport then
      if type(GameViewport.dimensions) == "function" then
        local ok, w, h = pcall(GameViewport.dimensions)
        if ok then uw, uh = tonumber(w), tonumber(h) end
      end
      if type(GameViewport.pixelDimensions) == "function" then
        local ok, w, h = pcall(GameViewport.pixelDimensions)
        if ok then pw, ph = tonumber(w), tonumber(h) end
      end
    end
    if not (uw and uh and uw > 0 and uh > 0) and type(g.getDimensions) == "function" then
      local ok, w, h = pcall(g.getDimensions)
      if ok then uw, uh = tonumber(w), tonumber(h) end
    end
    uw, uh = math.max(1, uw or 1), math.max(1, uh or 1)
    if not (pw and ph and pw > 0 and ph > 0) and type(g.getPixelDimensions) == "function" then
      local ok, w, h = pcall(g.getPixelDimensions)
      if ok then pw, ph = tonumber(w), tonumber(h) end
    end
    pw, ph = math.max(1, math.floor((pw or uw) + 0.5)),
      math.max(1, math.floor((ph or uh) + 0.5))
    local dpiX = pw / uw
    local dpiY = ph / uh
    if not (dpiX > 1e-6) then dpiX = 1 end
    if not (dpiY > 1e-6) then dpiY = 1 end

    local vx, vy, vw, vh = 0, 0, pw, ph
    local okPlayfield, Playfield = pcall(require, "src.render.Playfield")
    if okPlayfield and Playfield and type(Playfield.cutout) == "function" then
      local ok, x, y, w, h = pcall(Playfield.cutout, pw, ph)
      if ok and tonumber(x) and tonumber(y) and tonumber(w) and tonumber(h)
          and w > 0 and h > 0 then
        vx, vy = math.floor(x + 0.5), math.floor(y + 0.5)
        vw, vh = math.max(1, math.floor(w + 0.5)), math.max(1, math.floor(h + 0.5))
      end
    end
    return {
      width = vw, height = vh, pixelWidth = pw, pixelHeight = ph,
      x = vx, y = vy, dpiX = dpiX, dpiY = dpiY,
      unitX = vx / dpiX, unitY = vy / dpiY,
      unitWidth = vw / dpiX, unitHeight = vh / dpiY,
    }
  end

  -- Recreate the final native 160x144 battle placement in physical pixels.
  -- drawNativeBattleOverlay uses the same layout in LOVE units; this version
  -- is used by the worldOverride background compositor so the HD ground
  -- anchors and native battler feet resolve to the same final coordinates.
  local function nativeBattlePlacementPx(game, vw, vh)
    vw, vh = tonumber(vw) or 160, tonumber(vh) or 144
    local metrics = battleWorldMetrics()
    local dpiX = metrics and tonumber(metrics.dpiX) or 1
    local dpiY = metrics and tonumber(metrics.dpiY) or 1
    if not (dpiX > 1e-6) then dpiX = 1 end
    if not (dpiY > 1e-6) then dpiY = 1 end
    local uw, uh = vw / dpiX, vh / dpiY
    local orient = touchBattleOrientation(game)
    local x, y, scale

    if orient == "portrait" then
      local aspect = 1920 / 950
      local stageW, stageH = uw, uw / aspect
      if stageH > uh then stageH = uh; stageW = stageH * aspect end
      local lift = mobileScreenPositionLiftPx(game, vw, vh) / dpiY
      local stageX = (uw - stageW) * 0.5
      local stageY = (uh - stageH) * 0.5 - lift
      scale = math.max(1, math.floor(math.min(stageW / 160, stageH / 144)))
      x = stageX + (stageW - 160 * scale) * 0.5
      y = stageY + (stageH - 144 * scale) * 0.5
    else
      scale = math.max(1, math.floor(math.min(uw / 160, uh / 144)))
      local lift = mobileScreenPositionLiftPx(game, vw, vh) / dpiY
      x = (uw - 160 * scale) * 0.5
      y = uh * 0.055 - lift
    end

    return {
      x = x * dpiX, y = y * dpiY,
      sx = scale * dpiX, sy = scale * dpiY,
      width = 160 * scale * dpiX, height = 144 * scale * dpiY,
    }
  end

  local function nativeFitHdTransform(game, battle, image, backdrop, vw, vh)
    if not (image and backdrop and type(hdArenaRouter.groundAnchors) == "function") then
      return nil
    end
    local okAnchors, anchors = pcall(hdArenaRouter.groundAnchors, backdrop)
    if not okAnchors or type(anchors) ~= "table" then return nil end
    local okDims, iw, ih = pcall(function() return image:getWidth(), image:getHeight() end)
    if not okDims or not iw or not ih or iw <= 0 or ih <= 0 then return nil end

    local place = nativeBattlePlacementPx(game, vw, vh)
    local p = anchors.player or {}
    local e = anchors.enemy or {}
    local pSrcX = (tonumber(p.x) or 630) * iw / 1920
    local pSrcY = (tonumber(p.y) or 704) * ih / 950
    local eSrcX = (tonumber(e.x) or 1400) * iw / 1920
    local eSrcY = (tonumber(e.y) or 484) * ih / 950
    local dx, dy = eSrcX - pSrcX, eSrcY - pSrcY
    if math.abs(dx) < 1e-6 or math.abs(dy) < 1e-6 then return nil end

    -- Native Gen 1 battler ground-contact points used by BattleState.
    local pDstX = place.x + 26 * place.sx
    local pDstY = place.y + 110 * place.sy
    local eDstX = place.x + 124 * place.sx
    local eDstY = place.y + 65 * place.sy
    local sx = (eDstX - pDstX) / dx
    local sy = (eDstY - pDstY) / dy
    -- Keep the exact two-anchor platform alignment, but do not crop the HD
    -- artwork down to the narrow 160x144 Gen 1 battle rectangle.  Vanilla
    -- battlers still use that centered 160x144 coordinate space; the scenery
    -- gets an FR/LG-style 240x160 viewing window around it so substantially
    -- more of the authored field remains visible without moving either pad.
    local clipX = place.x - 40 * place.sx
    local clipY = place.y - 8 * place.sy
    local clipW = place.width + 80 * place.sx
    local clipH = place.height + 16 * place.sy
    local clipR = math.min(vw, clipX + clipW)
    local clipB = math.min(vh, clipY + clipH)
    clipX = math.max(0, clipX)
    clipY = math.max(0, clipY)
    clipW = math.max(1, clipR - clipX)
    clipH = math.max(1, clipB - clipY)

    -- v33 calibration: v32 was very close but the authored pads still sat a
    -- little low against the real vanilla battlers. Lift NATIVE FIT by ten
    -- native battle pixels total (two more than v32). Keep the wider crop,
    -- scale, and vanilla sprite coordinates unchanged.
    local nativeBgLift = 10 * place.sy

    return {
      x = pDstX - pSrcX * sx,
      y = pDstY - pSrcY * sy - nativeBgLift,
      sx = sx, sy = sy,
      clipX = clipX, clipY = clipY,
      clipW = clipW, clipH = clipH,
    }
  end

  -- One geometry contract is shared by Kanto in Motion's snapped HP HUD and
  -- third-party battle overlays. Quality of Life already consumes
  -- battle.dramaticShapeShot for its EXP bar and caught/Pokedex indicator, so
  -- publishing this table lets QOL follow KIM without changing QOL itself.
  -- `scale` intentionally follows the selected HUD scale here: OG uses the
  -- full integer window fit; SCALED uses the compact one-rung-smaller fit.
  local function battleHudGeometry(vw, vh, liftPx, game)
    local s = math.max(1, math.floor(math.min(vw / 160, vh / 144)))
    -- Preserve the established flat-shot snap rectangle geometry:
    -- OG uses the window-fit rung; SCALED is one integer rung smaller.
    local baseHs = (mod.options:get("battleHudScale") == "scaled")
      and math.max(1, s - 1) or s
    local hudSize = math.max(0.60, math.min(1.00,
      (tonumber(mod.options:get("battleHudSize")) or 100) / 100))
    local hs = baseHs * hudSize
    local lx = math.floor((vw - 160 * s) * 0.5)
    local ly = math.floor((vh - 144 * s) * 0.5) - math.floor(tonumber(liftPx) or 0)
    local enemyRect = { 8, 0, 80, 32 }
    local playerRect = { 72, 56, 88, 40 }
    local playerBandTop = 48
    -- Keep the enemy HP/status band slightly inset from the left screen edge.
    -- The old anchor made the first visible HUD pixel land at logical X=2,
    -- which is visibly cramped on mobile across normal KIM, Battle Art and
    -- PotatoVoxel. Use X=6 for a modest universal inset while preserving all
    -- HUD size/scale relationships.
    local enemyHudVisibleInset = 6
    local enemyBandX = (enemyHudVisibleInset - enemyRect[1]) * hs
    local playerBandX = vw - (playerRect[1] + playerRect[3]) * hs
    local playerBandY = ly + playerRect[2] * s
      - (playerRect[2] - playerBandTop) * hs
    local portraitStage=mobilePortraitStageRectPx(game,vw,vh)
    if portraitStage then
      -- Mobile portrait reference (Screenshot_20260829_173258.png): keep the
      -- player/Charizard HP band inside the lower-right of the contained
      -- battlefield rather than stacking it in the black space underneath.
      -- v8.6.30 got the dialog edge right but left this band too close to it.
      -- Lift the complete player band another 8 HUD rows while leaving the
      -- accepted dialog and battlefield geometry completely unchanged.
      playerBandY=math.floor(portraitStage.bottom-44*hs+0.5)
      playerBandY=math.max(0,math.min(vh-48*hs,playerBandY))
    end
    return {
      battleScale = s,
      hudScale = hs,
      lx = lx,
      ly = ly,
      enemyBandX = enemyBandX,
      playerBandX = playerBandX,
      enemyBandY = ly,
      playerBandY = playerBandY,
      portraitStage = portraitStage,
    }
  end

  -- Native-resolution fullscreen battlers. Avoid scaling a
  -- Pokemon down into the 160x144 UI and then scaling that UI back up; KIM now
  -- follows the same principle. One atlas frame is drawn directly onto the
  -- window-resolution world canvas with nearest filtering. At 1080p the
  -- old low-resolution stage rung was 6x; HD sheets now use scene-relative scale.
  mod._kimAutoPlayerSize = assert((loadstring or load)(assert(mod:read("lib/auto_player_size.lua")),
    "@" .. mod.path .. "/lib/auto_player_size.lua"))()

  local function directStageGeometry(vw, vh, game, battle)
    local fit = math.max(1, math.floor(math.min(vw / 160, vh / 144)))
    local stage = math.max(1, fit - 1)
    local lx = math.floor((vw - 160 * stage) * 0.5)
    local touchOrientation=touchBattleOrientation(game)
    local portraitTouch=touchOrientation=="portrait"
    local pixelScale = math.max(1, math.floor(stage * 2 / 3 + 0.5))
    if portraitTouch then
      -- Match the accepted HD sample-test portrait rung.
      pixelScale=math.max(1,math.floor(4*(vw/1920)+0.5))
    end

    local playerPixelScale=pixelScale
    if touchOrientation=="landscape" then
      local world=battleWorldMetrics()
      local fullW=world and tonumber(world.pixelWidth) or vw
      local authored=math.max(1,math.floor(4*(fullW/1920)+0.5))
      playerPixelScale=math.max(pixelScale,math.min(stage,authored))
    end

    if hdBattleBackgroundsEnabled() then
      local geo=hdArenaGroundGeometry(game,battle,vw,vh,pixelScale)
      if geo then
        -- Background geometry and battler pixel scale are intentionally
        -- independent. This was the key behavior in the accepted test build:
        -- the 1920x950 art chooses anchors, while Pokemon keep the BattleState
        -- pixel rung plus their per-species displayScale.
        geo.viewportWidth,geo.viewportHeight=vw,vh
        geo.playerPixelScale=playerPixelScale
        return geo
      end
    end

    return {
      scale = stage, pixelScale = pixelScale, playerPixelScale = playerPixelScale,
      lx = lx, ly = 0,
      playerX = lx + 26 * stage, playerY = 110 * stage,
      enemyX = lx + 124 * stage, enemyY = 65 * stage,
    }
  end

  local function battlerGrow(battle, battler)
    if not (battle and battler and type(battle.growInScale) == "function") then
      return 1
    end
    local ok, grow = pcall(battle.growInScale, battle, battler)
    grow = ok and tonumber(grow) or nil
    if grow == nil then return 1 end
    return math.max(0, math.min(1, grow))
  end

  -- Resolve live fallback art through the active game's pic provider. Restrict
  -- this to the mobile portrait flat scene, where native slots do not match
  -- the width-contained HD pads. The same resolver gates source suppression.
  mod._kantoInMotionFlatNativeFrame = function(battle, side)
    local nativePlayer = not battleLiteDirectStageActive() and (side == "player" or side == "enemy") and battleLiteFullScreenActive()
      and battleBackgroundMode() == "native" and touchBattleOrientation(battle and battle.game) == nil
    if not (battle and (battleLiteDirectStageActive() or nativePlayer)
        and hdBattleBackgroundsEnabled()) then return nil end
    if side == "player" and (battle.showPlayerBack or battle.sendingOut
        or battle.safari or battle.demo) then return nil end
    if side == "enemy" and (battle.showEnemyTrainer or battle.enemySendingOut
        or battle.enemyHidden) then return nil end
    if not hdArenaImage(battle.game, battle) then return nil end
    local provided, managed, layout
    if mod._kimBattlePicProvider then
      local trimPlayer = touchBattleOrientation(battle.game) == nil and (side == "player" or nativePlayer)
      provided, managed, layout = mod._kimBattlePicProvider.resolve(battle, side, nil, trimPlayer)
    end
    if managed then return provided, true, layout end
    local battler = battle[side]
    if not (battler and battler.sprite) then return nil end
    local image = battler.sprite
    if type(battle.picImage) == "function" then
      local ok, resolved = pcall(battle.picImage, battle, image)
      if not ok then return nil end
      image = resolved
    end
    if not (image and type(image.getDimensions) == "function") then return nil end
    local ok, w, h = pcall(image.getDimensions, image)
    if not (ok and w and h and w > 1 and h > 1) then return nil end
    return image
  end

  local function directSideMetrics(battle, side, geo)
    local battler = battle and battle[side]
    local mon = battler and battler.mon
    if not mon then return nil end
    local view = side == "enemy" and "front" or "back"
    local record, generation, species, shiny = battleRecord(mon.species, view, mon)
    local frame, providerManaged, spriteLayout
    local nativeFallback = false
    if geo.hd then
      frame, providerManaged, spriteLayout = mod._kantoInMotionFlatNativeFrame(battle, side)
    end
    if providerManaged then
      -- Includes a pending provider: no image until its custom sheet is ready.
      record = { displayScale = 1 }
      nativeFallback = true
    elseif not record and frame then
      record = { displayScale = 1 }
      nativeFallback = true
    elseif record then
      frame = renderPresentationFrame(record, generation, species,
        nil, view, shiny and "shiny" or "normal", true)
    end
    if not frame then return nil end
    if frame.setFilter then pcall(frame.setFilter, frame, "nearest", "nearest") end

    local basePixelScale = side == "player"
      and (tonumber(geo.playerPixelScale) or geo.pixelScale) or geo.pixelScale
    local scale = basePixelScale * battlerGrow(battle, battler)
    if side == "player" then
      local pct = tonumber(mod.options:get("battlePlayerSize")) or 100
      pct = math.max(50, math.min(200, pct))
      -- Desktop HD replay uses the provider's pixels at the scene rung.
      -- Desktop uses the explicit menu percentage independently of retired
      -- KIM size settings; mobile retains its calibrated presentation.
      if not geo.hd or touchBattleOrientation(battle.game) ~= nil then
        scale = scale * 1.15 * pct / 100
      else
        local desktopPct = tonumber(mod.options:get("desktopPlayerSizeV2")) or 100
        scale = scale * 1.3 * math.max(50, math.min(200, desktopPct)) / 100
      end
    else
      local pct = tonumber(mod.options:get("battleEnemySize")) or 100
      pct = math.max(50, math.min(200, pct))
      scale = scale * 1.25 * pct / 100
      if touchBattleOrientation(battle.game) == nil then
        local desktopPct = tonumber(mod.options:get("desktopEnemySize")) or 100
        scale = scale * math.max(50, math.min(200, desktopPct)) / 100
      end
    end
    scale = scale * (tonumber(record.displayScale) or 1)
    local w, h = frame:getDimensions()
    local ax = side == "enemy" and geo.enemyX or geo.playerX
    local ay = side == "enemy" and geo.enemyY or geo.playerY
    local groundPx = shinyGroundOffset(generation, view, species, shiny)
    local groundShift = groundPx * scale
    local result = {
      nativeFallback=nativeFallback,
      battler=battler, mon=mon, record=record, generation=generation,
      species=species, shiny=shiny, frame=frame, scale=scale, w=w, h=h,
      ax=ax, ay=ay, groundPx=groundPx, groundShift=groundShift,
      x=ax - w * scale * 0.5,
      y=ay - h * scale + groundShift,
      centerX=ax,
      centerY=ay - h * scale * 0.5 + groundShift,
    }
    if side == "player" and geo.hd and touchBattleOrientation(battle.game) == nil
        and mod.options:get("desktopPlayerSizeV2") == "auto"
        and mod._kimAutoPlayerSize and geo.viewportWidth and geo.viewportHeight then
      local bounds = spriteLayout
      if not bounds and not providerManaged and record.image then
        local entry = cacheEntry(record, generation, species)
        if entry then
          bounds = mod._kimAutoPlayerSize.measure(entry.atlas, w, h,
            entry.columns, tonumber(record.frames) or 1)
        end
      end
      -- Natural 1025Dex metadata already describes its whole trimmed loop.
      -- ROM/static or older providers may still return padded picture boxes:
      -- measure their opaque pixels instead of counting that invisible space.
      bounds = bounds or mod._kimAutoPlayerSize.measure(frame,w,h)
      local hud = battleHudGeometry(geo.viewportWidth, geo.viewportHeight)
      local hs = hud.hudScale
      local fitted = mod._kimAutoPlayerSize.fit(bounds, ax, ay,
        geo.viewportWidth, geo.viewportHeight, {
          {x=hud.enemyBandX+8*hs,y=hud.enemyBandY,w=112*hs,h=32*hs},
          {x=hud.playerBandX+72*hs,y=hud.playerBandY+8*hs,w=88*hs,h=40*hs},
        }, battlerGrow(battle,battler))
      if fitted then for key,value in pairs(fitted) do result[key]=value end end
    end
    return result
  end

  -- Live integrated KRBA session. The original 1.3.7 full-window battle
  -- compositor used this exact handoff so BG/FG planes, particles and battler
  -- transforms share one timing source.
  local function activeKrbaSession(battle)
    local fn=mod.exports and mod.exports._kantoInMotionKRBAActiveSession
    if type(fn)~="function" then return nil end
    local ok,value=pcall(fn)
    if not ok then return nil end

    -- The KRBA session snapshots the real attacker side at AnimPlayer:start.
    -- Keep that session-owned value authoritative. BattleState's transient
    -- animAttackerIsPlayer flag can lag the direct session during final-window
    -- reconstruction, which can invert enemy USER/TARGET ownership (Growl,
    -- Quick Attack, Fury Attack, etc.). A completed session is never drawable.
    if type(value)=="table" and value.done then return nil end
    return value
  end

  local function directSideVisible(battle, side)
    local battler = battle and battle[side]
    local mon = battler and battler.mon
    if not mon then return false end
    local fxHidden = false
    if type(battle.fxHidden) == "function" then
      local ok, hidden = pcall(battle.fxHidden, battle, battler)
      fxHidden = ok and hidden == true
    end
    if side == "enemy" then
      return not (battle.showEnemyTrainer or battle.enemyHidden or battle.enemySendingOut
        or battler.fainted or fxHidden)
    end
    return not (battle.showPlayerBack or battle.safari or battle.demo or battle.sendingOut
      or battler.fainted or fxHidden)
  end

  local function drawDirectSide(battle, side, geo)
    local battler = battle and battle[side]
    local mon = battler and battler.mon
    if not mon or not directSideVisible(battle, side) then return false end

    local metrics = directSideMetrics(battle, side, geo)
    if not metrics then return false end
    local frame, scale = metrics.frame, metrics.scale
    if scale <= 0 then return true end
    local ax, ay = metrics.ax, metrics.ay
    local x = math.floor(metrics.x + 0.5)
    local y = math.floor(metrics.y + 0.5)
    local transform=nil
    if geo.hd or geo.kimWide or geo.krs then
      local sess=activeKrbaSession(battle)
      if sess and type(sess.battlerTransformWide)=="function" then
        local ok,value=pcall(sess.battlerTransformWide,sess,side)
        if ok and type(value)=="table" then transform=value end
      end
    end
    if transform and transform.visible==false then return true end

    love.graphics.setShader()
    love.graphics.push("all")

    -- Shadows remain grounded at the authored contact point. The sprite itself
    -- then receives the move's USER/TARGET transform just like KIM 1.3.7.
    love.graphics.setColor(1,1,1,1)
    if mod._kantoInMotionBattlerShadows
        and type(mod._kantoInMotionBattlerShadows.drawDirect) == "function" then
      pcall(mod._kantoInMotionBattlerShadows.drawDirect,
        mod._kantoInMotionBattlerShadows, metrics, side, 1)
    end

    local alpha=transform and (tonumber(transform.opacity) or 1) or 1
    love.graphics.setColor(1,1,1,alpha)
    if transform then
      local k=geo.hdScale or geo.krsScale or geo.krbaScale or 1
      local dx=(tonumber(transform.dx) or 0)*k
      local dy=(tonumber(transform.dy) or 0)*k
      local sx=tonumber(transform.scaleX) or 1
      local sy=tonumber(transform.scaleY) or 1
      if transform.mirror then sx=-sx end
      love.graphics.translate(ax+dx,ay+dy)
      love.graphics.rotate(tonumber(transform.rotation) or 0)
      love.graphics.scale(sx,sy)
      love.graphics.translate(-ax,-ay)
    end
    love.graphics.draw(frame,x,y,0,scale,scale)
    love.graphics.pop()
    return true
  end

  -- A mobile HD intro uses the same player platform as the Pokemon. Resolve
  -- the live trainer first so the source slot is hidden only when a drawable
  -- can actually be reconstructed. ROM/default and sprites-OFF retain their
  -- native art provider; Safari/demo and external stages keep their own path.
  mod._kantoInMotionFlatTrainerFrame = function(battle)
    if not (battle and battle.showPlayerBack and not battle.fieldCleared
        and not battle.safari and not battle.demo
        and battleLiteFullScreenActive() and hdBattleBackgroundsEnabled()
        and hdArenaImage(battle.game, battle)) then return nil end
    local frame
    do
      local getter = mod.exports and mod.exports._kantoInMotionBattleTrainerFrame
      if type(getter) == "function" then
        local ok, selected = pcall(getter, battle)
        if ok then frame = selected end
      end
    end
    if not frame then
      frame = battle.playerBackPic
      if frame and type(battle.picImage) == "function" then
        local ok, resolved = pcall(battle.picImage, battle, frame)
        if not ok then return nil end
        frame = resolved
      end
    end
    if not (frame and type(frame.getDimensions) == "function") then return nil end
    local ok, w, h = pcall(frame.getDimensions, frame)
    if not (ok and w and h and w > 1 and h > 1) then return nil end
    return frame
  end

  local function drawDirectBattleTrainer(battle, geo, game, vw, vh)
    if not (battle and geo and battleLiteFullScreenActive()
        and battle.showPlayerBack and not battle.fieldCleared
        and not battle.safari and not battle.demo) then return false end
    local orientation = touchBattleOrientation(game)
    local mobile = orientation ~= nil and geo.hd
    local frame
    if geo.hd then
      frame = mod._kantoInMotionFlatTrainerFrame(battle)
    else
      local getter = mod.exports and mod.exports._kantoInMotionBattleTrainerFrame
      if type(getter) == "function" then
        local ok, selected = pcall(getter, battle)
        if ok then frame = selected end
      end
    end
    if not (frame and type(frame.getDimensions) == "function") then return false end

    local place=nativeBattlePlacementPx(game,vw,vh)
    local scaleX=place and tonumber(place.sx) or nil
    local scaleY=place and tonumber(place.sy) or nil
    if geo.hd then
      -- Use arena pixels on desktop too: the native UI's Retina/integer rung
      -- can otherwise double the trainer independently of the battlefield.
      local arenaScale = tonumber(geo.hdScale)
      if not (arenaScale and arenaScale > 0) then return false end
      local artScale = orientation == "portrait" and 10 or 8
      if not mobile then
        -- Fit the accepted 1920x1080 trainer rung to both window dimensions.
        -- An ultrawide window must not enlarge it using width alone.
        arenaScale=math.min((tonumber(vw) or 1920)/1920,
          (tonumber(vh) or 1080)/1080)
        local trainerPct=tonumber(mod.options:get("desktopTrainerSizeV2")) or 100
        artScale=8*math.max(50,math.min(200,trainerPct))/100
      end
      scaleX, scaleY = artScale * arenaScale, artScale * arenaScale
    end
    if not (scaleX and scaleX>0) then
      scaleX=math.max(1,math.floor((tonumber(vw) or 160)/160))
    end
    if not (scaleY and scaleY>0) then scaleY=scaleX end
    local slideScale = geo.hd and place and tonumber(place.sx) or scaleX
    if not (slideScale and slideScale > 0) then slideScale = scaleX end
    local offset=0
    if type(battle.picOffset)=="function" then
      local okOffset,value=pcall(battle.picOffset,battle,"back")
      if okOffset then offset=tonumber(value) or 0 end
    end
    local w,h=frame:getDimensions()
    local ground=h
    local ax=tonumber(geo.playerX) or 0
    local ay=tonumber(geo.playerY) or 0
    if geo.hd and mobile then
      -- Back-trainer silhouettes need a lower baseline than battler feet.
      -- Scale the correction with the arena, never the UI or device DPI.
      ay=ay+(orientation == "portrait" and 220 or 56)*geo.hdScale
    end
    if geo.hd and not mobile then
      local directBottom=false
      if type(mod.find)=="function" then
        local ok,menu=pcall(mod.find,"gen3transparency")
        local ui=ok and menu and menu.exports and menu.exports.battleUi
        if ui and type(ui.canDrawBottom)=="function" then
          local okBottom,canDraw=pcall(ui.canDrawBottom,battle)
          directBottom=okBottom and canDraw==true
        end
      end
      if directBottom then
        -- Menu Customizer draws the final-window strip at a continuous scale,
        -- independently of the native renderer's integer/letterbox rung.
        -- Its border starts with one transparent native row: let the trainer
        -- reach the first painted row, beneath the UI's final composition.
        local uiScale=math.min((tonumber(vw) or 160)/160,
          (tonumber(vh) or 144)/144)
        -- Include a physical pixel of overlap after rounding. At fractional
        -- UI scales the final nearest-filtered sprite row otherwise ends one
        -- pixel before the first painted frame row.
        ay=math.ceil(math.floor((tonumber(vh) or 144)-48*uiScale+0.5)+uiScale)+1
      else
        -- Keep native/external dialogue placement and device DPI unchanged.
        local renderer=game and game.renderer
        if renderer and type(renderer.frameRects)=="function" then
          local ok,r=pcall(renderer.frameRects,renderer)
          if ok and r and r.uoy and r.Uy then
            ay=(r.uoy+96*r.Uy-(r.vuy or 0))*(r.dpiY or 1)
          end
        else
          ay=(tonumber(vh) or 144)-48*math.min((tonumber(vw) or 160)/160,(tonumber(vh) or 144)/144)
        end
      end
      local bounds
      if mod._kimAutoPlayerSize and type(mod._kimAutoPlayerSize.measure)=="function" then
        local ok,value=pcall(mod._kimAutoPlayerSize.measure,frame,w,h)
        if ok and type(value)=="table" then bounds=value end
      end
      ground=bounds and tonumber(bounds.ground) or h
      local above=ground-(bounds and tonumber(bounds.y0) or 0)
      if above>0 then
        -- Preserve the selected percentage until its visible pixels would
        -- leave the top of the screen. Transparent rows do not count.
        local safeScale=math.max(0,ay-2)/above
        scaleX,scaleY=math.min(scaleX,safeScale),math.min(scaleY,safeScale)
      end
    end
    love.graphics.push("all")
    love.graphics.setShader()
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(frame,
      ax-w*scaleX*0.5+offset*slideScale,
      ay-ground*scaleY,0,scaleX,scaleY)
    love.graphics.pop()
    return true
  end

  drawDirectBattleSprites = function(battle, vw, vh)
    if not (battle and battleLiteDirectStageActive()) then return false end
    local geo = directStageGeometry(vw, vh, battle.game, battle)
    local enemy = drawDirectSide(battle, "enemy", geo)
    local player = drawDirectSide(battle, "player", geo)
    return enemy or player
  end

  setFlatBattleWorld = function(game, battle)
    if not game then
      local okGame, Game = pcall(require, "src.core.Game")
      if okGame then game = Game end
    end
    if battleSystemEnabled() and hdBattleBackgroundsEnabled() and not externalBattleSceneOwnerRegistered() then
      forceBattleLayoutOG(game)
    end
    if not (battleLiteFullScreenActive() and game and game.renderer
        and type(game.renderer.setWorldOverride) == "function") then return false end

    local image,backdrop=hdArenaImage(game,battle)
    if not image then return false end

    local worldMetrics = battleWorldMetrics()
    if not worldMetrics then return false end
    local vw, vh = worldMetrics.width, worldMetrics.height
    flatBattleWorldCanvas = ensureBattleCanvas(flatBattleWorldCanvas, vw, vh, "linear")
    if not flatBattleWorldCanvas then return false end

    local g = love.graphics
    local prev = g.getCanvas and g.getCanvas() or nil
    g.push("all")
    g.setCanvas(flatBattleWorldCanvas)
    g.origin()
    -- A native-menu scissor must not leave black bars on the complete arena.
    -- push/pop keeps the caller's clip intact outside this full-canvas pass.
    if g.setScissor then g.setScissor() end
    g.clear(0, 0, 0, 1)
    g.setShader()
    g.setColor(1, 1, 1, 1)
    local portraitTouch=touchBattleOrientation(game)=="portrait"

    -- A complete aspect arena replaces the former backdrop/source layers.
    -- Map its embedded source rectangle through the SAME stage transform as
    -- before; both mounds, Pokemon and screen-position settings stay aligned.
    local wideTransform
    if battleBackgroundMode() == "native" then
      wideTransform=nativeFitHdTransform(game,battle,image,backdrop,vw,vh)
    end
    if not wideTransform then
      wideTransform=hdArenaTransform(vw,vh,portraitTouch)
      if portraitTouch then
        wideTransform.y=wideTransform.y-mobileScreenPositionLiftPx(game,vw,vh)
      end
    end
    local complete=aspectArenaImage(backdrop,vw,vh)
    local A=hdArenaRouter._aspectBackgrounds
    if complete and type(A.transform)=="function" then
      local t=A.transform(vw,vh,wideTransform)
      g.draw(complete,t.x,t.y,0,t.sx,t.sy)
    else
      -- Safe fallback for incomplete/custom asset packs: draw the canonical
      -- background once, without applying an extension or blending shader.
      g.draw(image,wideTransform.x,wideTransform.y,0,
        wideTransform.sx or wideTransform.scale,wideTransform.sy or wideTransform.scale)
    end

    -- Original KIM 1.3.7 KRBA wide compositor, adapted to the current
    -- 1920x950 HD-background router. BG/FG image/color planes now use the
    -- complete final battle canvas instead of the native 160x144 surface.
    local krba=activeKrbaSession(battle)
    local krbaWideAnchors=nil
    if krba and wideTransform then
      local stageScale=tonumber(wideTransform.scale) or 1
      if not (stageScale>0) then stageScale=1 end
      local geo=directStageGeometry(vw,vh,game,battle)
      local tx,ty=wideTransform.x or 0,wideTransform.y or 0
      local pm=directSideMetrics(battle,"player",geo)
      local em=directSideMetrics(battle,"enemy",geo)
      local fallbackHalf=95*stageScale
      local pcx=pm and pm.centerX or (geo.playerX or 0)
      local pcy=pm and pm.centerY or ((geo.playerY or 0)-fallbackHalf)
      local ecx=em and em.centerX or (geo.enemyX or 0)
      local ecy=em and em.centerY or ((geo.enemyY or 0)-fallbackHalf)
      krbaWideAnchors={
        player={x=(pcx-tx)/stageScale,y=(pcy-ty)/stageScale},
        enemy={x=(ecx-tx)/stageScale,y=(ecy-ty)/stageScale},
      }
    end
    if krba and wideTransform and type(krba.drawWideBack)=="function" then
      mod._kantoInMotionGuardedMobileCall("KRBA wide back draw",
        krba.drawWideBack,krba,wideTransform,krbaWideAnchors)
    end

    -- Paint the intro trainer and imported HD animated Pokemon directly at
    -- final-window resolution using the same authored ground-contact anchors.
    -- The native 160x144 overlay is intentionally not responsible for trainer
    -- placement on the widened HD field.
    -- Native Fit normally clips battle pictures at row 96. Replay the player

    -- into the full world canvas before the translucent menu is composited.

    -- Keep native placement, provider frames, send-out and animation behavior.

    if battleBackgroundMode()=="native" and touchBattleOrientation(game)~=nil and battle and not battle.showPlayerBack

        and not battle.safari and not battle.demo and type(battle.drawPicsLayer)=="function" then

      local renderer=game and game.renderer

      local r=renderer and type(renderer.frameRects)=="function" and renderer:frameRects()

      if r then

        g.push("all");g.origin();g.setScissor();g.setShader()

        g.translate((r.uox-(r.vux or 0))*(r.dpiX or 1),

          (r.uoy-(r.vuy or 0))*(r.dpiY or 1))

        g.scale(r.Up,r.Up)

        -- Native back pictures end at row 96; the HD player platform is at

        -- row 110. Put those lower 14 rows behind the translucent menu.

        g.translate(0,14)

        local previous=battle._kimReplayPlayerBehindMenu

        battle._kimReplayPlayerBehindMenu=true

        local ok,err=pcall(battle.drawPicsLayer,battle,0,0,0,"player",true)

        battle._kimReplayPlayerBehindMenu=previous

        g.pop()

        if not ok then error(err,0) end

      end

    end

    -- Draw both desktop battlers using the painted mound transform and
    -- natural provider frames, rather than the native UI's padded sprite boxes.
    if battleBackgroundMode()=="native" and touchBattleOrientation(game)==nil
        and battle and not battle.safari and not battle.demo then
      local anchors=hdArenaRouter.groundAnchors(backdrop)
      local p=anchors and anchors.player
      local e=anchors and anchors.enemy
      if p then
        local sx=wideTransform.sx or wideTransform.scale or 1
        local sy=wideTransform.sy or wideTransform.scale or sx
        local rung=math.max(1,math.floor(math.min(vw/160,vh/144)*0.65+0.5))
        local geo={hd=true,hdScale=math.min(sx,sy),pixelScale=rung*0.8,playerPixelScale=rung,
          viewportWidth=vw,viewportHeight=vh,
          playerX=(wideTransform.x or 0)+p.x*sx,
          playerY=(wideTransform.y or 0)+p.y*sy,
          enemyX=e and (wideTransform.x or 0)+e.x*sx,
          enemyY=e and (wideTransform.y or 0)+e.y*sy}
        if not battle.showPlayerBack then
          mod._kantoInMotionGuardedMobileCall("native-fit player mound draw",
            drawDirectSide,battle,"player",geo)
        end
        if e then
          mod._kantoInMotionGuardedMobileCall("native-fit enemy mound draw",
            drawDirectSide,battle,"enemy",geo)
        end
      end
    end
    if not battleLiteDirectStageActive() and battle and battle.showPlayerBack then
      local anchors=hdArenaRouter.groundAnchors(backdrop)
      local p=anchors and anchors.player
      if p then
        local sx=wideTransform.sx or wideTransform.scale or 1
        local sy=wideTransform.sy or wideTransform.scale or sx
        local geo={hd=true,hdScale=math.min(sx,sy),
          playerX=(wideTransform.x or 0)+p.x*sx,
          playerY=(wideTransform.y or 0)+p.y*sy}
        mod._kantoInMotionGuardedMobileCall("native-fit trainer draw",
          drawDirectBattleTrainer,battle,geo,game,vw,vh)
      end
    end
    if battleLiteDirectStageActive() then
      local geo=directStageGeometry(vw,vh,game,battle)

      -- The Oak's Lab starter fight is the one Gen 1 trainer intro that can
      -- disappear completely on the Android fullscreen reconstruction. Draw
      -- KIM's packaged Gary front frame at the same authored enemy platform
      -- anchor used by the HD battler. The engine's live foe picOffset keeps
      -- the normal slide-off timing; this branch is inactive for every other
      -- trainer battle.
      local enemyTrainerGetter=mod.exports
        and mod.exports._kantoInMotionEnemyTrainerFrame or nil
      if type(enemyTrainerGetter)=="function" then
        local okEnemy,enemyTrainer=pcall(enemyTrainerGetter,battle)
        if okEnemy and enemyTrainer and type(enemyTrainer.getDimensions)=="function" then
          local place=nativeBattlePlacementPx(game,vw,vh)
          local enemyScaleX=place and tonumber(place.sx) or nil
          local enemyScaleY=place and tonumber(place.sy) or nil
          if not (enemyScaleX and enemyScaleX>0) then
            enemyScaleX=math.max(1,math.floor((tonumber(vw) or 160)/160))
          end
          if not (enemyScaleY and enemyScaleY>0) then enemyScaleY=enemyScaleX end
          local enemyOffset=0
          if type(battle.picOffset)=="function" then
            local okOffset,value=pcall(battle.picOffset,battle,"foe")
            if okOffset then enemyOffset=tonumber(value) or 0 end
          end
          local ew,eh=enemyTrainer:getDimensions()
          local eax=tonumber(geo.enemyX) or 0
          local eay=tonumber(geo.enemyY) or 0
          -- garyfrontplayer fills essentially the entire 80px authored frame,
          -- while Red's back-trainer art occupies about 48px of its 80px frame.
          -- The old 1.00x frame scale therefore made Gary ~67% taller than Red.
          -- A 0.60 presentation factor gives both trainers the same visible
          -- height without resampling the source asset or moving his feet off
          -- the authored enemy platform.  Foe picOffset remains in stage units
          -- so the native intro slide timing/distance is preserved.
          local garyScale=0.60
          local drawScaleX=enemyScaleX*garyScale
          local drawScaleY=enemyScaleY*garyScale
          mod._kantoInMotionGuardedMobileCall("Oak Lab Gary trainer draw",function()
            love.graphics.push("all")
            love.graphics.setShader()
            love.graphics.setColor(1,1,1,1)
            love.graphics.draw(enemyTrainer,
              eax-ew*drawScaleX*0.5+enemyOffset*enemyScaleX,
              eay-eh*drawScaleY,0,drawScaleX,drawScaleY)
            love.graphics.pop()
          end)
        end
      end

      mod._kantoInMotionGuardedMobileCall("direct trainer draw",
        drawDirectBattleTrainer,battle,geo,game,vw,vh)
      if type(drawDirectBattleSprites) == "function" then
        mod._kantoInMotionGuardedMobileCall("direct battler draw",
          drawDirectBattleSprites, battle, vw, vh)
      end
    end
    if battleLiteDirectStageActive() and battle and mod._kantoInMotionShinyEncounterFx
        and type(mod._kantoInMotionShinyEncounterFx.draw) == "function" then
      mod._kantoInMotionGuardedMobileCall("shiny encounter draw",
        mod._kantoInMotionShinyEncounterFx.draw,
        mod._kantoInMotionShinyEncounterFx, battle, game, vw, vh)
    end
    if krba and wideTransform and type(krba.drawWideFront)=="function" then
      mod._kantoInMotionGuardedMobileCall("KRBA wide front draw",
        krba.drawWideFront,krba,wideTransform,krbaWideAnchors)
    end
    g.pop()
    if prev then g.setCanvas(prev) else g.setCanvas() end
    mod._kantoInMotionFlatWorldOrientation(game.renderer, flatBattleWorldCanvas)
    game.renderer:setWorldOverride(flatBattleWorldCanvas)

    if battle then
      -- Publish the actual lower edge of the transformed KRS artwork.  Modern
      -- UI consumes this only while KRS Battle Lite is active and paints its
      -- theme into any uncovered footer below that edge.  This prevents a
      -- black bar when the 1920x950 source is lifted on 16:9 / 4:3 displays.
      if wideTransform then
        local footerPx = math.max(0, math.min(vh,
          math.floor(wideTransform.y + 950 * (wideTransform.sy or wideTransform.scale or 1) + 0.5)))
        -- Modern UI draws in LOVE/window units, while the fullscreen HD
        -- canvas above is deliberately physical-pixel sized. Convert the live
        -- arena edge back into the same screen-space coordinate system before
        -- publishing it; desktop dpi=1 remains byte-for-byte equivalent.
        battle._kantoInMotionHdFooterTop = (worldMetrics.unitY or 0)
          + footerPx / (worldMetrics.dpiY or 1)
      else
        battle._kantoInMotionHdFooterTop = nil
      end
      local hudLift=touchBattleOrientation(game) and mobileScreenPositionLiftPx(game,vw,vh) or 0
      local geo = battleHudGeometry(vw, vh, hudLift, game)
      -- Publish KIM's per-frame flat battle geometry contract. QOL already
      -- understands this exact shape and will draw its EXP/Pokedex overlays
      -- directly onto the fullscreen arena. Extra anchor/span fields also
      -- make this useful to other compatible battle add-ons (including
      -- ball/effect compatibility) without touching those mods.
      local shot = {
        canvas = flatBattleWorldCanvas,
        scale = geo.hudScale,
        battleScale = geo.battleScale,
        hudScale = geo.hudScale,
        pw = vw, ph = vh,
        lx = geo.lx, ly = geo.ly,
        player = { 26, 96 },
        enemy = { 124, 56 },
        playerSpan = 56,
        enemySpan = 56,
        tint = { 1, 1, 1, 1 },
        kantoInMotion2D = true,
      }
      battle.dramaticShapeShot = shot
      battle._kantoInMotionFlatShot = shot

      -- QOL EXP compatibility. Quality of Life uses dramaticShapeShot.ly as
      -- the shared origin for its player EXP bar. That is correct in ordinary
      -- landscape/desktop geometry, but KIM deliberately relocates the player
      -- HUD band inside the contained battlefield on mobile portrait. Anchor
      -- QOL's EXP primitives to the actual KIM player-band top plus the native
      -- Gen 1 EXP-row offset (89 - 48 = 41 HUD pixels). The same formula also
      -- exactly preserves the existing SCALED-mode correction in landscape.
      -- QOL itself and its saved options remain untouched. EXP fill/burst and
      -- the desktop flat-shot caught pixels are the only primitives remapped.
      local qolBaseY = geo.ly + 89 * geo.hudScale
      local qolTargetY = geo.playerBandY + 41 * geo.hudScale
      local qolPortrait = geo.portraitStage ~= nil
      local qolScaled = geo.battleScale > geo.hudScale + 0.001
      qolXpCompat.active = qolPortrait or qolScaled
      qolXpCompat.canvas = flatBattleWorldCanvas
      qolXpCompat.scale = geo.hudScale
      qolXpCompat.baseY = qolBaseY
      qolXpCompat.shiftY = qolTargetY - qolBaseY
      qolXpCompat.minX = vw * 0.5

      -- Desktop 3D-BTL OFF uses this same KIM-owned flat shot. Normalize the
      -- QOL caught cluster exactly like the working staged-3D bridges so its
      -- final position is independent of enemy-name length. Mobile keeps its
      -- separately confirmed reconstruction path untouched.
      local qolDesktop = not (type(mod._kantoInMotionNativeMobileHost) == "function"
        and mod._kantoInMotionNativeMobileHost())
      qolXpCompat.caughtActive = qolDesktop
      qolXpCompat.battle = battle
      qolXpCompat.game = game
      qolXpCompat.ly = geo.ly
      qolXpCompat.enemyBandX = geo.enemyBandX
      qolXpCompat.enemyBandY = geo.enemyBandY
    end
    return true
  end

  -- Shared with the integrated KRBA bridge. When true, KRBA suppresses its
  -- duplicate native 160x96 layer because setFlatBattleWorld has already
  -- rendered the same session at final-window resolution.
  mod.exports._kantoInMotionKrsWideActive=function(battle)
    return not IS_GEN2 and battle~=nil and battleLiteDirectStageActive()
      and activeKrbaSession()~=nil
  end

  -- Kanto in Motion owns the battlefield, animated battlers and one native-style
  -- HP/status bands.  When the integrated Modern UI is enabled it owns only the
  -- LOWER battle information surface: command menu, move menu and battle
  -- messages.  HP/status/EXP overlays remain source/KIM-owned.  Keeping this
  -- decision here also gives the master BATTLE SYSTEM switch a true bypass for
  -- users who prefer vanilla or another battle presentation mod.
  -- Forward declaration used by the Typed Move Colors compatibility branch.
  -- Compatibility code needs to inspect the live battle before the concrete
  -- scanner is defined later in this file. Keeping this as a real upvalue
  -- avoids Lua resolving currentBattleState as a missing global.
  local currentBattleState

  local function battleModernUiActive(game,state)
    -- Mobile uses the same hybrid ownership as desktop: Modern UI owns the
    -- command/move/message surface while KIM keeps the
    -- HP/status HUD. TouchControls are an input overlay, not a reason to
    -- fall back to the vanilla battle menus.
    if not integratedModernUiEnabled() then return false end
    if mod._kantoInMotionModernUiInstalled ~= true then return false end
    if not battleSystemEnabled() then return false end

    -- A generic external scene owner normally makes this helper yield, but an
    -- owner registered as LOWER/FULL has explicitly asked KIM Modern UI to
    -- keep the lower battle presentation. PotatoVoxel uses LOWER: it owns the
    -- 3D arena while KIM owns commands/moves/dialog. The integrated Modern UI
    -- module already honors this same registry; mirror that decision here so
    -- battle.bottom_ui_visible suppresses the source panel too. Legacy Battle
    -- Art remains on its established path because it has no registry entry.
    if externalBattleSceneOwnerRegistered() then
      local spec = mod._kantoInMotionInterop
        and type(mod._kantoInMotionInterop.battleOwnerFor) == "function"
        and mod._kantoInMotionInterop:battleOwnerFor(game,state) or nil
      local mode = type(spec) == "table"
        and tostring(spec.modernUi or spec.mode or "native"):lower() or "native"
      if mode ~= "lower" and mode ~= "full" then return false end
    end
    return mod.options:get("battleUiWip") ~= false
  end

  local function typedMoveColorsHandle()
    if type(mod.find) ~= "function" then return nil end
    local ok, handle = pcall(mod.find, "typed_move_colors")
    return ok and handle or nil
  end

  -- Typed Move Colors 0.4.x normally detaches its own 2x2 battle selector
  -- whenever it sees a custom/transparent battle surface. Kanto in Motion's
  -- Modern lower panel owns that exact phase, so let KIM own the cursor grid
  -- too while leaving Typed Move Colors fully active in menus and in battles
  -- where KIM is disabled. This patches only Typed's published process-stable
  -- BattleState helper table; no Typed Move Colors files/options are changed.
  local function installTypedBattleLiteInputCompat()
    if not typedMoveColorsHandle() then return false end
    local okState, BattleState = pcall(require, "src.battle.BattleState")
    if not okState or type(BattleState) ~= "table" then return false end
    local patch = rawget(BattleState, "_typedMoveColorsInputPatch")
    if type(patch) ~= "table" or type(patch.detached) ~= "function" then
      return false
    end
    if patch._kantoInMotionDetached then return true end
    local originalDetached = patch.detached
    patch._kantoInMotionDetached = originalDetached
    patch.detached = function(battle, ...)
      if battle and ((battleLiteFullScreenActive()
          and battleModernUiActive(battle and battle.game,battle))
          or (battle.dramaticShapeShot ~= nil and integratedModernUiEnabled()
            and mod._kantoInMotionModernUiInstalled == true
            and mod.options:get("battleUiWip") ~= false)) then
        return false
      end
      return originalDetached(battle, ...)
    end
    return true
  end

  -- Android/iOS composes the BattleState source before render.hud. Typed Move
  -- Colors can therefore decide to draw its detached 2x2 selector before the
  -- old render.hud-only compatibility install ran. Keep the same desktop
  -- detached() policy, but install it immediately before every BattleState draw
  -- as well. Store the installer on `mod` rather than adding locals to this
  -- already-large bootstrap function.
  mod._kantoInMotionEnsureTypedPreDrawCompat = function()
    local okState,BattleState=pcall(require,"src.battle.BattleState")
    if not (okState and type(BattleState)=="table"
        and type(BattleState.draw)=="function") then return false end
    if mod._kantoInMotionTypedPreDrawClass==BattleState
        and BattleState.draw==mod._kantoInMotionTypedPreDrawFn then
      return true
    end
    -- Capture this layer's inner draw in a per-wrapper local. A later mod may
    -- wrap BattleState.draw and cause us to install a newer outer layer; using
    -- one shared mutable inner upvalue would make the older layer recurse.
    local innerDraw=BattleState.draw
    local wrapper
    wrapper=function(self,...)
      pcall(installTypedBattleLiteInputCompat)
      return innerDraw(self,...)
    end
    mod._kantoInMotionTypedPreDrawClass=BattleState
    mod._kantoInMotionTypedPreDrawFn=wrapper
    BattleState.draw=wrapper
    return true
  end

  pcall(mod._kantoInMotionEnsureTypedPreDrawCompat)
  if mod.events and type(mod.events.on)=="function" then
    mod.events:on("mods.loaded",function()
      pcall(mod._kantoInMotionEnsureTypedPreDrawCompat)
      pcall(installTypedBattleLiteInputCompat)
    end)
    mod.events:on("game.ready",function()
      pcall(mod._kantoInMotionEnsureTypedPreDrawCompat)
      pcall(installTypedBattleLiteInputCompat)
    end)
    mod.events:on("battle.started",function()
      pcall(mod._kantoInMotionEnsureTypedPreDrawCompat)
      pcall(installTypedBattleLiteInputCompat)
    end)
  end

  -- Typed Move Colors 0.3.9 has two battle presenters: an in-canvas
  -- `battle.overlay` decorator and a finished-window `render.hud` presenter.
  -- PotatoVoxel reports a wide battle layout, so Typed uses the in-canvas
  -- decorator instead of its detached presenter. That is why changing only
  -- Typed's detached/wide-layout decision did not remove the second move grid.
  --
  -- KIM Modern UI already owns move selection while BATTLE SYSTEM and MODERN
  -- BATTLE UI are ON. During only the nested draw hooks used by Typed, hide the
  -- move-selection phase, then restore it before KIM Modern UI paints. Keep
  -- these helpers on `mod` because this bootstrap is already at Lua's local
  -- variable ceiling.
  mod._kantoInMotionOwnsTypedMoveSurface = function(battle)
    if not battle or not typedMoveColorsHandle() then return false end
    if not battleSystemEnabled() then return false end
    if not integratedModernUiEnabled() then return false end
    if mod._kantoInMotionModernUiInstalled ~= true then return false end
    if mod.options:get("battleUiWip") == false then return false end
    return battle.phase == "moveSelect" or battle.phase == "mimicSelect"
  end

  mod._kantoInMotionWithTypedMovePhaseHidden = function(battle, fn)
    if not mod._kantoInMotionOwnsTypedMoveSurface(battle) then return fn() end
    local oldPhase = battle.phase
    battle.phase = "kantoInMotionMovePresenter"
    local result = { pcall(fn) }
    battle.phase = oldPhase
    local ok = table.remove(result, 1)
    if not ok then error(result[1], 0) end
    return unpackCompat(result)
  end

  -- Typed's in-canvas move cards are drawn from its -100 battle.overlay link.
  -- Priority -50 places this immediately outside that link, so Typed sees the
  -- temporary non-move phase while the real battle state stays unchanged.
  mod.hooks:wrap("battle.overlay", function(nextFn, battle)
    return mod._kantoInMotionWithTypedMovePhaseHidden(battle,
      function() return nextFn(battle) end)
  end, -50)

  -- Also cover Typed's -100 final-window presenter. Modern UI's +100 HUD link
  -- is outside this wrapper: the real phase is restored before KIM draws its
  -- one authoritative move panel.
  mod.hooks:wrap("render.hud", function(nextFn, game, viewport)
    return mod._kantoInMotionWithTypedMovePhaseHidden(
      currentBattleState and currentBattleState(game) or nil,
      function() return nextFn(game, viewport) end)
  end, -50)

  local function withTypedBattlePresentationSuppressed(game, fn)
    pcall(installTypedBattleLiteInputCompat)
    if not typedMoveColorsHandle() or not (battleModernUiActive(game)
        or (integratedModernUiEnabled() and mod._kantoInMotionModernUiInstalled == true
          and mod.options:get("battleUiWip") ~= false
          and currentBattleState(game) ~= nil
          and currentBattleState(game).dramaticShapeShot ~= nil)) then
      return fn()
    end
    local loader = game and game.mods
    if not loader then return fn() end
    loader.modOptions = loader.modOptions or {}
    local bucket = loader.modOptions.typed_move_colors
    local created = false
    if type(bucket) ~= "table" then bucket = {}; loader.modOptions.typed_move_colors = bucket; created = true end
    local had = rawget(bucket, "battle_colors") ~= nil
    local old = rawget(bucket, "battle_colors")
    local snapshot = {}
    for k, v in pairs(bucket) do snapshot[k] = v end
    if snapshot.battle_colors == nil then snapshot.battle_colors = true end
    if snapshot.layout == nil then snapshot.layout = "wide" end
    if snapshot.effect_hints == nil then snapshot.effect_hints = true end
    if snapshot.strength == nil then snapshot.strength = "bold" end
    if snapshot.opacity == nil then snapshot.opacity = "100" end
    if snapshot.text_only == nil then snapshot.text_only = false end
    game._kantoInMotionTypedMoveColors = snapshot
    -- KIM suppresses Typed Move Colors' detached selector while Modern UI owns
    -- the lower battle panel, but retain Typed's own effectiveness helper so
    -- KIM can mirror the exact strong/weak/immune hint instead of maintaining
    -- a second type chart. The helper lives on Typed's process-stable
    -- BattleState patch table and honors its MOVE EFFECT option.
    local effectHelper = nil
    do
      local okState, BattleState = pcall(require, "src.battle.BattleState")
      local patch = okState and type(BattleState) == "table"
        and rawget(BattleState, "_typedMoveColorsInputPatch") or nil
      if type(patch) == "table" and type(patch.effectIndicator) == "function" then
        effectHelper = patch.effectIndicator
      end
    end
    game._kantoInMotionTypedMoveEffectIndicator = effectHelper
    bucket.battle_colors = false
    local result = { pcall(fn) }
    if had then bucket.battle_colors = old else bucket.battle_colors = nil end
    if created and next(bucket) == nil then loader.modOptions.typed_move_colors = nil end
    game._kantoInMotionTypedMoveColors = nil
    game._kantoInMotionTypedMoveEffectIndicator = nil
    local ok = table.remove(result, 1)
    if not ok then error(result[1], 0) end
    return unpackCompat(result)
  end

  -- -----------------------------------------------------------------------
  -- Kanto in Motion HD 2D battle compositor
  -- -----------------------------------------------------------------------
  -- The Gen 6 plate owns the full renderer world surface. The stock 160x144
  -- battle state is retained as a transparent overlay so its Pokemon, move
  -- animations and lower menu remain authoritative and correctly aligned.
  -- Only the status HUD is extracted and snapped to the window edges.
  local battleSceneCanvas = nil
  -- Mobile catch retargeting can move native Pokeball OAM well outside the
  -- stock 160x144 source rectangle. Keep a padded scratch surface available
  -- only for those catch frames so the translated ball cannot be clipped.
  local battleSceneExpandedCanvas = nil
  local battleHudCanvas = nil
  -- Party PokÃƒÂ© Balls are captured separately so HUD COLOR = INVERTED can
  -- transform HUD ink without recoloring PokÃƒÂ©ball Colorfix artwork.
  local battlePartyBallCanvas = nil
  local battleTextCanvas = nil
  local battleHudQuads = nil
  local battleHudShader = nil
  local battleHudShadowShader = nil

  local function finalViewportSize(viewport)
    local vw = tonumber(viewport and viewport.width)
    local vh = tonumber(viewport and viewport.height)
    if not (vw and vh and vw > 0 and vh > 0) then
      if love and love.graphics and type(love.graphics.getDimensions) == "function" then
        vw, vh = love.graphics.getDimensions()
      end
    end
    return tonumber(vw) or 160, tonumber(vh) or 144
  end

  local function battleUiViewportRect(game, viewport)
    if touchBattleOrientation(game) then
      -- Renderer:endFrame already reports the exact Playfield rect in the
      -- current GameViewport's LOVE-unit coordinate space. Prefer it over a
      -- second reconstruction so TouchSkin viewport moves and render.viewport
      -- captures are reflected immediately.
      local x = tonumber(viewport and viewport.viewX)
      local y = tonumber(viewport and viewport.viewY)
      local w = tonumber(viewport and viewport.viewWidth)
      local h = tonumber(viewport and viewport.viewHeight)
      if x and y and w and h and w > 0 and h > 0 then
        return x, y, w, h
      end
      local metrics=battleWorldMetrics()
      if metrics then
        return metrics.unitX or 0, metrics.unitY or 0,
          math.max(1,metrics.unitWidth or 1),
          math.max(1,metrics.unitHeight or 1)
      end
    end
    local vw,vh=finalViewportSize(viewport)
    return 0,0,vw,vh
  end

  currentBattleState = function(game)
    local stack = game and game.stack
    local states = stack and stack.states
    if type(states) == "table" then
      for i = #states, 1, -1 do
        local state = states[i]
        if type(state) == "table"
            and type(state.drawPicsLayer) == "function"
            and type(state.drawHUDs) == "function"
            and (state.isBattle == true or state.isBattleState == true
              or (state.player ~= nil and state.enemy ~= nil)) then
          return state
        end
      end
    end
    local top = stack and type(stack.top) == "function" and stack:top() or nil
    if type(top) == "table" and type(top.drawPicsLayer) == "function"
        and type(top.drawHUDs) == "function" then
      return top
    end
    return nil
  end

  -- While an in-battle Party or Bag flow is on top of BattleState, that
  -- child screen owns the whole UI. The fullscreen battle compositor must not
  -- repaint its trainer, battle text strip, or snapped HP/status bands over
  -- the child menu. Descendants (choice/summary/etc.) remain covered because
  -- the Party/Bag root stays in the stack below them.
  local partyMenuClass
  do
    local ok, cls = pcall(require, "src.ui.PartyMenu")
    if ok and type(cls) == "table" then partyMenuClass = cls end
  end

  local function battleChildMenuOpen(game, battle)
    local stack = game and game.stack
    local states = stack and stack.states
    if type(states) ~= "table" or type(battle) ~= "table" then return false end
    local battleIndex
    for i = #states, 1, -1 do
      if states[i] == battle then battleIndex = i break end
    end
    if not battleIndex or battleIndex >= #states then return false end
    for i = battleIndex + 1, #states do
      local state = states[i]
      if type(state) == "table" then
        local kind = rawget(state, "kind")
        if kind == "bag" or rawget(state, "__usefulBagKind") == "bag" then
          return true, "bag"
        end
        if partyMenuClass and getmetatable(state) == partyMenuClass then
          return true, "party"
        end
      end
    end
    return false
  end

  local function sizedBattleCanvas(slot, width, height)
    width=math.max(1,math.floor((tonumber(width) or 160)+0.5))
    height=math.max(1,math.floor((tonumber(height) or 144)+0.5))
    if slot and slot.getWidth and slot:getWidth()==width
        and slot:getHeight()==height then return slot end
    if not (love and love.graphics and type(love.graphics.newCanvas)=="function") then
      return nil
    end
    local ok,canvas=pcall(love.graphics.newCanvas,width,height)
    if not ok or not canvas then return nil end
    if canvas.setFilter then pcall(canvas.setFilter,canvas,"nearest","nearest") end
    return canvas
  end

  local function logicalCanvas(slot)
    return sizedBattleCanvas(slot,160,144)
  end

  local function menuBattleUi()
    if type(mod.find) ~= "function" then return nil end
    local ok, menu = pcall(mod.find, "gen3transparency")
    local ui = ok and menu and menu.exports and menu.exports.battleUi
    return type(ui) == "table" and ui or nil
  end

  local function directBattleBottom(battle)
    local ui = menuBattleUi()
    return ui and type(ui.canDrawBottom) == "function"
      and ui.canDrawBottom(battle) == true or false
  end

  local function battleOffsets(battle)
    local fx = battle and battle.fx
    local sx = (fx and fx.shakeX) or 0
    local sy = (fx and fx.shakeY) or 0
    if sx == 0 and sy == 0 and fx and fx.shake and fx.shake > 0 then
      sx = (battle.frame or 0) % 4 < 2 and 2 or -2
    end
    local slide = (battle.introSlide or 0) * 2
    return slide, sx, sy
  end

  local function captureBattleScene(battle, padX, padY)
    padX=math.max(0,math.floor((tonumber(padX) or 0)+0.5))
    padY=math.max(0,math.floor((tonumber(padY) or 0)+0.5))
    local sceneCanvas
    if padX>0 or padY>0 then
      battleSceneExpandedCanvas=sizedBattleCanvas(battleSceneExpandedCanvas,
        160+padX*2,144+padY*2)
      sceneCanvas=battleSceneExpandedCanvas
    else
      battleSceneCanvas=logicalCanvas(battleSceneCanvas)
      sceneCanvas=battleSceneCanvas
    end
    if not sceneCanvas then return nil end
    local g = love.graphics
    local previousCanvas = g.getCanvas and g.getCanvas() or nil
    local slide, sx, sy = battleOffsets(battle)
    local mobileCaptureBase = mod._kantoInMotionNativeMobileGen1() and mod._kantoInMotionGraphicsDepth() or nil
    g.push("all")
    local ok, err = pcall(function()
      g.setCanvas(sceneCanvas)
      g.origin()
      g.clear(0, 0, 0, 0)
      g.setShader()
      g.setColor(1, 1, 1, 1)
      if padX>0 or padY>0 then g.translate(padX,padY) end
      -- Rebuild the native transparent battle layers over the HD arena. KIM
      -- does not ship or inject move-animation art here; Gen1Recomp (or an
      -- external animation provider) remains the animation authority.
      local okLayers, layerErr = pcall(function()
        if type(battle.drawPicsLayer) == "function" then
          local oldBack=nil
          local hideNativeTrainer=battleLiteDirectStageActive()
            and battleLiteOwnsSprites() and battle.showPlayerBack
            and not battle.safari and not battle.demo
          if hideNativeTrainer then
            oldBack=battle.playerBackPic
            local blank=transparentPic()
            if blank then battle.playerBackPic=blank end
          end

          -- KIM directly owns Gary's presentation in the first Oak's Lab rival
          -- battle.  Gen1Recomp can restore its native rival trainer again in
          -- the victory/outro phase, which produced two rivals on the RP6.
          -- Blank only that native trainer pic while rebuilding the transparent
          -- source layer; the packaged Gary frame below remains the sole visible
          -- trainer at both the intro and the outro.
          local oldEnemyTrainer=nil
          local hideNativeEnemyTrainer=false
          local enemyTrainerGetter=mod.exports
            and mod.exports._kantoInMotionEnemyTrainerFrame or nil
          if battle.showEnemyTrainer and type(enemyTrainerGetter)=="function" then
            local okEnemy,enemyTrainer=pcall(enemyTrainerGetter,battle)
            hideNativeEnemyTrainer=okEnemy and enemyTrainer~=nil
          end
          if hideNativeEnemyTrainer then
            oldEnemyTrainer=battle.trainerPic
            local blank=transparentPic()
            if blank then
              battle.trainerPic=blank
            else
              hideNativeEnemyTrainer=false
            end
          end

          local okPics,picsErr=pcall(battle.drawPicsLayer,battle,slide,sx,sy,nil,true)
          if hideNativeTrainer then battle.playerBackPic=oldBack end
          if hideNativeEnemyTrainer then battle.trainerPic=oldEnemyTrainer end
          if not okPics then error(picsErr,0) end
        end

        -- The fullscreen trainer is now drawn directly into the HD world at
        -- the authored player platform. Keep the native 160x144 trainer out of
        -- this centred overlay so it cannot reappear in the middle of the
        -- widened battlefield.
      end)
      if okLayers then
        okLayers,layerErr=pcall(function()
          if type(battle.drawAnimLayer) == "function" then
            local colorized = type(battle.colorMode) == "function"
              and battle:colorMode() or false
            battle:drawAnimLayer(colorized)
          end
        end)
      end
      if not okLayers then error(layerErr, 0) end
      -- battle.overlay is draw-only. Replaying it onto the scratch canvas preserves compatible sparkle/custom overlays above the HD background.
      local okRuntime, Runtime = pcall(require, "src.mods.Runtime")
      if okRuntime and Runtime and type(Runtime.wantsHook) == "function"
          and Runtime.wantsHook("battle.overlay")
          and type(Runtime.call) == "function" then
        Runtime.call("battle.overlay", function() end, battle)
      end
    end)
    if mobileCaptureBase ~= nil then
      mod._kantoInMotionRestoreGraphicsDepth(mobileCaptureBase)
    else
      g.pop()
    end
    if previousCanvas then g.setCanvas(previousCanvas) else g.setCanvas() end
    if not ok then
      if mod.log and type(mod.log.warn) == "function" then
        mod.log:warn("Battle Lite scene capture failed: " .. tostring(err))
      end
      return nil
    end
    return sceneCanvas, slide, padX, padY
  end

  -- Rebuild only the transparent native battle pieces after render.compose
  -- removes Gen1Recomp's complete 160x144 UI canvas. This preserves trainer
  -- intro/send-out art and native fallback animation cels without ever
  -- reintroducing the white battle paper seen in the user's video. Settled
  -- Pokemon remain hidden by the drawPicsLayer bridge because KIM already
  -- renders the high-resolution battlers directly into the world canvas.
  local function drawNativeBattleOverlay(battle, viewport)
    local scene
    local ox,oy,vw,vh=battleUiViewportRect(battle and battle.game,viewport)
    local orient=touchBattleOrientation(battle and battle.game)
    local g=love.graphics
    local x,y,sx,sy
    local portraitStageBottom,portraitDpiY

    if orient=="portrait" then
      -- Trainer/send-out sprites live in the native transparent 160x144 pics
      -- layer. The arena itself is width-contained to a 1920x950 stage in
      -- portrait, so fitting that native layer to the whole tall phone view
      -- puts Red in the black space above the field. Fit the native overlay
      -- inside the SAME contained stage instead, on an integer physical-pixel
      -- rung so trainer pixels stay crisp.
      local aspect=1920/950
      local stageW=vw
      local stageH=stageW/aspect
      if stageH>vh then stageH=vh; stageW=stageH*aspect end
      local stageX=ox+(vw-stageW)*0.5
      local dpiX=tonumber(viewport and viewport.dpiX) or 1
      local dpiY=tonumber(viewport and viewport.dpiY) or 1
      if not (dpiX>1e-6) then dpiX=1 end
      if not (dpiY>1e-6) then dpiY=1 end
      local world=battleWorldMetrics()
      local liftPx=world and mobileScreenPositionLiftPx(battle and battle.game,
        world.width,world.height) or 0
      local stageY=oy+(vh-stageH)*0.5-liftPx/dpiY
      portraitStageBottom=stageY+stageH
      portraitDpiY=dpiY
      local pixelScale=math.max(1,math.floor(math.min(
        stageW*dpiX/160,stageH*dpiY/144)))
      sx,sy=pixelScale/dpiX,pixelScale/dpiY
      x=stageX+(stageW-160*sx)*0.5
      y=stageY+(stageH-144*sy)*0.5
    else
      local scale=math.max(1,math.floor(math.min(vw/160,vh/144)))
      x=math.floor(ox+(vw-160*scale)*0.5+0.5)
      local dpiY=tonumber(viewport and viewport.dpiY) or 1
      if not (dpiY>1e-6) then dpiY=1 end
      local world=battleWorldMetrics()
      local liftPx=world and mobileScreenPositionLiftPx(battle and battle.game,
        world.width,world.height) or 0
      y=math.floor(oy+vh*0.055-liftPx/dpiY+0.5)
      sx,sy=scale,scale
    end

    -- Pokeball catch animations are authored for the stock 160x144 enemy
    -- slot, while KIM's animated enemy is drawn directly at final resolution.
    -- Prepare a temporary native-pixel translation before capturing the anim
    -- layer so the toss keeps its original launch point but finishes on the
    -- actual KIM enemy battler. The module clears the shift immediately after
    -- the scratch capture; ordinary move animations never see it.
    if mod._kantoInMotionPokeballTargetFix
        and type(mod._kantoInMotionPokeballTargetFix.prepare)=="function" then
      pcall(mod._kantoInMotionPokeballTargetFix.prepare,
        mod._kantoInMotionPokeballTargetFix,battle,x,y,sx,sy)
    end

    -- On Android/iOS the fullscreen enemy can sit outside the stock 160x144
    -- overlay rectangle. v8.6.59 translated the native ball inside that exact
    -- 160x144 scratch canvas, so a valid mobile retarget could clip every ball
    -- frame before composition. Expand only this temporary capture by the full
    -- prepared catch offset, then subtract the padding when compositing. Other
    -- native scene pixels therefore stay at the exact same screen coordinates.
    local catchPadX,catchPadY=0,0
    local ballShift=battle and battle._kantoInMotionBallAnimShift
    if orient and type(ballShift)=="table" then
      catchPadX=math.min(512,math.ceil(math.abs(tonumber(ballShift.dx) or 0)+32))
      catchPadY=math.min(512,math.ceil(math.abs(tonumber(ballShift.dy) or 0)+32))
    end
    local scenePadX,scenePadY
    scene,_,scenePadX,scenePadY=captureBattleScene(
      battle,catchPadX,catchPadY)
    if mod._kantoInMotionPokeballTargetFix
        and type(mod._kantoInMotionPokeballTargetFix.finish)=="function" then
      pcall(mod._kantoInMotionPokeballTargetFix.finish,
        mod._kantoInMotionPokeballTargetFix,battle)
    end
    if not scene then return false end

    g.push("all")
    g.origin()
    g.setShader()
    g.setColor(1,1,1,1)
    local sceneX=x-(tonumber(scenePadX) or 0)*sx
    local sceneY=y-(tonumber(scenePadY) or 0)*sy
    g.draw(scene,sceneX,sceneY,0,sx,sy)
    g.pop()
    return true
  end

  -- Capture only the native Gen 1 HUD glyph/tile layer.  drawHUDs itself never
  -- paints the white battle paper, so the resulting texture can sit directly
  -- over the photographic/painted Gen 6 arena with no opaque status boxes.
  local function captureBattleHud(battle, slide, nameLayout)
    -- Half-size imported font pixels need two source pixels per GB pixel.
    -- Keep the logical HUD geometry while retaining every Emerald glyph row.
    -- Four logical rows above the original HUD let larger names extend upward
    -- without clipping or moving the level/HP/party geometry.
    battleHudCanvas = sizedBattleCanvas(battleHudCanvas,320,296)
    battlePartyBallCanvas = sizedBattleCanvas(battlePartyBallCanvas,320,296)
    if not battleHudCanvas then return nil, nil end
    local ui=menuBattleUi()
    local presenter=ui and ui.hudNames
    local names
    if presenter and type(presenter.enabled)=="function" and presenter.enabled(battle,nameLayout) then
      names={presenter=presenter,entries={}}
    end
    local priorNames=rawget(battle,"_kimHudNames")
    local g = love.graphics
    local previousCanvas = g.getCanvas and g.getCanvas() or nil
    local ownColorMode = rawget(battle, "colorMode")
    local mobileStageOnly =
      type(mod._kantoInMotionMobileBattleArtStageOnlyActive) == "function"
      and mod._kantoInMotionMobileBattleArtStageOnlyActive() == true
    local mobileExternalStageHud = false
    if not mobileStageOnly
        and type(mod._kantoInMotionNativeMobileHost) == "function"
        and mod._kantoInMotionNativeMobileHost()
        and type(mod._kantoInMotionExternalStageUsesKimHud) == "function" then
      local okExternal, value = pcall(mod._kantoInMotionExternalStageUsesKimHud, battle)
      mobileExternalStageHud = okExternal and value == true
    end
    local mobileSafeCapture = mobileStageOnly or mobileExternalStageHud
    local stackGuardCapture = mobileSafeCapture or mod._kantoInMotionNativeMobileGen1()
    local ownDramaticShapeShot = mobileSafeCapture and rawget(battle, "dramaticShapeShot") or nil
    local stackBase = nil

    if stackGuardCapture and type(g.getStackDepth) == "function" then
      local okDepth, depth = pcall(g.getStackDepth)
      if okDepth then stackBase = tonumber(depth) end
    end

    if stackGuardCapture then
      local okPush, pushErr = pcall(g.push, "all")
      if not okPush then
        if mod.log and type(mod.log.warn) == "function" then
          mod.log:warn("Battle Lite HUD capture could not save graphics state: " .. tostring(pushErr))
        end
        return nil, nil
      end
    else
      -- Desktop deliberately keeps the confirmed v11 graphics path exactly.
      g.push("all")
    end

    local ok, err = pcall(function()
      -- Keep party-ball artwork on its own native-resolution layer.  The
      -- integrated PokÃƒÂ©ball Colorfix drawBallRow hook switches to this canvas
      -- only for the six party icons, leaving every other HUD pixel exactly as
      -- it was in the confirmed v9 capture path.
      if battlePartyBallCanvas then
        g.setCanvas(battlePartyBallCanvas)
        g.origin()
        g.clear(0, 0, 0, 0)
      end
      g.setCanvas(battleHudCanvas)
      g.origin()
      g.scale(2,2);g.translate(0,4)
      g.clear(0, 0, 0, 0)
      g.setShader()
      g.setColor(1, 1, 1, 1)
      -- Direct-colour HP fills are needed here because this scratch texture is
      -- not followed by the engine's zone recolour pass.
      battle.colorMode = function() return false end
      battle._kantoInMotionHudCapture = true
      battle._kimHudNames = names
      battle._kantoInMotionPartyBallCanvas = battlePartyBallCanvas

      -- Cooperative staged renderers may wrap/suppress drawHUDs whenever
      -- dramaticShapeShot is present. This is KIM's private 160x144 scratch
      -- capture, not a request to redraw the 3D stage, so temporarily hide the
      -- staged-shot marker on Android/iOS. That makes compatible external scenes and
      -- PotatoVoxel delegate to Gen1Recomp's native HUD glyph draw.
      if mobileSafeCapture then battle.dramaticShapeShot = nil end
      battle:drawHUDs(slide or 0)

      -- The party row is authored into its own true-colour canvas above. If an
      -- engine/mod HUD wrapper also bakes the source balls into the main HUD
      -- canvas, KIM's shadow pass makes that stale row visible behind the
      -- correct Colorfix balls even after another battle renderer persisted OG
      -- layout and Potato was re-enabled). Scrub only the exact 8px party-row
      -- cells, and only while those rows are actually active; live HP numbers
      -- share y=80 later in the battle and must never be touched.
      if battlePartyBallCanvas and type(g.setBlendMode) == "function"
          and type(g.rectangle) == "function" then
        local intro = battle.introBalls and (slide or 0) == 0
        local enemyRow = (battle.showEnemyBalls and battle.enemyParty
            and (slide or 0) == 0)
          or (intro and battle.enemyParty
            and (battle.kind == "trainer" or battle.kind == "link"))
        if intro or enemyRow then
          g.setCanvas(battleHudCanvas)
          g.setShader()
          g.setBlendMode("replace")
          g.setColor(0, 0, 0, 0)
          if intro then g.rectangle("fill", 88, 80, 48, 8) end
          if enemyRow then g.rectangle("fill", 24, 16, 48, 8) end
          g.setBlendMode("alpha")
          g.setColor(1, 1, 1, 1)
        end
      end
    end)

    if stackGuardCapture then
      -- Plain KIM mobile now gets the same local depth repair as external
      -- staged renderers. Only the external paths temporarily suppress the
      -- dramaticShapeShot marker; ordinary KIM keeps that state untouched.
      if stackBase ~= nil then
        mod._kantoInMotionRestoreGraphicsDepth(stackBase)
      else
        pcall(g.pop)
      end
      if mobileSafeCapture then
        battle.dramaticShapeShot = ownDramaticShapeShot
      end
    else
      g.pop()
    end

    battle._kantoInMotionHudCapture = nil
    battle._kimHudNames = priorNames
    battle._kantoInMotionPartyBallCanvas = nil
    if ownColorMode ~= nil then battle.colorMode = ownColorMode
    else battle.colorMode = nil end
    if previousCanvas then g.setCanvas(previousCanvas) else g.setCanvas() end
    if not ok then
      if mod.log and type(mod.log.warn) == "function" then
        mod.log:warn("Battle Lite HUD capture failed: " .. tostring(err))
      end
      return nil, nil
    end
    return battleHudCanvas, battlePartyBallCanvas, names
  end

  local BATTLE_HUD_SHADER = [[
    uniform float inverted;
    bool gaugePixel(vec4 p, vec2 tc) {
      vec2 px = tc * vec2(160.0, 148.0) - vec2(0.0, 4.0);
      bool gauge = (px.x >= 32.0 && px.x < 80.0
                    && px.y >= 16.0 && px.y < 24.0)
                || (px.x >= 96.0 && px.x < 144.0
                    && px.y >= 72.0 && px.y < 80.0);
      float hi = max(p.r, max(p.g, p.b));
      float lo = min(p.r, min(p.g, p.b));
      return gauge && (hi - lo) > 0.04 * p.a;
    }
    vec3 vividGauge(vec4 p) {
      if (p.g > p.r + 0.08 * p.a && p.g > p.b)
        return vec3(0.20, 0.92, 0.32) * p.a;
      if (p.r > p.g * 1.35)
        return vec3(1.00, 0.16, 0.10) * p.a;
      return vec3(1.00, 0.82, 0.05) * p.a;
    }
    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
      vec4 p = Texel(tex, tc);
      float luma = dot(p.rgb, vec3(0.299, 0.587, 0.114));
      if (gaugePixel(p, tc)) {
        p.rgb = vividGauge(p);
      } else if (inverted > 0.5 && p.a > 0.0 && luma <= 0.35 * p.a) {
        p.rgb = vec3(p.a);
      }
      return p * color;
    }
  ]]

  local BATTLE_HUD_SHADOW = [[
    uniform float inverted;
    bool gaugePixel(vec4 p, vec2 tc) {
      vec2 px = tc * vec2(160.0, 148.0) - vec2(0.0, 4.0);
      bool gauge = (px.x >= 32.0 && px.x < 80.0
                    && px.y >= 16.0 && px.y < 24.0)
                || (px.x >= 96.0 && px.x < 144.0
                    && px.y >= 72.0 && px.y < 80.0);
      float hi = max(p.r, max(p.g, p.b));
      float lo = min(p.r, min(p.g, p.b));
      return gauge && (hi - lo) > 0.04 * p.a;
    }
    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
      vec4 p = Texel(tex, tc);
      float luma = dot(p.rgb, vec3(0.299, 0.587, 0.114));
      float a = (p.a > 0.0 && luma <= 0.35 * p.a && !gaugePixel(p, tc))
        ? p.a * (inverted > 0.5 ? 0.72 : 0.38) : 0.0;
      vec3 shade = inverted > 0.5 ? vec3(0.0) : vec3(1.0);
      return vec4(shade, a) * color;
    }
  ]]

  local function getBattleHudShaders()
    if battleHudShader == nil and love and love.graphics
        and type(love.graphics.newShader) == "function" then
      local ok, shader = pcall(love.graphics.newShader, BATTLE_HUD_SHADER)
      battleHudShader = ok and shader or false
    end
    if battleHudShadowShader == nil and love and love.graphics
        and type(love.graphics.newShader) == "function" then
      local ok, shader = pcall(love.graphics.newShader, BATTLE_HUD_SHADOW)
      battleHudShadowShader = ok and shader or false
    end
    return battleHudShader ~= false and battleHudShader or nil,
      battleHudShadowShader ~= false and battleHudShadowShader or nil
  end

  local function hudQuads()
    if battleHudQuads then return battleHudQuads end
    if not (love and love.graphics and type(love.graphics.newQuad) == "function") then
      return nil
    end
    battleHudQuads = {
      enemy = love.graphics.newQuad(0, 0, 320, 104, 320, 296),
      player = love.graphics.newQuad(0, 104, 320, 96, 320, 296),
    }
    return battleHudQuads
  end

  local function drawBattleHud(battle, viewport, slide)
    local ox,oy,vw,vh=battleUiViewportRect(battle and battle.game,viewport)

    -- Compute the HUD rung in physical pixels on high-DPI mobile windows, then
    -- convert positions/scales back to LOVE units for this screen-space pass.
    -- Desktop dpi=1 remains unchanged.
    local touch=touchBattleOrientation(battle and battle.game)
    local dpiX=tonumber(viewport and viewport.dpiX) or 1
    local dpiY=tonumber(viewport and viewport.dpiY) or 1
    if not (dpiX>1e-6) then dpiX=1 end
    if not (dpiY>1e-6) then dpiY=1 end
    local geo
    local hsX,hsY
    if touch then
      local metrics=battleWorldMetrics()
      local liftPx=metrics and mobileScreenPositionLiftPx(battle and battle.game,
        metrics.width,metrics.height) or 0
      geo=battleHudGeometry(vw*dpiX,vh*dpiY,liftPx,battle and battle.game)
      hsX,hsY=geo.hudScale/dpiX,geo.hudScale/dpiY
    else
      geo=battleHudGeometry(vw,vh)
      hsX,hsY=geo.hudScale,geo.hudScale
      dpiX,dpiY=1,1
    end

    local nameLayout={scaleX=hsX,scaleY=hsY,dpiX=dpiX,dpiY=dpiY}
    local layer,partyBalls,names=captureBattleHud(battle,slide,nameLayout)
    local quads=layer and hudQuads() or nil
    if not (layer and quads) then return false end

    -- KIM HUD bands use the same physical geometry exported through the flat
    -- battle-shot compatibility record, keeping QOL attached in both presets.
    local enemyBandX = ox + geo.enemyBandX/dpiX
    local playerBandX = ox + geo.playerBandX/dpiX
    local enemyBandY = oy + geo.enemyBandY/dpiY - 4*hsY
    local playerBandY = oy + geo.playerBandY/dpiY
    local inverted = mod.options:get("battleHudColor") == "inverted" and 1 or 0
    local hudOpacity = math.max(0.25, math.min(1.00,
      (tonumber(mod.options:get("battleHudOpacity")) or 100) / 100))
    local shader, shadow = getBattleHudShaders()
    local g = love.graphics
    g.push("all")
    g.origin()
    g.setColor(1, 1, 1, hudOpacity)
    if shadow then
      g.setShader(shadow)
      pcall(shadow.send, shadow, "inverted", inverted)
      g.draw(layer, quads.enemy, enemyBandX + hsX, enemyBandY + hsY, 0, hsX/2, hsY/2)
      g.draw(layer, quads.player, playerBandX + hsX, playerBandY + hsY, 0, hsX/2, hsY/2)
    end
    if shader then
      g.setShader(shader)
      pcall(shader.send, shader, "inverted", inverted)
    else
      g.setShader()
    end
    g.draw(layer, quads.enemy, enemyBandX, enemyBandY, 0, hsX/2, hsY/2)
    g.draw(layer, quads.player, playerBandX, playerBandY, 0, hsX/2, hsY/2)

    -- Composite PokÃƒÂ©ball Colorfix artwork after the HUD shader.  This keeps
    -- the exact v9 HUD resolution/geometry while preventing HUD COLOR =
    -- INVERTED from turning the balls' dark artwork outlines into white ink.
    g.setShader()
    if partyBalls then
      g.setColor(1, 1, 1, hudOpacity)
      g.draw(partyBalls, quads.enemy, enemyBandX, enemyBandY, 0, hsX/2, hsY/2)
      g.draw(partyBalls, quads.player, playerBandX, playerBandY, 0, hsX/2, hsY/2)
    end
    if names then
      names.presenter.draw(names,{
        enemy={x=enemyBandX,y=enemyBandY,sourceY=0},
        player={x=playerBandX,y=playerBandY,sourceY=104},
        scaleX=hsX,scaleY=hsY,dpiX=dpiX,dpiY=dpiY,opacity=hudOpacity,
      })
    end
    g.pop()
    return true
  end

  local function captureBattleText(battle)
    battleTextCanvas = logicalCanvas(battleTextCanvas)
    if not battleTextCanvas or type(battle.drawTextArea) ~= "function" then return nil end
    local g = love.graphics
    local previousCanvas = g.getCanvas and g.getCanvas() or nil
    local oldScrollPx = rawget(battle, "scrollPx")
    g.push("all")
    local ok, err = pcall(function()
      g.setCanvas(battleTextCanvas)
      g.origin()
      g.clear(0, 0, 0, 0)
      g.setShader()
      g.setColor(1, 1, 1, 1)
      battle:drawTextArea()
    end)
    g.pop()
    battle.scrollPx = oldScrollPx
    if previousCanvas then g.setCanvas(previousCanvas) else g.setCanvas() end
    if not ok then
      if mod.log and type(mod.log.warn) == "function" then
        mod.log:warn("Battle Lite text capture failed: " .. tostring(err))
      end
      return nil
    end
    return battleTextCanvas
  end

  -- Final-window rectangle occupied by the mobile battle command/dialog
  -- surface. Modern UI consumes this exact rectangle so switching from the
  -- native strip to Modern UI does not disturb the accepted mobile layout.
  local function mobileBattleDialogRect(battle, viewport)
    local orient=touchBattleOrientation(battle and battle.game)
    -- Android handhelds such as the RP6 often hide virtual TouchControls while
    -- their built-in controller is active.  That must not make KIM stop being
    -- a mobile battle presenter: the dialog/command surface still needs the
    -- same authored mobile rectangle even when no on-screen buttons are drawn.
    if not orient and mod._kantoInMotionNativeMobileGen1() then
      local g=love and love.graphics
      local w,h=0,0
      if g and type(g.getPixelDimensions)=="function" then
        local ok,pw,ph=pcall(g.getPixelDimensions)
        if ok then w,h=tonumber(pw) or 0,tonumber(ph) or 0 end
      end
      if not (w>0 and h>0) and g and type(g.getDimensions)=="function" then
        local ok,uw,uh=pcall(g.getDimensions)
        if ok then w,h=tonumber(uw) or 0,tonumber(uh) or 0 end
      end
      orient=(h>w and h>0) and "portrait" or "landscape"
    end
    if not orient then return nil end
    local ox,oy,vw,vh=battleUiViewportRect(battle and battle.game,viewport)
    if orient=="portrait" then
      local dpiX=tonumber(viewport and viewport.dpiX) or 1
      local dpiY=tonumber(viewport and viewport.dpiY) or 1
      if not (dpiX>1e-6) then dpiX=1 end
      if not (dpiY>1e-6) then dpiY=1 end
      local world=battleWorldMetrics()
      if world then
        local liftPx=mobileScreenPositionLiftPx(battle and battle.game,
          world.width,world.height)
        local geo=battleHudGeometry(world.width,world.height,liftPx,
          battle and battle.game)
        local stage=geo.portraitStage or mobilePortraitStageRectPx(
          battle and battle.game,world.width,world.height)
        local desiredY=(stage and stage.bottom or 0)+3
        local scalePx=math.max(1,math.floor(world.width/160))
        local available=math.max(48,world.height-desiredY)
        scalePx=math.max(1,math.min(scalePx,math.floor(available/48)))
        local x=ox+(world.width-160*scalePx)*0.5/dpiX
        local y=oy+desiredY/dpiY
        return {x=x,y=y,w=160*scalePx/dpiX,h=48*scalePx/dpiY,
          orientation=orient}
      end
    end
    local scale=math.min(vw/160,vh/144)
    local x=math.floor(ox+(vw-160*scale)*0.5+0.5)
    local dpiY=tonumber(viewport and viewport.dpiY) or 1
    if not (dpiY>1e-6) then dpiY=1 end
    local world=battleWorldMetrics()
    local liftPx=world and mobileScreenPositionLiftPx(battle and battle.game,
      world.width,world.height) or 0
    local y=math.floor(oy+vh-48*scale-liftPx/dpiY+0.5)
    return {x=x,y=y,w=160*scale,h=48*scale,orientation=orient}
  end

  mod._kimBattleMoveMenu = assert((loadstring or load)(assert(mod:read("lib/battle_move_menu.lua")),
    "@"..mod.path.."/lib/battle_move_menu.lua"))()(mod)
  mod._kimBattleMoveMenu.installSourceGuard(function(battle)
    return not IS_GEN2 and battleLiteFullScreenActive()
      and not battleChildMenuOpen(battle and battle.game, battle)
  end)

  mod.hooks:wrap("battle.move_grid_navigation", function(nextFn, battle)
    if battle and battle.phase=="moveSelect" and not IS_GEN2
        and battleLiteFullScreenActive() then return true end
    return nextFn(battle)
  end)

  local function drawNativeBattleText(battle, viewport)
    local isMoveMenu = battle.phase == "moveSelect" and not IS_GEN2
    local ox,oy,vw,vh=battleUiViewportRect(battle and battle.game,viewport)
    local orient=touchBattleOrientation(battle and battle.game)
    local x,y,sx,sy
    if orient=="portrait" then
      local dpiX=tonumber(viewport and viewport.dpiX) or 1
      local dpiY=tonumber(viewport and viewport.dpiY) or 1
      if not (dpiX>1e-6) then dpiX=1 end
      if not (dpiY>1e-6) then dpiY=1 end
      local world=battleWorldMetrics()
      if world then
        local liftPx=mobileScreenPositionLiftPx(battle and battle.game,
          world.width,world.height)
        local geo=battleHudGeometry(world.width,world.height,liftPx,
          battle and battle.game)
        local stage=geo.portraitStage or mobilePortraitStageRectPx(
          battle and battle.game,world.width,world.height)
        -- Match the portrait mock: the native command/dialog strip begins
        -- immediately below the contained battlefield. The player HUD now
        -- overlaps the field above, so it must no longer push the dialog down.
        local desiredY=(stage and stage.bottom or 0)+3
        local scalePx=math.max(1,math.floor(world.width/160))
        local available=math.max(48,world.height-desiredY)
        scalePx=math.max(1,math.min(scalePx,math.floor(available/48)))
        x=ox+(world.width-160*scalePx)*0.5/dpiX
        y=oy+desiredY/dpiY
        sx,sy=scalePx/dpiX,scalePx/dpiY
      end
    end
    if not x then
      local scale = math.min(vw / 160, vh / 144)
      x = math.floor(ox+(vw - 160 * scale) * 0.5 + 0.5)
      local liftUnits=0
      if orient then
        local dpiY=tonumber(viewport and viewport.dpiY) or 1
        if not (dpiY>1e-6) then dpiY=1 end
        local world=battleWorldMetrics()
        local liftPx=world and mobileScreenPositionLiftPx(battle and battle.game,
          world.width,world.height) or 0
        liftUnits=liftPx/dpiY
      end
      y = math.floor(oy+vh - 48 * scale-liftUnits + 0.5)
      sx,sy=scale,scale
    end
    local rect = {x=x,y=y,w=160*sx,h=48*sy}
    if mod._kimBattleMoveMenu.draw(battle, rect, viewport) then return true end
    local ui = menuBattleUi()
    if ui and type(ui.drawBottom) == "function" and ui.drawBottom(battle,rect,viewport) then
      return true
    end
    local layer = not isMoveMenu and captureBattleText(battle) or nil
    if not layer then return false end
    local quad = love.graphics.newQuad(0, 96, 160, 48, 160, 144)
    love.graphics.push("all")
    love.graphics.origin()
    love.graphics.setShader()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(layer, quad, x, y, 0, sx, sy)
    love.graphics.pop()
    return true
  end

  if mod.hooks and type(mod.hooks.wrap) == "function" then
    -- KIM removes the stock battle paper BEFORE the renderer
    -- composites it: BattleState:draw marks the frame, then the renderer's UI
    -- canvas is made transparent while it is still an offscreen source. This
    -- is the important difference from v4, which tried to repaint over the
    -- already-finished centered composite in render.hud and therefore could
    -- not remove it.
    --
    -- Use a lower priority than the integrated Modern UI compose wrapper so
    -- Modern UI can inspect/capture the untouched native source first. On the
    -- unwind, this wrapper clears the exact ctx.uiCanvas that the engine would
    -- otherwise letterbox into the final window. The fullscreen HD arena,
    -- animated battlers, KIM HUD and Modern commands are all redrawn
    -- later in render.hud from their own sources.
    -- v8.6.16 deliberately clears the finished native battle UI canvas here.
    -- KIM now owns the arena and high-resolution battlers;
    -- the few native pieces we still need are reconstructed transparently in
    -- render.hud instead of compositing the complete 160x144 battle surface.
    mod.hooks:wrap("render.compose", function(nextFn, renderer, ctx)
      local result={pcall(nextFn,renderer,ctx)}
      local ok=table.remove(result,1)
      if not ok then error(result[1],0) end
      -- Prefer the BattleState marker published during its draw, but fall back
      -- to the live stack.  On mobile the native intro/dialogue layer can be
      -- composed while a transparent battle child is on top, which previously
      -- left the host's larger trainer + dialogue visible underneath KIM's
      -- reconstructed pair.  Party/Bag remain explicit full-screen owners and
      -- are never scrubbed here.
      local battle=pendingFullscreenBattle
      local composeGame=nil
      do
        local okGame,Game=pcall(require,"src.core.Game")
        if okGame then composeGame=Game end
      end
      if not battle and composeGame then battle=currentBattleState(composeGame) end
      local childMenuOpen=battle and composeGame
        and battleChildMenuOpen(composeGame,battle) or false
      -- PotatoVoxel is also a cooperative scene owner on mobile: its world and
      -- camera stay live, but when KIM owns the HUD/Modern lower panel we must
      -- remove the same finished native battle UI surface that Battle Lite
      -- removes. Otherwise the source trainer and native move menu survive
      -- underneath KIM's reconstructed trainer + Modern UI, producing the
      -- duplicate trainer and stacked attack menus seen in v83.
      local externalKimHudStage=false
      if battle and type(mod._kantoInMotionExternalStageUsesKimHud)=="function" then
        local okExternal,value=pcall(mod._kantoInMotionExternalStageUsesKimHud,battle)
        externalKimHudStage=okExternal and value==true
      end
      local mobileExternalKimHudStage=externalKimHudStage
        and type(mod._kantoInMotionNativeMobileHost)=="function"
        and mod._kantoInMotionNativeMobileHost() or false
      if battle and not childMenuOpen
          and (battleLiteFullScreenActive() or mobileExternalKimHudStage)
          and ctx and ctx.uiCanvas and love and love.graphics then
        -- KIM fullscreen ownership: Modern UI has already had a chance to
        -- inspect/capture the untouched source (priority 100). Now remove the
        -- entire native battle canvas before Gen1Recomp can scale it over the
        -- fullscreen arena. Transparent trainer/native-effect pieces are
        -- reconstructed in render.hud from drawPicsLayer/drawAnimLayer only.
        love.graphics.push("all")
        love.graphics.setCanvas(ctx.uiCanvas)
        local touchOrient=touchBattleOrientation(battle.game)
        local modernLower=battleModernUiActive(battle.game,battle)
        local directLower=not modernLower and directBattleBottom(battle)
        local nativeVanilla = battleLiteFullScreenActive()
          and battleBackgroundMode() == "native"
          and mod.options:get("battleSprites") == false
        local cw,ch=ctx.uiCanvas:getDimensions()
        love.graphics.setBlendMode("replace","premultiplied")
        love.graphics.setColor(0,0,0,0)
        if nativeVanilla then
          -- NATIVE FIT + vanilla sprites is intentionally different from the
          -- fullscreen KIM-sprite path. withoutBattleBackgroundFill() has
          -- already made the stock battle paper transparent, so the finished
          -- upper 96 rows now contain exactly what we want: Gen1Recomp's real
          -- vanilla battlers and native attack/effect layer at their original
          -- 160x144 coordinates. Preserve those pixels instead of scrubbing
          -- them and trying to reconstruct settled Pokemon later.
          --
          -- Modern UI owns the lower 48 rows. Portrait also redraws its native
          -- lower strip at a safe final-window Y, so clear only that lower
          -- source region in those two cases. Desktop/landscape with Modern UI
          -- OFF keeps the native bottom strip as well.
          if modernLower or touchOrient == "portrait" or battle.phase == "moveSelect" or directLower then
            local split = ch * (96 / 144)
            love.graphics.rectangle("fill",0,split,cw,ch-split)
          end
        elseif touchOrient~="portrait" and not modernLower and battle.phase ~= "moveSelect" and not directLower then
          -- Native ownership fallback. When integrated Modern UI is OFF, keep
          -- Gen1Recomp's real bottom 48-row command/move/message strip alive on
          -- desktop and mobile landscape. KIM still removes the upper 96 rows
          -- because its fullscreen arena + KIM HP/status HUD own
          -- those surfaces. Portrait is redrawn separately at its safe Y.
          love.graphics.rectangle("fill",0,0,cw,ch*(96/144))
        else
          -- Modern UI owns the lower surface, or portrait needs its custom
          -- vertical stack. Remove the source strip and let the appropriate
          -- final-window presenter draw it later.
          love.graphics.clear(0,0,0,0)
        end
        love.graphics.pop()
      end
      return unpackCompat(result)
    end, 50)

    -- Modern UI owns the lower command/message layer when selected.  The
    -- source text box is not needed in that mode and would otherwise update
    -- underneath the final-window compositor.
    mod.hooks:wrap("battle.bottom_ui_visible", function(nextFn, state)
      local externalKimStage = state
        and type(mod._kantoInMotionExternalStageUsesKimHud) == "function"
        and mod._kantoInMotionExternalStageUsesKimHud(state) == true
      if (battleLiteFullScreenActive() or externalKimStage)
          and battleModernUiActive(state and state.game,state) then
        if state then state._kantoInMotionBottomUiSuppressed = true end
        return false
      end
      if state then state._kantoInMotionBottomUiSuppressed = nil end
      return nextFn(state)
    end, 20000)

    -- Kanto in Motion is the HP/status renderer while its battle HUD is active.
    -- Hide the source copy, but briefly fail open while captureBattleHud redraws
    -- those exact native glyphs into its transparent scratch texture.
    mod.hooks:wrap("battle.status_hud_visible", function(nextFn, state)
      -- KIM is the visible HP/status renderer whenever its battle HUD is
      -- active, including mobile Battle Art stage-only. captureBattleHud sets
      -- this private flag so the native glyphs can be redrawn into KIM's
      -- transparent scratch texture without exposing a second source HUD.
      if state and state._kantoInMotionHudCapture then return true end
      if battleLiteHudActive() then
        if state then state._kantoInMotionStatusHudSuppressed = true end
        return false
      end
      if state then state._kantoInMotionStatusHudSuppressed = nil end
      return nextFn(state)
    end, 20000)

    -- Final-window battle composition. KIM draws only the pieces it owns:
    -- the transparent native send-out/effect layer, optional native fallback
    -- text, the Modern lower panel, shiny encounter cue, and one HP/status HUD.
    mod.hooks:wrap("render.hud", function(nextFn, game, viewport)
      local battle = currentBattleState(game)
      local active = battle and battleLiteFullScreenActive() or false
      local mobileBattleArtStageOnly = battle
        and type(mod._kantoInMotionMobileBattleArtStageOnlyActive) == "function"
        and mod._kantoInMotionMobileBattleArtStageOnlyActive() == true or false
      local externalKimHudStage = battle
        and type(mod._kantoInMotionExternalStageUsesKimHud) == "function"
        and mod._kantoInMotionExternalStageUsesKimHud(battle) == true or false
      local mobileExternalKimHudStage = externalKimHudStage
        and type(mod._kantoInMotionNativeMobileHost) == "function"
        and mod._kantoInMotionNativeMobileHost() or false

      if not battle or not battleSystemEnabled() or externalBattleSceneOwnerRegistered() then
        restoreBattleLayout(game)
      else
        forceBattleLayoutOG(game)
      end
      if battle then
        battle._kantoInMotionBattleLite =
          (active or mobileBattleArtStageOnly or mobileExternalKimHudStage)
          and true or nil
      end
      if game then
        game._kantoInMotionFullscreenBattle =
          (active or mobileBattleArtStageOnly or mobileExternalKimHudStage)
          and true or nil
      end

      local childMenuOpen =
        (active or mobileBattleArtStageOnly or externalKimHudStage)
        and battleChildMenuOpen(game, battle) or false
      if battle then
        battle._kantoInMotionMobileDialogRect =
          (active or mobileBattleArtStageOnly or mobileExternalKimHudStage)
          and mobileBattleDialogRect(battle,viewport) or nil
        battle._kantoInMotionMobileStageRect = nil
        if active and touchBattleOrientation(battle.game)=="portrait" then
          local world=battleWorldMetrics()
          local stage=world and mobilePortraitStageRectPx(
            battle.game,world.width,world.height) or nil
          if world and stage then
            local dx=tonumber(world.dpiX) or 1
            local dy=tonumber(world.dpiY) or 1
            if not (dx>1e-6) then dx=1 end
            if not (dy>1e-6) then dy=1 end
            battle._kantoInMotionMobileStageRect={
              x=(tonumber(world.unitX) or 0)+(tonumber(stage.x) or 0)/dx,
              y=(tonumber(world.unitY) or 0)+(tonumber(stage.y) or 0)/dy,
              w=(tonumber(stage.width) or 0)/dx,
              h=(tonumber(stage.height) or 0)/dy,
              bottom=(tonumber(world.unitY) or 0)+(tonumber(stage.bottom) or 0)/dy,
              orientation="portrait",
            }
          end
        end
      end

      if (active or mobileExternalKimHudStage) and not childMenuOpen then
        local nativeVanilla = active
          and battleBackgroundMode() == "native"
          and mod.options:get("battleSprites") == false
        -- In NATIVE FIT the real vanilla battlers/effects are retained in the
        -- transparent source battle canvas during render.compose. Do not draw
        -- captureBattleScene a second time here; doing so is unnecessary and
        -- was the path that left settled vanilla Pokemon invisible in v29.
        if not nativeVanilla then
          pcall(drawNativeBattleOverlay,battle,viewport)
        end
        if (touchBattleOrientation(battle and battle.game)=="portrait"
            or battle.phase=="moveSelect" or directBattleBottom(battle))
            and not battleModernUiActive(game,battle) then
          pcall(drawNativeBattleText,battle,viewport)
        end
      end

      -- Battle Art projects ordinary KRBA particles into the 3D scene, but
      -- full-field BG/FG planes must remain screen-fixed. Restore KIM 1.3.7's
      -- final-window plane fallback so Thundershock/Thunder/Thunderbolt/Flash
      -- and every image/color timing plane fills the real window rather than
      -- disappearing or being trapped in the native 160x96 battle surface.
      local krbaBattleArtSession=nil
      local mobileBattleArt = battle and battleArt3DBattleEnabled()
        and type(mod._kantoInMotionNativeMobileHost)=="function"
        and mod._kantoInMotionNativeMobileHost() or false
      if battle and battleArt3DBattleEnabled()
          and type(battle.dramaticShapeShot)=="table"
          and mod.exports
          and type(mod.exports._kantoInMotionKRBAActiveSession)=="function" then
        local okSess,sess=pcall(mod.exports._kantoInMotionKRBAActiveSession)
        if okSess and type(sess)=="table" and not sess.done then
          krbaBattleArtSession=sess
          local backFn = mobileBattleArt and sess.drawBattleArtScreenBackMobile
            or sess.drawBattleArtScreenBack
          if type(backFn)=="function" then pcall(backFn,sess) end
        end
      end

      -- A cooperative external stage (for example PotatoVoxel) can expose the
      -- same projected-foot shot contract. Keep the shiny sparkle/SFX cue
      -- independent from HD-background ownership without importing any Battle
      -- Art-specific renderer code.
      if battle and externalBattleSceneOwnerRegistered()
          and mod._kantoInMotionShinyEncounterFx
          and type(battle.dramaticShapeShot)=="table" then
        local mobile = type(mod._kantoInMotionNativeMobileHost)=="function"
          and mod._kantoInMotionNativeMobileHost()
        local shinyFn = mobile
          and mod._kantoInMotionShinyEncounterFx.drawExternalStageMobile
          or mod._kantoInMotionShinyEncounterFx.drawExternalStage
        if type(shinyFn)=="function" then
          pcall(shinyFn,mod._kantoInMotionShinyEncounterFx,battle,game)
        end
      end

      if krbaBattleArtSession then
        local frontFn = mobileBattleArt
          and krbaBattleArtSession.drawBattleArtScreenFrontMobile
          or krbaBattleArtSession.drawBattleArtScreenFront
        if type(frontFn)=="function" then
          pcall(frontFn,krbaBattleArtSession)
        end
      end

      if battle then battle._kantoInMotionModernLowerDrawn = nil end
      local result = { pcall(function()
        return withTypedBattlePresentationSuppressed(game,
          function() return nextFn(game, viewport) end)
      end) }

      -- RP6/Android Gen 1 can keep the BattleState alive while the integrated
      -- Modern presentation stack fails to publish its battle layer. Native
      -- lower UI is already suppressed in that ownership mode, so that leaves
      -- an otherwise fully playable battle with no dialog/command surface.
      -- Give the integrated module one final-window chance to draw ONLY its
      -- lower panel. A proof flag prevents duplicates when the normal presenter
      -- already succeeded. Crystal/Gen 2 and FR/LG never enter this branch.
      if battle and mod._kantoInMotionNativeMobileGen1()
          and (active or mobileExternalKimHudStage) and not childMenuOpen
          and battleModernUiActive(game,battle)
          and battle._kantoInMotionModernLowerDrawn~=true then
        local fallback=mod.exports
          and mod.exports._kantoInMotionDrawModernBattleLower or nil
        if type(fallback)=="function" then
          local okFallback,drew=mod._kantoInMotionGuardedMobileCall(
            "Modern battle lower fallback",fallback,game,battle,viewport)
          if okFallback and drew==true
              and not mod._kantoInMotionModernLowerFallbackLogged then
            mod._kantoInMotionModernLowerFallbackLogged=true
            if mod.log and type(mod.log.info)=="function" then
              pcall(mod.log.info,mod.log,
                "Android Gen1 Modern battle lower-panel fallback engaged")
            end
          end
        end
      end

      -- Same ownership as the user's original KIM 1.3.7:
      -- Battle Art supplies the 3D stage; KIM captures/draws the HP/status HUD.
      -- drawBattleHud applies KIM's HUD COLOR shader, so INVERTED comes from
      -- KIM rather than Battle Art's own color option.
      if (active or mobileBattleArtStageOnly or externalKimHudStage)
          and not childMenuOpen and battleLiteHudActive() then
        drawBattleHud(battle, viewport, select(1, battleOffsets(battle)))
      end

      if pendingFullscreenBattle == battle then pendingFullscreenBattle = nil end
      if game then game._kantoInMotionFullscreenBattle = nil end
      if battle then
        battle._kantoInMotionMobileDialogRect = nil
        battle._kantoInMotionMobileStageRect = nil
        if not (active or mobileBattleArtStageOnly) then
          battle._kantoInMotionBattleLite = nil
        end
      end
      local ok = table.remove(result, 1)
      if not ok then error(result[1], 0) end
      return unpackCompat(result)
    end, 20000)
  end


  -- Colosseum Inspired UI can expose a small portrait-provider contract.
  -- Prefer that contract when present because Colosseum deliberately owns its
  -- final portrait composition. Older/unpatched builds still benefit from the
  -- standard engine sprite bridge when they use the normal resolved pipeline.
  local function installColosseumAnimationAdapter()
    local handle = mod.find and mod.find("colosseum_ui_overhaul") or nil
    local contract = handle and type(handle.exports) == "table"
      and handle.exports.portraitProvider or nil
    if not (type(contract) == "table"
        and tonumber(contract.apiVersion or 0) >= 1
        and type(contract.setProvider) == "function") then
      return false
    end

    local function provider(_, mon, kind)
      if not menuSpritesEnabled() or type(mon) ~= "table" or not mon.species then
        return nil
      end
      kind = tostring(kind or ""):lower()
      if not FRAME_BRIDGE_KINDS[kind] then return nil end
      local front, generation, species, shiny = bridgeFront(
        mon.species, selectedGeneration(), mon)
      if not front then return nil end
      local image = renderPresentationFrame(front, generation, species, menuPresentationFrame(front),
        "front", shiny and "shiny" or "normal", true)
      if not image then return nil end
      return image, { trueColor = true, kantoInMotion = true }
    end

    local ok, accepted = pcall(contract.setProvider, provider)
    if not ok or accepted == false then return false end
    if mod.log and type(mod.log.info) == "function" then
      mod.log:info("Colosseum UI animated portrait provider connected")
    end
    return true
  end

  pcall(installColosseumAnimationAdapter)


  -- Vanilla Gen1Recomp Summary and Pokedex entry pages cache their image once
  -- when the screen opens. Refresh that image with our current animation frame
  -- immediately before the native draw. Gen1 Modern UI consumes getSprite()
  -- directly, so this path is only visible when the stock UI owns the screen.
  local function patchVanillaScreens()
    if IS_GEN2 then return end
    local okDex, DexEntryMenu = false, nil
    if not IS_GEN2 then okDex, DexEntryMenu = pcall(require, "src.ui.DexEntryMenu") end
    if okDex and type(DexEntryMenu) == "table" then
      if type(DexEntryMenu.new) == "function" and not DexEntryMenu._animatedMenuPokemonNew then
        local originalNew = DexEntryMenu.new
        DexEntryMenu._animatedMenuPokemonNew = originalNew
        DexEntryMenu.new = function(game, speciesOrOpts, ...)
          local self = originalNew(game, speciesOrOpts, ...)
          local species = self and self.def and self.def.id
          local animated = species and getSprite(species, { kind = "dex" })
          animated = animated and fitStockPortrait(animated, 56, 56) or nil
          if self and animated then
            self.sprite, self.spriteTrueColor = animated, true
          end
          return self
        end
      end

      -- Patch the shared static renderer rather than only DexEntryMenu:draw().
      -- The stock Pokedex and printer paths both use this function, so the
      -- animated portrait remains available anywhere the vanilla entry page is
      -- rendered while Modern UI is disabled.
      if type(DexEntryMenu.render) == "function" and not DexEntryMenu._animatedMenuPokemonRender then
        local originalRender = DexEntryMenu.render
        DexEntryMenu._animatedMenuPokemonRender = originalRender
        DexEntryMenu.render = function(game, def, sprite, forceOwned, trueColor, page, ...)
          local species = def and def.id
          local animated = species and getSprite(species, { kind = "dex" })
          animated = animated and fitStockPortrait(animated, 56, 56) or nil
          if animated then
            sprite, trueColor = animated, true
          end
          return originalRender(game, def, sprite, forceOwned, trueColor, page, ...)
        end
      end
    end
  end
  patchVanillaScreens()

  -- Gold/Crystal have parallel menu classes rather than the Gen 1 Summary /
  -- DexEntry / EvolutionState classes.  Patch the actual Gen 2 picture
  -- methods directly so the selected Kanto in Motion atlas remains live.
  local function patchGen2Screens()
    if not IS_GEN2 then return end
    if gen2CleanUiHandle() then
      pcall(installStockGen2CleanUiBridge)
      return
    end

    local function modernUiEnabled()
      return integratedModernUiEnabled()
    end

    local function fillPortraitBox(x, y, w, h)
      local G = love.graphics
      if modernUiEnabled() then
        G.setColor(0.095, 0.022, 0.036, 1)
      else
        G.setColor(1, 1, 1, 1)
      end
      G.rectangle("fill", x, y, w, h)
      G.setColor(1, 1, 1, 1)
    end

    local function drawCenteredPortrait(image, x, y, w, h)
      if not image or type(image.getDimensions) ~= "function" then return false end
      local iw, ih = image:getDimensions()
      if not iw or not ih or iw <= 0 or ih <= 0 then return false end

      -- Gen 2's Summary/Pokedex drawWidescreen path already scales the native
      -- 160x144 coordinate system directly into the window. Draw KIM's original
      -- HD frame HERE instead of first rasterizing it into a 56x56 Canvas.
      -- The outer Gen 2 transform then samples the source art at final window
      -- resolution, which preserves the HD detail.
      local scale = math.min(w / iw, h / ih)
      local dw, dh = iw * scale, ih * scale
      local dx = x + (w - dw) * 0.5
      local dy = y + (h - dh) * 0.5

      fillPortraitBox(x, y, w, h)
      love.graphics.setShader()
      love.graphics.setColor(1, 1, 1, 1)
      if image.setFilter then pcall(image.setFilter, image, "linear", "linear") end
      love.graphics.draw(image, dx, dy, 0, scale, scale)
      if image.setFilter then pcall(image.setFilter, image, "nearest", "nearest") end
      love.graphics.setColor(1, 1, 1, 1)
      return true
    end

    -- #DEX main/entry picture. Gen 2 places the frontpic in a 7x7 tile block
    -- at the coordinates passed to drawPic(). Preserve the question mark for
    -- unseen species and replace only real seen Pokemon.
    local okDex, PokedexMenu = pcall(require, "src.ui.gen2.PokedexMenu")
    if okDex and type(PokedexMenu) == "table"
        and type(PokedexMenu.drawPic) == "function"
        and not PokedexMenu._kantoInMotionGen2DrawPic then
      local nativeDrawPic = PokedexMenu.drawPic
      PokedexMenu._kantoInMotionGen2DrawPic = nativeDrawPic
      PokedexMenu.drawPic = function(self, row, tx, ty, ownColors, ...)
        if menuSpritesEnabled() and row and row.seen
            and row.species then
          local form
          if mod._kimUnownCompat.isSpecies(row.species) then
            local first = self and self.save and tonumber(self.save.firstUnownSeen) or nil
            if not first or first < 1 or first > 26 then
              local list = self and self.save and self.save.unownDex
              first = type(list) == "table" and tonumber(list[1]) or nil
            end
            form = mod._kimUnownCompat.index(first) or 1
          end
          local animated = getSprite(row.species, { kind = "dex", form = form })
          if animated and drawCenteredPortrait(animated, (tx or 0) * 8,
              (ty or 0) * 8, 56, 56) then
            return
          end
        end
        return nativeDrawPic(self, row, tx, ty, ownColors, ...)
      end
    end

    -- Crystal UNOWN MODE is a form list, not a species list.  Keep the
    -- engine-owned caught-order/cursor/word logic and replace only the selected
    -- form's picture with the matching KIM HD A-Z animation.
    if okDex and type(PokedexMenu) == "table"
        and type(PokedexMenu.drawUnownPic) == "function"
        and not PokedexMenu._kantoInMotionGen2UnownPic then
      local nativeDrawUnownPic = PokedexMenu.drawUnownPic
      PokedexMenu._kantoInMotionGen2UnownPic = nativeDrawUnownPic
      PokedexMenu.drawUnownPic = function(self, letter, tx, ty, ...)
        if menuSpritesEnabled() then
          local animated = getSprite(201, { kind = "unown-dex", form = letter })
          if animated and drawCenteredPortrait(animated, (tx or 0) * 8,
              (ty or 0) * 8, 56, 56) then
            return
          end
        end
        return nativeDrawUnownPic(self, letter, tx, ty, ...)
      end
    end

  end
  patchGen2Screens()

  local function setOption(game, key, value)
    local options = game and game.save and game.save.options
    if options then
      options.modOptions = options.modOptions or {}
      options.modOptions[MOD_ID] = options.modOptions[MOD_ID] or {}
      options.modOptions[MOD_ID][key] = value
    end
    local loader = game and game.mods
    if loader then
      loader.modOptions = loader.modOptions or {}
      loader.modOptions[MOD_ID] = loader.modOptions[MOD_ID] or {}
      loader.modOptions[MOD_ID][key] = value
      if loader.events then
        loader.events:emit("mod.options_changed", { mod = MOD_ID, key = key, value = value })
      end
    end
    if game and game.writeOptions then pcall(game.writeOptions, game) end
  end

  mod._kimSettingsGroups.setOption = setOption

  local function optionLabel(row)
    if row.type == "toggle" then return mod.options:get(row.key) and "ON" or "OFF" end
    local current = mod.options:get(row.key)
    if row.type == "number" then return tostring(current or row.default or 0) end
    for _, choice in ipairs(row.choices or {}) do
      if tostring(choice[2]) == tostring(current) then return choice[1] end
    end
    return "----"
  end

  local function stepOption(game, row, direction)
    if row.type == "toggle" then
      setOption(game, row.key, not mod.options:get(row.key))
      return
    end
    if row.type == "number" then
      local value = (tonumber(mod.options:get(row.key)) or row.default or 0) + (direction or 1) * (row.step or 1)
      setOption(game, row.key, math.max(row.min or -math.huge, math.min(row.max or math.huge, value)))
      return
    end
    local choices = row.choices or {}
    if #choices == 0 then return end
    local current, index = mod.options:get(row.key), 1
    for i, choice in ipairs(choices) do
      if tostring(choice[2]) == tostring(current) then index = i break end
    end
    index = (index - 1 + (direction or 1)) % #choices + 1
    setOption(game, row.key, choices[index][2])
  end

  local SETTINGS_SCREEN = "kim1025:settings"
  local UI_SETTINGS_SCREEN = "kim1025:ui_settings"
  local BATTLE_SETTINGS_SCREEN = "kim1025:battle_settings"
  local function buildItems()
    local items = {}
    for _, row in ipairs(mod._kantoInMotionOptionSchema or {}) do
      items[#items + 1] = {id = MOD_ID .. ":" .. row.key, label = row.label,
        right = optionLabel(row), option = row}
    end
    if assetManager and assetManager.screenId then
      items[#items + 1] = {id = MOD_ID .. ":asset_manager", label = "KIM ASSETS",
        right = "OPEN", assetManager = true}
    end
    return items
  end

  local function newSettingsMenu(game, initialPath)
    local menu
    local function refresh(preferredId)
      local oldIndex = menu and menu.index or 1
      local items = buildItems()
      if not menu then return items end
      items = mod._kimSettingsGroups.apply(menu, items, "list", initialPath)
      local found
      if preferredId then
        for i, item in ipairs(items) do if item.id == preferredId then found = i break end end
      end
      menu.index = found or math.max(1, math.min(oldIndex, #items))
    end
    local function step(item, dir)
      if not (item and item.option) then return end
      stepOption(game, item.option, dir)
      refresh(item.id)
    end
    menu = mod.ui.ListMenu.new(game, "KIM1025", {}, {
      wrap = true, keyRepeat = true,
      onChoose = function(item, m)
        if item and item.cancel then
          if not mod._kimSettingsGroups.back(m) and m and m.close then m:close() end
          return
        end
        if item and item.activate then item.activate(); return end
        if item and item.assetManager and assetManager and type(assetManager.open) == "function" then
          assetManager.open(game)
          return
        end
        if item and item.submenu then mod.ui.push(game, item.submenu); return end
        step(item, 1)
      end,
    })
    menu._kimModernSettings = "main"
    refresh()
    menu._kimSettingsNavigation.refresh = refresh
    local baseUpdate = menu.update
    menu.update = function(self, dt)
      local input = self.game and self.game.input
      if input and #self._kimSettingsNavigation.parents > 0 and input:wasPressed("b") then
        mod._kimSettingsGroups.back(self); return
      end
      local item = self.items and self.items[self.index]
      if item and item.option then
        local input = self.game and self.game.input
        if input and input:wasPressed("left") then step(item, -1); return end
        if input and input:wasPressed("right") then step(item, 1); return end
      end
      return baseUpdate(self, dt)
    end
    return menu
  end

  local function newUiSettingsMenu(game)
    return newSettingsMenu(game, "interface")
  end
  local function newBattleSettingsMenu(game)
    return newSettingsMenu(game, "battle")
  end

  local submenuReady = mod.content and mod.content.screens
    and mod.content.screens.register and mod.ui and mod.ui.ListMenu
    and mod.ui.ListMenu.new and mod.ui.push
  if submenuReady then
    mod.content.screens:register(SETTINGS_SCREEN, { new = function(game) return newSettingsMenu(game) end })
    if IS_GEN2 and #gen2UiOptionSchema > 0 then
      mod.content.screens:register(UI_SETTINGS_SCREEN, { new = function(game) return newUiSettingsMenu(game) end })
    end
    mod.content.screens:register(BATTLE_SETTINGS_SCREEN, { new = function(game) return newBattleSettingsMenu(game) end })
  end

  local function insertOpenRow(out, row)
    if mod.ui and type(mod.ui.insertBefore) == "function" then
      local inserted = mod.ui.insertBefore(out, "MODS", row)
      if inserted then return inserted end
      inserted = mod.ui.insertBefore(out, "CANCEL", row)
      if inserted then return inserted end
    end
    out[#out + 1] = row
    return out
  end

  mod.hooks:wrap("ui.options.rows", function(next, game, rows)
    local out = next(game, rows)
    if type(out) ~= "table" then return out end
    if submenuReady then
      return insertOpenRow(out, {
        id = "kim1025:settings_open",
        label = "KIM1025",
        text = function() return "OPEN" end,
        value = function() return "OPEN" end,
        activate = function(g) mod.ui.push(g, SETTINGS_SCREEN) end,
      })
    end
    return out
  end)

  -- Integrated Gen 1 battle helpers. The move-animation code/data is the same
  -- KIM 1.3.7 implementation, now paired with the remediated animation/SFX
  -- asset set that passed the user's follow-up scanner.
  if not IS_GEN2 then
    local okHelper,helper=pcall(function()
      local src=assert(mod:read("lib/integrated_krba.lua"))
      local loader=loadstring or load
      return assert(loader(src,"@"..mod.path.."/lib/integrated_krba.lua"))()
    end)
    if okHelper and type(helper)=="function" then
      local okRun,err=pcall(helper,mod)
      if not okRun then
        mod.log:error("integrated KRBA failed: %s",tostring(err))
      end
    else
      mod.log:error("cannot load integrated KRBA: %s",tostring(helper))
    end

    -- Keep the accepted native catch-animation target correction. This module
    -- adjusts only Gen1Recomp's own Pokeball animation; it contains no bundled
    -- move art or move SFX.
    okHelper,helper=pcall(function()
      local src=assert(mod:read("lib/pokeball_target_fix.lua"))
      local loader=loadstring or load
      return assert(loader(src,"@"..mod.path.."/lib/pokeball_target_fix.lua"))()
    end)
    if okHelper and type(helper)=="function" then
      okHelper,helper=pcall(helper,mod,
        directStageGeometry,directSideMetrics,battleWorldMetrics)
      if okHelper then
        mod._kantoInMotionPokeballTargetFix=helper
        mod.exports.integratedPokeballTargetFix=true
      else
        mod.log:error("integrated Pokeball target fix failed: %s",tostring(helper))
      end
    else
      mod.log:error("cannot load integrated Pokeball target fix: %s",tostring(helper))
    end

  end
end
