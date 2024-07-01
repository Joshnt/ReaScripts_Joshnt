-- @description Move non-selected items to avoid overlaps (with all envelopes)
-- @version 1.1
-- @author Joshnt
-- @about
--    Credits to Aaron Cendan https://aaroncendan.me, Joshua Hank
--    Basically the isolate option of my ReaGlue - Regions script without a region around it;
--    Usecase: 
--    multiple Multi-Track Recordings or Sounddesigns across multiple tracks which needs to be exported to a single variation file.
--    Script creates region across those selected items (including beginning and end silence), adjusting the space between them, moving other non selected items away

---------------------------------------
--------- USER CONFIG - EDIT ME -------
--- Default Values for input dialog ---
---------------------------------------

local distance_to_original_Selection_after_paste_USER = 5 -- Time in Seconds
local distanceToSelItemEnd, startOffsetCut, endOffsetCut

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

local r = reaper

-- para-global variables for script
local originalSelection = {} -- Table to store items grouped by track
local numItems = r.CountSelectedMediaItems(0)
local boolNeedActivateEnvelopeOption = reaper.GetToggleCommandState(40070) == 0

-- Items freistellen/ move selection away from non-selected items
local function moveAwayFromOtherItems()
  reaper.Main_OnCommand(40309, 0) -- Ripple editing off
  -- get items
  reaper.SelectAllMediaItems(0, false)
  joshnt.reselectItems(originalSelection)
  local originalSelStart, originalSelEnd = joshnt.startAndEndOfSelectedItems()
  local overlappingItemsStart, overlappingItemsEnd = joshnt.getOverlapPointsFromSelection(true)
  r.GetSet_LoopTimeRange(true, false, overlappingItemsStart, overlappingItemsEnd, false)
  reaper.Main_OnCommand(40717,0) -- select all items in teimeselection
  joshnt.unselectItems(originalSelection)
  local otherItems = joshnt.saveItemSelection()

  local lockedItems_ALL = joshnt.saveLockedItems()
  -- remove items which are about to be moved from array
  if lockedItems_ALL then
    local i = 1
    while i <= #lockedItems_ALL do
      local item = lockedItems_ALL[i]
      if reaper.IsMediaItemSelected(item) then
          table.remove(lockedItems_ALL, i)
      else
          i = i + 1
      end
    end
  end

  -- insert Time
  reaper.Main_OnCommand(40309, 0) -- Ripple editing off
  -- move parent envelope - insert empty items
  local insertedEmptyItems = {}
  -- create empty items
  for i=0, reaper.CountTracks(0)-1 do
    reaper.SetOnlyTrackSelected(reaper.GetTrack(0, i))
    reaper.SetEditCurPos(overlappingItemsStart, true, true)
    reaper.SelectAllMediaItems(0, false)
    reaper.UpdateArrange() 
    reaper.Main_OnCommand(40142, 0) -- insert empty item
    table.insert(insertedEmptyItems, reaper.GetSelectedMediaItem(0,0))
  end
  joshnt.reselectItems(insertedEmptyItems)


  r.GetSet_LoopTimeRange(true, false, overlappingItemsStart-distance_to_original_Selection_after_paste_USER, overlappingItemsEnd, false)
  local pasteSelectionLength = overlappingItemsEnd - (overlappingItemsStart-distance_to_original_Selection_after_paste_USER)
  reaper.UpdateArrange()
  reaper.Main_OnCommand(40307, 0) -- cut area of items
  joshnt.unselectAllTracks()
  reaper.SetOnlyTrackSelected(reaper.GetTrack(0, 0))
  
  reaper.Main_OnCommand(40311, 0) -- Ripple editing all tracks 
  reaper.SetEditCurPos(overlappingItemsEnd, true, true)
  reaper.Main_OnCommand(42398, 0) -- paste

  -- remove inserted empty items
  r.GetSet_LoopTimeRange(true, false, overlappingItemsEnd, overlappingItemsEnd + pasteSelectionLength, false)
  reaper.SelectAllMediaItems(0, false)
  reaper.UpdateArrange()
  reaper.Main_OnCommand(40717 ,0) -- select items in time selection
  reaper.Main_OnCommand(40309, 0) -- Ripple editing off
  reaper.Main_OnCommand(40006,0) -- delete selected Items

  joshnt.reselectItems(otherItems)
  r.GetSet_LoopTimeRange(true, false, overlappingItemsStart-startOffsetCut, overlappingItemsEnd+endOffsetCut, false)
  joshnt.unselectAllTracks()
  joshnt.selectOnlyTracksOfSelectedItems()
  local selPasteTrack = reaper.GetSelectedTrack(0, 0)
  reaper.UpdateArrange()
  reaper.SetOnlyTrackSelected(selPasteTrack)
  reaper.Main_OnCommand(40307, 0) -- cut area of items

  reaper.SetEditCurPos(overlappingItemsEnd, true, true)
  reaper.Main_OnCommand(42398, 0) -- paste 

  joshnt.lockItemsState(lockedItems_ALL,1)
  reaper.Main_OnCommand(40309, 0) -- Ripple editing off
    
end

-- Main function
local function main()
  if numItems == 0 then 
    r.ShowMessageBox("No items selected!", "Error", 0)
    return
  end
  r.PreventUIRefresh(1) 
  reaper.Undo_BeginBlock()  
  local originalRippleEditState = joshnt.getRippleEditingMode()
  if boolNeedActivateEnvelopeOption then
    reaper.Main_OnCommand(40070, 0)
  end
  originalSelection = joshnt.saveItemSelection()

  -- isolate
  moveAwayFromOtherItems()
  reaper.SelectAllMediaItems(0, false)
  joshnt.reselectItems(originalSelection)

  joshnt.setRippleEditingMode(originalRippleEditState)
  if boolNeedActivateEnvelopeOption then
    reaper.Main_OnCommand(40070, 0)
  end
  reaper.Undo_EndBlock("Isolate items - move selected", -1)
  r.PreventUIRefresh(-1)
  reaper.UpdateArrange()
end


-- Run the main function
main()


