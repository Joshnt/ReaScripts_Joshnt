-- @noindex

-- "old" Version of the Core script for the "mother region" script version

-- para-global variables for script
joshnt_UniqueRegionsM = {
    -- para global variables; accessed from other scripts
    isolateItems = 1, -- 1 = move selected, 2 = move others, 3 = dont move
    space_in_between = 0, -- Time in seconds
    start_silence = 0, -- Time in seconds
    end_silence = 0, -- Time in seconds
    groupToleranceTime = 0,  -- Time in seconds
    lockBoolUser = false, -- bool to lock items after movement
    boolNeedActivateEnvelopeOption = nil, 
    regionColor = nil, 
    regionColorMother = nil, 
    regionName = "", 
    regionNameNumber = nil, 
    regionNameReplaceString = nil, 
    motherRegionName = "", 
    RRMLink_Child = 0, -- 1 = Master, 2 = Highest Parent, 3 = Parent, 4 = parent per item, 5 = Track, 0 = no link
    RRMLink_Mother = 0, -- 1 = Master, 2 = Highest Parent, 3 = Parent, 4 = parent per item, 5 = Track, 0 = no link
    createMotherRgn = false,
    createChildRgn = true,
    repositionToggle = true,

    -- only inside this script
    t = {}, -- Table to store items grouped by track
    trackIDs = {}, -- table trackIDs to access keys more easily
    numItems = 0,
    lockedItems = {},
    -- global variables for grouping of items; used in getItemGroups()
    itemGroups = {}, 
    itemGroupsStartsArray = nil, 
    itemGroupsEndArray = nil,
    nudgeValues = {},
    parentTracksWithEnvelopes = {},
    parentTrackForRRM = nil
}

function joshnt_UniqueRegionsM.getDefaults()
    if reaper.HasExtState("joshnt_UniqueRegions", "Options") then
        local tempArray = joshnt.splitStringToTable(reaper.GetExtState("joshnt_UniqueRegions", "Options"))
        joshnt_UniqueRegionsM.isolateItems = tonumber(tempArray[1])
        joshnt_UniqueRegionsM.space_in_between = tonumber(tempArray[2])
        joshnt_UniqueRegionsM.start_silence = tonumber(tempArray[3])
        joshnt_UniqueRegionsM.end_silence = tonumber(tempArray[4])
        joshnt_UniqueRegionsM.lockBoolUser = tempArray[5]
        joshnt_UniqueRegionsM.regionColor = tonumber(tempArray[6])
        joshnt_UniqueRegionsM.regionColorMother = tonumber(tempArray[7])
        joshnt_UniqueRegionsM.regionName = tempArray[8]
        joshnt_UniqueRegionsM.motherRegionName = tempArray[9]
        joshnt_UniqueRegionsM.RRMLink_Child = tonumber(tempArray[10])
        joshnt_UniqueRegionsM.RRMLink_Mother = tonumber(tempArray[11])
        joshnt_UniqueRegionsM.createMotherRgn = tempArray[12]
        joshnt_UniqueRegionsM.groupToleranceTime = tonumber(tempArray[13])
        joshnt_UniqueRegionsM.createChildRgn = tempArray[14]
        joshnt_UniqueRegionsM.repositionToggle = tempArray[15]
    end
end

function joshnt_UniqueRegionsM.saveDefaults()
    reaper.SetExtState("joshnt_UniqueRegions", "Options", joshnt_UniqueRegionsM.isolateItems..","..joshnt_UniqueRegionsM.space_in_between..","..joshnt_UniqueRegionsM.start_silence..","..joshnt_UniqueRegionsM.end_silence..","..tostring(joshnt_UniqueRegionsM.lockBoolUser)..","..joshnt_UniqueRegionsM.regionColor..","..joshnt_UniqueRegionsM.regionColorMother..","..joshnt_UniqueRegionsM.regionName..","..joshnt_UniqueRegionsM.motherRegionName..","..joshnt_UniqueRegionsM.RRMLink_Child..","..joshnt_UniqueRegionsM.RRMLink_Mother..","..tostring(joshnt_UniqueRegionsM.createMotherRgn)..","..joshnt_UniqueRegionsM.groupToleranceTime..","..tostring(joshnt_UniqueRegionsM.createChildRgn..","..tostring(joshnt_UniqueRegionsM.repositionToggle)), true)
