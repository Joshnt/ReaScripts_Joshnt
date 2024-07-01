-- @noindex

--
local indexMonitoringFX = 5 -- index of Monitoring FX Starting at 0 -> Monitor FX 1 = index 0
--

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

if not joshnt.checkSWS() then return end

if not joshnt.checkJS_API() then return end

-- Define a function to bring the FX window to focus
local function main()
    local master_track = reaper.GetMasterTrack(0)
    local fx_handle = 0x1000000 + indexMonitoringFX -- Special index for monitoring FX
    local monitoring_fx_count = reaper.TrackFX_GetRecCount(master_track)
    if monitoring_fx_count < indexMonitoringFX + 1 then
        joshnt.TooltipAtMouse("Monitoring FX "..tostring(indexMonitoringFX+1).." not found")
        return
    end
    local isOpen = reaper.TrackFX_GetFloatingWindow(master_track, fx_handle) ~= nil
    -- Check if the FX window was found
    if isOpen then
        -- Bring the FX window to focus
        reaper.TrackFX_Show(master_track, fx_handle, 2) -- 3 means show in floating window
    else
      reaper.TrackFX_Show(master_track, fx_handle, 3) -- 3 means show in floating window
    end
end

-- Run the function to set the FX window focused
main()