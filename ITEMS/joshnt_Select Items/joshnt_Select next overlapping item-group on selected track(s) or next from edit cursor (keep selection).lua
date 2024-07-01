-- @noindex

---------------------------------------
--------- USER CONFIG - EDIT ME -------
--- Default Values for input dialog ---
---------------------------------------

local moveCursor = true

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
  local startPositionSelection, endPositionSelection, cursorPos;
  if numItems == 0 then 
    cursorPos = reaper.GetCursorPosition()
  else
    startPositionSelection, endPositionSelection = joshnt.startAndEndOfSelectedItems()
  end

  local timeRangeStart, timeRangeEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  reaper.GetSet_LoopTimeRange(true, false, 0, reaper.GetProjectLength(0), false)
  local prevSelection = joshnt.saveItemSelection()
  reaper.SelectAllMediaItems(0, false)
  reaper.Main_OnCommand(40718,0) -- select all items in teimeselection on selected tracks
  
  local itemGroups, itemStarts, itemEnds = joshnt.getOverlappingItemGroupsOfSelectedItems()

  local groupToSelect;
  if not itemGroups or not itemStarts or not itemEnds then joshnt.TooltipAtMouse("Unable to get overlapping items") return end
  if numItems == 0 then 
    for i = 1, #itemStarts do
      if itemStarts[i] <= cursorPos and itemEnds[i] > cursorPos then groupToSelect = i break
      elseif itemStarts[i] > cursorPos then groupToSelect = i break end
    end
  else
    for i = 1, #itemStarts do
      if i == #itemStarts then break end
      if (itemStarts[i] <= startPositionSelection and itemEnds[i] >= endPositionSelection) then -- item selection is part of existing group
        if (itemStarts[i] == startPositionSelection and itemEnds[i] == endPositionSelection) then
          groupToSelect = i+1 
        else 
          groupToSelect = i
        end
        break
      elseif itemStarts[i] > endPositionSelection then
        groupToSelect = i break
      end
    end
  end
  reaper.SelectAllMediaItems(0, false)
  joshnt.reselectItems(prevSelection)
  reaper.GetSet_LoopTimeRange(true, false, timeRangeStart, timeRangeEnd, false)
  if not groupToSelect then 
    joshnt.TooltipAtMouse("No next overlapping item group found") 
    groupToSelect = #itemGroups
  end
  joshnt.reselectItems(itemGroups[groupToSelect])
  if moveCursor then
    reaper.SetEditCurPos(itemStarts[groupToSelect], true, true)
  end
end

reaper.PreventUIRefresh(1) 
reaper.Undo_BeginBlock()  
main()
reaper.Undo_EndBlock("Select next overlapping item group on selected track", -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()