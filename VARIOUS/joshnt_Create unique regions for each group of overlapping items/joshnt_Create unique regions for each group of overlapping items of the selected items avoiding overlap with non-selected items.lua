-- @noindex

-----------------------------------------
---------- USER CONFIG - EDIT ME --------
------ Default Values this scripts ------
-- overwrites saved settings from GUI! --
-----------------------------------------

local isolateItems_USER = nil -- valid inputs are: 1 = move selected, 2 = move others, 3 = dont move any items
local Time_Before_Item_Group_Start_USER = nil -- Time in Seconds
local Time_After_Item_Group_End_USER = nil -- Time in Seconds
local Space_Between_Regions_USER = nil -- Time in Seconds
local GroupTolerance_USER = nil -- Time in Seconds
local Lock_Items_USER = nil -- write true or false to lock selected items after moving them
local Region_Name_USER = nil -- Insert name as string between ""
local LinkToRRM_ChildRgn_USER = nil -- sets Region Manager Link for individual item Groups; 1 = Master, 2 = Highest Parent, 3 = Parent, 4 = Track

---------------------------------------
---------- USER CONFIG END ------------
---------------------------------------


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

-- Load Unique Regions Core script
local joshnt_UniqueRegions_Core = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/ITEMS/joshnt_Auto-Color items/joshnt_Unique Regions for overlapping items - CORE.lua'
if reaper.file_exists( joshnt_UniqueRegions_Core ) then 
  dofile( joshnt_UniqueRegions_Core ) 
else 
  reaper.MB("This script requires an additional script, which gets installed over ReaPack as well. Please re-install the whole 'Unique Regions' Pack here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt_Create unique regions for overlapping items'","Error",0)
  return
end

-- load defaults (from script and reaper extended states)
joshnt_UniqueRegions.getDefaults()
if isolateItems_USER == 1 or isolateItems_USER == 2 or isolateItems_USER == 3 then joshnt_UniqueRegions.isolateItems = isolateItems_USER end
if type(Space_Between_Regions_USER) == "number" then joshnt_UniqueRegions.space_in_between = Space_Between_Regions_USER end
if type(Time_Before_Item_Group_Start_USER) == "number" then joshnt_UniqueRegions.start_silence = Time_Before_Item_Group_Start_USER end
if type(Time_After_Item_Group_End_USER) == "number" then joshnt_UniqueRegions.end_silence = Time_After_Item_Group_End_USER end
if type(Lock_Items_USER) == "boolean" then joshnt_UniqueRegions.lockBoolUser = Lock_Items_USER end
if type(Region_Name_USER) == "string" then joshnt_UniqueRegions.regionName = Region_Name_USER end
if LinkToRRM_ChildRgn_USER == 1 or LinkToRRM_ChildRgn_USER == 2 or LinkToRRM_ChildRgn_USER == 3 or LinkToRRM_ChildRgn_USER == 4 then joshnt_UniqueRegions.RRMLink_Child = LinkToRRM_ChildRgn_USER end
if type(GroupTolerance_USER) == "number" then joshnt_UniqueRegions.groupToleranceTime = GroupTolerance_USER end
joshnt_UniqueRegions.createMotherRgn = false

local function quit(missingValue)
  reaper.MB("No default value set for:\n"..missingValue.."\nPlease run the GUI Version of this script once or edit this script directly to set default values.", "joshnt Error",0)
end

-- check for all values
if not joshnt_UniqueRegions.isolateItems then quit("isolateItems") return
elseif not joshnt_UniqueRegions.space_in_between then quit("space_in_between") return
elseif not joshnt_UniqueRegions.start_silence then quit("start_silence") return
elseif not joshnt_UniqueRegions.end_silence then quit("end_silence") return
elseif not joshnt_UniqueRegions.lockBoolUser then quit("lockBoolUser") return
elseif not joshnt_UniqueRegions.regionName then quit("regionName") return
elseif not joshnt_UniqueRegions.RRMLink_Child then quit("RRMLink_Child") return
elseif not joshnt_UniqueRegions.groupToleranceTime then quit("groupToleranceTime") return
end


joshnt_UniqueRegions.main()
joshnt_UniqueRegions.Quit()