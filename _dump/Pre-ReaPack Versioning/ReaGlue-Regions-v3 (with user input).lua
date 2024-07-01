-- @description ReaGlue adaption to Regions
-- @version 3.0
-- @author Joshnt
-- Credits to Aaron Cendan https://aaroncendan.me, David Arnoldy, Joshua Hank

--
-- Usecase: 
-- multiple Multi-Track Recordings or Sounddesigns across multiple tracks which needs to be exported to a single variation file.
-- Script creates region across those selected items (including beginning and end silence), adjusting the space between them, moving other non selected items away

r = reaper

function userInputValues()
  local continue, s = reaper.GetUserInputs("Moments of Silence", 6,
          "Start silence:,Space in between:,End silence:,Lock items (y/n):,Move envelopes with items(y/n):,Isolate items (n/y):,extrawidth=100", 
          "100,1000,50,y,as set,y")
     
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
    q = fromCSV(s)
    
    -- Get the values from the input
    d1 = q[1]
    d2 = q[2]
    d3 = q[3]
    lock1 = q[4]
    moveEnvelopes1 = q[5]
    isolateItems = q[6]
  
    -- Convert the values
    space_in_between = tonumber(d2) * 0.001 -- in seconds
    start_silence = tonumber(d1) * 0.001 -- in seconds
    end_silence = tonumber(d3) * 0.001 -- in seconds
    lockBoolUser = lock1 == "y"
    if moveEnvelopes1 == "y" or moveEnvelopes1 == "n" then 
      moveEnvelopes = moveEnvelopes1 == "y"
    else
      moveEnvelopes = reaper.GetToggleCommandState(40070) == 1 
    end
    boolNeedActivateEnvelopeOption = reaper.GetToggleCommandState(40070) == 0
    
    isolateItems = isolateItems == "y"
    return true
end


   -- unselect all automation items
   function unselectAllAutomationItems ()
    -- Iterate over all tracks
        local numTracks = reaper.CountTracks(0)
        for t = 0, numTracks - 1 do
            local track = reaper.GetTrack(0, t)
            
            -- Iterate over all envelopes in the track
            local numEnvelopes = reaper.CountTrackEnvelopes(track)
            for e = 0, numEnvelopes - 1 do
                local envelope = reaper.GetTrackEnvelope(track, e)
                
                -- Iterate through all automation items in the envelope
                local numAutoItems = reaper.CountAutomationItems(envelope)
                for i = 0, numAutoItems - 1 do
                    reaper.GetSetAutomationItemInfo(envelope, i, "D_UISEL", 0, true)
                end
            end
        end
    end


function initReaGlue()
  t = {}  -- Table to store items grouped by track
  itemSelectionStartTime = math.huge
  itemSelectionEndTime = 0
  
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
          local it_start = reaper.GetMediaItemInfo_Value(itemGlobal, "D_POSITION")
          local it_end = it_start + it_len
          itemSelectionStartTime = math.min(itemSelectionStartTime, it_start)
          itemSelectionEndTime = math.max(itemSelectionEndTime, it_end)
          addItemToTable(itemGlobal, it_len)
      end
  end
end

