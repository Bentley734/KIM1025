-- Run with engine source as arg[1]. Uses the real FRLG/RSE option menus.
local engine=assert(arg[1]);local checks=0
local function read(p)local f=assert(io.open(p));local s=f:read('*a');f:close();return s end
local function eq(a,b,label)checks=checks+1;assert(a==b,label..': '..tostring(a)..' ~= '..tostring(b))end
for _,region in ipairs({'firered','leafgreen','ruby','sapphire','emerald'})do
 local hooks,events,values={}, {}, {}
 local game={save={options={}},mods={modOptions={}},writeOptions=function()end}
 local session={version=region,game=game}
 local Stack=assert(loadfile(engine..'/src/ui/game3/stack.lua'))()
 local confirmations=0
 local Start={_kind='normal',_session=session,_game=game,confirm=function()confirmations=confirmations+1 end}
 local modules={['src.ui.game3.stack']=Stack,['src.ui.game3.start_menu']=Start,
  ['src.ui.game3.option_rows']={build=function()return {{id='mods',label='MODS'}}end,group=function(r)return r end,withCart=function(_,r)return r end},
  ['src.core.game3.options']={engine=function()return {}end,bind=function()end},
  ['src.core.game3.rom_text']={plain=function(s)return s end},
  ['src.ui.game3.rse.scene_kit']={},['src.ui.game3.window']={},['src.ui.game3.shaderfx_menu']={},
  ['src.ui.game3.chrome']={},['src.ui.game3.frlg_font']={},
  ['src.core.game3.runtime']={_game=game,getSession=function()return session end}}
 local Screens={redirect=function()end,openFlag=function()return function()return true end end}
 modules['src.ui.game3.screens']=Screens
 local function pic(s)return {image={dex=true,species=s}}end
 local P={national=function(s)return s>450 and s-64 or s end,frontPic=pic,backPic=pic}
 modules['src.core.game3.pokemon']=P
 modules['src.core.game3.battle.init']={isActive=function()return true end,getState=function()return {}end}
 local G=setmetatable({getDimensions=function()return 1920,1080 end,newCanvas=function()return {setFilter=function()end}end,
  newQuad=function()return {}end},{__index=function()return function()end end})
 local env=setmetatable({love={graphics=G,system={getOS=function()return 'Windows'end}},package={loaded=modules}},{__index=_G})
 env.require=function(n)if modules[n]then return modules[n]end;error(n)end
 env.load=function(s,n,m)return load(s,n,m or 't',env)end;env.loadstring=env.load
 local Frlg=assert(load(read(engine..'/src/ui/game3/option_menu.lua'),'native FRLG','t',env))()
 local Rse=assert(load(read(engine..'/src/ui/game3/rse/option_menu.lua'),'native RSE','t',env))()
 modules['src.ui.game3.option_menu']=Frlg;modules['src.ui.game3.rse.option_menu']=Rse
 Screens.get=function()return (region=='firered' or region=='leafgreen') and Frlg or Rse end
 local sprite={getDimensions=function()return 1,1 end,setFilter=function()end}
 local mod={path='.',generation=3,exports={},find=function(_,id)if id=='1025dex'then return {exports={}}end end,
  options={define=function(_,schema)for _,r in ipairs(schema)do values[r.key]=r.default end end,get=function(_,k)return values[k]end},
  hooks={wrap=function(_,name,fn)hooks[name]=hooks[name]or{};table.insert(hooks[name],fn)end},
  events={on=function(_,name,fn)events[name]=events[name]or{};table.insert(events[name],fn)end},
  _kimAssetProvider={image=function(path)if path=='kim.png'then return sprite end end},
  log={info=function()end,warn=function()end,error=function()end}}
 function mod:read(path)
  if path=='data/hd_pokemon_national.lua'then
   local r='{image="kim.png",width=1,height=1,frames=1,columns=1}'
   return 'return {[25]={front={normal={default='..r..'}},back={normal={default='..r..'}}}}'
  end
  if path=='lib/preview_bounds.lua' or path=='lib/gen3_settings.lua' or path=='data/hd_battle_backgrounds.lua' or path=='data/aspect_battle_backgrounds.lua' or path=='data/hoenn_battle_backgrounds.lua'then return read(path)end
 end
 local calls=0;P.__completeDexEnsurePics=function()calls=calls+1;P.frontPic=pic;P.backPic=pic end
 assert(load(read('lib/feature_scope.lua')))()(mod)
 assert(load(read('lib/gen3_frlg.lua'),'complete bridge','t',env))()(mod)
 for _,fn in ipairs(events['game.ready']or{})do fn({game=game})end
 eq(P.frontPic(25,0,false).image.dex,true,'native front provider retained')
 eq(P.backPic(25,0,false).image.dex,true,'native back provider retained')
 eq(P.frontPic(451,0,false).image.dex,true,'expanded provider retained')
 P.__completeDexEnsurePics();eq(calls,1,'native ensure unchanged')
 local menu=(region=='firered' or region=='leafgreen') and Frlg or Rse
 menu.show({game=game,session=session})
 local pages=menu==Rse and menu._st.pages or menu._pages
 local root=pages[1];local openRow
 for _,row in ipairs(root.rows)do if row.id=='kanto_in_motion'then openRow=row end end
 eq(openRow~=nil,true,'native options shortcut available')
 openRow.activate({game=game,session=session})
 local page=pages[#pages]
 eq(page.title,'KIM1025','native settings title')
 eq(#page.rows,2,'only Dex and HD controls on Gen3')
 eq(page.rows[1]._kimSpec.key,'animatedPokedex','Dex control')
 eq(page.rows[2]._kimSpec.key,'hdBattleBackgrounds','background control')
 page.rows[1].step(nil,1)
 eq(game.save.options.modOptions.kim1025.animatedPokedex,false,'saved fork namespace')
 eq(game.mods.modOptions.kim1025.animatedPokedex,false,'loader updated')
 eq(game.save.options.modOptions.animated_menu_pokemon,nil,'upstream namespace absent')

end
-- Actual background functions with an empty canonical cache.
local source=read('lib/gen3_frlg.lua')
local a=assert(source:find('  local function frlgBackdropImage',1,true));local b=assert(source:find('  -- Game3 renders the FRLG battle into',a,true))
local image={getWidth=function()return 1920 end,getHeight=function()return 1080 end}
local frames={};local env=setmetatable({frlgBackdrop=function()return {file='grass_day'}end,hdBgImageCache={},
 aspectArena=assert(loadfile('data/aspect_battle_backgrounds.lua'))(),packagedBackgroundFrames=frames,
 atlas=function(path)if path:find('/aspect/',1,true)then return image end end,
 hdArenaRouter=assert(loadfile('data/hd_battle_backgrounds.lua'))()},{__index=_G})
local get,geometry,transform=assert(load(source:sub(a,b-1)..'\nreturn frlgBackdropImage,frlgHdGeometry,frlgGlobalBackgroundTransform','background','t',env))()
local bg,backdrop=get({},{});eq(bg,image,'packaged fallback without cache')
local geo=geometry(backdrop);local t=transform(image,geo);local f=frames[image]
eq(math.abs((f.x+geo.player.x*f.scale)*t.sx+t.tx-72)<1e-6,true,'player mound')
eq(math.abs((f.x+geo.enemy.x*f.scale)*t.sx+t.tx-176)<1e-6,true,'enemy mound')
eq(t.tx<=0 and t.ty<=0 and t.tx+1920*t.sx>=240 and t.ty+1080*t.sy>=160,true,'viewport covered')
print('PASS: '..checks..' Gen3 integration checks')