end

function joshnt_UniqueRegionsM.initReaGlue()

    joshnt_UniqueRegionsM.t = {} -- init table t
    -- Function to add items to the table
    local function addItemToTable(item, itemLength)
        local track = reaper.GetMediaItem_Track(item)
        if not joshnt_UniqueRegionsM.t[track] then
            joshnt_UniqueRegionsM.t[track] = {}
        end
        table.insert(joshnt_UniqueRegionsM.t[track], {item, itemLength})
    end
  
  -- Group items by track
  for i = 0, joshnt_UniqueRegionsM.numItems - 1 do
      local itemInit_TEMP = reaper.GetSelectedMediaItem(0, i)
      if itemInit_TEMP then
          local it_len = reaper.GetMediaItemInfo_Value(itemInit_TEMP, 'D_LENGTH')
          addItemToTable(itemInit_TEMP, it_len)
      end
  end
  
  for key, _ in pairs(joshnt_UniqueRegionsM.t) do
    table.insert(joshnt_UniqueRegionsM.trackIDs, key)
  end
end

function joshnt_UniqueRegionsM.selectOriginalSelection(boolSelect)
  for track, items in pairs(joshnt_UniqueRegionsM.t) do
    for index, _ in ipairs(items) do
      reaper.SetMediaItemSelected(items[index][1], boolSelect)
    end
  end
  reaper.UpdateArrange()
end

-- Function to adjust item positions 
function joshnt_UniqueRegionsM.getItemGroups()
    joshnt_UniqueRegionsM.itemGroups, joshnt_UniqueRegionsM.itemGroupsStartsArray, joshnt_UniqueRegionsM.itemGroupsEndArray = joshnt.getOverlappingItemGroupsOfSelectedItems(joshnt_UniqueRegionsM.groupToleranceTime)
    if joshnt_UniqueRegionsM.itemGroups and joshnt_UniqueRegionsM.itemGroupsStartsArray and joshnt_UniqueRegionsM.itemGroupsEndArray then
        for i = 1, #joshnt_UniqueRegionsM.itemGroups do
            if i > 1 then
                joshnt_UniqueRegionsM.nudgeValues[i] = joshnt_UniqueRegionsM.space_in_between - ((joshnt_UniqueRegionsM.itemGroupsStartsArray[i] - joshnt_UniqueRegionsM.start_silence) - (joshnt_UniqueRegionsM.itemGroupsEndArray[i-1] + joshnt_UniqueRegionsM.end_silence))
            else 
                joshnt_UniqueRegionsM.nudgeValues[i] = 0
            end
        end
    end
end
    
    
function joshnt_UniqueRegionsM.adjustItemPositions()   
    -- move Groups, starting from last Group (and last item in Group)
      -- Deselect all items
      reaper.SelectAllMediaItems(0, false)
      for j = #joshnt_UniqueRegionsM.itemGroups-1, 1, -1 do
        local reverse = joshnt_UniqueRegionsM.nudgeValues[j+1] < 0  -- Determine if we need to move backward
        local absNudge = math.abs(joshnt_UniqueRegionsM.nudgeValues[j+1])  -- Get the absolute value of seconds
        local centerBetweenGroups
        if reverse == true then
          local possibleInsertRange_TEMP = (joshnt_UniqueRegionsM.itemGroupsStartsArray[j+1] - joshnt_UniqueRegionsM.itemGroupsEndArray[j]) - absNudge
          centerBetweenGroups = joshnt_UniqueRegionsM.itemGroupsEndArray[j] + (possibleInsertRange_TEMP * 0.5) -- entfernen von zeit dass gleicher abstand bei beiden items bleibt
        else
          centerBetweenGroups = joshnt_UniqueRegionsM.itemGroupsEndArray[j] + ((joshnt_UniqueRegionsM.itemGroupsStartsArray[j+1] - joshnt_UniqueRegionsM.itemGroupsEndArray[j]) * 0.5) -- Einfügen von zeit genau zwischen items
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
      joshnt_UniqueRegionsM.selectOriginalSelection(true) 
end

