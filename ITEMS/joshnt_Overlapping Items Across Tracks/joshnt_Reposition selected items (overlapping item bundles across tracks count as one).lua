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
local distance;

local function userInputValues()
    local continue, s = reaper.GetUserInputs("Highlight Tracks if items are:", 1,
        "Distance between items (sec):",
        "1.00")
    
    if not continue or s == "" then return false end
    local q = joshnt.fromCSV(s)
    
    distance = tonumber(q[1])

    if not distance then return false end

    return true
end

if not userInputValues() then joshnt.TooltipAtMouse("User input cancelled/ invalid") return end

reaper.PreventUIRefresh(1)
local itemGroups, itemStarts, itemEnds;
if touchingItemsCountAsOverlap then
    itemGroups = joshnt.getOverlappingItemGroupsOfSelectedItems(0.001)
else
    itemGroups = joshnt.getOverlappingItemGroupsOfSelectedItems()
end

local offset = 0
if itemGroups or itemGroups ~= {} then
    for i = 1, #itemGroups do
        reaper.ShowConsoleMsg("\n\nNewGroup with index "..i)
        local currItemGroup = itemGroups[i]
        
        for j = 1, #currItemGroup do
            local oldPos = reaper.GetMediaItemInfo_Value(currItemGroup[j], "D_POSITION")
            local newPos = oldPos + offset
            reaper.SetMediaItemPosition(currItemGroup[j], newPos, false)
            reaper.ShowConsoleMsg("\nOld Pos: "..oldPos)
            reaper.ShowConsoleMsg("\nNew Pos: "..newPos)
        end

        offset = offset + distance
        reaper.ShowConsoleMsg("\nNew Offset: "..offset)
    end
else
    joshnt.TooltipAtMouse("no item position adjusted \nDid you select any?")
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
