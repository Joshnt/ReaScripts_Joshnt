-- @noindex

---------------------------------------
--------- USER CONFIG - EDIT ME -------
---------------------------------------

local nameStartSuffix = "_Start" -- results in start of region to be named "[RegionName] Start" 
local nameEndSuffix = "_End" -- results in end of region to be named "[RegionName] End" 

---------------------------------------
---------- USER CONFIG END ------------
---------------------------------------


local joshnt_LuaUtils = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/DEVELOPMENT/joshnt_LuaUtilities.lua'
if reaper.file_exists( joshnt_LuaUtils ) then 
  dofile( joshnt_LuaUtils ) 
  if not joshnt or joshnt.version() < 3.2 then 
    reaper.MB("This script requires a newer version of joshnt Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages, 'joshnt_LuaUtilities.lua'","Error",0); 
    return 
  end
else 
  reaper.MB("This script requires joshnt Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt Lua Utilities'","Error",0)
  return
end

if not joshnt.checkJS_API() then return end

local function main() 
  local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
  if not ret or num_regions == 0 then
      reaper.MB("No regions found in project!","joshnt_Error",0)
      return
  end
  local selectedRgns = joshnt.getSelectedMarkerAndRegionIndex()
  if selectedRgns == nil or selectedRgns[1] == nil then
    reaper.MB("No regions selected!","joshnt_Error",0)
      return
  end

  local num_total = num_markers + num_regions
  local reg_Start = {}
  local reg_End = {}
  local reg_Name = {}

  for j=0, num_total - 1 do
    local retval, isrgn, pos, rgnend, rgnname, markrgnindexnumber = reaper.EnumProjectMarkers( j )
    if isrgn then
      local isSelected = joshnt.tableContainsVal(selectedRgns, markrgnindexnumber)
      if isSelected then
        reg_Start[#reg_Start+1] = pos
        reg_End[#reg_End+1] = rgnend
        reg_Name[#reg_Name+1] = rgnname
      end
    end
  end
  
  for i = 1, #selectedRgns do
    reaper.DeleteProjectMarker(0, selectedRgns[i], true)
    reaper.AddProjectMarker(0, false, reg_Start[i], reg_Start[i], reg_Name[i]..nameStartSuffix, -1)
    reaper.AddProjectMarker(0, false, reg_End[i], reg_End[i], reg_Name[i]..nameEndSuffix, -1)
  end
end

reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)
main()
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock('joshnt convert regions to markers - all', -1)