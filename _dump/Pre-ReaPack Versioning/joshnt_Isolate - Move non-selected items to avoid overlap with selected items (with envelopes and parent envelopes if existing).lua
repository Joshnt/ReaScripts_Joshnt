-- @description Move selected items to avoid overlaps (with parent envelopes)
-- @version 1.0
-- @author Joshnt
-- @about
--    Credits to Aaron Cendan https://aaroncendan.me, David Arnoldy, Joshua Hank
--    Basically the isolate option of my ReaGlue - Regions script without a region around it;
--    Usecase: 
--    multiple Multi-Track Recordings or Sounddesigns across multiple tracks which needs to be exported to a single variation file.
--    Script creates region across those selected items (including beginning and end silence), adjusting the space between them, moving other non selected items away

r = reaper

boolNeedActivateEnvelopeOption = reaper.GetToggleCommandState(40070) == 0

function getRippleEditingMode()
    local perTrackState = reaper.GetToggleCommandState(40310) -- Ripple editing per-track
    local allTracksState = reaper.GetToggleCommandState(40311) -- Ripple editing all tracks

    if perTrackState == 1 then
        return 1
    elseif allTracksState == 1 then
        return 2
    else
        return 0
    end
end

function setRippleEditingMode(mode)
    if mode == 0 then
        reaper.Main_OnCommand(40309, 0)  -- Ripple editing off
    elseif mode == 1 then
        reaper.Main_OnCommand(40310, 0)  -- Ripple editing per-track
    elseif mode == 2 then
        reaper.Main_OnCommand(40311, 0)  -- Ripple editing all tracks
    else
        reaper.ShowConsoleMsg("Invalid ripple editing mode: " .. mode .. "\n")
    end
end

function initReaGlue()
  t = {}  -- Table to store items grouped by track
  
  -- Function to add items to the table
  function addItemToTable(item, itemLength)
      track = r.GetMediaItem_Track(item)
      if not t[track] then
          t[track] = {}
      end
      table.insert(t[track], {item, itemLength})
  end
  
  -- Group items by track
  for i = 0, numItems - 1 do
      itemGlobal = r.GetSelectedMediaItem(0, i)
      if itemGlobal then
          local it_len = r.GetMediaItemInfo_Value(itemGlobal, 'D_LENGTH')
          addItemToTable(itemGlobal, it_len)
      end
  end
  
  -- table trackIDs to access keys more easily
  trackIDs = {}
  for key, _ in pairs(t) do
    table.insert(trackIDs, key)
  end
end


function startAndEndOfSelectedItems()
    local itemsInTimeSelection = r.CountSelectedMediaItems(0)
    local selItemsStart = 0
    local selItemsEnd = 0
    for i = 0, itemsInTimeSelection - 1 do
        local itemTempTime = r.GetSelectedMediaItem(0, i)
        if itemTempTime then
            local it_len = r.GetMediaItemInfo_Value(itemTempTime, 'D_LENGTH')
            local it_start = reaper.GetMediaItemInfo_Value(itemTempTime, "D_POSITION")
            local it_end = it_start + it_len
            if i == 0 then
              selItemsStart = it_start
              selItemsEnd = it_end
            else
              selItemsStart = math.min(selItemsStart, it_start)
              selItemsEnd = math.max(selItemsEnd, it_end)
            end
        end
    end
    return selItemsStart, selItemsEnd
end

function saveItemSelection()
  local itemTable = {}
  local numSelItems_TEMP = r.CountSelectedMediaItems(0)
  for i = 0, numSelItems_TEMP - 1 do
    local SelItem_TEMP = r.GetSelectedMediaItem(0, i)
    if SelItem_TEMP then
      table.insert(itemTable,SelItem_TEMP)
    end
  end
  return itemTable
end

function reselectItems(itemTable)
  local numSelItems_TEMP = #itemTable
  for i = 0, numSelItems_TEMP do
    local SelItem_TEMP = itemTable[i]
    if SelItem_TEMP then
      if reaper.ValidatePtr(SelItem_TEMP, "MediaItem*") then
        reaper.SetMediaItemSelected(SelItem_TEMP, true)
      end
    end
  end
