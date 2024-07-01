-- @noindex
-- script looks for parent tracks of all items in regions to find the highest parent (or use the track of the items itself, if it is on top level already)

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
  if reaper.CountTracks(0) == 0 then
    joshnt.TooltipAtMouse("No tracks in project to get parents")
    return
  elseif reaper.CountMediaItems(0) == 0 then 
    joshnt.TooltipAtMouse("No items in project to get parents")
    return
  end


  -- save selection pre-script
  local timeRangeStart, timeRangeEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  local itemSelection = joshnt.saveItemSelection()
  local trackSelection = joshnt.saveTrackSelection()

  local selRgnTable = joshnt.getSelectedMarkerAndRegionIndex()
  local numItemsSelRgn = 0 -- number of items in selected Region
  if selRgnTable == nil or selRgnTable[1] == nil then 
      joshnt.TooltipAtMouse("No region selected")
      return 
  end

  for index, rgnIndex in ipairs(selRgnTable) do
    reaper.SelectAllMediaItems(0, false)
    local regStart_TEMP, regEnd_TEMP = joshnt.getRegionBoundsByIndex(rgnIndex)
    reaper.GetSet_LoopTimeRange(true, false, regStart_TEMP, regEnd_TEMP, false)
    reaper.Main_OnCommand(40717,0) -- select all items in teimeselection

    -- if any items in region, find parents
    local selectedItemsTEMP = reaper.CountSelectedMediaItems(0)
    if selectedItemsTEMP ~= 0 then
      numItemsSelRgn = numItemsSelRgn + selectedItemsTEMP
      joshnt.selectOnlyTracksOfSelectedItems()

      local parentTracks = joshnt.getOnlyTopLevelTracksAndParents(joshnt.saveTrackSelection())

      for i = 1, #parentTracks do
        reaper.SetRegionRenderMatrix(0, rgnIndex, parentTracks[i], 1)
      end
    end
  end

  reaper.SelectAllMediaItems(0, false)

  reaper.UpdateArrange()
  if numItemsSelRgn == 0 then 
      joshnt.TooltipAtMouse("No items in all selected region(s) to get parent")
  end

  -- restore selection pre script
  reaper.GetSet_LoopTimeRange(true, false, timeRangeStart, timeRangeEnd, false)
  joshnt.reselectItems(itemSelection)
  joshnt.unselectAllTracks()
  joshnt.reselectTracks(trackSelection)
end
  
reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)
main()
reaper.UpdateArrange() reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock('Add selected Region(s) to RRM via highest parent(s)', -1)
