-- @noindex
-- Script uses Lokasenna GUI Library for GUI Elements

local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please install 'Lokasenna's GUI library v2 for Lua', available on ReaPack, then run the 'Set Lokasenna_GUI v2 library path.lua' script in your Action List.", "Whoops!", 0)
    return
else
    loadfile(lib_path .. "Core.lua")()
end

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

-- GUI vals
local yOffset = 64
local yIncr = 50
local numPrios = 10
local options = {"Reverse", "FX", ">Item-Name", "is exactly", "contains", "is not", "<is not containing", ">Pitch/Rate", "Pitch", "<Rate", ">Volume/Gain", "Volume", "Gain", "", "<Combined", "", "Nothing"}
local optionsForMain = {"reverse","FX","","is exactly","contains","is not","is not containing","","pitch","rate","","volume","gain","","combined"}
GUI.colors["neutralFill"] = {140,140,140,255}

-- content values; all as directly rewriteable to value
local selectedValues = {
    selProperty = {},
    selColor1 = {},
    selColor2 = {},
    selValRange = {},
    selGradToggle = {},
    selTextInput = {}
}
local verifiedVals = false
local redrawOptions = 0

GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Textbox.lua")()
GUI.req("Classes/Class - Menubox.lua")()
GUI.req("Classes/Class - Options.lua")()
GUI.req("Classes/Class - Label.lua")()
GUI.req("Classes/Class - Slider.lua")()
GUI.req("Classes/Class - Frame.lua")()
-- If any of the requested libraries weren't found, abort the script.
if missing_lib then return 0 end

local function checkOptionDefaults()
    if reaper.HasExtState("joshnt_Auto-Color_items", "priorityOrder") then
        selectedValues.selProperty = joshnt.splitStringToTable(reaper.GetExtState("joshnt_Auto-Color_items", "priorityOrder"))
        selectedValues.selColor1 = joshnt.splitStringToTable(reaper.GetExtState("joshnt_Auto-Color_items", "selColor1"))
        selectedValues.selColor2 = joshnt.splitStringToTable(reaper.GetExtState("joshnt_Auto-Color_items", "selColor2"))
        selectedValues.selValRange = joshnt.splitStringToTable(reaper.GetExtState("joshnt_Auto-Color_items", "selValRange"))
        selectedValues.selGradToggle = joshnt.splitStringToTable(reaper.GetExtState("joshnt_Auto-Color_items", "selGradToggle"))
        selectedValues.selTextInput = joshnt.splitStringToTable(reaper.GetExtState("joshnt_Auto-Color_items", "selTextInput"))
    end
end

local function saveOptions()
    reaper.SetExtState("joshnt_Auto-Color_items", "priorityOrder", joshnt.tableToCSVString(selectedValues.selProperty), true)
    reaper.SetExtState("joshnt_Auto-Color_items", "selColor1", joshnt.tableToCSVString(selectedValues.selColor1), true)
    reaper.SetExtState("joshnt_Auto-Color_items", "selColor2", joshnt.tableToCSVString(selectedValues.selColor2), true)
    reaper.SetExtState("joshnt_Auto-Color_items", "selValRange", joshnt.tableToCSVString(selectedValues.selValRange), true)
    reaper.SetExtState("joshnt_Auto-Color_items", "selGradToggle", joshnt.tableToCSVString(selectedValues.selGradToggle), true)
    reaper.SetExtState("joshnt_Auto-Color_items", "selTextInput", joshnt.tableToCSVString(selectedValues.selTextInput), true)
end