-- Items freistellen/ move selection away from non-selected items
local function moveAwayFromOtherItems()
  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  r.GetSet_LoopTimeRange(true, false, itemSelectionStartTime, itemSelectionEndTime, false)
  reaper.Main_OnCommand(40717,0)
  for track, items in pairs(t) do
    for index, _ in ipairs(items) do
      reaper.SetMediaItemSelected(items[index][1], false)
    end
  end
  
  local itemsInTimeSelection = r.CountSelectedMediaItems(0)
  local otherItemsStart = 0
  local otherItemsEnd = 0
  for i = 0, itemsInTimeSelection - 1 do
      local itemTempTime = r.GetSelectedMediaItem(0, i)
      if itemTempTime then
          local it_len = r.GetMediaItemInfo_Value(itemTempTime, 'D_LENGTH')
          local it_start = reaper.GetMediaItemInfo_Value(itemTempTime, "D_POSITION")
          local it_end = it_start + it_len
          if i == 0 then
            otherItemsStart = it_start
            otherItemsEnd = it_end
          else
            otherItemsStart = math.min(otherItemsStart, it_start)
            otherItemsEnd = math.max(otherItemsEnd, it_end)
          end
      end
  end
  
  if otherItemsStart > 0 or otherItemsEnd > 0 then
    local compensateTime = otherItemsEnd-itemSelectionStartTime + 1 + start_silence
    r.GetSet_LoopTimeRange(true, false, itemSelectionStartTime, itemSelectionStartTime + compensateTime, false)
    reaper.Main_OnCommand(40200, 0)
        
    -- move envelopes with items toggle an
    if moveEnvelopes and boolNeedActivateEnvelopeOption then
      reaper.Main_OnCommand(40070, 0)
    end
        
    reaper.ApplyNudge(0, 0, 0, 1, compensateTime, true, 0)
        
    -- move envelopes with items toggle wie davor
    if moveEnvelopes and boolNeedActivateEnvelopeOption then
      reaper.Main_OnCommand(40070, 0)
    end
  end
  
  --restore selection
    -- Deselect all items
    reaper.SelectAllMediaItems(0, false)
    -- Reselect Items
    for track, items in pairs(t) do
      for index, _ in ipairs(items) do
        reaper.SetMediaItemSelected(items[index][1], true)
      end
    end
    
  r.PreventUIRefresh(-1)
  r.Undo_EndBlock('Move Other Items away', -1)
end


