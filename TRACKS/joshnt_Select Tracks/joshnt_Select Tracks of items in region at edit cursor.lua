-- @noindex

local joshnt_LuaUtils = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/DEVELOPMENT/joshnt_LuaUtilities.lua'
if reaper.file_exists( joshnt_LuaUtils ) then 
  dofile( joshnt_LuaUtils ) 
  if not joshnt or joshnt.version() < 3.7 then 
    reaper.MB("This script requires a newer version of joshnt Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages, 'joshnt_LuaUtilities.lua'","Error",0); 
    return 
  end
else 
  reaper.MB("This script requires joshnt Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt Lua Utilities'","Error",0)
  return
end

local function main()
    local _, rgnpos, rgnend = joshnt.getRegionAtPosition(reaper.GetCursorPosition())
    if rgnpos == nil then joshnt.TooltipAtMouse("No region at edit cursor") return end
    local timeRangeStart, timeRangeEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

    reaper.GetSet_LoopTimeRange(true, false, rgnpos, rgnend, false)
    reaper.SelectAllMediaItems(0, false)
    reaper.Main_OnCommand(40717,0) -- select all items in teimeselection
    joshnt.selectOnlyTracksOfSelectedItems()

    reaper.GetSet_LoopTimeRange(true, false, timeRangeStart, timeRangeEnd, false)
end

reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)
main()
reaper.UpdateArrange() reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock('Select track(s) of region at edit cursor', -1)