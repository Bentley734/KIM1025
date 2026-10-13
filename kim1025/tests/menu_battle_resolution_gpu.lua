-- LOVE regression: real KIM producers retain every Emerald battle-font pixel.
local w=assert(os.getenv('BATTLE_UI_WORKSPACE'))..'/'
local cache=assert(os.getenv('POKEMON_CACHE_ROOT'))..'/'
local kim=w..'.work/latest-sprite-fix/current-source/kim1025/'
local function read(p)local f=io.open(p,'rb');if not f then return end;local s=f:read('*a');f:close();return s end
local function save(canvas,path)local f=assert(io.open(path,'wb'));f:write(canvas:newImageData():encode('png'):getString());f:close()end
package.path=w..'.tools/engine-0358/?.lua;'..w..'.tools/engine-0358/?/init.lua;'..package.path
function love.load()
 local ok,err=xpcall(function()
  local G=love.graphics
  local fsread=love.filesystem.read
  love.filesystem.read=function(p)return read(w..'.tools/engine-0358/'..p) or fsread(p)end
  require('src.core.GameVersion').set('blue')
  local Blob=require('src.import.CacheBlob')
  package.loaded['src.import.CacheFs']={readAt=function(p)local s=read(cache..p);return s and Blob.decode(p,s)end}
  local assets=require('src.render.Assets');assets.register=function()end
  assets.image=function(p)local raw=assert(read(cache..'blue/'..p));local img=G.newImage(love.filesystem.newFileData(raw,'font.png'));img:setFilter('nearest','nearest');return img end
  local GB=require('src.render.Font')
  GB.load({font=assert(loadstring(assert(read(cache..'blue/data/generated/font.lua'))))()})
  local menu={generation=1,exports={},read=function(_,p)return read(w..'MenuCustomizer/'..p)end,
   assets={image=function(_,p)local image=G.newImage(love.filesystem.newFileData(assert(read(w..'MenuCustomizer/'..p)),'font.png'));image:setFilter('nearest','nearest');return image end}}
  local theme=assert(loadstring(menu:read('lib/emerald_theme.lua')))()(menu,function()return true end)
  menu.exports.gbMenus={theme=theme}
  local port=assert(loadstring(menu:read('lib/emerald_native.lua')))()(menu)
  port.useEmeraldFont=function()return true end
  local ui={setting=function(k)return k=='style' and 3 or 100 end,faded=function(fn)return fn()end,
   panel=function(x,y,width,height)G.setColor(1,1,1,1);G.rectangle('fill',x,y,width,height)end}
  ui.canDrawBottom=function(b)return b.phase=='menu' or b.phase=='messages'end
  ui.drawBottom=function(b,r,v)return ui.canDrawBottom(b) and port.bottom(b,1,r,ui,v)end
  menu.exports.battleUi=ui
  local source=assert(read(kim..'main.lua'))
  local function between(first,last)
   local start=assert(source:find(first,1,true));local stop=assert(source:find(last,start+#first,true));return source:sub(start,stop-1)
  end
  local function compile(s,env)local fn=assert(loadstring(s));setfenv(fn,env);return fn()end
  local width,height=1047,699
  local mod={find=function()return menu end,_kimBattleMoveMenu={draw=function()return false end},
   _kantoInMotionNativeMobileGen1=function()return false end}
  local env=setmetatable({love=love,mod=mod,IS_GEN2=false,
   menuBattleUi=function()return ui end,
   battleUiViewportRect=function()return 0,0,width,height end,
   touchBattleOrientation=function()end,battleWorldMetrics=function()end,
   captureBattleText=function()error('Emerald must never pass through GB text capture')end,
   sizedBattleCanvas=function(_,cw,ch)local canvas=G.newCanvas(cw,ch);canvas:setFilter('nearest','nearest');return canvas end,
  },{__index=_G})
  local helpers=between('  local function menuBattleUi()','  local function battleOffsets(')
  local bottom=compile(helpers..between('  local function drawNativeBattleText(','  if mod.hooks and type(mod.hooks.wrap)')..'return drawNativeBattleText',env)
  local checks=0
  local function equalPixels(a,b,label)
   local aa,bb=a:newImageData(),b:newImageData()
   assert(aa:getWidth()==bb:getWidth() and aa:getHeight()==bb:getHeight())
   for y=0,aa:getHeight()-1 do for x=0,aa:getWidth()-1 do
    local r,g,bl,al=aa:getPixel(x,y);local rr,gg,bb,ab=bb:getPixel(x,y)
    assert(math.abs(r-rr)<.002 and math.abs(g-gg)<.002 and math.abs(bl-bb)<.002 and math.abs(al-ab)<.002,label..' differs at '..x..','..y)
   end end
   checks=checks+1
  end
  local battle={phase='messages',shown={GB.encode('Wild KRICKETUNE'),GB.encode('appeared!')},player={name='NIDOKING'},game={}}
  for _,size in ipairs({{1047,699},{1280,720},{5120,1440},{390,844}})do
   width,height=size[1],size[2]
   local scale=math.min(width/160,height/144)
   local rect={x=math.floor((width-160*scale)*.5+.5),y=math.floor(height-48*scale+.5),w=160*scale,h=48*scale}
   for _,phase in ipairs({'menu','messages'})do
    battle.phase=phase
    local actual,reference=G.newCanvas(width,height),G.newCanvas(width,height)
    G.setCanvas(actual);G.origin();G.clear(0,0,0,0);assert(bottom(battle,{}));G.setCanvas()
    G.setCanvas(reference);G.origin();G.clear(0,0,0,0);assert(port.bottom(battle,1,rect,ui,{}));G.setCanvas()
    equalPixels(actual,reference,'Final KIM '..phase..' '..width)
    if width==1047 then save(actual,w..'.work/menu-final-render-fix/kim-direct-'..phase..'.png')end
   end
  end
  -- Execute the production high-resolution HUD capture with real GB->Emerald
  -- glyph mapping, then compare against the full, unscaled battle font.
  menu.exports.battleFontScope=true
  theme.gbScale=function()return .5 end
  theme.gbColors=port.presentationColors
  battle.drawHUDs=function()
   local pen=0
   for _,code in ipairs(GB.encode('NIDOKING 309/309'))do
    assert(theme.gbGlyph(code,pen,0));pen=pen+theme.gbAdvance(code)
   end
  end
  local capture=compile(between('  local function captureBattleHud(','  local BATTLE_HUD_SHADER =')..'return captureBattleHud',env)
  local actual=capture(battle,0)
  local reference=G.newCanvas(320,296)
  G.setCanvas(reference);G.origin();G.clear(0,0,0,0)
  theme.draw('NIDOKING 309/309',0,8,{battle=true,colors=port.presentationColors()})
  G.setCanvas()
  equalPixels(actual,reference,'KIM HUD preserves complete Emerald glyphs')
  save(actual,w..'.work/menu-final-render-fix/kim-hud-highres.png')
  -- Exercise the production HUD label routing: larger names, native levels.
  local originalDraw,originalCode,originalAdvance=GB.draw,GB.drawCode,GB.advanceOf
  theme.enabled=function()return menu.exports.battleFontScope end
  theme.gbScale=function()return menu.exports.battleFontScale or .5 end
  GB._menuCustomizerGB={theme=theme}
  GB.advanceOf=function(code)if theme.enabled()then return theme.gbAdvance(code)or originalAdvance(code)end;return originalAdvance(code)end
  GB.drawCode=function(code,x,y)if not(theme.enabled()and theme.gbGlyph(code,x,y))then return originalCode(code,x,y)end end
  local labels=assert(read(w..'MenuCustomizer/lib/gb_menus.lua')):match('(  local function label%(text,x,y,render,%.%.%.%).-)  Font.draw=function')
  local labelEnv=setmetatable({Font=GB,mod=menu,unpack=unpack},{__index=_G})
  local labelChunk=assert(loadstring(labels..'return label'));setfenv(labelChunk,labelEnv);local label=labelChunk()
  GB.draw=function(text,x,y)return label(text,x,y,originalDraw)end
  menu.exports.battleHudScope=true;menu.exports.battleHudCapture=true
  battle.drawHUDs=function()
    GB.draw('Sandshrew',8,0);originalCode(0x6E,32,8);GB.draw('8',40,8)
    GB.draw('Nidoking',72,56);originalCode(0x6E,112,64);GB.draw('100',120,64)
  end
  local hud=capture(battle,0)
  menu.exports.battleFontScope=false
  local lev=G.newCanvas(320,296);G.setCanvas(lev);G.origin();G.clear();G.scale(2,2);G.translate(0,4)
  originalCode(0x6E,32,8);originalDraw('8',40,8)
  originalCode(0x6E,112,64);originalDraw('100',120,64);G.setCanvas();menu.exports.battleFontScope=true
  local a,b=hud:newImageData(),lev:newImageData()
  for _,box in ipairs({{32,9,16,7},{112,65,32,7}})do
    for yy=(box[2]+4)*2,(box[2]+4+box[4])*2-1 do for xx=box[1]*2,(box[1]+box[3])*2-1 do
      local ar,ag,ab,aa=a:getPixel(xx,yy);local br,bg,bb,ba=b:getPixel(xx,yy)
      assert(ar==br and ag==bg and ab==bb and aa==ba,'level glyphs differ from original font')
    end end
  end
  checks=checks+1
  save(hud,w..'.work/menu-final-render-fix/kim-hud-large-names.png')

  local out=assert(io.open(w..'.work/menu-final-render-fix/kim-gpu-result.txt','w'));out:write('PASS: '..checks..' full-canvas pixel comparisons');out:close()
 end,debug.traceback)
 if not ok then local f=assert(io.open(w..'.work/menu-final-render-fix/kim-gpu-result.txt','w'));f:write(err);f:close()end
 love.event.quit()
end
