-- @description Show volume for item or track depending on mouse context
-- @version 1.11
-- @author Joshnt
-- @about
--    Adaption of amagalma's version of this idea; checks for items under mouse cursor, then selected track(s) then track under mouse cursor
-- @changelog
--  + init

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

local done = "track"

local function volEnvItems(mainItem)
  local prevItemSel = joshnt.saveItemSelection()
  local setVolEnvVisible = ""
  reaper.SelectAllMediaItems(0, false)
  reaper.SetMediaItemSelected(mainItem, true)

  -- Get the active take of the selected item
  local take = reaper.GetActiveTake(mainItem)
  if not take then joshnt.TooltipAtMouse("No active take found in the selected item!") return end

  -- Get the take's volume envelope
  local envelope = reaper.GetTakeEnvelopeByName(take, "Volume")
  if envelope then

    local volEnvVisibleMain;
    local retval, chunk = reaper.GetEnvelopeStateChunk(envelope, "", false)
    if retval then
        -- Look for the "VIS" flag in the state chunk
        local visFlag = chunk:match("VIS (%d+)")
        if visFlag then
          volEnvVisibleMain = tonumber(visFlag) == 1
        end
    end
    setVolEnvVisible = ""

    if volEnvVisibleMain then 
      setVolEnvVisible = "_S&M_TAKEENVSHOW4" -- if visible, hide
    else
      setVolEnvVisible = "_S&M_TAKEENVSHOW1" -- if hidden, show
    end
  else
    setVolEnvVisible = "_S&M_TAKEENVSHOW1" -- if hidden, show
  end

  joshnt.reselectItems(prevItemSel)
  local numItems = reaper.CountSelectedMediaItems(0)
  for i = 0, numItems do
    local item = reaper.GetSelectedMediaItem(0,i)
    if item then
      reaper.Main_OnCommand(reaper.NamedCommandLookup(setVolEnvVisible),0)
    end
  end
end

local function volEnvTrack(trackUnderMouse)
  local isVisibleMain;
  local selTracks = joshnt.saveTrackSelection()
  local selTrackNum = #selTracks
  local trackMain = reaper.GetSelectedTrack(0, 0)

  if not trackMain then
    if trackUnderMouse then
      reaper.SetOnlyTrackSelected(trackUnderMouse)
      reaper.Main_OnCommand(40406, 0) -- Track: Toggle track volume envelope visible
      reaper.SetTrackSelected(trackUnderMouse, false)
    else joshnt.TooltipAtMouse("No item under mouse cursor, selected track or track under mouse cursor found!") return end
  else
    -- Get the track's volume envelope
    reaper.SetOnlyTrackSelected(trackMain)
    local envelope = reaper.GetTrackEnvelopeByName(trackMain, "Volume")
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
    reaper.Main_OnCommand(40406, 0) -- Track: Toggle track volume envelope visible
  end


  if selTrackNum > 1 then
    for i = 1, selTrackNum do
      local trackOther = selTracks[i]
      if trackOther and trackOther ~= trackMain then 
        reaper.SetOnlyTrackSelected(trackOther)
        -- Get the track's volume envelope
        local envelope = reaper.GetTrackEnvelopeByName(trackOther, "Volume")
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
          reaper.Main_OnCommand(40406, 0) -- Track: Toggle track volume envelope visible
        end
      end
    end
  end

  joshnt.reselectTracks(selTracks)

end

local function main()
    local window, segment, details = reaper.BR_GetMouseCursorContext()
    local mouse = reaper.BR_GetMouseCursorContext_Position()
    if not mouse or mouse ==-1 then volEnvTrack() return end

    local trackUnderMouse = reaper.BR_GetMouseCursorContext_Track()

    local mainItem = reaper.BR_GetMouseCursorContext_Item()
    if not mainItem or mainItem ==-1 then volEnvTrack(trackUnderMouse) return else
      done = "items" 
      volEnvItems(mainItem) 
      return
    end
end




reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)
main()
reaper.UpdateArrange() reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock('Toggle show Volume envelope for selected '.. done, -1)

