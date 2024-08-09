-- @description Increase distance between regions in time selection by 1 sec
-- @version 1.0
-- @author Joshnt
-- @about
--    Moves region closer together - only use when no items between regions, as those may get ripped apart
-- @changelog
--  + init

---------------------------------------
--------- USER CONFIG - EDIT ME -------
--- Default Values for input dialog ---
---------------------------------------

local timeAddedBetweenRegions_USER = 1 -- as script name suggest 1 second removed per script execution; change to your liking
local preventRegionOverlaps = true -- if time between regions would fall below 0, script doesnt finish execution
local ignoreItemsBetweenRegions_USER = 0 -- if items are found between regions: 0 doesn't execute script, 1 asks for permission, 2 executes the script anyway

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

local function nothing() end; local function bla() reaper.defer(nothing) end

  local startTime, endTime = reaper.GetSet_LoopTimeRange(false,false,0,0,false)
  local numRegions = reaper.CountProjectMarkers(0, 0)
  if numRegions == 0 or (startTime == 0 and endTime == 0) then
    bla() return
  end

  local regionsInTime = joshnt.getRegionsInTimeFrame(startTime, endTime) -- array
  if #regionsInTime == 0 then
    bla() return
  end

  -- get overlapping regions
  local regionOverlapGroups = {}
  local regionOverlapGroupsBounds = {}
  table.insert(regionOverlapGroups, {regionsInTime[1]})
  table.insert(regionOverlapGroupsBounds, {joshnt.getRegionBoundsByIndex(regionsInTime[1])})

  for j = 2, #regionsInTime do
    local rgnStart_TEMP, rgnEnd_TEMP = joshnt.getRegionBoundsByIndex(regionsInTime[j])
    for i = 1, #regionOverlapGroups do
      if regionOverlapGroupsBounds[i][1] < rgnEnd_TEMP and regionOverlapGroupsBounds[i][2] > rgnStart_TEMP then
        table.insert(regionOverlapGroups[i],regionsInTime[j])
        regionOverlapGroupsBounds[i][1] = math.min(regionOverlapGroupsBounds[i][1], rgnStart_TEMP)
        regionOverlapGroupsBounds[i][2] = math.max(regionOverlapGroupsBounds[i][2], rgnEnd_TEMP)
      end
      if i == #regionOverlapGroups then
        table.insert(regionOverlapGroups, i+1, {regionsInTime[j]})
        table.insert(regionOverlapGroupsBounds, i+1, {joshnt.getRegionBoundsByIndex(regionsInTime[j])})
      end
    end
  end

  -- check for overlapping region groups
  for i = 1, #regionOverlapGroups do
    if i > #regionOverlapGroups then
      break
    end
    local j = i+1
    while j <= #regionOverlapGroups+1 do
      if j > #regionOverlapGroups then
        break
      end
      if (regionOverlapGroupsBounds[i][2] > regionOverlapGroupsBounds[j][1] and regionOverlapGroupsBounds[i][1] < regionOverlapGroupsBounds[j][2]) or (regionOverlapGroupsBounds[j][2] > regionOverlapGroupsBounds[i][1] and regionOverlapGroupsBounds[j][1] < regionOverlapGroupsBounds[i][2]) then
        regionOverlapGroupsBounds[i][1] = math.min(regionOverlapGroupsBounds[i][1], regionOverlapGroupsBounds[j][1])
        regionOverlapGroupsBounds[i][2] = math.max(regionOverlapGroupsBounds[i][2], regionOverlapGroupsBounds[j][2])

        local combinedArray = {}
        local seen = {}
        for _, v in ipairs(regionOverlapGroups[i]) do
            if not seen[v] then
                table.insert(combinedArray, v)
                seen[v] = true
            end
        end
        for _, v in ipairs(regionOverlapGroups[j]) do
            if not seen[v] then
                table.insert(combinedArray, v)
                seen[v] = true
            end
        end
        regionOverlapGroups[i] = combinedArray
        table.remove(regionOverlapGroups,j)
        table.remove(regionOverlapGroupsBounds,j)
      else
        j = j+1
      end
    end
  end


  reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)

  if ignoreItemsBetweenRegions_USER ~= 2 then
    local item_TEMP = joshnt.saveItemSelection()
    local itemsBetween = false
    for i = 1, #regionOverlapGroups-1 do
      reaper.SelectAllMediaItems(0, false)
      reaper.GetSet_LoopTimeRange(true, false, regionOverlapGroupsBounds[i][2], regionOverlapGroupsBounds[i+1][1], false)
      reaper.Main_OnCommand(40717,0) -- select all items in teimeselection
      if reaper.CountSelectedMediaItems(0) > 0 then
        itemsBetween = true
        break
      end
    end
    reaper.SelectAllMediaItems(0, false)
    joshnt.reselectItems(item_TEMP)
    if itemsBetween == true then
      if ignoreItemsBetweenRegions_USER == 0 then
        joshnt.TooltipAtMouse("canceled script - items between groups")
        return
      else
        if reaper.MB("Found items between Regions. Adjust space between regions anyway and potentially split items?","CAUTION",4) == 7 then
          return
        end
      end
    end
  end

local timeAdded = 0

for i = 1, #regionOverlapGroups do
  local center_between_Regions = regionOverlapGroupsBounds[i][2]+0.01
  if i < #regionOverlapGroups then
    if regionOverlapGroupsBounds[i][2] >= (regionOverlapGroupsBounds[i+1][1] - timeAddedBetweenRegions_USER) and preventRegionOverlaps then
      reaper.GetSet_LoopTimeRange(true, false, startTime, endTime, false)
      joshnt.TooltipAtMouse("Further moving results in Regions Overlapping")
      return
    end
    center_between_Regions = regionOverlapGroupsBounds[i][2] + ((regionOverlapGroupsBounds[i+1][1] - regionOverlapGroupsBounds[i][2] - timeAddedBetweenRegions_USER)*0.5)
  end
  reaper.GetSet_LoopTimeRange(true, false, center_between_Regions + timeAdded, center_between_Regions + timeAddedBetweenRegions_USER + timeAdded, false)

  reaper.Main_OnCommand(40201, 0) -- remove Time
  timeAdded = timeAdded - timeAddedBetweenRegions_USER
end

reaper.GetSet_LoopTimeRange(true, false, startTime, endTime + timeAdded + timeAddedBetweenRegions_USER, false)

reaper.PreventUIRefresh(-1) 
reaper.UpdateArrange()
reaper.Undo_EndBlock('Decrease Region Distance', -1)

