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

local numItems = reaper.CountSelectedMediaItems(0)
if numItems == 0 then joshnt.TooltipAtMouse("No items selected!") return end

local continue, csvString = reaper.GetUserInputs("Move items to marker...", 2, "Marker Name, Exact", ",true")
if not continue or csvString == "" then joshnt.TooltipAtMouse("'Move items to marker with name...' aborted by user") return end
local csvTable = joshnt.fromCSV(csvString)
local markerName = csvTable[1]
local exact = csvTable[2] == "true"

local startTimeSel, _ = joshnt.startAndEndOfSelectedItems()
local markerPos = nil;

local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
local num_total = num_markers + num_regions
if num_markers ~= 0 then
    for j = 0, num_total - 1 do
        local _, isrgn, markerPosTEMP, _, markerNameTEMP, markerIndex = reaper.EnumProjectMarkers( j)
        if exact then
            if not isrgn and markerNameTEMP == markerName then
                markerPos = markerPosTEMP
                break
            end
        else
            if not isrgn and string.find(markerNameTEMP, markerName) ~= nil then
                markerPos = markerPosTEMP
                break
            end
        end
    end
end

if not markerPos then joshnt.TooltipAtMouse("Marker "..markerName.." doesn't exist in your project") return end

reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)
for i = 0, numItems -1 do
    local itemTemp = reaper.GetSelectedMediaItem(0, i)
    local prevPos = reaper.GetMediaItemInfo_Value(itemTemp, "D_POSITION")
    local newPos = markerPos + prevPos - startTimeSel
    reaper.SetMediaItemInfo_Value(itemTemp, "D_POSITION", newPos)
end

reaper.UpdateArrange() reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock('Move selected items to marker wit name '..markerName, -1)