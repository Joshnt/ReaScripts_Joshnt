-- @noindex

-- LOAD EXTERNALS
-- Load lua utilities
local joshnt_LuaUtils = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/DEVELOPMENT/joshnt_LuaUtilities.lua'
if reaper.file_exists( joshnt_LuaUtils ) then 
  dofile( joshnt_LuaUtils ) 
  if not joshnt or joshnt.version() < 3.4 then 
    reaper.MB("This script requires a newer version of joshnt Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages, 'joshnt_LuaUtilities.lua'","Error",0); 
    return 
  end
else 
  reaper.MB("This script requires joshnt Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt Lua Utilities'","Error",0)
  return
end

-- execute main function
local seamlessLoop = reaper.GetResourcePath().."/Scripts/Joshnt_ReaScripts/VARIOUS/joshnt_Create seamless loop in item/joshnt_Create seamless loop in selected items, re-extend and create '#' region over loop - use timeselection over first selected item as reference.lua"
if not reaper.file_exists( seamlessLoop ) then 
  reaper.MB("The package seems to be corrupted ('joshnt_Create seamless loop in selected items, re-extend and create '#' region over loop - use timeselection over first selected item as reference.lua' could not be found.)\nPlease reinstall it here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt_Create seamless loop in item","Error",0)
  return
end


reaper.SelectAllMediaItems(0, true)
joshnt.unselectMidiItems()

dofile(seamlessLoop)