-- Function to adjust item positions 
function adjustItemPositions()
    if numItems == 1 then return end
    
    d = space_in_between -- Time between items in Seconds
    
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
  
   
   
   -- select automation items in time
   local function selectAutomationItemsInTimeOnTracks(tracks, startTime, endTime)
    for t = 1, #tracks do
      -- Iterate over all envelopes in the track
          local numEnvelopes = reaper.CountTrackEnvelopes(tracks[t])
          for e = 0, numEnvelopes - 1 do
              local envelope = reaper.GetTrackEnvelope(tracks[t], e)
              -- Iterate through all automation items in the envelope
              local numAutoItems = reaper.CountAutomationItems(envelope)
              for i = 0, numAutoItems - 1 do
                  local autoItemStart = reaper.GetSetAutomationItemInfo(envelope, i, "D_POSITION", 0, false)
                  local autoItemEnd = autoItemStart + reaper.GetSetAutomationItemInfo(envelope, i, "D_LENGTH", 0, false)
                  -- Check if the automation item is within the time selection
                  if (autoItemStart < startTime and autoItemEnd > startTime) or (autoItemStart < endTime and autoItemEnd > endTime) or (autoItemStart <= startTime and autoItemEnd >= endTime) or (autoItemStart >= startTime and autoItemEnd <= endTime)  then
                      reaper.GetSetAutomationItemInfo(envelope, i, "D_UISEL", 1, true)
                  end
              end
          end
      end
    end
    
    
    -- checking for automation item duplicates
    local function isItemInTable(tbl, track, envelope, itemIndex)
        if tbl == nil then return false end
        for _, subTable in ipairs(tbl) do
          for _, item in ipairs(subTable) do
            if item.track == track and item.envelope == envelope and item.itemIndex == itemIndex then
                return true
            end
          end
        end
        return false
    end
    
   -- function to get all selected automation items in a table
  local function getSelectedAutomationItemsWithoutDuplicates(tableForDuplicateChecking)
      local selectedItems = {}
  
      -- Iterate over all tracks
      local numTracks = reaper.CountTracks(0)
      for t = 0, numTracks - 1 do
          local track = reaper.GetTrack(0, t)
          
          -- Iterate over all envelopes in the track
          local numEnvelopes = reaper.CountTrackEnvelopes(track)
          for e = 0, numEnvelopes - 1 do
              local envelope = reaper.GetTrackEnvelope(track, e)
              
              -- Iterate through all automation items in the envelope
              local numAutoItems = reaper.CountAutomationItems(envelope)
              for i = 0, numAutoItems - 1 do
                  local isSelected = reaper.GetSetAutomationItemInfo(envelope, i, "D_UISEL", 0, false)
                  if isSelected > 0 and not isItemInTable(tableForDuplicateChecking, track, envelope, i) then
                      -- Add selected automation item to the table if not already present
                      table.insert(selectedItems, {track = track, envelope = envelope, itemIndex = i})
                  end
              end
          end
      end
  
      return selectedItems
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
    
    r.Undo_BeginBlock()
    r.PreventUIRefresh(1)
    
    -- Process items for each track; Overlapping items across tracks
    local itemIndexPerTrack = createTableWithSameKeys(t, 0) -- bei x aufgehört zu checken
    local prevGroupItemIndexPerTrack = createTableWithSameKeys(t, 0) -- vorheriger Index, damit klar ist, wo starten
    local itemGroups = {}
    local nudgeValues = {}
    local automationItemsInGroups = {}
    local checkedForOverlap = createTableWithSameKeys(t, false) -- bool table if track got already checked for overlap with group
    local verified = false
    
    local itemGroupStart = 0
    local itemGroupEnd = 0
    local moveOffset = findEarliestItemAcrossTracks(t, itemIndexPerTrack)
    
    local trackIDs = {}
    for key, _ in pairs(t) do
      table.insert(trackIDs, key)
    end
    
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
              --reaper.MB(overlapEnd, "OverlapEnd", 0) --DEBUG
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
            local itemStart = r.GetMediaItemInfo_Value(items[i][1], "D_POSITION")
            currentGroupNudgeValue = moveOffset - itemGroupStart
            table.insert(currentGroup, items[i][1])
          end
        end
      end
      
      table.insert(itemGroups, currentGroup)
      table.insert(nudgeValues, currentGroupNudgeValue)
      moveOffset = moveOffset + (itemGroupEnd - itemGroupStart) + d -- Anfangsposition für nächste Gruppe 
      
      unselectAllAutomationItems()
      if moveEnvelopes then
        selectAutomationItemsInTimeOnTracks(trackIDs, itemGroupStart, itemGroupEnd)
        automationItemsInGroups[#itemGroups] = getSelectedAutomationItemsWithoutDuplicates(automationItemsInGroups)
      end
      
      if allItemsChecked(t, itemIndexPerTrack) then 
        break -- break, wenn alle items überprüft wurden
      end
    end
    
    -- insert time to compensate
      if (nudgeValues[#nudgeValues] > 0) then
        reaper.GetSet_LoopTimeRange(true, false, itemGroupEnd, itemGroupEnd + nudgeValues[#nudgeValues], false)
        reaper.Main_OnCommand(40200, 0)
      end
    
    -- move envelopes with items toggle an
      if moveEnvelopes and boolNeedActivateEnvelopeOption then
        reaper.Main_OnCommand(40070, 0)
      end
      
    -- move Groups, starting from last Group (and last item in Group)
      -- Deselect all items
      reaper.SelectAllMediaItems(0, false)
      unselectAllAutomationItems()
      
      for j = #itemGroups, 1, -1 do
        local reverse = nudgeValues[j] < 0  -- Determine if we need to move backward
        local absNudge = math.abs(nudgeValues[j])  -- Get the absolute value of seconds
        local singleItemGroup = itemGroups[j]
        for i = #singleItemGroup, 1, -1 do -- i entspricht jedem item aus der gruppe
          reaper.SetMediaItemSelected(singleItemGroup[i], true)
        end
        if moveEnvelopes then
          for _, aitem in ipairs(automationItemsInGroups[j]) do
            -- Set the selection state of the automation item to selected
            reaper.GetSetAutomationItemInfo(aitem.envelope, aitem.itemIndex, "D_UISEL", 1, true)
          end
        end
        reaper.ApplyNudge(0, 0, 0, 1, absNudge, reverse, 0) -- nudge whole group at once
        reaper.SelectAllMediaItems(0, false)
        unselectAllAutomationItems()
      end 
      
    -- move envelopes with items toggle wie davor
      if moveEnvelopes and boolNeedActivateEnvelopeOption then
        reaper.Main_OnCommand(40070, 0)
      end
    
    -- restore selection
      -- Deselect all items
      reaper.SelectAllMediaItems(0, false)
      -- Reselect Items
      for track, items in pairs(t) do
        for index, _ in ipairs(items) do
          reaper.SetMediaItemSelected(items[index][1], true)
        end
      end
    
    
    r.PreventUIRefresh(-1)
    r.Undo_EndBlock('Set distance between items on each track', -1)
end


-- Function to check for overlapping regions with selected items
local function checkOverlapWithRegions()

    local proj = r.EnumProjects(-1, "")
    local numRegions = r.CountProjectMarkers(proj, 0)
    if numRegions == 0 then
        return false
    end

    local overlapDetected = false

    for i = 0, numItems - 1 do
        local item = r.GetSelectedMediaItem(0, i)
        local itemStart = r.GetMediaItemInfo_Value(item, "D_POSITION")
        local itemEnd = itemStart + r.GetMediaItemInfo_Value(item, "D_LENGTH")

        for j = 0, numRegions - 1 do
            local _, isrgn, rgnstart, rgnend = r.EnumProjectMarkers( j)
            if isrgn then
                if itemStart < rgnend and itemEnd > rgnstart then
                    overlapDetected = true
                    break
                end
            end
        end

        if overlapDetected then
            break
        end
    end
  return overlapDetected
end



        -- check if region bound would overlap with non-selected items on edges
        function checkOtherItemsOverlapWithNewRegionBounds(TimeSelectionStartTime, TimeSelectionEndTime)
          -- Deselect all items
          reaper.SelectAllMediaItems(0, false)
          
          r.GetSet_LoopTimeRange(true, false, TimeSelectionStartTime, TimeSelectionEndTime, false)
          reaper.Main_OnCommand(40717,0)
          for track, items in pairs(t) do
            for index, _ in ipairs(items) do
              reaper.SetMediaItemSelected(items[index][1], false)
            end
          end
          
          local itemsInTimeSelection = r.CountSelectedMediaItems(0)
          local otherItemsStart = 0
          local otherItemsEnd = 0
          local boolSameTracks = false
          for i = 0, itemsInTimeSelection - 1 do
              local itemTempTime = r.GetSelectedMediaItem(0, i)
              if itemTempTime then
                  local it_len = r.GetMediaItemInfo_Value(itemTempTime, 'D_LENGTH')
                  local it_start = reaper.GetMediaItemInfo_Value(itemTempTime, "D_POSITION")
                  local it_end = it_start + it_len
                  local trackOfItemTemp = reaper.GetMediaItem_Track(itemTempTime)
                  if boolSameTracks == false then
                    boolSameTracks = t[trackOfItemTemp] ~= nil
                  end
                  
                  if i == 0 then
                    otherItemsStart = it_start
                    otherItemsEnd = it_end
                  else
                    otherItemsStart = math.min(otherItemsStart, it_start)
                    otherItemsEnd = math.max(otherItemsEnd, it_end)
                  end
              end
          end
          
          return otherItemsStart, otherItemsEnd, boolSameTracks
        end


-- Function to create a region over selected items
function createRegionOverItems()
    reaper.Undo_BeginBlock()

    local startTime = reaper.GetProjectLength(0) -- Initial value
    local endTime = 0 -- Initial value
    local startTimeOffset = 0
    local endTimeOffset = 0

    -- Get the selected items
        for i = 0, numItems - 1 do
            local selectedItem = reaper.GetSelectedMediaItem(0, i)
            if selectedItem then
                local itemStartTime = reaper.GetMediaItemInfo_Value(selectedItem, "D_POSITION")
                local itemLength = reaper.GetMediaItemInfo_Value(selectedItem, "D_LENGTH")
                local itemEndTime = itemStartTime + itemLength

                -- Update start and end time of the region
                if itemStartTime < startTime then
                    startTime = itemStartTime
                end
                if itemEndTime > endTime then
                    endTime = itemEndTime
                end
            end
        end
        
        
        --Region start check
          local _, startOverlapEnd, boolSameTracksBeginning = checkOtherItemsOverlapWithNewRegionBounds(startTime - start_silence, startTime)
          if startOverlapEnd > 0 then
            if startOverlapEnd < startTime then
              startTimeOffset = start_silence - (startTime - startOverlapEnd) + 0.1
              r.GetSet_LoopTimeRange(true, false, startTime, startTime + startTimeOffset, false)
              reaper.Main_OnCommand(40200, 0)
            else
              if boolSameTracksBeginning then
                reaper.MB("Non-selected item(s) overlapping selection on same tracks. Consider using the 'Move other Items' option in this script.", "Error", 0)
              end
            end
          end
          
          endTime = endTime + startTimeOffset
          
          local endOverlapBegin, _, boolSameTracksEnd = checkOtherItemsOverlapWithNewRegionBounds(endTime, endTime + end_silence)
          if endOverlapBegin > 0 then
            if endOverlapBegin > endTime then
              endTimeOffset = end_silence - (endOverlapBegin - endTime) + 0.1
              r.GetSet_LoopTimeRange(true, false, endTime, endTime + endTimeOffset, false)
              reaper.Main_OnCommand(40200, 0)
            else
              if boolSameTracksEnd then
                reaper.MB("Non-selected item(s) overlapping selection on same tracks. Consider using the 'Move other Items' option in this script.", "Error", 0)
              end
            end
          end
          
        
        
        -- restore selection
          -- Deselect all items
          reaper.SelectAllMediaItems(0, false)
          -- Reselect Items
          for track, items in pairs(t) do
            for index, _ in ipairs(items) do
              reaper.SetMediaItemSelected(items[index][1], true)
            end
          end
        
        -- Extend the region by 100ms at the beginning and 50ms at the end
        startTime = startTime - start_silence + startTimeOffset
        endTime = endTime + end_silence
        
        if startTime < 0 then
          r.GetSet_LoopTimeRange(true, false, startTime + start_silence, startTime + start_silence + math.abs(startTime), false)
          reaper.Main_OnCommand(40200, 0)
          startTime = 0
        end
        
        -- Create the region
        reaper.GetSet_LoopTimeRange(true, false, startTime, endTime, false)
        reaper.SetEditCurPos(startTime, true, false)
        reaper.Main_OnCommand(40289, 0) -- Select region under mouse cursor
        reaper.Main_OnCommand(40306,0)

    reaper.Undo_EndBlock("Create region over items", -1)
end


-- Function to adjust existing region
function setRegionLength()
  reaper.Undo_BeginBlock()
  local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
  local num_total = num_markers + num_regions
  local startTime = math.huge
  local endTime = 0
  
  if num_regions > 0 then
    
    local num_sel_items = numItems
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
        startTime = math.min(startTime,item_start)
        endTime = math.max(endTime,item_end)
      end
      
        -- Check for Overlaps
        --Region start check
          local _, startOverlapEnd, boolSameTracksBeginning = checkOtherItemsOverlapWithNewRegionBounds(startTime - start_silence, startTime)
          if startOverlapEnd > 0 then
            if startOverlapEnd < startTime then
              startTimeOffset = start_silence - (startTime - startOverlapEnd) + 0.1
              r.GetSet_LoopTimeRange(true, false, startTime, startTime + startTimeOffset, false)
              reaper.Main_OnCommand(40200, 0)
            else
              if boolSameTracksBeginning then
                reaper.MB("Non-selected item(s) overlapping selection on same tracks. Consider using the 'Move other Items' option in this script.", "Error", 0)
              end
            end
          end
          
          endTime = endTime + startTimeOffset
          
          local endOverlapBegin, _, boolSameTracksEnd = checkOtherItemsOverlapWithNewRegionBounds(endTime, endTime + end_silence)
          if endOverlapBegin > 0 then
            if endOverlapBegin > endTime then
              endTimeOffset = end_silence - (endOverlapBegin - endTime) + 0.1
              r.GetSet_LoopTimeRange(true, false, endTime, endTime + endTimeOffset, false)
              reaper.Main_OnCommand(40200, 0)
            else
              if boolSameTracksEnd then
                reaper.MB("Non-selected item(s) overlapping selection on same tracks. Consider using the 'Move other Items' option in this script.", "Error", 0)
              end
            end
          end
          
        
        
        -- restore selection
          -- Deselect all items
          reaper.SelectAllMediaItems(0, false)
          -- Reselect Items
          for track, items in pairs(t) do
            for index, _ in ipairs(items) do
              reaper.SetMediaItemSelected(items[index][1], true)
            end
          end
        
        -- Extend the region by 100ms at the beginning and 50ms at the end
        startTime = startTime - start_silence + startTimeOffset
        endTime = endTime + end_silence
        
        if startTime < 0 then
          r.GetSet_LoopTimeRange(true, false, startTime + start_silence, startTime + start_silence + math.abs(startTime), false)
          reaper.Main_OnCommand(40200, 0)
          startTime = 0
        end
      
      -- Divide running avg sum by num items to get true center
      item_center_avg = item_center_avg / num_sel_items
      
      -- DEBUG CENTER POSITION
      if dbg_mode then
        reaper.SetEditCurPos(item_center_avg, true, false)
        reaper.MB(tostring(item_center_avg),"Center Position",0)
      end

      -- Check to see if there is an overlapping region(s). IF NOT GET NEAREST
      local regions_to_move = {}
      local num_regions_to_move = 0
      for j=0, num_total - 1 do
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers( j )
        if isrgn then
          if dbg_mode then reaper.ShowConsoleMsg(tostring(pos) .. "-" .. tostring(rgnend) .. "\n") end
          if pos <= item_center_avg and rgnend >= item_center_avg then
            regions_to_move[markrgnindexnumber] = name
            num_regions_to_move = num_regions_to_move + 1
          end
        end
      end
      
      -- Move overlapping regions if > 0
      if num_regions_to_move > 0 then
        for rgn_num, rgn_name in pairs(regions_to_move) do
          reaper.SetProjectMarker( rgn_num, 1, startTime, endTime, rgn_name )
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
        if rgn_num >= 0 then reaper.SetProjectMarker( rgn_num, 1, startTime, endTime, rgn_name ) end
      end
    else
      reaper.MB("No items selected!","Set Nearest Region", 0)
    end
  else
    reaper.MB("Your project doesn't have any regions!","Set Nearest Region", 0)
  end
  reaper.Undo_EndBlock("Set Nearest Region", -1)
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
      --unselectAllAutomationItems()
      initReaGlue()
      if isolateItems == true then
        moveAwayFromOtherItems()
      end
      --adjustItemPositions()
      if lockBoolUser == true then
        --lockSelectedItems()
      end
      --if checkOverlapWithRegions() then setRegionLength()
       --else createRegionOverItems()
      --end
    end
    reaper.UpdateArrange()
end


-- Run the main function
main()
