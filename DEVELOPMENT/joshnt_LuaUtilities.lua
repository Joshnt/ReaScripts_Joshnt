-- @description Adding own functions and functionalities as lua-functions
-- @version 2.0
-- @author Joshnt
-- @provides [nomain] .
-- @about
--    Credits to Aaron Cendan https://aaroncendan.me - I partly straight up copied code from him; as well thanks for the awesome work in the scripting domain of reaper!


joshnt = {}

function joshnt.version()
    local file = io.open((reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/DEVELOPMENT/joshnt_LuaUtilities.lua'):gsub('\\','/'),"r")
    if not file then
      return 0
    end
    local vers_header = "-- @version "
    io.input(file)
    local t = 0
    for line in io.lines() do
        if line:find(vers_header) then
        t = line:gsub(vers_header,"")
        break
        end
    end
    io.close(file)
    return tonumber(t)
end

local r = reaper

-----------------
----- ITEMS -----
-----------------

-- get item property (f2) volume
function joshnt.getItemPropertyVolume(item)
  local take = reaper.GetMediaItemTake(item, 0)
  if not take then
    return
  end
  -- Get the volume of the media item as a double value
  return reaper.GetMediaItemTakeInfo_Value(take, "D_VOL")
end

-- get item property (f2) rate
function joshnt.getItemPropertyRate(item)
  local take = reaper.GetMediaItemTake(item, 0)
  if not take then
    return
  end
  -- Get the volume of the media item as a double value
  return reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
end

-- get item property (f2) pitch
function joshnt.getItemPropertyPitch(item)
  local take = reaper.GetMediaItemTake(item, 0)
  if not take then
    return
  end
  -- Get the volume of the media item as a double value
  return reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
end

-- get item property (f2) pitch
function joshnt.getItemPropertyPitch_WithRatePitch(item)
  local take = reaper.GetMediaItemTake(item, 0)
  if not take then
    return
  end
  -- Get the volume of the media item as a double value
  local pitchRaw = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")

  local preserve_pitch = reaper.GetMediaItemTakeInfo_Value(take, "B_PPITCH")
  local pitchRate = 0
  if preserve_pitch == 1 then
    local rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    -- Calculate the pitch change in semitones
    pitchRate = 12 * math.log(rate) / math.log(2)
  end
  return pitchRaw + pitchRate
end

-- set item property (f2) volume
function joshnt.setItemPropertyVolume(item, volume)
  local take = reaper.GetMediaItemTake(item, 0)
  if take then
    -- Get the volume of the media item as a double value
    reaper.SetMediaItemTakeInfo_Value(take, "D_VOL", volume)
  end
end

-- get start and end of selected items
function joshnt.startAndEndOfSelectedItems()
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

-- save selected items in a table to recall later (see reselectItems)
function joshnt.saveItemSelection()
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

-- reselect a table of items
function joshnt.reselectItems(itemTable)
    if not itemTable then return end
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

-- unselect Items given in a table (to have e.g. everything but items x selected)
function joshnt.unselectItems(itemTable)
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

-- Function to check which of the selected items are present in a given table and return them
function joshnt.getSelectedItemsInTable(itemTable)
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

-- Save all locked items to an array and unlock them
function joshnt.saveLockedItems()
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

function joshnt.lockItemsState(items, intLock)
  if items then
    for i, item in ipairs(items) do
        if item then
          reaper.SetMediaItemInfo_Value(item, "C_LOCK", intLock) -- lock/ unlock the item
        end
    end
  end
end

-- Function to lock selected items
function joshnt.lockSelectedItems()
  -- Get the selected items
  local numSelectedItems = reaper.CountSelectedMediaItems(0)
  if numSelectedItems > 0 then
      for i = 0, numSelectedItems - 1 do
          local selectedItem = reaper.GetSelectedMediaItem(0, i)
          if selectedItem then
              -- Lock the item
              reaper.SetMediaItemInfo_Value(selectedItem, "C_LOCK", 1)
          end
      end
  end
end

function joshnt.sortSelectedItemsByTrack()
    local trackTable = {} -- init table t
    local numSelItems = reaper.CountSelectedMediaItems(0)
    -- Function to add items to the table
    local function addItemToTable(item)
        local track = r.GetMediaItem_Track(item)
        if not trackTable[track] then
          trackTable[track] = {}
        end
        table.insert(trackTable[track], item)
    end
    
    -- Group items by track
    for i = 0, numSelItems - 1 do
        local itemInit_TEMP = r.GetSelectedMediaItem(0, i)
        if itemInit_TEMP then
            addItemToTable(itemInit_TEMP)
        end
    end

    return trackTable
end

-- Function to get overlapping item groups
-- includeCloserThan_Input (in seconds): if distance between items is equal or smaller than given value, items are included in the group (for e.g. splittet item with indiv. fades)
-- returns itemGroups - array with subarrays per group, itemGroupsStartsArray, itemGroupsEndArray
function joshnt.getOverlappingItemGroupsOfSelectedItems(inlcudeCloserThan_Input)
  local itemGroups = {}
  local itemGroupsStartsArray = {}
  local itemGroupsEndArray = {}
  local itemByTrackTable = joshnt.sortSelectedItemsByTrack()
  local numItems = reaper.CountSelectedMediaItems(0)
  local includeCloserThan = inlcudeCloserThan_Input or 0

  if numItems == 0 then return end

  -- check if all items got checked
  local function allItemsChecked(itemIndexPerTrack)
      for tracks, items in pairs(itemByTrackTable) do
          if #items > itemIndexPerTrack[tracks] then
              return false
          end
      end
      return true
  end

  
 -- find earliest Item (with weird table syntax from script)
 local function findEarliestItemAcrossTracks(table, indexTable)
    local earliestTime = math.huge
    local endTime = 0
    for track, items in pairs(table) do
      if #items > indexTable[track] then
        if reaper.GetMediaItemInfo_Value(items[indexTable[track]+1], "D_POSITION") < earliestTime then
          earliestTime = reaper.GetMediaItemInfo_Value(items[indexTable[track]+1], "D_POSITION")
          endTime = reaper.GetMediaItemInfo_Value(items[indexTable[track]+1], 'D_LENGTH') + earliestTime
        end
      end
    end
    return earliestTime, endTime
  end
  
  --function to check overlap per track
  local function overlapOnTrack (itemsOnTrack, startIndex)
    local startTime = reaper.GetMediaItemInfo_Value(itemsOnTrack[startIndex], "D_POSITION")
    local endTime = reaper.GetMediaItemInfo_Value(itemsOnTrack[startIndex], 'D_LENGTH') + startTime
    for i = startIndex+1, #itemsOnTrack do
      if itemsOnTrack[i] then 
        if reaper.GetMediaItemInfo_Value(itemsOnTrack[i], "D_POSITION") + includeCloserThan < endTime then
         endTime = reaper.GetMediaItemInfo_Value(itemsOnTrack[i], "D_POSITION") + reaper.GetMediaItemInfo_Value(itemsOnTrack[i], 'D_LENGTH')
        else
          return i-1, endTime
        end
      else
        return i-1, endTime
      end
    end
    return #itemsOnTrack, endTime
  end
  
  
  -- Process items for each track; Overlapping items across tracks
  local itemIndexPerTrack = joshnt.createTableWithSameKeys(itemByTrackTable, 0) -- bei x aufgehört zu checken
  local prevGroupItemIndexPerTrack = joshnt.createTableWithSameKeys(itemByTrackTable, 0) -- vorheriger Index, damit klar ist, wo starten
  local checkedForOverlap = joshnt.createTableWithSameKeys(itemByTrackTable, false) -- bool table if track got already checked for overlap with group
  
  local itemGroupStart = 0
  local itemGroupEnd = 0
  
  for i = 0, numItems do
    -- reset nach Durchlauf
    joshnt.copyTableValues(itemIndexPerTrack, prevGroupItemIndexPerTrack)
    itemGroupStart, itemGroupEnd = findEarliestItemAcrossTracks(itemByTrackTable, itemIndexPerTrack)
    joshnt.setTableValues(checkedForOverlap, false)
    local verified = false    
    local whileBreaking = 0 --DEBUG to catch while loop; reset each time

    while joshnt.allValuesEqualTo(checkedForOverlap, true) == false and verified == false do
      if joshnt.allValuesEqualTo(checkedForOverlap, true) == true then
        verified = true
      end
      
      -- detect overlaps across Tracks to find Group
      for track, items in pairs(itemByTrackTable) do
        if (itemIndexPerTrack[track] < #items) and (checkedForOverlap[track] == false) then
          itemIndexPerTrack[track] = itemIndexPerTrack[track] + 1
          local itemPosition = reaper.GetMediaItemInfo_Value(items[itemIndexPerTrack[track]], "D_POSITION")
          local itemEnd = reaper.GetMediaItemInfo_Value(items[itemIndexPerTrack[track]], 'D_LENGTH') + itemPosition

          if (itemPosition < itemGroupEnd + includeCloserThan and itemEnd > itemGroupStart - includeCloserThan) then 
            itemGroupStart = math.min(itemGroupStart,itemPosition)
            local indexTemp, overlapEnd = overlapOnTrack(items,itemIndexPerTrack[track])
            itemGroupEnd = math.max(itemGroupEnd,overlapEnd)
            itemIndexPerTrack[track] = indexTemp
            joshnt.setTableValues(checkedForOverlap, false)
            verified = false
        
          else
            checkedForOverlap[track] = true
            itemIndexPerTrack[track] = itemIndexPerTrack[track] - 1
          end
        else
          checkedForOverlap[track] = true
        end
      end
    
    
      --DEBUG
      whileBreaking = whileBreaking + 1
      if whileBreaking >= 10000 then
          reaper.MB("Over 10000 items were detected as one group. As this may crash the script, it was cancelled while running. Consider undoing", "CAUTION", 0) --DEBUG
          joshnt.Error("Over 10000 items were detected as one group. As this may crash the script, it was cancelled while running using this lua-error.")
      end
    end
    
    -- calculate movement per Group/ Item and saving to table (without actual moving)
    local currentGroup = {}
    
    for track, items in pairs(itemByTrackTable) do
      if itemIndexPerTrack[track] > 0 and itemIndexPerTrack[track] ~= prevGroupItemIndexPerTrack[track] then
        for j = prevGroupItemIndexPerTrack[track]+1, itemIndexPerTrack[track] do
          table.insert(currentGroup, items[j])
        end
      end
    end
    table.insert(itemGroups, currentGroup)
    table.insert(itemGroupsStartsArray, itemGroupStart)
    table.insert(itemGroupsEndArray, itemGroupEnd)
    
    if allItemsChecked(itemIndexPerTrack) then 
      break -- break, wenn alle items überprüft wurden
    end
  end

  return itemGroups, itemGroupsStartsArray, itemGroupsEndArray
end

-- Function to get the first point before and after selected items with no item in project (obey regions, as pasting there would stretch them weirdly)
-- obey Regions bool: if other items in region, recalulated from start/ end of region; startOffset/ endOffset = start and end silence for reaglue;
function joshnt.getOverlapPointsFromSelection(obeyRegionsBool, startOffset, endOffset)
  if reaper.CountSelectedMediaItems(0) == 0 then return nil end
  local inputSelection = joshnt.saveItemSelection()
  local currentOriginalStart_TEMP, currentOriginalEnd_TEMP = joshnt.startAndEndOfSelectedItems()
  if startOffset then currentOriginalStart_TEMP = currentOriginalStart_TEMP + startOffset end
  if endOffset then currentOriginalEnd_TEMP = currentOriginalEnd_TEMP + endOffset end
  reaper.GetSet_LoopTimeRange(true, false, currentOriginalStart_TEMP, currentOriginalEnd_TEMP, false)
  reaper.Main_OnCommand(40717,0) -- select all items in teimeselection
  joshnt.unselectItems(inputSelection)
  
  -- find overlap of non-selected items with selected items
  if (reaper.CountSelectedMediaItems(0) == 0) then 
    if obeyRegionsBool then
      local table, _, _, totalStart, totalEnd = joshnt.getAllOverlappingRegion(currentOriginalStart_TEMP,currentOriginalEnd_TEMP) 
      if table == {} or totalEnd == 0 then
        joshnt.reselectItems(inputSelection)
        return nil
      else
        r.GetSet_LoopTimeRange(true, false, totalStart, totalEnd, false)
        reaper.Main_OnCommand(40717,0) -- select all items in teimeselection
        joshnt.unselectItems(inputSelection)
        if (reaper.CountSelectedMediaItems(0) == 0) then
          joshnt.reselectItems(inputSelection)
          return nil
        end
      end
    else
      joshnt.reselectItems(inputSelection)
      return nil
    end
  end
  
  -- find overlap of non-selected items with other non-selected items which don't overlap selected items (point of inserting time)
  local foundAllOverlaps = false 
  local prevOtherItemStart, prevOtherItemEnd = 0,0
  local otherItemsStartWithOverlaps = currentOriginalStart_TEMP
  local otherItemsEndWithOverlaps = currentOriginalEnd_TEMP
  local whileBreakDebug = 0
  local cantReach = false
  while foundAllOverlaps == false do
    r.GetSet_LoopTimeRange(true, false, otherItemsStartWithOverlaps, otherItemsEndWithOverlaps, false)
    reaper.Main_OnCommand(40717,0) -- select all items in teimeselection
    local otherItemsStartTemp, otherItemsEndTemp = joshnt.startAndEndOfSelectedItems()

    -- if non-selected items in region, go to end of region
    if obeyRegionsBool then
      local _, _, _, rgnStart, rgnEnd = joshnt.getAllOverlappingRegion(otherItemsStartTemp,otherItemsEndTemp)
      if rgnStart < otherItemsStartTemp or rgnEnd > otherItemsEndTemp then
        otherItemsStartTemp = math.min(otherItemsStartTemp, rgnStart)
        otherItemsEndTemp = math.max(otherItemsEndTemp,rgnEnd)
        r.GetSet_LoopTimeRange(true, false, otherItemsStartTemp, otherItemsEndTemp, false)
        reaper.Main_OnCommand(40717,0) -- select all items in teimeselection
        otherItemsStartTemp, otherItemsEndTemp = joshnt.startAndEndOfSelectedItems()
      end
    end
    if (otherItemsStartWithOverlaps == otherItemsStartTemp and otherItemsEndWithOverlaps == otherItemsEndTemp) or cantReach then
      foundAllOverlaps = true
    elseif prevOtherItemStart == otherItemsStartTemp and prevOtherItemEnd == otherItemsEndTemp then
      cantReach = true
    else
      otherItemsStartWithOverlaps = math.min(otherItemsStartWithOverlaps, otherItemsStartTemp)
      otherItemsEndWithOverlaps = math.max(otherItemsEndWithOverlaps,otherItemsEndTemp)
      prevOtherItemStart = otherItemsStartTemp
      prevOtherItemEnd = otherItemsEndTemp
      cantReach = false
    end
    
    if whileBreakDebug == 10000 then
      reaper.ShowMessageBox("Unable to move Selection (extreme Number of overlapping later Items)", "Error", 0)
      break
    end
    
    whileBreakDebug = whileBreakDebug + 1
  end

  reaper.SelectAllMediaItems(0, false)
  joshnt.reselectItems(inputSelection)
  reaper.UpdateArrange()

  return otherItemsStartWithOverlaps, otherItemsEndWithOverlaps
end

-- move other items to the end of selected items
-- inputs: minSilence refer to selected items and how much you want to keep from the envelope before and after it (value in seconds); otherItemOffsets refer to non-selected items amount before and after (values in seconds)
-- retval indicating success, -1 = no items selected/ unable to perform moving, 0 = no movement necessary, 1 = moved successfully
function joshnt.isolate_MoveOtherItems_ToEndOfSelectedItems(minSilenceAtStart, minSilenceAtEnd, otherItemOffsetStart, otherItemOffsetEnd)
  local numItems = r.CountSelectedMediaItems(0)
  if numItems == 0 then return -1 end
  minSilenceAtStart = math.abs(minSilenceAtStart) * -1
  minSilenceAtEnd = math.max(0,minSilenceAtEnd)
  otherItemOffsetStart = math.abs(otherItemOffsetStart) * -1
  otherItemOffsetEnd = math.max(0,otherItemOffsetEnd)

  local boolNeedActivateEnvelopeOption = reaper.GetToggleCommandState(40070) == 0
  local originalRippleEditState = joshnt.getRippleEditingMode()
  if boolNeedActivateEnvelopeOption then
    reaper.Main_OnCommand(40070, 0)
  end
  local originalSelStart, originalSelEnd = joshnt.startAndEndOfSelectedItems()
  local originalSelection = joshnt.saveItemSelection()

  r.PreventUIRefresh(1) 


  reaper.Main_OnCommand(40309, 0) -- Ripple editing off
  -- get items
  local overlappingItemsStart, overlappingItemsEnd = joshnt.getOverlapPointsFromSelection(true, minSilenceAtStart,minSilenceAtEnd)
  if not overlappingItemsStart then r.PreventUIRefresh(-1) return 0 end -- if no overlap with other item or region, end here
  r.GetSet_LoopTimeRange(true, false, overlappingItemsStart, overlappingItemsEnd, false)
  reaper.Main_OnCommand(40717,0) -- select all items in teimeselection
  joshnt.unselectItems(originalSelection)
  local otherItems = joshnt.saveItemSelection()

  -- get locked items
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


  r.GetSet_LoopTimeRange(true, false, overlappingItemsStart+otherItemOffsetStart, overlappingItemsEnd+otherItemOffsetEnd, false)
  local pasteSelectionLength = overlappingItemsEnd+otherItemOffsetEnd - (overlappingItemsStart+otherItemOffsetStart)
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
  r.GetSet_LoopTimeRange(true, false, overlappingItemsStart+otherItemOffsetStart, overlappingItemsEnd+otherItemOffsetEnd, false)
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

  local startOtherPasted, endPastedOther = joshnt.startAndEndOfSelectedItems()
  if startOtherPasted > (originalSelEnd + minSilenceAtEnd - otherItemOffsetStart) then
    joshnt.removeTimeOnAllTracks(originalSelEnd + minSilenceAtEnd, startOtherPasted + otherItemOffsetStart)
  end


  -- Cleanup/ restore previous settings
  reaper.SelectAllMediaItems(0, false)
  joshnt.reselectItems(originalSelection)
  joshnt.setRippleEditingMode(originalRippleEditState)
  if boolNeedActivateEnvelopeOption then
    reaper.Main_OnCommand(40070, 0)
  end
  r.PreventUIRefresh(-1)
  reaper.UpdateArrange()

  return 1
end

-- move selected items to the end of overlapping other items - USE RETURNED ITEM-TABLE AS LINKS GET LOST BY CUT AND PASTE
-- inputs: minSilence refer to selected items and how much you want to keep from the envelope before and after it (value in seconds); otherItemOffsets refer to non-selected items amount before and after (values in seconds)
-- retval indicating success, -1 = no items selected/ unable to perform moving, 0 = no movement necessary, 1 = moved successfully; ret2 itemtable
function joshnt.isolate_MoveSelectedItems_InsertAtNextSilentPointInProject(minSilenceAtStart, minSilenceAtEnd, otherItemOffsetEnd)
  local numItems = r.CountSelectedMediaItems(0)
  if numItems == 0 then return -1 end
  minSilenceAtStart = math.abs(minSilenceAtStart) * -1
  minSilenceAtEnd = math.max(0,minSilenceAtEnd)
  otherItemOffsetEnd = math.max(0,otherItemOffsetEnd)
  local boolNeedActivateEnvelopeOption = reaper.GetToggleCommandState(40070) == 0
  local originalRippleEditState = joshnt.getRippleEditingMode()
  if boolNeedActivateEnvelopeOption then
    reaper.Main_OnCommand(40070, 0)
  end
  local originalSelection = joshnt.saveItemSelection()
  joshnt.selectOnlyTracksOfSelectedItems()
  local trackIDs = {}
  local parentTracksWithEnvelopes_GLOBAL = {}

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
  
  reaper.Main_OnCommand(40309, 0) -- Ripple editing off
  -- get items

  local originalSelStart, originalSelEnd = joshnt.startAndEndOfSelectedItems()
  r.PreventUIRefresh(1) 
  local overlappingItemsStart, overlappingItemsEnd = joshnt.getOverlapPointsFromSelection(true, minSilenceAtStart,minSilenceAtEnd)
  if not overlappingItemsStart then 
    r.PreventUIRefresh(-1) 
    return 0 
  end -- if no overlap with other item or region, end here
  
  -- copy parent envelopes with empty items
  r.GetSet_LoopTimeRange(true, false, originalSelStart+minSilenceAtStart, originalSelEnd+minSilenceAtEnd, false)
  reaper.Main_OnCommand(40309, 0) -- Ripple editing off
  reaper.SelectAllMediaItems(0, false)

  -- create empty items
  if #parentTracksWithEnvelopes_GLOBAL > 0 then
    local insertedEmptyItems = {}
    joshnt.unselectAllTracks()
    for index, parentTracks in ipairs(parentTracksWithEnvelopes_GLOBAL) do
      reaper.SetOnlyTrackSelected(parentTracks)
      reaper.SetEditCurPos(originalSelStart+minSilenceAtStart, true, true)
      reaper.SelectAllMediaItems(0, false)
      reaper.UpdateArrange() 
      reaper.Main_OnCommand(40142, 0) -- insert empty item
      table.insert(insertedEmptyItems, reaper.GetSelectedMediaItem(0,0))
    end
    joshnt.reselectItems(insertedEmptyItems)

    -- cut empty items
    r.GetSet_LoopTimeRange(true, false, originalSelStart+minSilenceAtStart, originalSelEnd+minSilenceAtEnd, false)
    local pasteSelectionLength = originalSelStart+minSilenceAtStart - (originalSelEnd+minSilenceAtEnd)
    reaper.UpdateArrange()
    reaper.Main_OnCommand(40307, 0) -- cut area of items

    -- paste empty items
    joshnt.unselectAllTracks()
    if #parentTracksWithEnvelopes_GLOBAL > 0 then 
      reaper.SetOnlyTrackSelected(parentTracksWithEnvelopes_GLOBAL[1])
    else 
      reaper.SetOnlyTrackSelected(trackIDs[1])
    end
    reaper.Main_OnCommand(40311, 0) -- Ripple editing all tracks 
    reaper.SetEditCurPos(overlappingItemsEnd + otherItemOffsetEnd, true, true)
    reaper.Main_OnCommand(42398, 0) -- paste

    -- remove inserted empty items
    r.GetSet_LoopTimeRange(true, false, overlappingItemsEnd + otherItemOffsetEnd, overlappingItemsEnd + otherItemOffsetEnd + pasteSelectionLength, false)
    reaper.SelectAllMediaItems(0, false)
    reaper.UpdateArrange()
    reaper.Main_OnCommand(40717 ,0) -- select items in time selection
    reaper.Main_OnCommand(40309, 0) -- Ripple editing off
    reaper.Main_OnCommand(40006,0) -- delete selected Items

  end

  joshnt.reselectItems(originalSelection)
  r.GetSet_LoopTimeRange(true, false, originalSelStart+minSilenceAtStart, originalSelEnd+minSilenceAtEnd, false)
  joshnt.unselectAllTracks()
  joshnt.selectOnlyTracksOfSelectedItems()
  local selPasteTrack = reaper.GetSelectedTrack(0, 0)
  reaper.UpdateArrange()
  reaper.Main_OnCommand(40307, 0) -- cut area of items


  reaper.SetOnlyTrackSelected(selPasteTrack)
  reaper.SetEditCurPos(overlappingItemsEnd + otherItemOffsetEnd, true, true)
  if #parentTracksWithEnvelopes_GLOBAL == 0 then 
    reaper.Main_OnCommand(40311, 0) -- Ripple editing all tracks 
  end
  reaper.Main_OnCommand(42398, 0) -- paste 
  local tempPastedItems = joshnt.saveItemSelection()

  reaper.Main_OnCommand(40309, 0) -- Ripple editing off
  joshnt.setRippleEditingMode(originalRippleEditState)
  if boolNeedActivateEnvelopeOption then
    reaper.Main_OnCommand(40070, 0)
  end
  r.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  return 1, tempPastedItems
end

-- move selected items to end of project - USE RETURNED ITEM-TABLE AS LINKS GET LOST BY CUT AND PASTE
-- inputs: minSilence refer to selected items and how much you want to keep from the envelope before and after it (value in seconds)
-- retval indicating success: -1 = no items selected/ unable to perform moving, 0 = no movement necessary, 1 = moved successfully; ret2 itemtable
function joshnt.isolate_MoveSelectedItems_InsertToInput(minSilenceAtStart, minSilenceAtEnd, pasteTimeInput, boolRipplePaste, boolJustCopy, boolCopyEvenWithoutOverlaps)
  local numItems = r.CountSelectedMediaItems(0)
  if numItems == 0 then return -1 end
  minSilenceAtStart = math.abs(minSilenceAtStart) * -1
  minSilenceAtEnd = math.max(0,minSilenceAtEnd)
  local boolNeedActivateEnvelopeOption = reaper.GetToggleCommandState(40070) == 0
  local originalRippleEditState = joshnt.getRippleEditingMode()
  if boolNeedActivateEnvelopeOption then
    reaper.Main_OnCommand(40070, 0)
  end
  local originalSelection = joshnt.saveItemSelection()
  joshnt.selectOnlyTracksOfSelectedItems()
  local trackIDs = {}
  local parentTracksWithEnvelopes_GLOBAL = {}

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
  
  reaper.Main_OnCommand(40309, 0) -- Ripple editing off
  -- get items

  local originalSelStart, originalSelEnd = joshnt.startAndEndOfSelectedItems()
  r.PreventUIRefresh(1) 

  -- check if any overlapping items
  reaper.GetSet_LoopTimeRange(true, false, originalSelStart, originalSelEnd, false)
  reaper.Main_OnCommand(40717,0) -- select all items in teimeselection
  joshnt.unselectItems(originalSelection)
  if (reaper.CountSelectedMediaItems(0) == 0) and boolCopyEvenWithoutOverlaps ~= true then r.PreventUIRefresh(-1) return 0 end
  
  -- copy parent envelopes with empty items
  r.GetSet_LoopTimeRange(true, false, originalSelStart+minSilenceAtStart, originalSelEnd+minSilenceAtEnd, false)
  reaper.Main_OnCommand(40309, 0) -- Ripple editing off
  reaper.SelectAllMediaItems(0, false)

  -- create empty items
  if #parentTracksWithEnvelopes_GLOBAL > 0 then
    local insertedEmptyItems = {}
    joshnt.unselectAllTracks()
    for index, parentTracks in ipairs(parentTracksWithEnvelopes_GLOBAL) do
      reaper.SetOnlyTrackSelected(parentTracks)
      reaper.SetEditCurPos(originalSelStart+minSilenceAtStart, true, true)
      reaper.SelectAllMediaItems(0, false)
      reaper.UpdateArrange() 
      reaper.Main_OnCommand(40142, 0) -- insert empty item
      table.insert(insertedEmptyItems, reaper.GetSelectedMediaItem(0,0))
    end
    joshnt.reselectItems(insertedEmptyItems)

    -- cut empty items
    r.GetSet_LoopTimeRange(true, false, originalSelStart+minSilenceAtStart, originalSelEnd+minSilenceAtEnd, false)
    local pasteSelectionLength = originalSelStart+minSilenceAtStart - (originalSelEnd+minSilenceAtEnd)
    reaper.UpdateArrange()
    reaper.Main_OnCommand(40307, 0) -- cut area of items

    -- paste empty items
    joshnt.unselectAllTracks()
    if #parentTracksWithEnvelopes_GLOBAL > 0 then 
      reaper.SetOnlyTrackSelected(parentTracksWithEnvelopes_GLOBAL[1])
    else 
      reaper.SetOnlyTrackSelected(trackIDs[1])
    end
    if boolRipplePaste then reaper.Main_OnCommand(40311, 0) end -- Ripple editing all tracks 
    reaper.SetEditCurPos(pasteTimeInput, true, true)
    reaper.Main_OnCommand(42398, 0) -- paste

    -- remove inserted empty items
    r.GetSet_LoopTimeRange(true, false, pasteTimeInput, pasteTimeInput + pasteSelectionLength, false)
    reaper.SelectAllMediaItems(0, false)
    reaper.UpdateArrange()
    reaper.Main_OnCommand(40717 ,0) -- select items in time selection
    reaper.Main_OnCommand(40309, 0) -- Ripple editing off
    reaper.Main_OnCommand(40006,0) -- delete selected Items

  end

  joshnt.reselectItems(originalSelection)
  r.GetSet_LoopTimeRange(true, false, originalSelStart+minSilenceAtStart, originalSelEnd+minSilenceAtEnd, false)
  joshnt.unselectAllTracks()
  joshnt.selectOnlyTracksOfSelectedItems()
  local selPasteTrack = reaper.GetSelectedTrack(0, 0)
  reaper.UpdateArrange()
  if boolJustCopy then
    reaper.Main_OnCommand(40060, 0) -- copy area of items 
  else
    reaper.Main_OnCommand(40307, 0) -- cut area of items
  end


  reaper.SetOnlyTrackSelected(selPasteTrack)
  reaper.SetEditCurPos(pasteTimeInput, true, true)
  if #parentTracksWithEnvelopes_GLOBAL == 0 and boolRipplePaste then 
    reaper.Main_OnCommand(40311, 0) -- Ripple editing all tracks 
  end
  reaper.Main_OnCommand(42398, 0) -- paste 

  reaper.Main_OnCommand(40309, 0) -- Ripple editing off
  joshnt.setRippleEditingMode(originalRippleEditState)
  if boolNeedActivateEnvelopeOption then
    reaper.Main_OnCommand(40070, 0)
  end
  r.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  return 1, joshnt.saveItemSelection()
end


----------------
----- TIME -----
----------------
function joshnt.insertTimeOnSelectedTracks(startTimeInsert, endTimeInsert)
  if endTimeInsert-startTimeInsert > 0.0000001 then
    local num_selected_tracks_TEMP = reaper.CountSelectedTracks(0)
    if num_selected_tracks_TEMP > 0 then
      local itemSelectionTemp = joshnt.saveItemSelection()
      reaper.SelectAllMediaItems(0, false)
      r.GetSet_LoopTimeRange(true, false, startTimeInsert, endTimeInsert, false)
      reaper.Main_OnCommand(40310, 0) -- Ripple editing per-track
      local trackTableTemp = {}
      local track_TEMP = nil

      -- get tracks
      for i = 0, num_selected_tracks_TEMP - 1 do
        track_TEMP = reaper.GetSelectedTrack(0, i) -- Get each selected track
        if track_TEMP then
          trackTableTemp[#trackTableTemp + 1] = track_TEMP
        end
      end
      joshnt.unselectAllTracks()

      -- insert item
      for i = 1, #trackTableTemp do
        reaper.SetOnlyTrackSelected(trackTableTemp[i])
        reaper.Main_OnCommand(40142, 0) -- insert empty item
      end
      -- remove inserted items
      reaper.Main_OnCommand(40309, 0) -- Ripple editing off
      reaper.SelectAllMediaItems(0, false)
      for i = 1, #trackTableTemp do
        reaper.SetTrackSelected(trackTableTemp[i], true)
      end
      reaper.Main_OnCommand(40718 ,0) -- select items on selected tracks in time selection
      for i = num_selected_tracks_TEMP, 0, -1 do
        local insertedItem = reaper.GetSelectedMediaItem(0, i)
        if insertedItem then
          local trackInsertedItem = reaper.GetMediaItemTrack(insertedItem)
          reaper.DeleteTrackMediaItem(trackInsertedItem, insertedItem)
        end
      end

      -- restore beginning
      joshnt.reselectItems(itemSelectionTemp)
    end
  end
end

function joshnt.removeTimeOnSelectedTracks(startTimeInsert, endTimeInsert)
  if endTimeInsert-startTimeInsert > 0.0000001 then
    local num_selected_tracks_TEMP = reaper.CountSelectedTracks(0)
    if num_selected_tracks_TEMP > 0 then
      local itemSelectionTemp = joshnt.saveItemSelection()
      reaper.SelectAllMediaItems(0, false)
      r.GetSet_LoopTimeRange(true, false, startTimeInsert, endTimeInsert, false)
      reaper.Main_OnCommand(40309, 0) -- Ripple editing off
      local trackTableTemp = {}
      local track_TEMP = nil

      -- get tracks
      for i = 0, num_selected_tracks_TEMP - 1 do
        track_TEMP = reaper.GetSelectedTrack(0, i) -- Get each selected track
        if track_TEMP then
          trackTableTemp[#trackTableTemp + 1] = track_TEMP
        end
      end
      joshnt.unselectAllTracks()

      -- insert item
      for i = 1, #trackTableTemp do
        reaper.SetOnlyTrackSelected(trackTableTemp[i])
        reaper.Main_OnCommand(40142, 0) -- insert empty item
      end
      -- remove inserted items
      reaper.Main_OnCommand(40310, 0) -- Ripple editing per-track
      reaper.SelectAllMediaItems(0, false)
      for i = 1, #trackTableTemp do
        reaper.SetTrackSelected(trackTableTemp[i], true)
      end
      reaper.Main_OnCommand(40718 ,0) -- select items on selected tracks in time selection
      reaper.Main_OnCommand(40006,0) -- delete selected items (via command to make use of ripple edit)

      -- restore beginning
      reaper.Main_OnCommand(40309, 0) -- Ripple editing off
      joshnt.reselectItems(itemSelectionTemp)
    end
  end
end

function joshnt.insertTimeOnAllTracks(startTimeInsert, endTimeInsert)
  if endTimeInsert-startTimeInsert > 0.0000001 then
      local itemSelectionTemp = joshnt.saveItemSelection()
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
      joshnt.reselectItems(itemSelectionTemp)
    end
end

function joshnt.removeTimeOnAllTracks(startTimeInsert, endTimeInsert)
  if endTimeInsert-startTimeInsert > 0.0000001 then
      local itemSelectionTemp = joshnt.saveItemSelection()
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
      joshnt.reselectItems(itemSelectionTemp)
    end
end

------------------
----- TRACKS -----
------------------

-- Function to unselect all tracks
function joshnt.unselectAllTracks()
  if reaper.CountTracks(0) == 0 then return end
  local first_track = reaper.GetTrack(0, 0)
  reaper.SetOnlyTrackSelected(first_track)
  reaper.SetTrackSelected(first_track, false)
end

-- save selected tracks in a table to recall later (see reselectTracks)
function joshnt.saveTrackSelection()
  local trackTable = {}
  local numSelTracks_TEMP = reaper.CountSelectedTracks()
  for i = 0, numSelTracks_TEMP - 1 do
    local SelTrack_TEMP = reaper.GetSelectedTrack(0, i)
    if SelTrack_TEMP then
      table.insert(trackTable,SelTrack_TEMP)
    end
  end
  return trackTable
end

-- reselect a table of tracks
function joshnt.reselectTracks(trackTable)
  local numSelTracks_TEMP = #trackTable
  for i = 0, numSelTracks_TEMP do
    local SelTrack_TEMP = trackTable[i]
    if SelTrack_TEMP then
      if reaper.ValidatePtr(SelTrack_TEMP, "MediaTrack*") then
        reaper.SetTrackSelected(SelTrack_TEMP, true)
      end
    end
  end
end

-- returns tracks of all selected items as array
function joshnt.getTracksOfSelectedItems()
  local numItems = reaper.CountSelectedMediaItems()
  local returnTracks = {}
  local lookUpTracksAsKeys = {}

  for i = 0, numItems-1 do
    local itemTemp = reaper.GetSelectedMediaItem(0,i)
    local itemTrack = reaper.GetMediaItemTrack(itemTemp)
    if not joshnt.tableContainsKey(lookUpTracksAsKeys, itemTrack) then
      returnTracks[#returnTracks+1] = itemTrack
      lookUpTracksAsKeys[itemTrack] = true
    end
  end

  return returnTracks
end

-- Function to check if a track is in the list
function joshnt.isTrackInList(track, trackList)
  for _, t in ipairs(trackList) do
    if t == track then
      return true
    end
  end
  return false
end


-- Function to get all parent tracks for an array with track IDs
function joshnt.getParentTracksWithoutDuplicates(tracks)
  -- Function to get all parent tracks recursively
  local function getParentTracks(track, selectedTracks)
    local parentTracks = {}

    local function addParentTracks(tracksTEMP)
      local newParents = {}
      for _, tr in ipairs(tracksTEMP) do
        local parent = reaper.GetParentTrack(tr)
        if parent and not parentTracks[parent] and not joshnt.isTrackInList(parent, selectedTracks) then
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

-- similar to get ParentTracks but includes top level tracks (= not inside a folder) from input list
function joshnt.getOnlyTopLevelTracksAndParents(tracks)
  -- Function to get the highest level parent tracks for a given track
  local function getTopLevelParentTrack(track)
    local parent = reaper.GetParentTrack(track)
    if parent then
      return getTopLevelParentTrack(parent) -- Recursively find the highest parent
    else
      return track -- If no parent, the track is top-level itself
    end
  end

  local allParentTracks = {}
  for _, track in ipairs(tracks) do
    local topLevelParent = getTopLevelParentTrack(track)
    allParentTracks[topLevelParent] = true -- Use a table to remove duplicates
  end

  local result = {}
  for parent, _ in pairs(allParentTracks) do
    table.insert(result, parent)
  end

  return result
end




-- boolean to check if selected items are on child tracks of given track
function joshnt.isAnyParentOfAllSelectedItems(inputTrack)
  local numItems = reaper.CountSelectedMediaItems()
  if numItems == 0 then return false end
  local checkedTracks = {}

  for i = 0, numItems - 1 do
    local itemTemp = reaper.GetSelectedMediaItem(0,i)
    local itemTrack = reaper.GetMediaItemTrack(itemTemp)
    if not joshnt.tableContainsKey(checkedTracks, itemTrack) then
      if itemTrack ~= inputTrack then
        local parentTrack = reaper.GetParentTrack(itemTrack)
        while parentTrack do
          if parentTrack == inputTrack then
            break
          else
            parentTrack = reaper.GetParentTrack(parentTrack)
          end
        end
        if parentTrack == nil then
          return false
        end
      end
      checkedTracks[itemTrack] = true
    end
  end

  return true
end

-- selects only the tracks of the selected items; copied from X-Raym
function joshnt.selectOnlyTracksOfSelectedItems()
  joshnt.unselectAllTracks()
  local selected_items_count = reaper.CountSelectedMediaItems(0)
  for i = 0, selected_items_count - 1  do
    local item = reaper.GetSelectedMediaItem(0, i)
    local track = reaper.GetMediaItem_Track(item)
    reaper.SetTrackSelected(track, true)
  end 
end

-- returns table with all soloed tracks
function joshnt.getSoloedTracks()
  local num_tracks = reaper.CountTracks(0) -- Get the number of tracks in the project
  local soloTrackTable = {}
    
  for i = 0, num_tracks - 1 do
      local track = reaper.GetTrack(0, i) -- Get each track
      
      -- Check if the track is soloed
      local solo = reaper.GetMediaTrackInfo_Value(track, "I_SOLO")
      if solo >= 1 then
          table.insert(soloTrackTable, track)
      end
  end
  
  return soloTrackTable
end

-- returns table with all muted tracks
function joshnt.getMutedTracks()
  local num_tracks = reaper.CountTracks(0) -- Get the number of tracks in the project
  local muteTrackTable = {}
    
  for i = 0, num_tracks - 1 do
      local track = reaper.GetTrack(0, i) -- Get each track
      
      -- Check if the track is muted
      local mute = reaper.GetMediaTrackInfo_Value(track, "B_MUTE")
      if mute == 1 then
          table.insert(muteTrackTable, track)
      end
  end
  
  return muteTrackTable
end

---------------------------
----- MARKER/ REGIONS -----
---------------------------

-- Function to check for overlapping regions with given time, returns bool
function joshnt.checkOverlapWithRegions(startTimeInput, endTimeInput)

  local proj = r.EnumProjects(-1, "")
  local numRegions = r.CountProjectMarkers(proj, 0)
  if numRegions == 0 then
      return false
  end

  local overlapDetected = false

  for j = 0, numRegions - 1 do
      local _, isrgn, rgnstart, rgnend = r.EnumProjectMarkers( j)
      if isrgn then
          if startTimeInput < rgnend and endTimeInput > rgnstart then
              overlapDetected = true
              break
          end
      end
  end

  return overlapDetected
end

-- Function to get start, end and name of a specific region given by index
function joshnt.getRegionBoundsByIndex(inputRegionIndex)
  local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
  local num_total = num_markers + num_regions
  if num_regions == 0 then
      return nil
  end

  for j = 0, num_total - 1 do
      local _, isrgn, rgnstart, rgnend, name, markerIndex = r.EnumProjectMarkers( j)
      if isrgn and markerIndex == inputRegionIndex then
        return rgnstart, rgnend, name
      end
  end
  return nil
end

-- Function to get marker position of a specific marker given by index
function joshnt.getMarkerPosByIndex(inputMarkerIndex)
  local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
  local num_total = num_markers + num_regions
  if num_markers == 0 then
      return nil
  end

  for j = 0, num_total - 1 do
      local _, isrgn, markerPos, _, _, markerIndex = r.EnumProjectMarkers( j)
      if not isrgn and markerIndex == inputMarkerIndex then
        return markerPos
      end
  end
  return nil
end

-- Function to get all overlapping region, returns region number, reg start and end (as arrays) + the first overlapping regions start and the last overlapping regions end
function joshnt.getAllOverlappingRegion(startTimeInput, endTimeInput)
  local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
  local num_total = num_markers + num_regions
  local targetRegion = {}
  local reg_Start = {}
  local reg_End = {}
  local reg_Start_total = math.huge
  local reg_End_total = 0
  for j=0, num_total - 1 do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers( j )
    if isrgn then
      if pos < endTimeInput and rgnend > startTimeInput then -- check for overlap
        targetRegion[#targetRegion+1] = markrgnindexnumber
        reg_Start[#reg_Start+1] = pos
        reg_End[#reg_End+1] = rgnend
        reg_Start_total = math.min(reg_Start_total,pos)
        reg_End_total = math.max(reg_End_total, rgnend)
      end
    end
  end
  return targetRegion, reg_Start, reg_End, reg_Start_total, reg_End_total
end

-- Function to get most overlapping region, returns region number, reg start and end
function joshnt.getMostOverlappingRegion(startTimeInput, endTimeInput)
  local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
  local num_total = num_markers + num_regions
  local targetRegion = nil
  local reg_Start = 0
  local reg_End = 0
  local name = ""
  local overlapAmount = math.huge
  for j=0, num_total - 1 do
    local retval, isrgn, pos, rgnend, nameTEMP, markrgnindexnumber = reaper.EnumProjectMarkers( j )
    local overlapRegion_TEMP = nil
    if isrgn then
      if pos < endTimeInput and rgnend > startTimeInput then -- check for overlap
        if pos >= startTimeInput and rgnend <= endTimeInput then -- if region completely overlaps with items
          overlapRegion_TEMP = rgnend - pos
        else
          if pos < startTimeInput then -- if overlap is at beginning of items
            overlapRegion_TEMP = rgnend - startTimeInput
          else
            overlapRegion_TEMP = endTimeInput - rgnend
          end
        end
        if overlapAmount > overlapRegion_TEMP then
          overlapAmount = overlapRegion_TEMP
          targetRegion = markrgnindexnumber
          reg_Start = pos
          reg_End = rgnend
          name = nameTEMP
        end
      end
    end
  end
  return targetRegion, reg_Start, reg_End, name
end

-- Function to get current, returns region number, reg start and end
function joshnt.getRegionAtPosition(startTimeInput)
  local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
  local num_total = num_markers + num_regions
  for j=0, num_total - 1 do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers( j )
    if isrgn then
        if (pos <= startTimeInput and rgnend > startTimeInput) then -- if given input is in region
          return markrgnindexnumber, pos, rgnend
        end
    end
  end
  return nil
end

-- Function to get current or next region, returns region number, reg start and end
function joshnt.getRegionAtPositionOrNext(startTimeInput)
  local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
  local num_total = num_markers + num_regions
  for j=0, num_total - 1 do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers( j )
    if isrgn then
        if pos >= startTimeInput or (pos < startTimeInput and rgnend > startTimeInput) then -- if given input is before start of region or in region
          return markrgnindexnumber, pos, rgnend
        end
    end
  end
  return nil
end

-- Count Regions in a specific timeframe; returns array of region indices
function joshnt.getRegionsInTimeFrame(startTimeInput, endTimeInput)
  local numRegions = r.CountProjectMarkers(0, 0)
  if numRegions == 0 then
    return {}
  end

  local regionsInTime = {}

  for j = 0, numRegions - 1 do
    local _, isrgn, rgnstart, rgnend, _, rgnIndex = r.EnumProjectMarkers( j)
    if isrgn then
        if startTimeInput < rgnend and endTimeInput > rgnstart then
          table.insert(regionsInTime,rgnIndex)
        end
    end
  end

  return regionsInTime
end

-- get selected Region in Region/ Marker Manager - adapted from edgemeal: Select next region in region manager window.lua
-- function returns two tables for regions and markers
function joshnt.getSelectedMarkerAndRegionIndex()
  
  if not joshnt.checkJS_API() then return end

  local rgn_list, item_count = joshnt.getRegionManagerListAndItemCount()
  if not rgn_list then return end
  local regionOrderInManager, markerOrderInManager = joshnt.GetRegionsAndMarkerInManagerOrder(rgn_list, item_count)

  if item_count == 0 then return end

  local indexSelRgn = {}
  local indexSelMrk = {}

  for posInRgnMgn, markerNum in pairs(regionOrderInManager) do
    local sel = reaper.JS_ListView_GetItemState(rgn_list, posInRgnMgn)
    if sel > 1 then
      indexSelRgn[#indexSelRgn+1] = markerNum
    end
  end

  for posInRgnMgn, markerNum in pairs(markerOrderInManager) do
    local sel = reaper.JS_ListView_GetItemState(rgn_list, posInRgnMgn)
    if sel > 1 then
      indexSelMrk[#indexSelMrk+1] = markerNum
    end
  end


  if #indexSelRgn == 0 then indexSelRgn = nil end
  if #indexSelMrk == 0 then indexSelMrk = nil end
  -- Return table of selected regions
  return indexSelRgn, indexSelMrk
end

-- set Region selected in Region/ Marker Manager by index - adapted from edgemeal: Select next region in region manager window.lua
function joshnt.setRegionSelectedByIndex(RegionIndexTable, boolUnselectOthers)
  
  if not RegionIndexTable or not joshnt.checkJS_API() then return end
  if type(RegionIndexTable) == "number" then
    RegionIndexTable = {RegionIndexTable}
  elseif type(RegionIndexTable) ~= "table" then return end

  local lv, cnt = joshnt.getRegionManagerListAndItemCount()
  if not lv then return end
  local regionOrderInManager, _ = joshnt.GetRegionsAndMarkerInManagerOrder(lv, cnt)

  if boolUnselectOthers == true then  
    reaper.JS_ListView_SetItemState(lv, -1, 0x0, 0x2)         -- unselect all items
  end

  for i = 1, #RegionIndexTable do
    local regionPositionInManager = -1
    -- find position of region in manager list
    for posInRgnMgn, markerNum in pairs(regionOrderInManager) do
      if markerNum == RegionIndexTable[i] then
        regionPositionInManager = posInRgnMgn
        break
      end
    end

    if regionPositionInManager >= 0 then
      reaper.JS_ListView_SetItemState(lv, regionPositionInManager, 0xF, 0x3) -- select item @ index
      reaper.JS_ListView_EnsureVisible(lv, regionPositionInManager, false) -- OPTIONAL: scroll item into view
    end
  end
end

function joshnt.getRegionManagerListAndItemCount()
  -- Open region/marker manager window if not found,
  local title = reaper.JS_Localize('Region/Marker Manager', 'common')
  local manager = reaper.JS_Window_Find(title, true)
  if not manager then
    reaper.Main_OnCommand(40326, 0) -- View: Show region/marker manager window
    manager = reaper.JS_Window_Find(title, true)
  end
  if manager then
    reaper.DockWindowActivate(manager)      -- OPTIONAL: Select/show manager if docked
    local lv = reaper.JS_Window_FindChildByID(manager, 1071)
    local item_cnt = reaper.JS_ListView_GetItemCount(lv)
    return lv, item_cnt;

  else reaper.MB("Unable to get Region/Marker Manager!","Error",0) return end
end

function joshnt.GetRegionsAndMarkerInManagerOrder(lv, cnt)
  local regions = {} -- table with position in list as key and region index as value
  local marker = {} -- table with position in list as key and marker index as value
  for i = 0, cnt-1 do
    local rgnMrkString_TEMP = reaper.JS_ListView_GetItemText(lv, i, 1)
    if rgnMrkString_TEMP:match("R%d") then
      local RGN_Index = string.gsub(rgnMrkString_TEMP, "R","")
      regions[i]= tonumber(RGN_Index)
    elseif rgnMrkString_TEMP:match("M%d") then
      local MRK_Index = string.gsub(rgnMrkString_TEMP, "M","")
      marker[i]= tonumber(MRK_Index)
    end
  end
  return regions, marker
end

-----------------
----- TABLE -----
-----------------
function joshnt.createTableWithSameKeys(originalTable, initValue)
  local newTable = {}
  for key, _ in pairs(originalTable) do
      newTable[key] = initValue
  end
  return newTable
end

-- Function to set all values of a table to an input value
function joshnt.setTableValues(table, value)
  for k, _ in pairs(table) do
      table[k] = value
  end
end

-- Copy table values
function joshnt.copyTableValues(tableFrom, tableTo)
  for k, v in pairs(tableFrom) do
    tableTo[k] = v
  end
end

-- check if table is all equal to a value
function joshnt.allValuesEqualTo(table, value)
  for _, v in pairs(table) do
      if v ~= value then
          return false
      end
  end
  return true
end

-- Check if a table contains a key // returns Boolean
function joshnt.tableContainsKey(table, key)
  return table[key] ~= nil
end

-- Check if a table contains a value in any one of its keyvalues// returns Boolean
function joshnt.tableContainsVal(table, val)
  for index, value in ipairs(table) do
    value = tostring(value)
    val = tostring(val)
    if value:find(val) then
      return true
    end
  end
  return false
end

----------------
----- USER -----
----------------
-- Bool check if a file exists
function joshnt.fileExists(filePath)
  local file = io.open(filePath, "r")
  if file then
    file:close()
    return true
  else
    return false
  end
end

-- Convert from CSV string to table (converts a single line of a CSV file) - for reading user input
function joshnt.fromCSV(s)
  s = s .. ','        -- add ending comma
  local q = {}        -- table to collect fields
  local fieldstart = 1
  repeat
    -- next field is quoted? (start with `"'?)
    if string.find(s, '^"', fieldstart) then
      local a, i, c
      i  = fieldstart
      repeat
          -- find closing quote
          a, i, c = string.find(s, '"("?)', i+1)
      until c ~= '"'    -- quote not followed by quote?
      if not i then error('unmatched "') end
      local f = string.sub(s, fieldstart+1, i-1)
      table.insert(q, (string.gsub(f, '""', '"')))
      fieldstart = string.find(s, ',', i) + 1
    else                -- unquoted; find next comma
      local nexti = string.find(s, ',', fieldstart)
      table.insert(q, string.sub(s, fieldstart, nexti-1))
      fieldstart = nexti + 1
    end
  until fieldstart > string.len(s)
  return q
end

-- write CSV file from input array - array can have subarrays as keyvalues but not further stacked subarrays
-- FileHeader needs to be comma seperated, e.g. keys of subarrays
function joshnt.toCSV(arrayToPrint, FileNameString, FileHeaderCommaSeperatedString)
  if type(arrayToPrint) ~= "table" or type(FileNameString) ~= "string" then reaper.ShowConsoleMsg("\nUnmatching filetype for CSV-File creation") return end
  -- Get the path of the currently opened project
  local retval, projectPath = reaper.EnumProjects(-1, "")

  if projectPath ~= "" then
    projectPath = projectPath:match("^(.*)[\\/]")
  else
    local ret = reaper.MB("No project open or project path not available to print CSV.\n\nChoose other save location?", "CSV Print Error",1)
    if ret == 2 then return end
    retval, projectPath = reaper.JS_Dialog_BrowseForFolder("Choose a dir for the CSV", "")
    if retval ~= 1 then return end
  end

  local filePath = projectPath.."/"..FileNameString..".csv"
  -- Attempt to open file for writing  
  local exists = joshnt.fileExists(filePath)
  if exists then
    local ret = reaper.MB(filePath.."\nalready exists.\n\nOverwrite existing file?\nIf 'No', increment filename until not overwriting existing files.", "CSV Print Error", 3)
    if ret == 7 then -- no
      local i = 1
      while exists do
        i = i+1
        filePath = projectPath.."/"..FileNameString..i..".csv"
        exists = joshnt.fileExists(filePath)
      end
    elseif ret == 6 then else return end
  end 

  local file, err = io.open(filePath, "w")
  if not file then
    reaper.ShowMessageBox("Failed to open CSV file for writing:\n" .. err, "Error", 0)
    return
  end

  -- check for subtables
  local boolSubtables = false
  for key, keyvalue in pairs(arrayToPrint) do
    if type(keyvalue) == "table" then boolSubtables = true end
    break
  end

  -- Write header
  file:write(FileHeaderCommaSeperatedString.."\n")

  -- Write each row of data
  if boolSubtables then
    for _, subtable in pairs(arrayToPrint) do
      local i = 1
      for _, keyvalue in pairs(subtable) do
        if i == 1 then 
          i = 2
          file:write(tostring(keyvalue))
        else
          file:write(","..tostring(keyvalue))
        end
      end
      file:write("\n")
    end
  else
    for _, keyvalue in pairs(arrayToPrint) do
      file:write(keyvalue.. "\n")
    end
  end

  -- Close the file
  file:close()

  reaper.ShowMessageBox(filePath.."\nfile created successfully.", "Success", 0)
end

-- add small pop-up which doesn't block user input (copied from X-Raym)
function joshnt.TooltipAtMouse(message)
  local x, y = reaper.GetMousePosition()
  reaper.TrackCtl_SetToolTip(tostring(message), x+17, y+17, false )
end

---------------------------
----- REAPER-specific -----
---------------------------
function joshnt.getRippleEditingMode()
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

function joshnt.setRippleEditingMode(mode)
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

function joshnt.getVolumeAsDB(reaperVolumeDouble)
  return 20 * math.log(reaperVolumeDouble, 10)
end

function joshnt.getDBAsVolume(dB)
  if dB <= -150.0 then
      return 0.0 -- REAPER represents very low dB values as 0.0 volume
  else
      return 10^(dB / 20)
  end
end
-------------------
----- STRINGS -----
-------------------
function joshnt.insertStringAtPosition(original, insert, position)
  return original:sub(1, position - 1) .. insert .. original:sub(position)
end

-- Function to find numbers until there is something different than numbers again after a specific sequence in a string and remove the sequence; returns shortened String, Found Number(s) and the index of them
-- use for Wildcard-Type user input for numbers e.g. $incr to increment from number after $incr
function joshnt.getNumbersUntilDifferent(str, sequence)
  if str ~= "" then
    -- Escape any special characters in the sequence
    sequence = sequence:gsub("([%%%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
    -- Define the pattern to match the sequence followed by numbers until non-numeric characters
    local pattern = sequence .. "(%d+)[^%d]*"
    -- Use string.match to find the first occurrence
    local number = string.match(str, pattern)
    if not number then
      return nil,nil,nil
    end
    local removeText = sequence..number.."]"
    local indexOfNumberInString;
    if string.find(str, removeText) then
      indexOfNumberInString = string.find(str, removeText)
      str = string.gsub(str, removeText, "")
    else
      return nil, nil, nil
    end
    
    return str, tonumber(number), indexOfNumberInString
  else 
    return nil, nil, nil
  end
end

-- create a string from a table (for e.g. user input)
function joshnt.tableToCSVString(tableInput)
  local function valueToString(value)
    if type(value) == "table" then
        return "{" .. joshnt.tableToCSVString(value) .. "}"
    else
        return tostring(value)
    end
  end

  local result = {}
  local maxIndex = 0

  -- Find the maximum index in the table
  for k in pairs(tableInput) do
      if type(k) == "number" and k > maxIndex then
          maxIndex = k
      end
  end

  -- Build the string with values separated by commas
  for i = 1, maxIndex do
      if tableInput[i] ~= nil then
          table.insert(result, valueToString(tableInput[i]))
      else
          table.insert(result, "")
      end
  end

  return table.concat(result, ",")
end


function joshnt.splitStringToTable(inputString)
  local function parseValue(value)
    if value:sub(1, 1) == "{" and value:sub(-1) == "}" then
        return joshnt.splitStringToTable(value:sub(2, -2))
    elseif value == "true" then
        return true
    elseif value == "false" then
        return false
    elseif tonumber(value) ~= nil then
        return tonumber(value)
    else
        return value
    end
  end

  local resultTable = {}
  local index = 1
  local pattern = "%b{}"  -- Pattern to match balanced {}

  -- Handle nested tables
  inputString = inputString:gsub(pattern, function(c)
      local placeholder = "__PLACEHOLDER" .. index .. "__"
      resultTable[placeholder] = c
      index = index + 1
      return placeholder
  end)

  -- Split the string by commas
  for value in string.gmatch(inputString, '([^,]*)') do
      if value:find("__PLACEHOLDER") then
          value = resultTable[value]
      end
      table.insert(resultTable, parseValue(value))
  end

  return resultTable
end

-----------------
----- DEBUG -----
-----------------

--DEBUG function
function joshnt.pauseForUserInput(prompt, debugBool)
  if debugBool then
    local ok, input = reaper.GetUserInputs(prompt, 1, "Press OK to continue", "")
    if not ok then
        reaper.ShowConsoleMsg("Script paused, user canceled the input.\n")
    end
  end
end

function joshnt.debugMSG(string, debugBool)
  if debugBool then
    reaper.ShowConsoleMsg(string)
  end
end

-- check if JS Extension is installed
function joshnt.checkJS_API()
  if not reaper.APIExists('JS_Localize') then
    reaper.MB("Please install the JS_ReaScriptAPI REAPER extension, available in ReaPack, under the ReaTeam Extensions repository.\n\nExtensions > ReaPack > Browse Packages\n\nFilter for 'JS_ReascriptAPI'. Right click to install.","joshnt Utility", 0)
    --error("Missing JS_ReaScriptAPI; execution of the last called joshnt script got cancelled")
    return false
  end
  return true
end

-- check for SWS extension
function joshnt.checkSWS()
  if reaper.NamedCommandLookup("_SWS_ABOUT") ~= 0 then
    return true
  else
    reaper.MB("This script requires the SWS Extension. Please install it from here:\n\nhttps://www.sws-extension.org/","Error",0)
    return false
  end
end

-- only use in rare cases - looks like massive failure from coding side
function joshnt.Error(string)
  error(string)
end

return joshnt
