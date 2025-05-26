-- @noindex

local joshnt_LuaUtils = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/DEVELOPMENT/joshnt_LuaUtilities.lua'
if reaper.file_exists( joshnt_LuaUtils ) then 
  dofile( joshnt_LuaUtils ) 
  if not joshnt or joshnt.version() < 3.7 then 
    reaper.MB("This script requires a newer version of joshnt Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages, 'joshnt_LuaUtilities.lua'","Error",0); 
    return 
  end
else 
  reaper.MB("This script requires joshnt Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt Lua Utilities'","Error",0)
  return
end

-- Load core script
local joshnt_repostionCORE = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/ITEMS/joshnt_Incremental Nudge/swobi-joshnt_Incremental Nudge - CORE.lua'
if reaper.file_exists( joshnt_repostionCORE ) then 
  dofile( joshnt_repostionCORE ) 
else 
  reaper.MB("This script requires an additional script, which gets installed over ReaPack as well. Please re-install the whole 'Incremental Nudge' Pack here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt_Incremental Nudge'","Error",0)
  return
end 

-- Get the script's filename
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local tracks, num, unit = script_name:match("every%s+(%d+)%s+tracks%s+by%s+([%+%-]?%d+)%s+(%a+)")

if not num or not unit or not tracks then
  unit = script_name:match("every%s+%a+%s+tracks%s+by%s+%a+%s+(%a+)")
  num = "X"
  tracks = "X"
end

joshnt_repostion.main(tracks, unit, num)