end

function unselectItems(itemTable)
  local numSelItems_TEMP = #itemTable
  for i = 0, numSelItems_TEMP do
    local SelItem_TEMP = itemTable[i]
    if SelItem_TEMP then
        if reaper.ValidatePtr(SelItem_TEMP, "MediaItem*") then
          reaper.SetMediaItemSelected(SelItem_TEMP, false)
        end
    end
  end
end

function selectOriginalSelection(boolSelect)
  for track, items in pairs(t) do
    for index, _ in ipairs(items) do
      reaper.SetMediaItemSelected(items[index][1], boolSelect)
    end
  end
  reaper.UpdateArrange()
end

-- Function to check which of the selected items are present in a given table and return them
function getSelectedItemsInTable(itemTable)
    local selectedItemsInTable = {}
    local numSelectedItems = reaper.CountSelectedMediaItems(0)
    
    for i = 0, numSelectedItems - 1 do
        local selectedItem = reaper.GetSelectedMediaItem(0, i)
        if selectedItem then
            for _, item in ipairs(itemTable) do
                if selectedItem == item then
                    table.insert(selectedItemsInTable, selectedItem)
                    break
                end
            end
        end
    end
    
    return selectedItemsInTable
end

-- Function to unselect all tracks
function unselectAllTracks()
    local num_tracks = reaper.CountTracks(0) -- Get the total number of tracks in the project
    for i = 0, num_tracks - 1 do
        local track = reaper.GetTrack(0, i) -- Get each track by index
        reaper.SetTrackSelected(track, false) -- Set the track as unselected
    end
end

-- Save all locked items to an array and unlock them
function saveLockedItems()
    local numItems = reaper.CountMediaItems(0) -- Get the number of media items in the project
    local lockedItems = {} -- Array to store locked items

    for i = 0, numItems - 1 do
        local item = reaper.GetMediaItem(0, i) -- Get each media item
        local isLocked = reaper.GetMediaItemInfo_Value(item, "C_LOCK") -- Get the lock status of the item

        if isLocked == 1 then
            table.insert(lockedItems, item) -- Save the locked item to the array
            reaper.SetMediaItemInfo_Value(item, "C_LOCK", 0) -- Unlock the item
        end
    end

    return lockedItems
end

function lockItemsState(items, intLock)
    for i, item in ipairs(items) do
        if item then
          reaper.SetMediaItemInfo_Value(item, "C_LOCK", intLock) -- unlock the item
        end
    end
end


-- Function to check for overlapping regions with selected items
local function checkOverlapWithRegions(boolReturnRegionBounds)

    local proj = r.EnumProjects(-1, "")
    local numRegions = r.CountProjectMarkers(proj, 0)
    if numRegions == 0 then
        if boolReturnRegionBounds then
          return -1, -1
        else  
          return false
        end
    end
    local numItems_TEMP = reaper.CountSelectedMediaItems()

    local overlapDetected = false
    local regionStart = -1
    local regionEnd = -1
    
    for i = 0, numItems_TEMP - 1 do
        local item = r.GetSelectedMediaItem(0, i)
        local itemStart = r.GetMediaItemInfo_Value(item, "D_POSITION")
        local itemEnd = itemStart + r.GetMediaItemInfo_Value(item, "D_LENGTH")

        for j = 0, numRegions - 1 do
            local _, isrgn, rgnstart, rgnend = r.EnumProjectMarkers( j)
            if isrgn then
                if itemStart < rgnend and itemEnd > rgnstart then
                    overlapDetected = true
                    regionStart = rgnstart
                    regionEnd = rgnend
                    break
                end
            end
        end

        if overlapDetected then
            break
        end
    end
  if boolReturnRegionBounds then
    return regionStart, regionEnd
  else  
    return overlapDetected
  end
end

