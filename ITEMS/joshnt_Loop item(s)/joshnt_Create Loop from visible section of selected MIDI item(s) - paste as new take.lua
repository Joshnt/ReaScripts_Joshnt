-- @noindex

-- Load lua utilities
local joshnt_LuaUtils = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/DEVELOPMENT/joshnt_LuaUtilities.lua'
if reaper.file_exists( joshnt_LuaUtils ) then 
  dofile( joshnt_LuaUtils ) 
  if not joshnt or joshnt.version() < 2.20 then 
    reaper.MB("This script requires a newer version of joshnt Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages, 'joshnt_LuaUtilities.lua'","Error",0); 
    return 
  end
else 
  reaper.MB("This script requires joshnt Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt Lua Utilities'","Error",0)
  return
end

if not joshnt.checkSWS() then return end

local count = reaper.CountSelectedMediaItems(0)

if count > 0 then
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  
  local tooltip = ""

  -- Save selected item GUID list
  local new_items_list = {}
  local itemGUID_list = {}
  for i=0, count-1 do
    table.insert(itemGUID_list, reaper.BR_GetMediaItemGUID(reaper.GetSelectedMediaItem(0, i)))
  end
  local timeRangeStart, timeRangeEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  for i, sGUID in ipairs(itemGUID_list) do
    local item = reaper.BR_GetMediaItemByGUID(0, sGUID)
    local take = reaper.GetActiveTake(item)
    if take then
      local source = reaper.GetMediaItemTake_Source(take)
      reaper.SelectAllMediaItems(0, false)
      reaper.SetMediaItemSelected(item, true)
      if reaper.GetMediaSourceType(source, '') == 'MIDI' then
        local item_in = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
        local length = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
        local item_out = item_in + length
  
        reaper.Main_OnCommand(reaper.NamedCommandLookup('_S&M_COPY_TAKE'),0)
  
        reaper.GetSet_LoopTimeRange(true, false, item_in-1, item_out+1, false)
        reaper.Main_OnCommand(41385, 0) -- Item: Fit items to time selection, padding with silence if needed
        local itemRest = reaper.SplitMediaItem(item, item_out)
        reaper.DeleteTrackMediaItem(reaper.GetMediaItemTrack(itemRest), itemRest)
        itemRest = reaper.SplitMediaItem(item, item_in)
        reaper.DeleteTrackMediaItem(reaper.GetMediaItemTrack(item), item)
        item = itemRest
        
        reaper.Main_OnCommand(reaper.NamedCommandLookup('_SWS_LOOPITEMSECTION'),0)
        reaper.SetMediaItemSelected(item, true)
        reaper.Main_OnCommand(reaper.NamedCommandLookup('_S&M_PASTE_TAKE'),0)
      else
        tooltip = "One or more non-midi items were selected\nNo settings changed on those" 
      end
    else
      tooltip = "One or more non-midi items were selected\nNo settings changed on those" 
    end
    table.insert(new_items_list, item)
  end
  
  reaper.GetSet_LoopTimeRange(true, false, timeRangeStart, timeRangeEnd, false) -- restore previous time selection
  
  reaper.SelectAllMediaItems(0, false)
  joshnt.reselectItems(new_items_list)
  
  reaper.Undo_EndBlock("Loop section of midi item (paste as take)",0)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  
  if tooltip ~= "" then
    joshnt.TooltipAtMouse(tooltip)
  end
else
    joshnt.TooltipAtMouse("No items selected!")
end