-- @noindex
joshnt_ReaGlue = {
    -- para global variables
    isolateItems = 1, -- 1 = move selected, 2 = move others, 3 = dont move
    space_in_between = 0, -- Time in seconds
    start_silence = 0, -- Time in seconds
    end_silence = 0, -- Time in seconds
    groupToleranceTime = 0,  -- Time in seconds
    RRMLink_ToMaster = true,
    t = {},
    trackIDs = {},   -- table trackIDs to access keys more easily
    numItems = 0,
    itemSelectionStartTime = nil,
    itemSelectionEndTime = nil,
    itemGroups = {},
    nudgeValues = {},
    itemGroupsStartsArray = {},
    itemGroupsEndArray = {},
    parentTracksWithEnvelopes_GLOBAL = {},
    openRgnDialog = true
}


function joshnt_ReaGlue.initReaGlue()
  
  -- Function to add items to the table
  local function addItemToTable(item, itemLength)
      local track = reaper.GetMediaItem_Track(item)
      if not joshnt_ReaGlue.t[track] then
        joshnt_ReaGlue.t[track] = {}
      end
      table.insert(joshnt_ReaGlue.t[track], {item, itemLength})
  end
  
  -- Group items by track
  for i = 0, joshnt_ReaGlue.numItems - 1 do
      local itemTEMP = reaper.GetSelectedMediaItem(0, i)
      if itemTEMP then
          local it_len = reaper.GetMediaItemInfo_Value(itemTEMP, 'D_LENGTH')
          addItemToTable(itemTEMP, it_len)
      end
  end

  for key, _ in pairs(joshnt_ReaGlue.t) do
    table.insert(joshnt_ReaGlue.trackIDs, key)
  end
end

function joshnt_ReaGlue.selectOriginalSelection(boolSelect)
  for track, items in pairs(joshnt_ReaGlue.t) do
    for index, _ in ipairs(items) do
      reaper.SetMediaItemSelected(items[index][1], boolSelect)
    end
  end
  reaper.UpdateArrange()
end

function joshnt_ReaGlue.getItemGroups()
    joshnt_ReaGlue.itemGroups, joshnt_ReaGlue.itemGroupsStartsArray, joshnt_ReaGlue.itemGroupsEndArray = joshnt.getOverlappingItemGroupsOfSelectedItems(joshnt_ReaGlue.groupToleranceTime)
    if joshnt_ReaGlue.itemGroups and joshnt_ReaGlue.itemGroupsStartsArray and joshnt_ReaGlue.itemGroupsEndArray then
        for i = 1, #joshnt_ReaGlue.itemGroups do
            if i > 1 then
                joshnt_ReaGlue.nudgeValues[i] = joshnt_ReaGlue.space_in_between - ((joshnt_ReaGlue.itemGroupsStartsArray[i] - joshnt_ReaGlue.start_silence) - (joshnt_ReaGlue.itemGroupsEndArray[i-1] + joshnt_ReaGlue.end_silence))
            else 
                joshnt_ReaGlue.nudgeValues[i] = 0
            end
        end
    end
end

function joshnt_ReaGlue.adjustItemPositions()   
    -- move Groups, starting from last Group (and last item in Group)
      -- Deselect all items
      reaper.SelectAllMediaItems(0, false)
      for j = #joshnt_ReaGlue.itemGroups-1, 1, -1 do
        local reverse = joshnt_ReaGlue.nudgeValues[j+1] < 0  -- Determine if we need to move backward
        local absNudge = math.abs(joshnt_ReaGlue.nudgeValues[j+1])  -- Get the absolute value of seconds
        local centerBetweenGroups
        if reverse == true then
          local possibleInsertRange_TEMP = (joshnt_ReaGlue.itemGroupsStartsArray[j+1] - joshnt_ReaGlue.itemGroupsEndArray[j]) - absNudge
          centerBetweenGroups = joshnt_ReaGlue.itemGroupsEndArray[j] + (possibleInsertRange_TEMP * 0.5) -- entfernen von zeit dass gleicher abstand bei beiden items bleibt
        else
          centerBetweenGroups = joshnt_ReaGlue.itemGroupsEndArray[j] + ((joshnt_ReaGlue.itemGroupsStartsArray[j+1] - joshnt_ReaGlue.itemGroupsEndArray[j]) * 0.5) -- Einfügen von zeit genau zwischen items
        end
        local endOfInsertedTime_TEMP = centerBetweenGroups + absNudge
        
        reaper.SetEditCurPos(centerBetweenGroups, true, true)
        if reverse == true then
          joshnt.removeTimeOnAllTracks(centerBetweenGroups, endOfInsertedTime_TEMP)
        else
          joshnt.insertTimeOnAllTracks(centerBetweenGroups,endOfInsertedTime_TEMP)
        end
        reaper.UpdateArrange()
      end 
    
    -- restore selection
      -- Deselect all items
      reaper.SelectAllMediaItems(0, false)
      -- Reselect Items
      joshnt_ReaGlue.selectOriginalSelection(true) 
