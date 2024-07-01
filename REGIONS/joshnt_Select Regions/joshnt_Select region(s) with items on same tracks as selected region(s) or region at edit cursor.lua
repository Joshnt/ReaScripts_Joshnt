-- @noindex

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

if not joshnt.checkJS_API() then return end

local function main() 
    local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
    local num_total = num_markers + num_regions
    if num_regions == 0 then
        joshnt.TooltipAtMouse("No regions in project")
        return
    end

    local selRgnTable = joshnt.getSelectedMarkerAndRegionIndex()
    
    if selRgnTable == nil or selRgnTable[1] == nil then
        local rgnAtEdit, _,_ = joshnt.getRegionAtPosition(reaper.GetCursorPosition())
        selRgnTable = {rgnAtEdit}
    end
    if selRgnTable == nil or selRgnTable[1] == nil then joshnt.TooltipAtMouse("No region(s) selected or at edit cursor") return end
    if #selRgnTable == num_regions then joshnt.TooltipAtMouse("All regions in the project are already selected") return end
    
    local trackArray_Main = {}
    local noItemsInRegions = true

    -- DEBUG
    for i = 1, #selRgnTable do
        reaper.ShowConsoleMsg("\nRegion: "..selRgnTable[i])
    end

    -- find tracks of items within region
    for index, rgnIndex in ipairs(selRgnTable) do
        local regionStart, regionEnd = joshnt.getRegionBoundsByIndex(rgnIndex)
        reaper.SelectAllMediaItems(0, false)
        reaper.UpdateArrange()
        reaper.GetSet_LoopTimeRange(true, false, regionStart, regionEnd, false)
        reaper.Main_OnCommand(40717,0) -- select all items in teimeselection
        local selItems_TEMP = reaper.CountSelectedMediaItems(0)

        if noItemsInRegions and selItems_TEMP > 0 then noItemsInRegions = false end
        for i = 0, selItems_TEMP - 1  do
            local item = reaper.GetSelectedMediaItem(0, i)
            local track = reaper.GetMediaItem_Track(item)
            
            -- DEBUG
            local _, trackName = reaper.GetTrackName(track)
            reaper.ShowConsoleMsg("\nTrack Name in region: "..trackName)
            trackArray_Main[track] = true
        end
    end

    reaper.SelectAllMediaItems(0, false)
    joshnt.unselectAllTracks()

    if noItemsInRegions then joshnt.TooltipAtMouse("No items in selected region to get tracks") return end

    local tracksOfRegion = {}
    -- select tracks of items in region and items
    for trackID, _ in pairs(trackArray_Main) do
        reaper.SetTrackSelected(trackID, true)
        table.insert(tracksOfRegion,trackID)
    end
    reaper.GetSet_LoopTimeRange(true, false, 0, reaper.GetProjectLength(0), false)
    reaper.SelectAllMediaItems(0, false)
    reaper.UpdateArrange()
    reaper.Main_OnCommand(40718,0) -- select all items on selected tracks in timeselection
    local itemsOnRelevantTracks = joshnt.saveItemSelection()
    local selRgns_NEW = {}

    for j=0, num_total - 1 do
        local retval, isrgn, rgnpos, rgnend, rgnname, markrgnindexnumber = reaper.EnumProjectMarkers( j )
        if isrgn then
            reaper.SelectAllMediaItems(0, false)
            reaper.GetSet_LoopTimeRange(true, false, rgnpos, rgnend, false)
            reaper.Main_OnCommand(40717,0) -- select all items in teimeselection
            for i = 0, reaper.CountSelectedMediaItems(0) -1 do
                if joshnt.tableContainsVal(itemsOnRelevantTracks,reaper.GetSelectedMediaItem(0, i)) then
                    table.insert(selRgns_NEW,markrgnindexnumber)
                    break
                end
            end
        end
    end

    joshnt.setRegionSelectedByIndex(selRgns_NEW)

    reaper.SelectAllMediaItems(0, false)
    joshnt.reselectItems(itemsOnRelevantTracks)
    reaper.GetSet_LoopTimeRange(true, false, 0, 0, false)
end
  
reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)
main()
reaper.UpdateArrange() reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock('Select region(s) with items on same tracks as selected region', -1)