local function VerifyAndRun_Button()
    local counterInAutoColor = 1 -- count index in autocolor indepently from i for potential nothing between others
    local nameIndex = 1
    for i = 1, numPrios do
        local curSelProperty = selectedValues.selProperty[i]
        if curSelProperty and curSelProperty ~= 17 then
            if curSelProperty >= 4 and curSelProperty <= 7 then
                joshnt_autoColor.priorityOrderArray[counterInAutoColor] = "name"..nameIndex
                joshnt_autoColor.names[nameIndex] = {}
                joshnt_autoColor.names[nameIndex][1] = selectedValues.selTextInput[i]
                joshnt_autoColor.names[nameIndex][2] = optionsForMain[curSelProperty]
                nameIndex = nameIndex +1
            else
                joshnt_autoColor.priorityOrderArray[counterInAutoColor] = optionsForMain[curSelProperty]
            end

            if selectedValues.selGradToggle[i] ~= true or GUI.elms[i.."_GradientToggle"]["z"] == 5 then
                joshnt_autoColor.colors[joshnt_autoColor.priorityOrderArray[counterInAutoColor]] = selectedValues.selColor1[i]
                joshnt_autoColor.valueRanges[joshnt_autoColor.priorityOrderArray[counterInAutoColor]] = nil
            else
                joshnt_autoColor.colors[joshnt_autoColor.priorityOrderArray[counterInAutoColor]] = {selectedValues.selColor1[i],selectedValues.selColor2[i]}
                joshnt_autoColor.valueRanges[joshnt_autoColor.priorityOrderArray[counterInAutoColor]] = selectedValues.selValRange[i]
            end

            counterInAutoColor = counterInAutoColor + 1
        end
    end
    
    local retval = joshnt_autoColor.checkDefaultsSet()
    verifiedVals = retval
    if verifiedVals == true then
        GUI.elms.needToSave:fade(5, 7, 5, -0.2)
        GUI.elms.unverified:fade(5, 5, 7, 0.2)
    else
        GUI.elms.unverified:fade(5, 7, 5, -0.2)
        GUI.elms.needToSave:fade(5, 5, 7, 0.2)
    end
end

local function compareSafedVal_CurVal_SelBox(intPriority)
    return GUI.Val(intPriority.."_Select") == selectedValues.selProperty[intPriority]
end

local function safeVal_CurVal_SelBox(intPriority)
    selectedValues.selProperty[intPriority] = GUI.Val(intPriority.."_Select")
end


local function refreshVisibleElementsForPriority(intPriority, boolRefreshSlider_Input)
    verifiedVals = false
    
    local selVal = selectedValues.selProperty[intPriority] or 17

    local gradientToggle = GUI.elms[intPriority.."_GradientToggle"]
    local color_GradLow = GUI.elms[intPriority.."_Color_GradLow"]
    local color_GradHigh = GUI.elms[intPriority.."_Color_GradHigh"]
    local valRange = GUI.elms[intPriority.."_ValRange"]
    local color_Normal = GUI.elms[intPriority.."_Color_Normal"]
    local textbox = GUI.elms[intPriority.."_Textbox"]
    if selVal <= 2 then -- check if reverse or fx
        gradientToggle.z = 5
        GUI.Val(intPriority.."_GradientToggle",false)
        color_GradLow.z = 5
        color_GradHigh.z = 5
        valRange.z = 5

        textbox.z = 5

        color_Normal.z = 20+intPriority
    elseif selVal >= 4 and selVal <= 7 then -- check if name input
        gradientToggle.z = 5
        GUI.Val(intPriority.."_GradientToggle",false)
        color_GradLow.z = 5
        color_GradHigh.z = 5
        valRange.z = 5

        textbox.z = 11

        color_Normal.z = 20+intPriority
    elseif selVal >= 9 and selVal <= 15 then -- check if volume/ gain/rate/ pitch
        gradientToggle.z = 11
        local gradientToggleVal = GUI.Val(intPriority.."_GradientToggle")
        if gradientToggleVal == false or gradientToggleVal == nil then 
            color_GradLow.z = 5
            color_GradHigh.z = 5
            valRange.z = 5
            color_Normal.z = 20+intPriority
        else
            color_GradLow.z = 20+intPriority
            color_GradHigh.z = 20+intPriority
            valRange.z = 11

            -- change slider boundarys depending on focus
            if boolRefreshSlider_Input ~= false then
                if selVal == 9 then -- pitch
                    valRange.min = -24
                    valRange.max = 24
                    valRange.inc = 1
                    valRange.defaults = {12,36}
                    valRange.tooltip = "Lower and upper bound for gradient\n(Values in semitones)"
                elseif selVal == 10 then -- rate
                    valRange.min = 0.25
                    valRange.max = 4
                    valRange.inc = 0.05
                    valRange.defaults = {5,35}
                    valRange.tooltip = "Lower and upper bound for gradient\n(Playback-Rate in %)"
                else -- volume in any form
                    valRange.min = -36
                    valRange.max = 36
                    valRange.inc = 1
                    valRange.defaults = {24,48}
                    valRange.tooltip = "Lower and upper bound for gradient\n(Values in dB)"
                end
                valRange:init_handles()
            end

            color_Normal.z = 5
        end

        textbox.z = 5

    else -- nothing is selected
        gradientToggle.z = 5
        GUI.Val(intPriority.."_GradientToggle",false)
        color_GradLow.z = 5
        color_GradHigh.z = 5
        valRange.z = 5

        textbox.z = 5

        color_Normal.z = 5
    end

    GUI.redraw_z[0] = true
