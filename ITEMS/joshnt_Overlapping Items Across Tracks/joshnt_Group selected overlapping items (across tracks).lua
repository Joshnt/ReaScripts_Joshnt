-- @noindex

---------------------------------------
--------- USER CONFIG - EDIT ME -------
---------------------------------------

local touchingItemsCountAsOverlap = false -- if true, an item starting at the exact end of the previous group gets counted to it

---------------------------------------
---------- USER CONFIG END ------------
---------------------------------------

-- Load lua utilities
local joshnt_LuaUtils = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/DEVELOPMENT/joshnt_LuaUtilities.lua'
if reaper.file_exists( joshnt_LuaUtils ) then 
  dofile( joshnt_LuaUtils ) 
  if not joshnt or joshnt.version() < 1.0 then 
    reaper.MB("This script requires a newer version of joshnt Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages, 'joshnt_LuaUtilities.lua'","Error",0); 
    return 
  end
else 
  reaper.MB("This script requires joshnt Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt Lua Utilities'","Error",0)
  return
end

local numItems = reaper.CountSelectedMediaItems(0)
if numItems == 0 then joshnt.TooltipAtMouse("No items selected") return end

reaper.PreventUIRefresh(1)
local itemGroups;
if touchingItemsCountAsOverlap then
    itemGroups = joshnt.getOverlappingItemGroupsOfSelectedItems(0.001)
else
    itemGroups = joshnt.getOverlappingItemGroupsOfSelectedItems()
end

if itemGroups or itemGroups ~= {} then
    for i = 1, #itemGroups do
        reaper.SelectAllMediaItems(0, false)
        joshnt.reselectItems(itemGroups[i])
        reaper.Main_OnCommand(40032, 0) -- group items
    end
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
