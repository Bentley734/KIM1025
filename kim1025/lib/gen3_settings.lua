-- Native Game3 settings controls. No drawing/presenter overrides.
return function(mod)
  local okFrlg, FrlgOptions = pcall(require, "src.ui.game3.option_menu")
  local okRse, RseOptions = pcall(require, "src.ui.game3.rse.option_menu")
  local okRs, RsOptions = pcall(require, "src.ui.game3.rs.option_menu")
  local function opt(key, fallback)
    local value = mod.options:get(key)
    if value == nil then return fallback end
    return value
  end
  local KIM_MOD_ID = "kim1025"

  -- Gen 3 does not run the normal mod.ui screen stack directly. Its OPTIONS
  -- screen belongs to src.ui.game3.stack, so trying to mod.ui.push() KIM's
  -- Gen1/2 ListMenu leaves the Game3 OPTIONS layer owning input and nothing
  -- usable appears. Build a native Game3 option page from KIM's live schema
  -- instead. The source OptionMenu still owns navigation/input/persistence;
  -- this only supplies rows for the child page.
  local function setKimOption(ctx, key, value)
    local game = ctx and ctx.game
    local options = game and game.save and game.save.options
    if options then
      options.modOptions = options.modOptions or {}
      options.modOptions[KIM_MOD_ID] = options.modOptions[KIM_MOD_ID] or {}
      options.modOptions[KIM_MOD_ID][key] = value
    end
    local loader = game and game.mods
    if loader then
      loader.modOptions = loader.modOptions or {}
      loader.modOptions[KIM_MOD_ID] = loader.modOptions[KIM_MOD_ID] or {}
      loader.modOptions[KIM_MOD_ID][key] = value
      if loader.events and type(loader.events.emit) == "function" then
        pcall(loader.events.emit, loader.events, "mod.options_changed",
          { mod = KIM_MOD_ID, key = key, value = value })
      end
    end
    if game and type(game.writeOptions) == "function" then
      pcall(game.writeOptions, game)
    end
  end

  local function kimCurrent(row)
    if not row then return nil end
    local value = opt(row.key, row.default)
    if value == nil then value = row.default end
    return value
  end

  local function kimValueLabel(row)
    if not row then return "" end
    local value = kimCurrent(row)
    if row.type == "toggle" then
      return value ~= false and "ON" or "OFF"
    end
    if row.type == "choice" then
      for _, choice in ipairs(row.choices or {}) do
        if tostring(choice[2]) == tostring(value) then
          return tostring(choice[1] or choice[2] or "")
        end
      end
      return tostring(value == nil and "----" or value)
    end
    return tostring(value == nil and "" or value)
  end

  local function stepKimRow(ctx, row, dir)
    if not row or not row.key then return false end
    if row.type == "toggle" then
      setKimOption(ctx, row.key, kimCurrent(row) == false)
      return true
    end
    if row.type == "choice" then
      local choices = row.choices or {}
      if #choices == 0 then return false end
      local current = kimCurrent(row)
      local index = 1
      for i, choice in ipairs(choices) do
        if tostring(choice[2]) == tostring(current) then index = i break end
      end
      local delta = (tonumber(dir) or 1) < 0 and -1 or 1
      index = ((index - 1 + delta) % #choices) + 1
      setKimOption(ctx, row.key, choices[index][2])
      return true
    end
    return false
  end

  local function kimOptionRow(ctx, spec)
    if not (type(spec)=="table" and type(spec.key)=="string") then return nil end
    if spec.type ~= "toggle" and spec.type ~= "choice" then return nil end
    local row = spec
    return {
      id = "kim:" .. row.key,
      label = tostring(row.label or row.key),
      description = tostring(row.description or ""),
      value = function() return kimValueLabel(row) end,
      step = function(_, dir) return stepKimRow(ctx, row, dir) end,
      _kimSpec = row,
    }
  end

  local function kimPages(menu,isRse)
    if isRse then
      local st=menu and menu._st
      return st and st.pages
    end
    return menu and menu._pages
  end

  local function pushKimPage(menu,isRse,title,section,rows)
    local pages=kimPages(menu,isRse)
    if type(pages)~="table" or type(rows)~="table" then return false end
    pages[#pages+1]={
      title=title,
      rows=rows,
      index=1,
      scroll=0,
      _kimDirectSettings=true,
      _kimSection=section,
    }
    menu.cursor=1
    return true
  end

  local function buildKimRootRows(menu, isRse, ctx)
    local rows = {}
    for _, spec in ipairs(mod._kantoInMotionOptionSchema or {}) do
      local row = kimOptionRow(ctx, spec)
      if row then rows[#rows+1] = row end
    end
    local manager = mod._kimAssetManager
    if manager then rows[#rows+1] = {
      id="kim:assets", label="KIM ASSETS", value=function() return "OPEN" end,
      activate=function() manager.open(ctx and ctx.game) end,
    } end
    return rows
  end
  local function openKimSettingsPage(menu, isRse, ctx)
    local rows=buildKimRootRows(menu,isRse,ctx)
    if #rows==0 then return false end
    return pushKimPage(menu,isRse,"KIM1025","main",rows)
  end

  -- Open the same complete native option page directly from the Start Menu.
  mod._kimOpenGen3Settings = function(game, session)
    local okScreens, Screens = pcall(require, "src.ui.game3.screens")
    local menu = okScreens and Screens.get and Screens.get("option", session) or nil
    if not (menu and type(menu.show) == "function") then return false end
    menu.show({ game = game, session = session })
    local isRse = menu == RseOptions
    local ctx = isRse and menu._st and menu._st.ctx or menu._ctx
      or {game=menu._game or game,session=menu._session or session,options=menu._engine}
    return openKimSettingsPage(menu, isRse, ctx)
  end

  local function kimSettingsRow(menu, isRse)
    return {
      id = "kanto_in_motion",
      label = "KIM1025",
      value = function() return "OPEN" end,
      activate = function(ctx)
        local ok, opened = pcall(openKimSettingsPage, menu, isRse, ctx)
        if not ok or opened ~= true then
          mod._kantoInMotionGen3OptionsKimOpenError = tostring(ok and "NO KIM OPTION ROWS" or opened)
        else
          mod._kantoInMotionGen3OptionsKimOpenError = nil
        end
      end,
    }
  end

  local function menuPage(menu,isRse)
    local pages
    if isRse then
      local st=menu and menu._st; pages=st and st.pages
    else
      pages=menu and menu._pages
    end
    return type(pages)=="table" and pages[#pages] or nil
  end

  local function injectKimSettingsRow(menu, isRse)
    local pages
    if isRse then
      local st = menu and menu._st
      pages = st and st.pages
    else
      pages = menu and menu._pages
    end
    local top = type(pages) == "table" and pages[1] or nil
    local rows = top and top.rows
    if type(rows) ~= "table" then return end
    for _, row in ipairs(rows) do
      if row and row.id == "kanto_in_motion" then return end
    end
    local at = #rows + 1
    for i, row in ipairs(rows) do
      if row and row.id == "mods" then
        at = i
        break
      end
    end
    table.insert(rows, at, kimSettingsRow(menu, isRse))
  end

  for _, entry in ipairs({{FrlgOptions,false},{RseOptions,true},{RsOptions,false}}) do
    local menu, isRse = entry[1], entry[2]
    if type(menu) == "table" and type(menu.show) == "function" and not menu._kimFocusedSettings then
      local native = menu.show
      menu.show = function(...)
        local result = {native(...)}
        injectKimSettingsRow(menu, isRse)
        return (table.unpack or unpack)(result)
      end
      menu._kimFocusedSettings = true
    end
  end
  return true
end
