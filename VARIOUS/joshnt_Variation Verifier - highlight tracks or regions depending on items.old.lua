-- @description Variation Verfier
-- @version 1.0
-- @author Joshnt
-- @about
--    Marks/ Colors/ Hides Tracks if different than given number of items
--    Useful for checking number of Variations of multiple files after dynamic splitting them
--    
--    User-Inputs:
--    Wanted Items Per Track: provide the number which the number of items on a track should match/ be lower/ larger than
--    Math. Comparison: insert different mathematical comparison symbols (allowed: =, <, > and /=, != or ~= for not equal to - or written out as words)
--    Operation with correct Tracks: write "Color", "Select", "Hide", "Delete" or "Nothing" - or first letter of those words
--    Operation with wrong Tracks: write "Color", "Select", "Hide", "Delete" or "Nothing" - or first letter of those words
--    
-- @changelog
--  + init

---------------------------------------
--------- USER CONFIG - EDIT ME -------
--- Default Values for input dialog ---
---------------------------------------

local wantedItemsPerTrack_Math_USER = "!=" -- insert different mathematical comparison symbols (allowed: =, <, >, != or written out)
local wantedItemsPerTrack_Num_USER = 6 -- provide the number which the number of items on a track should match/ be lower/ larger than
local operationWithTracksWrong_USER = "Hide" -- write "Color", "Select", "Hide", "Delete" or "Nothing" - or first letter of those words
local operationWithTrackCorrect_USER = "Color" -- write "Color", "Select", "Hide", "Delete" or "Nothing" - or first letter of those words
local showTrackNames_Correct_USER = false -- set true or false to show console with track names of track meeting given condition after script execution
local showTrackNames_Wrong_USER = true -- set true or false to show console with track names of track not meeting given condition after script execution
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

-- Input Values
local mathOperation, wantItemNum, opTrackWrong_GLOBAL, opTrackCorrect_GLOBAL, mathOperationSymbol;

local function userInputValues()
    local defaultValuesString = wantedItemsPerTrack_Num_USER .. "," .. wantedItemsPerTrack_Math_USER .. "," .. operationWithTrackCorrect_USER .. "," .. operationWithTracksWrong_USER
    local continue, s = reaper.GetUserInputs("Highlight Tracks if items are:", 4,
        "Number of Items Per Track:,Compare (Number x itemsTrack):,Operation matching Tracks:,Operation other Tracks:,,extrawidth=100",
        defaultValuesString)
    
    if not continue or s == "" then return false end
    local q = joshnt.fromCSV(s)
    
    local function invalidUserInput(stringInput)
        reaper.MB("Invalid User Input at '"..stringInput.."'.", "Version Verifier - ERROR", 0)
    end

    -- Get the values from the input
    if tonumber(q[1]) then 
        wantItemNum = tonumber(q[1])
    else
        invalidUserInput("Number of Items per Track")
        return false
    end

    mathOperation = q[2]
    local opTrackWrong_TEMP = q[4]
    local opTrackCorrect_TEMP = q[3]

    if mathOperation == "=" or mathOperation == "==" or mathOperation == "equal" or mathOperation == "e" then
        mathOperation = 0
        mathOperationSymbol = "="
    elseif mathOperation == "<" or mathOperation == "higher" or mathOperation == "h" then
        mathOperation = 1
        mathOperationSymbol = "<"
    elseif mathOperation == ">" or mathOperation == "lower" or mathOperation == "l" or mathOperation == "smaller" or mathOperation == "s" then
        mathOperation = 2
        mathOperationSymbol = ">"
    elseif mathOperation == "~=" or mathOperation == "=/=" or mathOperation == "/=" or mathOperation == "=/" or mathOperation == "!=" or mathOperation == "not equal" or mathOperation == "n" then
        mathOperation = 3
        mathOperationSymbol = "!="
    else
        invalidUserInput("Math. Operation")
        return false
    end

    if wantItemNum < 0 then
        invalidUserInput("wanted item number per Track")
        return false
    end

    opTrackWrong_GLOBAL = 4
    if opTrackWrong_TEMP == "Color" or opTrackWrong_TEMP == "c" or opTrackWrong_TEMP == "C" then
        opTrackWrong_GLOBAL = 0
    elseif opTrackWrong_TEMP == "Select" or opTrackWrong_TEMP == "S" or opTrackWrong_TEMP == "s" then
        opTrackWrong_GLOBAL = 1
    elseif opTrackWrong_TEMP == "Hide" or opTrackWrong_TEMP == "H" or opTrackWrong_TEMP == "h" then
        opTrackWrong_GLOBAL = 2
    elseif opTrackWrong_TEMP == "Delete" or opTrackWrong_TEMP == "D" or opTrackWrong_TEMP == "d" then
        opTrackWrong_GLOBAL = 3
    end

    opTrackCorrect_GLOBAL = 4
    if opTrackCorrect_TEMP == "Color" or opTrackCorrect_TEMP == "c" or opTrackCorrect_TEMP == "C" then
        opTrackCorrect_GLOBAL = 0
    elseif opTrackCorrect_TEMP == "Select" or opTrackCorrect_TEMP == "S" or opTrackCorrect_TEMP == "s" then
        opTrackCorrect_GLOBAL = 1
    elseif opTrackCorrect_TEMP == "Hide" or opTrackCorrect_TEMP == "H" or opTrackCorrect_TEMP == "h" then
        opTrackCorrect_GLOBAL = 2
    elseif opTrackCorrect_TEMP == "Delete" or opTrackCorrect_TEMP == "D" or opTrackCorrect_TEMP == "d" then
        opTrackCorrect_GLOBAL = 3
    end

    return true
