-- @noindex

-- Load lua utilities
local joshnt_LuaUtils = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/DEVELOPMENT/joshnt_LuaUtilities.lua'
if reaper.file_exists( joshnt_LuaUtils ) then 
  dofile( joshnt_LuaUtils ) 
  if not joshnt or joshnt.version() < 3.5 then 
    reaper.MB("This script requires a newer version of joshnt Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages, 'joshnt_LuaUtilities.lua'","Error",0); 
    return 
  end
else 
  reaper.MB("This script requires joshnt Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt Lua Utilities'","Error",0)
  return
end

-- execute main function
local seamlessLoop_single = reaper.GetResourcePath().."/Scripts/Joshnt_ReaScripts/VARIOUS/joshnt_Create seamless loop in selected items at timeselection, re-extend and create '#' region over loop.lua"
if not reaper.file_exists( seamlessLoop_single ) then 
  reaper.MB("The package seems to be corrupted ('joshnt_Create seamless loop in selected items at timeselection, re-extend and create '#' region over loop.lua' could not be found.)\nPlease reinstall it here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt_Create seamless loop in item","Error",0)
  return
end


reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

reaper.Main_OnCommand(40717,0) -- select items in timeselection
joshnt.unselectMidiItems()

reaper.Undo_EndBlock("Select all items in timeselection (ignore MIDI)", -1) -- End of the undo block. Leave it at the bottom of your main function.
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)

dofile(seamlessLoop_single)