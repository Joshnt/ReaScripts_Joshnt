-- @noindex

-- load 'externals'
-- Load Unique Regions Core script
local joshnt_UniqueRegions_Core = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/VARIOUS/joshnt_Create unique regions for each group of overlapping items/joshnt_Unique Regions for overlapping items - CORE.lua'
if reaper.file_exists( joshnt_UniqueRegions_Core ) then 
  dofile( joshnt_UniqueRegions_Core ) 
else 
  reaper.MB("This script requires an additional script, which gets installed over ReaPack as well. Please re-install the whole 'Unique Regions' Pack here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt_Create unique regions for overlapping items'","Error",0)
  return
end 

-- Load lua utilities
local joshnt_LuaUtils = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/DEVELOPMENT/joshnt_LuaUtilities.lua'
if reaper.file_exists( joshnt_LuaUtils ) then 
  dofile( joshnt_LuaUtils ) 
  if not joshnt or joshnt.version() < 3.0 then 
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


--[[
-----------------------------------
----- z layer logic for GUI: ------
-----------------------------------
- 5 = hidden

General:
- 2 = non-clickable Lables etc.
- 3 = General UI 


Tab specifics:
- 11 = tab 1
- 12 = tab 2
- 13 = tab 3 
...


Wildcard windows with textboxes
- 50 = Buttons to confirm/ cancel (close only open window, if not crash! safe in variable which is open), "each line represents a new entry to cycle through. Watch out for unwanted empty lines."
- 51 = Texteditor 1, Window
- 52 = Texteditor 2, Window
- 53 = Texteditor 3, Window
- 54 = Texteditor 4, Window
- 55 = Texteditor 5, Window
]]--


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
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 400, 675
GUI.anchor, GUI.corner = "screen", "C"

-- additional GUI variables
local focusArray, focusIndex = {"TimeBefore_Text","TimeAfter_Text","RegionName","TimeBetween_Text","TimeInclude_Text"}, 0
local tabPressed, enterPressed = false, false

