-- @noindex

-- @description ReaGlue adaption to Regions (with user input)
-- @version 4.0
-- @changelog 
--    - changed about section for detailed explanation about parameters
--    - fixed rare case, when region start/ end of other region with items without items overlapping with selection, that region doesn't get "stolen"
-- @author Joshnt
-- @about 
--    ## ReaGlue Region
--    **User input explanation:**
--    
--
--    **Credits** to Aaron Cendan (for acendan_Set nearest regions edges to selected media items.lua; https://aaroncendan.me), David Arnoldy, Joshua Hank
--
--    **Usecase:** 
--    multiple Multi-Track Recordings or Sounddesigns across multiple tracks which needs to be exported to a single variation file.
--    Script creates region across those selected items (including beginning and end silence), adjusting the space between them, moving other non selected items away




-- load 'externals'
-- Load Unique Regions Core script
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

local isolateItems_USER = nil -- 1 = move selected, 2 = move others, 3 = dont move
local space_in_between_USER = 0 -- Time in seconds (positive)
local start_silence_USER = 0 -- Time in seconds (positive)
local end_silence_USER = 0 -- Time in seconds (positive)
local groupToleranceTime_USER = 0  -- Time in seconds (positive); Adjust how far away from each other items can be to still be considered as one 'group'.\n\nE.g. 0 means only actually overlapping items count as one group.\n1 means items within 1 second of each others start/ end still count as one group.
local RRMLink_ToMaster_USER = true -- Create Link in Region Render Matrix to Master Track
local openRgnDialog_USER = false -- wheather or not to open the "Edit region dialog" for the newly created region; only works when RRM_Link is set to false

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


local function userInputValues()
  local continue, s = reaper.GetUserInputs("ReaGlue Region", 7,
          "Start silence (ms):,Space in between (ms):,End silence (ms):,Group tolerance:,Render Matrix Master Link:,Open Region Edit Dialog,Isolate items across tracks (1-3):,extrawidth=1", 
          "100,1000,50,0,y,n,2")
  
    if not continue or s == "" then return false end
    local q = joshnt.fromCSV(s)
    
    -- Convert the values to globals
    space_in_between_USER = tonumber(q[2]) * 0.001 -- in seconds
    start_silence_USER = tonumber(q[1]) * 0.001 -- in seconds
    end_silence_USER = tonumber(q[3]) * 0.001 -- in seconds
    groupToleranceTime_USER = tonumber(q[4]) * 0.001
    RRMLink_ToMaster_USER = q[5] == "y"
    openRgnDialog_USER = q[6] == "y"
    isolateItems_USER = tonumber(q[7])
    
    return true
end

if userInputValues() then verifyUserInputs() end