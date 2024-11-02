-- @noindex

-- Load lua utilities
local joshnt_LuaUtils = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/DEVELOPMENT/joshnt_LuaUtilities.lua'
if reaper.file_exists( joshnt_LuaUtils ) then 
  dofile( joshnt_LuaUtils ) 
  if not joshnt or joshnt.version() < 2.22 then 
    reaper.MB("This script requires a newer version of joshnt Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages, 'joshnt_LuaUtilities.lua'","Error",0); 
    return 
  end
else 
  reaper.MB("This script requires joshnt Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt Lua Utilities'","Error",0)
  return
end

-- Load Unique Regions Core script
local joshnt_UniqueRegions_Core = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/VARIOUS/joshnt_Create unique regions for each group of overlapping items/joshnt_Unique Regions for overlapping items - CORE.lua'
if reaper.file_exists( joshnt_UniqueRegions_Core ) then 
  dofile( joshnt_UniqueRegions_Core ) 
else 
  reaper.MB("This script requires an additional script, which gets installed over ReaPack as well. Please re-install the whole 'Unique Regions' Pack here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt_Create unique regions for overlapping items'","Error",0)
  return
end

-- load defaults (from script and reaper extended states)
if not joshnt_UniqueRegions.settingsFromClipboard() then return end

local function quit(missingValue)
  reaper.MB("No default value set for:\n"..missingValue.."\nPlease run the GUI Version of this script once to set default values.", "joshnt Error",0)
end

-- check for all values
if not joshnt_UniqueRegions.isolateItems then quit("isolateItems") return
elseif not joshnt_UniqueRegions.space_in_between then quit("space_in_between") return
elseif not joshnt_UniqueRegions.lockBoolUser then quit("lockBoolUser") return
elseif not joshnt_UniqueRegions.groupToleranceTime then quit("groupToleranceTime") return
elseif not joshnt_UniqueRegions.repositionToggle then quit("repositionToggle") return
elseif not joshnt_UniqueRegions.allRgnArray[1] then quit("any Region") return
end


joshnt_UniqueRegions.main()
joshnt_UniqueRegions.Quit()