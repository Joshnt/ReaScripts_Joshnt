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
local Mother_Region_Name_USER = nil -- Insert name as string between ""
local LinkToRRM_ChildRgn_USER = nil -- sets Region Manager Link for individual item Groups; 1 = Master, 2 = Highest common Parent, 3 = first common Parent, 4 = Track,  5 = each track, 0 = no link
local LinkToRRM_MotherRgn_USER = nil -- sets Region Manager Link for individual item Groups; 1 = Master, 2 = Highest common Parent, 3 = first common Parent, 4 = Parent per item, 5 = each track, 0 = no link

---------------------------------------
---------- USER CONFIG END ------------
---------------------------------------


-- Load lua utilities
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

-- Load Unique Regions Core script
local joshnt_UniqueRegionsM_Core = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/VARIOUS/joshnt_Create unique regions for each group of overlapping items/joshnt_Unique Regions for overlapping items - CORE Mother.lua'
if reaper.file_exists( joshnt_UniqueRegionsM_Core ) then 
  dofile( joshnt_UniqueRegionsM_Core ) 
else 
  reaper.MB("This script requires an additional script, which gets installed over ReaPack as well. Please re-install the whole 'Unique Regions' Pack here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt_Create unique regions for overlapping items'","Error",0)
  return
end

-- load defaults (from script and reaper extended states)
joshnt_UniqueRegionsM.getDefaults()
if isolateItems_USER == 1 or isolateItems_USER == 2 or isolateItems_USER == 3 then joshnt_UniqueRegionsM.isolateItems = isolateItems_USER end
if type(Space_Between_Regions_USER) == "number" then joshnt_UniqueRegionsM.space_in_between = Space_Between_Regions_USER end
if type(Time_Before_Item_Group_Start_USER) == "number" then joshnt_UniqueRegionsM.start_silence = Time_Before_Item_Group_Start_USER end
if type(Time_After_Item_Group_End_USER) == "number" then joshnt_UniqueRegionsM.end_silence = Time_After_Item_Group_End_USER end
if type(Lock_Items_USER) == "boolean" then joshnt_UniqueRegionsM.lockBoolUser = Lock_Items_USER end
if type(Region_Name_USER) == "string" then joshnt_UniqueRegionsM.regionName = Region_Name_USER end
if type(Mother_Region_Name_USER) == "string" then joshnt_UniqueRegionsM.motherRegionName = Mother_Region_Name_USER end
if LinkToRRM_ChildRgn_USER == 1 or LinkToRRM_ChildRgn_USER == 2 or LinkToRRM_ChildRgn_USER == 3 or LinkToRRM_ChildRgn_USER == 4 then joshnt_UniqueRegionsM.RRMLink_Child = LinkToRRM_ChildRgn_USER end
if LinkToRRM_MotherRgn_USER == 1 or LinkToRRM_MotherRgn_USER == 2 or LinkToRRM_MotherRgn_USER == 3 or LinkToRRM_MotherRgn_USER == 4 then joshnt_UniqueRegionsM.RRMLink_Mother = LinkToRRM_MotherRgn_USER end
if type(GroupTolerance_USER) == "number" then joshnt_UniqueRegionsM.groupToleranceTime = GroupTolerance_USER end
joshnt_UniqueRegionsM.createMotherRgn = true

local function quit(missingValue)
  reaper.MB("No default value set for:\n"..missingValue.."\nPlease run the GUI Version of this script once or edit this script directly to set default values.", "joshnt Error",0)
end

-- check for all values
if not joshnt_UniqueRegionsM.isolateItems then quit("isolateItems") return
elseif not joshnt_UniqueRegionsM.space_in_between then quit("space_in_between") return
elseif not joshnt_UniqueRegionsM.start_silence then quit("start_silence") return
elseif not joshnt_UniqueRegionsM.end_silence then quit("end_silence") return
elseif not joshnt_UniqueRegionsM.lockBoolUser then quit("lockBoolUser") return
elseif not joshnt_UniqueRegionsM.regionName then quit("regionName") return
elseif not joshnt_UniqueRegionsM.motherRegionName then quit("motherRegionName") return
elseif not joshnt_UniqueRegionsM.RRMLink_Child then quit("RRMLink_Child") return
elseif not joshnt_UniqueRegionsM.RRMLink_Mother then quit("RRMLink_Mother") return
elseif not joshnt_UniqueRegionsM.groupToleranceTime then quit("groupToleranceTime") return
end


joshnt_UniqueRegionsM.main()
joshnt_UniqueRegionsM.Quit()