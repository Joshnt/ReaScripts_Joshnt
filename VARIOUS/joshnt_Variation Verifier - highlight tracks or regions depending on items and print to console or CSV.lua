-- @description Variation Verfier
-- @version 1.1
-- @author Joshnt
-- @about
--    Marks/ Colors/ Hides Tracks or regions if different than given number of items
--    Useful for checking number of Variations of multiple files after dynamic splitting them
--    
-- @changelog
--  minor bug fix for print to console



local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please install 'Lokasenna's GUI library v2 for Lua', available on ReaPack, then run the 'Set Lokasenna_GUI v2 library path.lua' script in your Action List.", "Whoops!", 0)
    return
end
loadfile(lib_path .. "Core.lua")()

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


GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Label.lua")()
GUI.req("Classes/Class - Options.lua")()
GUI.req("Classes/Class - Textbox.lua")()
GUI.req("Classes/Class - Frame.lua")()
-- If any of the requested libraries weren't found, abort the script.
if missing_lib then return 0 end



GUI.name = "joshnt - variation verifier"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 1000, 350
GUI.anchor, GUI.corner = "screen", "C"
local actionOptArray = {"Color", "Select", "Delete", "Hide", "Do nothing"}
local targetOptArray = {"All Tracks", "All Regions", "Sel. Tracks", "Sel. Regions"}

-- variables
local textArrayDescription = {
    target = "",
    countWhat = "",
    numItems = "",
    mathCompare = "",
    actionMain = "",
    actionsOther = "",
    print = "",
    printwhat = "",
    printWhere = ""
}
local colors = {main = nil, other = nil}
local redrawAction = nil

-- keyinput variables
local tabOrder = {"target","mathCompare","numItems","actionMain","countWhat","actionsOther"}
local tabPosition = 0
local keyPress = false

local function checkOptionDefaults()
    local retvalRedraw = false
    if reaper.HasExtState("joshnt_VariationVerifier_Interface", "printMatching") then
        -- print default values
        local defaultsTable1 = {}
        local defaultsTable2 = {}
        local defaultsTable3 = {}
        table.insert(defaultsTable1,reaper.GetExtState("joshnt_VariationVerifier_Interface", "printMatching")=="true")
        table.insert(defaultsTable1,reaper.GetExtState("joshnt_VariationVerifier_Interface", "printOther")=="true")
        table.insert(defaultsTable2,reaper.GetExtState("joshnt_VariationVerifier_Interface", "printNames")=="true")
        table.insert(defaultsTable2,reaper.GetExtState("joshnt_VariationVerifier_Interface", "printItemCount")=="true")
        table.insert(defaultsTable3,reaper.GetExtState("joshnt_VariationVerifier_Interface", "printToConsole")=="true")
        table.insert(defaultsTable3,reaper.GetExtState("joshnt_VariationVerifier_Interface", "printToCSV")=="true")
        GUI.Val("print",defaultsTable1)
        GUI.Val("printwhat",defaultsTable2)
        GUI.Val("printWhere",defaultsTable3)

        -- other default values
        GUI.Val("target",tonumber(reaper.GetExtState("joshnt_VariationVerifier_Interface", "target")))
        GUI.Val("countWhat",tonumber(reaper.GetExtState("joshnt_VariationVerifier_Interface", "countWhat")))
        GUI.Val("numItems",tonumber(reaper.GetExtState("joshnt_VariationVerifier_Interface", "numItems") or 0))
        GUI.Val("mathCompare",tonumber(reaper.GetExtState("joshnt_VariationVerifier_Interface", "mathCompare")))
        GUI.Val("actionMain",tonumber(reaper.GetExtState("joshnt_VariationVerifier_Interface", "actionMain")))
        GUI.Val("actionsOther",tonumber(reaper.GetExtState("joshnt_VariationVerifier_Interface", "actionsOther")))
        local colorsTEMP = joshnt.splitStringToTable(reaper.GetExtState("joshnt_VariationVerifier_Interface", "Colors"))
        if tonumber(colorsTEMP[1]) then colors.main = tonumber(colorsTEMP[1]) retvalRedraw = true end
        if tonumber(colorsTEMP[2]) then colors.other = tonumber(colorsTEMP[2]) retvalRedraw = true end
    end
    return retvalRedraw
