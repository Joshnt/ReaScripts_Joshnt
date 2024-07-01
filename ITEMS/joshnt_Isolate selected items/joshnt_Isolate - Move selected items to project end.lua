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

--reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
local projEnd = reaper.GetProjectLength(0)
joshnt.isolate_MoveSelectedItems_InsertToInput(1,1,projEnd,true)
reaper.Undo_EndBlock("Isolate - Move selected items to project end",0)
reaper.UpdateArrange()
--reaper.PreventUIRefresh(-1)