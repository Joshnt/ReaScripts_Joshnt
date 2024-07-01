-- @description Play only selected Time
-- @version 1.0
-- @changelog
-- + init
-- @author Joshnt
-- @about 
--    play only time selection (from start of timeselection or edit cursor)

local timeRangeStart, timeRangeEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
local playState = reaper.GetPlayState()


local repeatState = reaper.GetSetRepeat(-1)
if repeatState == 1 then
    reaper.GetSetRepeat(0)
end

if playState == 4 then -- recording
    local x, y = reaper.GetMousePosition()
    reaper.TrackCtl_SetToolTip("Can't play only time-selection while recording", x+17, y+17, false )
    return
elseif playState == 1 then -- playing
    local playPos = reaper.GetPlayPosition()
    if playPos > timeRangeEnd then
        reaper.SetEditCurPos(timeRangeStart, true, true)
    end
else 
    if reaper.GetCursorPosition() < timeRangeStart or reaper.GetCursorPosition() > timeRangeEnd then
        reaper.SetEditCurPos(timeRangeStart, true, true)
    end
end

if playState == 0 or playState == 2 then -- stopped or paused
    reaper.Main_OnCommand(1007, 0) -- play (toggle)
end

local function breakLoop()
    if repeatState == 1 then
        reaper.GetSetRepeat(1)
    end
end

local function mainLoop()
    local newPlayState = reaper.GetPlayState()
    local newPlayPos = reaper.GetPlayPosition()
    if newPlayState == 0 or newPlayState == 2 then
        breakLoop()
        return
    end
    if newPlayPos >= timeRangeEnd then
        reaper.Main_OnCommand(1016, 0) -- 1016 stop playback
        breakLoop()
        return
    end
    reaper.defer(mainLoop)
end

mainLoop()