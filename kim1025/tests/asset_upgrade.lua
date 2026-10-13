local function read(p)local f=assert(io.open(p));local s=f:read('*a');f:close();return s end
local s=read('lib/asset_download_manager.lua');local a=assert(s:find('  local function installedAssetVersion()',1,true))
local b=assert(s:find('  function manager:isComplete()',a,true))
local marker;local env=setmetatable({safeCacheRead=function()return marker end,COMPLETE_KEY='complete',
 BASE_ASSET_VERSION='1.0.0',ASSET_VERSION='1.2.0',ASSET_CHAIN={'1.0.0','1.1.0','1.2.0'}},{__index=_G})
local nextVersion=assert(load(s:sub(a,b-1)..'\nreturn nextAssetVersion','production asset upgrade','t',env))()
local checks=0
for _,case in ipairs({{false,'1.0.0'},{'zip:1.0.0','1.1.0'},{'legacy:1.0.0','1.1.0'},
 {'zip:1.1.0','1.2.0'},{'zip:1.2.0',false},{'broken','1.0.0'}})do
 marker=case[1] or nil;checks=checks+1;assert((nextVersion() or false)==case[2],'upgrade from '..tostring(marker))
end
print('PASS: '..checks..' asset upgrade checks')
