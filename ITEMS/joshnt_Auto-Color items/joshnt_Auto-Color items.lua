-- @noindex

-- check for external states
-- set default values (priority list, indiv. colors, value ranges) from external states

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

-- Load auto-color main script
local joshnt_AutoColor_Main = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/ITEMS/joshnt_Auto-Color items/joshnt_Auto-Color items - Main Function.lua'
if reaper.file_exists( joshnt_AutoColor_Main ) then 
  dofile( joshnt_AutoColor_Main ) 
else 
  reaper.MB("This script requires an additional script, which gets installed over ReaPack as well. Please re-install the whole 'Items Auto-Coloring' Pack here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt Auto-Color items'","Error",0)
  return
end



local function getSavedSettings()
  local optionsForMain = {"reverse","","FX","FXnamed","","is exactly","contains","is not","is not containing","","pitch","rate","","volume","gain","","combined"}
  local selectedValues = {
    selProperty = {},
    selColor1 = {},
    selColor2 = {},
    selValRange = {},
    selGradToggle = {},
    selTextInput = {}
  }
  joshnt_autoColor.priorityOrderArray = {}

  if reaper.HasExtState("joshnt_Auto-Color_items", "priorityOrder") then
    selectedValues.selProperty = joshnt.splitStringToTable(reaper.GetExtState("joshnt_Auto-Color_items", "priorityOrder"))
    selectedValues.selColor1 = joshnt.splitStringToTable(reaper.GetExtState("joshnt_Auto-Color_items", "selColor1"))
    selectedValues.selColor2 = joshnt.splitStringToTable(reaper.GetExtState("joshnt_Auto-Color_items", "selColor2"))
    selectedValues.selValRange = joshnt.splitStringToTable(reaper.GetExtState("joshnt_Auto-Color_items", "selValRange"))
    selectedValues.selGradToggle = joshnt.splitStringToTable(reaper.GetExtState("joshnt_Auto-Color_items", "selGradToggle"))
    selectedValues.selTextInput = joshnt.splitStringToTable(reaper.GetExtState("joshnt_Auto-Color_items", "selTextInput"))
    joshnt_autoColor.dontOverwrite = reaper.GetExtState("joshnt_Auto-Color_items", "dontOverwrite") == "true"
  else return end

  local counterInAutoColor = 1 -- count index in autocolor indepently from i for potential nothing between others
  local nameIndex = 1
  local FXnameIndex = 1
  for i = 1, #selectedValues.selProperty do
      local curSelProperty = selectedValues.selProperty[i]
      if curSelProperty and curSelProperty ~= "" and curSelProperty ~= 19 then
          if curSelProperty >= 6 and curSelProperty <= 9 then -- if names
            joshnt_autoColor.priorityOrderArray[counterInAutoColor] = "name"..nameIndex
            joshnt_autoColor.names[nameIndex] = {}
            joshnt_autoColor.names[nameIndex][1] = selectedValues.selTextInput[i]
            joshnt_autoColor.names[nameIndex][2] = optionsForMain[curSelProperty]
            nameIndex = nameIndex +1
          elseif curSelProperty == 4 then
            joshnt_autoColor.priorityOrderArray[counterInAutoColor] = "FXnamed"..nameIndex
            joshnt_autoColor.FXnames[FXnameIndex] = selectedValues.selTextInput[i]
            FXnameIndex = FXnameIndex +1
          else
              joshnt_autoColor.priorityOrderArray[counterInAutoColor] = optionsForMain[curSelProperty]
          end

          if selectedValues.selGradToggle[i] ~= true then
              joshnt_autoColor.colors[joshnt_autoColor.priorityOrderArray[counterInAutoColor]] = selectedValues.selColor1[i]
              joshnt_autoColor.valueRanges[joshnt_autoColor.priorityOrderArray[counterInAutoColor]] = nil
          else
              joshnt_autoColor.colors[joshnt_autoColor.priorityOrderArray[counterInAutoColor]] = {selectedValues.selColor1[i],selectedValues.selColor2[i]}
              joshnt_autoColor.valueRanges[joshnt_autoColor.priorityOrderArray[counterInAutoColor]] = selectedValues.selValRange[i]
          end

          counterInAutoColor = counterInAutoColor + 1
      end
  end
end

getSavedSettings()

if joshnt_autoColor.checkDefaultsSet() == false then return end

local function main_sel_noOverwrite()
  joshnt_autoColor.selItems_dontOverwrite()
  reaper.defer(main_sel_noOverwrite)
end

local function main_sel()
  joshnt_autoColor.selItems()
  reaper.defer(main_sel)
end

local function main()
  if joshnt_autoColor.dontOverwrite == true then
    main_sel_noOverwrite()
  else
    main_sel()
  end
end

local function exitFunc()
    reaper.set_action_options(8) -- toggle off
end

reaper.atexit(exitFunc)

reaper.set_action_options(4) -- toggle on
reaper.set_action_options(1) -- on rerun, terminate script
main()