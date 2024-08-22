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



local function main()
    local itemnum = reaper.CountSelectedMediaItems(0)
    if itemnum == 0 then joshnt.TooltipAtMouse("No items selected!") return end

    reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)

    reaper.Main_OnCommand(40699,0) -- cut items
    reaper.Main_OnCommand(41221,0) -- paste items at mouse pos

    reaper.UpdateArrange() reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock('Move selected items to mouse - time and track relative', -1)

end

main()