-- @noindex

---------------------------------------
--------- USER CONFIG - EDIT ME -------
--- Default Values for input dialog ---
---------------------------------------

local timeAdded_USER = 1 -- as script name suggest 1 second removed per script execution; change to your liking
local ignoreItemsAtBounds_USER = 1 -- if items are found at start or end of time selection: 0 doesn't execute script, 1 asks for permission, 2 executes the script anyway

---------------------------------------
---------- USER CONFIG END ------------
---------------------------------------

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

local function nothing() end; local function bla() reaper.defer(nothing) end

local startTime, endTime = reaper.GetSet_LoopTimeRange(false,false,0,0,false)
startTime = startTime - 0.000001 -- for working with regions; region would get weirdly streteched


reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)

if ignoreItemsAtBounds_USER ~= 2 then
  local item_TEMP = joshnt.saveItemSelection()
  local itemsBetween = false
  -- check start of time selection
  reaper.SelectAllMediaItems(0, false)
  reaper.GetSet_LoopTimeRange(true, false, startTime-timeAdded_USER, startTime, false)
  reaper.Main_OnCommand(40717,0) -- select all items in timeselection
  if reaper.CountSelectedMediaItems(0) > 0 then
    itemsBetween = true
  end

  -- check end of time selection
  reaper.SelectAllMediaItems(0, false)
  reaper.GetSet_LoopTimeRange(true, false, endTime, endTime+timeAdded_USER, false)
  reaper.Main_OnCommand(40717,0) -- select all items in timeselection
  if reaper.CountSelectedMediaItems(0) > 0 then
    itemsBetween = true
  end

  reaper.SelectAllMediaItems(0, false)
  joshnt.reselectItems(item_TEMP)

  if itemsBetween == true then
    if ignoreItemsAtBounds_USER == 0 then
      joshnt.TooltipAtMouse("canceled script - items overlapping timeselection bounds")
      return
    else
      if reaper.MB("Found items overlapping timeselection bounds. Execute anyway and split items?","CAUTION",4) == 7 then
        return
      end
    end
  end
end

reaper.GetSet_LoopTimeRange(true, false, endTime, endTime + timeAdded_USER, false)
reaper.Main_OnCommand(40201, 0) -- remove Time
reaper.GetSet_LoopTimeRange(true, false, startTime - timeAdded_USER, startTime, false)
reaper.Main_OnCommand(40201, 0) -- remove Time
reaper.GetSet_LoopTimeRange(true, false, startTime - timeAdded_USER, endTime - timeAdded_USER, false)

reaper.PreventUIRefresh(-1) 
reaper.UpdateArrange()
reaper.Undo_EndBlock('Remove Time at borders of time selection', -1)