-- @description Zoom to all regions with items on same tracks as current region
-- @version 1.0
-- @author Joshnt
-- @about
--    Zoom to all regions with items on same tracks as current region; Idea and Concept bei Wieland Müller
-- @changelog
--  + init

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

if not joshnt.checkSWS() then return end


local function main()
    local timeRangeStart, timeRangeEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    reaper.PreventUIRefresh(1)
    local curPos = reaper.GetCursorPosition()
    local num, rgnpos, rgnend = joshnt.getRegionAtPositionOrNext(curPos)
    if not num then 
        joshnt.TooltipAtMouse("No current or next region found.")
        return 
    end

    reaper.MoveEditCursor(rgnpos-curPos, 0)

    -- timeselect region
    reaper.GetSet_LoopTimeRange(true, false, rgnpos, rgnend, false)
    reaper.SelectAllMediaItems(0, false)
    reaper.Main_OnCommand(40717,0) -- select all items in teimeselection
    local numItems = reaper.CountSelectedMediaItems()
    if numItems == 0 then 
        joshnt.TooltipAtMouse("No items in current region.")
        return
    end

    -- select only Tracks of items
    joshnt.unselectAllTracks()
    for i = 0, numItems -1 do
        local itemTemp = reaper.GetSelectedMediaItem(0,i)
        local trackTemp = reaper.GetMediaItem_Track(itemTemp)
        reaper.SetTrackSelected(trackTemp,true)
    end
    reaper.Main_OnCommand(40421,0) -- select all items on selected tracks

    -- unselect all items which aren't in a region
    local numItemsNew = reaper.CountSelectedMediaItems()
    if numItemsNew ~= numItems then
        for i = 0, numItemsNew - 1 do
            local itemTemp = reaper.GetSelectedMediaItem(0,i)
            if itemTemp then
                local itemPos_TEMP = reaper.GetMediaItemInfo_Value(itemTemp, "D_POSITION")
                local itemEnd_TEMP = reaper.GetMediaItemInfo_Value(itemTemp, 'D_LENGTH') + itemPos_TEMP
                if not joshnt.checkOverlapWithRegions(itemPos_TEMP, itemEnd_TEMP) then
                    reaper.SetMediaItemSelected(itemTemp, false)
                end
            end
        end
    end
    reaper.PreventUIRefresh(-1) 
    reaper.UpdateArrange()

    reaper.PreventUIRefresh(1)
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_HZOOMITEMS"),0) -- horizontal zoom to selected items
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_VZOOMIITEMS"),0) -- vertical zoom to selected items
    
    joshnt.unselectAllTracks()
    reaper.SelectAllMediaItems(0, false)
    reaper.GetSet_LoopTimeRange(true, false, timeRangeStart, timeRangeEnd, false)
    reaper.PreventUIRefresh(-1) 
end

reaper.Undo_BeginBlock()
main()
reaper.UpdateArrange()
reaper.Undo_EndBlock('Zoom to all Regions with same Tracks as current', -1)