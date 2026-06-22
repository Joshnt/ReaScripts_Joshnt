-- @noindex

-- Load lua utilities
local joshnt_LuaUtils = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/DEVELOPMENT/joshnt_LuaUtilities.lua'
if reaper.file_exists( joshnt_LuaUtils ) then 
  dofile( joshnt_LuaUtils ) 
  if not joshnt or joshnt.version() < 4.01 then 
    reaper.MB("This script requires a newer version of joshnt Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages, 'joshnt_LuaUtilities.lua'","Error",0); 
    return 
  end
else 
  reaper.MB("This script requires joshnt Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt Lua Utilities'","Error",0)
  return
end

-- check if hover edit exists
local hoverEdit = reaper.GetResourcePath()..'/Scripts/LKC Tools/Hover editing package/LKC - HOVER EDIT - Toggle hovering.lua'
if not reaper.file_exists( hoverEdit ) then 
    reaper.MB("This script requires LKC's Hover Edit Package! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'LKC Hover Edit Package'","Error",0)
    return
end

local hoverToggleID = reaper.NamedCommandLookup("_RS8277b238cd7341ba4a3c9ff870f30876ce76160b") -- ID of hover edit toggle
local function play()
    

    if reaper.GetToggleCommandState(hoverToggleID) == 0 then
        reaper.Main_OnCommand(40044, 0)
    else
        local cmd = reaper.NamedCommandLookup("_BR_PLAY_STOP_MOUSECURSOR")
        if cmd ~= 0 then
            reaper.Main_OnCommand(cmd, 0)
        end
    end

    
end
play()