end

local function markTrackWrong (trackInput)
    if opTrackWrong_GLOBAL == 0 then -- 0 = color
        reaper.SetTrackColor(trackInput, reaper.ColorToNative(80,213,76)) -- green
    elseif opTrackWrong_GLOBAL == 1 then -- 1 = select
        reaper.SetTrackSelected(trackInput, true)
    elseif opTrackWrong_GLOBAL == 2 then -- 2 = Hide
        reaper.SetMediaTrackInfo_Value(trackInput,'B_SHOWINTCP',0);
    end
    -- delete after all tracks got checked
end

local function markTrackCorrect (trackInput)
    if opTrackCorrect_GLOBAL == 0 then -- 0 = color
        reaper.SetTrackColor(trackInput, reaper.ColorToNative(245,65,65)) -- red
    elseif opTrackCorrect_GLOBAL == 1 then -- 1 = select
        reaper.SetTrackSelected(trackInput, true)
    elseif opTrackCorrect_GLOBAL == 2 then -- 2 = Hide
        reaper.SetMediaTrackInfo_Value(trackInput,'B_SHOWINTCP',0);
    end
    -- delete after all tracks got checked
end

local function main()
    local numItems = reaper.CountMediaItems(0)
    if numItems == 0 then
        return
    end

    if userInputValues() then
        if opTrackCorrect_GLOBAL == 4 and opTrackWrong_GLOBAL == 4 then
            return
        end
        local wrongTrack_Table = {}
        local correctTrack_Table = {}

        reaper.PreventUIRefresh(1) 
        reaper.Undo_BeginBlock()  

        joshnt.unselectAllTracks()

        for i = 0, reaper.CountTracks(0)-1 do -- check tracks if wrong or right
            local track_TEMP = reaper.GetTrack(0,i)
            local numItems_Track = reaper.CountTrackMediaItems(track_TEMP)
            if mathOperation == 0 then -- item number on tracks is equal to User input
                if numItems_Track == wantItemNum then
                    markTrackCorrect(track_TEMP)
                    table.insert(correctTrack_Table, track_TEMP)
                else
                    markTrackWrong(track_TEMP)
                    table.insert(wrongTrack_Table, track_TEMP)
                end
            elseif mathOperation == 1 then -- highligth item number on tracks is larger than User input
                if numItems_Track > wantItemNum then
                    markTrackCorrect(track_TEMP)
                    table.insert(correctTrack_Table, track_TEMP)
                else
                    markTrackWrong(track_TEMP)
                    table.insert(wrongTrack_Table, track_TEMP)
                end
            elseif mathOperation == 2 then -- highlight item number on tracks is lower than User input
                if numItems_Track < wantItemNum then
                    markTrackCorrect(track_TEMP)
                    table.insert(correctTrack_Table, track_TEMP)
                else
                    markTrackWrong(track_TEMP)
                    table.insert(wrongTrack_Table, track_TEMP)
                end
            else -- highlight item number on tracks is not equal to User input
                if numItems_Track ~= wantItemNum then
                    markTrackCorrect(track_TEMP)
                    table.insert(correctTrack_Table, track_TEMP)
                else
                    markTrackWrong(track_TEMP)
                    table.insert(wrongTrack_Table, track_TEMP)
                end
            end

        end

        if showTrackNames_Wrong_USER or showTrackNames_Correct_USER then
            reaper.ClearConsole()
            reaper.ShowConsoleMsg("Mark Tracks with different item numbers (Variation Verifier) - Track Name Output:")

            if showTrackNames_Correct_USER then -- print correct track names in console
                reaper.ShowConsoleMsg("\n\nFollowing tracks had items different than " .. mathOperationSymbol .. " to "..wantItemNum)
                for i = 1, #wrongTrack_Table do
                    local retval, name = reaper.GetTrackName(wrongTrack_Table[i])
                    if retval then reaper.ShowConsoleMsg("\n"..name) end
                end
            end

            if showTrackNames_Wrong_USER then -- print wrong track names in console
                reaper.ShowConsoleMsg("\n\nFollowing tracks had items " .. mathOperationSymbol .. " to "..wantItemNum)
                for i = 1, #correctTrack_Table do
                    local retval, name = reaper.GetTrackName(correctTrack_Table[i])
                    if retval then reaper.ShowConsoleMsg("\n"..name) end
                end
            end
        end
        if opTrackWrong_GLOBAL == 3 then -- delete correct tracks if user input
            for i = 1, #wrongTrack_Table do
                reaper.DeleteTrack(wrongTrack_Table[i])
            end
        end
        if opTrackCorrect_GLOBAL == 3 then -- delete wrong tracks if user input
            for i = 1, #correctTrack_Table do
                reaper.DeleteTrack(correctTrack_Table[i])
            end
        end

        reaper.Undo_EndBlock("Variation Verifier", -1)
        reaper.PreventUIRefresh(-1)
        reaper.UpdateArrange()
    end
end

main()
