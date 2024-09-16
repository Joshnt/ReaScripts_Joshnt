-- @description Show pan for item or track depending on mouse context
-- @version 1.0
-- @author Joshnt
-- @about
--    Adaption of amagalma's version of this idea (pan instead of volume); checks for items under mouse cursor, then selected track(s) then track under mouse cursor
-- @changelog
--  + init

-- Load lua utilities
local joshnt_LuaUtils = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/DEVELOPMENT/joshnt_LuaUtilities.lua'
if reaper.file_exists( joshnt_LuaUtils ) then 
  dofile( joshnt_LuaUtils ) 
  if not joshnt or joshnt.version() < 2.21 then 
    reaper.MB("This script requires a newer version of joshnt Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages, 'joshnt_LuaUtilities.lua'","Error",0); 
    return 
  end
else 
  reaper.MB("This script requires joshnt Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt Lua Utilities'","Error",0)
  return
end

if not joshnt.checkSWS() then return end

local done = "track"

local function panEnvItems(mainItem)
  local prevItemSel = joshnt.saveItemSelection()
  local setPanEnvVisible = ""
  reaper.SelectAllMediaItems(0, false)
  reaper.SetMediaItemSelected(mainItem, true)

  -- Get the active take of the selected item
  local take = reaper.GetActiveTake(mainItem)
  if not take then joshnt.TooltipAtMouse("No active take found in the selected item!") return end

  -- Get the take's pan envelope
  local envelope = reaper.GetTakeEnvelopeByName(take, "Pan")
  if envelope then

    local panEnvVisibleMain;
    local retval, chunk = reaper.GetEnvelopeStateChunk(envelope, "", false)
    if retval then
        -- Look for the "VIS" flag in the state chunk
        local visFlag = chunk:match("VIS (%d+)")
        if visFlag then
          panEnvVisibleMain = tonumber(visFlag) == 1
        end
    end
    setPanEnvVisible = ""

    if panEnvVisibleMain then 
      setPanEnvVisible = "_S&M_TAKEENVSHOW5" -- if visible, hide
    else
      setPanEnvVisible = "_S&M_TAKEENVSHOW2" -- if hidden, show
    end
  else
    setPanEnvVisible = "_S&M_TAKEENVSHOW2" -- if hidden, show
  end

  joshnt.reselectItems(prevItemSel)
  local numItems = reaper.CountSelectedMediaItems(0)
  for i = 0, numItems do
    local item = reaper.GetSelectedMediaItem(0,i)
    if item then
      reaper.Main_OnCommand(reaper.NamedCommandLookup(setPanEnvVisible),0)
    end
  end
end

local function panEnvTracks(trackUnderMouse)
  local isVisibleMain;
  local selTracks = joshnt.saveTrackSelection()
  local selTrackNum = #selTracks
  local trackMain = reaper.GetSelectedTrack2(0, 0, true)

  if not trackMain then
    if trackUnderMouse then
      reaper.SetOnlyTrackSelected(trackUnderMouse)
      reaper.Main_OnCommand(40407, 0) -- Track: Toggle track pan envelope visible
      reaper.SetTrackSelected(trackUnderMouse, false)
    else joshnt.TooltipAtMouse("No item under mouse cursor, selected track or track under mouse cursor found!") return end
  else
    -- Get the track's volume envelope
    reaper.SetOnlyTrackSelected(trackMain)
    local envelope = reaper.GetTrackEnvelopeByName(trackMain, "Pan")
    if not envelope then isVisibleMain = false
    else
      -- Check the visibility of the envelope
      local retval, envelopeState = reaper.GetEnvelopeStateChunk(envelope, "", false)
      isVisibleMain = false

      if envelopeState then
        -- Extract the VIS flag
        local visFlag = envelopeState:match('VIS (%d+)')
        if visFlag then
          isVisibleMain = tonumber(visFlag) == 1

        end
      end
    end
    reaper.Main_OnCommand(40407, 0) -- Track: Toggle track pan envelope visible
  end


  if selTrackNum > 1 then
    for i = 1, selTrackNum do
      local trackOther = selTracks[i]
      if trackOther and trackOther ~= trackMain then 
        reaper.SetOnlyTrackSelected(trackOther)
        -- Get the track's volume envelope
        local envelope = reaper.GetTrackEnvelopeByName(trackOther, "Pan")
        local isVisibleOther = false
        if envelope then
        
          -- Check the visibility of the envelope
          local retval, envelopeState = reaper.GetEnvelopeStateChunk(envelope, "", false)
          
          if envelopeState then
            -- Extract the VIS flag
            local visFlag = envelopeState:match('VIS (%d+)')
            if visFlag then
              isVisibleOther = tonumber(visFlag) == 1
            end
          end
        end

        if isVisibleOther == isVisibleMain then
          reaper.Main_OnCommand(40407, 0) -- Track: Toggle track volume envelope visible
        end
      end
    end
  end

  joshnt.reselectTracks(selTracks)

end

local function main()
    local window, segment, details = reaper.BR_GetMouseCursorContext()
    local mouse = reaper.BR_GetMouseCursorContext_Position()
    local trackUnderMouse = reaper.BR_GetMouseCursorContext_Track()
    if not mouse or mouse ==-1 then panEnvTracks(trackUnderMouse) return end

    local mainItem = reaper.BR_GetMouseCursorContext_Item()
    if not mainItem or mainItem ==-1 then panEnvTracks(trackUnderMouse) return else
      done = "items" 
      panEnvItems(mainItem) 
      return
    end
end




reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)
main()
reaper.UpdateArrange() reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock('Toggle show Pan envelope for selected '.. done, -1)

