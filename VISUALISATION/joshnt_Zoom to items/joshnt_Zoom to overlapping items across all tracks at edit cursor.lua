-- @noindex

---------------------------------------
--------- USER CONFIG - EDIT ME -------
--- Default Values for input dialog ---
---------------------------------------

local moveCursor = true
local changeSelection = false

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

local numItemsTotal = reaper.CountMediaItems(0)
local numSelTracks = reaper.CountSelectedTracks(0)
if numItemsTotal == 0 then joshnt.TooltipAtMouse("No items in project") return end
if numSelTracks == 0 then joshnt.TooltipAtMouse("No tracks selected") return end

local function main()
    local numItems = reaper.CountSelectedMediaItems(0)
    local cursorPos = reaper.GetCursorPosition()


    local timeRangeStart, timeRangeEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    reaper.GetSet_LoopTimeRange(true, false, 0, reaper.GetProjectLength(0), false)
    local prevSelection = joshnt.saveItemSelection()
    reaper.SelectAllMediaItems(0, false)
    reaper.Main_OnCommand(40717,0) -- select all items in teimeselection on all tracks
    
    local itemGroups, itemStarts, itemEnds = joshnt.getOverlappingItemGroupsOfSelectedItems()

    local groupToSelect;
    if not itemGroups or not itemStarts or not itemEnds then joshnt.TooltipAtMouse("Unable to get overlapping items") return end
    for i = 1, #itemStarts do
        if itemStarts[i] <= cursorPos and itemEnds[i] > cursorPos then groupToSelect = i break end
    end

    if not groupToSelect then 
        joshnt.TooltipAtMouse("No next overlapping item group found") 
        groupToSelect = #itemGroups
    end

    -- zoom to group 
    reaper.SelectAllMediaItems(0, false)
    joshnt.reselectItems(itemGroups[groupToSelect])
    local startPositionSelection, endPositionSelection = joshnt.startAndEndOfSelectedItems()
    reaper.GetSet_LoopTimeRange(true, false, startPositionSelection, endPositionSelection, false)
    reaper.Main_OnCommand(40717,0) -- select all items in timeselection
    reaper.PreventUIRefresh(-1)
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_HZOOMITEMS"),0) -- horizontal zoom to selected items
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_VZOOMIITEMS"),0) -- vertical zoom to selected items
    reaper.PreventUIRefresh(1) 


    reaper.SelectAllMediaItems(0, false)
    reaper.GetSet_LoopTimeRange(true, false, timeRangeStart, timeRangeEnd, false)
    if moveCursor then
        reaper.SetEditCurPos(itemStarts[groupToSelect], true, true)
    end
    if changeSelection then
        joshnt.reselectItems(itemGroups[groupToSelect])
    else
        joshnt.reselectItems(prevSelection)
    end
end

reaper.PreventUIRefresh(1) 
reaper.Undo_BeginBlock()  
main()
reaper.Undo_EndBlock("Select next overlapping item group on selected track", -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()