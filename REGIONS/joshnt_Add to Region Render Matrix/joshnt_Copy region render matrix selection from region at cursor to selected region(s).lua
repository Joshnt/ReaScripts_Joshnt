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
    local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
    local num_total = num_markers + num_regions
    if num_regions == 0 then
        joshnt.TooltipAtMouse("No regions in project")
        return
    end

    local regIndexCopy = joshnt.getRegionAtPosition(reaper.GetCursorPosition())
    if not regIndexCopy then joshnt.TooltipAtMouse("No region at edit cursor") return end
    local rrmCopyTable = {reaper.EnumRegionRenderMatrix(0,regIndexCopy,0)}

    if rrmCopyTable[1] == nil then joshnt.TooltipAtMouse("No RRM links found for region at edit cursor") return end
    local selRgnTable = joshnt.getSelectedMarkerAndRegionIndex()
    if selRgnTable == nil then joshnt.TooltipAtMouse("No region selected") return end

    while rrmCopyTable[#rrmCopyTable] ~= nil do
        if reaper.EnumRegionRenderMatrix(0, regIndexCopy, #rrmCopyTable) == nil then break end -- break while loop if no next RRM Link for region found
        table.insert(rrmCopyTable, reaper.EnumRegionRenderMatrix(0, regIndexCopy, #rrmCopyTable))
    end
  
    for index, rgnIndex in ipairs(selRgnTable) do
        for i = 1, #rrmCopyTable do
            reaper.SetRegionRenderMatrix(0, rgnIndex, rrmCopyTable[i], 1)
        end
    end

end
  
reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)
main()
reaper.UpdateArrange() reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock('Copy RRM from region at cursor to selected region', -1)