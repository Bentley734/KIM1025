-- Export HD source sheets without exposing filesystem paths to other mods.
return function(mod)
 mod._kimDexSelected=function(side,battle)
  if type(mod.find)~='function'then return true end
  local ok,handle=pcall(mod.find,mod,'1025dex')
  local peer=ok and handle and handle.exports
  if not(peer and type(peer.spriteStyleFor)=='function')then return true end
  local good,style=pcall(peer.spriteStyleFor,side,battle)
  return not good or style==5
 end
 local entries
 local function tableAt(path)
  local source=mod:read(path);return source and assert((loadstring or load)(source))()or {}
 end
 local function catalog()
  if entries then return entries end
  entries=tableAt('data/hd_pokemon_sprites.lua')
  local numeric={};for _,row in pairs(entries)do if type(row)=='table'and row.dex then numeric[tostring(row.dex)]=row end end
  for key,row in pairs(numeric)do entries[key]=row end
  for dex,row in pairs(tableAt('data/hd_pokemon_national.lua'))do entries[tostring(dex)]=row end
  local unown=tableAt('data/hd_unown_forms.lua')
  for index,row in pairs(unown)do
   local letter=tonumber(index)
   if letter then entries['UNOWN_'..(letter<=26 and string.char(64+letter)or letter==27 and 'EXCLAMATION'or 'QUESTION')]=row end
  end
  local deoxys=tableAt('data/hd_deoxys_forms.lua')
  for form,row in pairs(deoxys)do entries['DEOXYS_'..tostring(form):upper()]=row end
  return entries
 end
 mod.exports.getDexSpriteSheet=function(species,side,shiny,dex)
  local key=(mod.exports.normalizeSpeciesKey or string.upper)(tostring(species));local rows=catalog()
  local female=key:match('_FEMALE$')~=nil;key=key:gsub('_FEMALE$','')
  local row=rows[key]or rows[tostring(dex)];if not row then return nil end
  local variants=row[side=='back'and 'back'or 'front']
  variants=variants and variants[shiny and 'shiny'or 'normal']
  local record=variants and (female and variants.female or variants.default or variants.male or variants.female)
  if not record or not record.image then return nil end
  local bytes=mod._kimAssetProvider and mod._kimAssetProvider.read(record.image)or mod:read(record.image)
  if not bytes then return nil end
  local data=love.image.newImageData(love.filesystem.newFileData(bytes,'kim.png'))
  local w,h,count,columns=record.width,record.height,record.frames,record.columns
  if not(w and h and count and columns)or w<1 or h<1 or count<1 or columns<1 then return nil end
  local strip=love.image.newImageData(w*count,h)
  local timing={durations={},total_ticks=0,loop_tick=0}
  for frame=0,count-1 do
   strip:paste(data,frame*w,0,(frame%columns)*w,math.floor(frame/columns)*h,w,h)
   local ticks=(tonumber((record.durations or {})[frame+1])or 100)*60/1000
   timing.durations[frame+1]=ticks;timing.total_ticks=timing.total_ticks+ticks
  end
  return strip,{width=w,height=h,count=count,timing=timing}
 end
end
