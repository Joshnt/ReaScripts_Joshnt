-- @noindex

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

if not joshnt.checkJS_API() then return end


local function main()
    local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
    local num_total = num_markers + num_regions
    if num_regions == 0 then joshnt.TooltipAtMouse("No regions found") return end
    if reaper.CountSelectedTracks(0) == 0 then joshnt.TooltipAtMouse("No tracks selected") return end
    local prevSelection = joshnt.saveItemSelection()
    reaper.SelectAllMediaItems(0, false)
    reaper.Main_OnCommand(40421,0) -- select all items on selected tracks
    if reaper.CountSelectedMediaItems(0) == 0 then joshnt.TooltipAtMouse("No items on selected tracks") return end
    local itemsOnTracks = joshnt.saveItemSelection() -- table

    local selRgns_NEW = {}
    for j=0, num_total - 1 do
        local retval, isrgn, rgnpos, rgnend, rgnname, markrgnindexnumber = reaper.EnumProjectMarkers( j )
        if isrgn then
            reaper.SelectAllMediaItems(0, false)
            reaper.GetSet_LoopTimeRange(true, false, rgnpos, rgnend, false)
            reaper.Main_OnCommand(40717,0) -- select all items in teimeselection
            for i = 0, reaper.CountSelectedMediaItems(0) -1 do
                if joshnt.tableContainsVal(itemsOnTracks,reaper.GetSelectedMediaItem(0, i)) then
                    table.insert(selRgns_NEW,markrgnindexnumber)
                    break
                end
            end
        end
    end
    joshnt.setRegionSelectedByIndex(selRgns_NEW)

    reaper.SelectAllMediaItems(0, false)
    joshnt.reselectItems(prevSelection)
end

reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)
main()
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock('Select Regions with items on selected Tracks', -1)