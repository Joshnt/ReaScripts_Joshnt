-- @noindex

-- Load lua utilities
local joshnt_LuaUtils = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/DEVELOPMENT/joshnt_LuaUtilities.lua'
if reaper.file_exists( joshnt_LuaUtils ) then 
  dofile( joshnt_LuaUtils ) 
  if not joshnt or joshnt.version() < 3.4 then 
    reaper.MB("This script requires a newer version of joshnt Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages, 'joshnt_LuaUtilities.lua'","Error",0); 
    return 
  end
else 
  reaper.MB("This script requires joshnt Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt Lua Utilities'","Error",0)
  return
end

-- Load snapshot core utilities
local joshnt_SnapshotCore = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/VARIOUS/joshnt_Save Item Snapshots in project/joshnt_Item Snapshots - CORE.lua'
if reaper.file_exists( joshnt_SnapshotCore ) then 
  dofile( joshnt_SnapshotCore ) 
else 
  reaper.MB("This script requires an additional script, which gets installed over ReaPack as well. Please re-install the whole 'Item Snapshots' Pack here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt_Save Item Snapshots in project","Error",0)
  return
end 

local function loadSlot()

  local slot_num = joshnt.getNumberInScriptName()

  if slot_num then
    local sectionName = "joshnt_itemSnapshot"..slot_num
    if reaper.EnumProjExtState(0, sectionName, 0) then
      joshnt_savedItems.restoreInTimeSelection(sectionName, true, false)
    else
      joshnt.msg("No directory saved in Slot #" .. slot_num .. "!\n\nPlease run the action joshnt_Save All Items (Snapshot) to Slot " .. slot_num .. ".lua or \njoshnt_Save Selected Items (Snapshot) to Slot " .. slot_num .. ".lua")
    end
  else
    joshnt.msg("No slot number found in script name!\n\nPlease edit script name and include a slot number.")
  end

end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

loadSlot()

reaper.Undo_EndBlock(joshnt.getScriptName(),-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()