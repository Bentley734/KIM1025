local checks=0
local function eq(a,b,m)checks=checks+1;assert(a==b,m..': '..tostring(a)..' ~= '..tostring(b))end
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local source=read('lib/asset_download_manager.lua')
local Json=assert(loadfile('../work/engine/gen1recomp-0.3.71/src/link/Json.lua'))()
local digest='39377ee203ea18f67fece295d55a1207c828a9e9054af8fdeccde30309eb4174'
local path='assets/battle/backgrounds/aspect/portrait/fixture.jpg'
for _,case in ipairs({'valid','checksum','wrong-id','wrong-version','missing-files','traversal','wrong-prefix','write-failure','wrong-release','direct'})do
 local archive=read('tests/fixtures/asset_packs/'..((case=='write-failure' or case=='wrong-release' or case=='direct') and 'valid' or case)..'.zip')
 local cache,files={},{}
 cache['kim_assets/complete.txt']='zip:1.2.0';cache['kim_assets/files/original']='preserve'
 local fs={getInfo=function(p)return files[p] and {type='file',size=#files[p]}end,remove=function(p)files[p]=nil end}
 fs.newFile=function(p)
  local cursor=0
  return {open=function()return true end,getSize=function()return #files[p]end,seek=function(_,n)cursor=n;return true end,
   read=function(_,n)local data=files[p]:sub(cursor+1,cursor+n);cursor=cursor+n;return data end,close=function()end}
 end
 local modules={['src.link.Json']=Json,['src.core.SaveData']={persistenceFs=function()return fs end},
  ['src.mods.ModUpdate']={beginFetchReleases=function(repo)eq(case=='direct',false,'direct artwork bypasses launcher release cache');eq(repo,'Bentley734/KIM1025','correct artwork repository');return {}end,
   pumpFetchReleases=function()return true,{{version='1.0.0',zip={name=case=='wrong-release' and 'unrelated.zip' or 'KIM1025-assets-v1.0.0.zip',url='fixture',size=#archive}}}end},
  ['src.net.Fetch']={download=function(_,filename)files[filename]=archive;return {}end,poll=function()return {status='ok'}end,release=function()end}}
 local mod={generation=1,path='fixture',content={screens={register=function()end}},info=function()return nil end,list=function()return {}end,
  cache={read=function(_,k)return cache[k]end,info=function(_,k)return cache[k] and {size=#cache[k]}end,
   write=function(_,k,v)if case=='write-failure' and k:find('/files/',1,true)then return nil,'disk full'end;cache[k]=v;return true end,
   delete=function(_,k)cache[k]=nil;return true end}}
 local env=setmetatable({require=function(n)return assert(modules[n],n)end,love={data={
  hash=function(algorithm,bytes)eq(algorithm,'sha256','SHA256 verification');eq(bytes,'fixture artwork','verify uncompressed bytes');return digest end,
  encode=function(_,encoding,bytes)eq(encoding,'hex','native digest encoding');return bytes end}}},{__index=_G})
 local manager=assert(load(source,'production artwork installer','t',env))()(mod,{embedded=true,assetURL=case=='direct' and 'fixture://pinned.zip' or nil,assetSize=#archive,version='1.0.0',packId='kim1025_assets',repo='Bentley734/KIM1025',
  cacheNamespace='kim1025_assets',assetName='KIM1025-assets-v1.0.0.zip',verifyFiles=true,indexOnly=true,
  legacyRoots={},allowedPrefix='assets/battle/backgrounds/aspect/'})
 manager:start()
 for i=1,20 do manager:update()end
 eq(cache['kim_assets/complete.txt'],'zip:1.2.0','original pack marker untouched')
 eq(cache['kim_assets/files/original'],'preserve','original pack art untouched')
 if case=='valid' or case=='direct' then
  eq(manager.state,'done','real ZIP directory and extraction complete')
  eq(manager:isComplete(),true,'art completion recorded')
  eq(manager:read(path),'fixture artwork','cache read serves installed art')
  eq(cache['kim1025_assets/installed-files.txt']:find(path,1,true)~=nil,true,'removal index saved')
  local n=0;for _ in pairs(files)do n=n+1 end;eq(n,0,'temporary ZIP cleaned')
  manager:beginDelete();for i=1,10 do manager:update()end
  eq(manager.state,'deleted','scoped removal completes')
  eq(manager:read(path),nil,'only artwork removed')
  eq(cache['kim_assets/files/original'],'preserve','removal preserves original cache')
 else
  eq(manager.state,'error',case..' rejected')
  eq(manager:isComplete(),false,case..' never commits completion')
  eq(manager:read(path),nil,case..' never installs invalid art')
 end
end
print('PASS: '..checks..' production ZIP installation, verification, rejection, cleanup and cache-isolation checks')
