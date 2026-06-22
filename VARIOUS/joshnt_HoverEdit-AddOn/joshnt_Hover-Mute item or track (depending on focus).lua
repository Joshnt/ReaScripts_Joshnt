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
function muteItemOrTrackUnderMouse ()
    function nothing() end

    item = reaper.BR_ItemAtMouseCursor()
    if item then
        reaper.Undo_BeginBlock()
        if reaper.GetMediaItemInfo_Value(item, 'B_MUTE') == false then
            reaper.SetMediaItemInfo_Value(item, 'B_MUTE', true)
        else
            reaper.SetMediaItemInfo_Value(item, 'B_MUTE', false)
        end
        reaper.Undo_EndBlock('toggle mute item or track under mouse', -1)
    else
        track = reaper.BR_TrackAtMouseCursor()
        if track then
            reaper.Undo_BeginBlock()
            if reaper.GetMediaTrackInfo_Value(track, 'B_MUTE') == false then
                reaper.SetMediaTrackInfo_Value(track, 'B_MUTE', true)
            else
                reaper.SetMediaTrackInfo_Value(track, 'B_MUTE', false)
            end
            reaper.Undo_EndBlock('toggle mute item or track under mouse', -1)
        else reaper.defer(nothing) end
    end
end

local hoverToggleID = reaper.NamedCommandLookup("_RS8277b238cd7341ba4a3c9ff870f30876ce76160b") -- ID of hover edit toggle
if reaper.GetToggleCommandState(hoverToggleID) == 0 then
    reaper.Main_OnCommand(40183, 0) -- solo selected track
else 
    muteItemOrTrackUnderMouse()
end
