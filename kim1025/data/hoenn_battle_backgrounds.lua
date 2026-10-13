-- Hoenn's environment IDs come from the live RSE profile, never FRLG constants.
-- nil means retain the exact native Emerald arena (including story overrides).
local M={}
function M.resolve(id,terrain,T,kind,period)
 id=tostring(id or ''):upper():gsub('^EM_',''):gsub('ROUTE_?(%d+)','ROUTE_%1')
 period=period or 'day';T=T or {}
 if terrain==nil then return nil end
 local function is(name)return T[name]~=nil and terrain==T[name]end
 -- Frontier, teams, gym leaders, Elite Four, champion and weather trio have
 -- dedicated native scenes. Do not flatten them into generic overworld art.
 for _,name in ipairs({'FRONTIER','GROUDON','KYOGRE','RAYQUAZA','LEADER','CHAMPION',
   'GYM','MAGMA','AQUA','SIDNEY','PHOEBE','GLACIA','DRAKE'}) do
  if is(name) then return nil end
 end
 if is('UNDERWATER') or is('SAND') or is('MOUNTAIN') or is('POND') or is('BUILDING')
  or id:find('UNDERWATER',1,true) or id:find('MT_CHIMNEY',1,true)
  or id:find('JAGGED_PASS',1,true) or id:find('FIERY_PATH',1,true)
  or id:find('ROUTE_113',1,true) or id:find('MT_PYRE',1,true)
  or kind=='indoor' or kind=='building' then return nil end
 local file,category
 -- Terrain wins over named land locations while surfing/fishing.
 if is('WATER') then file,category='sea_'..period,'sea'
 elseif is('CAVE') then file,category='cave_dark','cave'
 elseif is('GRASS') or is('LONG_GRASS') then
  category=id:find('PETALBURG_WOODS',1,true) and 'viridian_forest' or 'grass'
  file=category..'_'..period
 else return nil end
 return {file=file,kind=category,period=category=='cave' and nil or period,
   region='hoenn',environment=terrain,mapId=id}
end
return M
