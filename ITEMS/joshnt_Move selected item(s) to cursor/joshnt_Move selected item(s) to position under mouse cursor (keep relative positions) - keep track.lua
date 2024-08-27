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

if not joshnt.checkSWS() then return end



local function main()
    local itemnum = reaper.CountSelectedMediaItems(0)
    if itemnum == 0 then joshnt.TooltipAtMouse("No items selected!") return end
    local window, segment, details = reaper.BR_GetMouseCursorContext()
    local mousePosX = reaper.BR_GetMouseCursorContext_Position()
    if not window or window == "" or not mousePosX or mousePosX == -1 then joshnt.TooltipAtMouse("Unable to get mouse context or position") return end

    reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)
    
    -- Snap xPos to grid (if snapping is toggled & grid active)
    if reaper.GetToggleCommandState(1157) == 1 then -- options: toggle snapping
      mousePosX = reaper.SnapToGrid(0,mousePosX)
    end

    local startPos = reaper.GetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0,0), "D_POSITION")
    local itemArray = {}
    for i = 0, itemnum -1 do
      itemArray[i] = reaper.GetSelectedMediaItem(0,i)
    end

    for i = 0, itemnum -1 do
        local item_TEMP = itemArray[i]
        local oldPos_TEMP = reaper.GetMediaItemInfo_Value(item_TEMP, "D_POSITION")
        reaper.SetMediaItemInfo_Value(item_TEMP, "D_POSITION", mousePosX + oldPos_TEMP - startPos)
    end

    reaper.UpdateArrange() reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock('Move selected items to mouse - time relative on same track', -1)
end

main()