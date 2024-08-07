-- @noindex

-- load 'externals'
-- Load Unique Regions Core script
--[[
local joshnt_UniqueRegions_Core = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/ITEMS/joshnt_Auto-Color items/joshnt_Unique Regions for overlapping items - CORE.lua'
if reaper.file_exists( joshnt_UniqueRegions_Core ) then 
  dofile( joshnt_UniqueRegions_Core ) 
else 
  reaper.MB("This script requires an additional script, which gets installed over ReaPack as well. Please re-install the whole 'Unique Regions' Pack here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt_Create unique regions for overlapping items'","Error",0)
  return
end 
]]--

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

-- load Lokasenna GUI
local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please install 'Lokasenna's GUI library v2 for Lua', available on ReaPack, then run the 'Set Lokasenna_GUI v2 library path.lua' script in your Action List.", "Whoops!", 0)
    return
end
loadfile(lib_path .. "Core.lua")()




GUI.req("Classes/Class - Frame.lua")()
GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Textbox.lua")()
GUI.req("Classes/Class - Slider.lua")()
GUI.req("Classes/Class - Label.lua")()
GUI.req("Classes/Class - Options.lua")()
GUI.req("Classes/Class - Menubox.lua")()
-- If any of the requested libraries weren't found, abort the script.
if missing_lib then return 0 end



GUI.name = "joshnt_Unique Regions - Settings-GUI"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 800, 425
GUI.anchor, GUI.corner = "screen", "C"

-- additional GUI variables
local previewWithTimeSelection = false -- saved as settings to external states
local focusArray, focusIndex = {"TimeBefore_Text","TimeAfter_Text","TimeBetween_Text","RegionNameChild","RegionNameMother"}, 0
local tabPressed, enterPressed = false, false
local timeSliderVals = {
    TimeBefore = {min = -10, max = 0, defaults = 100, val = 0},
    TimeAfter = {min = 0, max = 10, defaults = 0, val = 0},
    TimeBetween = {min = 0, max = 10, defaults = 0, val = 0},
    TimeInclude = {min = 0, max = 10, defaults = 0, val = 0}
}


local function exitFunction()
    joshnt_UniqueRegions.saveDefaults()
    reaper.SetExtState("joshnt_UniqueRegions", "GUI_Options", tostring(previewWithTimeSelection), true)
    joshnt_UniqueRegions.Quit()
end

local function run_Button()
    joshnt_UniqueRegions.main()
    local optionsTable = GUI.Val("options") -- Lock, Save as default, Close GUI
    if optionsTable[2] then
        joshnt_UniqueRegions.saveDefaults()
    end
    if optionsTable[3] then
        GUI.quit = true
    end
end

local function adjustTimeselection()
    if previewWithTimeSelection then
        local _, itemStarts, itemEnds = joshnt.getOverlappingItemGroupsOfSelectedItems(joshnt_UniqueRegions.groupToleranceTime)
        if itemStarts and itemEnds then
            local startTime, endTime = itemStarts[1], itemEnds[1]
            reaper.GetSet_LoopTimeRange(true, false, startTime - joshnt_UniqueRegions.start_silence, endTime + joshnt_UniqueRegions.end_silence, false)
        end
    end
end

local function setSliderSize(SliderName_String, newSliderValue_Input)
    local newSliderValue = newSliderValue_Input 
    if not newSliderValue_Input then 
        if SliderName_String == "TimeBefore" then newSliderValue = joshnt_UniqueRegions.start_silence
        elseif SliderName_String == "TimeAfter" then newSliderValue = joshnt_UniqueRegions.end_silence
        elseif SliderName_String == "TimeBetween" then newSliderValue = joshnt_UniqueRegions.space_in_between
        else newSliderValue = joshnt_UniqueRegions.groupToleranceTime end
    end

    local tb_to_num = tonumber(newSliderValue)
    if tb_to_num then
        if SliderName_String ~= "TimeBefore" then
            tb_to_num = math.max(0, tb_to_num)
            if tb_to_num > GUI.elms[SliderName_String]["max"] or GUI.elms[SliderName_String]["max"] > 10 then
                timeSliderVals[SliderName_String]["max"] = math.max(tb_to_num,10)
            end
            local newVal = (tb_to_num-GUI[SliderName_String]["min"])/GUI.elms[SliderName_String]["inc"]
            timeSliderVals[SliderName_String]["val"] = newVal
            GUI.Val(SliderName_String,{newVal})
        else
        end

        local sliderTemp = GUI.elms[SliderName_String]
        sliderTemp:init_handles()
    end