-- function to adjust existing region over selected items
function joshnt_UniqueRegionsM.setRegionLength()
  reaper.Undo_BeginBlock()

  local start_time, end_time = joshnt.startAndEndOfSelectedItems()

  -- Find region with most overlap
  local region_to_move = joshnt.getMostOverlappingRegion(start_time,end_time)
  
  start_time = start_time - joshnt_UniqueRegionsM.start_silence
  end_time = end_time + joshnt_UniqueRegionsM.end_silence
  
  if start_time < 0 then
    reaper.GetSet_LoopTimeRange(true, false, 0, math.abs(start_time), false)
    reaper.Main_OnCommand(40200, 0)
    end_time = end_time + math.abs(start_time)
    start_time = 0
    joshnt_UniqueRegionsM.selectOriginalSelection(true)
  end
  
  -- Move overlapping region
  if joshnt_UniqueRegionsM.regionColor ~= nil then
    reaper.SetProjectMarker3(0, region_to_move, 1, start_time, end_time, joshnt_UniqueRegionsM.regionName, joshnt_UniqueRegionsM.regionColor | 0x1000000) 
  else
    reaper.SetProjectMarker( region_to_move, 1, start_time, end_time, joshnt_UniqueRegionsM.regionName )
  end
  reaper.Undo_EndBlock("Set Nearest Region", -1)
  return region_to_move
end

-- Function to create a region over selected items
function joshnt_UniqueRegionsM.createRegionOverItems()
    local startTime, endTime = joshnt.startAndEndOfSelectedItems()
    -- Extend the region by 100ms at the beginning and 50ms at the end
    startTime = startTime - joshnt_UniqueRegionsM.start_silence
    endTime = endTime + joshnt_UniqueRegionsM.end_silence
    
    if startTime < 0 then
        reaper.GetSet_LoopTimeRange(true, false, startTime + joshnt_UniqueRegionsM.start_silence, startTime + joshnt_UniqueRegionsM.start_silence + math.abs(startTime), false)
        reaper.Main_OnCommand(40200, 0)
        endTime = endTime - startTime
        startTime = 0
    end
    -- Create the region
    local colorTEMP = 0;
    if joshnt_UniqueRegionsM.regionColor ~= nil then colorTEMP = joshnt_UniqueRegionsM.regionColor | 0x1000000 end
    return reaper.AddProjectMarker2(0, true, startTime, endTime, joshnt_UniqueRegionsM.regionName, -1, colorTEMP)
end