function insertTimeOnAllTracks(startTimeInsert, endTimeInsert)
  if endTimeInsert-startTimeInsert > 0.0000001 then
      local itemSelectionTemp = saveItemSelection()
      reaper.SelectAllMediaItems(0, false)
      r.GetSet_LoopTimeRange(true, false, startTimeInsert, endTimeInsert, false)
      reaper.Main_OnCommand(40311, 0) -- Ripple editing all tracks
      reaper.SetOnlyTrackSelected(reaper.GetTrack(0, 0))
      reaper.Main_OnCommand(40142, 0) -- insert empty item
      
      -- remove inserted items
      reaper.Main_OnCommand(40309, 0) -- Ripple editing off
      reaper.SelectAllMediaItems(0, false)
      reaper.Main_OnCommand(40717,0) -- select all items in teimeselection
      reaper.Main_OnCommand(40006,0) -- delete selected items (via command to make use of ripple edit)
      
      -- restore beginning
      reselectItems(itemSelectionTemp)
    end
end

function removeTimeOnAllTracks(startTimeInsert, endTimeInsert)
  if endTimeInsert-startTimeInsert > 0.0000001 then
      local itemSelectionTemp = saveItemSelection()
      reaper.SelectAllMediaItems(0, false)
      r.GetSet_LoopTimeRange(true, false, startTimeInsert, endTimeInsert, false)
      reaper.Main_OnCommand(40309, 0) -- Ripple editing off
      reaper.SetOnlyTrackSelected(reaper.GetTrack(0, 0))
      reaper.Main_OnCommand(40142, 0) -- insert empty item
      
      -- remove inserted items
      reaper.Main_OnCommand(40311, 0) -- Ripple editing all tracks
      reaper.SelectAllMediaItems(0, false)
      reaper.Main_OnCommand(40717,0) -- select all items in teimeselection
      reaper.Main_OnCommand(40006,0) -- delete selected items (via command to make use of ripple edit)
      
      reaper.UpdateArrange()
      
      -- restore beginning
      reselectItems(itemSelectionTemp)
    end
end

