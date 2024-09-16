-- @noindex

local joshnt_LuaUtils = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/DEVELOPMENT/joshnt_LuaUtilities.lua'
if reaper.file_exists( joshnt_LuaUtils ) then 
  dofile( joshnt_LuaUtils ) 
  if not joshnt or joshnt.version() < 2.21 then 
    reaper.MB("This script requires a newer version of joshnt Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages, 'joshnt_LuaUtilities.lua'","Error",0); 
    return 
  end
else 
  reaper.MB("This script requires joshnt Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt Lua Utilities'","Error",0)
  return
end

local curPos = reaper.GetCursorPosition()
local rgnIndex, rgnStart, rgnEnd, rgnName = joshnt.getRegionAtPosition(curPos)
if rgnStart then
  reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)
  reaper.SetProjectMarker(rgnIndex, true, rgnStart, rgnEnd + 1, rgnName)
  reaper.PreventUIRefresh(-1) 
  reaper.UpdateArrange()
  reaper.Undo_EndBlock('Extend region at edit cursor end by 1 sec', -1)
else
  joshnt.TooltipAtMouse("No Region at edit cursor!")
end
