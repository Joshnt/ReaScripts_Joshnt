-- @noindex


-- LOAD EXTERNALS
-- Load lua utilities
local joshnt_LuaUtils = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/DEVELOPMENT/joshnt_LuaUtilities.lua'
if reaper.file_exists( joshnt_LuaUtils ) then 
  dofile( joshnt_LuaUtils ) 
  if not joshnt or joshnt.version() < 3.3 then 
    reaper.MB("This script requires a newer version of joshnt Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages, 'joshnt_LuaUtilities.lua'","Error",0); 
    return 
  end
else 
  reaper.MB("This script requires joshnt Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt Lua Utilities'","Error",0)
  return
end


-- Delete Item
function DeleteItem(item)
  local track = reaper.GetMediaItem_Track(item)
  local retval reaper.DeleteTrackMediaItem(track, item)

  return retval
end


-- Split Item at Two Points, optionnaly keeping only middle section
function SplitItemAtSection(item, start_time, end_time)

  local middle_item = reaper.SplitMediaItem(item, start_time)

  local last_item = reaper.SplitMediaItem(middle_item, end_time)

  DeleteItem(item)
  DeleteItem(last_item)

  reaper.SetMediaItemInfo_Value(middle_item, "D_FADEINLEN", 0)
  reaper.SetMediaItemInfo_Value(middle_item, "D_FADEOUTLEN", 0)

  return middle_item

end

--------------------------------------------------------- END OF UTILITIES


-- Main function
function main(item)
  local original_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local original_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local original_endpos = original_len + original_pos

  -- Set new, adapted time selection per item
  local start_time = original_pos + start_time_Offset
  local end_time = original_endpos + end_time_Offset

  -- Split at Time Selection Edges
  item = SplitItemAtSection(item, start_time, end_time)

  local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

  -- Cut in Middle of Time Selection
  local new_item_pos = item_pos + item_len / 2
  local new_item = reaper.SplitMediaItem(item, new_item_pos)

  -- Invert items
  reaper.SetMediaItemInfo_Value(item, "D_POSITION", new_item_pos)
  reaper.SetMediaItemInfo_Value(new_item, "D_POSITION", item_pos)

  
  -- make overlap
  local length = item_len / 4
  reaper.BR_SetItemEdges(item, new_item_pos - length, end_time)
  reaper.BR_SetItemEdges(new_item, item_pos, new_item_pos + length)

  -- extend to original position
  local item_pos_temp = reaper.GetMediaItemInfo_Value(new_item, "D_POSITION")
  local item_len_temp = reaper.GetMediaItemInfo_Value(new_item, "D_LENGTH")
  local item_end_temp = item_pos_temp + item_len_temp
  reaper.BR_SetItemEdges(new_item, original_pos - ((end_time-start_time)/2), item_end_temp) -- left item
  item_pos_temp = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  reaper.BR_SetItemEdges(item, item_pos_temp, original_endpos + ((end_time-start_time)/2)) -- right item

  reaper.Main_OnCommand(41059, 0) -- Crossfade any overlappin items

  -- create '#' region (if not already existing)
  if not joshnt.tableContainsTable(regionTimeArray, {start_time, end_time}) then
    reaper.AddProjectMarker(0, true, start_time, end_time, "#", -1)
    regionTimeArray[#regionTimeArray + 1] = {start_time, end_time}
  end
end


-- INIT ---------------------------------------------------------------------


-- GET LOOP
start_time_loop, end_time_loop = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
regionTimeArray = {}

if start_time_loop ~= end_time_loop then

  local count_sel_items = reaper.CountSelectedMediaItems(0)

  if count_sel_items > 0 then
    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

    local itemReference = reaper.GetSelectedMediaItem(0, 0)

    local item_pos_Ref = reaper.GetMediaItemInfo_Value(itemReference, "D_POSITION")
    local item_len_Ref = reaper.GetMediaItemInfo_Value(itemReference, "D_LENGTH")
    local item_end_Ref = item_pos_Ref + item_len_Ref

    if item_pos_Ref <= start_time_loop and end_time_loop <= item_end_Ref then
      start_time_Offset = start_time_loop - item_pos_Ref
      end_time_Offset = end_time_loop - item_end_Ref
    else 
      reaper.ShowMessageBox("No time-selection over first selected item to use as reference\nor time selection larger than first item", "Error - Seamless loop", 0)
      return
    end

    local init_sel_items = joshnt.saveItemSelection()

    for i, item in ipairs(init_sel_items) do
      reaper.SelectAllMediaItems(0, false)

      reaper.SetMediaItemSelected(item, true)

      main(item)

    end

    reaper.SelectAllMediaItems(0, false)

    -- set original time selection
    reaper.GetSet_LoopTimeRange2(0, true, false, start_time_loop, end_time_loop, false)

    reaper.Undo_EndBlock("Create seamless loops from selected items sections inside time selection", -1) -- End of the undo block. Leave it at the bottom of your main function.

    reaper.UpdateArrange()

    reaper.PreventUIRefresh(-1)


  end -- if item selected

else -- if time selection

  reaper.MB("No time selection!","Error",0)

  return
end -- if time selection