-- Items freistellen/ move selection away from non-selected items
local function moveAwayFromOtherItems()
  reaper.Main_OnCommand(40309, 0) -- Ripple editing off
  -- get items
  reaper.SelectAllMediaItems(0, false)
  selectOriginalSelection(true)
  local currentOriginalStart_TEMP, currentOriginalEnd_TEMP = startAndEndOfSelectedItems()
  
  reaper.GetSet_LoopTimeRange(true, false, currentOriginalStart_TEMP, currentOriginalEnd_TEMP, false)
  
  reaper.Main_OnCommand(40717,0) -- select all items in teimeselection
  selectOriginalSelection(false)

  
  local otherItemsStart, otherItemsEnd = 0
  -- find overlap of non-selected items with selected items
  if reaper.CountSelectedMediaItems(0) == 0 then 
    return
  else
    otherItemsStart, otherItemsEnd = startAndEndOfSelectedItems()
  end
  
  -- find overlap of non-selected items with other non-selected items which don't overlap selected items (point of inserting time)
  local foundAllOverlaps = false 
  local otherItemsEndWithOverlaps = otherItemsEnd
  local whileBreakDebug = 0
  local lockedItems_TEMP = {}
  while foundAllOverlaps == false do
    local newLoopBound_TEMP = math.max(currentOriginalEnd_TEMP,otherItemsEnd)
    r.GetSet_LoopTimeRange(true, false, currentOriginalStart_TEMP, newLoopBound_TEMP, false)
    reaper.Main_OnCommand(40717,0) -- select all items in teimeselection
    selectOriginalSelection(false)
    local _, otherItemsEndTemp = startAndEndOfSelectedItems()
    -- if locked items in region, go to end of region
    if lockedItems_Global then
      lockedItems_TEMP2 = getSelectedItemsInTable(lockedItems_Global)
      if lockedItems_TEMP2 ~= lockedItems_TEMP then
        reaper.SelectAllMediaItems(0, false)
        reselectItems(lockedItems_TEMP2)
        local _, regionEnd_TEMP = checkOverlapWithRegions(true)
        if regionEnd_TEMP ~= -1 then
          otherItemsEndTemp = math.max(otherItemsEndTemp, regionEnd_TEMP)
        end
        lockedItems_TEMP = lockedItems_TEMP2
      end
      if otherItemsEnd == otherItemsEndTemp then
        foundAllOverlaps = true
      else
        otherItemsEnd = otherItemsEndTemp
      end
    end
    
    if whileBreakDebug == 100000 then
      reaper.ShowMessageBox("Unable to move Selection (extreme Number of overlapping later Items)", "Error", 0)
      break
    end
    
    whileBreakDebug = whileBreakDebug + 1
  end
  
  -- insert Time
    reaper.SelectAllMediaItems(0, false)
    reaper.Main_OnCommand(40309, 0) -- Ripple editing off
    
    -- move parent envelope - insert empty items
    local insertedEmptyItems = {}
    if #parentTracksWithEnvelopes_GLOBAL > 0 then
      unselectAllTracks()
      -- create empty items
      for index, parentTracks in ipairs(parentTracksWithEnvelopes_GLOBAL) do
        reaper.SetOnlyTrackSelected(parentTracksWithEnvelopes_GLOBAL[index])
        r.GetSet_LoopTimeRange(true, false, currentOriginalStart_TEMP-1, currentOriginalEnd_TEMP+1, false)
        reaper.SetEditCurPos(currentOriginalStart_TEMP-1, true, true)
        reaper.UpdateArrange() 
        reaper.Main_OnCommand(40142, 0) -- insert empty item
        table.insert(insertedEmptyItems, reaper.GetSelectedMediaItem(0,0))
      end
      reselectItems(insertedEmptyItems)
    end
    
    selectOriginalSelection(true)
    r.GetSet_LoopTimeRange(true, false, currentOriginalStart_TEMP-1, currentOriginalEnd_TEMP+1, false)
    reaper.UpdateArrange()
    reaper.Main_OnCommand(40307, 0) -- cut area of items
    reaper.SetEditCurPos(otherItemsEnd, true, true)
    unselectAllTracks()
    
    -- select first track or first parent track
    for key, _ in pairs(t) do
      reaper.SetTrackSelected(key, true)
    end
    -- select first track of parents
    if next(insertedEmptyItems) ~= nil then
      for index, trackParentTEMP in pairs(parentTracksWithEnvelopes_GLOBAL) do
        reaper.SetTrackSelected(trackParentTEMP, true)
      end
    end
    local firstTrackOfOriginalSelection = reaper.GetSelectedTrack(0, 0)
    reaper.SetOnlyTrackSelected(firstTrackOfOriginalSelection)
    
    reaper.Main_OnCommand(40311, 0) -- Ripple editing all tracks 
    reaper.SetEditCurPos(otherItemsEnd, true, true)
    reaper.Main_OnCommand(42398, 0) -- paste
      
    -- remove inserted empty items for parent envelopes
    if next(insertedEmptyItems) ~= nil then
      local pastedItems_TEMP = saveItemSelection() 
      local pastedItemsStart_TEMP, pastedItemsEnd_TEMP = startAndEndOfSelectedItems()
      unselectAllTracks()
      for index, trackParentTEMP in pairs(parentTracksWithEnvelopes_GLOBAL) do
        reaper.SetTrackSelected(trackParentTEMP, true)
      end
      
      r.GetSet_LoopTimeRange(true, false, pastedItemsStart_TEMP, pastedItemsEnd_TEMP, false)
      reaper.SelectAllMediaItems(0, false)
      reaper.UpdateArrange()
      reaper.Main_OnCommand(40718 ,0) -- select items on selected tracks in time selection
      reaper.Main_OnCommand(40309, 0) -- Ripple editing off
      
      reaper.Main_OnCommand(40006,0) -- delete selected Items
      reselectItems(pastedItems_TEMP)
      
    end
    
    local _,endTimeSel_TEMP = startAndEndOfSelectedItems()
    if (currentOriginalEnd_TEMP - otherItemsEnd) > 0 then
      removeTimeOnAllTracks(endTimeSel_TEMP + 1, endTimeSel_TEMP + 1 + (currentOriginalEnd_TEMP - otherItemsEnd))
    end
    
  
  initReaGlue()
  reaper.SelectAllMediaItems(0, false)
  reaper.Main_OnCommand(40309, 0) -- Ripple editing off
  
  
  
  
  --restore selection
    -- Reselect Items
    selectOriginalSelection(true)
    
