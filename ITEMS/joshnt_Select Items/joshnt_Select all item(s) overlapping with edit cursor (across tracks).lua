-- @noindex
-- useful for finding the "where does that come from" in a huge project

---------------------------------------
--------- USER CONFIG - EDIT ME -------
--- Default Values for input dialog ---
---------------------------------------

local moveCursor = false

---------------------------------------
---------- USER CONFIG END ------------
---------------------------------------

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

local numItemsTotal = reaper.CountMediaItems(0)
if numItemsTotal == 0 then joshnt.TooltipAtMouse("No items in project") return end

local function selectAllOverlappingItem(timeInput)
  local itemToSelect = {};
  local itemToSelectStart = math.huge

  local timeRangeStart, timeRangeEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  reaper.GetSet_LoopTimeRange(true, false, timeInput-0.5, timeInput+0.5, false)
  reaper.SelectAllMediaItems(0, false)
  reaper.Main_OnCommand(40717,0) -- select all items in teimeselection
  reaper.GetSet_LoopTimeRange(true, false, timeRangeStart, timeRangeEnd, false)

  for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    local itemTemp = reaper.GetSelectedMediaItem(0, i)
    if itemTemp then
      local start_pos_TEMP = reaper.GetMediaItemInfo_Value(itemTemp, "D_POSITION")
      local end_pos_TEMP = start_pos_TEMP + reaper.GetMediaItemInfo_Value(itemTemp, "D_LENGTH")
      local mute = reaper.GetMediaItemInfo_Value(itemTemp, "B_MUTE") == 1
      if start_pos_TEMP <= timeInput and end_pos_TEMP > timeInput and not mute then
        if itemToSelectStart > start_pos_TEMP then itemToSelectStart = start_pos_TEMP end
        itemToSelect[#itemToSelect+1] = itemTemp
        itemToSelectStart = start_pos_TEMP
      end
    end
  end

  reaper.SelectAllMediaItems(0, false)

  if itemToSelect[1] ~= nil then
    for i = 1, #itemToSelect do
      if itemToSelect[i] then
        reaper.SetMediaItemSelected(itemToSelect[i], true)
      end
    end
    return itemToSelectStart
  else
    joshnt.TooltipAtMouse("No audible item overlapping with cursor")
    return nil
  end
end

local function main()
  local cursorPos = reaper.GetCursorPosition() 
  local itemStart = selectAllOverlappingItem(cursorPos)
  if itemStart and moveCursor then
    reaper.SetEditCurPos(itemStart, true, true)
  end
end

reaper.PreventUIRefresh(1) 
reaper.Undo_BeginBlock()  
main()
reaper.Undo_EndBlock("Select all items overlapping with cursor", -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()