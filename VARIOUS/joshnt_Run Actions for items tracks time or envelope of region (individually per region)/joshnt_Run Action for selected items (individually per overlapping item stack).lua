-- @noindex

---------------------------------------
--------- USER CONFIG - EDIT ME -------
---------------------------------------

local selectTracks = true -- if false, actions regarding tracks won't work
local selectTime = true -- if false, actions regarding time won't work
local selectEnvelopePoints = true -- if false, actions regarding Envelopes won't work
local promptAfterEachRegion = false -- allows what happend after each execution

---------------------------------------
---------- USER CONFIG END ------------
---------------------------------------

local joshnt_LuaUtils = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/DEVELOPMENT/joshnt_LuaUtilities.lua'
if reaper.file_exists( joshnt_LuaUtils ) then 
  dofile( joshnt_LuaUtils ) 
  if not joshnt or joshnt.version() < 3.7 then 
    reaper.MB("This script requires a newer version of joshnt Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages, 'joshnt_LuaUtilities.lua'","Error",0); 
    return 
  end
else 
  reaper.MB("This script requires joshnt Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt Lua Utilities'","Error",0)
  return
end

-- para-Global variables
local selected_action_id = 0
if reaper.CountSelectedMediaItems(0) == 0 then
  reaper.MB("No items selected. Please select at least one item.","Error",0)
  return
end
local itemGroups, itemStarts, itemEnds = joshnt.getOverlappingItemGroupsOfSelectedItems()
if #itemGroups == 0 or itemGroups == nil or itemStarts == nil or itemEnds == nil then
  reaper.MB("No overlapping items found. Please select at least one item.","Error",0)
  return
end

local function runAction()
  local realActionID = reaper.NamedCommandLookup(selected_action_id)
  local actionName = reaper.kbd_getTextFromCmd(realActionID,0)
  if realActionID == 0 then reaper.MB("Invalid Action selected.", "Error",0) return end

  
  for j=1, #itemGroups do

    reaper.Main_OnCommand(40769,0) -- unselect everything

    -- selection part
    if selectTime then
      reaper.GetSet_LoopTimeRange(true, false, itemStarts[j], itemEnds[j], false) -- select Time
    end

    -- select Items
    joshnt.reselectItems(itemGroups[j])
    local numItems = reaper.CountSelectedMediaItems(0)

    -- select Tracks
    for i = 0, numItems -1 do
      local itemTemp = reaper.GetSelectedMediaItem(0,i)
      local trackTemp = reaper.GetMediaItem_Track(itemTemp)
      reaper.SetTrackSelected(trackTemp,true)
    end

    -- select Envelope Points
    if selectEnvelopePoints then
      reaper.Main_OnCommand(40888,0) -- show all active envelopes
      for i = 0, reaper.CountSelectedTracks()-1 do
        local track = reaper.GetSelectedTrack(0,i)
        for e = 0, reaper.CountTrackEnvelopes(reaper.GetSelectedTrack(0,i)) - 1 do
          local envelope = reaper.GetTrackEnvelope(track, e)
          for p = 0, reaper.CountEnvelopePoints(envelope) - 1 do
            local retval, time, value, shape, tension, selected = reaper.GetEnvelopePoint(envelope, p)
            -- Check if the point is within the time selection
            if time >= itemStarts[j] and time <= itemEnds[j] then
              -- Select the point
              reaper.SetEnvelopePoint(envelope, p, time, value, shape, tension, true, true)
            end
          end
          reaper.Envelope_SortPoints(envelope)
        end
      end
    end

    -- unselect time/ items/ tracks, if adjusted by user (after selecting, because envelope is depending on everything else)
    if selectTime == false then reaper.GetSet_LoopTimeRange(true, false, 0, 0, false) end-- unselect Time
    if selectTracks == false then joshnt.unselectAllTracks() end

    reaper.Undo_BeginBlock()
    reaper.Main_OnCommand(realActionID, 0)
    reaper.Undo_EndBlock("Run '"..actionName.."' for index " .. j .. " overlapping items of selected items", -1)
    
    if promptAfterEachRegion and j ~= #itemGroups then
      reaper.UpdateArrange()
      local messageText = "Executed Action:\n'"..actionName.."' for " .. j .. "overlapping items of selected items.\n\n Continue with next region?"
      if reaper.MB(messageText,"Wait for User",1) ~= 1 then
        return
      end
    end
  end
end

local function getSelectedAction()
    selected_action_id = reaper.PromptForAction(0,0,0)
    if selected_action_id == 0 then
        reaper.defer(getSelectedAction)
    elseif selected_action_id == -1 then
        joshnt.TooltipAtMouse("Action Input got cancelled")
    else
        reaper.PromptForAction(-1,0,0) -- close action window
        runAction()
    end
    
end

reaper.PromptForAction(1,0,0)
getSelectedAction()