end

local function saveOptions()
    -- print defaults 
    local printBoolTable = GUI.Val("print")
    local printWhatBoolTable = GUI.Val("printwhat")
    local printWhereBoolTable = GUI.Val("printWhere")


    reaper.SetExtState("joshnt_VariationVerifier_Interface", "printMatching", tostring(printBoolTable[1]), true)
    reaper.SetExtState("joshnt_VariationVerifier_Interface", "printOther", tostring(printBoolTable[2]), true)
    reaper.SetExtState("joshnt_VariationVerifier_Interface", "printNames", tostring(printWhatBoolTable[1]), true)
    reaper.SetExtState("joshnt_VariationVerifier_Interface", "printItemCount", tostring(printWhatBoolTable[2]), true)
    reaper.SetExtState("joshnt_VariationVerifier_Interface", "printToConsole", tostring(printWhereBoolTable[1]), true)
    reaper.SetExtState("joshnt_VariationVerifier_Interface", "printToCSV", tostring(printWhereBoolTable[2]), true)

    -- other defaults 
    reaper.SetExtState("joshnt_VariationVerifier_Interface", "target", tostring(GUI.Val("target")), true)
    reaper.SetExtState("joshnt_VariationVerifier_Interface", "countWhat", tostring(GUI.Val("countWhat")), true)
    reaper.SetExtState("joshnt_VariationVerifier_Interface", "numItems", tostring(GUI.Val("numItems")), true)
    reaper.SetExtState("joshnt_VariationVerifier_Interface", "mathCompare", tostring(GUI.Val("mathCompare")), true)
    reaper.SetExtState("joshnt_VariationVerifier_Interface", "actionMain", tostring(GUI.Val("actionMain")), true)
    reaper.SetExtState("joshnt_VariationVerifier_Interface", "actionsOther", tostring(GUI.Val("actionsOther")), true)
    reaper.SetExtState("joshnt_VariationVerifier_Interface", "Colors", tostring(colors.main)..","..tostring(colors.other), true)
end

local function updateDescription()
    local textString;

    local mathCompare_toString = ""
    if textArrayDescription.mathCompare == "=" then 
        mathCompare_toString = "exactly"
    elseif textArrayDescription.mathCompare == "!=" then
        mathCompare_toString = "not"
    elseif textArrayDescription.mathCompare == "<" then
        mathCompare_toString = "less than"
    else 
        mathCompare_toString = "more than"
    end

    local print_toString = ""
    if textArrayDescription.print == "" or textArrayDescription.printwhat == "" or textArrayDescription.printWhere == "" then 
        print_toString = "Don't print anything."
    else
        print_toString = "Print "..textArrayDescription.printwhat.." "..textArrayDescription.print.." to "..textArrayDescription.printWhere.."."
    end
    if textArrayDescription.actionsOther ~= "Do nothing" then
        textString = textArrayDescription.actionMain.." "..textArrayDescription.target.." with "..mathCompare_toString.." "..textArrayDescription.numItems.." "..textArrayDescription.countWhat..". "..textArrayDescription.actionsOther.." others. "..print_toString
    else
        textString = textArrayDescription.actionMain.." "..textArrayDescription.target.." with "..mathCompare_toString.." "..textArrayDescription.numItems.." "..textArrayDescription.countWhat..". "..print_toString
    end
    GUI.Val("description",textString)
end

