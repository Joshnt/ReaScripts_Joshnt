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
    local selRgnTable = joshnt.getSelectedMarkerAndRegionIndex()
    if selRgnTable == nil then 
        joshnt.TooltipAtMouse("No region selected")
        return 
    end
    local timeRangeStart, timeRangeEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    reaper.SelectAllMediaItems(0, false)

    local trackArray = {}
    for index, rgnIndex in ipairs(selRgnTable) do
        local rgnpos, rgnend = joshnt.getRegionBoundsByIndex(rgnIndex)
        reaper.GetSet_LoopTimeRange(true, false, rgnpos, rgnend, false)
        reaper.Main_OnCommand(40717,0) -- select all items in teimeselection
        joshnt.selectOnlyTracksOfSelectedItems()
        for i = 0, reaper.CountSelectedTracks(0) -1 do
            trackArray[reaper.GetSelectedTrack(0, i)] = true
        end
    end
    
    joshnt.unselectAllTracks()

    for tracks, _ in pairs(trackArray) do
        reaper.SetTrackSelected(tracks, 1)
    end
    

    reaper.GetSet_LoopTimeRange(true, false, timeRangeStart, timeRangeEnd, false)
end

reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)
main()
reaper.UpdateArrange() reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock('Select track(s) of selected region', -1)