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

local numItemsTotal = reaper.CountMediaItems(0)
if numItemsTotal == 0 then joshnt.TooltipAtMouse("No items in project") return end


local function selectNextItem(timeInput)
  local itemToSelect = {};
  local itemToSelectStart = math.huge

  local timeRangeStart, timeRangeEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  reaper.GetSet_LoopTimeRange(true, false, timeInput-0.5, reaper.GetProjectLength(0), false)
  reaper.SelectAllMediaItems(0, false)
  reaper.Main_OnCommand(40717,0) -- select all items in teimeselection
  reaper.GetSet_LoopTimeRange(true, false, timeRangeStart, timeRangeEnd, false)
  for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    local itemTemp = reaper.GetSelectedMediaItem(0, i)
    if itemTemp then
      local start_pos_TEMP = reaper.GetMediaItemInfo_Value(itemTemp, "D_POSITION")
      local end_pos_TEMP = start_pos_TEMP + reaper.GetMediaItemInfo_Value(itemTemp, "D_LENGTH")
      if start_pos_TEMP > timeInput and itemToSelectStart >= start_pos_TEMP then
        if itemToSelectStart == start_pos_TEMP then
          itemToSelect[#itemToSelect+1] = itemTemp
        else
          joshnt.allValuesEqualTo(itemToSelect,nil)
          itemToSelect[1] = itemTemp
          itemToSelectStart = start_pos_TEMP
        end
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
    return itemToSelectStart;
  else
    joshnt.TooltipAtMouse("No next item found")
    return nil
  end
end

local function main()
  local cursorPos = reaper.GetCursorPosition() 
  local itemStart = selectNextItem(cursorPos)
  if itemStart then
    reaper.SetEditCurPos(itemStart, true, true)
  end
end

reaper.PreventUIRefresh(1) 
reaper.Undo_BeginBlock()  
main()
reaper.Undo_EndBlock("Select next item from cursor (across tracks)", -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()