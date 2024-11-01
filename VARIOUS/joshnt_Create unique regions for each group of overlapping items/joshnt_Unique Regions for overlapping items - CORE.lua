-- @noindex

-- para-global variables for script
joshnt_UniqueRegions = {
    -- para global variables; accessed from other scripts
    repositionToggle = true,
    space_in_between = 0, -- Time in seconds

    start_silence = 0, -- Time in seconds
    end_silence = 0, -- Time in seconds
    groupToleranceTime = 0,  -- Time in seconds

    createMotherRgn = false,
    createChildRgn = true,
    regionColor = nil, 
    regionColorMother = nil, 
    regionName = "", 
    regionNameReplaceString = {}, -- subarray with index of found wildcards with subarray with {stringToSearchFor, curr Index/ Value of that count/ Replacement [, modifier, modifierArgument1, modifierArgument2]}
    motherRegionName = "", 
    RRMLink_Child = 0, -- 1 = Master, 2 = Highest Parent, 3 = Parent, 4 = parent per item, 5 = Track, 0 = no link
    RRMLink_Mother = 0, -- 1 = Master, 2 = Highest Parent, 3 = Parent, 4 = parent per item, 5 = Track, 0 = no link

    -- Region/ Rarker by every X item tab 
    isRgn_RMX = {}, 
    everyX_RMX = {},
    RRMLink_RMX = {}, -- 1 = Master, 2 = Highest Parent, 3 = Parent, 4 = parent per item, 5 = Track, 0 = no link
    name_RMX = {}, 
    name_RMXReplaceString = {}, -- subarray with {stringToSearchFor, curr Index of that count[, modifier, modifierArgument1, modifierArgument2]}
    color_RMX = {}, 
    
    isolateItems = 1, -- 1 = move selected, 2 = move others, 3 = dont move
    lockBoolUser = false, -- bool to lock items after movement

    -- only inside this script
    boolNeedActivateEnvelopeOption = nil, 
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
    parentTrackForRRM = nil,
    regionName_Rename = nil, -- single string
    name_RMX_Rename = {} -- name array
}

function joshnt_UniqueRegions.getDefaults()
    if reaper.HasExtState("joshnt_UniqueRegions", "Options") then
        local tempArray = joshnt.splitStringToTable(reaper.GetExtState("joshnt_UniqueRegions", "Options"))
        joshnt_UniqueRegions.isolateItems = tonumber(tempArray[1])
        joshnt_UniqueRegions.space_in_between = tonumber(tempArray[2])
        joshnt_UniqueRegions.start_silence = tonumber(tempArray[3])
        joshnt_UniqueRegions.end_silence = tonumber(tempArray[4])
        joshnt_UniqueRegions.lockBoolUser = tempArray[5]
        joshnt_UniqueRegions.regionColor = tonumber(tempArray[6])
        joshnt_UniqueRegions.regionColorMother = tonumber(tempArray[7])
        joshnt_UniqueRegions.regionName = tempArray[8]
        joshnt_UniqueRegions.motherRegionName = tempArray[9]
        joshnt_UniqueRegions.RRMLink_Child = tonumber(tempArray[10])
        joshnt_UniqueRegions.RRMLink_Mother = tonumber(tempArray[11])
        joshnt_UniqueRegions.createMotherRgn = tempArray[12]
        joshnt_UniqueRegions.groupToleranceTime = tonumber(tempArray[13])
        joshnt_UniqueRegions.createChildRgn = tempArray[14]
        joshnt_UniqueRegions.repositionToggle = tempArray[15]
    end
end

function joshnt_UniqueRegions.saveDefaults()
    reaper.SetExtState("joshnt_UniqueRegions", "Options", joshnt_UniqueRegions.isolateItems..","..joshnt_UniqueRegions.space_in_between..","..joshnt_UniqueRegions.start_silence..","..joshnt_UniqueRegions.end_silence..","..tostring(joshnt_UniqueRegions.lockBoolUser)..","..joshnt_UniqueRegions.regionColor..","..joshnt_UniqueRegions.regionColorMother..","..joshnt_UniqueRegions.regionName..","..joshnt_UniqueRegions.motherRegionName..","..joshnt_UniqueRegions.RRMLink_Child..","..joshnt_UniqueRegions.RRMLink_Mother..","..tostring(joshnt_UniqueRegions.createMotherRgn)..","..joshnt_UniqueRegions.groupToleranceTime..","..tostring(joshnt_UniqueRegions.createChildRgn..","..tostring(joshnt_UniqueRegions.repositionToggle)), true)
