-- @description PowerReaName - Find and Replace in Track, Items, Regions or Marker Names
-- @version 1.2
-- @author Joshnt
-- @about
--      Various possibilities to reliable rename most things in REAPER
--      Requires Lokasenna_GUI Library
-- @changelog
--  - added case-sensetive search
--  - Bug fix for special characters in searchbar
--  - added option to toggle replace (offers option to add or truncate only on matching names without replacing)

local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please install 'Lokasenna's GUI library v2 for Lua', available on ReaPack, then run the 'Set Lokasenna_GUI v2 library path.lua' script in your Action List.", "Whoops!", 0)
    return
end
loadfile(lib_path .. "Core.lua")()


GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Textbox.lua")()
GUI.req("Classes/Class - Slider.lua")()
GUI.req("Classes/Class - Options.lua")()
GUI.req("Classes/Class - Tabs.lua")()
GUI.req("Classes/Class - Frame.lua")()
GUI.req("Classes/Class - Label.lua")()
-- If any of the requested libraries weren't found, abort the script.
if missing_lib then return 0 end

local searchString, replaceString, insertStartString, insertEndString, truncateStartInt, truncateEndInt;
local boolJustReturn = true
local boolReplace = true
local oldNameString, newNameString = "", ""
local markersToRename, regionsToRename = {},{} -- both include subarrays on each index with 1 = rgnIndex, 2 = rgnName, 3 = rgnStart and for regions 4 = rgnEnd
local startTime, endTime = -1,-1
local enumNameIndexMaster = {replace = nil, insertStart = nil, insertEnd = nil}
local enumNameIndex = {replace = nil, insertStart = nil, insertEnd = nil}
local enumReplaceString = {replace = "", insertStart = "", insertEnd = ""}
local targetArray = {"Tracks", "Items", "Regions", "Markers"}
local tabPressed, enterPressed = false, false
local focusedText = nil
local focusArray = {"Find", "Replace","InsertStart","insertEnd"}

GUI.name = "joshnt_PowerReaName"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 430, 380
GUI.cur_w, GUI.cur_h = GUI.w, GUI.h
GUI.anchor, GUI.corner = "screen", "C"

-- Load lua utilities
local joshnt_LuaUtils = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/DEVELOPMENT/joshnt_LuaUtilities.lua'
if reaper.file_exists( joshnt_LuaUtils ) then 
  dofile( joshnt_LuaUtils ) 
  if not joshnt or joshnt.version() < 2.21 then 
    reaper.MB("This script requires a newer version of joshnt Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages, 'joshnt_LuaUtilities.lua'","Error",0); 
    return 
  end
else 
  reaper.MB("This script requires joshnt Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt Lua Utilities'","Error",0)
  return
end

-- Function to escape special characters in the pattern
local function escapePattern(inputString)
    return string.gsub(inputString, "([%%%-%+%.%*%?%[%]%^%$%(%)])", "%%%1")
end

local function caseSensetiveFind(inputString)
    inputString = tostring(inputString)
    if not GUI.Val("ToggleCaseFind") then
        -- Convert both the searchString and the originalString to lowercase
        local lowerSearchString = string.lower(searchString)
        local lowerOriginalString = string.lower(inputString)

        -- Find the pattern in the lower case string
        return string.find(lowerOriginalString, escapePattern(lowerSearchString))
    else
        return string.find(inputString, searchString)
    end
end

-- utility functions
local function getMarkersAndRegionsInTimeFrame_WithName()
    local numRegions = reaper.CountProjectMarkers(0, 0)
    if numRegions == 0 then
        return {}, {}
    end
  
    local markersInTime, regionsInTime = {}, {}
  
    for j = 0, numRegions - 1 do
        local retval, isrgn, rgnstart, rgnend, rgnName, rgnIndex = reaper.EnumProjectMarkers( j)
        if retval then
            if isrgn then
                if startTime <= rgnend and endTime > rgnstart and caseSensetiveFind(rgnName) then
                    table.insert(regionsInTime,{rgnIndex, rgnName, rgnstart, rgnend})
                end
            else
                if startTime <= rgnstart and endTime > rgnstart and caseSensetiveFind(rgnName) then
                    table.insert(markersInTime,{rgnIndex,rgnName, rgnstart})
                end
            end
        end
    end
  
    return markersInTime, regionsInTime
