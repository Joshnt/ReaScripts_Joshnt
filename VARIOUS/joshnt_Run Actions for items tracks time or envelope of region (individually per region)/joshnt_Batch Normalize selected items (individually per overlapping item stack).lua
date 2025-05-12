-- @noindex

---------------------------------------
--------- USER CONFIG - EDIT ME -------
---------------------------------------

local promptAfterEachRegion = false -- allows what happend after each execution
---------------------------------------
---------- USER CONFIG END ------------
---------------------------------------
--- adapted from mpl_scripts: Normalize selected items takes loudness to XdB
local loudtype = 3 -- 0=LUFS-I, 1=RMS-I, 2=peak, 3=true peak, 4=LUFS-M max, 5=LUFS-S max
local loudvalue = -6 -- dBFS

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

-- para-Global variables
local selected_action_id = 0
if reaper.CountSelectedMediaItems(0) == 0 then
  reaper.MB("No items selected. Please select at least one item.","Error",0)
  return
end
local itemGroups, itemStarts, itemEnds = joshnt.getOverlappingItemGroupsOfSelectedItems()
if #itemGroups == 0 or itemGroups == nil or itemStarts == nil or itemEnds == nil then
  reaper.MB("No overlapping items found. Please select at least one item.","Error",0)
  return
end



local function runAction()
  local actionName = "normalize selected items - TruePeak -6dB loudest item"
  reaper.Undo_BeginBlock()
  reaper.ShowConsoleMsg("Number item groups: "..#itemGroups.."\n")

  for j=1, #itemGroups do

    reaper.Main_OnCommand(40769,0) -- unselect everything

    -- select Items
    joshnt.reselectItems(itemGroups[j])

    if j == 1 then 
      reaper.Main_OnCommand(42460,0) -- normalize with dialog
    else 
      reaper.Main_OnCommand(42461,0) -- normalize with recent settings
    end

  end
  reaper.Undo_EndBlock("Run '"..actionName.."' for overlapping items of selected items", -1)
end

runAction()
reaper.UpdateArrange()
