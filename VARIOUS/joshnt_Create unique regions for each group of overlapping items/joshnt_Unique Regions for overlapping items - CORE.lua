-- @noindex

joshnt_UniqueRegions = {}

function joshnt_UniqueRegions.Init()
    -- para global variables; accessed from other scripts/ user variables
    joshnt_UniqueRegions.repositionToggle = true
    -- unique because only relevant for group detection/ reposition
    joshnt_UniqueRegions.space_in_between = 0 -- Time in seconds
    joshnt_UniqueRegions.groupToleranceTime = 0  -- Time in seconds

    -- copy to all rgns if existing; dont rearrange! order specific in copy & paste settings
    joshnt_UniqueRegions.rgnProperties = {
        create = true,
        name = "",
        color = -1,
        RRMLink = 0, -- 1 = Master, 2 = Highest common Parent (all),  3 = First common Parent (all), 4 = First common parent (per item group), 5 = Parent (per item), 6 = Each Track, 0 = None
        start_silence = 0,
        end_silence = 0,
        -- subarray per modifier with {stringToSearchFor, curr Index of that count/ default replace[, modifier, modifierArgument1, modifierArgument2]}
        replaceString = { },
        rename = "",
        isRgn = true, -- RMX only: rgn or marker
        everyX = 1 -- RMX only: after x item groups
    }

    -- use joshnt_UniqueRegions.allRgnArray[#joshnt_UniqueRegions.allRgnArray] = joshnt.copyTable(joshnt_UniqueRegions.rgnProperties) for each new rgn rule set
    joshnt_UniqueRegions.allRgnArray = {} -- master array with sub arrays per "region Rule" with each having rgnProperties
    joshnt_UniqueRegions.allRgnArray[1] = joshnt.copyTable(joshnt_UniqueRegions.rgnProperties)

    joshnt_UniqueRegions.customWildCard = {
        [1] = {},
        [2] = {},
        [3] = {},
        [4] = {},
        [5] = {}
    } -- for /C; so far fixed length of 5 in GUI; code should be flexible for increase

    joshnt_UniqueRegions.isolateItems = 1 -- 1 = move selected, 2 = move others, 3 = dont move
    joshnt_UniqueRegions.lockBoolUser = false -- bool to lock items after movement
    joshnt_UniqueRegions.leadingZero = 2 -- use leading zero up to digit number x -> 2 = 10, 3 = 100

    -- GUI values only - only saved in external states, not txt or clipboard
    joshnt_UniqueRegions.previewTimeSelection = false
    joshnt_UniqueRegions.closeGUI = false

    -- only inside this script
    joshnt_UniqueRegions.boolNeedActivateEnvelopeOption = nil
    joshnt_UniqueRegions.t = {} -- Table to store items grouped by track
    joshnt_UniqueRegions.trackIDs = {} -- table trackIDs to access keys more easily
    joshnt_UniqueRegions.parentTracks = {}
    joshnt_UniqueRegions.numItems = 0
    joshnt_UniqueRegions.lockedItems = {}
    joshnt_UniqueRegions.highCom_Parent = nil
    joshnt_UniqueRegions.firstCom_Parent = nil
    -- global variables for grouping of items; used in getItemGroups()
    joshnt_UniqueRegions.itemGroups = {}
    joshnt_UniqueRegions.itemGroupsStartsArray = nil
    joshnt_UniqueRegions.itemGroupsEndArray = nil
    joshnt_UniqueRegions.nudgeValues = {}
    joshnt_UniqueRegions.maxStartSilence = 0
    joshnt_UniqueRegions.maxEndSilence = 0
end

function joshnt_UniqueRegions.InitBackend()
    for i = 1, #joshnt_UniqueRegions.allRgnArray do
        joshnt_UniqueRegions.allRgnArray[i]["replaceString"] = {}
        joshnt_UniqueRegions.allRgnArray[i]["rename"] = ""
    end
    joshnt_UniqueRegions.boolNeedActivateEnvelopeOption = nil
    joshnt_UniqueRegions.t = {}
    joshnt_UniqueRegions.trackIDs = {}
    joshnt_UniqueRegions.parentTracks = {}
    joshnt_UniqueRegions.numItems = 0
    joshnt_UniqueRegions.lockedItems = {}

    joshnt_UniqueRegions.itemGroups = {}
    joshnt_UniqueRegions.itemGroupsStartsArray = nil
    joshnt_UniqueRegions.itemGroupsEndArray = nil
    joshnt_UniqueRegions.nudgeValues = {}
    joshnt_UniqueRegions.highCom_Parent = nil
    joshnt_UniqueRegions.firstCom_Parent = nil
    joshnt_UniqueRegions.maxStartSilence = 0
    joshnt_UniqueRegions.maxEndSilence = 0
end

joshnt_UniqueRegions.Init()


-- SAVING & LOADING SETTINGS
function joshnt_UniqueRegions.getDefaults()
    -- get general settings
    if reaper.HasExtState("joshnt_UniqueRegions", "GeneralSettings") then
        local tempArray = joshnt.splitStringToTable(reaper.GetExtState("joshnt_UniqueRegions", "GeneralSettings"))
        joshnt_UniqueRegions.isolateItems = tonumber(tempArray[1])
        joshnt_UniqueRegions.space_in_between = tonumber(tempArray[2])
        joshnt_UniqueRegions.lockBoolUser = tempArray[3] == "true"
        joshnt_UniqueRegions.groupToleranceTime = tonumber(tempArray[4])
        joshnt_UniqueRegions.repositionToggle = tempArray[5] == "true"
        joshnt_UniqueRegions.leadingZero = tonumber(tempArray[6])
    end

    local counter = 1
    -- search region specific defaults
    while true do
        if not reaper.HasExtState("joshnt_UniqueRegions", "region"..counter) then break end
        local tempArray = joshnt.splitStringToTable(reaper.GetExtState("joshnt_UniqueRegions", "region"..counter))
        joshnt_UniqueRegions.setRgnSettingsFromTable(counter, tempArray)
        counter = counter + 1
    end

    counter = 1
    -- search region specific defaults
    while true do
        if not reaper.HasExtState("joshnt_UniqueRegions", "customWildCard"..counter) then break end
        local tempArray = joshnt.splitStringToTable(reaper.GetExtState("joshnt_UniqueRegions", "customWildCard"..counter))
        joshnt_UniqueRegions.customWildCard[counter] = {}
        joshnt.copyTableValues(tempArray, joshnt_UniqueRegions.customWildCard[counter])
        counter = counter + 1
    end

    if reaper.HasExtState("joshnt_UniqueRegions", "OptionsGUI") then
        local tempArray = joshnt.splitStringToTable(reaper.GetExtState("joshnt_UniqueRegions", "OptionsGUI"..counter))
        joshnt_UniqueRegions.previewTimeSelection = tempArray[1]
        joshnt_UniqueRegions.closeGUI = tempArray[1]
    end
end

function joshnt_UniqueRegions.saveDefaults()
    -- General Settings
    reaper.SetExtState("joshnt_UniqueRegions", "GeneralSettings", joshnt_UniqueRegions.isolateItems..","..joshnt_UniqueRegions.space_in_between..","..tostring(joshnt_UniqueRegions.lockBoolUser)..","..joshnt_UniqueRegions.groupToleranceTime..","..tostring(joshnt_UniqueRegions.repositionToggle..","..joshnt_UniqueRegions.leadingZero), true)
    
    -- region specific settings
    for i = 1, #joshnt_UniqueRegions.allRgnArray do
        reaper.SetExtState("joshnt_UniqueRegions", "region"..i, joshnt_UniqueRegions.getRgnSettingsAsString(i))
    end
    
    -- custom Wildcards for /C
    for i = 1, #joshnt_UniqueRegions.customWildCard do
        reaper.SetExtState("joshnt_UniqueRegions", "customWildCard"..i, joshnt.tableToCSVString(joshnt_UniqueRegions.customWildCard[i]))
    end

    reaper.SetExtState("joshnt_UniqueRegions", "OptionsGUI", tostring(joshnt_UniqueRegions.previewTimeSelection)..","..tostring(joshnt_UniqueRegions.closeGUI), true)
end

function joshnt_UniqueRegions.getRgnSettingsAsString(i, rgnString)
    rgnString = rgnString or ""
    local tempName = tostring(joshnt_UniqueRegions.allRgnArray[i]["name"])
    if tempName == "" then tempName = "_joshnt.EMPTY_" end
    rgnString = rgnString .. tostring(joshnt_UniqueRegions.allRgnArray[i]["create"])..","
    rgnString = rgnString .. tempName ..","
    rgnString = rgnString .. tostring(joshnt_UniqueRegions.allRgnArray[i]["color"])..","
    rgnString = rgnString .. tostring(joshnt_UniqueRegions.allRgnArray[i]["RRMLink"])..","
    rgnString = rgnString .. tostring(joshnt_UniqueRegions.allRgnArray[i]["start_silence"])..","
    rgnString = rgnString .. tostring(joshnt_UniqueRegions.allRgnArray[i]["end_silence"])..","
    rgnString = rgnString .. tostring(joshnt_UniqueRegions.allRgnArray[i]["isRgn"])..","
    rgnString = rgnString .. tostring(joshnt_UniqueRegions.allRgnArray[i]["everyX"])
    return rgnString
end

function joshnt_UniqueRegions.setRgnSettingsFromTable(i, rgnSettingTable)
    
    joshnt_UniqueRegions.allRgnArray[i] = {}
    for j, value in ipairs(rgnSettingTable) do -- proper reassign from array to table with keys, s. strict sorting in "getRgnSettingsAsString"
        if j == 1 then joshnt_UniqueRegions.allRgnArray[i]["create"] = value == "true"
        elseif j == 2 then 
            if value == "_joshnt.EMPTY_" then joshnt_UniqueRegions.allRgnArray[i]["name"] = ""
            else joshnt_UniqueRegions.allRgnArray[i]["name"] = value end
        elseif j == 3 then joshnt_UniqueRegions.allRgnArray[i]["color"] = tonumber(value)
        elseif j == 4 then joshnt_UniqueRegions.allRgnArray[i]["RRMLink"] = tonumber(value)
        elseif j == 5 then joshnt_UniqueRegions.allRgnArray[i]["start_silence"] = tonumber(value)
        elseif j == 6 then joshnt_UniqueRegions.allRgnArray[i]["end_silence"] = tonumber(value)
        elseif j == 7 then joshnt_UniqueRegions.allRgnArray[i]["isRgn"] = value == "true"
        elseif j == 8 then joshnt_UniqueRegions.allRgnArray[i]["everyX"] = tonumber(value)
        end
    end
end

-- get String of all Settings
function joshnt_UniqueRegions.getSettingsString()
    local str = ""
    -- general Settings - adding more settings here will change the index of regions and wildcards array!
    local general = {
        joshnt_UniqueRegions.isolateItems,
        joshnt_UniqueRegions.space_in_between,
        tostring(joshnt_UniqueRegions.lockBoolUser),
        joshnt_UniqueRegions.groupToleranceTime,
        tostring(joshnt_UniqueRegions.repositionToggle)
    }
    str = joshnt.tableToCSVString(general)

    -- regions - additional array on index 6 in output string-array
    -- strict sorting
    local rgnString = ""
    for i = 1, #joshnt_UniqueRegions.allRgnArray do
        rgnString = rgnString.."{"
        rgnString = joshnt_UniqueRegions.getRgnSettingsAsString(i, rgnString)
        rgnString = rgnString.."}"..","
    end
    rgnString = string.sub(rgnString, 1, -2) -- remove last ,

    str = str..",".."{"..rgnString.."}"

    -- customWildCards - additional array on index 7 in output string-array
    str = str..",".."{"..joshnt.tableToCSVString(joshnt_UniqueRegions.customWildCard).."}"
    
    str = str..","..joshnt_UniqueRegions.leadingZero

    return str
end

-- decode Settings string back to properties
function joshnt_UniqueRegions.setSettingsByString(str)
    local settingsArray = joshnt.fromCSV(str)
    if settingsArray and #settingsArray == 8 then

        -- general
        joshnt_UniqueRegions.isolateItems = tonumber(settingsArray[1])
        joshnt_UniqueRegions.space_in_between = tonumber(settingsArray[2])
        joshnt_UniqueRegions.lockBoolUser = settingsArray[3] == "true"
        joshnt_UniqueRegions.groupToleranceTime = tonumber(settingsArray[4])
        joshnt_UniqueRegions.repositionToggle = settingsArray[5] == "true"
        joshnt_UniqueRegions.leadingZero = tonumber(settingsArray[8])

        -- regions
        for i = 1, #settingsArray[6] do
            joshnt_UniqueRegions.setRgnSettingsFromTable(i, settingsArray[6][i])
        end

        -- custom wildcards
        for i = 1, #settingsArray[7] do
            joshnt_UniqueRegions.customWildCard[i] = settingsArray[7][i]
        end
        if not joshnt_UniqueRegions.verifySettings() then joshnt_UniqueRegions.init() end
        return true
    else
        joshnt.TooltipAtMouse("Tried to paste wrong/ corrupt settings.\nNo Settings have been changed.")
        return false
    end
end

function joshnt_UniqueRegions.settingsToClipboard()
    local str = joshnt_UniqueRegions.getSettingsString()
    reaper.CF_SetClipboard(str)
end

function joshnt_UniqueRegions.settingsFromClipboard()
    local clipboardContent = reaper.CF_GetClipboard()
    if clipboardContent then
        return joshnt_UniqueRegions.setSettingsByString(clipboardContent)
    else
        joshnt.TooltipAtMouse("Clipboard is empty or not accessible.\nNo Settings have been changed.")
        return false
    end

end

function joshnt_UniqueRegions.writeSettingsToFile()
    local str = joshnt_UniqueRegions.getSettingsString()
    joshnt.toNewTXT(str, "UniqueRegions_Settings")
end

function joshnt_UniqueRegions.readSettingsFromFile()
    local retval, settings = joshnt.readFromTXT("UniqueRegions_Settings")
    if retval == 1 and settings ~= "" then
        return joshnt_UniqueRegions.setSettingsByString(settings)
    else
        joshnt.TooltipAtMouse("Failed to read settings from file.")
        return false
    end
end

function joshnt_UniqueRegions.verifySettings()
    local foundError = false

    if 
    not type(joshnt_UniqueRegions.repositionToggle) == "boolean" or
    not type(joshnt_UniqueRegions.lockBoolUser) == "boolean" or
    not type(joshnt_UniqueRegions.space_in_between) == "number" or
    not type(joshnt_UniqueRegions.groupToleranceTime) == "number" or
    not type(joshnt_UniqueRegions.isolateItems) == "number" or
    not type(joshnt_UniqueRegions.leadingZero) == "number" 
    then foundError = true end

    if not foundError then
        for i = 1, #joshnt_UniqueRegions.customWildCard do
            for j = 1, #joshnt_UniqueRegions.customWildCard[i] do
                if joshnt_UniqueRegions.customWildCard[i][j] and not type(joshnt_UniqueRegions.customWildCard[i][j]) == "string" then
                    joshnt_UniqueRegions.customWildCard[i][j] = tostring(joshnt_UniqueRegions.customWildCard[i][j])
                    if not type(joshnt_UniqueRegions.customWildCard[i][j]) == "string" then foundError = true break end
                end
            end
        end
    end

    if not foundError then
        for i = 1, #joshnt_UniqueRegions.allRgnArray do
            if not type(joshnt_UniqueRegions.allRgnArray[i]["create"]) == "bool" or
            not type(joshnt_UniqueRegions.allRgnArray[i]["name"]) == "string" or
            not type(joshnt_UniqueRegions.allRgnArray[i]["color"]) == "number" or
            not type(joshnt_UniqueRegions.allRgnArray[i]["RRMLink"]) == "number" or
            not type(joshnt_UniqueRegions.allRgnArray[i]["start_silence"]) == "number" or
            not type(joshnt_UniqueRegions.allRgnArray[i]["end_silence"]) == "number" or
            not type(joshnt_UniqueRegions.allRgnArray[i]["isRgn"]) == "bool" or
            not type(joshnt_UniqueRegions.allRgnArray[i]["everyX"]) == "number"
            then foundError = true break end
        end
    end

    if foundError == true then
        reaper.MB("IMPORT SETTINGS ERROR\n\nFound no/ corrupt/ wrong data, consider rebuilding your preset.", "IMPORT ERROR", 0)
        return false
    else
        joshnt.TooltipAtMouse("Settings loaded successfully!")
        return true
    end

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


end

-- function to get the item groups
function joshnt_UniqueRegions.getItemGroups()
    joshnt_UniqueRegions.itemGroups, joshnt_UniqueRegions.itemGroupsStartsArray, joshnt_UniqueRegions.itemGroupsEndArray = joshnt.getOverlappingItemGroupsOfSelectedItems(joshnt_UniqueRegions.groupToleranceTime)
    if joshnt_UniqueRegions.itemGroups and joshnt_UniqueRegions.itemGroupsStartsArray and joshnt_UniqueRegions.itemGroupsEndArray then
        for i = 1, #joshnt_UniqueRegions.itemGroups do
            if i > 1 then
                joshnt_UniqueRegions.nudgeValues[i] = joshnt_UniqueRegions.space_in_between - ((joshnt_UniqueRegions.itemGroupsStartsArray[i] - joshnt_UniqueRegions.maxStartSilence) - (joshnt_UniqueRegions.itemGroupsEndArray[i-1] + joshnt_UniqueRegions.maxEndSilence))
            else 
                joshnt_UniqueRegions.nudgeValues[i] = 0
            end
        end
    end
end
    


-- Function to adjust item positions/ move them
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

function joshnt_UniqueRegions.repositionMarker(allRgnArrayIndex, startTime, ignoreMrkTable)

    local startTimeOffset = joshnt_UniqueRegions.allRgnArray[allRgnArrayIndex]["start_silence"]

    -- Find marker which is most likely the existing one
    local function getClosestPossibleMarker(timeInput, searchRange, mrkTable)
        mrkTable = mrkTable or {}
        local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
        local num_total = num_markers + num_regions
        local targetMrk = nil
        local mrkPos = 0
        local name = ""
        local offsetToTarget = math.huge
        for j=0, num_total - 1 do
          local retval, isrgn, pos, _, nameTEMP, markrgnindexnumber = reaper.EnumProjectMarkers( j )
          local offsetToTarget_TEMP = nil
          if retval and not isrgn and not joshnt.tableContainsVal(mrkTable, markrgnindexnumber) then -- check if marker and not to exclude from search
            if pos <= timeInput+searchRange and pos >= timeInput-searchRange then -- check for overlap in timeframe
                offsetToTarget_TEMP = math.abs(pos-timeInput)
              if offsetToTarget > offsetToTarget_TEMP then
                offsetToTarget = offsetToTarget_TEMP
                targetMrk = markrgnindexnumber
                mrkPos = pos
                name = nameTEMP
              end
            end
          end
        end
        return targetMrk, mrkPos, name
    end

    local mrkIndex, mrkPos, name = getClosestPossibleMarker(startTime - startTimeOffset, startTimeOffset+1, ignoreMrkTable)
    if not mrkIndex then return end
    joshnt_UniqueRegions.updateRgnRename(allRgnArrayIndex, name)
    local mrkNameReference = joshnt_UniqueRegions.allRgnArray[allRgnArrayIndex]["rename"]
    local mrkColor = joshnt_UniqueRegions.allRgnArray[allRgnArrayIndex]["color"]

    if startTime - startTimeOffset < 0 then
        startTime = 0
    end
  
    -- Move overlapping region
    if mrkColor ~= -1 then
        reaper.SetProjectMarker3(0, mrkIndex, false, startTime - startTimeOffset, _, mrkNameReference, mrkColor | 0x1000000) 
    else
        reaper.SetProjectMarker( mrkIndex, false, startTime - startTimeOffset, _, mrkNameReference )
    end
    return mrkIndex

end

-- function to adjust existing region over selected items
function joshnt_UniqueRegions.setRegionLength(allRgnArrayIndex, start_time, end_time, ignoreRgnArray)

    start_time = start_time - joshnt_UniqueRegions.allRgnArray[allRgnArrayIndex]["start_silence"]
    end_time = end_time + joshnt_UniqueRegions.allRgnArray[allRgnArrayIndex]["end_silence"]

    -- Find region with most overlap
    local region_to_move, _, _, rgnName = joshnt.getMostOverlappingRegion(start_time,end_time, ignoreRgnArray)
    joshnt_UniqueRegions.updateRgnRename(allRgnArrayIndex, rgnName)

    if start_time < 0 then
        reaper.GetSet_LoopTimeRange(true, false, 0, math.abs(start_time), false)
        reaper.Main_OnCommand(40200, 0)
        end_time = end_time + math.abs(start_time)
        start_time = 0
    end
  
    local rgnNameReference = joshnt_UniqueRegions.allRgnArray[allRgnArrayIndex]["rename"]
    local rgnColor = joshnt_UniqueRegions.allRgnArray[allRgnArrayIndex]["color"]

    -- Move overlapping region
    if rgnColor ~= -1 then
        reaper.SetProjectMarker3(0, region_to_move, true, start_time, end_time, rgnNameReference, rgnColor | 0x1000000) 
    else
        reaper.SetProjectMarker( region_to_move, true, start_time, end_time, rgnNameReference )
    end

    return region_to_move
end

-- create marker function
function joshnt_UniqueRegions.createMarker(allRgnArrayIndex, startTime)
    -- Offset the marker by userinput
    startTime = startTime - joshnt_UniqueRegions.allRgnArray[allRgnArrayIndex]["start_silence"]
    
    if startTime < 0 then
        startTime = 0
    end

    joshnt_UniqueRegions.updateRgnRename(allRgnArrayIndex)
    -- Create the region
    local colorTEMP = 0;
    if joshnt_UniqueRegions.allRgnArray[allRgnArrayIndex]["color"] ~= -1 then colorTEMP = joshnt_UniqueRegions.allRgnArray[allRgnArrayIndex]["color"] | 0x1000000 end
    return reaper.AddProjectMarker2(0, false, startTime, 0, joshnt_UniqueRegions.allRgnArray[allRgnArrayIndex]["rename"], -1, colorTEMP)
end

-- Function to create a region over selected items
function joshnt_UniqueRegions.createRegionOverItems(allRgnArrayIndex,startTime, endTime)
    -- Extend the region by userinput
    startTime = startTime - joshnt_UniqueRegions.allRgnArray[allRgnArrayIndex]["start_silence"]
    endTime = endTime + joshnt_UniqueRegions.allRgnArray[allRgnArrayIndex]["end_silence"]
    
    if startTime < 0 then
        reaper.GetSet_LoopTimeRange(true, false, startTime + joshnt_UniqueRegions.allRgnArray[allRgnArrayIndex]["start_silence"], startTime + joshnt_UniqueRegions.allRgnArray[allRgnArrayIndex]["start_silence"] + math.abs(startTime), false)
        reaper.Main_OnCommand(40200, 0)
        endTime = endTime - startTime
        startTime = 0
    end

    joshnt_UniqueRegions.updateRgnRename(allRgnArrayIndex)
    -- Create the region
    local colorTEMP = 0;
    if joshnt_UniqueRegions.allRgnArray[allRgnArrayIndex]["color"] ~= -1 then colorTEMP = joshnt_UniqueRegions.allRgnArray[allRgnArrayIndex]["color"] | 0x1000000 end
    return reaper.AddProjectMarker2(0, true, startTime, endTime, joshnt_UniqueRegions.allRgnArray[allRgnArrayIndex]["rename"], -1, colorTEMP)
end

function joshnt_UniqueRegions.createRRMLink(allRgnIndex,rgnIndex)
    if joshnt_UniqueRegions.allRgnArray[allRgnIndex]["RRMLink"] == 2 then -- highest common parent 
        reaper.SetRegionRenderMatrix(0, rgnIndex,joshnt_UniqueRegions.highCom_Parent,1)
    elseif joshnt_UniqueRegions.allRgnArray[allRgnIndex]["RRMLink"] == 3 then -- first common parent
        reaper.SetRegionRenderMatrix(0, rgnIndex,joshnt_UniqueRegions.firstCom_Parent,1)
    elseif joshnt_UniqueRegions.allRgnArray[allRgnIndex]["RRMLink"] == 4 then -- parent per item group 
        local _, firstCommonParent = joshnt.getSpecificParentOfSelectedItems(joshnt_UniqueRegions.parentTracks)
        reaper.SetRegionRenderMatrix(0, rgnIndex, firstCommonParent, 1)
    elseif joshnt_UniqueRegions.allRgnArray[allRgnIndex]["RRMLink"] == 5 then -- parent track per item
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
    elseif joshnt_UniqueRegions.allRgnArray[allRgnIndex]["RRMLink"] == 1 then -- Master track
        reaper.SetRegionRenderMatrix(0, rgnIndex,reaper.GetMasterTrack(0),1)
    elseif joshnt_UniqueRegions.allRgnArray[allRgnIndex]["RRMLink"] == 6 then -- indiv. tracks
        local groupTracks = joshnt.getTracksOfSelectedItems()
        for _, track in ipairs (groupTracks) do
            reaper.SetRegionRenderMatrix(0, rgnIndex,track,1)
        end
    end   
end

function joshnt_UniqueRegions.setSubRegions(allRgnArrayIndex, newRgnTable)
    local currEveryX = joshnt_UniqueRegions.allRgnArray[allRgnArrayIndex]["everyX"]

    local function callRegionCheck()
        local currSelStart_TEMP, currSelEnd_TEMP = joshnt.startAndEndOfSelectedItems()
        local regionIndex_TEMP = nil

        if joshnt.checkOverlapWithRegions(currSelStart_TEMP, currSelEnd_TEMP, newRgnTable) then regionIndex_TEMP = joshnt_UniqueRegions.setRegionLength(allRgnArrayIndex, currSelStart_TEMP, currSelEnd_TEMP, newRgnTable)
        else regionIndex_TEMP = joshnt_UniqueRegions.createRegionOverItems(allRgnArrayIndex, currSelStart_TEMP, currSelEnd_TEMP)
        end
        
        joshnt_UniqueRegions.createRRMLink(allRgnArrayIndex, regionIndex_TEMP)

        table.insert(newRgnTable,regionIndex_TEMP)
    end



    if currEveryX == 0 then -- if region over all items
        for i = 1, #joshnt_UniqueRegions.itemGroups do
            joshnt.reselectItems(joshnt_UniqueRegions.itemGroups[i])
        end
        callRegionCheck()
    else
        for i = 0, (#joshnt_UniqueRegions.itemGroups)/ currEveryX do
            if i >= #joshnt_UniqueRegions.itemGroups/ currEveryX then break end
            reaper.SelectAllMediaItems(0, false)
            for j = 1, currEveryX do
                local currInd = i*currEveryX + j
                if currInd <= #joshnt_UniqueRegions.itemGroups then
                    joshnt.reselectItems(joshnt_UniqueRegions.itemGroups[currInd])
                end
            end
                
            callRegionCheck()

        end
    end
  return newRgnTable
end

function joshnt_UniqueRegions.setSubMarkers(allRgnArrayIndex, newMarkerTable)
    local currEveryX = joshnt_UniqueRegions.allRgnArray[allRgnArrayIndex]["everyX"]

    for i = 0, #joshnt_UniqueRegions.itemGroups do
        local currInd = i*currEveryX + 1
        if currInd > #joshnt_UniqueRegions.itemGroups then break end
        reaper.SelectAllMediaItems(0, false)
        joshnt.reselectItems(joshnt_UniqueRegions.itemGroups[currInd])

        local currSelStart_TEMP, _ = joshnt.startAndEndOfSelectedItems()
        local mrkIndex_TEMP = nil

        mrkIndex_TEMP = joshnt_UniqueRegions.repositionMarker(allRgnArrayIndex, currSelStart_TEMP, newMarkerTable)
        if mrkIndex_TEMP == nil then
            mrkIndex_TEMP = joshnt_UniqueRegions.createMarker(allRgnArrayIndex, currSelStart_TEMP)
        end
        
        if mrkIndex_TEMP == -1 or mrkIndex_TEMP == nil then
            reaper.ShowConsoleMsg("\nFailed to create Marker for RMX Ruleset "..allRgnArrayIndex.." at index "..i)
        end

        table.insert(newMarkerTable, mrkIndex_TEMP)

        if currEveryX == 0 then break end
    end
  return newMarkerTable
end

-- all wildcard-Functions look a bit weird with the if as RMX regions and more wildcards got added later
-- all replace Strings will be used in a gmatch -> weird syntax
-- check for /E's in region names
function joshnt_UniqueRegions.wildcardsCheck_E(currName, currReplaceStr)
    -- Check for "/E('Number')" - normal enumerate
    for number in currName:gmatch("/E%((%d+)%)") do
        local number1Num = tonumber(number)
        if number1Num then
            currReplaceStr[#currReplaceStr + 1] = {}  
            currReplaceStr[#currReplaceStr][1] = "/E%("..number.."%)"
            currReplaceStr[#currReplaceStr][2] = number1Num
        end
    end

    -- Check for "/E('Number1'%'Number2')" - modulu enumerate 
    for number1, number2 in currName:gmatch("/E%((%d+)%%(%d+)%)") do
        local number1Num, number2Num = tonumber(number1), tonumber(number2)
        if number1Num and number2Num then
            currReplaceStr[#currReplaceStr + 1] = {}  
            currReplaceStr[#currReplaceStr][1] = "/E%("..number1.."%%"..number2.."%)"
            currReplaceStr[#currReplaceStr][2] = number1Num % number2Num
            currReplaceStr[#currReplaceStr][3] = "%"
            currReplaceStr[#currReplaceStr][4] = number2Num
        end
    end
    
    -- Check for "/E('Number1'%'Number2''offset')" - modulu enumerate with offset
    for number1, number2, offset in currName:gmatch("/E%((%d+)%%(%d+)([+-]%d+)%)") do
        local number1Num, number2Num, offsetNum = tonumber(number1), tonumber(number2), tonumber(offset)
        if number1Num and number2Num and offsetNum then
            currReplaceStr[#currReplaceStr + 1] = {}  
            currReplaceStr[#currReplaceStr][1] = "/E%("..number1.."%%"..number2.."%"..offset.."%)"
            currReplaceStr[#currReplaceStr][2] = number1Num % number2Num + offsetNum
            currReplaceStr[#currReplaceStr][3] = "%"
            currReplaceStr[#currReplaceStr][4] = number2Num
            currReplaceStr[#currReplaceStr][5] = offsetNum
        end
    end

    return currReplaceStr
end

-- check for /M's in region name
function joshnt_UniqueRegions.wildcardsCheck_M(currName, currReplaceStr)
    -- Check for "/M('MidiNote')" - normal stepsize
    for midiNote, octave in currName:gmatch("/M%((..?)([+-]?%d+)%)") do
        local octaveNum = tonumber(octave)
        local midiNoteIndex = joshnt.findIndex(joshnt.midiNotes, midiNote)
        if octaveNum and midiNoteIndex then
            currReplaceStr[#currReplaceStr + 1] = {}  
            currReplaceStr[#currReplaceStr][1] = "/M%("..midiNote..octave.."%)"
            currReplaceStr[#currReplaceStr][2] = {joshnt.findIndex(joshnt.midiNotes, midiNote), octave}
        end
    end

    -- Check for "/M('MidiNote','stepsize')" - custom stepsize
    for midiNote, octave, stepSize in currName:gmatch(("/M%((..?)([+-]?%d+):%s*([+-]?%d+)%)")) do
        local stepSizeNum = tonumber(stepSize) -- avoid getting some random swobi input
        local octaveNum = tonumber(octave)
        local midiNoteIndex = joshnt.findIndex(joshnt.midiNotes, midiNote)
        if stepSizeNum and octaveNum and midiNoteIndex then
            currReplaceStr[#currReplaceStr + 1] = {}  
            currReplaceStr[#currReplaceStr][1] = "/M%("..midiNote..octave..":"..stepSize.."%)"
            currReplaceStr[#currReplaceStr][2] = {midiNoteIndex, octaveNum}
            currReplaceStr[#currReplaceStr][3] = "STEPSIZE"
            currReplaceStr[#currReplaceStr][4] = stepSizeNum
        end
    end

    return currReplaceStr
end

-- check for /O's in region name
function joshnt_UniqueRegions.wildcardsCheck_O(currName, currReplaceStr)
    -- Check for "/O('AlternativeName')"
    for alternativeName in currName:gmatch("/O%((.-)%)") do
        currReplaceStr[#currReplaceStr + 1] = {}  
        currReplaceStr[#currReplaceStr][1] = "/O%("..alternativeName.."%)"
        currReplaceStr[#currReplaceStr][2] = alternativeName
    end

    return currReplaceStr
end

-- check for /C's in region name
function joshnt_UniqueRegions.wildcardsCheck_C(currName, currReplaceStr)
    -- Check for "/C('customWildCard')"
    for customTableNum in currName:gmatch("/C%(([+-]?%d+)%)") do
        local index = tonumber(customTableNum)
        if index and joshnt_UniqueRegions.customWildCard[index][1] then
            currReplaceStr[#currReplaceStr + 1] = {}  
            currReplaceStr[#currReplaceStr][1] = "/C%("..customTableNum.."%)"
            currReplaceStr[#currReplaceStr][2] = 1 -- curr index to count from
            currReplaceStr[#currReplaceStr][3] = index -- index of overall table at 3
        end
    end

    return currReplaceStr
end

function joshnt_UniqueRegions.wildcardsCheck(rgnIndex) 
    if joshnt_UniqueRegions.allRgnArray[rgnIndex]["create"] == true then
        local currName = joshnt_UniqueRegions.allRgnArray[rgnIndex]["name"]
        local currReplaceStr = joshnt_UniqueRegions.allRgnArray[rgnIndex]["replaceString"]
        currReplaceStr = joshnt_UniqueRegions.wildcardsCheck_E(currName, currReplaceStr)
        currReplaceStr = joshnt_UniqueRegions.wildcardsCheck_M(currName, currReplaceStr)
        currReplaceStr = joshnt_UniqueRegions.wildcardsCheck_O(currName, currReplaceStr)
        currReplaceStr = joshnt_UniqueRegions.wildcardsCheck_C(currName, currReplaceStr)
    end
end

-- sets the desired name to the 'rename' property rgns/ markers, referenced by moving or creating functions
function joshnt_UniqueRegions.updateRgnRename(allRgnArrIndex, oldName)
    oldName = oldName or ""
    local currName = joshnt_UniqueRegions.allRgnArray[allRgnArrIndex]["name"]
    local currReplaceStr = joshnt_UniqueRegions.allRgnArray[allRgnArrIndex]["replaceString"]
    local newName = currName;

    -- index of currReplaceStr see at start of script with variable define
    for i = 1, #currReplaceStr do
        if currReplaceStr[i][1]:find("/E") then
            newName = string.gsub(newName, currReplaceStr[i][1], joshnt.addLeadingZero(currReplaceStr[i][2],joshnt_UniqueRegions.leadingZero)) 
            if currReplaceStr[i][3] == "%" then -- modulu addition/ increment
                -- offset for modulu, if set
                if currReplaceStr[i][5] then 
                    currReplaceStr[i][2] = (currReplaceStr[i][2] - currReplaceStr[i][5] + 1) % currReplaceStr[i][4]
                    currReplaceStr[i][2] = currReplaceStr[i][2] + currReplaceStr[i][5]
                else 
                    currReplaceStr[i][2] = (currReplaceStr[i][2] + 1) % currReplaceStr[i][4]
                end
                
            else -- normal addition/ increment
                currReplaceStr[i][2] = currReplaceStr[i][2] + 1
            end
            
        elseif currReplaceStr[i][1]:find("/M") then
            newName = string.gsub(newName, currReplaceStr[i][1], joshnt.midiNotes[currReplaceStr[i][2][1]]..currReplaceStr[i][2][2])
            local step = currReplaceStr[i][4] -- -1 wegen additional offset für modulo
            if step then step = step -1 else step = 0 end
            if currReplaceStr[i][2][1] + step+1 > 12 then
                currReplaceStr[i][2][2] = currReplaceStr[i][2][2] + 1
            end
            currReplaceStr[i][2][1] = (currReplaceStr[i][2][1] + step) %12 + 1
        elseif currReplaceStr[i][1]:find("/O") then
            if oldName ~= "" then
                newName = string.gsub(newName, currReplaceStr[i][1], oldName)
            else
                newName = string.gsub(newName, currReplaceStr[i][1], currReplaceStr[i][2])
            end
        elseif currReplaceStr[i][1]:find("/C") then
            local whichWildcardTable = joshnt_UniqueRegions.customWildCard[currReplaceStr[i][3]]
            local IndexInWildCardTable = currReplaceStr[i][2]
            newName = string.gsub(newName, currReplaceStr[i][1], whichWildcardTable[IndexInWildCardTable])
            currReplaceStr[i][2] = (IndexInWildCardTable%(#whichWildcardTable))+1
        end
    end
    joshnt_UniqueRegions.allRgnArray[allRgnArrIndex]["rename"] = newName
end

-- Call from outside
-- Main function
function joshnt_UniqueRegions.main()
    joshnt_UniqueRegions.InitBackend()

    joshnt_UniqueRegions.numItems = reaper.CountSelectedMediaItems(0)
    if joshnt_UniqueRegions.numItems == 0 then 
        reaper.ShowMessageBox("No items selected!", "Error", 0)
        return 
    end
    local noActive = true
    for i = 1, #joshnt_UniqueRegions.allRgnArray do
        if joshnt_UniqueRegions.allRgnArray[i]["create"] == true then 
            noActive = false
            break
        end
    end
    if noActive == true then 
        reaper.ShowMessageBox("No active Region-Creation Rule!", "Error", 0)
        return 
    end


    joshnt_UniqueRegions.space_in_between = math.abs(joshnt_UniqueRegions.space_in_between)
    for i, rgn in ipairs(joshnt_UniqueRegions.allRgnArray) do
        rgn.start_silence = math.abs(rgn.start_silence)
        rgn.end_silence = math.abs(rgn.end_silence)
    end  
    joshnt_UniqueRegions.boolNeedActivateEnvelopeOption = reaper.GetToggleCommandState(40070) == 0

    for i = 1, #joshnt_UniqueRegions.allRgnArray do 
        joshnt_UniqueRegions.wildcardsCheck(i)
        joshnt_UniqueRegions.allRgnArray[i]["rename"] = joshnt_UniqueRegions.allRgnArray[i]["name"]
    end

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
    joshnt_UniqueRegions.parentTracks = joshnt.getParentTracksWithoutDuplicates(joshnt_UniqueRegions.trackIDs)

    -- falls keine Parents, Master als RRM für alle rgns mit Parent link
    if joshnt_UniqueRegions.parentTracks[1] == nil then 
        for i, rgn in ipairs(joshnt_UniqueRegions.allRgnArray) do
            if rgn.RRMLink == 2 or rgn.RRMLink == 3 or rgn.RRMLink == 4 or rgn.RRMLink == 5 then
                rgn.RRMLink = 1
            end
        end        
    end

    -- find highest and first common parent
    -- only if necessary = any region as parent link
    local needsParent = false;

    for i, rgn in ipairs(joshnt_UniqueRegions.allRgnArray) do
        if rgn.RRMLink == 2 or rgn.RRMLink == 3 then
            needsParent = true;
            break;
        end
    end  
    if needsParent == true then
        joshnt_UniqueRegions.highCom_Parent, joshnt_UniqueRegions.firstCom_Parent = joshnt.getSpecificParentOfSelectedItems(joshnt_UniqueRegions.parentTracks)
        
        -- check if highest parent is any parent of all Tracks of selected items
        if joshnt_UniqueRegions.highCom_Parent == nil then
            for i, rgn in ipairs(joshnt_UniqueRegions.allRgnArray) do
                if rgn.RRMLink == 2 then
                    rgn.RRMLink = 1 -- set to master
                end
            end  
        end
        if joshnt_UniqueRegions.firstCom_Parent == nil then
            for i, rgn in ipairs(joshnt_UniqueRegions.allRgnArray) do
                if rgn.RRMLink == 3 then
                    rgn.RRMLink = 1 -- set to master
                end
            end  
        end
    end

    

    -- isolate
    joshnt_UniqueRegions.maxStartSilence, joshnt_UniqueRegions.maxEndSilence = 0, 0
    for i, rgn in ipairs(joshnt_UniqueRegions.allRgnArray) do
        joshnt_UniqueRegions.maxStartSilence = math.max(joshnt_UniqueRegions.maxStartSilence, rgn.start_silence)
        joshnt_UniqueRegions.maxEndSilence = math.max(joshnt_UniqueRegions.maxEndSilence, rgn.end_silence)
    end  
    if joshnt_UniqueRegions.isolateItems == 1 or joshnt_UniqueRegions.isolateItems == 2 then
        if joshnt_UniqueRegions.isolateItems == 1 then 
            local retval, itemTable = joshnt.isolate_MoveSelectedItems_InsertAtNextSilentPointInProject(joshnt_UniqueRegions.maxStartSilence, joshnt_UniqueRegions.maxEndSilence, joshnt_UniqueRegions.maxEndSilence)
            if retval == 1 then joshnt.reselectItems(itemTable) end
            joshnt_UniqueRegions.sortItemsByTracks()
        else
            joshnt.isolate_MoveOtherItems_ToEndOfSelectedItems(joshnt_UniqueRegions.maxStartSilence, joshnt_UniqueRegions.maxEndSilence, joshnt_UniqueRegions.maxStartSilence, joshnt_UniqueRegions.maxEndSilence) 
        end
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
    local newRgnTable = {}
    local newMrkTable = {}

    for i = 1, #joshnt_UniqueRegions.allRgnArray do
        if joshnt_UniqueRegions.allRgnArray[i]["create"] then

            if joshnt_UniqueRegions.allRgnArray[i]["isRgn"] then
                newRgnTable = joshnt_UniqueRegions.setSubRegions(i, newRgnTable)
            else 
                newMrkTable = joshnt_UniqueRegions.setSubMarkers(i, newMrkTable)
            end
        end
    end  

    -- add cleanup (alle nicht region spezifischen settings reseten)

    reaper.Undo_EndBlock("joshnt Create Regions", -1)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
end

-- Call from outside
function joshnt_UniqueRegions.Quit()
    joshnt_UniqueRegions = nil
end



return joshnt_UniqueRegions