end

-- Naming related Functions
local function getNewName(oldName)
    local newName = oldName
    if truncateStartInt ~= 0 then newName = string.sub(newName, (truncateStartInt+1)) end -- remove start
    if truncateEndInt ~= 0 then newName = string.sub(newName, 1, -(truncateEndInt+1)) end -- remove end
    if boolReplace then -- check if replace is toggled
        if searchString == "" and enumNameIndex.replace == nil then 
            newName = replaceString 
        elseif searchString == "" and enumNameIndex.replace ~= nil then
            enumNameIndex.replace = enumNameIndex.replace + 1
            newName = string.gsub(replaceString, enumReplaceString.replace, enumNameIndex.replace) 
        else 
            local replaceStringTemp = replaceString
            if enumNameIndex.replace ~= nil then 
                enumNameIndex.replace = enumNameIndex.replace + 1
                replaceStringTemp = string.gsub(replaceString, enumReplaceString.replace, enumNameIndex.replace) 
            end
            if not GUI.Val("ToggleCaseFind") then
                -- Convert both the searchString and the originalString to lowercase
                local lowerSearchString = string.lower(searchString)
                local lowerOriginalString = string.lower(newName)

                -- Find the pattern in the lower case string
                local startPos, endPos = string.find(lowerOriginalString, escapePattern(lowerSearchString))
                -- If the pattern is found, remove it from the original string (case-sensitive)
                if startPos then
                    newName = string.sub(newName, 1, startPos - 1) .. replaceString .. string.sub(newName, endPos + 1)
                end
            else
                newName = string.gsub(newName, escapePattern(searchString), replaceStringTemp) 
            end
        end
    end
    local insertStartString_Temp, insertEndString_Temp = insertStartString, insertEndString
    if enumNameIndex.insertStart ~= nil then
        enumNameIndex.insertStart = enumNameIndex.insertStart + 1
        insertStartString_Temp = string.gsub(insertStartString_Temp, enumReplaceString.insertStart, enumNameIndex.insertStart) 
    end
    if enumNameIndex.insertEnd ~= nil then
        enumNameIndex.insertEnd = enumNameIndex.insertEnd + 1
        insertEndString_Temp = string.gsub(insertEndString_Temp, enumReplaceString.insertEnd, enumNameIndex.insertEnd) 
    end

    newName = insertStartString_Temp..newName..insertEndString_Temp
    return newName
end

