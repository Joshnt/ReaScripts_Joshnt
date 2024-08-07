-- @description Zoom to previous region
-- @version 1.0
-- @author Joshnt
-- @about
--    Zoom to previous region; Idea and Concept + v1 as custom action by Exenye
--    basically chaining REAPER/ SWS commands - avoiding the need to setup own custom action by that + smoother UI because of UI gets updated after everthing is complete
-- @changelog
--  + init

-- check for SWS extension
if reaper.NamedCommandLookup("_SWS_ABOUT") == 0 then
    reaper.MB("This script requires the SWS Extension. Please install it from here:\n\nhttps://www.sws-extension.org/","Error",0)
    return
end

local function main()
    local curPosOld = reaper.GetCursorPosition()

    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SELPREVREG"),0) -- timeselect previous region
    reaper.Main_OnCommand(40630,0) -- set cursor to new region
    reaper.Main_OnCommand(40717,0) -- select all items in timeselection
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_HZOOMITEMS"),0) -- horizontal zoom to selected items
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_VZOOMIITEMS"),0) -- vertical zoom to selected items
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_UNSELALL"),0) -- unselect everthing

    local curPosNew = reaper.GetCursorPosition()
    if curPosOld < curPosNew then
        local x, y = reaper.GetMousePosition()
        reaper.TrackCtl_SetToolTip("Zoomed to last region in project", x+17, y+17, false )
    end
end

reaper.Undo_BeginBlock()
main()
reaper.UpdateArrange()
reaper.Undo_EndBlock('Zoom to previous region', -1)