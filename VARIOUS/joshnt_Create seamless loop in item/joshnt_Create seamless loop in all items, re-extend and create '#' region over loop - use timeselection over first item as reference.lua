-- @noindex

-- execute main function
local seamlessLoop = reaper.GetResourcePath().."/Scripts/Joshnt_ReaScripts/VARIOUS/joshnt_Create seamless loop in item/joshnt_Create seamless loop in selected items, re-extend and create '#' region over loop - use timeselection over first selected item as reference.lua"
if not reaper.file_exists( seamlessLoop ) then 
  reaper.MB("The package seems to be corrupted ('joshnt_Create seamless loop in selected items, re-extend and create '#' region over loop - use timeselection over first selected item as reference.lua' could not be found.)\nPlease reinstall it here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt_Create seamless loop in item","Error",0)
  return
end


reaper.SelectAllMediaItems(0, true)

dofile(seamlessLoop)


