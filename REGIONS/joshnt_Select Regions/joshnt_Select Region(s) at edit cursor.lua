-- @noindex

-- Load lua utilities
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
    if num_regions == 0 then joshnt.TooltipAtMouse("No regions found") return end
    local curPos = reaper.GetCursorPosition()

    local selRgns_NEW = {}
    for j=0, num_total - 1 do
        local retval, isrgn, rgnpos, rgnend, rgnname, markrgnindexnumber = reaper.EnumProjectMarkers( j )
        if isrgn then
          if rgnpos <= curPos and rgnend >= curPos then
            table.insert(selRgns_NEW,markrgnindexnumber)
          end
        end
    end
    joshnt.setRegionSelectedByIndex(selRgns_NEW)

end

reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)
main()
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock('Select Regions at edit cursor', -1)