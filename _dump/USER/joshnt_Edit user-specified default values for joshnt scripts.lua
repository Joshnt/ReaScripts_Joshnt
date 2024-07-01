-- @noindex

-- REMOVED - usage of default values which are saved externally isn't efficent for such small scripts

-- @description Edit "../Scripts/Joshnt_ReaScripts/USER/joshnt_DefaultValues.ini" file inside of reaper with user input field
-- @version 1.0
-- @author Joshnt
-- @about
-- Semi-interactive variant of adjusting the default values shown for specific scripts - gives the option, not to have to open the code editor to change those

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

local function listDefaultValuesInIniFile()
    local file = io.open(joshnt.getDefaultValPath(), "r")
    if file then
        local sectionTable = {}
        for line in file:lines() do
            if line:match("^%[.-%]$") then
                sectionTable[#sectionTable+1] = line
            end
        end
        file:close()
        return sectionTable
    else
        reaper.ShowMessageBox("joshnt_Scripts: Unable to open\n\n"..joshnt.getDefaultValPath().."\n\nfor listing default values.", "Error", 0)
    end
    return nil
end

local function getWhichEdit(maxLength)
    local continue, num = reaper.GetUserInputs("Default Values joshnt", 1, "Number of Script to edit", "")
    if not continue or num == "" then reaper.ShowMessageBox("Editing default values aborted by user.", "Error", 0) return end
    num = tonumber(num)
    if not num or num < 1 or num > maxLength then reaper.ShowMessageBox("The input did not match to an existing default value set.", "Error", 0) num = getWhichEdit(maxLength) end
    return num
end

local function editValueSet(section)
    section = string.gsub(section, "^%[(.*)%]$", "%1")
    local counter = 0
    local keyString = ""
    local keyTable = {}
    local valueString = ""
    local file = io.open(joshnt.getDefaultValPath(), "r")
    if file then
        local in_section = false
        for line in file:lines() do
            if line:match("^%[.-%]$") then
                if not in_section then
                    in_section = (line == "[" .. section .. "]")
                else break end
            elseif in_section then
                local k, v = line:match("^(.-)=(.-)$")
                if k then
                    counter = counter +1
                    if k == "#####" then k = "" end
                    if keyString == "" then keyString = keyString..k else keyString = keyString..", "..k end
                    table.insert(keyTable,k)
                    if valueString == "" then valueString = valueString..v else valueString = valueString..", "..v end
                end
            end
        end
        file:close()
        local retval = reaper.ShowMessageBox("The following user input allows you to adjust the default values. Type '#####' to delete a default value without adjusting it.", "Default values joshnt", 0) 
        if retval ~= 1 then return end
        local continue, csvString = reaper.GetUserInputs("'"..section.."' default values", counter, keyString..",extrawidth=100", valueString)
        if not continue or csvString == "" then reaper.ShowMessageBox("Editing default values aborted by user.", "Cancel", 0) return end
        local csvTable = joshnt.fromCSV(csvString)
        for i = 1, counter do
            if csvTable[i] == "#####" then joshnt.delete_ini_key(joshnt.getDefaultValPath(), section, keyTable[i]) 
            else joshnt.write_ini(joshnt.getDefaultValPath(), section, keyTable[i], csvTable[i])
            end
        end
        reaper.ShowMessageBox("Edited default values succesfully.", "Default Values joshnt", 0)
    else
        reaper.ShowMessageBox("joshnt_Scripts: Unable to open\n\n"..joshnt.getDefaultValPath().."\n\nfor reading default values.", "Error", 0)
    end
end

local function main() 
    local sectionTable = listDefaultValuesInIniFile()
    if sectionTable == nil then reaper.ShowMessageBox("joshnt_Scripts: Unable to get\n\n"..joshnt.getDefaultValPath().."\n\nfor listing default values.", "Error", 0) return
    elseif sectionTable[1] == nil then 
        reaper.ShowMessageBox("joshnt_Scripts: no default values to edit found in \n\n"..joshnt.getDefaultValPath(), "Error", 0)
        return
    end

    reaper.ClearConsole()
    reaper.ShowConsoleMsg("Default Values found for the following joshnt scripts:\n")

    for index, section in ipairs(sectionTable) do
        local sectionNameClear = string.gsub(section, "^%[(.*)%]$", "%1") -- section name without []
        reaper.ShowConsoleMsg("\n"..index.." - "..sectionNameClear)
    end

    local retval = reaper.ShowMessageBox("All scripts where existing default values have been found are now listed in the 'ReaScript' console.\nIf you would like to edit one of them, press 'Yes' and type the number next to the section name into the following user input box", "Default Values joshnt", 4)
    if retval == 6 then
        local num = getWhichEdit(#sectionTable)
        editValueSet(sectionTable[num])
    end
    reaper.ClearConsole()
    if reaper.GetToggleCommandState(42663) == 1 then reaper.Main_OnCommand(42663, 0) end
end

main()