-- @description Count selected overlapping item groups/ bundles across tracks
-- @version 1.0
-- @author Joshnt
-- @about
--    alternative to misleading item count with "Item properties (F2)" when crossfading items/ using multi-mic arrangements

---------------------------------------
--------- USER CONFIG - EDIT ME -------
---------------------------------------

local showMessageBox = false -- show a message box with the number of items; if false, use tooltip at mouse

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
local _, itemStarts = joshnt.getOverlappingItemGroupsOfSelectedItems()
reaper.PreventUIRefresh(-1)

if itemStarts then
    if showMessageBox then
        reaper.MB("Number of selected overlapping item groups/ bundles:\n\n"..#itemStarts, "Count overlapping items",0)
    else
        joshnt.TooltipAtMouse(#itemStarts.." overlapping item groups")
    end
else joshnt.TooltipAtMouse("Unable to count overlapping items") end