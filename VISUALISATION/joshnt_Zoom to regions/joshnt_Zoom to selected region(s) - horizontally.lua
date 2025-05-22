-- @noindex

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

if not joshnt.checkSWS() then return end

if not joshnt.checkJS_API() then return end

local function main()
  local timeRangeStart, timeRangeEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  local curPos = reaper.GetCursorPosition()
    local selRgnTable = joshnt.getSelectedMarkerAndRegionIndex()
    if selRgnTable == nil then 
        joshnt.TooltipAtMouse("No region selected")
        return 
    end

    local regSelStart = math.huge
    local regSelEnd = 0

    for index, rgnIndex in ipairs(selRgnTable) do
        local regStart_TEMP, regEnd_TEMP = joshnt.getRegionBoundsByIndex(rgnIndex)
        regSelStart = math.min(regSelStart, regStart_TEMP)
        regSelEnd = math.max(regSelEnd, regEnd_TEMP)
    end

    -- timeselect region
    reaper.GetSet_LoopTimeRange(true, false, regSelStart, regSelEnd, false)
    reaper.SelectAllMediaItems(0, false)
    reaper.MoveEditCursor(curPos-regSelStart, 0)
    reaper.UpdateArrange()
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_ZOOMSIT"),0) -- zoom to timeselection

    reaper.GetSet_LoopTimeRange(true, false, timeRangeStart, timeRangeEnd, false)
    joshnt.unselectAllTracks()
    reaper.SelectAllMediaItems(0, false)
end

reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)
main()
reaper.PreventUIRefresh(-1) 
reaper.UpdateArrange()
reaper.Undo_EndBlock('horizontally zoom to selected regions', -1)