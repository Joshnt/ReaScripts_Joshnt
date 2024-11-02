-- @noindex

-- USERINPUT START
local groupTolerance = 0;
-- USERINPUT END

local joshnt_LuaUtils = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/DEVELOPMENT/joshnt_LuaUtilities.lua'
if reaper.file_exists( joshnt_LuaUtils ) then 
  dofile( joshnt_LuaUtils ) 
  if not joshnt or joshnt.version() < 3.0 then 
    reaper.MB("This script requires a newer version of joshnt Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages, 'joshnt_LuaUtilities.lua'","Error",0); 
    return 
  end
else 
  reaper.MB("This script requires joshnt Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt Lua Utilities'","Error",0)
  return
end

local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
local numSel = reaper.CountSelectedMediaItems(0)

if numSel == 0 then
  joshnt.TooltipAtMouse("No selected items.")
  return
end

if num_regions ~= 0 then
  reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)
  
  local _, itemGroupsStart, itemGroupsEnd = joshnt.getOverlappingItemGroupsOfSelectedItems(groupTolerance)

  if itemGroupsStart and itemGroupsEnd then

    for i in ipairs(itemGroupsStart) do
        local region_to_move, _, _, name = joshnt.getMostOverlappingRegion(itemGroupsStart[i],itemGroupsEnd[i])
        if region_to_move ~= nil then
            reaper.SetProjectMarker( region_to_move, true, itemGroupsStart[i], itemGroupsEnd[i], name )
        end
    end
      
  else
      joshnt.TooltipAtMouse("Unable to get overlapping items.")
  end

  reaper.PreventUIRefresh(-1) 
  reaper.UpdateArrange()
  reaper.Undo_EndBlock('Adjusted most overlapping region bounds', -1)
else
  joshnt.TooltipAtMouse("No region in project.")
end