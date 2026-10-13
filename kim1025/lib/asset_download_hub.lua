-- Persistent, independently versioned original KIM and KIM1025 artwork packs.
return function(mod, installManager)
  local ID = "kim1025:asset_downloads"
  local GEN3 = tonumber(mod.generation) == 3
  local original = installManager(mod, { embedded = true })
  local extra = installManager(mod, {
    embedded = true, screenId = "kim1025:artwork_download", repo = "Bentley734/KIM1025",
    packId = "kim1025_assets", version = "1.0.0",
    assetURL = "https://github.com/Bentley734/KIM1025/releases/download/v1.7.3/KIM1025-assets-v1.0.0.zip",
    assetSize = 464270943, cacheNamespace = "kim1025_assets",
    assetName = "KIM1025-assets-v1.0.0.zip", indexOnly = true, verifyFiles = true,
    allowedPrefix = "assets/battle/backgrounds/aspect/",
    legacyRoots = { "assets/battle/backgrounds/aspect" }, legacyExpectedFiles = 216,
  })
  local hub = { screenId = ID, original = original, extra = extra, selection = 1,
    queue = {}, active = nil, state = "idle", opening = false, game = nil }
  local Stack, Window
  if GEN3 then
    Stack = require("src.ui.game3.stack")
    Window = require("src.ui.game3.window")
  end
  function hub:isComplete() return original:isComplete() and extra:isComplete() end
  function hub:sourceRevision() return original:sourceRevision() + extra:sourceRevision() end
  function hub:statusLabel() return self:isComplete() and "READY" or "DOWNLOAD" end
  function hub:managerFor(path)
    if type(path) == "string" and path:sub(1, 33) == "assets/battle/backgrounds/aspect/" then return extra end
    return original
  end
  function hub:read(path) return self:managerFor(path):read(path) end
  function hub:image(path) return self:managerFor(path):image(path) end
  function hub:exists(path) return self:managerFor(path):exists(path) end
  function hub:deferMissing()
    for _, pack in ipairs({ original, extra }) do if not pack:isComplete() then pack:defer() end end
  end
  function hub:close()
    self:deferMissing()
    if GEN3 then Stack.pop(ID) elseif self.game and self.game.stack then self.game.stack:pop() end
  end
  function hub:advance()
    self.active = nil
    while #self.queue > 0 do
      local pack = table.remove(self.queue, 1)
      if not pack:isComplete() then
        self.active = pack
        pack:start()
        return
      end
    end
    self.state = "done"
  end
  function hub:start(which)
    self.state = "installing"
    self.queue = which == "original" and { original } or which == "extra" and { extra }
      or { original, extra }
    self:advance()
  end
  function hub:update()
    local pack = self.active
    if not pack then return end
    pack:update()
    if pack.state == "done" then
      -- A migrated original base still needs its Unown/Deoxys supplements.
      if not pack:isComplete() then pack:start() else self:advance() end
    end
    if pack.state == "deleted" then self.active = nil; self.state = "menu" end
  end
  local function pressed(input, key)
    return input and type(input.wasPressed) == "function" and input:wasPressed(key)
  end
  function hub:handleInput(input)
    local pack = self.active
    if pack then
      if pack.state == "error" or pack.state == "delete_error" then
        if pressed(input, "a") then
          if pack.state == "delete_error" then pack:beginDelete() else pack:start() end
        elseif pressed(input, "b") then pack:cancel(); self.queue = {}; self.active = nil; self:close() end
      elseif pack.state == "checking" or pack.state == "downloading" then
        if pressed(input, "b") then pack:cancel(); self.queue = {}; self.active = nil; self:close() end
      end
      return
    end
    if self.state == "confirm_delete" then
      if pressed(input, "a") then
        self.active = self.deleteTarget
        self.active:beginDelete()
        self.state = "removing"
      elseif pressed(input, "b") then self.state = "menu" end
      return
    end
    if self.state == "done" then
      if pressed(input, "a") or pressed(input, "b") then self:close() end
      return
    end
    local max = self.state == "remove_menu" and 2 or 4
    if pressed(input, "up") then self.selection = (self.selection - 2) % max + 1 end
    if pressed(input, "down") then self.selection = self.selection % max + 1 end
    if pressed(input, "b") then
      if self.state == "remove_menu" then self.state = "menu"; self.selection = 4 else self:close() end
    elseif pressed(input, "a") then
      if self.state == "remove_menu" then
        self.deleteTarget = self.selection == 1 and original or extra
        self.state = "confirm_delete"
      elseif self.selection == 4 then self.state = "remove_menu"; self.selection = 1
      else self:start(self.selection == 2 and "original" or self.selection == 3 and "extra" or "all") end
    end
  end
  local function mb(bytes) return string.format("%.1f", (tonumber(bytes) or 0) / 1000000) end
  function hub:lines()
    local pack = self.active
    local name = pack == extra and "KIM1025" or "KIM"
    if pack then
      if pack.state == "error" or pack.state == "delete_error" then
        local errorText = tostring(pack.error or "Please retry"):gsub("\n", " ")
        return { name .. " ERROR", errorText:sub(1,18), errorText:sub(19,36), errorText:sub(37,54), "A RETRY  B LATER" }
      elseif pack.state == "checking" then return { name .. " ASSETS", "CHECKING RELEASE", "", "", "B CANCEL" }
      elseif pack.state == "downloading" then
        return { name .. " ASSETS", "DOWNLOADING", mb(pack.downloadBytes) .. "/" .. mb(pack.downloadTotal) .. " MB", "", "B CANCEL" }
      elseif pack.state == "migrating" then
        return { name .. " ASSETS", "SAVING LOCAL ART", tostring(pack.legacyCount) .. "/" .. tostring(#pack.legacyFiles) .. " FILES", "NO DOWNLOAD NEEDED", "PLEASE WAIT" }
      elseif pack.state == "deleting" then
        return { "REMOVING " .. name, tostring(pack.deletedCount) .. "/" .. tostring(#pack.deleteFiles) .. " FILES", "", "", "PLEASE WAIT" }
      end
      return { name .. " ASSETS", "INSTALLING", tostring(pack.extractedCount) .. "/" .. tostring(#pack.extractFiles) .. " FILES", "", "PLEASE WAIT" }
    end
    if self.state == "done" then return { "ASSETS READY", "ART SAVED IN CACHE", "SMALL MOD UPDATES", "", "A CONTINUE B CLOSE" } end
    if self.state == "confirm_delete" then
      return { "REMOVE ASSETS?", self.deleteTarget == extra and "KIM1025 ARTWORK" or "ORIGINAL KIM ART", "CAN DOWNLOAD AGAIN", "", "A REMOVE B CANCEL" }
    end
    local labels = self.state == "remove_menu" and { "REMOVE KIM", "REMOVE KIM1025" }
      or { "DOWNLOAD ALL", "DOWNLOAD KIM", "DOWNLOAD KIM1025", "REMOVE ASSETS" }
    local out = {}
    for i, label in ipairs(labels) do out[i] = "  " .. label end
    out[5] = self.state == "remove_menu" and "A SELECT B BACK" or "A SELECT B CLOSE"
    return out
  end
  function hub:draw()
    local function drawSelector(x, firstY)
      if self.active or (self.state ~= "idle" and self.state ~= "menu" and self.state ~= "remove_menu") then return end
      local G = love and love.graphics
      if not (G and type(G.polygon) == "function") then return end
      local y = firstY + (self.selection - 1) * 20
      -- Draw chrome independently of the ROM charmap: ASCII ">" is not a
      -- portable selector glyph across Gen 1/2/3 fonts and translations.
      G.push("all")
      G.setShader()
      G.setColor(.08, .08, .12, 1)
      G.polygon("fill", x, y + 1, x + 6, y + 4, x, y + 7)
      G.pop()
    end
    local function content()
      local lines = self:lines()
      if GEN3 then
        local G = love.graphics
        G.setShader(); G.setScissor(); G.setColor(1,1,1,1); G.rectangle("fill",0,0,240,160)
        Window.stdFrame(Window.template(1,1,28,18))
        local function line(text,y) Window.printPx(text,16,y,{ maxWidth=208, colors={fg={.08,.08,.12,1},shadow={.78,.78,.82,1}} }) end
        line("KIM ASSETS",14)
        line(self.promptExtra and "NEW KIM1025 ASSETS" or "ASSET DOWNLOADS",30)
        for i=1,5 do line(lines[i] or "",48+(i-1)*20) end
        drawSelector(16,48)
      elseif mod.ui and mod.ui.Font then
        local F=mod.ui.Font
        F.drawBox(0,0,20,18); F.draw("KIM ASSETS",8,8)
        F.draw(self.promptExtra and "NEW KIM1025 ASSETS" or "ASSET DOWNLOADS",8,24)
        for i=1,5 do F.draw(lines[i] or "",8,44+(i-1)*20) end
        drawSelector(8,44)
      end
    end
    if GEN3 then
      love.graphics.push("all")
      local ok,err=pcall(content)
      love.graphics.pop()
      if not ok then error(err,0) end
    else content() end
  end
  local function open(game)
    hub.game = game or hub.game
    if not hub.game or hub.opening then return end
    hub.opening = true
    if not hub.active then hub.state = "menu"; hub.queue = {} end
    hub.promptExtra = original:isComplete() and not extra:isComplete()
    hub.selection = hub.promptExtra and 3 or 1
    local ok,err=pcall(function()
      if GEN3 then
        Stack.push(ID,{update=function()hub:update()end,handleInput=function(input)hub:handleInput(input)end,
          draw=function()hub:draw()end},{hideBelow=true,fullscreen=true})
      else mod.ui.push(hub.game,ID) end
    end)
    hub.opening = false
    if not ok and mod.log and mod.log.error then mod.log:error("KIM Assets could not open: %s",tostring(err)) end
  end
  hub.open = open
  if not GEN3 then
    mod.content.screens:register(ID,{new=function(game)
      return {isOpaque=true,update=function()hub:update();hub:handleInput(game.input)end,draw=function()hub:draw()end}
    end})
  end
  local function needsPrompt()
    return (not original:isComplete() and not original:isDeferred())
      or (not extra:isComplete() and not extra:isDeferred())
  end
  hub.autoPromptArmed = needsPrompt()
  mod.events:on("game.ready",function(ev)
    hub.game=ev and ev.game or nil
    if GEN3 and hub.autoPromptArmed and hub.game then hub.autoPromptArmed=false; open(hub.game) end
  end)
  mod.events:on("screen.pushed",function()
    if hub.autoPromptArmed and hub.game and not hub.opening then
      hub.autoPromptArmed=false; open(hub.game)
    end
  end)
  -- The downloader is opened from KIM1025 settings on every generation.
  -- Do not add a second entry to the game options page.
  return hub
end