end

-- gets items sorted by tracks
function joshnt_UniqueRegions.sortItemsByTracks()

    joshnt_UniqueRegions.t = {} -- init table t
    -- Function to add items to the table
    local function addItemToTable(item, itemLength)
        local track = reaper.GetMediaItem_Track(item)
        if not joshnt_UniqueRegions.t[track] then
            joshnt_UniqueRegions.t[track] = {}
        end
        table.insert(joshnt_UniqueRegions.t[track], {item, itemLength})
    end
  
  -- Group items by track
  for i = 0, joshnt_UniqueRegions.numItems - 1 do
      local itemInit_TEMP = reaper.GetSelectedMediaItem(0, i)
      if itemInit_TEMP then
          local it_len = reaper.GetMediaItemInfo_Value(itemInit_TEMP, 'D_LENGTH')
          addItemToTable(itemInit_TEMP, it_len)
      end
  end
  
  for key, _ in pairs(joshnt_UniqueRegions.t) do
    table.insert(joshnt_UniqueRegions.trackIDs, key)
  end
end

function joshnt_UniqueRegions.selectOriginalSelection(boolSelect)
  for track, items in pairs(joshnt_UniqueRegions.t) do
    for index, _ in ipairs(items) do
      reaper.SetMediaItemSelected(items[index][1], boolSelect)
    end
  end
  reaper.UpdateArrange()
end

-- Function to adjust item positions 
function joshnt_UniqueRegions.getItemGroups()
    joshnt_UniqueRegions.itemGroups, joshnt_UniqueRegions.itemGroupsStartsArray, joshnt_UniqueRegions.itemGroupsEndArray = joshnt.getOverlappingItemGroupsOfSelectedItems(joshnt_UniqueRegions.groupToleranceTime)
    if joshnt_UniqueRegions.itemGroups and joshnt_UniqueRegions.itemGroupsStartsArray and joshnt_UniqueRegions.itemGroupsEndArray then
        for i = 1, #joshnt_UniqueRegions.itemGroups do
            if i > 1 then
                joshnt_UniqueRegions.nudgeValues[i] = joshnt_UniqueRegions.space_in_between - ((joshnt_UniqueRegions.itemGroupsStartsArray[i] - joshnt_UniqueRegions.start_silence) - (joshnt_UniqueRegions.itemGroupsEndArray[i-1] + joshnt_UniqueRegions.end_silence))
            else 
                joshnt_UniqueRegions.nudgeValues[i] = 0
            end
        end
    end
end
    
    
function joshnt_UniqueRegions.adjustItemPositions()   
    -- move Groups, starting from last Group (and last item in Group)
      -- Deselect all items
      reaper.SelectAllMediaItems(0, false)
      for j = #joshnt_UniqueRegions.itemGroups-1, 1, -1 do
        local reverse = joshnt_UniqueRegions.nudgeValues[j+1] < 0  -- Determine if we need to move backward
        local absNudge = math.abs(joshnt_UniqueRegions.nudgeValues[j+1])  -- Get the absolute value of seconds
        local centerBetweenGroups
        if reverse == true then
          local possibleInsertRange_TEMP = (joshnt_UniqueRegions.itemGroupsStartsArray[j+1] - joshnt_UniqueRegions.itemGroupsEndArray[j]) - absNudge
          centerBetweenGroups = joshnt_UniqueRegions.itemGroupsEndArray[j] + (possibleInsertRange_TEMP * 0.5) -- entfernen von zeit dass gleicher abstand bei beiden items bleibt
        else
          centerBetweenGroups = joshnt_UniqueRegions.itemGroupsEndArray[j] + ((joshnt_UniqueRegions.itemGroupsStartsArray[j+1] - joshnt_UniqueRegions.itemGroupsEndArray[j]) * 0.5) -- Einfügen von zeit genau zwischen items
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
      joshnt_UniqueRegions.selectOriginalSelection(true) 
end

