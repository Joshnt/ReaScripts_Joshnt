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

local function saveSlot()

  local slot_num = joshnt.getNumberInScriptName()
  if slot_num then
    local sectionName = "joshnt_itemSnapshot"..slot_num
    if reaper.EnumProjExtState(0, sectionName, 0) then
      local response = reaper.MB("Slot #" .. slot_num .. " already exists!\n\nPlease delete it first or use another slot number.\n\nWould you like to overwrite it?", joshnt.getScriptName(), 4)
      if response == 6 then
        joshnt_savedItems.clearSnapshotForSection(sectionName)
        saveSlot()
      end
      return
    end
    joshnt_savedItems.saveAllItemsToSection(sectionName)
  else
    joshnt.msg("No slot number found in script name!\n\nPlease edit script name and include a slot number.")
  end
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

saveSlot()

reaper.Undo_EndBlock(joshnt.getScriptName(),-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()
