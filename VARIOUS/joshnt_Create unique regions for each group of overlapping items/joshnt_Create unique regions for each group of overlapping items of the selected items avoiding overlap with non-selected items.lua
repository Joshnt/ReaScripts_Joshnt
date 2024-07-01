-- @description Unique Region per overlapping item bundle in selection - Game Audio/ SD Use
-- @version 1.1
-- @author Joshnt
-- @about 
--    ## Unique Regions - Joshnt
--    **User input explanation:**
--    - Time before item group start: Time in seconds between region start and item group start (per region) (use numbers above 0)
--    - Time after item group end: Time in seconds between item group end and region end (per region) (use numbers above 0)
--    - Space between regions: space between each item group's region and the next (use numbers above 0)
--    - Lock items: write "y" to lock the items after adjusting the position
--    - Region names: Eachs overlapping item group region name; use the wildcard [$incrX] to start numbering the regions from X and increase it per region (e.g. "Footsteps_[$incr3]" would name the first region "Footsteps_03", the next "Footsteps_04", ...)
--    - Region Color: input anything to open the REAPER's Color-Picker to color the region; leave empty to use default color
--    
--
--    **Credits** to Aaron Cendan (for acendan_Set nearest regions edges to selected media items.lua; https://aaroncendan.me), David Arnoldy, Joshua Hank, Yannick Winter
--
--    **Usecase:**  
--    creating incremental numbered regions for single layered sounds (for e.g. game audio) - mother region possibly useful for reapers region render dialog and naming via $region(=name) 
--    Script creates regions for overlapping selected items (including beginning and end silence), adjusting the space between them, moving other non selected items away

r = reaper

function userInputValues()
    local continue, s = reaper.GetUserInputs("Regions user input", 6,
        "Time before item group start:,Time after item group end:,Space between regions:,Lock items (y/n):,Region name:,Region Color ( [P] ick / default ):,extrawidth=100",
        "0,0,2000,y,[$incr1],")
    
    -- Convert from CSV string to table (converts a single line of a CSV file)
    function fromCSV(s)
        s = s .. ','        -- ending comma
        local q = {}        -- table to collect fields
        local fieldstart = 1
        repeat
            -- next field is quoted? (start with `"'?)
            if string.find(s, '^"', fieldstart) then
                local a, c
                local i  = fieldstart
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
    
    if not continue or s == "" then return false end
    local q = fromCSV(s)
    
    -- Get the values from the input
    local d1 = q[1]
    local d2 = q[2]
    local d3 = q[3]
    local lock1 = q[4]
    local regionName = q[5]
    local chooseColorButton = q[6]
    
    -- Convert the values to globals
    space_in_between = tonumber(d3) * 0.001 -- in seconds
    start_silence = tonumber(d1) * 0.001 -- in seconds
    end_silence = tonumber(d2) * 0.001 -- in seconds
    if space_in_between < 0 or start_silence < 0 or end_silence < 0 then
        reaper.ShowMessageBox("Please only use positive numbers for the space in between and the start and end silence.", "Error", 0)
        return false
    end
    lockBoolUser = lock1 == "y"
    boolNeedActivateEnvelopeOption = reaper.GetToggleCommandState(40070) == 0
    regionColor = 0 -- is default
    
    -- Handle the Choose Color button
    if chooseColorButton ~= "" then
        local retval, color = reaper.GR_SelectColor(nil) -- Open the color picker dialog
        if retval ~= 0 then
          local r,g,b = reaper.ColorFromNative(color)
          regionColor = (r + 256 * g + 65536 * b)|16777216
        end
    end
    
    -- Store the region names globally
    regionName_GLOBAL = regionName
    regionNameLeftOver_GLOBAL = nil
    regionNameNumber_GLOBAL = nil
    regionNameNumberIndex_GLOBAL = nil
    local leftText, number, indexOfNumber = getNumbersUntilDifferent(regionName, "[$incr")
    if number then
        regionNameLeftOver_GLOBAL = leftText
        regionNameNumber_GLOBAL = number
        regionNameNumberIndex_GLOBAL = indexOfNumber
    end
    
    return true
end


-- Function to find numbers until there is something different than numbers again after a specific sequence in a string and remove the sequence
function getNumbersUntilDifferent(str, sequence)
    -- Escape any special characters in the sequence
    sequence = sequence:gsub("([%%%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
    -- Define the pattern to match the sequence followed by numbers until non-numeric characters
    local pattern = sequence .. "(%d+)[^%d]*"
    -- Use string.match to find the first occurrence
    local number = string.match(str, pattern)
    local removeText = sequence..number.."]"
    local indexOfNumberInString = 0
    if string.find(str, removeText) then
      indexOfNumberInString = string.find(str, removeText)
      str = string.gsub(str, removeText, "")
    else
      return nil
    end
    
    return str, tonumber(number), indexOfNumberInString
end

function insertStringAtPosition(original, insert, position)
    return original:sub(1, position - 1) .. insert .. original:sub(position)
end

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


-- Function to check for overlapping regions with given time
local function checkOverlapWithRegions(startTimeInput, endTimeInput, boolReturnRegionBounds)

    local proj = r.EnumProjects(-1, "")
    local numRegions = r.CountProjectMarkers(proj, 0)
    if numRegions == 0 then
        if boolReturnRegionBounds then
          return -1, -1
        else  
          return false
        end
    end

    local overlapDetected = false
    local regionStart = -1
    local regionEnd = -1

    for j = 0, numRegions - 1 do
        local _, isrgn, rgnstart, rgnend = r.EnumProjectMarkers( j)
        if isrgn then
            if startTimeInput < rgnend and endTimeInput > rgnstart then
                overlapDetected = true
                regionStart = rgnstart
                regionEnd = rgnend
                break
            end
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
  if (reaper.CountSelectedMediaItems(0) == 0) and (checkOverlapWithRegions(currentOriginalStart_TEMP,currentOriginalEnd_TEMP,false) == false) then 
    return
  else
    otherItemsStart, otherItemsEnd = startAndEndOfSelectedItems()
    if otherItemsStart == 0 and otherItemsEnd == 0 then
      return
    end
  end
  
  -- find overlap of non-selected items with other non-selected items which don't overlap selected items (point of inserting time)
  local foundAllOverlaps = false 
  local otherItemsEndWithOverlaps = otherItemsEnd
  local whileBreakDebug = 0
  local regionEnd_TEMP = -1
  while foundAllOverlaps == false do
    local newLoopBound_TEMP = math.max(currentOriginalEnd_TEMP,otherItemsEnd)
    r.GetSet_LoopTimeRange(true, false, currentOriginalStart_TEMP, newLoopBound_TEMP, false)
    reaper.Main_OnCommand(40717,0) -- select all items in teimeselection
    selectOriginalSelection(false)
    local _, otherItemsEndTemp = startAndEndOfSelectedItems()
    -- if non-selected items in region, go to end of region
    local regionStart_TEMP2, regionEnd_TEMP2 = checkOverlapWithRegions(regionEnd_TEMP,newLoopBound_TEMP,true)
    if regionEnd_TEMP2 > regionEnd_TEMP then
      local itemSel_TEMP = saveItemSelection()
      r.GetSet_LoopTimeRange(true, false, regionStart_TEMP2, regionEnd_TEMP2, false)
      reaper.Main_OnCommand(40717,0) -- select all items in teimeselection
      selectOriginalSelection(false)
      if reaper.CountSelectedMediaItems() > 0 then
        otherItemsEndTemp = math.max(otherItemsEndTemp, regionEnd_TEMP2)
      end
      reselectItems(itemSel_TEMP)
    end
    if otherItemsEnd == otherItemsEndTemp then
      foundAllOverlaps = true
    else
      otherItemsEnd = otherItemsEndTemp
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
        r.GetSet_LoopTimeRange(true, false, currentOriginalStart_TEMP-start_silence-1, currentOriginalEnd_TEMP+end_silence, false)
        reaper.SetEditCurPos(currentOriginalStart_TEMP-start_silence-1, true, true)
        reaper.UpdateArrange() 
        reaper.Main_OnCommand(40142, 0) -- insert empty item
        table.insert(insertedEmptyItems, reaper.GetSelectedMediaItem(0,0))
      end
      reselectItems(insertedEmptyItems)
    end
    
    selectOriginalSelection(true)
    r.GetSet_LoopTimeRange(true, false, currentOriginalStart_TEMP-start_silence-1, currentOriginalEnd_TEMP+end_silence, false)
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
      removeTimeOnAllTracks(endTimeSel_TEMP + end_silence, endTimeSel_TEMP + end_silence + (currentOriginalEnd_TEMP - otherItemsEnd))
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

-- Function to adjust item positions 
function getItemGroups()
    if numItems == 1 then return end
    
    d = space_in_between + start_silence + end_silence -- Time between items in Seconds
    
    local function createTableWithSameKeys(originalTable, initValue)
        local newTable = {}
        for key, _ in pairs(originalTable) do
            newTable[key] = initValue -- You can set any initial value here if needed
        end
        return newTable
    end
    
    -- Function to set all values of a table to an input value
    local function setTableValues(table, value)
        for k, _ in pairs(table) do
            table[k] = value
        end
    end
    
    -- Copy table values
    local function copyTableValues(tableFrom, tableTo)
      for k, v in pairs(tableFrom) do
        tableTo[k] = v
      end
    end
    
    -- check if table is all equal to a value
    local function allValuesEqualTo(table, value)
        for _, v in pairs(table) do
            if v ~= value then
                return false
            end
        end
        return true
    end
    
    -- check if all items got checked
    local function allItemsChecked(t, itemIndexPerTrack)
        for tracks, items in pairs(t) do
            if #items > itemIndexPerTrack[tracks] then
                return false
            end
        end
        return true
    end
  
    
   -- find earliest Item
   local function findEarliestItemAcrossTracks(table, indexTable)
      local earliestTime = math.huge
      local endTime = nil
      for track, items in pairs(table) do
        if #items > indexTable[track] then
          if r.GetMediaItemInfo_Value(items[indexTable[track]+1][1], "D_POSITION") < earliestTime then
            earliestTime = r.GetMediaItemInfo_Value(items[indexTable[track]+1][1], "D_POSITION")
            endTime = r.GetMediaItemInfo_Value(items[indexTable[track]+1][1], 'D_LENGTH') + earliestTime
          end
        end
      end
      return earliestTime, endTime
    end
    
    --function to check overlap per track
    local function overlapOnTrack (itemsOnTrack, startIndex)
      local startTime = r.GetMediaItemInfo_Value(itemsOnTrack[startIndex][1], "D_POSITION")
      local endTime = itemsOnTrack[startIndex][2] + startTime
      for i = startIndex+1, #itemsOnTrack do
        if itemsOnTrack[i][1] then 
          if r.GetMediaItemInfo_Value(itemsOnTrack[i][1], "D_POSITION") < endTime then
           endTime = r.GetMediaItemInfo_Value(itemsOnTrack[i][1], "D_POSITION") + itemsOnTrack[i][2]
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
    local itemIndexPerTrack = createTableWithSameKeys(t, 0) -- bei x aufgehört zu checken
    local prevGroupItemIndexPerTrack = createTableWithSameKeys(t, 0) -- vorheriger Index, damit klar ist, wo starten
    local checkedForOverlap = createTableWithSameKeys(t, false) -- bool table if track got already checked for overlap with group
    local verified = false
    
    local itemGroupStart = 0
    local itemGroupEnd = 0
    
    for i = 0, numItems do
      -- reset nach Durchlauf
      copyTableValues(itemIndexPerTrack, prevGroupItemIndexPerTrack)
      itemGroupStart, itemGroupEnd = findEarliestItemAcrossTracks(t, itemIndexPerTrack)
      setTableValues(checkedForOverlap, false)
      verified = false
      
      
      local whileBreaking = 0 --DEBUG to catch while loop; reset each time
      while allValuesEqualTo(checkedForOverlap, true) == false and verified == false do
        if allValuesEqualTo(checkedForOverlap, true) == true then
          verified = true
        end
        
        -- detect overlaps across Tracks to find Group
        for track, items in pairs(t) do
          if (itemIndexPerTrack[track] < #items) and (checkedForOverlap[track] == false) then
            itemIndexPerTrack[track] = itemIndexPerTrack[track] + 1
            local itemPosition = r.GetMediaItemInfo_Value(items[itemIndexPerTrack[track]][1], "D_POSITION")
            local itemEnd = items[itemIndexPerTrack[track]][2] + itemPosition
            if (itemPosition < itemGroupStart and itemEnd > itemGroupStart) or (itemEnd > itemGroupEnd and itemPosition < itemGroupEnd) or (itemPosition >= itemGroupStart and itemEnd <= itemGroupEnd) then 
              itemGroupStart = math.min(itemGroupStart,itemPosition)
              local indexTemp, overlapEnd = overlapOnTrack(items,itemIndexPerTrack[track])
              itemGroupEnd = math.max(itemGroupEnd,overlapEnd)
              itemIndexPerTrack[track] = indexTemp
              setTableValues(checkedForOverlap, false)
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
        if whileBreaking >= 1000 then
            reaper.MB("Over 1000 items were detected as one group. As this may crash the script, it was cancelled while running. As to unknown behaviour, undoing is strongly recommended.", "CAUTION", 0) --DEBUG
          break
        end
      end
      
      -- calculate movement per Group/ Item and saving to table (without actual moving)
      local currentGroup = {}
      local currentGroupNudgeValue = 0
      
      for track, items in pairs(t) do
        if itemIndexPerTrack[track] > 0 and itemIndexPerTrack[track] ~= prevGroupItemIndexPerTrack[track] then
          for i = prevGroupItemIndexPerTrack[track]+1, itemIndexPerTrack[track] do
            if itemGroupsEndArray[#itemGroupsEndArray] then
              currentGroupNudgeValue = d - (itemGroupStart - itemGroupsEndArray[#itemGroupsEndArray])
            else 
              currentGroupNudgeValue = 0
            end
            table.insert(currentGroup, items[i][1])
          end
        end
      end
      table.insert(itemGroups, currentGroup)
      table.insert(nudgeValues, currentGroupNudgeValue)
      table.insert(itemGroupsStartsArray, itemGroupStart)
      table.insert(itemGroupsEndArray, itemGroupEnd)
      
      if allItemsChecked(t, itemIndexPerTrack) then 
        break -- break, wenn alle items überprüft wurden
      end
    end
end
    
    
function adjustItemPositions()   
    -- move Groups, starting from last Group (and last item in Group)
      -- Deselect all items
      reaper.SelectAllMediaItems(0, false)
      
      for j = #itemGroups-1, 1, -1 do
        local reverse = nudgeValues[j+1] < 0  -- Determine if we need to move backward
        local absNudge = math.abs(nudgeValues[j+1])  -- Get the absolute value of seconds
        local centerBetweenGroups
        if reverse == true then
          local possibleInsertRange_TEMP = (itemGroupsStartsArray[j+1] - itemGroupsEndArray[j]) - absNudge
          centerBetweenGroups = itemGroupsEndArray[j] + (possibleInsertRange_TEMP * 0.5) -- entfernen von zeit dass gleicher abstand bei beiden items bleibt
        else
          centerBetweenGroups = itemGroupsEndArray[j] + ((itemGroupsStartsArray[j+1] - itemGroupsEndArray[j]) * 0.5) -- Einfügen von zeit genau zwischen items
        end
        local endOfInsertedTime_TEMP = centerBetweenGroups + absNudge
        
        reaper.SetEditCurPos(centerBetweenGroups, true, true)
        if reverse == true then
          removeTimeOnAllTracks(centerBetweenGroups, endOfInsertedTime_TEMP)
        else
          insertTimeOnAllTracks(centerBetweenGroups,endOfInsertedTime_TEMP)
        end
        reaper.UpdateArrange()
      end 
    
    -- restore selection
      -- Deselect all items
      reaper.SelectAllMediaItems(0, false)
      -- Reselect Items
      selectOriginalSelection(true) 
end


-- Function to create a region over selected items
function createRegionOverItems()
    local startTime, endTime = startAndEndOfSelectedItems()
    -- Extend the region by 100ms at the beginning and 50ms at the end
    startTime = startTime - start_silence
    endTime = endTime + end_silence
    
    if startTime < 0 then
      r.GetSet_LoopTimeRange(true, false, startTime + start_silence, startTime + start_silence + math.abs(startTime), false)
      reaper.Main_OnCommand(40200, 0)
      endTime = endTime - startTime
      startTime = 0
    end
    -- Create the region
    reaper.AddProjectMarker2(0, true, startTime, endTime, regionName_GLOBAL, -1, regionColor)
end


function setRegionLength()
  reaper.Undo_BeginBlock()
  local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
  local num_total = num_markers + num_regions
  local start_time = math.huge
  local end_time = 0
  
  if num_regions > 0 then
    
    local num_sel_items = reaper.CountSelectedMediaItems(0)
    if num_sel_items > 0 then
      -- Get avg center of media items & set start/end points
      local item_center_avg = 0
      for i=0, num_sel_items - 1 do
        -- Get item position info
        local item = reaper.GetSelectedMediaItem( 0, i )
        local item_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
        local item_length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
        local item_end = item_start + item_length
        local item_center = item_start + (item_length * 0.5)
        
        -- Running average sum
        item_center_avg = item_center_avg + item_center
        
        -- Get region bounds
        start_time = math.min(start_time,item_start)
        end_time = math.max(end_time,item_end)
      end
      -- Divide running avg sum by num items to get true center
      item_center_avg = item_center_avg / num_sel_items
      
    
      -- Check to see if there is an overlapping region(s). IF NOT GET NEAREST
      local regions_to_move = {}
      local num_regions_to_move = 0
      for j=0, num_total - 1 do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers( j )
        if isrgn then
          if pos <= item_center_avg and rgnend >= item_center_avg then
            regions_to_move[markrgnindexnumber] = name
            num_regions_to_move = num_regions_to_move + 1
          end
        end
      end
      
      start_time = start_time - start_silence
      end_time = end_time + end_silence
      
      if start_time < 0 then
        r.GetSet_LoopTimeRange(true, false, 0, math.abs(start_time), false)
        reaper.Main_OnCommand(40200, 0)
        end_time = end_time + math.abs(start_time)
        start_time = 0
        selectOriginalSelection(true)
      end
      
      -- Move overlapping regions if > 0
      if num_regions_to_move > 0 then
        for rgn_num, rgn_name in pairs(regions_to_move) do
          if regionColor ~= 0 then
            reaper.SetProjectMarker3(0, rgn_num, 1, start_time, end_time, regionName_GLOBAL, regionColor) 
          else
            reaper.SetProjectMarker( rgn_num, 1, start_time, end_time, regionName_GLOBAL )
          end
        end
      else
        -- Get nearest region
        local min_distance = math.huge
        local rgn_num = -1
        local rgn_name = ""
        
        for j=0, num_total - 1 do
          local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers( j )
          if isrgn then
            -- If start of region is after the center point...
            if pos > item_center_avg then
              if (pos - item_center_avg) < min_distance then 
                min_distance = pos - item_center_avg
                rgn_num = markrgnindexnumber
                rgn_name = name
              end
            -- If end of region is before the center point...
            elseif rgnend < item_center_avg then
              if (item_center_avg - rgnend) < min_distance then 
                min_distance = item_center_avg - rgnend
                rgn_num = markrgnindexnumber
                rgn_name = name
              end
            end
          end
        end
        
        -- Move nearest region
        if rgn_num >= 0 then 
          if regionColor ~= 0 then
            reaper.SetProjectMarker3(0, rgn_num, 1, start_time, end_time, regionName_GLOBAL, regionColor) 
          else
            reaper.SetProjectMarker( rgn_num, 1, start_time, end_time, regionName_GLOBAL )
          end
        end
      end
    else
      reaper.MB("No items selected!","Set Nearest Region", 0)
    end
  else
    reaper.MB("Your project doesn't have any regions!","Set Nearest Region", 0)
  end
  reaper.Undo_EndBlock("Set Nearest Region", -1)
end

function setRegionsForItemGroups()
  for i = 1, #itemGroups do
    reaper.SelectAllMediaItems(0, false)
    reselectItems(itemGroups[i])
    
    if regionNameNumber_GLOBAL then
      local regionNameNumber_TEMP = regionNameNumber_GLOBAL
      if regionNameNumber_TEMP < 10 then
        regionNameNumber_TEMP = "0"..regionNameNumber_TEMP
      end
      regionName_GLOBAL = insertStringAtPosition(regionNameLeftOver_GLOBAL, regionNameNumber_TEMP, regionNameNumberIndex_GLOBAL)
    end
    
    local currSelStart_TEMP, currSelEnd_TEMP = startAndEndOfSelectedItems()
    if checkOverlapWithRegions(currSelStart_TEMP, currSelEnd_TEMP, false) then setRegionLength()
      else createRegionOverItems()
    end
    
    if regionNameNumber_GLOBAL then
      regionNameNumber_GLOBAL = regionNameNumber_GLOBAL + 1
    end
  end
end


-- Function to lock selected items
function lockSelectedItems()
    reaper.Undo_BeginBlock()
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
    reaper.Undo_EndBlock("Lock selected items", -1)
end

-- Main function
function main()
    numItems = r.CountSelectedMediaItems(0)
    if numItems == 0 then 
      r.ShowMessageBox("No items selected!", "Error", 0)
      return 
    end
    if userInputValues() then
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
      
      -- global variables for grouping of items; used in getItemGroups()
      itemSelectionStartTime, itemSelectionEndTime = startAndEndOfSelectedItems()
      itemGroups = {}
      nudgeValues = {}
      itemGroupsStartsArray = {}
      itemGroupsEndArray = {}
      
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
      getItemGroups()
      adjustItemPositions()
      lockItemsState(lockedItems_Global,1)
      setRippleEditingMode(originalRippleEditState)
      if boolNeedActivateEnvelopeOption then
        reaper.Main_OnCommand(40070, 0)
      end
      reaper.Undo_EndBlock("Move Items", -1)
      
      reaper.Undo_BeginBlock()  
      if lockBoolUser == true then
        lockSelectedItems()
      end
      setRegionsForItemGroups()
      reaper.Undo_EndBlock("Create Regions", -1)
    end
    r.PreventUIRefresh(-1)
    reaper.UpdateArrange()
end


-- Run the main function
main()


