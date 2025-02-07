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

  local targetRegion, reg_Start, reg_End, _, _, reg_Name = joshnt.getAllOverlappingRegion(0, reaper.GetProjectLength(0)) -- get all regions in project
  for i = 1, #targetRegion do
    reaper.AddProjectMarker(0, false, reg_Start[i], reg_Start[i], reg_Name[i]..nameStartSuffix, -1)
    reaper.AddProjectMarker(0, false, reg_End[i], reg_End[i], reg_Name[i]..nameEndSuffix, -1)
  end
end

reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)
main()
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock('joshnt add markers to region bounds - all', -1)