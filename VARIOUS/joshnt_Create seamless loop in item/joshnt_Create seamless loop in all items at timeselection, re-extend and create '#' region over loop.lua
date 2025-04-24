-- @noindex

-- execute main function
local seamlessLoop_single = reaper.GetResourcePath().."/Scripts/Joshnt_ReaScripts/VARIOUS/joshnt_Create seamless loop in item/joshnt_Create seamless loop in selected items at timeselection, re-extend and create '#' region over loop.lua"
if not reaper.file_exists( seamlessLoop_single ) then 
  reaper.MB("The package seems to be corrupted ('joshnt_Create seamless loop in selected items at timeselection, re-extend and create '#' region over loop.lua' could not be found.)\nPlease reinstall it here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt_Create seamless loop in item","Error",0)
  return
end

reaper.Main_OnCommand(40717,0) -- select items in timeselection
dofile(seamlessLoop_single)