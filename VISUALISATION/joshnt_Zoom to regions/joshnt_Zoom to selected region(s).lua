-- @description Zoom selected regions - horizontally and vertically
-- @version 1.0
-- @author Joshnt
-- @about
--    Zoom to regions selected in region/ marker manager
-- @changelog
--  + init

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

if not joshnt.checkJS_API() then return end

local function main()
  local timeRangeStart, timeRangeEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  reaper.PreventUIRefresh(1)
  local selRgnTable = joshnt.getSelectedMarkerAndRegionIndex()
  if selRgnTable == nil then 
      joshnt.TooltipAtMouse("No region selected")
      return 
  end

  local regSelStart = math.huge
  local regSelEnd = 0
  local itemsInRgn = {}

  reaper.SelectAllMediaItems(0, false)

  for index, rgnIndex in ipairs(selRgnTable) do
      local regStart_TEMP, regEnd_TEMP = joshnt.getRegionBoundsByIndex(rgnIndex)
      regSelStart = math.min(regSelStart,regStart_TEMP)
      regSelEnd = math.max(regSelEnd, regEnd_TEMP)
      reaper.GetSet_LoopTimeRange(true, false, regStart_TEMP, regEnd_TEMP, false)
      reaper.Main_OnCommand(40717,0) -- select all items in teimeselection
      for i = 0, reaper.CountSelectedMediaItems() -1 do
        table.insert(itemsInRgn,reaper.GetSelectedMediaItem(0,i))
      end
  end

  reaper.SelectAllMediaItems(0, false)
  joshnt.reselectItems(itemsInRgn)

  reaper.UpdateArrange()
  local numItems = reaper.CountSelectedMediaItems()
  if numItems == 0 then 
      joshnt.TooltipAtMouse("No items in current region(s) to zoom at")
  end

  reaper.GetSet_LoopTimeRange(true, false, regSelStart, regSelEnd, false)
  reaper.SetEditCurPos(regSelStart, false, false)
  reaper.PreventUIRefresh(-1) 
  
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_VZOOMIITEMS"),0) -- vertical zoom to selected items
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_ZOOMSIT"),0) -- zoom to timeselection
  reaper.PreventUIRefresh(1) 
  joshnt.unselectAllTracks()
  reaper.SelectAllMediaItems(0, false)
  reaper.GetSet_LoopTimeRange(true, false, timeRangeStart, timeRangeEnd, false)
  reaper.PreventUIRefresh(-1)
end

reaper.Undo_BeginBlock()
main()
reaper.UpdateArrange()
reaper.Undo_EndBlock('Zoom to selected regions', -1)