end

local function refreshAllVisibleElements()
    for i = 1, numPrios do
        refreshVisibleElementsForPriority(i)
    end
end

-- to avoid double selected properties
local function refreshPrioritySelectBoxes()
    local nextOptArray = {}
    local nameConditionCounter = 0
    joshnt.copyTableValues(options, nextOptArray)

    -- ! = selected, # = blocked from selection
    for i = 1, numPrios do
        local selVal = GUI.Val(i.."_Select")
        local currSelBox = GUI.elms[i.."_Select"]
        local currOptArray = {}
        joshnt.copyTableValues(nextOptArray, currOptArray)
        
        --[[
        -- TODO - optional
        -- setting checkmark to selected folder doesnt work?? - weird offset of value
        if (selVal >= 4 and selVal <= 7) then -- name
            --currOptArray[3] = "!"..options[3]
        elseif (selVal == 9 or selVal == 10) then -- pitch/ rate
            --currOptArray[8] = "!"..options[8]
            currOptArray[8] = currOptArray[8]
        elseif (selVal >= 12 and selVal <= 15) then -- volume/ gain
            currOptArray[11] = "!"..options[11]
        else 
            currOptArray[selVal] = "!"..options[selVal]
        end--]]

        currSelBox.optarray = currOptArray

        if selVal >= 4 and selVal <= 7 then -- check if name input
            nameConditionCounter = nameConditionCounter +1
            if nameConditionCounter > 5 then
                GUI.Val(i.."_Select", 17)
                refreshVisibleElementsForPriority(i)
                joshnt.TooltipAtMouse("Max. Number of 5 Conditions with names reached.")
            end
        end

        
        for j = i+1, numPrios do
            local selValOther = GUI.Val(j.."_Select")
            if selVal == selValOther and (selVal < 4 or selVal > 7) and selVal ~= 17 or (selVal == 15 and (selValOther == 12 or selValOther == 13)) or (selVal == 12 and selValOther == 15) or (selVal == 13 and selValOther == 15) then -- exclude text & Nothing; block gain volume and combined crossovers
                GUI.Val(j.."_Select", 17)
                refreshVisibleElementsForPriority(j)
            end
        end

        if selVal ~= 17  then
            nextOptArray[selVal] = "#"..options[selVal]
            if selVal == 15 then
                nextOptArray[12] = "#"..options[12]
                nextOptArray[13] = "#"..options[13]
            elseif selVal == 12 or selVal == 13 then
                nextOptArray[15] = "#"..options[15]
            end
        end 
    end

    GUI.redraw_z[0] = true
end

