-- @noindex

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

if not joshnt.checkJS_API() then return end

local function main()    
  local selTrackCount = reaper.CountSelectedTracks2(0, true)
  
  if selTrackCount == 0 then 
    joshnt.TooltipAtMouse("No tracks selected")
    return
  elseif reaper.CountMediaItems(0) == 0 then 
    joshnt.TooltipAtMouse("No items in project to get regions")
    return
  end


  -- save selection pre-script
  local timeRangeStart, timeRangeEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  local itemSelection = joshnt.saveItemSelection()
  local trackSelection = joshnt.saveTrackSelection()

  local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
  local num_total = num_markers + num_regions

  if num_regions == 0 then
    joshnt.TooltipAtMouse("No regions in project")
    return
  end

  for j=0, num_total - 1 do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers( j )
    if isrgn then
      reaper.SelectAllMediaItems(0, false)
      reaper.GetSet_LoopTimeRange(true, false, pos, rgnend, false)
      reaper.Main_OnCommand(40717,0) -- select all items in teimeselection

      if reaper.CountSelectedMediaItems(0) > 0 then
        joshnt.selectOnlyTracksOfSelectedItems()
        local trackSelection_TEMP = joshnt.saveTrackSelection()

        for i = 1, #trackSelection_TEMP do
          if joshnt.isTrackInList(trackSelection_TEMP[i], trackSelection) then
            reaper.SetRegionRenderMatrix(0, markrgnindexnumber, trackSelection_TEMP[i], 1)
          end
        end
      end
    end
  end

  -- restore selection pre script
  reaper.SelectAllMediaItems(0, false)
  reaper.GetSet_LoopTimeRange(true, false, timeRangeStart, timeRangeEnd, false)
  joshnt.reselectItems(itemSelection)
  joshnt.unselectAllTracks()
  joshnt.reselectTracks(trackSelection)
end
  
reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)
main()
reaper.UpdateArrange() reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock('Add selected Track(s) to RRM via corresponding regions with items', -1)
