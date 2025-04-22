-- @noindex

-- Load lua utilities
local joshnt_LuaUtils = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/DEVELOPMENT/joshnt_LuaUtilities.lua'
if reaper.file_exists( joshnt_LuaUtils ) then 
  dofile( joshnt_LuaUtils ) 
  if not joshnt or joshnt.version() < 3.5 then 
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
  if not joshnt_SnapshotCore or joshnt.version() < 1.0 then 
    reaper.MB("This script requires a newer version of the 'Item Snapshots' Pack. Please run:\n\nExtensions > ReaPack > Browse Packages > 'joshnt_Save Item Snapshots in project'","Error",0); 
    return 
  end
else 
  reaper.MB("This script requires an additional script-package, which gets installed over ReaPack as well. Please (re-)install the whole 'Item Snapshots' Pack here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt_Save Item Snapshots in project","Error",0)
  return
end 

local start_time_loop, end_time_loop = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)

if start_time_loop == end_time_loop then 
    joshnt.msg("No time selection found!\n\nPlease create a time selection over the loop(s) you want to revert.")
    return
end

local sectionName = "joshnt_SnapshotItems_Loop"
if not reaper.EnumProjExtState(0, sectionName, 0) then
    joshnt.msg("No items have been saved to be restored now!\n\nPlease run the action \njoshnt_Create seamless loop in selected items, re-extend and create '#' region over loop - use timeselection over first selected item as reference - single region revert possible.lua\n\nbefore.")
    return
end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

reaper.Main_OnCommand(40717 ,0) -- select items in time selection
joshnt.unselectMidiItems()
reaper.Main_OnCommand(40309, 0) -- Ripple editing off
reaper.Main_OnCommand(40006,0) -- delete selected Items

local indexTable, _, _, _, _, nameTable = joshnt.getAllOverlappingRegion(start_time_loop-0.01, end_time_loop+0.01)

if #indexTable > 0 then 
    for i = 1, #indexTable do 
        if tostring(nameTable[i]) == "#" then 
            reaper.DeleteProjectMarker(0, indexTable[i], true)
        end
    end
end

joshnt_savedItems.restoreInTimeSelection(sectionName, true, false)

reaper.Undo_EndBlock("Revert seamless loop at time-selection", -1) -- End of the undo block. Leave it at the bottom of your main function.

reaper.UpdateArrange()

reaper.PreventUIRefresh(-1)