local function updateTextArrayDescription_Full()
    if GUI.Val("numItems") == "" then GUI.Val("numItems",0) end
    textArrayDescription = {
        target = GUI.elms.target.optarray[GUI.Val("target")],
        countWhat = GUI.elms.countWhat.optarray[GUI.Val("countWhat")],
        numItems = tostring(GUI.Val("numItems")),
        mathCompare = GUI.elms.mathCompare.optarray[GUI.Val("mathCompare")],
        actionMain = GUI.elms.actionMain.optarray[GUI.Val("actionMain")],
        actionsOther = GUI.elms.actionsOther.optarray[GUI.Val("actionsOther")],
    }

    local optionTable = GUI.Val("print")
    local tempString = ""
    for index, bool in ipairs(optionTable) do
        if bool == true then
            if tempString ~= "" then
                tempString = tempString.." and "..GUI.elms.print.optarray[index]
            else
                tempString = GUI.elms.print.optarray[index]
            end
        end
    end
    textArrayDescription.print = tempString

    optionTable = GUI.Val("printwhat")
    tempString = ""
    for index, bool in ipairs(optionTable) do
        if bool == true then
            if tempString ~= "" then
                tempString = tempString.." and "..GUI.elms.printwhat.optarray[index]
            else
                tempString = GUI.elms.printwhat.optarray[index]
            end
        end
    end
    textArrayDescription.printwhat = tempString

    optionTable = GUI.Val("printWhere")
    tempString = ""
    for index, bool in ipairs(optionTable) do
        if bool == true then
            if tempString ~= "" then
                tempString = tempString.." and "..GUI.elms.printWhere.optarray[index]
            else
                tempString = GUI.elms.printWhere.optarray[index]
            end
        end
    end
    textArrayDescription.printWhere = tempString

    updateDescription()
end