-- SLIDER
local timeSlidersVals = {
    general = {
        TimeBetween = {min = 0, max = 10, defaults = 0, val = 0},
        TimeInclude = {min = 0, max = 10, defaults = 0, val = 0}
    },

    rgn_TEMPLATE = {
    TimeBefore = {min = -10, max = 0, defaults = 100, val = 0},
    TimeAfter = {min = 0, max = 10, defaults = 0, val = 0},
    },
    -- TODO Init slider on tab creation
    -- use timeSliderValRgn[#timeSliderValRgn+1] = joshnt.copyTable(timeSliderValRgn_TEMPLATE) for each new Rgn Set
    rgn = {}
}

-- TABS
local numTabs = 1


-- MENU
-- TODO setup menu structure with variables

local function updateUserValues()
    joshnt_UniqueRegions.repositionToggle = true
    joshnt_UniqueRegions.space_in_between = 0 -- Time in seconds
    joshnt_UniqueRegions.groupToleranceTime = 0  -- Time in seconds

    -- for loop with number of tabs
    for i = 1, numTabs do
        if not joshnt_UniqueRegions.allRgnArray[i] then
            joshnt_UniqueRegions.allRgnArray[i] = joshnt.copyTable(joshnt_UniqueRegions.rgnProperties)
        end
        -- TODO assign GUI Vals to joshnt_UniqueRegions stuff
    end
    -- mehr gespeicherte regionen als momentan tabs -> delete speicher
    if numTabs < #joshnt_UniqueRegions.allRgnArray then
        for i = numTabs, #joshnt_UniqueRegions.allRgnArray do
            joshnt_UniqueRegions.allRgnArray[i] = nil
        end
    end
    joshnt_UniqueRegions.isolateItems = 1 -- 1 = move selected, 2 = move others, 3 = dont move
end

local function run_Button()
    updateUserValues()
    joshnt_UniqueRegions.main()
    if joshnt_UniqueRegions.closeGUI then
        joshnt_UniqueRegions.Quit()
        GUI.quit = true
    end
end

local function adjustTimeselection()
    if joshnt_UniqueRegions.previewTimeSelection == true then
        local _, itemStarts, itemEnds = joshnt.getOverlappingItemGroupsOfSelectedItems(GUI.Val("TimeInclude")) 
        if itemStarts and itemEnds then
            local startTime, endTime = itemStarts[1], itemEnds[1]
            reaper.GetSet_LoopTimeRange(true, false, startTime + GUI.Val("TimeBefore"), endTime + GUI.Val("TimeAfter"), false) -- TODO get Value for slider 1
        end
    end
end

local function setSliderSize(SliderName_String, newSliderValue_Input, tabNum)
    local newSliderValue = newSliderValue_Input 
    if not newSliderValue_Input then 
        if SliderName_String.find("TimeBefore") then newSliderValue = joshnt_UniqueRegions.allRgnArray[tabNum]["start_silence"]
        elseif SliderName_String.find("TimeAfter") then newSliderValue = joshnt_UniqueRegions.allRgnArray[tabNum]["end_silence"]
        elseif SliderName_String.find("TimeBetween") then newSliderValue = joshnt_UniqueRegions.space_in_between
        elseif SliderName_String.find("TimeInclude") then newSliderValue = joshnt_UniqueRegions.groupToleranceTime end
    end

    local tb_to_num = tonumber(newSliderValue)
    if tb_to_num then
        local redraw = false
        if not SliderName_String.find("TimeBefore") then
            tb_to_num = math.max(0, tb_to_num)
            if tb_to_num > GUI.elms[SliderName_String]["max"] or GUI.elms[SliderName_String]["max"] > 10 then
                local tempVal = math.max(tb_to_num,10)
                if tabNum then
                    timeSlidersVals["rgn"][tabNum][SliderName_String]["max"] = tempVal
                else
                    timeSlidersVals["general"][SliderName_String]["max"] = tempVal
                end
                GUI.elms[SliderName_String]["max"] = tempVal
                redraw = true
            end
        else
            tb_to_num = math.abs(tb_to_num) * -1
            if tb_to_num < GUI.elms[SliderName_String]["min"] or GUI.elms[SliderName_String]["min"] < -10 then
                timeSlidersVals["rgn"][tabNum][SliderName_String]["min"] = math.min(tb_to_num,-10)
                GUI.elms[SliderName_String]["min"] = timeSlidersVals["rgn"][tabNum][SliderName_String]
                redraw = true
            end
        end
        local newVal = (tb_to_num-GUI.elms[SliderName_String]["min"])/GUI.elms[SliderName_String]["inc"]
        if redraw == true then GUI.elms[SliderName_String]:init_handles() end
        timeSlidersVals["rgn"][tabNum][SliderName_String]["val"] = newVal
        GUI.Val(SliderName_String,newVal)
        adjustTimeselection()
    end
end

-- TODO - split up in general & per tab (per tab function uses index as input)
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
        caption = "Group tolerance (s)",
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

    function GUI.elms.TimeBefore:onmouseup()
        GUI.Slider.onmouseup(self)
        adjustTimeselection()
        GUI.Val("TimeBefore_Text", GUI.Val("TimeBefore"))
    end
    function GUI.elms.TimeBefore:ondrag()
        GUI.Slider.ondrag(self)
        adjustTimeselection()
    end
    function GUI.elms.TimeBefore:ondoubleclick()
        GUI.Slider.ondrag(self)
        adjustTimeselection()
    end

    function GUI.elms.TimeAfter:onmouseup()
        GUI.Slider.onmouseup(self)
        adjustTimeselection()
        GUI.Val("TimeAfter_Text", GUI.Val("TimeAfter"))
    end
    function GUI.elms.TimeAfter:ondrag()
        GUI.Slider.ondrag(self)
        adjustTimeselection()
    end
    function GUI.elms.TimeAfter:ondoubleclick()
        GUI.Slider.ondrag(self)
        adjustTimeselection()
    end

    function GUI.elms.TimeBetween:onmouseup()
        GUI.Slider.onmouseup(self)
        GUI.Val("TimeBetween_Text", GUI.Val("TimeBetween"))
    end

    function GUI.elms.TimeInclude:onmouseup()
        GUI.Slider.onmouseup(self)
        GUI.Val("TimeInclude_Text", GUI.Val("TimeInclude"))
    end

    GUI.elms.TimeBefore.tooltip = "Adjust how many seconds before each overlapping item group should be part of the corresponding region."
    GUI.elms.TimeAfter.tooltip = "Adjust how many seconds after each overlapping item group should be part of the corresponding region."
    GUI.elms.TimeBetween.tooltip = "Adjust how many seconds between each item group's region should be empty."
    GUI.elms.TimeInclude.tooltip = "Adjust how far away from each other items can be to still be considered as one 'group'.\n\nE.g. 0 means only actually overlapping items count as one group.\n1 means items within 1 second of each others start/ end still count as one group."
   
end

local function redrawColFrames(tabInd)
    GUI.New("ColSelFrame_"..tabInd, "Frame", {
        z = 10+tabInd,
        x = 86,
        y = 476,
        w = 80,
        h = 25,
        shadow = false,
        fill = false,
        color = "elm_frame",
        bg = "ChildCol",
        round = 0,
        text = "      Color ",
        txt_indent = 0,
        txt_pad = 0,
        pad = 4,
        font = 4,
        col_txt = "txt"
    })

    local currColFrame = GUI["elms"]["ColSelFrame_"..tabInd]
    function currColFrame:onmouseup()
        local retval, newColor = reaper.GR_SelectColor(nil)
        if retval ~= 0 then 
            joshnt_UniqueRegions.allRgnArray[tabInd]["color"] = newColor 
        else
            joshnt_UniqueRegions.allRgnArray[tabInd]["color"] = -1
        end

        setFrameColors(tabInd, newColor)
    end

    currColFrame.tooltip = "Click here to choose a color for each individual region/ marker.\nCancelling the color-picker dialog will use the default color."
end

-- global because redraw needs to access it
function setFrameColors(tabInd, targetColor)
    if targetColor and targetColor ~= 0 then 
        local r,g,b = reaper.ColorFromNative(targetColor)
        r = r/255
        g = g/255
        b = b/255
        GUI.colors["Col"..tostring(tabInd)] = {r,g,b,1}
    else 
        GUI.colors["Col"..tostring(tabInd)] = GUI.colors["wnd_bg"] 
    end

    redrawColFrames(tabInd)
end

-- TODO ja die main arbeit halt nich
local function redrawAll ()
    GUI.elms_hide[5] = true

    GUI.New("Cat1", "Label", {
        z = 11,
        x = 5,
        y = 5,
        caption = "Adjust Region Length and Distance",
        font = 2,
        color = "elm_fill",
        bg = "elm_frame",
        shadow = true
    })

    GUI.New("TimeBefore_Text", "Textbox", {
        z = 11,
        x = 315,
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
        x = 315,
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
        x = 315,
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

    GUI.New("RepositionToggle", "Checklist", {
        z = 10,
        x = 368,
        y = 133,
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

    GUI.New("TimeInclude_Text", "Textbox", {
        z = 11,
        x = 315,
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
        y = 228,
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

    -- Region creation
    GUI.New("Cat2", "Label", {
        z = 11,
        x = 5,
        y = 280,
        caption = "Create Region(s)",
        font = 2,
        color = "elm_fill",
        bg = "elm_frame",
        shadow = true
    })

    GUI.New("ChildRgnBool", "Checklist", {
        z = 11,
        x = 60,
        y = 308,
        w = 155,
        h = 30,
        caption = "",
        optarray = {"Create indiv. Regions"},
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
        x = 70,
        y = 348,
        caption = "Region per Item group",
        font = 3,
        color = "txt",
        bg = "wnd_bg",
        shadow = false
    })

    GUI.New("RegionNameChild", "Textbox", {
        z = 11,
        x = 86,
        y = 380,
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
        x = 86,
        y = 428,
        w = 100,
        h = 20,
        caption = "Link to RRM",
        optarray = {"Master", "Highest common Parent (all)", "First common Parent (all)", "First common parent (per item group)", "Parent (per item)", "Each Track", "None"},
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


    -- run and settings
    GUI.New("Cat3", "Label", {
        z = 11,
        x = 5,
        y = 530,
        caption = "Other settings",
        font = 2,
        color = "elm_fill",
        bg = "elm_frame",
        shadow = true
    })

    GUI.New("isolateItems", "Radio", {
        z = 11,
        x = 24,
        y = 575,
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
        y = 565,
        w = 72,
        h = 30,
        caption = "Run",
        font = 2,
        col_txt = "txt",
        col_fill = "elm_frame",
        func = run_Button
    })

    -- seperation frames - visualisation only

    GUI.New("Frame_hor1", "Frame", {
        z = 30,
        x = 12,
        y = 270,
        w = 376,
        h = 2,
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

    GUI.New("Frame_hor2", "Frame", {
        z = 30,
        x = 12,
        y = 520,
        w = 376,
        h = 2,
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

    for i = 1, #focusArray do
        local currTextboxName = focusArray[i]
        local tempTextbox = GUI.elms[currTextboxName]
        function tempTextbox:lostfocus()
            GUI.Textbox.lostfocus(self)
            setSliderSize(string.gsub(currTextboxName, "_Text", ""),GUI.Val(currTextboxName))
        end
    end

    function GUI.elms.ChildRgnBool:onmousedown()
        GUI.Checklist.onmousedown(self)
        setVisibilityChildRgn()
    end

    function GUI.elms.ChildRgnBool:onmouseup()
        GUI.Checklist.onmouseup(self)
        setVisibilityChildRgn()
    end

    function GUI.elms.MotherRgnBool:onmousedown()
        GUI.Checklist.onmousedown(self)
        setVisibilityMotherRgn()
    end

    function GUI.elms.MotherRgnBool:onmouseup()
        GUI.Checklist.onmouseup(self)
        setVisibilityMotherRgn()
    end

    function GUI.elms.Preview:onmouseup()
        GUI.Checklist.onmouseup(self)
        previewWithTimeSelection = GUI.Val("Preview")
        if previewWithTimeSelection then adjustTimeselection() end
    end

    function GUI.elms.RepositionToggle:onmouseup()
        GUI.Checklist.onmouseup(self)
        if GUI.Val("RepositionToggle") then 
            GUI.elms.TimeBetween.z = 15
            GUI.elms.TimeBetween_Text.z = 11
            GUI.redraw_z[5] = true
            GUI.redraw_z[11] = true
            GUI.redraw_z[15] = true
        else
            GUI.elms.TimeBetween.z = 5
            GUI.elms.TimeBetween_Text.z = 5
            GUI.redraw_z[5] = true
            GUI.redraw_z[11] = true
            GUI.redraw_z[15] = true
        end
    end

    -- Tooltips
    GUI.elms.TimeBefore_Text.tooltip = "Corresponding textinput to slider to the left.\nIf input is out of slider bounds, slider gets rescaled automatically.\nUse 'TAB' to cycle between all text-input boxes."
    GUI.elms.TimeAfter_Text.tooltip = "Corresponding textinput to slider to the left.\nIf input is out of slider bounds, slider gets rescaled automatically.\nUse 'TAB' to cycle between all text-input boxes."
    GUI.elms.TimeBetween_Text.tooltip = "Corresponding textinput to slider to the left.\nIf input is out of slider bounds, slider gets rescaled automatically.\nUse 'TAB' to cycle between all text-input boxes."
    GUI.elms.TimeInclude_Text.tooltip = "Corresponding textinput to slider to the left.\nIf input is out of slider bounds, slider gets rescaled automatically.\nUse 'TAB' to cycle between all text-input boxes."
    GUI.elms.Preview.tooltip = "Use REAPER's 'Time-Selection' to visualize the first group's region bounds.\nRefreshes on time-value changes; to refresh after a item-selection change, press 'R'."
    GUI.elms.RepositionToggle.tooltip = "Toggle whether the selected items should get moved to ensure the region distance set with the slider to the left."
    GUI.elms.RegionNameChild.tooltip = "Set the name of the individual regions.\nUse '/E(Number) to enumerate from that number, e.g. '/E(3)' to enumerate from 3 onwards. Accepts as well modulo in the syntax of /E(0%4).\nYou can offset that modulo by using /E('start'%'moduloValue''offset'), e.g. /E(1%3-2).\n\nUse '/M(Note_Start: Step)' to enumerate Midinotes starting from 'Note_Start' increasing with 'Step' each time, e.g. /M(C#1,4). No given step size defaults to 1. \n\nUse '/O() to reference the name of an existing region at the corresponding spot. /O(ALTERNATIVE) will either use the original name (if existing) or the given 'ALTERNATIVE'.\nWarning: /O() might lead to unwanted results in situations with a lot of unclear region overlaps by failing to get the original region."
    GUI.elms.RegionNameMother.tooltip = "Set the name of the mother regions. \nWildcards like '/E' don't work here, as there is only one 'Mother-Region' created."
    GUI.elms.RRMChild.tooltip = "Choose over which track to route the newly created regions in the region render matrix.\n\n'Master' routes over the Master-Track.\n'First common Parent' routes over the first found parent of all selected items (without any selected items on it) or the Master if no parent can be found.\n'Highest common Parent' uses the highest common parent of all selected items or the Master if no parent can be found.\n'First parent per item' routes over all parent tracks of any items.\n'Each Track' only routes over a track if the track has items from the selection on it.\n'None' doesn't set a link in the RRM."
    GUI.elms.RRMMother.tooltip = "Choose over which track to route the newly created mother region in the region render matrix.\n\n'Master' routes over the Master-Track.\n'First common Parent' routes over the first found parent of all selected items (without any selected items on it) or the Master if no parent can be found.\n'Highest common Parent' uses the highest common parent of all selected items or the Master if no parent can be found.\n'First parent per item' routes over all parent tracks of any items.\n'Each Track' only routes over a track if the track has items from the selection on it.\n'None' doesn't set a link in the RRM."
    GUI.elms.MotherRgnBool.tooltip = "Toogle if a 'Mother-Region' (a region over all other newly created regions) should be created."
    GUI.elms.isolateItems.tooltip = "Sets if any and which items should be moved to avoid overlaps of the selected items with non-selected items.\nWARNING: Not moving items if there are other items on the track with the selected items may result in deleting those items between."
    GUI.elms.Run.tooltip = "Execute the script with the current Settings.\nShortcut - 'Shift + RETURN'"
    GUI.elms.options.tooltip = "Additional options for when this script gets executed via the 'Run' button.\n\nLock items - locks the selected items after creating the regions and eventually moving them.\nSave as default - save current setttings as defaults (for the next start of this GUI and the GUI-less versions of this script).\nClose GUI - Close GUI after executing this script."

    redrawSliders()
    redrawColFrames()

    GUI.Val("options",{joshnt_UniqueRegions.lockBoolUser, false, closeGUI})
end

local function Loop()

    -- TODO add numbers of keyboard for tab switch
    -- keyinput
    if GUI.char == 9.0 and tabPressed == false then
        if type(focusIndex) == "number" and focusIndex ~= 0 then
            GUI.elms[focusArray[focusIndex]].focus = false

            local function getNextFocusIndex()
                if GUI.mouse.cap == 8 then
                    focusIndex = ((focusIndex-2) % #focusArray) +1
                else
                    focusIndex = (focusIndex % #focusArray) +1
                end
                if GUI.elms[focusArray[focusIndex]].z == 5 then getNextFocusIndex() end
            end
            getNextFocusIndex()
        else 
            focusIndex = 1
        end
        GUI.elms[focusArray[focusIndex]].focus = true
        tabPressed = true
    elseif GUI.char == 13.0 and GUI.mouse.cap == 8 and enterPressed == false then -- Shift Return pressed
        enterPressed = true
        run_Button()
    elseif GUI.char == 114 then -- R für refresh
        for i = 1, #focusArray do
            if GUI.elms[focusArray[i]].focus == true then return end
        end
        adjustTimeselection()
    elseif GUI.char == 0.0 then
        if tabPressed == true then tabPressed = false
        elseif enterPressed == true then enterPressed = false end
    end
end

-- load default values to GUI interface
local function refreshGUIValues()
    -- TODO gescheites laden von values, abhängig von namen der GUI sachen
    if joshnt_UniqueRegions.isolateItems then GUI.Val("isolateItems",joshnt_UniqueRegions.isolateItems) else GUI.Val("isolateItems",1) end
    if joshnt_UniqueRegions.space_in_between then GUI.Val("TimeBetween",joshnt_UniqueRegions.space_in_between) GUI.Val("TimeBetween_Text",joshnt_UniqueRegions.space_in_between) end
    if joshnt_UniqueRegions.groupToleranceTime then GUI.Val("TimeInclude",joshnt_UniqueRegions.groupToleranceTime) GUI.Val("TimeInclude_Text",joshnt_UniqueRegions.groupToleranceTime) end
    if joshnt_UniqueRegions.start_silence then GUI.Val("TimeBefore",joshnt_UniqueRegions.start_silence) GUI.Val("TimeBefore_Text",joshnt_UniqueRegions.start_silence) end
    if joshnt_UniqueRegions.end_silence then GUI.Val("TimeAfter",joshnt_UniqueRegions.end_silence) GUI.Val("TimeAfter_Text",joshnt_UniqueRegions.end_silence) end
    if joshnt_UniqueRegions.lockBoolUser then GUI.Val("options",{joshnt_UniqueRegions.lockBoolUser,false,closeGUI}) end
    if joshnt_UniqueRegions.regionName then GUI.Val("RegionNameChild",joshnt_UniqueRegions.regionName) end
    if joshnt_UniqueRegions.motherRegionName then GUI.Val("RegionNameMother",joshnt_UniqueRegions.motherRegionName) end
    if joshnt_UniqueRegions.RRMLink_Child then GUI.Val("RRMChild",joshnt_UniqueRegions.RRMLink_Child) end
    if joshnt_UniqueRegions.RRMLink_Mother then GUI.Val("RRMMother",joshnt_UniqueRegions.RRMLink_Mother) end
    if joshnt_UniqueRegions.createMotherRgn == true then GUI.Val("MotherRgnBool", true) end
    if joshnt_UniqueRegions.createChildRgn == true then GUI.Val("ChildRgnBool", true) end
    if joshnt_UniqueRegions.repositionToggle == true or not joshnt_UniqueRegions.repositionToggle then GUI.Val("RepositionToggle", true) end
    GUI.Val("Preview",previewWithTimeSelection)

    -- TODO set frame über Anzahl von Regions
    setFrameColors("Child",joshnt_UniqueRegions.regionColor)
    setFrameColors("Mother",joshnt_UniqueRegions.regionColorMother)
end

local function init()
    joshnt_UniqueRegions.getDefaults()
    -- TODO on new rgn tab, create new rgn color; delete on tab delete (?)
    GUI.colors["Col_1"] = GUI.colors["wnd_bg"] 
    redrawAll()
    refreshGUIValues()
    -- TODO refresh general slider & pro region time before time after; evtl auslagern als function
    for sliderName, _ in pairs(timeSliderVals) do
        setSliderSize(sliderName)
    end
end

local function resize()

    -- TODO uff okay alles anpassen
    updateUserValues()
    redrawAll()
    refreshGUIValues()
    -- TODO refresh general slider & pro region time before time after; evtl auslagern als function (s. oben)
    for sliderName, _ in pairs(timeSliderVals) do
        setSliderSize(sliderName)
    end
end


GUI.Init()
init()
GUI.func = Loop
GUI.freq = 0
GUI.onresize = resize
GUI.Main()