-- function to adjust existing region over selected items
function joshnt_UniqueRegions.setRegionLength(RMXIndex)
  reaper.Undo_BeginBlock()

  local start_time, end_time = 0, 0
  local rgnNameReference, rgnColor = "", nil
  if not RMXIndex or RMXIndex == 0 then start_time, end_time = joshnt.startAndEndOfSelectedItems() end -- child rgns

  -- Find region with most overlap
  local region_to_move, _, _, rgnName = joshnt.getMostOverlappingRegion(start_time,end_time)
  joshnt_UniqueRegions.updateRgnRename(RMXIndex, rgnName)


  if not RMXIndex or RMXIndex == 0 then
    rgnNameReference = joshnt_UniqueRegions.regionName_Rename
    rgnColor = joshnt_UniqueRegions.regionColor

    start_time = start_time - joshnt_UniqueRegions.start_silence
    end_time = end_time + joshnt_UniqueRegions.end_silence
    if start_time < 0 then
        reaper.GetSet_LoopTimeRange(true, false, 0, math.abs(start_time), false)
        reaper.Main_OnCommand(40200, 0)
        end_time = end_time + math.abs(start_time)
        start_time = 0
        joshnt_UniqueRegions.selectOriginalSelection(true)
    end
  else
    rgnNameReference = joshnt_UniqueRegions.name_RMX_Rename[RMXIndex]
    rgnColor = joshnt_UniqueRegions.color_RMX[RMXIndex]
  end
  

  
  -- Move overlapping region
  if rgnColor ~= nil then
    reaper.SetProjectMarker3(0, region_to_move, 1, start_time, end_time, rgnNameReference, rgnColor | 0x1000000) 
  else
    reaper.SetProjectMarker( region_to_move, 1, start_time, end_time, rgnNameReference )
  end
  reaper.Undo_EndBlock("Set Nearest Region", -1)
  return region_to_move
end

-- Function to create a region over selected items
function joshnt_UniqueRegions.createRegionOverItems()
    local startTime, endTime = joshnt.startAndEndOfSelectedItems()
    -- Extend the region by 100ms at the beginning and 50ms at the end
    startTime = startTime - joshnt_UniqueRegions.start_silence
    endTime = endTime + joshnt_UniqueRegions.end_silence
    
    if startTime < 0 then
        reaper.GetSet_LoopTimeRange(true, false, startTime + joshnt_UniqueRegions.start_silence, startTime + joshnt_UniqueRegions.start_silence + math.abs(startTime), false)
        reaper.Main_OnCommand(40200, 0)
        endTime = endTime - startTime
        startTime = 0
    end
    -- Create the region
    local colorTEMP = 0;
    if joshnt_UniqueRegions.regionColor ~= nil then colorTEMP = joshnt_UniqueRegions.regionColor | 0x1000000 end
    return reaper.AddProjectMarker2(0, true, startTime, endTime, joshnt_UniqueRegions.regionName_Rename, -1, colorTEMP)
end

function joshnt_UniqueRegions.createRRMLink(RRMLink_Target,rgnIndex)
    if joshnt_UniqueRegions["RRMLink_"..RRMLink_Target] == 2 or joshnt_UniqueRegions["RRMLink_"..RRMLink_Target] == 3 then -- highest common parent or first common parent
        reaper.SetRegionRenderMatrix(0, rgnIndex,joshnt_UniqueRegions.parentTrackForRRM,1)
    elseif joshnt_UniqueRegions["RRMLink_"..RRMLink_Target] == 4 then -- parent track per item
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
    elseif joshnt_UniqueRegions["RRMLink_"..RRMLink_Target] == 1 then -- Master track
        reaper.SetRegionRenderMatrix(0, rgnIndex,reaper.GetMasterTrack(0),1)
    elseif joshnt_UniqueRegions["RRMLink_"..RRMLink_Target] == 5 then -- indiv. tracks
        local groupTracks = joshnt.getTracksOfSelectedItems()
        for _, val in ipairs (groupTracks) do
            reaper.SetRegionRenderMatrix(0, rgnIndex,val,1)
        end
    end   
end

-- Function to check for overlapping regions with given time, returns bool
function joshnt_UniqueRegions.checkOverlapWithRegions(startTimeInput, endTimeInput, rgnTable)

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

