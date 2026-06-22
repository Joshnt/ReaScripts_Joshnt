-- @noindex

-- Load lua utilities
local joshnt_LuaUtils = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/DEVELOPMENT/joshnt_LuaUtilities.lua'
if reaper.file_exists( joshnt_LuaUtils ) then 
  dofile( joshnt_LuaUtils ) 
  if not joshnt or joshnt.version() < 4.01 then 
    reaper.MB("This script requires a newer version of joshnt Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages, 'joshnt_LuaUtilities.lua'","Error",0); 
    return 
  end
else 
  reaper.MB("This script requires joshnt Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt Lua Utilities'","Error",0)
  return
end

-- check if hover edit exists
local hoverEdit = reaper.GetResourcePath()..'/Scripts/LKC Tools/Hover editing package/LKC - HOVER EDIT - Toggle hovering.lua'
if not reaper.file_exists( hoverEdit ) then 
    reaper.MB("This script requires LKC's Hover Edit Package! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'LKC Hover Edit Package'","Error",0)
    return
end


-- copied from me2beats - toggle solo track under mouse.lua
function muteTrackUnderMouse ()
    function nothing() end

    track = reaper.BR_TrackAtMouseCursor()
    if track then
    reaper.Undo_BeginBlock()
    if reaper.GetMediaTrackInfo_Value(track, 'B_MUTE') == false then
        reaper.SetMediaTrackInfo_Value(track, 'B_MUTE', true)
    else
        reaper.SetMediaTrackInfo_Value(track, 'B_MUTE', false)
    end
    reaper.Undo_EndBlock('toggle solo track under mouse', -1)
    else reaper.defer(nothing) end
end

local hoverToggleID = reaper.NamedCommandLookup("_RS8277b238cd7341ba4a3c9ff870f30876ce76160b") -- ID of hover edit toggle
if reaper.GetToggleCommandState(hoverToggleID) == 0 then
    reaper.Main_OnCommand(6, 0) -- solo selected track
else 
    muteTrackUnderMouse()
end
