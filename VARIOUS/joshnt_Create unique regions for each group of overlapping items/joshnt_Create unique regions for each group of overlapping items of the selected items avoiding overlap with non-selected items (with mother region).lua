-- @description Unique Region per overlapping item bundle in selection (with Mother Region over them) - Game Audio/ SD Use
-- @version 1.1
-- @changelog
--  - added optional link to parent track
--  - reworked Top of Script to be more accessable for default parameter changes
--  - adjusted about section of script to explain parameters properly
--  - Both "chooseColor" and "ChooseColorMother" show the colorpicker, if there is anything (instead of only with "p")
--  - introduced "joshnt lua utilities" for shared functions + other optimisations
-- @author Joshnt
-- @about 
--    ## Unique Regions - Joshnt
--    **User input explanation:**
--    - Time before item group start: Time in seconds between region start and item group start (per region) (use numbers above 0)
--    - Time after item group end: Time in seconds between item group end and region end (per region) (use numbers above 0)
--    - Space between regions: space between each item group's region and the next (use numbers above 0)
--    - Lock items: write "y" to lock the items after adjusting the position
--    - Region names/ Mother Region name: Eachs overlapping item group region name; use the wildcard [$incrX] to start numbering the regions from X and increase it per region (e.g. "Footsteps_[$incr3]" would name the first region "Footsteps_03", the next "Footsteps_04", ...)
--    - Region Color/ Mother Region Color: input anything to open the REAPER's Color-Picker to color the region; leave empty to use default color
--    - Link to RRM: Input to create a link to the moved/ created region(s); Input can be "HP" for highest hierachy common parent track of selected Items, "P" for first common parent of selected items, "T" for each track if it has items in the region, "M" for Master-Track, "N" (or anything else) for no link to Region Render Matrix
--    
--
--    **Credits** to Aaron Cendan (for acendan_Set nearest regions edges to selected media items.lua; https://aaroncendan.me), David Arnoldy, Joshua Hank, Yannick Winter
--
--    **Usecase:**  
--    creating incremental numbered regions for single layered sounds (for e.g. game audio) - mother region possibly useful for reapers region render dialog and naming via $region(=name) 
--    Script creates regions for overlapping selected items (including beginning and end silence), adjusting the space between them, moving other non selected items away.

---------------------------------------
--------- USER CONFIG - EDIT ME -------
--- Default Values for input dialog ---
---------------------------------------

local isolateItems_USER = "move other" -- valid inputs are: move selected/ s/ sel, move other/ o/ other or anything else to not change the position of the items
local Time_Before_Item_Group_Start_USER = 0 -- Time in Milliseconds
local Time_After_Item_Group_End_USER = 0 -- Time in Milliseconds
local Space_Between_Regions_USER = 2000 -- Time in Milliseconds
local Lock_Items_USER = "n" -- "y" to lock moved items or anything else to not lock them
local Region_Name_USER = "_[$incr1]" -- Insert name as string between ""
local Mother_Region_Name_USER = "" -- Insert name as string between ""
local Region_Color_USER = "" -- Insert anything as string between "" to open colorpicker after the Userinput dialog
local Mother_Region_Color_USER = "" -- Insert anything as string between "" to open colorpicker after the Userinput dialog
local Link_To_RRM_USER = "M" -- "HP" for highest hierachy common parent track of selected Items, "P" for first common parent of selected items, "T" for each track if it has items in the region, "M" for Master-Track, "N" (or anything else) for no link to Region Render Matrix

---------------------------------------
---------- USER CONFIG END ------------
---------------------------------------

-- Load lua utilities
local joshnt_LuaUtils = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/DEVELOPMENT/joshnt_LuaUtilities.lua'
if reaper.file_exists( joshnt_LuaUtils ) then 
  dofile( joshnt_LuaUtils ) 
  if not joshnt or joshnt.version() < 1.0 then 
    reaper.MB("This script requires a newer version of joshnt Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages, 'joshnt_LuaUtilities.lua'","Error",0); 
    return 
  end
else 
  reaper.MB("This script requires joshnt Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt Lua Utilities'","Error",0)
  return
end

local r = reaper

-- para-global variables for script
  local isolateItems, space_in_between, start_silence, end_silence, lockBoolUser, boolNeedActivateEnvelopeOption, regionColor, regionColorMother, regionName_GLOBAL, regionNameLeftOver_GLOBAL, regionNameNumber_GLOBAL, regionNameNumberIndex_GLOBAL, motherRegionName_GLOBAL, RRMLink_GLOBAL;
  local t = {} -- Table to store items grouped by track
  local trackIDs = {} -- table trackIDs to access keys more easily
  local d; -- duration
  local numItems = r.CountSelectedMediaItems(0)
  local lockedItems_Global = {}
  -- global variables for grouping of items; used in getItemGroups()
    local itemGroups, itemGroupsStartsArray, itemGroupsEndArray;
    local nudgeValues = {}
  local parentTracksWithEnvelopes_GLOBAL = {}
  local parentTrackForRRM;



local function userInputValues()
    local defaultValuesString = isolateItems_USER..Time_Before_Item_Group_Start_USER .. "," .. Time_After_Item_Group_End_USER .. "," .. Space_Between_Regions_USER .. "," .. Lock_Items_USER .. "," .. Region_Name_USER .. "," .. Mother_Region_Name_USER .. "," .. Region_Color_USER .. "," .. Mother_Region_Color_USER .. "," .. Link_To_RRM_USER
    local continue, s = reaper.GetUserInputs("Regions user input", 10,
        "Isolate items:,Time before item group start:,Time after item group end:,Space between regions:,Lock items (y/n):,Region name:,Mother Region name:,Region Color ( Pick / default ):,M. Reg. Color ( Pick / default ):,Link to RRM (M / HP / P / T / N ):,,extrawidth=100",
        defaultValuesString)
    
    if not continue or s == "" then return false end
    local q = joshnt.fromCSV(s)
    
    -- Get the values from the input
    local isolateInput = q[1]
    local d1 = q[2]
    local d2 = q[3]
    local d3 = q[4]
    local lock1 = q[5]
    local regionName = q[6]
    local motherRegionName = q[7]
    local chooseColor = q[8]
    local chooseColorMother = q[9]
    local rrm_Link = q[10]
    
    -- Convert the values to globals
    if isolateInput:match("other") or isolateInput == "o" then 
    isolateItems = 1 -- move other = 1
    elseif isolateInput:match("sel") or isolateInput == "s" then
      isolateItems = 2 -- move selected = 2
    else
      isolateItems = 0 -- dont move = 0
    end
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
    regionColorMother = 0 -- is default
    
    -- Handle the Choose Color button
    if chooseColor ~= "" then
        local retval, color = reaper.GR_SelectColor(nil) -- Open the color picker dialog
        if retval ~= 0 then
          local r,g,b = reaper.ColorFromNative(color)
          regionColor = (r + 256 * g + 65536 * b)|16777216
        end
    end
    
    -- Handle the Choose Color button
    if chooseColorMother ~= "" then
        local retval, color = reaper.GR_SelectColor(nil) -- Open the color picker dialog
        if retval ~= 0 then
          local r,g,b = reaper.ColorFromNative(color)
          regionColorMother = (r + 256 * g + 65536 * b)|16777216
        end
    end
    
    -- Store the region names globally
    regionName_GLOBAL = regionName
    regionNameLeftOver_GLOBAL = nil
    regionNameNumber_GLOBAL = nil
    regionNameNumberIndex_GLOBAL = nil
    local leftText, number, indexOfNumber = joshnt.getNumbersUntilDifferent(regionName, "[$incr")
    if number then
        regionNameLeftOver_GLOBAL = leftText
        regionNameNumber_GLOBAL = number
        regionNameNumberIndex_GLOBAL = indexOfNumber
    end
    
    motherRegionName_GLOBAL = motherRegionName
    RRMLink_GLOBAL = 0
    if rrm_Link == "M" or rrm_Link == "m" or rrm_Link == "master" or rrm_Link == "Master" then
      RRMLink_GLOBAL = 1
    elseif rrm_Link == "HP" or rrm_Link == "hp" then
      RRMLink_GLOBAL = 2
    elseif rrm_Link == "P" or rrm_Link == "p" then
      RRMLink_GLOBAL = 3
    elseif rrm_Link == "T" or rrm_Link == "t" then
      RRMLink_GLOBAL = 4
    end

    return true
end

local function initReaGlue()

  t = {} -- init table t
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
      local itemInit_TEMP = r.GetSelectedMediaItem(0, i)
      if itemInit_TEMP then
          local it_len = r.GetMediaItemInfo_Value(itemInit_TEMP, 'D_LENGTH')
          addItemToTable(itemInit_TEMP, it_len)
      end
  end
  
  for key, _ in pairs(t) do
    table.insert(trackIDs, key)
  end
end

local function selectOriginalSelection(boolSelect)
  for track, items in pairs(t) do
    for index, _ in ipairs(items) do
      reaper.SetMediaItemSelected(items[index][1], boolSelect)
    end
  end
  reaper.UpdateArrange()
end

-- Items freistellen/ move selection away from non-selected items
local function moveAwayFromOtherItems()
  reaper.Main_OnCommand(40309, 0) -- Ripple editing off
  -- get items
  reaper.SelectAllMediaItems(0, false)
  selectOriginalSelection(true)
  local currentOriginalStart_TEMP, currentOriginalEnd_TEMP = joshnt.startAndEndOfSelectedItems()
  
  reaper.GetSet_LoopTimeRange(true, false, currentOriginalStart_TEMP, currentOriginalEnd_TEMP, false)
  
  reaper.Main_OnCommand(40717,0) -- select all items in teimeselection
  selectOriginalSelection(false)

  
  local otherItemsStart, otherItemsEnd = 0, 0
  -- find overlap of non-selected items with selected items
  if (reaper.CountSelectedMediaItems(0) == 0) and (joshnt.checkOverlapWithRegions(currentOriginalStart_TEMP,currentOriginalEnd_TEMP) == false) then 
    return
  else
    otherItemsStart, otherItemsEnd = joshnt.startAndEndOfSelectedItems()
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
    local _, otherItemsEndTemp = joshnt.startAndEndOfSelectedItems()
    -- if non-selected items in region, go to end of region
    local regionStart_TEMP2, regionEnd_TEMP2 = joshnt.getMostOverlappingRegion(regionEnd_TEMP,newLoopBound_TEMP)
    if regionEnd_TEMP2 > regionEnd_TEMP then
      local itemSel_TEMP = joshnt.saveItemSelection()
      r.GetSet_LoopTimeRange(true, false, regionStart_TEMP2, regionEnd_TEMP2, false)
      reaper.Main_OnCommand(40717,0) -- select all items in teimeselection
      selectOriginalSelection(false)
      if reaper.CountSelectedMediaItems() > 0 then
        otherItemsEndTemp = math.max(otherItemsEndTemp, regionEnd_TEMP2)
      end
      joshnt.reselectItems(itemSel_TEMP)
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
      joshnt.unselectAllTracks()
      -- create empty items
      for index, parentTracks in ipairs(parentTracksWithEnvelopes_GLOBAL) do
        reaper.SetOnlyTrackSelected(parentTracksWithEnvelopes_GLOBAL[index])
        r.GetSet_LoopTimeRange(true, false, currentOriginalStart_TEMP-start_silence-1, currentOriginalEnd_TEMP+end_silence, false)
        reaper.SetEditCurPos(currentOriginalStart_TEMP-start_silence-1, true, true)
        reaper.UpdateArrange() 
        reaper.Main_OnCommand(40142, 0) -- insert empty item
        table.insert(insertedEmptyItems, reaper.GetSelectedMediaItem(0,0))
      end
      joshnt.reselectItems(insertedEmptyItems)
    end
    
    selectOriginalSelection(true)
    r.GetSet_LoopTimeRange(true, false, currentOriginalStart_TEMP-start_silence-5, currentOriginalEnd_TEMP+end_silence, false)
    reaper.UpdateArrange()
    reaper.Main_OnCommand(40307, 0) -- cut area of items
    reaper.SetEditCurPos(otherItemsEnd+5, true, true)
    joshnt.unselectAllTracks()
    
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
      local pastedItems_TEMP = joshnt.saveItemSelection() 
      local pastedItemsStart_TEMP, pastedItemsEnd_TEMP = joshnt.startAndEndOfSelectedItems()
      joshnt.unselectAllTracks()
      for index, trackParentTEMP in pairs(parentTracksWithEnvelopes_GLOBAL) do
        reaper.SetTrackSelected(trackParentTEMP, true)
      end
      
      r.GetSet_LoopTimeRange(true, false, pastedItemsStart_TEMP, pastedItemsEnd_TEMP, false)
      reaper.SelectAllMediaItems(0, false)
      reaper.UpdateArrange()
      reaper.Main_OnCommand(40718 ,0) -- select items on selected tracks in time selection
      reaper.Main_OnCommand(40309, 0) -- Ripple editing off
      
      reaper.Main_OnCommand(40006,0) -- delete selected Items
      joshnt.reselectItems(pastedItems_TEMP)
      
    end
    
    local _,endTimeSel_TEMP = joshnt.startAndEndOfSelectedItems()
    if (currentOriginalEnd_TEMP - otherItemsEnd) > 0 then
      joshnt.removeTimeOnAllTracks(endTimeSel_TEMP + end_silence, endTimeSel_TEMP + end_silence + (currentOriginalEnd_TEMP - otherItemsEnd))
    end
    
  
  initReaGlue()
  reaper.SelectAllMediaItems(0, false)
  reaper.Main_OnCommand(40309, 0) -- Ripple editing off
  
  
  
  
  --restore selection
    -- Reselect Items
    selectOriginalSelection(true)
    
end

local function moveOtherItemsAway()
end

-- Function to adjust item positions 
local function getItemGroups()
  itemGroups, itemGroupsStartsArray, itemGroupsEndArray = joshnt.getOverlappingItemGroupsOfSelectedItems()
  if itemGroups and itemGroupsStartsArray and itemGroupsEndArray then
    for i = 1, #itemGroups do
      if i > 1 then
        nudgeValues[i] = d - (itemGroupsStartsArray[i] - itemGroupsEndArray[i-1])
      else 
        nudgeValues[i] = 0
      end
    end
  end
end
    
    
local function adjustItemPositions()   
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
      selectOriginalSelection(true) 
end

-- function to adjust existing region over selected items
local function setRegionLength()
  reaper.Undo_BeginBlock()

  local start_time, end_time = joshnt.startAndEndOfSelectedItems()

  -- Find region with most overlap
  local region_to_move = joshnt.getMostOverlappingRegion(start_time,end_time)
  
  start_time = start_time - start_silence
  end_time = end_time + end_silence
  
  if start_time < 0 then
    r.GetSet_LoopTimeRange(true, false, 0, math.abs(start_time), false)
    reaper.Main_OnCommand(40200, 0)
    end_time = end_time + math.abs(start_time)
    start_time = 0
    selectOriginalSelection(true)
  end
  
  -- Move overlapping region
  if regionColor ~= 0 then
    reaper.SetProjectMarker3(0, region_to_move, 1, start_time, end_time, regionName_GLOBAL, regionColor) 
  else
    reaper.SetProjectMarker( region_to_move, 1, start_time, end_time, regionName_GLOBAL )
  end
  reaper.Undo_EndBlock("Set Nearest Region", -1)
  return region_to_move
end

-- Function to create a region over selected items
local function createRegionOverItems()
    local startTime, endTime = joshnt.startAndEndOfSelectedItems()
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
    return reaper.AddProjectMarker2(0, true, startTime, endTime, regionName_GLOBAL, -1, regionColor)
end

local function setRegionsForItemGroups()
  local rgnIndexTable_TEMP = {}
  for i = 1, #itemGroups do
    reaper.SelectAllMediaItems(0, false)
    joshnt.reselectItems(itemGroups[i])

    if regionNameNumber_GLOBAL then
      local regionNameNumber_TEMP = regionNameNumber_GLOBAL
      if regionNameNumber_TEMP < 10 then
        regionNameNumber_TEMP = "0"..regionNameNumber_TEMP
      end
      regionName_GLOBAL = joshnt.insertStringAtPosition(regionNameLeftOver_GLOBAL, regionNameNumber_TEMP, regionNameNumberIndex_GLOBAL)
    end
    
    local currSelStart_TEMP, currSelEnd_TEMP = joshnt.startAndEndOfSelectedItems()
    local regionIndex_TEMP = nil

    if joshnt.checkOverlapWithRegions(currSelStart_TEMP, currSelEnd_TEMP) then regionIndex_TEMP = setRegionLength()
      else regionIndex_TEMP = createRegionOverItems()
    end
    
    if RRMLink_GLOBAL == 2 or RRMLink_GLOBAL == 3 then -- highest common parent or first common parent
      reaper.SetRegionRenderMatrix(0, regionIndex_TEMP,parentTrackForRRM,1)
    elseif RRMLink_GLOBAL == 1 then -- Master track
      reaper.SetRegionRenderMatrix(0, regionIndex_TEMP,reaper.GetMasterTrack(0),1)
    elseif RRMLink_GLOBAL == 4 then -- indiv. tracks
      local groupTracks = joshnt.getTracksOfSelectedItems()
      for _, val in ipairs (groupTracks) do
        reaper.SetRegionRenderMatrix(0, regionIndex_TEMP,val,1)
      end
    end   

    if regionNameNumber_GLOBAL then
      regionNameNumber_GLOBAL = regionNameNumber_GLOBAL + 1
    end

    table.insert(rgnIndexTable_TEMP,regionIndex_TEMP)

  end
  return rgnIndexTable_TEMP
end

local function setMotherRegion(tableWithChildRgnIndex)
  selectOriginalSelection(true)
  local startTime_TEMP, endTime_TEMP = joshnt.startAndEndOfSelectedItems()

  -- check if mother region already exists
  local overlappingRgns_TEMP = joshnt.getRegionsInTimeFrame(startTime_TEMP, endTime_TEMP) 
  local motherRegionStart = startTime_TEMP - start_silence - 0.01
  local motherRegionEnd = endTime_TEMP + end_silence + 0.01

  if #overlappingRgns_TEMP > #tableWithChildRgnIndex then
    local differentRgns_TEMP = nil
    for _, v in ipairs(overlappingRgns_TEMP) do
      if not joshnt.tableContainsVal(tableWithChildRgnIndex, v) then
        differentRgns_TEMP = v
        break
      end
    end

    if regionColorMother ~= 0 then
      reaper.SetProjectMarker3(0, differentRgns_TEMP, 1, motherRegionStart, motherRegionEnd, motherRegionName_GLOBAL, regionColor) 
    else
      reaper.SetProjectMarker( differentRgns_TEMP, 1, motherRegionStart, motherRegionEnd, motherRegionName_GLOBAL )
    end
  else
    reaper.AddProjectMarker2(0, true, motherRegionStart, motherRegionEnd, motherRegionName_GLOBAL, -1, regionColorMother)
  end
end

-- Main function
local function main()
    if numItems == 0 then 
      r.ShowMessageBox("No items selected!", "Error", 0)
      return 
    end
    if userInputValues() then
      r.PreventUIRefresh(1) 
      reaper.Undo_BeginBlock()  
      local originalRippleEditState = joshnt.getRippleEditingMode()
      if boolNeedActivateEnvelopeOption then
        reaper.Main_OnCommand(40070, 0)
      end
      initReaGlue()
      
      --get locked Items and unlock them
      lockedItems_Global = joshnt.saveLockedItems()
      joshnt.lockItemsState(lockedItems_Global,0)
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
      

      -- get all parent Tracks
      local parentTracks = joshnt.getParentTracksWithoutDuplicates(trackIDs)

      if parentTracks[1] == nil and (RRMLink_GLOBAL == 2 or RRMLink_GLOBAL == 3) then -- falls keine Parents, Master als RRM
        RRMLink_GLOBAL = 1
      else
        local commonParents = {}
        for i = 1, #parentTracks do
          if (RRMLink_GLOBAL == 2 or RRMLink_GLOBAL == 3) and joshnt.isAnyParentOfAllSelectedItems(parentTracks[i]) then

            commonParents[#commonParents + 1] = parentTracks[i]
          end

          -- get parent Tracks with envelopes
          if reaper.CountTrackEnvelopes(parentTracks[i]) > 0 then
            table.insert(parentTracksWithEnvelopes_GLOBAL,parentTracks[i])
          end
        end

        -- set RRM ParentTrack
        if commonParents[1] then
          parentTrackForRRM = commonParents[1]
        end
        for i = 1, #commonParents do
          if RRMLink_GLOBAL == 2 then -- highest common parent
            if reaper.GetMediaTrackInfo_Value(commonParents[i], "IP_TRACKNUMBER") < reaper.GetMediaTrackInfo_Value(parentTrackForRRM, "IP_TRACKNUMBER") then
              parentTrackForRRM = commonParents[i]
            end
          elseif RRMLink_GLOBAL == 3 then -- first common parent
            if reaper.GetMediaTrackInfo_Value(commonParents[i], "IP_TRACKNUMBER") > reaper.GetMediaTrackInfo_Value(parentTrackForRRM, "IP_TRACKNUMBER") then
              parentTrackForRRM = commonParents[i]
            end
          end
        end

        -- check if highest parent is any parent of all Tracks of selected items
        if (RRMLink_GLOBAL == 2 or RRMLink_GLOBAL == 3) and parentTrackForRRM == nil then
          RRMLink_GLOBAL = 1 -- set to master
        end

      end
      

      -- isolate
      if isolateItems == 1 then moveAwayFromOtherItems()
      elseif isolateItems == 2 then moveOtherItemsAway() end
      getItemGroups()
      adjustItemPositions()
      joshnt.lockItemsState(lockedItems_Global,1)
      joshnt.setRippleEditingMode(originalRippleEditState)
      if boolNeedActivateEnvelopeOption then
        reaper.Main_OnCommand(40070, 0)
      end
      reaper.Undo_EndBlock("Move Items", -1)
      
      reaper.Undo_BeginBlock()  
      if lockBoolUser == true then
        joshnt.lockSelectedItems()
      end
      local childRegionIndex = setRegionsForItemGroups()
      setMotherRegion(childRegionIndex)
      reaper.Undo_EndBlock("Create Regions", -1)
    end
    r.PreventUIRefresh(-1)
    reaper.UpdateArrange()
end


-- Run the main function
main()