end

local function setVisibilityMotherRgn()
    if joshnt_UniqueRegions.createMotherRgn then
        GUI.elms.RRMMother.z = 21
        GUI.elms.RegionNameMother.z = 21
        GUI.elms.Mother_Label.z = 21
        GUI.elms.ColSelFrame_Mother.z = 21
    else
        GUI.elms.RRMMother.z = 5
        GUI.elms.RegionNameMother.z = 5
        GUI.elms.Mother_Label.z = 5
        GUI.elms.ColSelFrame_Mother.z = 5
    end
    GUI.redraw_z[5] = true
    GUI.redraw_z[21] = true
end

local function redrawSliders()

    GUI.New("TimeBefore", "Slider", {
        z = 15,
        x = 144,
        y = 48,
        w = 150,
        caption = "Time Before (s)",
        min = timeSliderVals.TimeBefore.min,
        max = timeSliderVals.TimeBefore.max,
        defaults = {timeSliderVals.TimeBefore.defaults},
        inc = 0.1,
        dir = "h",
        font_a = 3,
        font_b = 4,
        col_txt = "txt",
        col_fill = "elm_fill",
        bg = "wnd_bg",
        show_handles = true,
        show_values = true,
        cap_x = -125,
        cap_y = 20
    })

    GUI.New("TimeAfter", "Slider", {
        z = 15,
        x = 144,
        y = 96,
        w = 150,
        caption = "Time After (s)",
        min = timeSliderVals.TimeAfter.min,
        max = timeSliderVals.TimeAfter.max,
        defaults = {timeSliderVals.TimeAfter.defaults},
        inc = 0.1,
        dir = "h",
        font_a = 3,
        font_b = 4,
        col_txt = "txt",
        col_fill = "elm_fill",
        bg = "wnd_bg",
        show_handles = true,
        show_values = true,
        cap_x = -122,
        cap_y = 20
    })

    GUI.New("TimeBetween", "Slider", {
        z = 15,
        x = 144,
        y = 144,
        w = 150,
        caption = "Distance between (s)",
        min = timeSliderVals.TimeBetween.min,
        max = timeSliderVals.TimeBetween.max,
        defaults = {timeSliderVals.TimeBetween.defaults},
        inc = 0.1,
        dir = "h",
        font_a = 3,
        font_b = 4,
        col_txt = "txt",
        col_fill = "elm_fill",
        bg = "wnd_bg",
        show_handles = true,
        show_values = true,
        cap_x = -140,
        cap_y = 20
    })

    GUI.New("TimeInclude", "Slider", {
        z = 15,
        x = 144,
        y = 192,
        w = 150,
        caption = "Group tolerance",
        min = timeSliderVals.TimeInclude.min,
        max = timeSliderVals.TimeInclude.max,
        defaults = timeSliderVals.TimeInclude.defaults,
        inc = 0.01,
        dir = "h",
        font_a = 3,
        font_b = 4,
        col_txt = "txt",
        col_fill = "elm_fill",
        bg = "wnd_bg",
        show_handles = true,
        show_values = true,
        cap_x = -140,
        cap_y = 20
    })
end

local function redrawColFrames()
    GUI.New("ColSelFrame_Child", "Frame", {
        z = 11,
        x = 486,
        y = 187,
        w = 80,
        h = 25,
        shadow = false,
        fill = false,
        color = "elm_frame",
        bg = "wnd_bg",
        round = 0,
        text = "      Color ",
        txt_indent = 0,
        txt_pad = 0,
        pad = 4,
        font = 4,
        col_txt = "txt"
    })

    
    GUI.New("ColSelFrame_Mother", "Frame", {
        z = 21,
        x = 630,
        y = 187,
        w = 80,
        h = 25,
        shadow = false,
        fill = false,
        color = "elm_frame",
        bg = "wnd_bg",
        round = 0,
        text = "      Color ",
        txt_indent = 0,
        txt_pad = 0,
        pad = 4,
        font = 4,
        col_txt = "txt"
    })


end

