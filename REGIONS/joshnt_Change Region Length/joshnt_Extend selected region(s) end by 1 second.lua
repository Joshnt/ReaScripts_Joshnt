-- @noindex

local joshnt_LuaUtils = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/DEVELOPMENT/joshnt_LuaUtilities.lua'
if reaper.file_exists( joshnt_LuaUtils ) then 
  dofile( joshnt_LuaUtils ) 
  if not joshnt or joshnt.version() < 2.2 then 
    reaper.MB("This script requires a newer version of joshnt Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages, 'joshnt_LuaUtilities.lua'","Error",0); 
    return 
  end
else 
  reaper.MB("This script requires joshnt Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt Lua Utilities'","Error",0)
  return
end

local selRgns, _ = joshnt.getSelectedMarkerAndRegionIndex()

if selRgns then
    reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)
    for i = 0, #selRgns do
        local rgnStart, rgnEnd, rgnName = joshnt.getRegionBoundsByIndex(selRgns[i])
        if rgnStart then 
          reaper.SetProjectMarker(selRgns[i], true, rgnStart, rgnEnd + 1, rgnName)
        end
    end
    reaper.PreventUIRefresh(-1) 
    reaper.UpdateArrange()
    reaper.Undo_EndBlock('Extend sel. region(s) end by 1 sec', -1)
else
    joshnt.TooltipAtMouse("No region(s) selected!")
end
