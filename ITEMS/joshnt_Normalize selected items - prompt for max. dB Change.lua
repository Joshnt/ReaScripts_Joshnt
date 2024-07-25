-- @description Normalize selected items seperatly with recent settings - prompt for max. dB Change.lua
-- @version 1.0
-- @author Joshnt
-- @about
--    Usecase: "rough" normalization as something between common gain and seperatly normalizing

---------------------------------------
--------- USER CONFIG - EDIT ME -------
--- Default Values for input dialog ---
---------------------------------------

local maxVolumeIncrease = 12 -- Volume Value in dB
local maxVolumeDecrease = -12 -- Volume Value in dB

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

local function userInputValues()
    local defaultValuesString = maxVolumeIncrease..","..maxVolumeDecrease
    local continue, s = reaper.GetUserInputs("Max. Volume change in normalization", 2,
        "Max. vol. increase:, Max. vol. decrease:,extrawidth=100",defaultValuesString)
    
    if not continue or s == "" then joshnt.TooltipAtMouse("Input canceled by user") return false end
    local q = joshnt.fromCSV(s)
    
    -- Get the values from the input
    local input1 = tonumber(q[1])
    local input2 = tonumber(q[2])
    if type(input1) ~= "number" or type(input2) ~= "number" then joshnt.TooltipAtMouse("Invalid user input") return false end

    if input1 < 0 then input1 = 0 end
    if input2 > 0 then input2 = 0 end

    return input1, input2
end

local function main()
    local numItems = reaper.CountSelectedMediaItems(0)
    if numItems == 0 then joshnt.TooltipAtMouse("No items selected!") return end
    local maxIncrease, maxDecrease = userInputValues()

    if not maxIncrease or not maxDecrease then return end

    local volTable = {}

    -- write prev item volume values
    for i = 0, numItems -1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        if item then
            local itemVol = joshnt.getItemPropertyVolume(item)
            if itemVol ~= nil then
                local itemVolInDB = joshnt.getVolumeAsDB(itemVol)
                volTable[item] = itemVolInDB
            end
        end
    end

    reaper.Undo_BeginBlock();
    -- normalize seperatly with recent settings
    reaper.Main_OnCommand(42460, 0)


    -- compare previous item volume values to new ones and adjust
    for item, volInDB in pairs(volTable) do
        local itemVol = joshnt.getItemPropertyVolume(item)
        if itemVol ~= nil then
            local newVolInDB = joshnt.getVolumeAsDB(itemVol)
            local diff = newVolInDB - volInDB

            if diff < maxDecrease then
                joshnt.setItemPropertyVolume(item, joshnt.getDBAsVolume(volInDB+maxDecrease))
            elseif diff > maxIncrease then
                joshnt.setItemPropertyVolume(item, joshnt.getDBAsVolume(volInDB+maxIncrease))
            end
        end
    end 

    reaper.Undo_EndBlock('Normalize seperatly with max. and min. change',-1);
end

reaper.PreventUIRefresh(1)
main()
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()