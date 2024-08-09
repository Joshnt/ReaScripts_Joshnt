-- @noindex
---------------------------------------
--------- USER CONFIG - EDIT ME -------
---------------------------------------

    local isolateItems_USER = 2 -- 1 = move selected, 2 = move others, 3 = dont move
    local space_in_between_USER = 1 -- Time in seconds (positive)
    local start_silence_USER = 0.100 -- Time in seconds (positive)
    local end_silence_USER = 0.050 -- Time in seconds (positive)
    local groupToleranceTime_USER = 0  -- Time in seconds (positive); Adjust how far away from each other items can be to still be considered as one 'group'.\n\nE.g. 0 means only actually overlapping items count as one group.\n1 means items within 1 second of each others start/ end still count as one group.
    local RRMLink_ToMaster_USER = true -- Create Link in Region Render Matrix to Master Track
    local openRgnDialog_USER = false -- wheather or not to open the "Edit region dialog" for the newly created region; only works when RRM_Link is set to false

---------------------------------------
---------- USER CONFIG END ------------
---------------------------------------



-- load 'externals'
-- Load ReaGlue Core script
local joshnt_ReaGlue_Core = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/VARIOUS/joshnt_Regions for Variation File (ReaGlue-Regions)/joshnt_ReaGlue Regions - CORE.lua'
if reaper.file_exists( joshnt_ReaGlue_Core ) then 
  dofile( joshnt_ReaGlue_Core ) 
else 
  reaper.MB("This script requires an additional script, which gets installed over ReaPack as well. Please re-install the whole 'ReaGlue Regions' Pack here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt_ReaGlue Regions","Error",0)
  return
end 

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

local function verifyUserInputs()
    if type(isolateItems_USER) ~="number" or isolateItems_USER < 1 or isolateItems_USER > 3 then joshnt.TooltipAtMouse("Invalid input at isolateItems.") return end
    if type(space_in_between_USER) ~="number" or space_in_between_USER < 0 then joshnt.TooltipAtMouse("Invalid input at space_in_between.") return end
    if type(start_silence_USER) ~="number" or start_silence_USER < 0 then joshnt.TooltipAtMouse("Invalid input at start_silence.") return end
    if type(end_silence_USER) ~="number" or end_silence_USER < 0 then joshnt.TooltipAtMouse("Invalid input at end_silence.") return end
    if type(groupToleranceTime_USER) ~="number" or groupToleranceTime_USER < 0 then joshnt.TooltipAtMouse("Invalid input at group tolerance.") return end
    if type(RRMLink_ToMaster_USER) ~="boolean" then joshnt.TooltipAtMouse("Invalid input at RRM Link.") return end
    if type(openRgnDialog_USER) ~="boolean" then joshnt.TooltipAtMouse("Invalid input at Open Region Dialog.") return end
    if RRMLink_ToMaster_USER == true and openRgnDialog_USER == true then joshnt.TooltipAtMouse("Can't open Region Edit dialog and make RRM Link.") return end

    joshnt_ReaGlue.isolateItems = isolateItems_USER -- 1 = move selected, 2 = move others, 3 = dont move
    joshnt_ReaGlue.space_in_between = space_in_between_USER -- Time in seconds
    joshnt_ReaGlue.start_silence = start_silence_USER -- Time in seconds
    joshnt_ReaGlue.end_silence = end_silence_USER -- Time in seconds
    joshnt_ReaGlue.groupToleranceTime = groupToleranceTime_USER  -- Time in seconds
    joshnt_ReaGlue.RRMLink_ToMaster = RRMLink_ToMaster_USER
    joshnt_ReaGlue.openRgnDialog = openRgnDialog_USER

    joshnt_ReaGlue.main()
end

verifyUserInputs()