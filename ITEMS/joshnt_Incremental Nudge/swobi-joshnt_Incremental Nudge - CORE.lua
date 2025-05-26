-- @noindex

joshnt_repostion = {}

function joshnt_repostion.main(num_tracks, unit, num)
  if reaper.CountSelectedMediaItems(0) == 0 then
    reaper.MB("Please select at least one item to reposition.", "No Items Selected", 0)
    return
  end

  if not unit or (unit ~= "grid" and unit ~= "seconds" and unit ~= "second" and unit ~= "beats" and unit ~= "beat") then
    reaper.MB("Invalid parameters. Please ensure the script is called with valid arguments.", "Error", 0)
    return
  end

  local continue = true;
  local s;
  local usedInput = false;
  if num ~= "X" and num_tracks == "X" then 
    usedInput = true;
    continue, s = reaper.GetUserInputs("joshnt_Reposition - "..unit, 1,
      "Number of tracks to move together", "2");
  elseif num == "X" and num_tracks == "X" then 
    usedInput = true;
    continue, s = reaper.GetUserInputs("joshnt_Reposition - "..unit, 2,
      "Number of tracks to move together,Units ("..unit..")", "2, 1");
  end

  
  if not continue then return end

  local retVal;
  if usedInput then retVal = joshnt.fromCSV(s) end
  if num_tracks == "X" then
    num_tracks = retVal[1]:match("(%d+)")
  end
  if num == "X" then
    num = retVal[2]:match("(%d+)")
  end
  num_tracks = tonumber(num_tracks)
  num = tonumber(num)
  if not num_tracks or not type(num_tracks) == "number" or num_tracks < 1 then
    reaper.MB("Please enter a valid number of tracks to move together (minimum 1).", "Invalid Input", 0)
    return
  end
  if not num or not type(num) == "number" then
    reaper.MB("Please enter a valid number of units to move (minimum 1) instead of "..tostring(num), "Invalid Input", 0)
    return
  end

  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  local tracks = joshnt.getTracksOfSelectedItems()
  joshnt.unselectAllTracks()
  joshnt.reselectTracks(tracks)
  local firstTrack = reaper.GetSelectedTrack(0, 0)
  local firstTrackIndex = reaper.GetMediaTrackInfo_Value(firstTrack, "IP_TRACKNUMBER")
  local originalSelection = joshnt.saveItemSelection()
  local trackTable = joshnt.sortSelectedItemsByTrack()

  local couldFinish = true;

  for track, items in pairs(trackTable) do
    reaper.SelectAllMediaItems(0, false) -- Deselect all items

    if #items > 0 then
      local trackIndex = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
      if trackIndex > firstTrackIndex then 

        joshnt.reselectItems(items)
        local multiplier = math.floor((trackIndex-firstTrackIndex)/num_tracks)
        if (trackIndex-firstTrackIndex) % num_tracks ~= 0 then
          couldFinish = false
        else 
          couldFinish = true
        end
        local move_amount = num * multiplier;
        local reverse = false;
        if move_amount < 0 then
          move_amount = -move_amount;
          reverse = true;
        end
        if unit == "grid" then
          reaper.ApplyNudge(0, 0, 0, 2, move_amount, reverse, 0)
        elseif unit == "seconds" or unit == "second" then
          reaper.ApplyNudge(0, 0, 0, 1, move_amount, reverse, 0)
        elseif unit == "beats" or unit == "beat" then
          reaper.ApplyNudge(0, 0, 0, 13, move_amount, reverse, 0)
        end
      end
    end
  end

  joshnt.reselectItems(originalSelection)

  if not couldFinish then
    reaper.MB("Your number of selected items was not dividable by the given number of tracks of "..num_tracks..".\nThis means the last nudged tracks are less then "..num_tracks..".", "joshnt_Reposition - Warning", 0)
  end

  reaper.Undo_EndBlock("Reposition items on " .. num_tracks .. " tracks vertically by " .. num .. " " .. unit, -1)
  reaper.PreventUIRefresh(-1)
end

return joshnt_repostion