-- @description Move selected items to avoid overlaps (with all envelopes)
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
local compensateAdditionalTime_USER = false -- as the selected items get pasted again, that can result in bigger time gaps to the next item; removing that inserted time may result in abrupt cutting in envelopes

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
local parentTracksWithEnvelopes_GLOBAL = {}

-- Items freistellen/ move selection away from non-selected items
local function moveAwayFromOtherItems()
  reaper.Main_OnCommand(40309, 0) -- Ripple editing off
  -- get items
  reaper.SelectAllMediaItems(0, false)
  joshnt.reselectItems(originalSelection)

  local originalSelStart, originalSelEnd = joshnt.startAndEndOfSelectedItems()
  local overlappingItemsStart, overlappingItemsEnd = joshnt.getOverlapPointsFromSelection(true)
  joshnt.pauseForUserInput(overlappingItemsStart.." and "..overlappingItemsEnd, true)
  
  -- insert Time
  r.GetSet_LoopTimeRange(true, false, overlappingItemsStart, overlappingItemsEnd, false)
  reaper.Main_OnCommand(40309, 0) -- Ripple editing off
  reaper.SelectAllMediaItems(0, false)
  -- move parent envelope - insert empty items
  local insertedEmptyItems = {}
  if #parentTracksWithEnvelopes_GLOBAL > 0 then
    joshnt.unselectAllTracks()
    -- create empty items
    for index, parentTracks in ipairs(parentTracksWithEnvelopes_GLOBAL) do
      reaper.SetOnlyTrackSelected(parentTracks)
      reaper.SetEditCurPos(overlappingItemsStart, true, true)
      reaper.SelectAllMediaItems(0, false)
      reaper.UpdateArrange() 
      reaper.Main_OnCommand(40142, 0) -- insert empty item
      table.insert(insertedEmptyItems, reaper.GetSelectedMediaItem(0,0))
    end
    joshnt.reselectItems(insertedEmptyItems)
  end

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

  joshnt.reselectItems(originalSelection)
  r.GetSet_LoopTimeRange(true, false, originalSelStart-distance_to_original_Selection_after_paste_USER, overlappingItemsEnd, false)
  joshnt.unselectAllTracks()
  joshnt.selectOnlyTracksOfSelectedItems()
  local selPasteTrack = reaper.GetSelectedTrack(0, 0)
  reaper.UpdateArrange()

  reaper.Main_OnCommand(40307, 0) -- cut area of items

  reaper.SetOnlyTrackSelected(selPasteTrack)
  reaper.SetEditCurPos(overlappingItemsEnd, true, true)
  if #parentTracksWithEnvelopes_GLOBAL == 0 then 
    reaper.Main_OnCommand(40311, 0) -- Ripple editing all tracks 
  end
  reaper.Main_OnCommand(42398, 0) -- paste 
  reaper.Main_OnCommand(40309, 0) -- Ripple editing off

  local _,endTimeSel_NEW = joshnt.startAndEndOfSelectedItems()

  if (originalSelEnd < overlappingItemsEnd or originalSelStart > overlappingItemsStart) and compensateAdditionalTime_USER then 
    joshnt.removeTimeOnAllTracks(endTimeSel_NEW, endTimeSel_NEW + (overlappingItemsEnd-originalSelEnd)+ (originalSelStart-overlappingItemsStart))
  end
    
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
  joshnt.selectOnlyTracksOfSelectedItems()
  local trackIDs = {}

  for i = 0, reaper.CountSelectedTracks(0) do
    table.insert(trackIDs,reaper.GetSelectedTrack(0, i))
  end

  -- get all parent Tracks
  local parentTracks = joshnt.getParentTracksWithoutDuplicates(trackIDs)
  -- get parent Tracks with envelopes
  for i = 1, #parentTracks do
    if reaper.CountTrackEnvelopes(parentTracks[i]) > 0 then
      table.insert(parentTracksWithEnvelopes_GLOBAL,parentTracks[i])
    end
  end

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


