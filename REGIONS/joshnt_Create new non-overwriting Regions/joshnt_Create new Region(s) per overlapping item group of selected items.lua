-- @noindex

local joshnt_LuaUtils = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/DEVELOPMENT/joshnt_LuaUtilities.lua'
if reaper.file_exists( joshnt_LuaUtils ) then 
  dofile( joshnt_LuaUtils ) 
  if not joshnt or joshnt.version() < 3.1 then 
    reaper.MB("This script requires a newer version of joshnt Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages, 'joshnt_LuaUtilities.lua'","Error",0); 
    return 
  end
else 
  reaper.MB("This script requires joshnt Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt Lua Utilities'","Error",0)
  return
end

local function main() 
    local numItems = reaper.CountSelectedMediaItems(0)
    if numItems == 0 then 
        reaper.ShowMessageBox("No items selected!", "joshnt_Error", 0)
        return 
    end

    local _, itemStartsArray, itemEndsArray = joshnt.getOverlappingItemGroupsOfSelectedItems(0)

    if itemStartsArray and itemEndsArray then 
        for i = 1, #itemStartsArray do
            local itemStart = itemStartsArray[i]
            local itemEnd = itemEndsArray[i]
            reaper.AddProjectMarker(0, true, itemStartsArray[i], itemEndsArray[i], "", -1)
        end
    end
end

reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)
main()
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock('joshnt Create new regions', -1)