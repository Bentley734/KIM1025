-- A dedicated flat move panel; never crop the native Gen1 TYPE/PP window.
return function(mod)
  local Font = require('src.render.Font')
  local TypeChart = require('src.battle.TypeChart')
  local api = {}
  local function customizer()
    if not (mod and type(mod.find)=='function') then return nil end
    local found,menu=pcall(mod.find,'gen3transparency')
    if found and menu and menu.exports and menu.exports.battleUi then return menu.exports.battleUi end
    local ok,h=pcall(mod.find,'battleuicustomizer')
    if not ok or not h then ok,h=pcall(mod.find,mod,'battleuicustomizer') end
    local e=ok and h and h.exports
    if type(e)=='table' and type(e.setting)=='function' then return e end
  end
  function api.installSourceGuard(active)
    if not mod then return end
    local function install()
      local ok,B=pcall(require,'src.battle.BattleState')
      if not ok or type(B.drawTextArea)~='function' then return end
      if B.drawTextArea==api.sourceWrapper then return end
      local inner=B.drawTextArea
      local function wrapper(battle,...)
        if battle.phase=='moveSelect' and active(battle) then return end
        return inner(battle,...)
      end
      api.sourceWrapper=wrapper;B.drawTextArea=wrapper
    end
    install()
    if mod.events then
      mod.events:on('mods.loaded',install)
      mod.events:on('game.ready',install)
    end
  end
  function api.layout(rect, dpiX, dpiY)
    dpiX, dpiY = tonumber(dpiX) or 1, tonumber(dpiY) or 1
    if dpiX <= 0 then dpiX=1 end
    if dpiY <= 0 then dpiY=1 end
    local scale = math.min(rect.w*dpiX/336, rect.h*dpiY/64)
    if scale >= 1 then scale=math.floor(scale) end
    return {x=rect.x+(rect.w-336*scale/dpiX)/2,
      y=rect.y+rect.h-64*scale/dpiY, sx=scale/dpiX,sy=scale/dpiY}
  end
  function api.draw(battle, rect, viewport)
    if battle.phase~='moveSelect' then return false end
    local theme=customizer()
    if theme and theme.moveScreen then return theme.moveScreen.draw(battle,rect,viewport) end
    local g=love.graphics
    local p=api.layout(rect,viewport and viewport.dpiX,viewport and viewport.dpiY)
    g.push('all')
    local ok,err=pcall(function()
      g.origin();g.setShader();g.setScissor()
      g.translate(p.x,p.y);g.scale(p.sx,p.sy)
      local theme=customizer()
      local function emeraldPanel(x,w)
        -- Preserve the imported frame corners and border thickness instead of
        -- squeezing a 240px textbox into the narrow PP/type column.
        if api.emeraldFrame==nil then
          api.emeraldFrame=false
          local loaded,frame=pcall(function()
            local cache=require('src.import.CacheFs')
            local root='emerald/data/generated/gba/pokemon/battle/'
            local src=cache.readAt(root..'manifest.lua')
            local chunk=type(src)=='string' and load(src,'@kim-emerald-frame','t',{})
            local m=chunk and chunk()
            if type(m)~='table' then return end
            local iw,ih=m.textboxW or 256,m.textboxH or 512
            local rgba=cache.readAt(root..'textbox.rgba')
            if type(rgba)~='string' or #rgba~=iw*ih*4 then return end
            local image=g.newImage(love.image.newImageData(iw,ih,'rgba8',rgba))
            image:setFilter('nearest','nearest')
            local parts={}
            local xs,ys={0,12,228},{112,124,148}
            local ws,hs={12,216,12},{12,24,12}
            for row=1,3 do for col=1,3 do
              parts[#parts+1]={quad=g.newQuad(xs[col],ys[row],ws[col],hs[row],iw,ih),
                row=row,col=col,w=ws[col],h=hs[row]}
            end end
            return {image=image,parts=parts}
          end)
          if loaded and frame then api.emeraldFrame=frame end
        end
        if api.emeraldFrame then
          local frame=api.emeraldFrame
          local xs,ys={x,x+12,x+w-12},{0,12,52}
          local ws,hs={12,w-24,12},{12,40,12}
          g.setColor(1,1,1,1)
          for _,part in ipairs(frame.parts) do
            g.draw(frame.image,part.quad,xs[part.col],ys[part.row],0,
              ws[part.col]/part.w,hs[part.row]/part.h)
          end
          g.setColor(.97,.97,.87,1);g.rectangle('fill',x+8,8,w-16,48)
        else
          -- Emerald's red rim also remains available without an Emerald import.
          g.setColor(74/255,66/255,82/255,1);g.rectangle('fill',x,0,w,64)
          g.setColor(214/255,74/255,58/255,1);g.rectangle('fill',x+3,3,w-6,58)
          g.setColor(107/255,165/255,165/255,1);g.rectangle('fill',x+8,8,w-16,48)
          g.setColor(.97,.97,.87,1);g.rectangle('fill',x+8,8,w-16,48)
        end
      end
      local function frames()
        if theme and theme.setting('style',1)==2 then
          emeraldPanel(0,240);emeraldPanel(240,96)
        else
          g.setColor(1,1,1,1)
          Font.drawBox(0,0,30,8);Font.drawBox(30,0,12,8)
        end
      end
      -- Customizer composites opacity once and leaves text at full opacity.
      -- Emerald uses the same imported artwork with fixed-size borders.
      if theme and type(theme.faded)=='function' then theme.faded(frames) else frames() end
      g.setColor(0.08,0.10,0.12,1)
      local moves=battle.player and battle.player.curMoves or {}
      for i=1,4 do
        local col=(i-1)%2;local row=math.floor((i-1)/2)
        local x,y=16+col*112,14+row*26
        local mv=moves[i];local def=mv and battle.data.moves[mv.id]
        Font.draw(def and def.name or mv and tostring(mv.id) or '-',x,y)
        if battle.moveIndex==i then Font.drawCode(0xED,x-9,y) end
        if battle.moveSwapIndex==i and battle.moveIndex~=i then Font.drawCode(0xEC,x-9,y) end
      end
      local selected=moves[battle.moveIndex or 1]
      local def=selected and battle.data.moves[selected.id]
      Font.draw('PP',248,14)
      local pp='--/--'
      if def then
        local base=tonumber(def.pp) or 0
        local maximum=tonumber(selected.maxPp) or base+(selected.ppUps or 0)*math.floor(base/5)
        pp=string.format('%d/%d',tonumber(selected.pp) or 0,maximum)
      end
      Font.draw(pp,328-#pp*8,14)
      Font.draw('TYPE/',248,34)
      local name=def and def.type and TypeChart.displayName(def.type,battle.data) or '--'
      -- The native pixel font is eight pixels wide. Long type names get a
      -- separate line, keeping the detail column legible without stretching.
      Font.draw(name,248,46)
      if battle.player and battle.player.disabledSlot==battle.moveIndex then
        Font.draw('DISABLED',248,24)
      end
    end)
    g.pop()
    if not ok then error(err,0) end
    return true
  end
  return api
end