end

--DEBUG function
function pauseForUserInput(prompt)
    local ok, input = reaper.GetUserInputs(prompt, 1, "Press OK to continue", "")
    if not ok then
        -- User canceled the input dialog; you can handle it if needed
        reaper.ShowConsoleMsg("Script paused, user canceled the input.\n")
    end
end



-- Function to get parent tracks of table t
local function getParentTracksWithoutDuplicates()
    -- Function to check if a track is in the list
    function isTrackInList(track, trackList)
      for _, t in ipairs(trackList) do
        if t == track then
          return true
        end
      end
      return false
    end
    
    -- Function to get all parent tracks recursively
    function getParentTracks(track, selectedTracks)
      local parentTracks = {}
      local function addParentTracks(tracks)
        local newParents = {}
        for _, tr in ipairs(tracks) do
          local parent = reaper.GetParentTrack(tr)
          if parent and not parentTracks[parent] and not isTrackInList(parent, selectedTracks) then
            parentTracks[parent] = true
            table.insert(newParents, parent)
          end
        end
        if #newParents > 0 then
          addParentTracks(newParents) -- Recursively add parents of the new parents
        end
      end
    
      addParentTracks({track})
      local result = {}
      for parent, _ in pairs(parentTracks) do
        table.insert(result, parent)
      end
      return result
    end
    
    -- Function to get all parent tracks for a list of tracks
    function getAllParentTracks(tracks)
      local allParentTracks = {}
      for _, track in ipairs(tracks) do
        local parentTracks = getParentTracks(track, tracks)
        for _, parent in ipairs(parentTracks) do
          allParentTracks[parent] = true
        end
      end
      local result = {}
      for parent, _ in pairs(allParentTracks) do
        table.insert(result, parent)
      end
      return result
    end
    
    -- Get all parent tracks of the selected tracks
    return getAllParentTracks(trackIDs)
end


-- Main function
function main()
    numItems = r.CountSelectedMediaItems(0)
    if numItems == 0 then 
      r.ShowMessageBox("No items selected!", "Error", 0)
      return 
    end
      r.PreventUIRefresh(1) 
      reaper.Undo_BeginBlock()  
      local originalRippleEditState = getRippleEditingMode()
      if boolNeedActivateEnvelopeOption then
        reaper.Main_OnCommand(40070, 0)
      end
      initReaGlue()
      
      --get locked Items and unlock them
      lockedItems_Global = {}
      lockedItems_Global = saveLockedItems()
      lockItemsState(lockedItems_Global,0)
      -- remove selected items from locked item array
      if lockedItems_Global then
        local i = 1
        while i <= #lockedItems_Global do
          local item = lockedItems_Global[i]
          if reaper.IsMediaItemSelected(item) then
              table.remove(lockedItems_Global, i)
          else
              i = i + 1
          end
        end
      end
      
      -- get parent Tracks with envelopes
      parentTracksWithEnvelopes_GLOBAL = {}
      local parentTracks = getParentTracksWithoutDuplicates()
      for i = 1, #parentTracks do
        if reaper.CountTrackEnvelopes(parentTracks[i]) > 0 then
          table.insert(parentTracksWithEnvelopes_GLOBAL,parentTracks[i])
        end
      end
      -- isolate or only move items on same tracks away 
      moveAwayFromOtherItems()
      
      setRippleEditingMode(originalRippleEditState)
      if boolNeedActivateEnvelopeOption then
        reaper.Main_OnCommand(40070, 0)
      end
    r.PreventUIRefresh(-1)
    reaper.UpdateArrange()
end


-- Run the main function
main()


