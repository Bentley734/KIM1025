-- Windows LOVE regression using production trainer placement, real trainer
-- pixels, and Menu Customizer's original selected border renderer.
local workspace=assert(os.getenv('BATTLE_UI_WORKSPACE'))..'/'
local kim=(os.getenv('KIM_SOURCE_ROOT') or workspace..'.work/latest-sprite-fix/current-source/kim1025')..'/'
local menu=workspace..'MenuCustomizer/'
local cache=assert(os.getenv('POKEMON_CACHE_ROOT'))..'/'
local output=(os.getenv('TRAINER_TEST_OUTPUT') or workspace..'.work/trainer-size-fix')..'/'
local function read(path)
 local f=io.open(path,'rb');if not f then return end
 local data=f:read('*a');f:close();return data
end
local function loadImage(path)
 local image=love.graphics.newImage(love.filesystem.newFileData(assert(read(path),path),path))
 image:setFilter('nearest','nearest');return image
end
local function save(canvas,path)
 local data=canvas:newImageData()
 local encoded=data:encode('png')
 local f=assert(io.open(path,'wb'));f:write(encoded:getString());f:close()
 data:release();encoded:release()
end
function love.load()
 local ok,err=xpcall(function()
  local G=love.graphics
  local checks=0
  local function check(condition,message)checks=checks+1;assert(condition,message)end
  local function near(a,b,message)check(math.abs(a-b)<.00001,message..': '..tostring(a)..' ~= '..tostring(b))end
  local auto=assert(loadstring(assert(read(kim..'lib/auto_player_size.lua'))))()
  local source=assert(read(kim..'main.lua'))
  local first=assert(source:find('  local function drawDirectBattleTrainer(',1,true))
  local last=assert(source:find('  drawDirectBattleSprites = function',first+1,true))
  local selected,orientation,trainerPercent=100,nil,100
  local drawCall
  local graphicProxy=setmetatable({draw=function(...)drawCall={...};return G.draw(...)end},{__index=G})
  local mod={_kimAutoPlayerSize=auto,options={get=function()return trainerPercent end},exports={}}
  local env=setmetatable({mod=mod,love={graphics=graphicProxy},
   battleLiteFullScreenActive=function()return true end,
   touchBattleOrientation=function()return orientation end,
   nativeBattlePlacementPx=function()return {sx=7,sy=7}end,
  },{__index=_G})
  local compile=assert(loadstring(source:sub(first,last-1)..'\nreturn drawDirectBattleTrainer','@production-trainer'))
  setfenv(compile,env);local draw=compile()
  local battle={game={},showPlayerBack=true,phase='messages',picOffset=function()return 0 end}
  local borderMod={generation=1,assets={image=function(_,path)return loadImage(menu..path)end}}
  local catalog=assert(loadstring(assert(read(menu..'lib/border_catalog.lua'))))()
  local borders=assert(loadstring(assert(read(menu..'lib/menu_borders.lua'))))()(borderMod,
   function(k)return k=='menuBorder' and 6 or 2 end,catalog,function()return true end)
  mod.find=function()return {exports={battleUi={canDrawBottom=function()return true end}}}end
  local frames={}
  for _,identity in ipairs({'red','ash'})do
   local file=identity..'player.png'
   frames[#frames+1]={image=loadImage(kim..'assets/battle/player-trainers-frames/'..file),label=identity..'-static',save=identity}
   local raw=love.image.newImageData(love.filesystem.newFileData(assert(read(kim..'assets/battle/player-trainers-animated/'..file)),file))
   check(raw:getWidth()==400 and raw:getHeight()==80,'real '..identity..' animation sheet dimensions')
   for index=0,4 do
    local cell=love.image.newImageData(80,80);cell:paste(raw,0,0,index*80,0,80,80)
    local image=G.newImage(cell);image:setFilter('nearest','nearest');cell:release()
    frames[#frames+1]={image=image,label=identity..'-frame-'..index}
   end
   raw:release()
  end
  local arenaBytes=read(cache..'mod_cache/kim1025/kim_assets/files/assets/battle/backgrounds/hd/grass_day.png')
  local arena=arenaBytes and G.newImage(love.filesystem.newFileData(arenaBytes,'grass.png'))
  local report={}
  local sizes={{1024,729},{1047,699},{1920,1080},{5120,1440}}
  local function inkRow(data,left,right,row)
   if row<0 or row>=data:getHeight() then return false end
   for x=math.max(0,left),math.min(data:getWidth()-1,right) do
    if select(4,data:getPixel(x,row))>.99 then return true end
   end
   return false
  end
  for _,size in ipairs(sizes)do
   local width,height=size[1],size[2]
   local uiScale=math.min(width/160,height/144)
   local rect={x=math.floor((width-160*uiScale)*.5+.5),
    y=math.floor(height-48*uiScale+.5),w=160*uiScale,h=48*uiScale}
   local arenaScale=math.max(width/1920,height/950)
   local geo={hd=true,hdScale=arenaScale,playerX=(width-1920*arenaScale)*.5+604*arenaScale,playerY=672*arenaScale}
   local borderCanvas=G.newCanvas(width,height,{dpiscale=1})
   G.setCanvas(borderCanvas);G.origin();G.clear(0,0,0,0)
   G.push('all');G.translate(rect.x,rect.y);G.scale(uiScale,uiScale)
   check(borders.drawBattlePixels(0,0,160,48),'real selected battle border rendered')
   G.pop();G.setCanvas()
   local borderData=borderCanvas:newImageData()
   local borderFirst
   local center=math.floor(rect.x+rect.w*.5)
   for row=rect.y,rect.y+math.ceil(4*uiScale)do
    if select(4,borderData:getPixel(center,row))>.99 then borderFirst=row;break end
   end
   check(borderFirst~=nil,'real selected blue FR/LG 05 border has a painted top row')
   borderData:release()
   for _,percent in ipairs({100,200})do
    trainerPercent=percent
    for index,entry in ipairs(frames)do
     local frame=entry.image
     selected=frame;mod._kantoInMotionFlatTrainerFrame=function()return selected end
     mod.exports._kantoInMotionBattleTrainerFrame=mod._kantoInMotionFlatTrainerFrame
     local bounds=assert(auto.measure(frame,80,80))
     check(bounds.ground<=80 and bounds.y0>0,entry.label..' visible shape measured independently of its 80px canvas')
     local trainerCanvas=G.newCanvas(width,height,{dpiscale=1})
     G.setCanvas(trainerCanvas);G.origin();G.clear(0,0,0,0);drawCall=nil
     check(draw(battle,geo,battle.game,width,height),'production trainer is rendered')
     G.setCanvas()
     local scale=drawCall[5]
     local anchor=math.ceil(rect.y+uiScale)+1
     local cap=(anchor-2)/(bounds.ground-bounds.y0)
     local wanted=8*math.min(width/1920,height/1080)*percent/100
     near(scale,math.min(wanted,cap),'trainer uses height-aware scale and opaque top cap')
     near(drawCall[6],scale,'trainer keeps square pixels')
     near(drawCall[3]+bounds.ground*scale,anchor,'visible trainer bottom matches painted frame row')
     check(drawCall[3]+bounds.y0*scale>=2-.00001,'visible trainer never extends above the screen')
     near(drawCall[2]+80*scale*.5,geo.playerX,'existing horizontal mound anchor preserved')
     local data=trainerCanvas:newImageData()
     local left=math.floor(drawCall[2]+bounds.x0*scale)
     local right=math.ceil(drawCall[2]+bounds.x1*scale)
     -- The atlas has a transparent first border row. The trainer must remain
     -- visible immediately above the first painted border pixel, with no gap.
     local lastInk
     for row=math.min(height-1,math.ceil(anchor+2)),math.max(0,math.floor(anchor-32)),-1 do
      if inkRow(data,left,right,row) then lastInk=row;break end
     end
     if not inkRow(data,left,right,borderFirst-1) then save(trainerCanvas,output..'failed-trainer.png');save(borderCanvas,output..'failed-border.png')end
     check(inkRow(data,left,right,borderFirst-1),
      'empty line between '..entry.label..' and dialog at '..width..'x'..height..' '..percent..'%: lastInk='..tostring(lastInk)..', firstBorder='..borderFirst..', anchor='..anchor..', drawY='..drawCall[3]..', ground='..bounds.ground..', scale='..scale)
     data:release()
     if entry.save then
      report[#report+1]=entry.label..' '..width..'x'..height..' '..percent..'%: scale='..string.format('%.4f',scale)..', opaqueHeight='..string.format('%.2f',(bounds.ground-bounds.y0)*scale)..', borderTop='..borderFirst
      local scene=G.newCanvas(width,height,{dpiscale=1})
      G.setCanvas(scene);G.origin();G.clear(.13,.32,.12,1)
      if arena then
       G.setColor(1,1,1,1);G.draw(arena,(width-1920*arenaScale)*.5,(height-950*arenaScale)*.5-172,0,arenaScale,arenaScale)
      end
      G.setColor(1,1,1,1);G.draw(trainerCanvas);G.draw(borderCanvas);G.setCanvas()
      save(scene,output..'trainer-'..entry.save..'-'..width..'x'..height..'-'..percent..'.png')
      scene:release()
     end
     trainerCanvas:release()
    end
   end
   borderCanvas:release()
  end
  -- Mobile continues to use its approved arena scale and raw sprite baseline.
  for _,mode in ipairs({'portrait','landscape'})do
   orientation=mode;trainerPercent=200;selected=frames[1].image
   local geo={hd=true,hdScale=.4,playerX=240,playerY=380}
   local canvas=G.newCanvas(707,950,{dpiscale=1});G.setCanvas(canvas);G.origin();G.clear()
   check(draw(battle,geo,battle.game,707,950),'mobile trainer drawn')
   G.setCanvas();canvas:release()
   local scale=(mode=='portrait' and 10 or 8)*geo.hdScale
   near(drawCall[5],scale,'mobile trainer rung unchanged')
   near(drawCall[3]+80*scale,geo.playerY+(mode=='portrait' and 220 or 56)*geo.hdScale,'mobile baseline unchanged')
  end
  local f=assert(io.open(output..'gpu-result.txt','w'))
  f:write('PASS: '..checks..' production trainer GPU assertions\n'..table.concat(report,'\n'));f:close()
 end,debug.traceback)
 if not ok then local f=assert(io.open(output..'gpu-result.txt','w'));f:write(err);f:close()end
 love.event.quit(ok and 0 or 1)
end
