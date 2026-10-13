local function read(path)
 local f=assert(io.open(path));local s=f:read('*a');f:close();return s
end
local A=assert(load(read('data/aspect_battle_backgrounds.lua')))()
local R=assert(load(read('data/hd_battle_backgrounds.lua')))()
local checks=0
local function ok(v,label)checks=checks+1;assert(v,label)end
local function near(a,b,label)ok(math.abs(a-b)<1e-7,label)end
local files={}
local viewports={{1320,2868,true},{1080,1920,true},{1920,1080,false},{2868,1320,false},{1024,768,false},{2560,1080,false},{768,1024,false},{5120,1440,false},{3840,1080,false},{7680,2160,false}}
for _,entry in ipairs(R.previewCatalog())do
 for _,period in ipairs(R.availablePeriods(entry.id))do
  local b=assert(R.previewBackdrop(entry.id,period));files[b.file]=true
  local anchors=R.groundAnchors(b)
  for _,v in ipairs(viewports)do
   local vw,vh,contain=v[1],v[2],v[3]
   local s=contain and math.min(vw/1920,vh/950) or math.max(vw/1920,vh/950)
   local path=A.path(b.file,vw,vh);local f=io.open(path,'rb')
   ok(f~=nil,'complete asset '..path);if f then f:close()end
   for _,lift in ipairs(contain and {0,vh*.2,vh*.35} or {0})do
    local stage={x=(vw-1920*s)/2,y=(vh-950*s)/2-(contain and lift or 172),scale=s}
    local t=A.transform(vw,vh,stage);local frame=A.frame(vw,vh)
    for _,side in ipairs({'player','enemy'})do
     local p=anchors[side]
     near(t.x+(frame.x+p.x*frame.scale)*t.sx,stage.x+p.x*s,side..' X preserved')
     near(t.y+(frame.y+p.y*frame.scale)*t.sy,stage.y+p.y*s,side..' Y preserved')
    end
    ok(t.x<=0 and t.y<=0,'top and left filled')
    ok(t.x+frame.width*t.sx>=vw and t.y+frame.height*t.sy>=vh,'bottom and right filled')
   end
   local native={x=95,y=180,sx=.7,sy=.9}
   local n=A.transform(vw,vh,native);local frame=A.frame(vw,vh)
   near(n.x+(frame.x+anchors.player.x*frame.scale)*n.sx,native.x+anchors.player.x*native.sx,'native X unchanged')
   near(n.y+(frame.y+anchors.enemy.y*frame.scale)*n.sy,native.y+anchors.enemy.y*native.sy,'native Y unchanged')
   if vw/vh>=3 then
    local k=math.max(1,math.floor(math.min(vw/160,vh/144)))
    local p,e=anchors.player,anchors.enemy
    local sx=98*k/(e.x-p.x);local sy=45*k/(p.y-e.y)
    local fit={x=(vw-160*k)/2+26*k-p.x*sx,y=(vh-144*k)/2+100*k-p.y*sy,sx=sx,sy=sy}
    local mapped=A.transform(vw,vh,fit)
    ok(mapped.x<=0 and mapped.x+frame.width*mapped.sx>=vw,'32:9 native fit fills horizontal edges')
    ok(mapped.y<=0 and mapped.y+frame.height*mapped.sy>=vh,'32:9 native fit fills vertical edges')
   end
  end
 end
end
local count=0;for _ in pairs(files)do count=count+1 end
ok(count==72,'all 72 original backgrounds covered')
ok(A.path('../bad',1920,1080)==nil,'invalid file rejected')
ok(A.path('grass_night',1920,1080):find('/widescreen/',1,true),'16:9 selects wide')
ok(A.path('grass_night',1080,1920):find('/portrait/',1,true),'portrait selects portrait')
ok(A.path('grass_day',5120,1440):find('/ultrawide/',1,true),'32:9 selects dedicated panorama')
ok(A.path('grass_day',2560,1080):find('/widescreen/',1,true),'21:9 retains wide artwork')
local main=read('main.lua')
ok(not main:find('portraitArenaImage',1,true),'old backdrop loader removed')
ok(not main:find('getPortraitBlendShader',1,true),'runtime layer blend removed')
print('PASS: '..checks..' complete-aspect background and original anchor checks')