function joshnt_UniqueRegions.setRegionsForitemGroups()
    local rgnIndexTable_TEMP = {}



    for i = 1, #joshnt_UniqueRegions.itemGroups do
        reaper.SelectAllMediaItems(0, false)
        joshnt.reselectItems(joshnt_UniqueRegions.itemGroups[i])
        
        local currSelStart_TEMP, currSelEnd_TEMP = joshnt.startAndEndOfSelectedItems()
        local regionIndex_TEMP = nil

        if joshnt_UniqueRegions.checkOverlapWithRegions(currSelStart_TEMP, currSelEnd_TEMP, rgnIndexTable_TEMP) then regionIndex_TEMP = joshnt_UniqueRegions.setRegionLength(0)
        else regionIndex_TEMP = joshnt_UniqueRegions.createRegionOverItems()
        end
        
        joshnt_UniqueRegions.createRRMLink("Child",regionIndex_TEMP)

        table.insert(rgnIndexTable_TEMP,regionIndex_TEMP)

    end
  return rgnIndexTable_TEMP
end

function joshnt_UniqueRegions.setMotherRegion(tableWithChildRgnIndex)
    tableWithChildRgnIndex = tableWithChildRgnIndex or {}
    joshnt_UniqueRegions.selectOriginalSelection(true)
    local startTime_TEMP, endTime_TEMP = joshnt.startAndEndOfSelectedItems()

    -- check if mother region already exists
    local overlappingRgns_TEMP = joshnt.getRegionsInTimeFrame(startTime_TEMP, endTime_TEMP) 
    local motherRegionStart = startTime_TEMP - joshnt_UniqueRegions.start_silence - 0.01
    local motherRegionEnd = endTime_TEMP + joshnt_UniqueRegions.end_silence + 0.01
    local addedRegion = nil

    if #overlappingRgns_TEMP > #tableWithChildRgnIndex then
        local differentRgns_TEMP = nil
        for _, v in ipairs(overlappingRgns_TEMP) do
            if not joshnt.tableContainsVal(tableWithChildRgnIndex, v) then
                differentRgns_TEMP = v
                break
            end
        end

        
        if joshnt_UniqueRegions.regionColorMother ~= nil then
            reaper.SetProjectMarker3(0, differentRgns_TEMP, 1, motherRegionStart, motherRegionEnd, joshnt_UniqueRegions.motherRegionName, joshnt_UniqueRegions.regionColorMother | 0x1000000) 
        else
            reaper.SetProjectMarker( differentRgns_TEMP, 1, motherRegionStart, motherRegionEnd, joshnt_UniqueRegions.motherRegionName )
        end
        addedRegion = differentRgns_TEMP
    else
        local colorTEMP = 0;
        if joshnt_UniqueRegions.regionColorMother ~= nil then colorTEMP = joshnt_UniqueRegions.regionColorMother | 0x1000000 end
        addedRegion = reaper.AddProjectMarker2(0, true, motherRegionStart, motherRegionEnd, joshnt_UniqueRegions.motherRegionName, -1, colorTEMP)
    end

    joshnt_UniqueRegions.createRRMLink("Mother",addedRegion)
end

