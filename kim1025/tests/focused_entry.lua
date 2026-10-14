local function read(p)local f=io.open(p);if not f then return nil end;local s=f:read('*a');f:close();return s end
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
for generation=1,3 do for _,host in ipairs({'Windows','OS X','Android','iOS'})do
 local hooks,events,screens,logs={},{},{},{}
 local values={battleSprites=true,menuIcons=true,integratedModernUi=true,gen2IntegratedModernUi=true,
  gen3IntegratedModernUi=true,titleScreen=true,battleShinyOdds='1',battleTrainerSprite='ash',battlePlayerSize='125',battleEnemySize='150'}
 local schema={};local function unchanged()return 'native'end
 local pic={getDimensions=function()return 56,56 end,getWidth=function()return 56 end,getHeight=function()return 56 end,setFilter=function()end}
 local B={newWild=unchanged,drawPicsLayer=unchanged,picImage=function(_,p)return p end,draw=unchanged,drawHUDs=unchanged,resolveBattleScale=function()return 1 end}
 local Pokemon={frontPic=unchanged,backPic=unchanged,__completeDexEnsurePics=unchanged}
 local classes={};for _,key in ipairs({'SummaryMenu','EvolutionState','TitleScreen','StarterChoose','PartyMenu'})do classes[key]={draw=unchanged,new=unchanged,drawPic=unchanged}end
 local calls={}
 local nativeStart=function(self,id,side,opts) calls.start={self,id,side,opts};return 'native',id,side,opts end
 local nativeDraw=function(self,colorized) calls.draw={self,colorized};return 'native-draw',colorized end
 B.drawAnimLayer=nativeDraw
 local A={start=nativeStart,update=unchanged,isDone=unchanged,pollEffects=unchanged,draw=unchanged}
 local modules={['src.render.Font']={},['src.battle.TypeChart']={},['src.battle.BattleState']=B,['src.battle.AnimPlayer']=A,['src.core.Sound']={},
  ['src.core.GameVersion']={generation=function()return generation end,get=function()return generation==3 and 'firered' or 'red'end},
  ['src.core.Game']={save={options={}},stack={states={}}},['src.core.game3.pokemon']=Pokemon,
  ['src.core.game3.battle.init']={isActive=function()return false end},
  ['src.ui.DexEntryMenu']={new=function(_,s)return {def={id=s}}end,render=unchanged},
  ['src.ui.gen2.PokedexMenu']={drawPic=unchanged,drawUnownPic=unchanged}}
 for key,class in pairs(classes)do modules['src.ui.'..key]=class;modules['src.ui.gen2.'..key]=class end
 local G=setmetatable({getStackDepth=function()return 0 end,getCanvas=function()end,getDimensions=function()return 390,844 end,
  getPixelDimensions=function()return 1170,2532 end,newCanvas=function()return pic end,newImage=function()return pic end},{__index=function()return function()end end})
 local env=setmetatable({love={graphics=G,system={getOS=function()return host end},timer={getTime=function()return 0 end}},
  package={loaded=modules},require=function(n)if modules[n]then return modules[n]end;error('unavailable '..n)end},{__index=_G})
 env.load=function(s,n,m)return load(s,n,m or 't',env)end;env.loadstring=env.load
 local mod={path='.',generation=generation,exports={},find=function()end,info=function(_,p)if read(p)then return {}end end,
  assets={image=function()end,path=function(_,p)return p end},
  options={define=function(_,s)schema=s end,get=function(_,k)if values[k]~=nil then return values[k]end;for _,r in ipairs(schema)do if r.key==k then return r.default end end end},
  events={on=function(_,n,f)events[n]=events[n]or{};table.insert(events[n],f)end},
  hooks={wrap=function(_,n,f)hooks[n]=hooks[n]or{};table.insert(hooks[n],f)end},
  content={screens={register=function(_,id,s)screens[id]=s end},sfx={register=function()error('move SFX must not be registered')end},battle_sprite_scales={register=function()end}},
  log={info=function()end,warn=function()end,error=function(_,fmt,...)logs[#logs+1]=string.format(fmt,...)end},read=function(_,p)return read(p)end}
 local ok,err=pcall(assert(env.load(assert(read('main.lua')),'complete focused entry'))(),mod)
 check(ok,'entry boots '..generation..' '..host..': '..tostring(err))
 for _,fn in ipairs(events['game.ready']or{})do fn({game=modules['src.core.Game']})end
 check(#schema==(generation==1 and 6 or generation==2 and 1 or 2),'only requested options')
 check(mod.options:get('battleSprites')==false and mod.options:get('menuIcons')==false,'old sprite/icon flags disabled')
 check(mod.options:get('battleShinyOdds')=='native','old shiny odds disabled')
 check(mod.options:get('battlePlayerSize')=='125' and mod.options:get('battleEnemySize')=='150','saved alignment retained')
 check(mod.options:get('battleTrainerSprite')=='ash','trainer retained')
 for _,class in pairs(classes)do check(class.draw==unchanged and class.new==unchanged and class.drawPic==unchanged,'removed menus native')end
 check(Pokemon.frontPic==unchanged and Pokemon.backPic==unchanged and Pokemon.__completeDexEnsurePics==unchanged,'Gen3 provider unchanged')
 check(B.newWild==unchanged,'encounters unchanged')
 check(mod.exports._kantoInMotionStagedBattleSprite==nil and mod.exports._kantoInMotionPotatoPinnedBackNative==nil,'3D sprite providers removed')
 if generation~=3 then check(mod.exports.registerBattleCompatibility({owner='potato_voxel',active=function()return true end})==false,'legacy 3D registration refused') end
 check(mod._kantoInMotionBattleArtCompat==nil and mod._kantoInMotionPotatoVoxelCompat==nil and mod._kantoInMotionBattleArtGen2Compat==nil,'3D installers absent')
 if generation==1 then check(mod.exports.integratedKrba==nil and mod.exports._kantoInMotionKRBAActiveSession==nil,'native move animations retained')end
 check(A.start==nativeStart and B.drawAnimLayer==nativeDraw,'animation player and effect draw methods untouched')
 check(A.update==unchanged and A.draw==unchanged and A.pollEffects==unchanged and A.isDone==unchanged,'native animation lifecycle preserved')
 for _,id in ipairs(assert(loadfile('tests/fixtures/native_moves.lua'))())do
  for _,side in ipairs({true,false})do
   local ap=setmetatable({},{__index=A});local opts={test=id};local tag,move,who,o=ap:start(id,side,opts)
   check(tag=='native' and move==id and who==side and o==opts,'native start result: '..id)
   check(calls.start[1]==ap and calls.start[2]==id and calls.start[3]==side and calls.start[4]==opts,'native start args: '..id)
   local b=setmetatable({kind='wild',animPlayer=ap},{__index=B})
   if mod._kantoInMotionPokeballTargetFix then check(mod._kantoInMotionPokeballTargetFix:prepare(b,0,0,1,1)==false and b._kantoInMotionBallAnimShift==nil,'catch correction ignores moves: '..id)end
   for _,colorized in ipairs({true,false})do
    local result,color=b:drawAnimLayer(colorized)
    check(result=='native-draw' and color==colorized and calls.draw[1]==b and calls.draw[2]==colorized,'native effect draw: '..id)
   end
  end
 end
 for _,line in ipairs(logs)do check((line:find('asset manager',1,true)~=nil or line:find('asset-manager',1,true)~=nil),'unexpected installer failure: '..line)end
end end
print('PASS: '..checks..' complete entry / upgrade / native ownership checks')