local function run_VariationVerifier()
    if not colors.main then colors.main = reaper.ColorToNative(0, 255, 0) end
    if not colors.other then colors.other = reaper.ColorToNative(0, 255, 0) end
    updateTextArrayDescription_Full()

    local function markTrackOther (trackInput)
        if textArrayDescription.actionsOther == "Color" then
            reaper.SetTrackColor(trackInput, colors.other | 0x1000000)
        elseif textArrayDescription.actionsOther == "Select" then
            reaper.SetTrackSelected(trackInput, true)
        elseif textArrayDescription.actionsOther == "Hide" then
            reaper.SetMediaTrackInfo_Value(trackInput,'B_SHOWINTCP',0);
        end
        -- delete after all tracks got checked
    end

    local function markTrackMain (trackInput)
        if textArrayDescription.actionMain == "Color" then
            reaper.SetTrackColor(trackInput, colors.main | 0x1000000) -- TODO: maybe need | 0x10000...
        elseif textArrayDescription.actionMain == "Select" then 
            reaper.SetTrackSelected(trackInput, true)
        elseif textArrayDescription.actionMain == "Hide" then
            reaper.SetMediaTrackInfo_Value(trackInput,'B_SHOWINTCP',0);
        end
        -- delete after all tracks got checked
    end

    local function compareItemCount(itemNum)
        if textArrayDescription.mathCompare == "=" then
            if itemNum == tonumber(textArrayDescription.numItems) then
                return true
            else
                return false
            end
        elseif textArrayDescription.mathCompare == "!=" then
            if itemNum ~=  tonumber(textArrayDescription.numItems) then
                return true
            else
                return false
            end
        elseif textArrayDescription.mathCompare == "<" then
            if itemNum < tonumber(textArrayDescription.numItems) then
                return true
            else
                return false
            end
        else
            if itemNum > tonumber(textArrayDescription.numItems) then
                return true
            else
                return false
            end
        end
    end

    local function conditionalUnselect()
        if textArrayDescription.actionMain == "Select" or textArrayDescription.actionsOther == "Select" then
            joshnt.unselectAllTracks()
        end
    end

    local function getItemNumInTimeframe(startTime, endTime)
        if endTime - startTime < 0.01 then return 0 end
        reaper.SelectAllMediaItems(0, false)
        reaper.GetSet_LoopTimeRange(true, false, startTime, endTime, false)
        reaper.Main_OnCommand(40717, 0) -- select items in time
        return reaper.CountSelectedMediaItems(0)
    end

    local numItems = reaper.CountMediaItems(0)
    if numItems == 0 then joshnt.TooltipAtMouse("No items in project!") return end


    local mainTarget_Table = {} -- contains tracks/ rgn_index as keys and subarray with name and number per key value
    local otherTarget_Table = {} -- contains tracks/ rgn_index as keys and subarray with name and number per key value

    reaper.PreventUIRefresh(1) 
    reaper.Undo_BeginBlock()  

    if textArrayDescription.target == "All Tracks" then
        local tracksNum = reaper.CountTracks(0)
        if tracksNum == 0 then joshnt.TooltipAtMouse("No tracks in project!") return end
        conditionalUnselect()
        for i = 0, tracksNum-1 do -- check tracks if wrong or right
            local track_TEMP = reaper.GetTrack(0,i)
            local numItems_Track = reaper.CountTrackMediaItems(track_TEMP)
            local retval = compareItemCount(numItems_Track)
            if retval == true then
                markTrackMain(track_TEMP)
                local retval2, name = reaper.GetTrackName(track_TEMP)
                mainTarget_Table[track_TEMP] = {name, numItems_Track}
            else
                markTrackOther(track_TEMP)
                local retval2, name = reaper.GetTrackName(track_TEMP)
                otherTarget_Table[track_TEMP] = {name, numItems_Track}
            end
        end
    elseif textArrayDescription.target == "Sel. Tracks" then
        local selTrackTable = {}
        local selTracksNum = reaper.CountSelectedTracks(0)
        if selTracksNum == 0 then joshnt.TooltipAtMouse("No selected tracks!") return end
        for i = 0, selTracksNum-1 do
            table.insert(selTrackTable,reaper.GetSelectedTrack(0, i))
        end
        conditionalUnselect()
        for i = 1, #selTrackTable do -- check tracks if wrong or right
            local track_TEMP = selTrackTable(i)
            local numItems_Track = reaper.CountTrackMediaItems(track_TEMP)
            local retval = compareItemCount(numItems_Track)
            if retval == true then
                markTrackMain(track_TEMP)
                mainTarget_Table[track_TEMP] = numItems_Track
            else
                markTrackOther(track_TEMP)
                otherTarget_Table[track_TEMP] = numItems_Track
            end
        end
    elseif textArrayDescription.target == "All Regions" then
        local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
        if num_regions == 0 then joshnt.TooltipAtMouse("No regions in project!") return end
        local num_total = num_markers + num_regions
        for j=0, num_total - 1 do
          local retval2, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers( j )
          if name == "" then name = "Region Nr."..markrgnindexnumber end
          if isrgn then
            local numItems_rgn = getItemNumInTimeframe(pos,rgnend)
            local retval = compareItemCount(numItems_rgn)
            if retval == true then
                mainTarget_Table[markrgnindexnumber] = {name, numItems_rgn}
            else
                otherTarget_Table[markrgnindexnumber] = {name, numItems_rgn}
            end
          end
        end
    else -- selected regions
        local selRgns, _ = joshnt.getSelectedMarkerAndRegionIndex()
        if selRgns then
            for i = 1, #selRgns do
                local rgnStart, rgnEnd, name = joshnt.getRegionBoundsByIndex(selRgns[i])
                local numItems_rgn = getItemNumInTimeframe(rgnStart,rgnEnd)
                local retval = compareItemCount(numItems_rgn)
                if name == "" then name = "Region Nr."..selRgns[i] end
                if retval == true then
                    mainTarget_Table[selRgns[i]] = {name, numItems_rgn}
                else
                    otherTarget_Table[selRgns[i]] = {name, numItems_rgn}
                end
            end
        else
            joshnt.TooltipAtMouse("No selected regions!")
            return
        end
    end

    -- print names/ item count
    if textArrayDescription.print ~= "" and textArrayDescription.printwhat ~= "" and textArrayDescription.printWhere ~= "" then
        
        -- print to console
        if string.find(textArrayDescription.printWhere,"console") then
            reaper.ClearConsole()
            reaper.ShowConsoleMsg("Variation Verifier - Target Name Output:")

            if string.find(textArrayDescription.print,"matching") then
                reaper.ShowConsoleMsg("\n\nFollowing "..textArrayDescription.target.." had items " .. textArrayDescription.mathCompare .. " to "..textArrayDescription.numItems..":")
                for key, subtable in pairs(mainTarget_Table) do
                    local name, itemNum = subtable[1], subtable[2]
                    reaper.ShowConsoleMsg("\n"..name.." - "..itemNum)
                end
            end

            if string.find(textArrayDescription.print,"others") then
                reaper.ShowConsoleMsg("\n\nFollowing "..textArrayDescription.target.." had items different than " .. textArrayDescription.mathCompare .. " to "..textArrayDescription.numItems..":")
                for key, subtable in pairs(otherTarget_Table) do
                    local name, itemNum = subtable[1], subtable[2]
                    reaper.ShowConsoleMsg("\n"..name.." - "..itemNum)
                end
            end
        end

        -- print to CSV
        if string.find(textArrayDescription.printWhere,"CSV") then
            if string.find(textArrayDescription.print,"matching") then
                joshnt.toCSV(mainTarget_Table,"Variation Verifier - Matching","Name of "..textArrayDescription.target..",Number items")
            end
            if string.find(textArrayDescription.print,"others") then
                joshnt.toCSV(otherTarget_Table,"Variation Verifier - Others","Name of "..textArrayDescription.target..",Number items")
            end
        end
    end

    -- action for regions
    if textArrayDescription.target == "All Regions" or textArrayDescription.target == "Sel. Regions" then
        local function colorRgns(table)
            local numMarkers, numRegions = reaper.CountProjectMarkers(0)
            for i = 0, numMarkers + numRegions - 1 do
                local retval, isRegion, pos, rgnend, name, markerIndex, color = reaper.EnumProjectMarkers3(0, i)
                if isRegion and joshnt.tableContainsKey(table,markerIndex) then
                    reaper.SetProjectMarker3(0, markerIndex, isRegion, pos, rgnend, name, colors.main | 0x1000000 )
                end
            end
        end
        local function deleteTime(table)
            local numMarkers, numRegions = reaper.CountProjectMarkers(0)
            for i = 0, numMarkers + numRegions - 1 do
                local retval, isRegion, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers( i )
                if isRegion and joshnt.tableContainsKey(table,markrgnindexnumber) then
                    reaper.GetSet_LoopTimeRange(true, false, pos, rgnend, false)
                    reaper.Main_OnCommand(40201,0) -- remove time
                end
            end
        end
        local function deleteRgns(table)
            local numMarkers, numRegions = reaper.CountProjectMarkers(0)
            for i = 0, numMarkers + numRegions - 1 do
                local retval, isRegion, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers( i )
                if isRegion and joshnt.tableContainsKey(table,markrgnindexnumber) then
                    reaper.DeleteProjectMarker(0, markrgnindexnumber, true)
                end
            end
        end
        
        -- main regions
        if textArrayDescription.actionMain == "Color" then
            colorRgns(mainTarget_Table)
        elseif textArrayDescription.actionMain == "Select" then
            local rgnAsValues = {}
            for key, _ in pairs(mainTarget_Table) do
                rgnAsValues[#rgnAsValues+1] = key
            end
            joshnt.setRegionSelectedByIndex(rgnAsValues,true)
        elseif textArrayDescription.actionMain == "Delete" then
            deleteRgns(mainTarget_Table)
        elseif textArrayDescription.actionMain == "Delete time" then
            deleteTime(mainTarget_Table)
        end

        -- other regions
        if textArrayDescription.actionsOther == "Color" then
            colorRgns(otherTarget_Table)
        elseif textArrayDescription.actionsOther == "Select" then
            local rgnAsValues = {}
            for key, _ in pairs(otherTarget_Table) do
                rgnAsValues[#rgnAsValues+1] = key
            end
            joshnt.setRegionSelectedByIndex(rgnAsValues,true)
        elseif textArrayDescription.actionsOther == "Delete" then
            deleteRgns(otherTarget_Table)
        elseif textArrayDescription.actionsOther == "Delete time" then
            deleteTime(otherTarget_Table)
        end
    end

    -- Delete Tracks, if selected
    if textArrayDescription.target == "All Tracks" or textArrayDescription.target == "Sel. Tracks" then
        if textArrayDescription.actionMain == "Delete" then -- delete correct tracks if user input
            for keyTrack, _ in pairs(mainTarget_Table) do
                reaper.DeleteTrack(keyTrack)
            end
        end
        if textArrayDescription.actionsOther == "Delete" then -- delete other tracks if user input
            for keyTrack, _ in pairs(otherTarget_Table) do
                reaper.DeleteTrack(keyTrack)
            end
        end
    end

    reaper.Undo_EndBlock("Variation Verifier", -1)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    
    
    GUI.quit = true
    saveOptions()
end

local function setActionColors(stringTarget)
    if colors[stringTarget] ~= nil then
        local r,g,b = reaper.ColorFromNative(colors[stringTarget])
        r = r/255
        g = g/255
        b = b/255
        GUI.colors[stringTarget] = {r,g,b,1}
    else GUI.colors[stringTarget] = GUI.colors["elm_fill"] 
    end
end

local function unfocusLists()
    for i = 1, #tabOrder do
        if tabOrder[i] ~= "numItems" then
            GUI.elms[tabOrder[i]].frame = false
        end
    end 
    tabPosition = 0
end

local function redraw_ActionOthers()
    local prevVal = GUI.Val("actionsOther") or 1

    GUI.New("actionsOther", "Radio", {
        z = 11,
        x = 734.0,
        y = 65.0,
        w = 110,
        h = 135,
        caption = "Action for others",
        optarray = actionOptArray,
        dir = "v",
        font_a = 3,
        font_b = 2,
        col_txt = "txt",
        col_fill = "other",
        bg = "wnd_bg",
        frame = false,
        shadow = true,
        swap = false,
        opt_size = 20
    })

    GUI.Val("actionsOther",prevVal)
    GUI.elms.actionsOther.tooltip = "Click on 'Color' to open Color selector\nUse 'Do nothing' if you only want to print the number of items"

    function GUI.elms.actionsOther:onmouseup()
        GUI.Radio.onmouseup(self)
        local prevColor = colors.other
        if GUI.Val("actionsOther") == 1 then
            local retval, newColor = reaper.GR_SelectColor(nil)
            if retval then
                colors.other = newColor
            else
                GUI.Val("actionsOther",5)
                colors.other = nil
            end
        else
            colors.other = nil
        end

        if colors.other ~= prevColor then
            setActionColors("other")
            redrawAction = "other"
        end

        updateTextArrayDescription_Full()
        unfocusLists()
    end
end

local function redraw_ActionMain()
    local prevVal = GUI.Val("actionMain") or 1

    GUI.New("actionMain", "Radio", {
        z = 11,
        x = 330,
        y = 64,
        w = 110,
        h = 135,
        caption = "Action to perform",
        optarray = actionOptArray,
        dir = "v",
        font_a = 3,
        font_b = 2,
        col_txt = "txt",
        col_fill = "main",
        bg = "wnd_bg",
        frame = false,
        shadow = true,
        swap = false,
        opt_size = 20
    })

    GUI.Val("actionMain",prevVal)
    GUI.elms.actionMain.tooltip = "Click on 'Color' to open Color selector\nUse 'Do nothing' if you only want to print the number of items"

    function GUI.elms.actionMain:onmouseup()
        GUI.Radio.onmouseup(self)
        local prevColor = colors.main
        if GUI.Val("actionMain") == 1 then
            local retval, newColor = reaper.GR_SelectColor(nil)
            if retval then
                colors.main = newColor
            else
                GUI.Val("actionMain",5)
                colors.main = nil
            end
        else
            colors.main = nil
        end

        if colors.main ~= prevColor then
            setActionColors("main")
            redrawAction = "main"
        end

        updateTextArrayDescription_Full()
        unfocusLists()
    end
end

local function updateActions()
    local prevOptArray = GUI.elms.actionMain.optarray
    local targetVal = GUI.Val("target")
    local newOptArray = {}
    if targetVal == 2 or targetVal == 4 then -- "All Regions" or "Sel. Regions"
        newOptArray = {"Color", "Select", "Delete", "Delete time", "Do nothing"}
        
    else
        newOptArray = {"Color", "Select", "Delete", "Hide", "Do nothing"}
    end
    
    if prevOptArray[4] ~= newOptArray[4] then
        actionOptArray = newOptArray
        redraw_ActionMain()
        redraw_ActionOthers()
    end
end

local function redrawAll()
    redraw_ActionMain()
    redraw_ActionOthers()
    
    GUI.New("Run", "Button", {
        z = 11,
        x = 17.0,
        y = 250.0,
        w = 100,
        h = 30,
        caption = "Go!",
        font = 2,
        col_txt = "txt",
        col_fill = "elm_frame",
        func = run_VariationVerifier
    })

    GUI.New("target", "Radio", {
        z = 11,
        x = 16,
        y = 64,
        w = 120,
        h = 112,
        caption = "What to check",
        optarray = targetOptArray,
        dir = "v",
        font_a = 3,
        font_b = 2,
        col_txt = "txt",
        col_fill = "elm_fill",
        bg = "wnd_bg",
        frame = false,
        shadow = true,
        swap = false,
        opt_size = 20
    })

    GUI.New("countWhat", "Radio", {
        z = 11,
        x = 452.0,
        y = 64.0,
        w = 200,
        h = 65,
        caption = "What to count",
        optarray = {"Singular media items", "Overlapping item groups"},
        dir = "v",
        font_a = 3,
        font_b = 2,
        col_txt = "txt",
        col_fill = "elm_fill",
        bg = "wnd_bg",
        frame = false,
        shadow = true,
        swap = false,
        opt_size = 20
    })

    GUI.New("VariationVerifier", "Label", {
        z = 11,
        x = 10,
        y = 10,
        caption = "Variation Verifier",
        font = 1,
        color = "txt",
        bg = "wnd_bg",
        shadow = false
    })

    GUI.New("numItems", "Textbox", {
        z = 11,
        x = 220.0,
        y = 76.0,
        w = 96,
        h = 20,
        caption = "Number of items",
        cap_pos = "top",
        font_a = 3,
        font_b = "monospace",
        color = "txt",
        bg = "wnd_bg",
        shadow = true,
        pad = 4,
        undo_limit = 20
    })

    GUI.New("description", "Label", {
        z = 11,
        x = 18.0,
        y = 320.0,
        caption = "",
        font = 3,
        color = "txt",
        bg = "wnd_bg",
        shadow = false
    })

    GUI.New("Frame1", "Frame", {
        z = 11,
        x = 689.0,
        y = 60.0,
        w = 2,
        h = 145,
        shadow = false,
        fill = false,
        color = "green",
        bg = "green",
        round = 0,
        text = "",
        txt_indent = 0,
        txt_pad = 0,
        pad = 4,
        font = 4,
        col_txt = "txt"
    })

    GUI.New("mathCompare", "Radio", {
        z = 11,
        x = 147,
        y = 64,
        w = 60,
        h = 112,
        caption = "compare",
        optarray = {"=", "<", ">", "!="},
        dir = "v",
        font_a = 3,
        font_b = 2,
        col_txt = "txt",
        col_fill = "elm_fill",
        bg = "wnd_bg",
        frame = false,
        shadow = true,
        swap = false,
        opt_size = 20
    })

    GUI.New("print", "Checklist", {
        z = 11,
        x = 150.0,
        y = 236.0,
        w = 120,
        h = 65,
        caption = "Print",
        optarray = {"of matching", "of others"},
        dir = "v",
        pad = 4,
        font_a = 3,
        font_b = 3,
        col_txt = "txt",
        col_fill = "elm_fill",
        bg = "wnd_bg",
        frame = false,
        shadow = true,
        swap = nil,
        opt_size = 20
    })

    GUI.New("printwhat", "Checklist", {
        z = 11,
        x = 290.0,
        y = 236.0,
        w = 100,
        h = 65,
        caption = "what",
        optarray = {"names", "item count"},
        dir = "v",
        pad = 4,
        font_a = 3,
        font_b = 3,
        col_txt = "txt",
        col_fill = "elm_fill",
        bg = "wnd_bg",
        frame = false,
        shadow = true,
        swap = nil,
        opt_size = 20
    })

    GUI.New("printWhere", "Checklist", {
        z = 11,
        x = 410.0,
        y = 236.0,
        w = 100,
        h = 65,
        caption = "to",
        optarray = {"console", "CSV-File"},
        dir = "v",
        pad = 4,
        font_a = 3,
        font_b = 3,
        col_txt = "txt",
        col_fill = "elm_fill",
        bg = "wnd_bg",
        frame = false,
        shadow = true,
        swap = nil,
        opt_size = 20
    })

    function GUI.elms.target:onmouseup()
        GUI.Radio.onmouseup(self)
        updateActions()
        updateTextArrayDescription_Full()
        unfocusLists()
    end

    function GUI.elms.countWhat:onmouseup()
        GUI.Radio.onmouseup(self)
        updateTextArrayDescription_Full()
        unfocusLists()
    end

    GUI.elms.countWhat.tooltip = "'Single items' - number of individual items\n'Overlapping items' - overlapping items count as one"

    function GUI.elms.mathCompare:onmouseup()
        GUI.Radio.onmouseup(self)
        updateTextArrayDescription_Full()
        unfocusLists()
    end

    function GUI.elms.numItems:lostfocus()
        GUI.Textbox.lostfocus(self)
        updateTextArrayDescription_Full()
        unfocusLists()
    end

    function GUI.elms.print:onmouseup()
        GUI.Checklist.onmouseup(self)
        updateTextArrayDescription_Full()
        unfocusLists()
    end

    function GUI.elms.printwhat:onmouseup()
        GUI.Checklist.onmouseup(self)
        updateTextArrayDescription_Full()
        unfocusLists()
    end

    function GUI.elms.printWhere:onmouseup()
        GUI.Checklist.onmouseup(self)
        updateTextArrayDescription_Full()
        unfocusLists()
    end

    GUI.elms.VariationVerifier.tooltip = "Filter and/ or print track/ region names depending on the number of items on them.\nPress 'TAB' to cycle through the options, 'UP' or 'DOWN' to select different options and 'RETURN' to execute the script."

end

local function Loop()
    if redrawAction ~= nil then
        if redrawAction == "main" then redraw_ActionMain()
        elseif redrawAction == "other" then redraw_ActionOthers()
        else redraw_ActionMain() redraw_ActionOthers()
        end
        redrawAction = nil
    end

    if GUI.char == 9.0 and keyPress == false then -- tab
        if tabPosition ~= 0 then
            -- visually unfocus previous
            if tabOrder[tabPosition] ~= "numItems" then
                local temp = GUI.elms[tabOrder[tabPosition]]
                temp.frame= false
            else
                GUI.elms.numItems.focus = false
            end
        end

        if GUI.mouse.cap == 8 then
            tabPosition = ((tabPosition-2) % #tabOrder) +1
        else
            tabPosition = (tabPosition % #tabOrder) +1
        end
        
        -- visually focus current
        if tabOrder[tabPosition] ~= "numItems" then
            GUI.elms[tabOrder[tabPosition]].frame= true
        else
            GUI.elms.numItems.focus = true
        end

        GUI.redraw_z[11] = true

        keyPress = true
    elseif GUI.char == 0.0 and keyPress == true then
        keyPress = false
    elseif GUI.elms.numItems.focus == true then return -- if text input box is focused, dont check further
    elseif GUI.char == 13.0 and keyPress == false then -- enter
        run_VariationVerifier()
        keyPress = true
    elseif GUI.char == 30064 and keyPress == false and tabPosition ~= 0 then -- up arrow
        local selVal = GUI.Val(tabOrder[tabPosition])
        selVal = ((selVal-2) % #GUI.elms[tabOrder[tabPosition]].optarray) +1
        GUI.Val(tabOrder[tabPosition],selVal)
        updateTextArrayDescription_Full()
        keyPress = true
    elseif GUI.char == 1685026670 and keyPress == false and tabPosition ~= 0 then -- down arrow
        local selVal = GUI.Val(tabOrder[tabPosition])
        selVal = (selVal % #GUI.elms[tabOrder[tabPosition]].optarray) +1
        GUI.Val(tabOrder[tabPosition],selVal)
        updateTextArrayDescription_Full()
        keyPress = true
    end

end



reaper.set_action_options(1) -- on rerun, terminate script
GUI.Init()
setActionColors("other")
setActionColors("main")
redrawAll()
if checkOptionDefaults() == true then 
    setActionColors("main")
    setActionColors("other")
    redrawAction = "all"
end

updateActions()
updateTextArrayDescription_Full()
updateActions()
GUI.func = Loop
GUI.freq = 0
GUI.onresize = redrawAll
GUI.exit = saveOptions
GUI.Main()


-- TODO
--[[
- copy functions from old variation verifier script and adjust variables
- add region support/ actual region action from table of regions
]]--



