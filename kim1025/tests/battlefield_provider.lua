local root=arg[1]or'.';local function read(p)local f=assert(io.open(root..'/'..p));local s=f:read('*a');f:close();return s end
local source=read('main.lua');local a=assert(source:find('    local customField=false',1,true));local b=assert(source:find('    -- Paint the intro trainer',a,true));local code=source:sub(a,b-1)
for _,mode in ipairs({'native','custom','error','absent'})do
 local native=0;local seen=0
 local provider={draw=function(x,y,w,h)seen=seen+1;assert(w==640 and h==480);if mode=='error'then error('probe')end;return mode=='custom'end}
 local env=setmetatable({mod={find=function()if mode~='absent'then return{exports={battlefieldBackground=provider}}end end},vw=640,vh=480,
 complete={},image={},backdrop={},wideTransform={x=0,y=0,scale=1},A={transform=function()return{x=0,y=0,sx=1,sy=1}end},g={draw=function()native=native+1 end}},{__index=_G})
 local f=assert(load(code,'production background seam','t',env));f()
 assert(native==(mode=='custom'and 0 or 1));assert(seen==(mode=='absent'and 0 or 1))
end
local s=read('lib/gen3_frlg.lua');local a=assert(s:find('    local menuOk,menu=pcall',1,true));local b=assert(s:find('    local t = frlgGlobalBackgroundTransform',a,true));local branch=s:sub(a,b-1)
local calls=0;local env=setmetatable({mod={find=function()return{exports={battlefieldBackground={draw=function(x,y,w,h)calls=calls+1;assert(x==4 and y==8 and w==640 and h==480);return true end}}}end},coverage={x=4,y=8,w=640,h=480}},{__index=_G})
assert(assert(load(branch,'Gen3 field provider','t',env))()==true and calls==1)
print('PASS scenery-only KIM provider, native/absent/error fallback and Gen3 viewport coverage')
