local M=assert(loadfile(arg[1]..'/data/hoenn_battle_backgrounds.lua'))()
local T={};for i,n in ipairs({'GRASS','LONG_GRASS','SAND','UNDERWATER','WATER','POND','MOUNTAIN','CAVE','BUILDING','PLAIN',
'FRONTIER','GROUDON','KYOGRE','RAYQUAZA','LEADER','CHAMPION','GYM','MAGMA','AQUA','SIDNEY','PHOEBE','GLACIA','DRAKE'})do T[n]=i-1 end
local checks=0;local function eq(a,b)checks=checks+1;assert(a==b,tostring(a)..' ~= '..tostring(b))end
for _,period in ipairs({'day','night','sunrise','sunset'}) do
 for _,name in ipairs({'GRASS','LONG_GRASS'})do eq(M.resolve('EM_ROUTE_119',T[name],T,'route',period).file,'grass_'..period)end
 eq(M.resolve('EM_PETALBURG_WOODS',T.GRASS,T,'route',period).file,'viridian_forest_'..period)
 eq(M.resolve('EM_PETALBURG_WOODS',T.WATER,T,'route',period).file,'sea_'..period)
 eq(M.resolve('EM_GRANITE_CAVE_B1F',T.CAVE,T,'cave',period).file,'cave_dark')
 eq(M.resolve('EM_METEOR_FALLS_1F_1R',T.WATER,T,'cave',period).file,'sea_'..period)
 for _,n in ipairs({'SAND','UNDERWATER','POND','MOUNTAIN','BUILDING','PLAIN','FRONTIER','GROUDON','KYOGRE','RAYQUAZA','LEADER','CHAMPION','GYM','MAGMA','AQUA','SIDNEY','PHOEBE','GLACIA','DRAKE'})do
  eq(M.resolve('EM_ROUTE_111',T[n],T,'route',period),nil)
 end
 for _,id in ipairs({'EM_UNDERWATER_ROUTE_124','EM_MT_CHIMNEY','EM_JAGGED_PASS','EM_FIERY_PATH','EM_ROUTE_113','EM_ROUTE113','EM_MT_PYRE_6F'})do eq(M.resolve(id,T.GRASS,T,'route',period),nil)end
 eq(M.resolve('EM_LITTLEROOT_TOWN_BRENDANS_HOUSE_1F',T.GRASS,T,'indoor',period),nil)
end
-- shifted constants prove the resolver does not assume FRLG numeric values.
local shifted={WATER=200,CAVE=300};eq(M.resolve('EM_ROUTE_124',200,shifted,'route','night').file,'sea_night')
eq(M.resolve('EM_ROUTE_124',nil,{},'route','night'),nil)
print('Hoenn background checks',checks)
