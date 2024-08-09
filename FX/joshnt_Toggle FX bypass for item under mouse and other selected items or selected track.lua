-- @description Toggle FX Bypass for item under mouse or selected Track
-- @version 1.11
-- @changelog
--  + init
-- @author Joshnt
-- @about
--  allows for single shortcut to bypass either item or track FX, depending on mouse position


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

local function bypassFXItems(mainItem)
    reaper.SetMediaItemSelected(mainItem, true)

    local take = reaper.GetActiveTake(mainItem)
    if take then
        -- Get the number of FX on the take
        local num_fx = reaper.TakeFX_GetCount(take)
        -- Check if there is at least one FX on the take
        if num_fx == 0 then
            joshnt.TooltipAtMouse("Item under mouse has no FX - no bypass has been changed.") return
        end
    else
        joshnt.TooltipAtMouse("No active take found - no bypass has been changed.") return
    end

    reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_TGL_TAKEFX_BYP"),0)
end

local function bypassFXTrack(trackUnderMouse)
  if trackUnderMouse then 
    reaper.SetTrackSelected(trackUnderMouse, true)
  end
  reaper.Main_OnCommand(8,0)
end

local function main()
    local window, segment, details = reaper.BR_GetMouseCursorContext()
    local mouse = reaper.BR_GetMouseCursorContext_Position()
    if not mouse or mouse ==-1 then bypassFXTrack() return end

    local trackUnderMouse = reaper.BR_GetMouseCursorContext_Track()

    local mainItem = reaper.BR_GetMouseCursorContext_Item()
    if not mainItem or mainItem ==-1 then bypassFXTrack(trackUnderMouse) return else
      done = "items" 
      bypassFXItems(mainItem) 
      return
    end
end




reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)
main()
reaper.UpdateArrange() reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock('Toggle bypass FX for selected '.. done, -1)