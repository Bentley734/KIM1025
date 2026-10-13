local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function read(p)local f=assert(io.open(p));local s=f:read('*a');f:close();return s end
local engine=arg[2]or '../../../../.tools/engine-0358'
local source=read(engine..'/src/ui/game3/rs/option_menu.lua')
for _,version in ipairs({'ruby','sapphire'})do
 local game={save={options={}},options={},mods={modOptions={}}}
 local loaded={}
 loaded['src.ui.game3.stack']={push=function()end,pop=function()end}
 loaded['src.core.game3.options']={engine=function()return game.options end,bind=function()return {}end}
 loaded['src.core.game3.profile']={active=function()return {id=version}end}
 loaded['src.ui.game3.frlg_font']={}
 loaded['src.ui.game3.chrome']={}
 loaded['src.core.game3.pal_fade']={new=function()return {beginFade=function()end}end}
 loaded['src.ui.game3.rse.scene_kit']={manifest=function()return {layout='rs',option={}}end}
 loaded['src.ui.game3.option_rows']={withCart=function()return {{id='mods',label='MODS'}}end}
 loaded['src.ui.game3.shaderfx_menu']={}
 local env=setmetatable({package={loaded=loaded},require=function(n)return assert(loaded[n],n)end},{__index=_G})
 local menu=assert(load(source,'actual RS options','t',env))()
 loaded['src.ui.game3.rs.option_menu']=menu
 loaded['src.ui.game3.option_menu']={};loaded['src.ui.game3.rse.option_menu']={}
 loaded['src.ui.game3.screens']={get=function()return menu end}
 local value=true
 local mod={options={get=function()return value end,set=function(_,_,v)value=v end},
  _kantoInMotionOptionSchema={{key='hdBattleBackgrounds',label='HD BACKGROUNDS',type='toggle',default=true}}}
 assert(load(read('lib/gen3_settings.lua'),'settings','t',env))()(mod)
 check(mod._kimOpenGen3Settings(game,{version=version}),version..' direct settings opens')
 local pages=menu._pages
 check(#pages==2 and pages[2].title=='KIM1025','RS uses actual native pages')
 check(pages[1].rows[1].id=='kanto_in_motion','RS top page receives KIM row')
 pages[2].rows[1].step(nil,1)
 check(game.save.options.modOptions.kim1025.hdBattleBackgrounds==false,'RS settings persist game context')
 check(game.mods.modOptions.kim1025.hdBattleBackgrounds==false,'RS loader context persists')
end
print('PASS '..checks..' actual Ruby/Sapphire Options and KIM context checks')