local function setOptionColors(intPriority)
    if selectedValues.selColor1[intPriority] ~= nil and selectedValues.selColor1[intPriority] ~= "brighter" and selectedValues.selColor1[intPriority] ~= "darker" then 
        local r,g,b = reaper.ColorFromNative(selectedValues.selColor1[intPriority])
        r = r/255
        g = g/255
        b = b/255
        GUI.colors[intPriority.."_color1"] = {r,g,b,1}
    else GUI.colors[intPriority.."_color1"] = GUI.colors["neutralFill"] 
    end
    if selectedValues.selColor2[intPriority] ~= nil and selectedValues.selColor2[intPriority] ~= "brighter" and selectedValues.selColor2[intPriority] ~= "darker" then 
        local r,g,b = reaper.ColorFromNative(selectedValues.selColor2[intPriority])
        r = r/255
        g = g/255
        b = b/255
        GUI.colors[intPriority.."_color2"] = {r,g,b,1}
    else GUI.colors[intPriority.."_color2"] = GUI.colors["neutralFill"] end
end

local function drawOptions(intPriority)
    local valueStore = 1
    if GUI.elms[intPriority.."_Color_Normal"] ~= nil then
        valueStore = GUI.Val(intPriority.."_Color_Normal")
    end

    GUI.New(intPriority.."_Color_GradLow", "Radio", {
        z = 20+intPriority,
        x = 240,
        y = yOffset + ((intPriority-1)*yIncr),
        w = 30,
        h = 30,
        caption = "",
        optarray = {""},
        dir = "h",
        font_a = 2,
        font_b = 3,
        col_txt = "txt",
        col_fill = intPriority.."_color1",
        bg = "wnd_bg",
        frame = false,
        shadow = true,
        swap = nil,
        opt_size = 20
    })
    
    GUI.New(intPriority.."_Color_GradHigh", "Radio", {
        z = 20+intPriority,
        x = 288,
        y = yOffset + ((intPriority-1)*yIncr),
        w = 30,
        h = 30,
        caption = "",
        optarray = {""},
        dir = "h",
        font_a = 2,
        font_b = 3,
        col_txt = "txt",
        col_fill = intPriority.."_color2",
        bg = "wnd_bg",
        frame = false,
        shadow = true,
        swap = nil,
        opt_size = 20
    })

    GUI.New(intPriority.."_Color_Normal", "Radio", {
        z = 20+intPriority,
        x = 240,
        y = yOffset + ((intPriority-1)*yIncr),
        w = 80,
        h = 30,
        caption = "",
        optarray = {"", "", ""},
        dir = "h",
        font_a = 2,
        font_b = 3,
        col_txt = "txt",
        col_fill = intPriority.."_color1",
        bg = "wnd_bg",
        frame = false,
        shadow = true,
        swap = nil,
        opt_size = 20
    })
    GUI.Val(intPriority.."_Color_Normal",valueStore)

    -- color option update
    for k = 1, 3 do 
        local elmNameAppend = ""
        if k == 1 then 
            elmNameAppend = "_Color_Normal"
        elseif k == 2 then
            elmNameAppend = "_Color_GradLow"
        else
            elmNameAppend = "_Color_GradHigh"
        end
        local curColorOption = GUI.elms[intPriority..elmNameAppend]

        function curColorOption:onmouseup() 
            GUI.Radio.onmouseup(self)
            local retval, newColor;

            -- check if brighter or darker is clicked
            if k == 1 and GUI.Val(intPriority..elmNameAppend) > 1 then 
                if GUI.Val(intPriority..elmNameAppend) == 2 then
                    selectedValues.selColor1[intPriority] = "brighter"
                else
                    selectedValues.selColor1[intPriority] = "darker"
                end
            else -- else open colorwheel to select
                retval, newColor = reaper.GR_SelectColor(nil)
                if retval and retval ~= 0 then
                    if k < 3 then     
                        selectedValues.selColor1[intPriority] = newColor
                    else
                        selectedValues.selColor2[intPriority] = newColor
                    end
                else
                    if k < 3 then     
                        selectedValues.selColor1[intPriority] = nil
                    else
                        selectedValues.selColor2[intPriority] = nil
                    end
                end
            end 
            setOptionColors(intPriority)
            redrawOptions = intPriority
            verifiedVals = false
        end

        function curColorOption:onmousedown() GUI.Radio.onmousedown(self) end
        function curColorOption:ondrag() end
        function curColorOption:onwheel() end
        function curColorOption:ondoubleclick()  end

        function curColorOption:draw()  
            GUI.Radio.draw(self)                 
            verifiedVals = false
        end

        if k == 1 then
            curColorOption.tooltip = "Custom Color/ Brighter/ Darker\nClick first box to open color wheel"
        elseif k == 2 then
            curColorOption.tooltip = "Custom Color (low boundary) for gradient\nClick to open color wheel"
        else
            curColorOption.tooltip = "Custom Color (high boundary) for gradient\nClick to open color wheel"
        end
    end 