-- all wildcard-Functions look a bit weird with the if as RMX regions and more wildcards got added later
-- all replace Strings will be used in a gmatch -> weird syntax
-- check for /E's in region names
function joshnt_UniqueRegions.wildcardsCheck_E(currName, currReplaceStr)
    -- Check for "/E('Number')" - normal enumerate
    for number in currName:gmatch("/E%((%d+)%)") do
        currReplaceStr[#currReplaceStr + 1] = {}  
        currReplaceStr[#currReplaceStr][1] = "/E%("..number.."%)"
        currReplaceStr[#currReplaceStr][2] = number
    end

    -- Check for "/E('Number1'%'Number2')" - modulu enumerate 
    for number1, number2 in currName:gmatch("/E%((%d+)%%(%d+)%)") do
        currReplaceStr[#currReplaceStr + 1] = {}  
        currReplaceStr[#currReplaceStr][1] = "/E%("..number1.."%%"..number2.."%)"
        currReplaceStr[#currReplaceStr][2] = number1
        currReplaceStr[#currReplaceStr][3] = "%"
        currReplaceStr[#currReplaceStr][4] = number2
    end
    
    -- Check for "/E('Number1'%'Number2''offset')" - modulu enumerate with offset
    for number1, number2, offset in currName:gmatch("/E%((%d+)%%(%d+)([+-]%d+)%)") do
        currReplaceStr[#currReplaceStr + 1] = {}  
        currReplaceStr[#currReplaceStr][1] = "/E%("..number1.."%%"..number2..offset.."%)"
        currReplaceStr[#currReplaceStr][2] = number1 % number2
        currReplaceStr[#currReplaceStr][3] = "%"
        currReplaceStr[#currReplaceStr][4] = number2
        currReplaceStr[#currReplaceStr][5] = offset
    end
end

-- check for /M's in region name
function joshnt_UniqueRegions.wildcardsCheck_M(currName, currReplaceStr)
    -- Check for "/M('MidiNote')" - normal stepsize
    for midiNote, octave in currName:gmatch("/M%((..?)([+-]?%d+)%)") do
        reaper.ShowConsoleMsg(tostring(#currReplaceStr).." and "..midiNote.." and "..octave.."\n")
        currReplaceStr[#currReplaceStr + 1] = {}  
        currReplaceStr[#currReplaceStr][1] = "/M%("..midiNote..octave.."%)"
        currReplaceStr[#currReplaceStr][2] = midiNote
    end

    -- Check for "/M('MidiNote','stepsize')" - custom stepsize
    for midiNote, octave, stepSize in currName:gmatch(("/M%((..?)([+-]?%d+),(%s*%-?%d+)%)")) do
        local stepSizeNum = tonumber(stepSize) -- avoid getting some random swobi input
        if stepSizeNum then
            currReplaceStr[#currReplaceStr + 1] = {}  
            currReplaceStr[#currReplaceStr][1] = "/M%("..midiNote..octave..","..stepSize.."%)"
            currReplaceStr[#currReplaceStr][2] = {joshnt.findIndex(joshnt.midiNotes, midiNote), octave}
            currReplaceStr[#currReplaceStr][3] = "STEPSIZE"
            currReplaceStr[#currReplaceStr][4] = stepSize
        end
    end
end

-- check for /O's in child region name
function joshnt_UniqueRegions.wildcardsCheck_O(currName, currReplaceStr)
    -- Check for "/O('AlternativeName')"
    for alternativeName in currName:gmatch("/O%((.-)%)") do
        currReplaceStr[#currReplaceStr + 1] = {}  
        currReplaceStr[#currReplaceStr][1] = "/O%("..alternativeName.."%)"
        currReplaceStr[#currReplaceStr][2] = alternativeName
    end
end

-- call function without RMXIndex/ RMXIndex = 0 to refer to childRgn
function joshnt_UniqueRegions.wildcardsCheck(RMXIndex) 
    local currName, currReplaceStr;
    if RMXIndex ~= 0 then 
        reaper.ShowConsoleMsg(tostring(RMXIndex).."\n")
        currName = joshnt_UniqueRegions.name_RMX[RMXIndex]
        currReplaceStr = joshnt_UniqueRegions.name_RMXReplaceString[RMXIndex]
    else
        currName = joshnt_UniqueRegions.regionName
        currReplaceStr = joshnt_UniqueRegions.regionNameReplaceString
    end
    joshnt_UniqueRegions.wildcardsCheck_E(currName, currReplaceStr)
    joshnt_UniqueRegions.wildcardsCheck_M(currName, currReplaceStr)
    joshnt_UniqueRegions.wildcardsCheck_O(currName, currReplaceStr)
end

-- sets the desired name to the '_Rename' property of child rgns or RMX, referenced by moving or creating functions
function joshnt_UniqueRegions.updateRgnRename(RMXIndex, oldName)
    local currName, currReplaceStr, newName;
    if RMXIndex ~= 0 then 
        currName = joshnt_UniqueRegions.name_RMX[RMXIndex]
        currReplaceStr = joshnt_UniqueRegions.name_RMXReplaceString[RMXIndex]
    else
        currName = joshnt_UniqueRegions.regionName
        currReplaceStr = joshnt_UniqueRegions.regionNameReplaceString
    end
    newName = currName;

    -- index of currReplaceStr see at start of script with variable define
    for i = 1, #currReplaceStr do
        if currReplaceStr[i][1]:find("/E") then
            newName = string.gsub(newName, currReplaceStr[i][1], joshnt.addLeadingZero(currReplaceStr[i][1],2)) 

            if currReplaceStr[i][3] == "%" then -- modulu addition/ increment
                currReplaceStr[i][2] = (currReplaceStr[i][2] + 1) % currReplaceStr[i][4]
                -- offset for modulu, if set
                if currReplaceStr[i][5] then 
                    currReplaceStr[i][2] = currReplaceStr[i][2] + currReplaceStr[i][5]
                end
            else -- normal addition/ increment
                currReplaceStr[i][2] = currReplaceStr[i][2] + 1
            end
            
        elseif currReplaceStr[i][1]:find("/M") then
            newName = string.gsub(newName, currReplaceStr[i][1], joshnt.midiNotes[currReplaceStr[i][2][1]]..currReplaceStr[i][2][2])
            if joshnt.midiNotes[currReplaceStr[i][2][1]] == "B" then
                currReplaceStr[i][2][2] = currReplaceStr[i][2][2] + 1
            end
            currReplaceStr[i][2][1] = (currReplaceStr[i][2][1] %12) + 1
        elseif currReplaceStr[i][1]:find("/O") then
            if oldName then
                newName = string.gsub(newName, currReplaceStr[i][1], oldName)
            else
                newName = string.gsub(newName, currReplaceStr[i][1], currReplaceStr[i][2])
            end
        end
    end

    


    if RMXIndex ~= 0 then 
        joshnt_UniqueRegions.regionName_Rename = newName
    else
        joshnt_UniqueRegions.name_RMX_Rename[RMXIndex] = newName
    end

end

-- Call from outside
-- Main function
function joshnt_UniqueRegions.main()
    joshnt_UniqueRegions.numItems = reaper.CountSelectedMediaItems(0)
    if joshnt_UniqueRegions.numItems == 0 then 
        reaper.ShowMessageBox("No items selected!", "Error", 0)
        return 
    end

    joshnt_UniqueRegions.space_in_between = math.abs(joshnt_UniqueRegions.space_in_between)
    joshnt_UniqueRegions.start_silence = math.abs(joshnt_UniqueRegions.start_silence)
    joshnt_UniqueRegions.end_silence = math.abs(joshnt_UniqueRegions.end_silence)
    joshnt_UniqueRegions.boolNeedActivateEnvelopeOption = reaper.GetToggleCommandState(40070) == 0

    joshnt_UniqueRegions.wildcardsCheck(0) -- child rgn = fucntion call without argument
    for i = 1, #joshnt_UniqueRegions.name_RMX do
        joshnt_UniqueRegions.wildcardsCheck(i)
    end
    joshnt_UniqueRegions.regionName_Rename = joshnt_UniqueRegions.regionName

    reaper.PreventUIRefresh(1) 
    reaper.Undo_BeginBlock()  
    local originalRippleEditState = joshnt.getRippleEditingMode()
    if joshnt_UniqueRegions.boolNeedActivateEnvelopeOption then
        reaper.Main_OnCommand(40070, 0)
    end
    joshnt_UniqueRegions.sortItemsByTracks()
    
    --get locked Items and unlock them
    joshnt_UniqueRegions.lockedItems = joshnt.saveLockedItems()
    joshnt.lockItemsState(joshnt_UniqueRegions.lockedItems,0)
    -- remove selected items from locked item array
    if joshnt_UniqueRegions.lockedItems and joshnt_UniqueRegions.lockedItems ~= {} then
        local i = 1
        while i <= #joshnt_UniqueRegions.lockedItems do
            local item = joshnt_UniqueRegions.lockedItems[i]
            if reaper.IsMediaItemSelected(item) then
                table.remove(joshnt_UniqueRegions.lockedItems, i)
            else
                i = i + 1
            end
        end
    end

    -- get all parent Tracks
    local parentTracks = joshnt.getParentTracksWithoutDuplicates(joshnt_UniqueRegions.trackIDs)

    if parentTracks[1] == nil and (joshnt_UniqueRegions.RRMLink_Child == 2 or joshnt_UniqueRegions.RRMLink_Child == 3 or joshnt_UniqueRegions.RRMLink_Child == 4) then -- falls keine Parents, Master als RRM
        joshnt_UniqueRegions.RRMLink_Child = 1
    elseif joshnt_UniqueRegions.RRMLink_Child == 2 or joshnt_UniqueRegions.RRMLink_Child == 3 then -- if not first parent per item
        local commonParents = {}
        for i = 1, #parentTracks do
            if (joshnt_UniqueRegions.RRMLink_Child == 2 or joshnt_UniqueRegions.RRMLink_Child == 3) and joshnt.isAnyParentOfAllSelectedItems(parentTracks[i]) then
                commonParents[#commonParents + 1] = parentTracks[i]
            end

        end

        -- set RRM ParentTrack
        if commonParents[1] then
            joshnt_UniqueRegions.parentTrackForRRM = commonParents[1]
        end
        for i = 1, #commonParents do
            if joshnt_UniqueRegions.RRMLink_Child == 2 then -- highest common parent
                if reaper.GetMediaTrackInfo_Value(commonParents[i], "IP_TRACKNUMBER") < reaper.GetMediaTrackInfo_Value(joshnt_UniqueRegions.parentTrackForRRM, "IP_TRACKNUMBER") then
                    joshnt_UniqueRegions.parentTrackForRRM = commonParents[i]
                end
            elseif joshnt_UniqueRegions.RRMLink_Child == 3 then -- first common parent
                if reaper.GetMediaTrackInfo_Value(commonParents[i], "IP_TRACKNUMBER") > reaper.GetMediaTrackInfo_Value(joshnt_UniqueRegions.parentTrackForRRM, "IP_TRACKNUMBER") then
                    joshnt_UniqueRegions.parentTrackForRRM = commonParents[i]
                end
            end
        end

        -- check if highest parent is any parent of all Tracks of selected items
        if (joshnt_UniqueRegions.RRMLink_Child == 2 or joshnt_UniqueRegions.RRMLink_Child == 3) and joshnt_UniqueRegions.parentTrackForRRM == nil then
            joshnt_UniqueRegions.RRMLink_Child = 1 -- set to master
        end

    end
    

    -- isolate
    if joshnt_UniqueRegions.isolateItems == 1 then 
        local retval, itemTable = joshnt.isolate_MoveSelectedItems_InsertAtNextSilentPointInProject(joshnt_UniqueRegions.start_silence, joshnt_UniqueRegions.end_silence, joshnt_UniqueRegions.end_silence)
        if retval == 1 then joshnt.reselectItems(itemTable) end
        joshnt_UniqueRegions.sortItemsByTracks()
    elseif joshnt_UniqueRegions.isolateItems == 2 then 
        joshnt.isolate_MoveOtherItems_ToEndOfSelectedItems(joshnt_UniqueRegions.start_silence, joshnt_UniqueRegions.end_silence, joshnt_UniqueRegions.start_silence, joshnt_UniqueRegions.end_silence) 
    end

    joshnt_UniqueRegions.getItemGroups()
    if not joshnt_UniqueRegions.itemGroups then reaper.ShowConsoleMsg("\nNo Item groups found") return end
    if joshnt_UniqueRegions.repositionToggle then joshnt_UniqueRegions.adjustItemPositions() end
    joshnt.lockItemsState(joshnt_UniqueRegions.lockedItems,1)
    joshnt.setRippleEditingMode(originalRippleEditState)
    if joshnt_UniqueRegions.boolNeedActivateEnvelopeOption then
        reaper.Main_OnCommand(40070, 0)
    end

    if joshnt_UniqueRegions.lockBoolUser == true then
        joshnt.lockSelectedItems()
    end
    local childRegionIndex = nil 
    if joshnt_UniqueRegions.createChildRgn then childRegionIndex = joshnt_UniqueRegions.setRegionsForitemGroups() end
    if joshnt_UniqueRegions.createMotherRgn and joshnt_UniqueRegions.createChildRgn then joshnt_UniqueRegions.setMotherRegion(childRegionIndex) 
    elseif joshnt_UniqueRegions.createMotherRgn then joshnt_UniqueRegions.setMotherRegion(childRegionIndex) end
    -- todo warum hier if elseif

    -- todo add cleanup

    reaper.Undo_EndBlock("joshnt Create Regions", -1)

    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
end

-- Call from outside
function joshnt_UniqueRegions.Quit()
    joshnt_UniqueRegions = nil
end

return joshnt_UniqueRegions

