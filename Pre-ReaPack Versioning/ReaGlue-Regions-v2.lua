-- @description ReaGlue adaption to Regions
-- @version 2
-- Credits to Aaron Cendan https://aaroncendan.me, David Arnoldy, Joshua Hank

r = reaper

function userInputValues()
  local continue, s  = reaper.GetUserInputs("Moments of Silence", 4,
      "Start silence:,Space in between:,End silence:,Lock items (1 = yes):, extrawidth=100","100,1000,50,1")
     
  -- Convert from CSV string to table (converts a single line of a CSV file)
  function fromCSV(s)
    s = s .. ','        -- ending comma
    local t = {}        -- table to collect fields
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
          table.insert(t, (string.gsub(f, '""', '"')))
          fieldstart = string.find(s, ',', i) + 1
        else                -- unquoted; find next comma
          local nexti = string.find(s, ',', fieldstart)
          table.insert(t, string.sub(s, fieldstart, nexti-1))
          fieldstart = nexti + 1
      end
    until fieldstart > string.len(s)
    return t
  end
  
  if not continue or s == "" then return false end
  t = fromCSV(s)
  d1 = t[1]
  d2 = t[2]
  d3 = t[3]
  lock1 = t[4]

  space_in_between = d2 * 0.001-- in seconds
  start_silence = d1 * 0.001-- in seconds
  end_silence = d3 * 0.001-- in seconds
  lockBoolUser = lock1 == "1"
  return true
end

-- Function to adjust item positions 
function adjustItemPositions()
    if numItems == 1 then return end
    
    d = space_in_between -- Time between items in Seconds
    
    local t = {}  -- Table to store items grouped by track
    
    -- Function to add items to the table
    local function addItemToTable(item, itemLength)
        local track = r.GetMediaItem_Track(item)
        if not t[track] then
            t[track] = {}
        end
        table.insert(t[track], {item, itemLength})
    end
    
    -- Group items by track
    for i = 0, numItems - 1 do
        local item = r.GetSelectedMediaItem(0, i)
        if item then
            local it_len = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
            addItemToTable(item, it_len)
        end
    end
    
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
      --reaper.MB(earliestTime, "Function: Find earliest item - earliest Time", 0) --DEBUG
      --reaper.MB(endTime, "Function: Find earliest item - endTime", 0) --DEBUG
      return earliestTime, endTime
    end
    
    
    --function to check overlap per track
    local function overlapOnTrack (itemsOnTrack, startIndex)
      local startTime = r.GetMediaItemInfo_Value(itemsOnTrack[startIndex][1], "D_POSITION")
      local endTime = itemsOnTrack[startIndex][2] + startTime
      for i = startIndex+1, #itemsOnTrack do
      --reaper.MB(tostring(itemsOnTrack[i][1] == nil), "Existence Check", 0) --DEBUG
        if itemsOnTrack[i][1] then 
          --reaper.MB(tostring(r.GetMediaItemInfo_Value(itemsOnTrack[i][1], "D_POSITION") < endTime), "Existence Check", 0) --DEBUG
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
    local checkedForOverlap = createTableWithSameKeys(t, false) -- bool table if track got already checked for overlap with group
    local verified = false
    
    local itemGroupStart = 0
    local itemGroupEnd = 0
    local moveOffset = findEarliestItemAcrossTracks(t, itemIndexPerTrack)
    
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
            reaper.MB("Over 1000 items were detected as one group. As this may crash the script, it was cancelled while running. As to unknown behaviour, undoing is strongly recommended", "CAUTION", 0) --DEBUG
          break
        end
      end
      
      -- move Group
      for track, items in pairs(t) do
        if itemIndexPerTrack[track] > 0 and itemIndexPerTrack[track] ~= prevGroupItemIndexPerTrack[track] then
          for i = prevGroupItemIndexPerTrack[track]+1, itemIndexPerTrack[track] do
            local itemStart = r.GetMediaItemInfo_Value(items[i][1], "D_POSITION")
            local newItemPosition = itemStart - itemGroupStart + moveOffset
            r.SetMediaItemInfo_Value(items[i][1], "D_POSITION", newItemPosition)
          end
        end
      end
      
      moveOffset = moveOffset + (itemGroupEnd - itemGroupStart) + d -- Anfangsposition für nächste Gruppe 
      
      if allItemsChecked(t, itemIndexPerTrack) then 
        break -- break, wenn alle items überprüft wurden
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


-- Function to create a region over selected items
function createRegionOverItems()
    reaper.Undo_BeginBlock()

    local startTime = reaper.GetProjectLength(0) -- Initial value
    local endTime = 0 -- Initial value

    -- Get the selected items
    local numSelectedItems = reaper.CountSelectedMediaItems(0)
    if numSelectedItems > 0 then
        for i = 0, numSelectedItems - 1 do
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

        -- Extend the region by 100ms at the beginning and 50ms at the end
        startTime = startTime - start_silence
        endTime = endTime + end_silence
        
        if startTime < 0 then
          startTime = 0
          reaper.MB("Beginning silence adjusted to fit to project start.", "Error", 0)
        end
        
        -- Create the region
        reaper.GetSet_LoopTimeRange(true, false, startTime, endTime, false)
        reaper.SetEditCurPos(startTime, true, false)
        reaper.Main_OnCommand(40289, 0) -- Select region under mouse cursor
        reaper.Main_OnCommand(40306,0)
    end

    reaper.Undo_EndBlock("Create region over items", -1)
end


-- Function to adjust existing region
function setRegionLength()
  reaper.Undo_BeginBlock()
  local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
  local num_total = num_markers + num_regions
  local start_time = math.huge
  local end_time = 0
  
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
        start_time = math.min(start_time,item_start)
        end_time = math.max(end_time,item_end)
      end
        -- Extend the region by 100ms at the beginning and 50ms at the end
      start_time = start_time - start_silence
      end_time = end_time + end_silence
      
      if start_time < 0 then
        start_time = 0
        reaper.MB("Beginning silence adjusted to fit to project start.", "Error", 0)
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
          reaper.SetProjectMarker( rgn_num, 1, start_time, end_time, rgn_name )
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
        if rgn_num >= 0 then reaper.SetProjectMarker( rgn_num, 1, start_time, end_time, rgn_name ) end
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
      adjustItemPositions()
      if lockBoolUser == true then
        lockSelectedItems()
      end
      if checkOverlapWithRegions() then setRegionLength()
       else createRegionOverItems()
      end
    end
end


-- Run the main function
main()


