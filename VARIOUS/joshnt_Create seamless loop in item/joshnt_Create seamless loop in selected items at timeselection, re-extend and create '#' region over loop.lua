-- @noindex


-- LOAD EXTERNALS
-- Load lua utilities
local joshnt_LuaUtils = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/DEVELOPMENT/joshnt_LuaUtilities.lua'
if reaper.file_exists( joshnt_LuaUtils ) then 
  dofile( joshnt_LuaUtils ) 
  if not joshnt or joshnt.version() < 3.2 then 
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
end


-- INIT ---------------------------------------------------------------------


-- GET LOOP
start_time, end_time = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)

if start_time ~= end_time then

  local count_sel_items = reaper.CountSelectedMediaItems(0)

  if count_sel_items > 0 then

    reaper.PreventUIRefresh(1)

    reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

    local init_sel_items = joshnt.saveItemSelection()
    local anyInTS = false

    for i, item in ipairs(init_sel_items) do

      local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      local item_end = item_pos + item_len

      -- If time selection is inside item
      if item_pos < start_time and start_time < item_end and item_pos < end_time and end_time < item_end then

        reaper.SelectAllMediaItems(0, false)

        reaper.SetMediaItemSelected(item, true)

        main(item)

        anyInTS = true

      end

    end

    
    if anyInTS then 
      reaper.AddProjectMarker(0, true, start_time, end_time, "#", -1) 
      reaper.SelectAllMediaItems(0, false)
    else
      reaper.ShowMessageBox("No item item in time-selection! (No item changed)", "Error - Seamless loop", 0)
    end

    reaper.Undo_EndBlock("Create seamless loops from selected items sections inside time selection", -1) -- End of the undo block. Leave it at the bottom of your main function.

    reaper.UpdateArrange()

    reaper.PreventUIRefresh(-1)


  end -- if item selected

else -- if time selection

  reaper.MB("No time selection!","Error",0)

  return
end -- if time selection