local function searchReplaceTrackName(track)
  if not track or not reaper.ValidatePtr(track, "MediaTrack") == false then return end
  local _,trackName = reaper.GetTrackName(track)
  if trackName == "Track "..math.floor(reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")) then trackName = "" end
  if caseSensetiveFind(caseSensetiveFind) then
    local newName = getNewName(trackName)
    if boolJustReturn == true then 
      oldNameString = oldNameString .. "\n"..trackName
      newNameString = newNameString.."\n"..newName
    else reaper.GetSetMediaTrackInfo_String(track, "P_NAME", newName, true) end
  end
end

local function searchReplaceItemName(item)
    if not item or not reaper.ValidatePtr(item, "MediaItem") == false then return end
    local take = reaper.GetActiveTake(item)
    if take then
        local takeName = reaper.GetTakeName(take)
        if caseSensetiveFind(takeName) then
            local newName = getNewName(takeName)
            if boolJustReturn == true then 
            oldNameString = oldNameString .. "\n"..takeName
            newNameString = newNameString.."\n"..newName
            else reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", newName, true) end
        end
    end
end

local function renameAllTracks ()
  local numTracks = reaper.CountTracks(0)
  if numTracks == 0 then return end
  
  for i = 0, numTracks -1 do
    local track = reaper.GetTrack(0,i)
    searchReplaceTrackName(track)
  end
end


local function renameSelTracks ()
  local numTracks = reaper.CountSelectedTracks(0)
  if numTracks == 0 then return end
  for i = 0, numTracks -1 do
    local track = reaper.GetSelectedTrack(0,i)
    searchReplaceTrackName(track)
  end
end

local function renameSelItems()
  local numItems = reaper.CountSelectedMediaItems(0)
  if numItems == 0 then return end
  for i = 0, numItems -1 do
    local item = reaper.GetSelectedMediaItem(0,i)
    searchReplaceItemName(item)
  end
end

local function renameAllItems()
  local numItems = reaper.CountMediaItems(0)
  if numItems == 0 then return end
  for i = 0, numItems -1 do
    local item = reaper.GetMediaItem(0,i)
    searchReplaceItemName(item)
  end
end


local function renameItemsInTime()
    local prevSelection = joshnt.saveItemSelection()
    reaper.SelectAllMediaItems(0,false)
    reaper.Main_OnCommand(40717,0) -- select items in timeselection
    local numItems = reaper.CountSelectedMediaItems(0)
    if numItems ~= 0 then
        for i = 0, numItems -1 do
            local item = reaper.GetSelectedMediaItem(0,i)
            searchReplaceItemName(item)
        end
        reaper.SelectAllMediaItems(0,false)
    end
    joshnt.reselectItems(prevSelection)
end

local function renameAllMarkersOrRegions(boolRegion)
    local numRegions = reaper.CountProjectMarkers(0, 0)
    if numRegions == 0 then
        return
    end
  
    for j = 0, numRegions - 1 do
        local retval, isrgn, rgnstart, rgnend, rgnName, rgnIndex = reaper.EnumProjectMarkers( j)
        if retval and isrgn == boolRegion and caseSensetiveFind(rgnName) then
            local newName = getNewName(rgnName)
            if boolJustReturn == true then 
                oldNameString = oldNameString .. "\n"..rgnName
                newNameString = newNameString.."\n"..newName
            else reaper.SetProjectMarker(rgnIndex, isrgn, rgnstart, rgnend, newName) end
        end
    end
end

local function renameAllRegions()
    renameAllMarkersOrRegions(true)
end

local function renameSpecificRegions()
    for i = 1, #regionsToRename do
        local currRgnIndex, currRgnName, currRgnStart, curRgnEnd = regionsToRename[i][1], regionsToRename[i][2], regionsToRename[i][3], regionsToRename[i][4]
        local newName = getNewName(currRgnName)
        if boolJustReturn == true then 
            oldNameString = oldNameString .. "\n"..currRgnName
            newNameString = newNameString.."\n"..newName
        else reaper.SetProjectMarker(currRgnIndex, true, currRgnStart, curRgnEnd, newName) end
    end
end

local function renameAllMarkers()
    renameAllMarkersOrRegions(false)
end

local function renameSpecificMarkers()
    for i = 1, #markersToRename do
        local currRgnIndex, currRgnName, currRgnStart = markersToRename[i][1], markersToRename[i][2], markersToRename[i][3]
        local newName = getNewName(currRgnName)
        if boolJustReturn == true then 
            oldNameString = oldNameString .. "\n"..currRgnName
            newNameString = newNameString.."\n"..newName
        else reaper.SetProjectMarker(currRgnIndex, false, currRgnStart, 0, newName) end
    end
end

local function empty() end

local functionTables = {
    Tracks = {renameAllTracks, renameSelTracks,empty},
    Items = {renameAllItems, renameSelItems, renameItemsInTime},
    Regions = {renameAllRegions,renameSpecificRegions,renameSpecificRegions},
    Markers = {renameAllMarkers,renameSpecificMarkers,renameSpecificMarkers}
}

-- execution function (both execute and preview)
local function executeRename()
    local selTargetTable = GUI.Val("Target")
    local selSelectionTarget = GUI.Val("selectionTarget")
    insertEndString = tostring(GUI.Val("insertEnd"))
    insertStartString = tostring(GUI.Val("InsertStart"))
    replaceString = tostring(GUI.Val("Replace"))
    searchString = tostring(GUI.Val("Find"))
    truncateStartInt = GUI.Val("TruncateStart")
    truncateEndInt = GUI.Val("TruncateEnd")

    enumNameIndexMaster = {replace = nil, insertStart = nil, insertEnd = nil}
    enumNameIndex = {replace = nil, insertStart = nil, insertEnd = nil}
    enumReplaceString = {replace = "", insertStart = "", insertEnd = ""}

    reaper.SetExtState("joshnt_PowerReaName", "Target", joshnt.tableToCSVString(selTargetTable), true)
    reaper.SetExtState("joshnt_PowerReaName", "OtherSettings", selSelectionTarget..","..searchString..","..replaceString..","..insertStartString..","..insertEndString..","..truncateStartInt..","..truncateEndInt, true)

    if selSelectionTarget == 3 then -- if minimal time selection, quit
        startTime, endTime = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
        if endTime - startTime < 0.001 then return end
    end
    if (selTargetTable[3] or selTargetTable[4]) then
        -- if selected markers & regions, get name and bounds
        if selSelectionTarget == 2 then 
            local tempRegions, tempMarker = joshnt.getSelectedMarkerAndRegionIndex()
            local numRgnMarkers = reaper.CountProjectMarkers( 0 )
            markersToRename = {} 
            regionsToRename = {} 
            for j = 0, numRgnMarkers - 1 do
                local _, isrgn, rgnpos, rgnend, rgnname, rgnIndex = reaper.EnumProjectMarkers( j)
                if tempMarker then
                    for i = 1, #tempMarker do
                        if not isrgn and rgnIndex == tempMarker[i] and caseSensetiveFind(rgnname) then
                            table.insert(markersToRename,{rgnIndex, rgnname, rgnpos})
                            break
                        end
                    end
                end
                if tempRegions then
                    for i = 1, #tempRegions do
                        if isrgn and rgnIndex == tempRegions[i] and caseSensetiveFind(rgnname) then
                            table.insert(regionsToRename,{rgnIndex, rgnname, rgnpos, rgnend})
                            break
                        end
                    end
                end
            end
        elseif selSelectionTarget == 3 then
            markersToRename, regionsToRename = getMarkersAndRegionsInTimeFrame_WithName()
        end
    end

    for textBox, _ in pairs (enumReplaceString) do
        local tempNumber = nil 
        local curString = ""
        if textBox == "replace" then
            curString = replaceString
        elseif textBox == "insertStart" then
            curString = insertStartString
        else
            curString = insertEndString
        end
        tempNumber = tonumber(curString:match("/E%((%d+)%)"))
        if tempNumber then
            enumNameIndexMaster[textBox] = tempNumber-1
            enumReplaceString[textBox] = "/E%("..tempNumber.."%)"
        elseif curString:find("/E") then
            enumNameIndexMaster[textBox] = 0
            enumReplaceString[textBox] = "/E"
        end
    end

    for i = 1, #selTargetTable do
        enumNameIndex = enumNameIndexMaster
        if selTargetTable[i] == true then
            local currTarget = targetArray[i]
            if boolJustReturn == true then
                if oldNameString == "" then
                    oldNameString, newNameString = "##  "..currTarget.."  ##\n", "##  "..currTarget.."  ##\n" 
                else 
                    oldNameString, newNameString = oldNameString.."\n_\n##  "..currTarget.."  ##\n", newNameString.."\n_\n##  "..currTarget.."  ##\n"
                end
            end
            functionTables[currTarget][selSelectionTarget]()
        end
    end
    reaper.UpdateArrange()
end

local function redrawFrame() 

    GUI.New("PreviewFrame_old", "Frame", {
        z = 21,
        x = 110,
        y = 60,
        w = (GUI.cur_w-130)/2,
        h = GUI.cur_h-70,
        shadow = false,
        fill = false,
        color = "elm_frame",
        bg = "wnd_bg",
        round = 0,
        text = oldNameString,
        txt_indent = 0,
        txt_pad = 0,
        pad = 4,
        font = 4,
        col_txt = "white"
    })

    GUI.New("PreviewFrame_new", "Frame", {
        z = 21,
        x = ((GUI.cur_w-130)/2)+120,
        y = 60,
        w = (GUI.cur_w-130)/2,
        h = GUI.cur_h-70,
        shadow = false,
        fill = false,
        color = "elm_frame",
        bg = "wnd_bg",
        round = 0,
        text = newNameString,
        txt_indent = 0,
        txt_pad = 0,
        pad = 4,
        font = 4,
        col_txt = "white"
    })

    GUI.New("oldNames", "Label", {
        z = 21,
        x = 110,
        y = 35,
        caption = "OLD NAMES",
        font = 3,
        color = "txt",
        bg = "wnd_bg",
        shadow = false
    })
    GUI.New("newNames", "Label", {
        z = 21,
        x = ((GUI.cur_w-130)/2)+120,
        y = 35,
        caption = "NEW NAMES",
        font = 3,
        color = "txt",
        bg = "wnd_bg",
        shadow = false
    })

    function GUI.elms.PreviewFrame_old:redraw()
        redrawFrame()
    end

    function GUI.elms.PreviewFrame_old:onresize()
        self:redraw()
    end
end


local function preview_Button()
    reaper.Undo_BeginBlock()
    oldNameString, newNameString = "", ""
    executeRename()
    redrawFrame()
    reaper.Undo_EndBlock("", -1)
end
    
local function run_Button()
    reaper.Undo_BeginBlock()
    boolJustReturn = false
    executeRename()
    boolJustReturn = true
    reaper.Undo_EndBlock("PowerReaName", -1)
    preview_Button()
end


GUI.New("Target", "Checklist", {
    z = 11,
    x = 16,
    y = 120,
    w = 120,
    h = 130,
    caption = "Target",
    optarray = targetArray,
    dir = "v",
    pad = 4,
    font_a = 2,
    font_b = 2,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = false,
    shadow = true,
    swap = nil,
    opt_size = 25
})

GUI.New("insertEnd", "Textbox", {
    z = 11,
    x = 230,
    y = 144,
    w = 150,
    h = 20,
    caption = "Insert at End",
    cap_pos = "left",
    font_a = 3,
    font_b = "monospace",
    color = "txt",
    bg = "wnd_bg",
    shadow = true,
    pad = 4,
    undo_limit = 20
})

GUI.New("Replace", "Textbox", {
    z = 11,
    x = 230,
    y = 80,
    w = 150,
    h = 20,
    caption = "Replace",
    cap_pos = "left",
    font_a = 3,
    font_b = "monospace",
    color = "txt",
    bg = "wnd_bg",
    shadow = true,
    pad = 4,
    undo_limit = 20
})

GUI.New("ToggleReplace", "Checklist", {
    z = 11,
    x = 390,
    y = 74,
    w = 300,
    h = 30,
    caption = "",
    optarray = {""},
    dir = "v",
    pad = 4,
    font_a = 2,
    font_b = 3,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = false,
    shadow = true,
    swap = nil,
    opt_size = 20
})

GUI.Val("ToggleReplace", true)

GUI.New("Find", "Textbox", {
    z = 11,
    x = 230,
    y = 48,
    w = 150,
    h = 20,
    caption = "Find",
    cap_pos = "left",
    font_a = 3,
    font_b = "monospace",
    color = "txt",
    bg = "wnd_bg",
    shadow = true,
    pad = 4,
    undo_limit = 20
})

GUI.New("ToggleCaseFind", "Checklist", {
    z = 11,
    x = 390,
    y = 42,
    w = 300,
    h = 30,
    caption = "",
    optarray = {""},
    dir = "v",
    pad = 4,
    font_a = 2,
    font_b = 3,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = false,
    shadow = true,
    swap = nil,
    opt_size = 20
})

GUI.New("TruncateEnd", "Slider", {
    z = 11,
    x = 230,
    y = 220,
    w = 146,
    caption = "Truncate End",
    min = 0,
    max = 20,
    defaults = {0},
    inc = 1,
    dir = "h",
    font_a = 3,
    font_b = 4,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    show_handles = true,
    show_values = true,
    cap_x = -115,
    cap_y = 22
})

GUI.New("selectionTarget", "Radio", {
    z = 11,
    x = 16,
    y = 260,
    w = 96,
    h = 130,
    caption = "",
    optarray = {"All", "Selected", "In Timeframe"},
    dir = "v",
    font_a = 2,
    font_b = 2,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = false,
    shadow = true,
    swap = nil,
    opt_size = 25
})

GUI.New("Preview", "Button", {
    z = 21,
    x = 16,
    y = 100,
    w = 80,
    h = 35,
    caption = "Refresh\nPreview",
    font = 3,
    col_txt = "txt",
    col_fill = "elm_frame",
    func = preview_Button
})

GUI.New("InsertStart", "Textbox", {
    z = 11,
    x = 230,
    y = 112,
    w = 150,
    h = 20,
    caption = "Insert at Start",
    cap_pos = "left",
    font_a = 3,
    font_b = "monospace",
    color = "txt",
    bg = "wnd_bg",
    shadow = true,
    pad = 4,
    undo_limit = 20
})

GUI.New("Tabs", "Tabs", {
    z = 1,
    x = 0,
    y = 0,
    w = 912.0,
    caption = "Tabs",
    optarray = {"Settings", " Preview"},
    tab_w = 55,
    tab_h = 25,
    pad = 8,
    font_a = 3,
    font_b = 4,
    col_txt = "txt",
    col_tab_a = "wnd_bg",
    col_tab_b = "tab_bg",
    bg = "elm_bg",
    fullwidth = true
})

GUI.New("Run", "Button", {
    z = 1,
    x = 16,
    y = 48,
    w = 80,
    h = 35,
    caption = "Execute",
    font = 3,
    col_txt = "txt",
    col_fill = "elm_frame",
    func = run_Button
})

GUI.New("TruncateStart", "Slider", {
    z = 11,
    x = 230,
    y = 180,
    w = 146,
    caption = "Truncate Start",
    min = 0,
    max = 20,
    defaults = {0},
    inc = 1,
    dir = "h",
    font_a = 3,
    font_b = 4,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    show_handles = true,
    show_values = true,
    cap_x = -117,
    cap_y = 22
})


GUI.elms.Find.tooltip = "Text input to search in target names.\nLeave empty to apply to all target names."
GUI.elms.Replace.tooltip = "Text input to replace the search string with.\nUse '/E(X)' (e.g. '/E(1)') to enumerate from X. Just '/E' defaults to 1.\n(All targets get enumrated seperatly)\nIf 'find' is empty, target name is set to this"
GUI.elms.InsertStart.tooltip = "Inserts this at the beginning of the targets name (after truncate got applied)\nOnly applies, if it matches the 'find' field.\nUsage of '/E' possible (see 'Replace'-box tooltip)"
GUI.elms.insertEnd.tooltip = "Inserts this at the end of the targets name (after truncate got applied)\nOnly applies, if it matches the 'find' field\nUsage of '/E' possible (see 'Replace'-box tooltip)"
GUI.elms.Preview.tooltip = "Click to refresh the renaming preview, e.g. after changing a selection\nShortcut: 'R'"

for i = 1, #focusArray do
    local currText = GUI.elms[focusArray[i]]
    function currText:lostfocus()
        GUI.Textbox.lostfocus(self)
        if tabPressed == false then focusedText = 1 end
    end

end

GUI.elms.TruncateStart.tooltip = "How many charactes to cut at the beginning of the target's name"
GUI.elms.TruncateEnd.tooltip = "How many charactes to cut at the end of the target's name"
GUI.elms.selectionTarget.tooltip = "Sets which targets exactly to check"
GUI.elms.Target.tooltip = "Sets the target to search and rename"
GUI.elms.ToggleReplace.tooltip = "Toggle if the text in the 'find' field should be replaced."
GUI.elms.ToggleCaseFind.tooltip = "Toggle case sensetive search"

redrawFrame()

GUI.elms.Tabs:update_sets({
    [1] = {11},
    [2] = {21}
})

function GUI.elms.ToggleReplace:onmouseup()
    GUI.Checklist.onmouseup(self)        
    if GUI.Val("ToggleReplace") then 
        GUI.elms.Replace.z = 11
        GUI.redraw_z[11] = true
    else
        GUI.elms.Replace.z = 5
        GUI.redraw_z[11] = true
    end
    boolReplace = GUI.Val("ToggleReplace")
end

function GUI.elms.Tabs:onmousedown()
    GUI.Tabs.onmousedown(self)        
    preview_Button()
end
function GUI.elms.Tabs:onmouseup()
    GUI.Tabs.onmouseup(self)        
    preview_Button()
end
function GUI.elms.Tabs:onwheel()
    GUI.Tabs.onwheel(self)    
    preview_Button()
end


-- load defaults
local function loadDefaults()
    if reaper.HasExtState("joshnt_PowerReaName", "Target") then
        local targetBoolArray = joshnt.splitStringToTable(reaper.GetExtState("joshnt_PowerReaName", "Target"))
        GUI.Val("Target", targetBoolArray)
    end
    if reaper.HasExtState("joshnt_PowerReaName", "Target") then
        local otherSettingsTable = joshnt.splitStringToTable(reaper.GetExtState("joshnt_PowerReaName", "OtherSettings"))
        for i = 1, #otherSettingsTable do
            if otherSettingsTable and otherSettingsTable[i] ~= "" and otherSettingsTable[i] ~= 0 then
                if i == 1 then GUI.Val("selectionTarget",otherSettingsTable[i])
                elseif i == 2 then GUI.Val("Find",otherSettingsTable[i])
                elseif i == 3 then GUI.Val("Replace",otherSettingsTable[i])
                elseif i == 4 then GUI.Val("InsertStart",otherSettingsTable[i])
                elseif i == 5 then GUI.Val("insertEnd",otherSettingsTable[i])
                elseif i == 6 then GUI.Val("TruncateStart",otherSettingsTable[i])
                else GUI.Val("TruncateEnd",otherSettingsTable[i]) end
            end
        end
    end
end

local function Loop()
    if GUI.char == 9.0 and tabPressed == false then
        if type(focusedText) == "number" then
            GUI.elms[focusArray[focusedText]].focus = false
            if GUI.mouse.cap == 8 then
                focusedText = ((focusedText-2) % #focusArray) +1
            else
                focusedText = (focusedText % #focusArray) +1
            end
        else 
            focusedText = 1
        end
        GUI.elms[focusArray[focusedText]].focus = true
        tabPressed = true
    elseif GUI.char == 13.0 and enterPressed == false then
        for i = 1, #focusArray do
            if GUI.elms[focusArray[i]].focus == true then return end
        end
        run_Button()
        enterPressed = true
    elseif GUI.char == 114 then
        preview_Button()
    elseif GUI.char == 0.0 then
        if tabPressed == true then tabPressed = false
        elseif enterPressed == true then enterPressed = false end
    end
end

reaper.set_action_options(1) -- on rerun, terminate script
loadDefaults()
GUI.func = Loop
GUI.freq = 0
GUI.Init()
GUI.Main()