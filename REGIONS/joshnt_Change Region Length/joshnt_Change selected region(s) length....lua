-- @noindex

local joshnt_LuaUtils = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/DEVELOPMENT/joshnt_LuaUtilities.lua'
if reaper.file_exists( joshnt_LuaUtils ) then 
  dofile( joshnt_LuaUtils ) 
  if not joshnt or joshnt.version() < 2.2 then 
    reaper.MB("This script requires a newer version of joshnt Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages, 'joshnt_LuaUtilities.lua'","Error",0); 
    return 
  end
else 
  reaper.MB("This script requires joshnt Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt Lua Utilities'","Error",0)
  return
end

local function userInputValues()
    local continue, s = reaper.GetUserInputs("Max. Volume change in normalization", 2,
        "Time adjust (ms):, Adjust Region...:,extrawidth=100","1000,end")
    
    if not continue or s == "" then joshnt.TooltipAtMouse("Input canceled by user") return false end
    local q = joshnt.fromCSV(s)
    
    -- Get the values from the input
    local input1 = tonumber(q[1])
    local input2 = q[2] == "start"
    if type(input1) ~= "number" then joshnt.TooltipAtMouse("Invalid user input") return false end

    return input1, input2
end

local selRgns, _ = joshnt.getSelectedMarkerAndRegionIndex()


if selRgns then
    local time, boolStart = userInputValues()
    if not time then return else time = time/1000 end
    reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)
    for i = 0, #selRgns do
        local rgnStart, rgnEnd, rgnName = joshnt.getRegionBoundsByIndex(selRgns[i])
        if rgnStart then 
            if boolStart then
                reaper.SetProjectMarker(selRgns[i], true, rgnStart - time, rgnEnd, rgnName)
            else
                reaper.SetProjectMarker(selRgns[i], true, rgnStart, rgnEnd + time, rgnName)
            end
        end
    end
    reaper.PreventUIRefresh(-1) 
    reaper.UpdateArrange()
    reaper.Undo_EndBlock('Change sel. region(s) length...', -1)
else
    joshnt.TooltipAtMouse("No region(s) selected!")
end
