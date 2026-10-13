local untouched=function()end
local Manager={buildOptionRows=untouched,openOptions=untouched,goBack=untouched}
package.loaded['src.mods.ManagerState']=Manager
local mod={};local api=assert(loadfile('lib/settings_groups.lua'))()(mod)
local source={{id='dex',option={key='animatedPokedex'}},{id='backgrounds',option={key='hdBattleBackgrounds'}},
 {id='trainer',option={key='battleTrainerSprite'}},{id='moves',option={key='battleAnimations'}},{id='assets',assetManager=true}}
local list={};local rows=api.apply(list,source,'list')
assert(#rows==6 and rows[6].cancel and list.items==rows)
for i=1,5 do assert(rows[i]==source[i])end
assert(#list._kimSettingsNavigation.parents==0 and not api.back(list))
assert(Manager.buildOptionRows==untouched and Manager.openOptions==untouched and Manager.goBack==untouched)
print('PASS: native flat settings, four controls, downloader and B/back')
