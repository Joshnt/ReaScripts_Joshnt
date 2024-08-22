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
    local mousePosX = reaper.BR_GetMouseCursorContext_Position()
    local trackUnderMouse = reaper.BR_GetMouseCursorContext_Track()
    if not window or window =="" or not mousePosX or mousePosX == -1 then joshnt.TooltipAtMouse("Unable to get mouse context or position") return end
    if not trackUnderMouse then joshnt.TooltipAtMouse("Unable to get track under mouse") return end

    reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)

    local itemArray = {}
    for i = 0, itemnum -1 do
      itemArray[i] = reaper.GetSelectedMediaItem(0,i)
    end

    for i = 0, itemnum -1 do
        local item_TEMP = itemArray[i]
        reaper.SetMediaItemInfo_Value(item_TEMP, "D_POSITION", mousePosX)
        reaper.MoveMediaItemToTrack(item_TEMP, trackUnderMouse)
    end

    reaper.UpdateArrange() reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock('Move selected items to mouse', -1)
end

main()