end

function joshnt_ReaGlue.createRegionOverItems()
    local startTime, endTime = joshnt.startAndEndOfSelectedItems()
    -- Extend the region by 100ms at the beginning and 50ms at the end
    startTime = startTime - joshnt_ReaGlue.start_silence
    endTime = endTime + joshnt_ReaGlue.end_silence
    
    if startTime < 0 then
        reaper.GetSet_LoopTimeRange(true, false, startTime + joshnt_ReaGlue.start_silence, startTime + joshnt_ReaGlue.start_silence + math.abs(startTime), false)
        reaper.Main_OnCommand(40200, 0)
        endTime = endTime - startTime
        startTime = 0
    end
    -- Create the region
    if joshnt_ReaGlue.openRegionDialog then
        reaper.GetSet_LoopTimeRange(true, false, startTime, endTime, false)
        reaper.SetEditCurPos(startTime, true, false)
        reaper.Main_OnCommand(40289, 0) -- Select region under mouse cursor
        reaper.Main_OnCommand(40306,0) -- create region with dialog
    else
        local rgnIndex = reaper.AddProjectMarker2(0, true, startTime, endTime, "", -1, 0)
        -- set region render matrix link
        if joshnt_ReaGlue.RRMLink_ToMaster == true then
            reaper.SetRegionRenderMatrix(0, rgnIndex,reaper.GetMasterTrack(0),1)
        end
    end
end

-- function to adjust existing region over selected items
function joshnt_ReaGlue.setRegionLength()  
    local start_time, end_time = joshnt.startAndEndOfSelectedItems()
  
    -- Find region with most overlap
    local region_to_move, _,_, name = joshnt.getMostOverlappingRegion(start_time,end_time)
    
    start_time = start_time - joshnt_ReaGlue.start_silence
    end_time = end_time + joshnt_ReaGlue.end_silence
    
    if start_time < 0 then
      reaper.GetSet_LoopTimeRange(true, false, 0, math.abs(start_time), false)
      reaper.Main_OnCommand(40200, 0)
      end_time = end_time + math.abs(start_time)
      start_time = 0
      joshnt_ReaGlue.selectOriginalSelection(true)
    end
    
    reaper.SetProjectMarker( region_to_move, 1, start_time, end_time, name)
end

-- Main function - call from outside
function joshnt_ReaGlue.main()
    joshnt_ReaGlue.numItems = reaper.CountSelectedMediaItems(0)
    if joshnt_ReaGlue.numItems == 0 then 
      joshnt.TooltipAtMouse("No items selected!")
      return 
    end
    reaper.PreventUIRefresh(1) 
    reaper.Undo_BeginBlock()  
    local originalRippleEditState = joshnt.getRippleEditingMode()
    joshnt_ReaGlue.initReaGlue()
    
    -- global variables for grouping of items; used in getItemGroups()
    joshnt_ReaGlue.itemSelectionStartTime, joshnt_ReaGlue.itemSelectionEndTime = joshnt.startAndEndOfSelectedItems()
    joshnt_ReaGlue.itemGroups = {}
    joshnt_ReaGlue.nudgeValues = {}
    joshnt_ReaGlue.itemGroupsStartsArray = {}
    joshnt_ReaGlue.itemGroupsEndArray = {}
    
    -- isolate or only move items on same tracks away 
    if joshnt_ReaGlue.isolateItems == 1 then 
        local retval, itemTable = joshnt.isolate_MoveSelectedItems_InsertAtNextSilentPointInProject(joshnt_ReaGlue.start_silence, joshnt_ReaGlue.end_silence, joshnt_ReaGlue.end_silence)
        if retval == 1 then joshnt.reselectItems(itemTable) end
        joshnt_ReaGlue.initReaGlue()
    elseif joshnt_ReaGlue.isolateItems == 2 then 
        joshnt.isolate_MoveOtherItems_ToEndOfSelectedItems(joshnt_ReaGlue.start_silence, joshnt_ReaGlue.end_silence, joshnt_ReaGlue.start_silence, joshnt_ReaGlue.end_silence) 
    end

    joshnt_ReaGlue.getItemGroups()
    joshnt_ReaGlue.adjustItemPositions()
    joshnt.setRippleEditingMode(originalRippleEditState)
    reaper.Undo_EndBlock("Move Items", -1)
    reaper.PreventUIRefresh(-1)
    local currSelStart_TEMP, currSelEnd_TEMP = joshnt.startAndEndOfSelectedItems()
    if joshnt.checkOverlapWithRegions(currSelStart_TEMP, currSelEnd_TEMP) then joshnt_ReaGlue.setRegionLength()
    else joshnt_ReaGlue.createRegionOverItems()
    end
    joshnt.unselectAllTracks()
    reaper.UpdateArrange()
    joshnt_ReaGlue = nil
end


return joshnt_ReaGlue