end

local function SaveAndExit_Button()
    if verifiedVals == true then
        GUI.quit = true
        saveOptions()
    else
        reaper.MB("Please press 'Verify new Settings' to check if all your conditions work.","Auto-Color items - Error",0)
    end
end

local function movePrioTo(origPosition, newPrio)    
    if origPosition == newPrio then return end
    -- Store the value from the new prio
    for subtablesKeys, valueTables in pairs(selectedValues) do
        -- Shift the values
        if origPosition > newPrio then
            local temp = valueTables[origPosition]
            for i = origPosition, newPrio+1, -1 do
                valueTables[i] = valueTables[i-1]
            end
            valueTables[newPrio] = temp
        else
            local temp = valueTables[origPosition]
            for i = origPosition, newPrio-1 do
                valueTables[i] = valueTables[i+1]
            end
            valueTables[newPrio] = temp
        end
    end
end

local function redrawAll() 

    GUI.New("SaveAndExit", "Button", {
        z = 1,
        x = 12,
        y = 12,
        w = 90,
        h = 24,
        caption = "Save & Exit",
        font = 2,
        col_txt = "txt",
        col_fill = "elm_frame",
        func = SaveAndExit_Button
    })

    GUI.New("VerifyAndRun", "Button", {
        z = 1,
        x = 120,
        y = 12,
        w = 130,
        h = 24,
        caption = "Verify new Settings",
        font = 4,
        col_txt = "txt",
        col_fill = "elm_frame",
        func = VerifyAndRun_Button
    })

    GUI.New("unverified", "Label", {
    z = 7,
    x = 270,
    y = 17,
    caption = "unverified changes - execution paused",
    font = 4,
    color = "txt",
    bg = "wnd_bg",
    shadow = false
    })

    GUI.New("needToSave", "Label", {
        z = 5,
        x = 270,
        y = 17,
        caption = "Preview - Settings not saved",
        font = 4,
        color = "txt",
        bg = "wnd_bg",
        shadow = false
    })

    --[[GUI.New("Gradient", "Label", {
        z = 11,
        x = 160,
        y = 32,
        caption = "Gradient",
        font = 2,
        color = "txt",
        bg = "wnd_bg",
        shadow = false
    }) --]]

    local nameIndex = 1

    for i = 1, numPrios do
        
        setOptionColors(i)

        drawOptions(i)
        
        GUI.New(i.."_Textbox", "Textbox", {
            z = 11,
            x = 358.0,
            y = yOffset + ((i-1)*yIncr) + 6,
            w = 96,
            h = 20,
            caption = "",
            cap_pos = "left",
            font_a = 3,
            font_b = "monospace",
            color = "txt",
            bg = "wnd_bg",
            shadow = true,
            pad = 4,
            undo_limit = 20
        })

        GUI.New(i.."_GradientToggle", "Checklist", {
            z = 11,
            x = 187,
            y = yOffset + ((i-1)*yIncr),
            w = 30,
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
            shadow = false,
            swap = nil,
            opt_size = 20
        })
        
        GUI.New(i.."_ValRange", "Slider", {
            z = 11,
            x = 357.0,
            y = yOffset + ((i-1)*yIncr) + 10,
            w = 96,
            caption = "",
            min = 0,
            max = 10,
            defaults = {4,6},
            inc = 1,
            dir = "h",
            font_a = 3,
            font_b = 4,
            col_txt = "txt",
            col_fill = "elm_fill",
            bg = "wnd_bg",
            show_handles = true,
            show_values = true,
            cap_x = 0,
            cap_y = 0
        })
        
        GUI.New(i.."_Select", "Menubox", {
            z = 1,
            x = 12.0,
            y = yOffset + ((i-1)*yIncr) + 3,
            w = 140,
            h = 24,
            caption = "",
            optarray = options,
            retval = 1.0,
            font_a = 3,
            font_b = 2,
            col_txt = "txt",
            col_cap = "txt",
            bg = "wnd_bg",
            pad = 4,
            noarrow = false,
            align = 0
        })

        if i ~= 1 then 
            GUI.New(i.."SeperatorLine", "Frame", {
                z = 30,
                x = 12.0,
                y = yOffset + ((i-1)*yIncr) - 10,
                w = 510,
                h = 1,
                shadow = false,
                fill = false,
                color = "gray",
                bg = "gray",
                round = 0,
                text = "",
                txt_indent = 0,
                txt_pad = 0,
                pad = 4,
                font = 4,
                col_txt = "txt"
            })
        end

        GUI.New(i.."_priorityLabel", "Label", {
        z = 11,
        x = 490,
        y = yOffset + ((i-1)*yIncr) + 6,
        caption = i,
        font = 4,
        color = "txt",
        bg = "wnd_bg",
        shadow = false
        })

        -- load values
        if selectedValues.selProperty[i] ~= nil then
            GUI.Val(i.."_Select", selectedValues.selProperty[i])

            if selectedValues.selTextInput[1] ~= nil and selectedValues.selProperty[i] >= 4 and selectedValues.selProperty[i] <= 7 then
                GUI.Val(i.."_Textbox", selectedValues.selTextInput[nameIndex])
                nameIndex = nameIndex +1
            end
        else
            GUI.Val(i.."_Select", 17)
        end


        -- Functions on User input
        local curSelBox = GUI.elms[i.."_Select"]
        -- select box value update on user input
        function curSelBox:onmousedown()
            GUI.Menubox.onmousedown(self)  
            if not compareSafedVal_CurVal_SelBox(i) then 
                safeVal_CurVal_SelBox(i) 
                refreshVisibleElementsForPriority(i)
                refreshPrioritySelectBoxes()
            end
        end

        function curSelBox:onmouseup()
            GUI.Menubox.onmouseup(self)        
            if not compareSafedVal_CurVal_SelBox(i) then  
                safeVal_CurVal_SelBox(i)
                refreshVisibleElementsForPriority(i)
                refreshPrioritySelectBoxes()
            end
        end


        function curSelBox:onr_drag() end
        function curSelBox:ondrag() end
        function curSelBox:onwheel() end
        function curSelBox:ondoubleclick() end
        function curSelBox:onmouser_up()
            local newPrio = math.floor((GUI.mouse.y - yOffset+9)/yIncr) +1
            if newPrio < 1 then
                newPrio = 1
            elseif newPrio > 10 then
                newPrio = 10
            end

            movePrioTo(i,newPrio)

            redrawAll()
            refreshPrioritySelectBoxes()
            refreshAllVisibleElements()
        end
        curSelBox.tooltip = "Click to open menu with options\nRight drag to move property up or down in priority list"

        local curPrioLabel = GUI.elms[i.."_priorityLabel"]
        function curPrioLabel:onmouser_up()
            local newPrio = math.floor((GUI.mouse.y - yOffset+9)/yIncr) +1
            if newPrio < 1 then
                newPrio = 1
            elseif newPrio > 10 then
                newPrio = 10
            end

            movePrioTo(i,newPrio)

            redrawAll()
            refreshPrioritySelectBoxes()
            refreshAllVisibleElements()
        end
        curPrioLabel.tooltip = "Displays Priority order for properties\nRight drag to move property up or down in priority list"

        -- value slider user input
        local curValRangeSlider = GUI.elms[i.."_ValRange"]
        function curValRangeSlider:onmousedown()
            GUI.Slider.onmousedown(self)        
            selectedValues.selValRange[i] = GUI.Val(i.."_ValRange")
            verifiedVals = false
        end
        function curValRangeSlider:onmouseup()
            GUI.Slider.onmouseup(self)        
            selectedValues.selValRange[i] = GUI.Val(i.."_ValRange")
            verifiedVals = false
        end

        function curValRangeSlider:ondrag()
            GUI.Slider.ondrag(self)
            selectedValues.selValRange[i] = GUI.Val(i.."_ValRange")
            verifiedVals = false
        end
        function curValRangeSlider:onwheel()
            GUI.Slider.onwheel(self)
            selectedValues.selValRange[i] = GUI.Val(i.."_ValRange")
            verifiedVals = false
        end
        function curValRangeSlider:ondoubleclick()
            GUI.Slider.ondoubleclick(self)
            selectedValues.selValRange[i] = GUI.Val(i.."_ValRange")
            verifiedVals = false
        end
        function curValRangeSlider:draw()
            GUI.Slider.draw(self)
            if self.z == 5 then
                selectedValues.selValRange[i] = nil
            else
                selectedValues.selValRange[i] = GUI.Val(i.."_ValRange")
            end
            verifiedVals = false
        end
        curValRangeSlider.tooltip = "Set value boundarys for gradient for current property"

        local curToggleBox = GUI.elms[i.."_GradientToggle"]
        function curToggleBox:onmousedown()
            GUI.Checklist.onmousedown(self)        
            refreshVisibleElementsForPriority(i)
            selectedValues.selGradToggle[i] = GUI.Val(i.."_GradientToggle")
            verifiedVals = false
        end
        function curToggleBox:onmouseup()
            GUI.Checklist.onmouseup(self)        
            refreshVisibleElementsForPriority(i)
            selectedValues.selGradToggle[i] = GUI.Val(i.."_GradientToggle")
            verifiedVals = false
        end
        curToggleBox.tooltip = "Toggles Gradient for selected property"

        local curTextBox = GUI.elms[i.."_Textbox"]
        function curTextBox:lostfocus()
            GUI.Textbox.lostfocus(self)        
            selectedValues.selTextInput[i] = GUI.Val(i.."_Textbox")
            verifiedVals = false
        end
        curTextBox.tooltip = "Text input which should match/ not be included in item name\ne.g. 'glued'"
        
    end

    GUI.elms_hide[5] = true

    for i = 1, numPrios do
        refreshVisibleElementsForPriority(i)
    end
end

local function Loop()
    -- show label or run function
    if verifiedVals == true then
        joshnt_autoColor.selItems()
    else
        if GUI.elms.unverified.z ~= 7 then
            GUI.elms.unverified:fade(5, 7, 5, -0.2)
            GUI.elms.needToSave:fade(5, 5, 7, 0.2)
        end
    end

    -- redraw options with new color
    if redrawOptions ~= 0 then
        drawOptions(redrawOptions)
        refreshVisibleElementsForPriority(redrawOptions,false)
        redrawOptions = 0
    end
end

local function init()
    redrawAll()
    refreshPrioritySelectBoxes()
    refreshAllVisibleElements()
end


GUI.name = "Auto-Color items"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 535, 560
GUI.anchor, GUI.corner = "screen", "L"

GUI.Init()
checkOptionDefaults()
init()
GUI.func = Loop
GUI.freq = 0
GUI.onresize = init
GUI.escape_bypass = true
GUI.Main()


