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

local function main()
  local itemnum = reaper.CountSelectedMediaItems(0)
  if itemnum == 0 then joshnt.TooltipAtMouse("No items selected!") return end
  local window, segment, details = reaper.BR_GetMouseCursorContext()
  local trackUnderMouse = reaper.BR_GetMouseCursorContext_Track()
  local mousePosX = reaper.BR_GetMouseCursorContext_Position()
  local trackUnderMouse_Index
  if not trackUnderMouse then 
    trackUnderMouse_Index = reaper.CountTracks(0)
  else
    trackUnderMouse_Index = reaper.GetMediaTrackInfo_Value(trackUnderMouse, "IP_TRACKNUMBER") - 1
  end
  if not window or window =="" or not mousePosX or mousePosX == -1 then joshnt.TooltipAtMouse("Unable to get mouse context or position") return end

  reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)

  -- Snap xPos to grid (if snapping is toggled & grid active)
  if reaper.GetToggleCommandState(1157) == 1 then -- options: toggle snapping
    mousePosX = reaper.SnapToGrid(0,mousePosX)
  end

  local startPos = reaper.GetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0,0), "D_POSITION")
  local itemArray = {}
  local highestTrack = math.huge -- visually highest in TCP = lowest index
  local lowestTrack = 0 -- visually lowest in TCP = lowest index
  for i = 0, itemnum -1 do
    local item = reaper.GetSelectedMediaItem(0,i)
    local track = reaper.GetMediaItem_Track(item)
    local track_number = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")-1
    itemArray[i] = {item, track_number}
    highestTrack = math.min(highestTrack,track_number)
    lowestTrack = math.max(lowestTrack,track_number)
  end

  local numTracks = reaper.CountTracks(0)
  if trackUnderMouse_Index + lowestTrack - highestTrack + 1 > numTracks then 
    for i = 0, trackUnderMouse_Index + lowestTrack - highestTrack - numTracks do
      reaper.InsertTrackAtIndex(numTracks + i, true)
    end
  end

  for i = 0, itemnum -1 do
      local item_TEMP = itemArray[i][1]
      local pasteTrack = reaper.GetTrack(0, trackUnderMouse_Index + (itemArray[i][2] - highestTrack))
      local oldPos_TEMP = reaper.GetMediaItemInfo_Value(item_TEMP, "D_POSITION")
      reaper.SetMediaItemInfo_Value(item_TEMP, "D_POSITION", mousePosX + oldPos_TEMP - startPos)
      reaper.MoveMediaItemToTrack(item_TEMP, pasteTrack)
  end

  reaper.UpdateArrange() reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock('Move selected items to track under mouse - track relative', -1)
end

main()