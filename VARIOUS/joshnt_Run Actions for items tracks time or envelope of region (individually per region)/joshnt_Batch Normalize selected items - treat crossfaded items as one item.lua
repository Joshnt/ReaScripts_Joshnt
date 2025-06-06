-- @noindex

---------------------------------------
--------- USER CONFIG - EDIT ME -------
---------------------------------------

local promptAfterEachRegion = false -- allows what happend after each execution
---------------------------------------
---------- USER CONFIG END ------------
---------------------------------------
---
---
---
local actionName = "normalize selected items - TruePeak -6dB loudest item"

--- adapted from mpl_scripts: Normalize selected items takes loudness to XdB
local loudtype = 3 -- 0=LUFS-I, 1=RMS-I, 2=peak, 3=true peak, 4=LUFS-M max, 5=LUFS-S max
local loudvalue = -6 -- dBFS

local successDelete = true

local joshnt_LuaUtils = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/DEVELOPMENT/joshnt_LuaUtilities.lua'
if reaper.file_exists( joshnt_LuaUtils ) then 
  dofile( joshnt_LuaUtils ) 
  if not joshnt or joshnt.version() < 3.6 then 
    reaper.MB("This script requires a newer version of joshnt Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages, 'joshnt_LuaUtilities.lua'","Error",0); 
    return 
  end
else 
  reaper.MB("This script requires joshnt Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt Lua Utilities'","Error",0)
  return
end

-- para-Global variables
if reaper.CountSelectedMediaItems(0) == 0 then
  reaper.MB("No items selected. Please select at least one item.","Error",0)
  return
end

local itemGroups, itemStarts, itemEnds;
local trackName;

local failedItems = {}

local function runAction()
  reaper.Undo_BeginBlock()
  -- write in note to identify the item group - before glue to not undo
  local prevJ = 0
  for j=1, #itemGroups do
    reaper.Main_OnCommand(40769,0) -- unselect everything
    joshnt.reselectItems(itemGroups[j])
    local selItems_temp = reaper.CountSelectedMediaItems(0)
    for i = 0, selItems_temp-1 do
      -- Glue items to get gain
      local item = reaper.GetSelectedMediaItem(0,i)
      if item then 
        if not j then reaper.ShowConsoleMsg("Failed to get item group for "..prevJ+1)
        else joshnt.AppendToNoteItem(item, "itemGroup"..j, false) end
      end
    end
  end
  reaper.Undo_EndBlock("joshnt-Internal: write in Notes for items on track "..trackName, -1)

  reaper.Undo_BeginBlock()
  local gainArray = {}
  
  -- glue items and get gain
  for j=1, #itemGroups do

    reaper.Main_OnCommand(40769,0) -- unselect everything

    -- select Items
    joshnt.reselectItems(itemGroups[j])

    reaper.Main_OnCommand(40362,0) -- glue
    reaper.UpdateArrange()
    local selItems_temp = reaper.CountSelectedMediaItems(0)
    local track_gain_map = {} -- Table to hold take gains grouped by track
    reaper.Main_OnCommand(42461,0) -- normalize with recent settings
    for i = 0, selItems_temp-1 do
      -- Glue items to get gain
      local item = reaper.GetSelectedMediaItem(0,i)
      local track = reaper.GetMediaItemTrack(item)
      if item then 
        local take = reaper.GetActiveTake(item)
        if take then 
          local gain = reaper.GetMediaItemTakeInfo_Value(take, "D_VOL")
          track_gain_map[track] = gain
          local source = reaper.GetMediaItemTake_Source(take)
          if source then 
            local source_path = source and reaper.GetMediaSourceFileName(source, "")
            if source_path then 
              reaper.DeleteTrackMediaItem(track, item) 
              local success = os.remove(source_path)
              if not success then
                successDelete = false
              end
            end
          end
        end
      end
    end
    gainArray[j] = track_gain_map
  end

  
  reaper.Undo_EndBlock("get gain for item groups on track "..trackName, -1)
  reaper.Undo_DoUndo2(0)
  reaper.Undo_BeginBlock()

  for j=1, #itemGroups do
    reaper.Main_OnCommand(40769,0) -- unselect everything
    reaper.UpdateArrange()
    -- joshnt.reselectItems(itemGroups[j]) -- funktioniert nicht wegen glue und undo ._.
    -- select items on track
    reaper.GetSet_LoopTimeRange(true, false, itemStarts[j], itemEnds[j], false)
    reaper.UpdateArrange()
    reaper.Main_OnCommand(40717 ,0) -- select items in time selection

    local selItems_temp = reaper.CountSelectedMediaItems(0)

    -- apply gain to items
    for i = 0, selItems_temp-1 do
      local item = reaper.GetSelectedMediaItem(0,i)
      local track = reaper.GetMediaItemTrack(item)
      if item then 
        -- check if item is relevant
        if joshnt.CheckNoteofItem(item, "itemGroup"..j, false) then
          joshnt.RemoveFromNoteItem(item, "itemGroup"..j, false)
          local take = reaper.GetActiveTake(item)
          if take then 
            if not gainArray[j][track] then
              local _, name = reaper.GetTrackName(track)
              reaper.ShowConsoleMsg("Failed to set/ get gain for item Group "..j.." on track "..name)
              failedItems[#failedItems] = item
            else
              reaper.SetMediaItemTakeInfo_Value(take, 'D_VOL', gainArray[j][track])
            end
          end
        end
      end
    end


  end

  reaper.Undo_EndBlock("Normalized (overlapping) items on track "..trackName, -1)
  
end



reaper.PreventUIRefresh(1)
reaper.Main_OnCommand(42460,0) -- normalize with dialog
reaper.Main_OnCommand(40938,0) -- un normalize all

local itemByTrackTable = joshnt.sortSelectedItemsByTrack()



for tracks, items in pairs(itemByTrackTable) do
  reaper.Main_OnCommand(40769,0) -- unselect everything
  joshnt.reselectItems(items)
  itemGroups, itemStarts, itemEnds = joshnt.getOverlappingItemGroupsOfSelectedItems()
  _, trackName = reaper.GetTrackName(tracks)
  if #itemGroups == 0 or itemGroups == nil or itemStarts == nil or itemEnds == nil then
    reaper.ShowConsoleMsg("Failed to get items for Track "..trackName)
  else
    runAction()
  end
  
end



if failedItems[1] then
    joshnt.reselectItems(failedItems)
    reaper.UpdateArrange()
    reaper.ShowMessageBox("The now selected items could not be normalized.","Debug/Error - Normalize",0)
end

if not successDelete then
  reaper.MB("Failed to delete glued files to calculate loudness - consider doing that manually", "Error", 0)
end

reaper.Main_OnCommand(40769,0) -- unselect everything
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
