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

local r = reaper; local function nothing() end; local function bla() r.defer(nothing) end
tracks = r.CountTracks()

-- copied from "me2beats_Toggle exclusive solo for selected tracks.lua" 
function soloSelectedTrack ()
  sel = r.GetMediaTrackInfo_Value(r.GetSelectedTrack(0,0), 'I_SOLO')
  if sel == 0 then
    r.Main_OnCommand(40340,0) -- unsolo all tracks
    for i = 0, sel_tracks-1 do
      tr = r.GetSelectedTrack(0,i)
      r.SetMediaTrackInfo_Value(tr, 'I_SOLO', 2)
    end
  else
    r.Main_OnCommand(40340,0) -- unsolo all tracks
  end
end

function soloTrackUnderMouse ()
  sel = r.GetMediaTrackInfo_Value(mouse_tr, 'I_SOLO')
  if sel == 0 then
    r.Main_OnCommand(40340,0) -- unsolo all tracks
    r.SetMediaTrackInfo_Value(mouse_tr, 'I_SOLO', 2)
  else
    r.Main_OnCommand(40340,0) -- unsolo all tracks
  end
end

local hoverToggleID = reaper.NamedCommandLookup("_RS8277b238cd7341ba4a3c9ff870f30876ce76160b") -- ID of hover edit toggle

if reaper.GetToggleCommandState(hoverToggleID) == 0 then
  sel_tracks = r.CountSelectedTracks()
  if tracks == 0 or sel_tracks == 0 then bla() return end 
  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)
  soloSelectedTrack()
else 
  mouse_tr = r.BR_TrackAtMouseCursor()
  if tracks == 0 or sel_tracks == 0 then bla() return end 
  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)
  soloTrackUnderMouse()
end
r.PreventUIRefresh(-1)
r.Undo_EndBlock('Hover exclusive solo', -1)