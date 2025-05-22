-- @noindex

-- Load lua utilities
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

-- Load snapshot core utilities
local joshnt_SnapshotCore = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/VARIOUS/joshnt_Save Item Snapshots in project/joshnt_Item Snapshots - CORE.lua'
if reaper.file_exists( joshnt_SnapshotCore ) then 
  dofile( joshnt_SnapshotCore ) 
  if not joshnt_SnapshotCore or joshnt.version() < 3.7 then 
    reaper.MB("This script requires a newer version of the 'Item Snapshots' Pack. Please run:\n\nExtensions > ReaPack > Browse Packages > 'joshnt_Save Item Snapshots in project'","Error",0); 
    return 
  end
else 
  reaper.MB("This script requires an additional script-package, which gets installed over ReaPack as well. Please (re-)install the whole 'Item Snapshots' Pack here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt_Save Item Snapshots in project","Error",0)
  return
end 

local sectionName = "joshnt_SnapshotItems_Loop"

local function clearSlot()
  if reaper.EnumProjExtState(0, sectionName, 0) then
    local response = reaper.MB("Your seamless loops item edits will be deleted!\n\nAre you sure?", "Joshnt_Error", 4)
    if response == 6 then
      joshnt_savedItems.clearSnapshotForSection(sectionName)
    end
    return
  else 
    joshnt.msg("No saved item edits have been found to be cleared!")
  end
end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

clearSlot()

reaper.Undo_EndBlock("Clear saved item edits pre seamless loop", -1) -- End of the undo block. Leave it at the bottom of your main function.

reaper.UpdateArrange()

reaper.PreventUIRefresh(-1)