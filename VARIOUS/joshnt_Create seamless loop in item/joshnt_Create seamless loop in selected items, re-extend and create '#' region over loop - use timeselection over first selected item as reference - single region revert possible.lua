-- @noindex

-- Load snapshot core utilities
local joshnt_SnapshotCore = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/VARIOUS/joshnt_Save Item Snapshots in project/joshnt_Item Snapshots - CORE.lua'
if reaper.file_exists( joshnt_SnapshotCore ) then 
  dofile( joshnt_SnapshotCore ) 
else 
  reaper.MB("This script requires an additional script-package, which gets installed over ReaPack as well. Please (re-)install the whole 'Item Snapshots' Pack here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt_Save Item Snapshots in project","Error",0)
  return
end 

-- execute main function
local seamlessLoop = reaper.GetResourcePath().."/Scripts/Joshnt_ReaScripts/VARIOUS/joshnt_Create seamless loop in item/joshnt_Create seamless loop in selected items, re-extend and create '#' region over loop - use timeselection over first selected item as reference.lua"
if not reaper.file_exists( seamlessLoop ) then 
  reaper.MB("The package seems to be corrupted ('joshnt_Create seamless loop in selected items, re-extend and create '#' region over loop - use timeselection over first selected item as reference.lua' could not be found.)\nPlease reinstall it here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt_Create seamless loop in item","Error",0)
  return
end


local sectionName = "joshnt_SnapshotItems_Loop"

local function saveSlot()
  if reaper.EnumProjExtState(0, sectionName, 0) then
    local response = reaper.MB("The item saving slot for Loop-Restoring already exists!\n\nWould you like to overwrite it?\nPress 'Yes' to overwrite it and 'No' to run the script without saving the currently selected items.", "joshnt_Error", 3)
    if response == 6 then
      joshnt_savedItems.clearSnapshotForSection(sectionName)
    elseif response == 7 then
    else return end
  end
  joshnt_savedItems.saveSelectedItemsToSection(sectionName)
end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

saveSlot()

reaper.Undo_EndBlock("Save Items pre seamless loop", -1) -- End of the undo block. Leave it at the bottom of your main function.
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)

dofile(seamlessLoop)


