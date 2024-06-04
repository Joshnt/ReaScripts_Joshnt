-- @description Nearest Regions Edges To Items
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Set nearest regions edges to selected media items.lua
-- @link https://aaroncendan.me


-- Function to adjust item positions to 1000ms
function adjustItemPositions()
    r = reaper
    
    local function nothing() end
    local function bla() r.defer(nothing) end
    
    local items = r.CountSelectedMediaItems(0)
    if items < 2 then bla() return end
    
    d = 1000
    
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
    for i = 0, items - 1 do
        local item = r.GetSelectedMediaItem(0, i)
        if item then
            local it_len = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
            addItemToTable(item, it_len)
        end
    end
    
    r.Undo_BeginBlock()
    r.PreventUIRefresh(1)
    
    -- Process items for each track
    for track, items in pairs(t) do
        local it_start = r.GetMediaItemInfo_Value(items[1][1], 'D_POSITION')
        local x = it_start
    
        for i, itemData in ipairs(items) do
            local item = itemData[1]
            local itemLength = itemData[2]
            
            r.SetMediaItemInfo_Value(item, 'D_POSITION', x)
            x = x + itemLength + (tonumber(d) / 1000)
        end
    end
    
    r.PreventUIRefresh(-1)
    r.Undo_EndBlock('Set distance between items on each track', -1)
end


-- Function to check for overlapping regions with selected items
local function checkOverlapWithRegions()
    local numSelectedItems = r.CountSelectedMediaItems(0)
    if numSelectedItems == 0 then
        r.ShowMessageBox("No items selected!", "Error", 0)
        return
    end

    local proj = r.EnumProjects(-1, "")
    local numRegions = r.CountProjectMarkers(proj, 0)
    if numRegions == 0 then
        r.ShowMessageBox("No regions found in the project.", "Error", 0)
        return
    end

    local overlapDetected = false

    for i = 0, numSelectedItems - 1 do
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
        startTime = startTime - 0.1
        endTime = endTime + 0.05

        -- Create the region
        reaper.AddProjectMarker2(0, true, startTime, endTime, "", -1, 0)
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
      -- Extend the region by 100ms at the beginning and 50ms at the end
      start_time = start_time - 0.1
      end_time = end_time + 0.05
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
    adjustItemPositions()
    if checkOverlapWithRegions() then setRegionLength()
    else createRegionOverItems()
    end
    lockSelectedItems()
end

-- Run the main function
main()