function joshnt_UniqueRegionsM.createRRMLink(RRMLink_Target,rgnIndex)
    if joshnt_UniqueRegionsM["RRMLink_"..RRMLink_Target] == 2 or joshnt_UniqueRegionsM["RRMLink_"..RRMLink_Target] == 3 then -- highest common parent or first common parent
        reaper.SetRegionRenderMatrix(0, rgnIndex,joshnt_UniqueRegionsM.parentTrackForRRM,1)
    elseif joshnt_UniqueRegionsM["RRMLink_"..RRMLink_Target] == 4 then -- parent track per item
        local parentTracks = {}
        for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
            local trackTemp = reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0,i))
            local parent = reaper.GetParentTrack(trackTemp) or reaper.GetMasterTrack(0)
            if not joshnt.tableContainsVal(parentTracks, parent) then
                parentTracks[#parentTracks + 1] = parent
            end
        end
        for i = 1, #parentTracks do
            reaper.SetRegionRenderMatrix(0, rgnIndex, parentTracks[i], 1)
        end
    elseif joshnt_UniqueRegionsM["RRMLink_"..RRMLink_Target] == 1 then -- Master track
        reaper.SetRegionRenderMatrix(0, rgnIndex,reaper.GetMasterTrack(0),1)
    elseif joshnt_UniqueRegionsM["RRMLink_"..RRMLink_Target] == 5 then -- indiv. tracks
        local groupTracks = joshnt.getTracksOfSelectedItems()
        for _, val in ipairs (groupTracks) do
            reaper.SetRegionRenderMatrix(0, rgnIndex,val,1)
        end
    end   
end

-- Function to check for overlapping regions with given time, returns bool
function joshnt_UniqueRegionsM.checkOverlapWithRegions(startTimeInput, endTimeInput, rgnTable)

    local proj = reaper.EnumProjects(-1, "")
    local numRegions = reaper.CountProjectMarkers(proj, 0)
    if numRegions == 0 then
        return false
    end
  
    local overlapDetected = false
  
    for j = 0, numRegions - 1 do
        local _, isrgn, rgnstart, rgnend, _, index = reaper.EnumProjectMarkers( j)
        if isrgn and not joshnt.tableContainsVal(rgnTable, index) then -- is region and is not newly created region
            if startTimeInput < rgnend and endTimeInput > rgnstart then -- region is in timeframe
                overlapDetected = true
                break
            end
        end
    end
  
    return overlapDetected
end

function joshnt_UniqueRegionsM.setRegionsForitemGroups()
    local rgnIndexTable_TEMP = {}
    local rgnName_Save;
    if joshnt_UniqueRegionsM.regionNameReplaceString then
        rgnName_Save = joshnt_UniqueRegionsM.regionName
    end



    for i = 1, #joshnt_UniqueRegionsM.itemGroups do
        reaper.SelectAllMediaItems(0, false)
        joshnt.reselectItems(joshnt_UniqueRegionsM.itemGroups[i])

        if joshnt_UniqueRegionsM.regionNameNumber then
            local regionNameNumber_TEMP = tostring(joshnt_UniqueRegionsM.regionNameNumber)
            if joshnt_UniqueRegionsM.regionNameNumber < 10 then
                regionNameNumber_TEMP = "0"..regionNameNumber_TEMP
            end
        
            joshnt_UniqueRegionsM.regionName = string.gsub(tostring(rgnName_Save), joshnt_UniqueRegionsM.regionNameReplaceString, regionNameNumber_TEMP) 
        end
        
        local currSelStart_TEMP, currSelEnd_TEMP = joshnt.startAndEndOfSelectedItems()
        local regionIndex_TEMP = nil

        if joshnt_UniqueRegionsM.checkOverlapWithRegions(currSelStart_TEMP, currSelEnd_TEMP, rgnIndexTable_TEMP) then regionIndex_TEMP = joshnt_UniqueRegionsM.setRegionLength()
        else regionIndex_TEMP = joshnt_UniqueRegionsM.createRegionOverItems()
        end
        
        joshnt_UniqueRegionsM.createRRMLink("Child",regionIndex_TEMP)

        if joshnt_UniqueRegionsM.regionNameNumber then
            joshnt_UniqueRegionsM.regionNameNumber = joshnt_UniqueRegionsM.regionNameNumber + 1
        end

        table.insert(rgnIndexTable_TEMP,regionIndex_TEMP)

    end
  return rgnIndexTable_TEMP
end

function joshnt_UniqueRegionsM.setMotherRegion(tableWithChildRgnIndex)
    tableWithChildRgnIndex = tableWithChildRgnIndex or {}
    joshnt_UniqueRegionsM.selectOriginalSelection(true)
    local startTime_TEMP, endTime_TEMP = joshnt.startAndEndOfSelectedItems()

    -- check if mother region already exists
    local overlappingRgns_TEMP = joshnt.getRegionsInTimeFrame(startTime_TEMP, endTime_TEMP) 
    local motherRegionStart = startTime_TEMP - joshnt_UniqueRegionsM.start_silence - 0.01
    local motherRegionEnd = endTime_TEMP + joshnt_UniqueRegionsM.end_silence + 0.01
    local addedRegion = nil

    if #overlappingRgns_TEMP > #tableWithChildRgnIndex then
        local differentRgns_TEMP = nil
        for _, v in ipairs(overlappingRgns_TEMP) do
            if not joshnt.tableContainsVal(tableWithChildRgnIndex, v) then
                differentRgns_TEMP = v
                break
            end
        end

        
        if joshnt_UniqueRegionsM.regionColorMother ~= nil then
            reaper.SetProjectMarker3(0, differentRgns_TEMP, 1, motherRegionStart, motherRegionEnd, joshnt_UniqueRegionsM.motherRegionName, joshnt_UniqueRegionsM.regionColorMother | 0x1000000) 
        else
            reaper.SetProjectMarker( differentRgns_TEMP, 1, motherRegionStart, motherRegionEnd, joshnt_UniqueRegionsM.motherRegionName )
        end
        addedRegion = differentRgns_TEMP
    else
        local colorTEMP = 0;
        if joshnt_UniqueRegionsM.regionColorMother ~= nil then colorTEMP = joshnt_UniqueRegionsM.regionColorMother | 0x1000000 end
        addedRegion = reaper.AddProjectMarker2(0, true, motherRegionStart, motherRegionEnd, joshnt_UniqueRegionsM.motherRegionName, -1, colorTEMP)
    end

    joshnt_UniqueRegionsM.createRRMLink("Mother",addedRegion)
end

-- Call from outside
-- Main function
function joshnt_UniqueRegionsM.main()
    joshnt_UniqueRegionsM.numItems = reaper.CountSelectedMediaItems(0)
    if joshnt_UniqueRegionsM.numItems == 0 then 
        reaper.ShowMessageBox("No items selected!", "Error", 0)
        return 
    end

    joshnt_UniqueRegionsM.space_in_between = math.abs(joshnt_UniqueRegionsM.space_in_between)
    joshnt_UniqueRegionsM.start_silence = math.abs(joshnt_UniqueRegionsM.start_silence)
    joshnt_UniqueRegionsM.end_silence = math.abs(joshnt_UniqueRegionsM.end_silence)
    joshnt_UniqueRegionsM.boolNeedActivateEnvelopeOption = reaper.GetToggleCommandState(40070) == 0

    local tempNumber = tonumber(joshnt_UniqueRegionsM.regionName:match("/E%((%d+)%)"))
    if tempNumber then
        joshnt_UniqueRegionsM.regionNameNumber = tempNumber
        joshnt_UniqueRegionsM.regionNameReplaceString = "/E%("..tempNumber.."%)"
    elseif joshnt_UniqueRegionsM.regionName:find("/E") then
        joshnt_UniqueRegionsM.regionNameNumber = 1
        joshnt_UniqueRegionsM.regionNameReplaceString = "/E"
    end

    reaper.PreventUIRefresh(1) 
    reaper.Undo_BeginBlock()  
    local originalRippleEditState = joshnt.getRippleEditingMode()
    if joshnt_UniqueRegionsM.boolNeedActivateEnvelopeOption then
        reaper.Main_OnCommand(40070, 0)
    end
    joshnt_UniqueRegionsM.initReaGlue()
    
    --get locked Items and unlock them
    joshnt_UniqueRegionsM.lockedItems = joshnt.saveLockedItems()
    joshnt.lockItemsState(joshnt_UniqueRegionsM.lockedItems,0)
    -- remove selected items from locked item array
    if joshnt_UniqueRegionsM.lockedItems and joshnt_UniqueRegionsM.lockedItems ~= {} then
        local i = 1
        while i <= #joshnt_UniqueRegionsM.lockedItems do
            local item = joshnt_UniqueRegionsM.lockedItems[i]
            if reaper.IsMediaItemSelected(item) then
                table.remove(joshnt_UniqueRegionsM.lockedItems, i)
            else
                i = i + 1
            end
        end
    end

    -- get all parent Tracks
    local parentTracks = joshnt.getParentTracksWithoutDuplicates(joshnt_UniqueRegionsM.trackIDs)

    if parentTracks[1] == nil and (joshnt_UniqueRegionsM.RRMLink_Child == 2 or joshnt_UniqueRegionsM.RRMLink_Child == 3 or joshnt_UniqueRegionsM.RRMLink_Child == 4) then -- falls keine Parents, Master als RRM
        joshnt_UniqueRegionsM.RRMLink_Child = 1
    elseif joshnt_UniqueRegionsM.RRMLink_Child == 2 or joshnt_UniqueRegionsM.RRMLink_Child == 3 then -- if not first parent per item
        local commonParents = {}
        for i = 1, #parentTracks do
            if (joshnt_UniqueRegionsM.RRMLink_Child == 2 or joshnt_UniqueRegionsM.RRMLink_Child == 3) and joshnt.isAnyParentOfAllSelectedItems(parentTracks[i]) then
                commonParents[#commonParents + 1] = parentTracks[i]
            end

            -- get parent Tracks with envelopes
            -- EDIT: RRM Link should be set despite any envelopes
            --[[
            if reaper.CountTrackEnvelopes(parentTracks[i]) > 0 then
                table.insert(joshnt_UniqueRegionsM.parentTracksWithEnvelopes,parentTracks[i])
            end--]]
        end

        -- set RRM ParentTrack
        if commonParents[1] then
            joshnt_UniqueRegionsM.parentTrackForRRM = commonParents[1]
        end
        for i = 1, #commonParents do
            if joshnt_UniqueRegionsM.RRMLink_Child == 2 then -- highest common parent
                if reaper.GetMediaTrackInfo_Value(commonParents[i], "IP_TRACKNUMBER") < reaper.GetMediaTrackInfo_Value(joshnt_UniqueRegionsM.parentTrackForRRM, "IP_TRACKNUMBER") then
                    joshnt_UniqueRegionsM.parentTrackForRRM = commonParents[i]
                end
            elseif joshnt_UniqueRegionsM.RRMLink_Child == 3 then -- first common parent
                if reaper.GetMediaTrackInfo_Value(commonParents[i], "IP_TRACKNUMBER") > reaper.GetMediaTrackInfo_Value(joshnt_UniqueRegionsM.parentTrackForRRM, "IP_TRACKNUMBER") then
                    joshnt_UniqueRegionsM.parentTrackForRRM = commonParents[i]
                end
            end
        end

        -- check if highest parent is any parent of all Tracks of selected items
        if (joshnt_UniqueRegionsM.RRMLink_Child == 2 or joshnt_UniqueRegionsM.RRMLink_Child == 3) and joshnt_UniqueRegionsM.parentTrackForRRM == nil then
            joshnt_UniqueRegionsM.RRMLink_Child = 1 -- set to master
        end

    end
    

    -- isolate
    if joshnt_UniqueRegionsM.isolateItems == 1 then 
        local retval, itemTable = joshnt.isolate_MoveSelectedItems_InsertAtNextSilentPointInProject(joshnt_UniqueRegionsM.start_silence, joshnt_UniqueRegionsM.end_silence, joshnt_UniqueRegionsM.end_silence)
        if retval == 1 then joshnt.reselectItems(itemTable) end
        joshnt_UniqueRegionsM.initReaGlue()
    elseif joshnt_UniqueRegionsM.isolateItems == 2 then 
        joshnt.isolate_MoveOtherItems_ToEndOfSelectedItems(joshnt_UniqueRegionsM.start_silence, joshnt_UniqueRegionsM.end_silence, joshnt_UniqueRegionsM.start_silence, joshnt_UniqueRegionsM.end_silence) 
    end

    joshnt_UniqueRegionsM.getItemGroups()
    if not joshnt_UniqueRegionsM.itemGroups then reaper.ShowConsoleMsg("\nNo Item groups found") return end
    if joshnt_UniqueRegionsM.repositionToggle then joshnt_UniqueRegionsM.adjustItemPositions() end
    joshnt.lockItemsState(joshnt_UniqueRegionsM.lockedItems,1)
    joshnt.setRippleEditingMode(originalRippleEditState)
    if joshnt_UniqueRegionsM.boolNeedActivateEnvelopeOption then
        reaper.Main_OnCommand(40070, 0)
    end

    if joshnt_UniqueRegionsM.lockBoolUser == true then
        joshnt.lockSelectedItems()
    end
    local childRegionIndex = nil 
    if joshnt_UniqueRegionsM.createChildRgn then childRegionIndex = joshnt_UniqueRegionsM.setRegionsForitemGroups() end
    if joshnt_UniqueRegionsM.createMotherRgn and joshnt_UniqueRegionsM.createChildRgn then joshnt_UniqueRegionsM.setMotherRegion(childRegionIndex) 
    elseif joshnt_UniqueRegionsM.createMotherRgn then joshnt_UniqueRegionsM.setMotherRegion(childRegionIndex) end
    reaper.Undo_EndBlock("joshnt Create Regions", -1)

    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
end

-- Call from outside
function joshnt_UniqueRegionsM.Quit()
    joshnt_UniqueRegionsM = nil
end

return joshnt_UniqueRegionsM

