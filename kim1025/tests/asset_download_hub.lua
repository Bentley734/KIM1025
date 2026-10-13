local count=0
local function eq(a,b,m)count=count+1;assert(a==b,m..': '..tostring(a)..' ~= '..tostring(b))end
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('lib/asset_download_hub.lua')
for _,gen in ipairs({1,2,3})do
 for _,scenario in ipairs({'fresh','existing','ready','deferred','old-deferred','legacy'})do
  local events,hooks,registry,drawn,packs={},{},{},{},{}
  local polygons, depth = {}, 0
  local Stack=assert(loadfile('tests/fixtures/gen3_stack.lua'))()
  local Rows={build=function()return {{id='native',label='NATIVE'}}end}
  local modules={['src.ui.game3.stack']=Stack,['src.ui.game3.option_rows']=Rows,
   ['src.ui.game3.window']={template=function()return {}end,stdFrame=function()end,printPx=function(t)drawn[#drawn+1]=t end}}
  local mod={generation=gen,events={on=function(_,n,f)events[n]=f end},hooks={wrap=function(_,n,f)hooks[n]=f end},
   content={screens={register=function(_,id,d)registry[id]=d end}},ui={Font={drawBox=function()end,draw=function(t)drawn[#drawn+1]=t end},
   push=function(game,id)game.view=registry[id].new(game);if events['screen.pushed']then events['screen.pushed']()end end}}
  local env=setmetatable({require=function(n)return assert(modules[n],n)end,love={graphics={push=function()depth=depth+1 end,pop=function()depth=depth-1 end,polygon=function(...)polygons[#polygons+1]={...}end,setShader=function()end,
   setScissor=function()end,setColor=function()end,rectangle=function()end}}},{__index=_G})
  local function factory(_,cfg)
   eq(cfg.embedded,true,'only one hub integration per pack')
   local n=#packs+1; local p={state='idle',revision=0,started=0,config=cfg,files={}}
   p.complete=scenario=='ready' or n==1 and (scenario=='existing' or scenario=='deferred')
   p.deferred=scenario=='deferred' or scenario=='old-deferred' and n==1
   function p:isComplete()return self.complete end
   function p:isDeferred()return self.deferred end
   function p:sourceRevision()return self.revision end
   function p:start()self.started=self.started+1;self.state='checking';self.deferred=false end
   function p:update()end
   function p:cancel()self.state='idle';self.deferred=true end
   function p:defer()self.deferred=true end
   function p:beginDelete()self.state='deleting';self.complete=false end
   function p:read(path)return self.files[path]end
   function p:exists(path)return self.files[path]~=nil end
   function p:image(path)return self.files[path]end
   packs[n]=p;return p
  end
  local hub=assert(load(source,'production download hub','t',env))()(mod,factory)
  local original,extra=packs[1],packs[2]
  eq(extra.config.cacheNamespace,'kim1025_assets','separate persistent cache')
  eq(extra.config.version,'1.0.0','assets version independent of code')
  eq(extra.config.indexOnly,true,'art removal never targets original Pokemon')
  eq(hub.autoPromptArmed,scenario~='ready' and scenario~='deferred','prompt only missing nondeferred packs')
  local game={input={wasPressed=function()return false end},stack={pop=function()gameClosed=true end}}
  events['game.ready']({game=game})
  if gen~=3 then events['screen.pushed']() end
  if scenario~='ready' and scenario~='deferred' then
   eq(gen==3 and Stack.depth()>0 or gen~=3 and game.view~=nil,true,'automatic prompt on boot')
   eq(hub.selection,scenario=='existing' and 3 or 1,'existing assets select KIM1025 download')
  end
  eq(hooks['ui.options.rows'],nil,'download hub adds no root options hook')
  local rows=Rows.build({game=game})
  eq(#rows,1,'native options has no standalone assets row')
  eq(rows[1].id,'native','native root row retained')
  hub.open(game)
  hub:draw();eq(drawn[1],'KIM ASSETS','visible hub heading')
  for row=1,4 do
   hub.selection=row;polygons={};hub:draw()
   eq(#polygons,1,'one visible selector per download row')
   local arrow=polygons[1]
   eq(arrow[1],'fill','selector is drawn chrome, independent of glyphs')
   eq(arrow[2],gen==3 and 16 or 8,'arrow occupies reserved label gutter')
   eq(arrow[3],(gen==3 and 48 or 44)+(row-1)*20+1,'arrow follows selected row')
   eq(depth,0,'selector restores graphics state')
   eq(table.concat(hub:lines(),'|'):find('>',1,true),nil,'no unsupported ASCII arrow glyph')
  end
  hub.selection=4
  hub:handleInput({wasPressed=function(_,k)return k=='down'end})
  eq(hub.selection,1,'down wraps selector to first row')
  hub:handleInput({wasPressed=function(_,k)return k=='up'end})
  eq(hub.selection,4,'up wraps selector to last row')
  hub.state='checking';polygons={};hub:draw();eq(#polygons,0,'no menu selector on progress/status screen')
  hub.state='menu'

  local all=table.concat(hub:lines(),'|');eq(all:find('DOWNLOAD KIM1025',1,true)~=nil,true,'explicit KIM1025 download option')
  local path='assets/battle/backgrounds/aspect/portrait/test.jpg'
  original.files[path]='wrong';extra.files[path]='art'
  eq(hub:read(path),'art','portrait art routes to extra pack')
  eq(hub:image(path),'art','Gen3 wide art routes to extra pack')
  original.files['assets/battle/hd-pokemon/front/a.png']='pokemon'
  eq(hub:read('assets/battle/hd-pokemon/front/a.png'),'pokemon','original sprites unchanged')
  hub:start('all')
  if scenario=='ready' then eq(hub.state,'done','ready packs do not redownload')
  else
   local first=original.complete and extra or original
   eq(hub.active,first,'first missing pack selected')
   if first==original then
    original.state='done';hub:update();eq(original.started,2,'legacy base continues supplements')
    original.complete=true;original.state='done';original.revision=1;hub:update()
   end
   eq(hub.active,extra,'original download chains extra pack')
   extra.state='error';extra.error='network failed';hub:update()
   eq(hub:lines()[1],'KIM1025 ERROR','error identifies failing pack')
   hub:handleInput({wasPressed=function(_,k)return k=='a'end});eq(extra.state,'checking','retry only failing pack')
   local prior=original.started
   hub:handleInput({wasPressed=function(_,k)return k=='b'end})
   eq(extra.deferred,true,'cancellation defers missing art')
   eq(original.started,prior,'cancel does not restart original')
   hub.open(game);hub:start('extra');extra.complete=true;extra.state='done';extra.revision=2;hub:update()
   eq(hub.state,'done','standalone KIM1025 install completes')
   eq(hub:sourceRevision(),original.revision+2,'cache miss revision sees both packs')
  end
  hub.open(game);hub.selection=4
  hub:handleInput({wasPressed=function(_,k)return k=='a'end});eq(hub.state,'remove_menu','retains maintenance menu')
  hub.selection=2;hub:handleInput({wasPressed=function(_,k)return k=='a'end})
  eq(hub.state,'confirm_delete','removal requires confirmation')
  polygons={};hub:draw();eq(#polygons,0,'confirmation hides menu selector')
  hub:handleInput({wasPressed=function(_,k)return k=='b'end});eq(hub.active,nil,'cancel removal keeps assets')
 end
end
print('PASS: '..count..' download hub checks across Gen1/2/3, upgrade, cache, queue, retry and cancel')
