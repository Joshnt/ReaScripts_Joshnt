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
    local selRgnTable = joshnt.getSelectedMarkerAndRegionIndex()
    if selRgnTable == nil then 
        joshnt.TooltipAtMouse("No region selected")
        return 
    end
  
    for index, rgnIndex in ipairs(selRgnTable) do
        reaper.SetRegionRenderMatrix(0, rgnIndex, reaper.GetMasterTrack(0), 1)
    end

  end
  
  reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)
  main()
  reaper.UpdateArrange() reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock('Add selected Region(s) to RRM via Master', -1)