local function setFrameColors(frameTargetString)
    local targetColor = nil
    if frameTargetString == "Child" then targetColor = joshnt_UniqueRegions.regionColor
    else targetColor = joshnt_UniqueRegions.regionColorMother end

    if targetColor then 
        local r,g,b = reaper.ColorFromNative(targetColor)
        r = r/255
        g = g/255
        b = b/255
        GUI.colors[frameTargetString.."Col"] = {r,g,b,1}
    else 
        GUI.colors[frameTargetString.."Col"] = GUI.colors["wnd_bg"] 
    end

    redrawColFrames()
end

local function redrawAll ()
    GUI.elms_hide[5] = true

    redrawSliders()
    redrawColFrames()

    GUI.New("TimeBefore_Text", "Textbox", {
        z = 11,
        x = 320,
        y = 43,
        w = 40,
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

    GUI.New("TimeAfter_Text", "Textbox", {
        z = 11,
        x = 320,
        y = 91,
        w = 40,
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

    GUI.New("TimeBetween_Text", "Textbox", {
        z = 11,
        x = 320,
        y = 139,
        w = 40,
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

    GUI.New("TimeInclude_Text", "Textbox", {
        z = 11,
        x = 320,
        y = 187,
        w = 40,
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

    GUI.New("Preview", "Checklist", {
        z = 11,
        x = 56,
        y = 238,
        w = 300,
        h = 30,
        caption = "",
        optarray = {"Preview Before and after Time as time-selection"},
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

    GUI.New("Child_Label", "Label", {
        z = 11,
        x = 470,
        y = 59,
        caption = "Region per Item group",
        font = 3,
        color = "txt",
        bg = "wnd_bg",
        shadow = false
    })

    GUI.New("RegionNameChild", "Textbox", {
        z = 11,
        x = 486,
        y = 91,
        w = 100,
        h = 20,
        caption = "Region Name",
        cap_pos = "left",
        font_a = 3,
        font_b = "monospace",
        color = "txt",
        bg = "wnd_bg",
        shadow = true,
        pad = 4,
        undo_limit = 20
    })

    GUI.New("RRMChild", "Menubox", {
        z = 11,
        x = 486,
        y = 139,
        w = 100,
        h = 20,
        caption = "Link to RRM",
        optarray = {"Master", "First Parent", "Highest Parent", "Each Track", "None"},
        retval = 2.0,
        font_a = 3,
        font_b = 4,
        col_txt = "txt",
        col_cap = "txt",
        bg = "wnd_bg",
        pad = 4,
        noarrow = false,
        align = 0
    })

    GUI.New("MotherRgnBool", "Checklist", {
        z = 11,
        x = 625,
        y = 19,
        w = 155,
        h = 30,
        caption = "",
        optarray = {"Create Mother Region"},
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

    GUI.New("Mother_Label", "Label", {
        z = 21,
        x = 630,
        y = 59,
        caption = "Mother region",
        font = 3,
        color = "txt",
        bg = "wnd_bg",
        shadow = false
    })

    GUI.New("RegionNameMother", "Textbox", {
        z = 21,
        x = 630,
        y = 91,
        w = 100,
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

    GUI.New("RRMMother", "Menubox", {
        z = 21,
        x = 630,
        y = 139,
        w = 100,
        h = 20,
        caption = "",
        optarray = {"Master", "First Parent", "Highest Parent", "Each Track", "None"},
        retval = 1,
        font_a = 3,
        font_b = 4,
        col_txt = "txt",
        col_cap = "txt",
        bg = "wnd_bg",
        pad = 4,
        noarrow = false,
        align = 0
    })

    GUI.New("isolateItems", "Radio", {
        z = 11,
        x = 24,
        y = 315,
        w = 120,
        h = 80,
        caption = "Isolate options",
        optarray = {"Move selected", "Move others", "Don't move"},
        dir = "v",
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

    GUI.New("Run", "Button", {
        z = 11,
        x = 308,
        y = 305,
        w = 72,
        h = 30,
        caption = "Run",
        font = 2,
        col_txt = "txt",
        col_fill = "elm_frame",
        func = run_Button
    })

    GUI.New("options", "Checklist", {
        z = 11,
        x = 174,
        y = 315,
        w = 120,
        h = 85,
        caption = "On run:",
        optarray = {"Lock items", "Save as default", "Close GUI"},
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

    -- seperation frames
    GUI.New("Frame_TimeSel", "Frame", {
        z = 30,
        x = 12,
        y = 16,
        w = 365,
        h = 260,
        shadow = false,
        fill = false,
        color = "elm_frame",
        bg = "wnd_bg",
        round = 0,
        text = "",
        txt_indent = 0,
        txt_pad = 0,
        pad = 4,
        font = 4,
        col_txt = "txt"
    })

    GUI.New("Frame_RegionOptions", "Frame", {
        z = 30,
        x = 400,
        y = 16,
        w = 390,
        h = 220,
        shadow = false,
        fill = false,
        color = "elm_frame",
        bg = "wnd_bg",
        round = 0,
        text = "",
        txt_indent = 0,
        txt_pad = 0,
        pad = 4,
        font = 4,
        col_txt = "txt"
    })

    GUI.New("Frame_OtherObjects", "Frame", {
        z = 30,
        x = 12,
        y = 290,
        w = 385,
        h = 124,
        shadow = false,
        fill = false,
        color = "elm_frame",
        bg = "wnd_bg",
        round = 0,
        text = "",
        txt_indent = 0,
        txt_pad = 0,
        pad = 4,
        font = 4,
        col_txt = "txt"
    })


    -- Tooltips
    GUI.elms.TimeBefore.tooltip = "Adjust how many seconds before each overlapping item group should be part of the corresponding region."
    GUI.elms.TimeBefore_Text.tooltip = "Corresponding textinput to slider to the left.\nIf input is out of slider bounds, slider gets rescaled automatically.\nUse 'TAB' to cycle between all text-input boxes."
    GUI.elms.TimeAfter.tooltip = "Adjust how many seconds after each overlapping item group should be part of the corresponding region."
    GUI.elms.TimeAfter_Text.tooltip = "Corresponding textinput to slider to the left.\nIf input is out of slider bounds, slider gets rescaled automatically.\nUse 'TAB' to cycle between all text-input boxes."
    GUI.elms.TimeBetween.tooltip = "Adjust how many seconds between each item group's region should be empty."
    GUI.elms.TimeBetween_Text.tooltip = "Corresponding textinput to slider to the left.\nIf input is out of slider bounds, slider gets rescaled automatically.\nUse 'TAB' to cycle between all text-input boxes."
    GUI.elms.TimeInclude.tooltip = "Adjust how far away from each other items can be to still be considered as one 'group'.\n\nE.g. 0 means only actually overlapping items count as one group.\n1 means items within 1 second of each others start/ end still count as one group."
    GUI.elms.TimeInclude_Text.tooltip = "Corresponding textinput to slider to the left.\nIf input is out of slider bounds, slider gets rescaled automatically.\nUse 'TAB' to cycle between all text-input boxes."
    GUI.elms.Preview.tooltip = "Use REAPER's 'Time-Selection' to visualize the first group's region bounds.\nRefreshes on time-value changes; to refresh after a item-selection change, press 'R'."
    GUI.elms.RegionNameChild.tooltip = "Set the name of the individual regions. Use '/E' to enumerate from 1 or '/E(Number), e.g. '/E(3)' to enumerate from that number onwards."
    GUI.elms.RegionNameMother.tooltip = "Set the name of the mother regions."
    GUI.elms.RRMChild.tooltip = "Choose over which track to route the newly created regions in the region render matrix.\n\n'Master' routes over the Master-Track.\n'First Parent' routes over the first found parent of all selected items (without any selected items on it) or the Master if no parent can be found.\n'Highest Parent' uses the highest common parent of all selected items or the Master if no parent can be found.\n'Each Track' only routes over a track if the track has items from the selection on it.\n'None' doesn't set a link in the RRM."
    GUI.elms.RRMMother.tooltip = "Choose over which track to route the newly created mother region in the region render matrix.\n\n'Master' routes over the Master-Track.\n'First Parent' routes over the first found parent of all selected items (without any selected items on it) or the Master if no parent can be found.\n'Highest Parent' uses the highest common parent of all selected items or the Master if no parent can be found.\n'Each Track' only routes over a track if the track has items from the selection on it.\n'None' doesn't set a link in the RRM."
    GUI.elms.MotherRgnBool.tooltip = "Toogle if a 'Mother-Region' (a region over all other newly created regions) should be created."
    GUI.elms.ColSelFrame_Child.tooltip = "Click here to choose a color for each individual region.\nCancelling the color-picker dialog will use the default region color."
    GUI.elms.ColSelFrame_Mother.tooltip = "Click here to choose a color for the mother region.\nCancelling the color-picker dialog will use the default region color."
    GUI.elms.isolateItems.tooltip = "Sets if any and which items should be moved to avoid overlaps of the selected items with non-selected items.\nWARNING: Not moving items if there are other items on the track with the selected items may result in deleting those items between."
    GUI.elms.Run.tooltip = "Execute the script with the current Settings.\nShortcut - 'RETURN'"
    GUI.elms.options.tooltip = "Additional options for when this script gets executed via the 'Run' button.\n\nLock items - locks the selected items after creating the regions and eventually moving them.\nSave as default - save current setttings as defaults (for the next start of this GUI and the GUI-less versions of this script).\nClose GUI - Close GUI after executing this script."

end

local function Loop()
    if GUI.char == 9.0 and tabPressed == false then
        if type(focusIndex) == "number" and type(focusIndex) ~= 0 then
            GUI.elms[focusArray[focusIndex]].focus = false
            if GUI.mouse.cap == 8 then
                focusIndex = ((focusIndex-2) % #focusArray) +1
            else
                focusIndex = (focusIndex % #focusArray) +1
            end
        else 
            focusIndex = 1
        end
        GUI.elms[focusArray[focusIndex]].focus = true
        tabPressed = true
    elseif GUI.char == 13.0 and enterPressed == false then -- Return pressed
        for i = 1, #focusArray do
            if GUI.elms[focusArray[i]].focus == true then return end
        end
        run_Button()
        enterPressed = true
    elseif GUI.char == 114 then -- R für refresh
        adjustTimeselection()
    elseif GUI.char == 0.0 then
        if tabPressed == true then tabPressed = false
        elseif enterPressed == true then enterPressed = false end
    end
end

-- load default values to GUI interface
local function loadDefaultValues()
    if joshnt_UniqueRegions.isolateItems then GUI.Val("isolateItems",joshnt_UniqueRegions.isolateItems) end
    if joshnt_UniqueRegions.space_in_between then GUI.Val("TimeBetween",joshnt_UniqueRegions.space_in_between) GUI.Val("TimeBetween_Text",joshnt_UniqueRegions.space_in_between) end
    if joshnt_UniqueRegions.groupToleranceTime then GUI.Val("TimeInclude",joshnt_UniqueRegions.groupToleranceTime) GUI.Val("TimeInclude_Text",joshnt_UniqueRegions.groupToleranceTime) end
    if joshnt_UniqueRegions.start_silence then GUI.Val("TimeBefore",joshnt_UniqueRegions.start_silence) GUI.Val("TimeBefore_Text",joshnt_UniqueRegions.start_silence) end
    if joshnt_UniqueRegions.end_silence then GUI.Val("TimeAfter",joshnt_UniqueRegions.end_silence) GUI.Val("TimeAfter_Text",joshnt_UniqueRegions.end_silence) end
    if joshnt_UniqueRegions.lockBoolUser then GUI.Val("isolateItems",joshnt_UniqueRegions.lockBoolUser) end
    if joshnt_UniqueRegions.regionName then GUI.Val("RegionNameChild",joshnt_UniqueRegions.regionName) end
    if joshnt_UniqueRegions.motherRegionName then GUI.Val("isolateItems",joshnt_UniqueRegions.motherRegionName) end
    if joshnt_UniqueRegions.RRMLink_Child then GUI.Val("RRMChild",joshnt_UniqueRegions.RRMLink_Child) end
    if joshnt_UniqueRegions.RRMLink_Mother then GUI.Val("isolateItems",joshnt_UniqueRegions.RRMLink_Mother) end
    GUI.Val("Preview",previewWithTimeSelection)
    setFrameColors("Child")
    setFrameColors("Mother")
    setVisibilityMotherRgn()
end

local function init()
    joshnt_UniqueRegions.getDefaults()
    GUI.colors["ChildCol"] = GUI.colors["wnd_bg"] 
    GUI.colors["MotherCol"] = GUI.colors["wnd_bg"] 
    local tempOption_Array = joshnt.splitStringToTable(reaper.GetExtState("joshnt_UniqueRegions", "GUI_Options", tostring(previewWithTimeSelection)))
    previewWithTimeSelection = tempOption_Array[1] == "true"
    redrawAll()
    loadDefaultValues()
    for sliderName, _ in pairs(timeSliderVals) do
        setSliderSize(sliderName)
    end
end



init()
GUI.Init()
GUI.func = Loop
GUI.freq = 0
GUI.onresize = redrawAll
GUI.exit = exitFunction
GUI.Main()

--
--[[
- input options with clicks to trigger functions + hide/ show mother region

]]--