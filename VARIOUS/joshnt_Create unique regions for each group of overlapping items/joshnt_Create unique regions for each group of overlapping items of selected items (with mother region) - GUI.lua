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

-- TODO Set all z layers
--[[
-----------------------------------
----- z layer logic for GUI: ------
-----------------------------------
- 5 = hidden

General:
- 2 = non-clickable Lables etc.
- 3 = General UI 
- 6 = Help-Window Wildcards
- 7 = Help-Window Shortcuts


Tab specifics:
- 11 = tab 1
- 12 = tab 2
- 13 = tab 3 
...


Wildcard windows with textboxes (Window has to be on single layer & the lowest)
- 50 = Buttons to confirm/ cancel (close only open window, if not crash! safe in variable which is open), "each line represents a new entry to cycle through. Watch out for unwanted empty lines."
- 51 = Texteditor 1
- 52 = Texteditor 2
- 53 = Texteditor 3
- 54 = Texteditor 4
- 55 = Texteditor 5
- 56 = Window 1
- 57 = Window 2
- 58 = Window 3
- 59 = Window 4
- 60 = Window 5
]]--


GUI.req("Classes/Class - Frame.lua")()
GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Textbox.lua")()
GUI.req("Classes/Class - Slider.lua")()
GUI.req("Classes/Class - Label.lua")()
GUI.req("Classes/Class - Options.lua")()
GUI.req("Classes/Class - Menubox.lua")()
GUI.req("Classes/Class - Window.lua")()
GUI.req("Classes/Class - Menubar.lua")()
GUI.req("Classes/Class - Tabs.lua")()
-- If any of the requested libraries weren't found, abort the script.
if missing_lib then return 0 end



GUI.name = "joshnt_Unique Regions - Settings-GUI"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 400, 675
GUI.anchor, GUI.corner = "screen", "C"

-- additional GUI variables
local focusArray, focusIndex = {"TimeBefore_Text","TimeAfter_Text","RegionName","TimeBetween_Text","TimeInclude_Text"}, 0
local tabPressed, enterPressed = false, false
local showRemoveWarning = true
local pressedHelp = 0 -- just troll

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
    -- use timeSlidersVals.Rgn[#timeSlidersVals.Rgn+1] = joshnt.copyTable(timeSlidersVals.Rgn_TEMPLATE) for each new Rgn Set
    rgn = {}
}
timeSlidersVals.rgn[1] = joshnt.copyTable(timeSlidersVals.rgn_TEMPLATE)

-- TABS, MENU, WINDOWS
local numTabsMax, numTabsMin = 20, 1 -- can be changed potentially
local numTabs = 1
local menuTableGUI= {}
local currOpenWindow = 0


-- sets values in CORE to GUI Values
local function updateUserValues()
    -- TODO assign GUI Vals to joshnt_UniqueRegions stuff
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
    -- TODO assign GUI Vals to joshnt_UniqueRegions stuff
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

-- at the moment only for RRM & after Time
local function setVisibilityRgnProperties(tabIndex)
    if GUI.Val("isRgn"..tabIndex) == 1 then
        GUI.elms["TimeAfter_Text"..tabIndex].z = 10+tabIndex
        GUI.elms["TimeAfter"..tabIndex].z = 10+tabIndex
        GUI.elms["RRM"..tabIndex].z = 10+tabIndex
    else
        GUI.elms["TimeAfter_Text"..tabIndex].z = 5
        GUI.elms["TimeAfter"..tabIndex].z = 5
        GUI.elms["RRM"..tabIndex].z = 5
    end
    GUI.redraw_z[5] = true
    GUI.redraw_z[10+tabIndex] = true
end

-- TODO call from create
local function setVisibilityRgn(tabIndex)
    if GUI.Val("Create"..tabIndex) == true then
        GUI.elms["RegionName"..tabIndex].z = 10+tabIndex
        GUI.elms["isRgn"..tabIndex].z = 10+tabIndex
        GUI.elms["TimeBefore_Text"..tabIndex].z = 10+tabIndex
        GUI.elms["TimeBefore"..tabIndex].z = 10+tabIndex
        GUI.elms["ColSelFrame"..tabIndex].z = 10+tabIndex
        setVisibilityRgnProperties(tabIndex)
    else
        GUI.elms["TimeAfter_Text"..tabIndex].z = 5
        GUI.elms["TimeAfter"..tabIndex].z = 5
        GUI.elms["RRM"..tabIndex].z = 5
        GUI.elms["RegionName"..tabIndex].z = 5
        GUI.elms["isRgn"..tabIndex].z = 5
        GUI.elms["TimeBefore_Text"..tabIndex].z = 5
        GUI.elms["TimeBefore"..tabIndex].z = 5
        GUI.elms["ColSelFrame"..tabIndex].z = 5
    end
    GUI.redraw_z[5] = true
    GUI.redraw_z[10+tabIndex] = true
end


local function adjustTimeselection()
    if joshnt_UniqueRegions.previewTimeSelection == true then
        local _, itemStarts, itemEnds = joshnt.getOverlappingItemGroupsOfSelectedItems(GUI.Val("TimeInclude")) -- TODO get Value for slider of current tab
        if itemStarts and itemEnds then
            local startTime, endTime = itemStarts[1], itemEnds[1]
            local startTimeOffset, endTimeOffset = GUI.Val("TimeBefore"), 0.1-- TODO get Value for slider of current tab
            -- TODO insert actual tab element name & actual is rgn element name + correct index (is 1 actually being a region?)
            if GUI.Val("isRgn"..GUI.Val("Tab")) == 1 then
                endTimeOffset = GUI.Val("TimeAfter") -- TODO get Value for slider of current tab
            end
            reaper.GetSet_LoopTimeRange(true, false, startTime + startTimeOffset, endTime + endTimeOffset, false) 
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

-- TODO adjust position
local function redrawColFrames(tabInd)
    GUI.New("ColSelFrame"..tabInd, "Frame", {
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

    local currColFrame = GUI["elms"]["ColSelFrame"..tabInd]
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

local function redrawTabs()
    local tabLayers = { }
    local displayTabs = {}
    for i = 1, numTabs do
        tabLayers[i] = {i}
        displayTabs[i] = tostring(i)
    end

    local tabW = joshnt.clamp((GUI.w - 80)/numTabs, 48, 18)

    GUI.New("Tabs", "Tabs", {
        z = 3,
        x = 80,
        y = 32,
        w = 832.0,
        caption = "Tabs",
        optarray = displayTabs,
        tab_w = 48,
        tab_h = 20,
        pad = 8,
        font_a = 3,
        font_b = 4,
        col_txt = "txt",
        col_tab_a = "wnd_bg",
        col_tab_b = "tab_bg",
        bg = "elm_bg",
        fullwidth = true
    })

    GUI.elms.Tabs:update_sets(tabLayers)
end

local function setTabNumButtonVisibility()
    if numTabs > numTabsMin then
        GUI.elms.Button_RemoveTab.z = 3
    else GUI.elms.Button_RemoveTab.z = 5
    end
    
    if numTabs < numTabsMax then
        GUI.elms.Button_AddTab.z = 3
    else GUI.elms.Button_AddTab.z = 5
    end

    GUI.redraw_z[5] = true
    GUI.redraw_z[3] = true
end

local function addTab()
    if numTabs < numTabsMax then
        numTabs = numTabs+1
        timeSlidersVals.Rgn[numTabs] = joshnt.copyTable(timeSlidersVals.Rgn_TEMPLATE)
        redrawTabs()
        -- add new region
        joshnt_UniqueRegions.allRgnArray[numTabs] = joshnt.copyTable(joshnt_UniqueRegions.rgnProperties)
        setTabNumButtonVisibility()
    end
end

-- remove current selected Tab & move backend indexes
local function removeTab()
    if numTabs > numTabsMin then
        if showRemoveWarning then
            local retval = reaper.MB("Are you sure, that you want to delete the selected tab and all of its settings? If you are unsure, if you will need it later, you can just uncheck 'Create'.\n\nPress 'Yes', if you want to hide this warning for this instance of the script.\nPress 'No' for still removing the tab, but showing the tab again on the next remove.", "Unique Regions Warning", 3)
            if retval == 2 then return 
            elseif retval == 6 then showRemoveWarning = false
            end
        end
        local prevSel = GUI.Val("Tabs")
        updateUserValues()
        -- move other regions one index down
        joshnt_UniqueRegions.allRgnArray[prevSel] = nil
        for i = prevSel +1, numTabs do
            joshnt_UniqueRegions.allRgnArray[i-1] = joshnt.copyTable(joshnt_UniqueRegions.allRgnArray[i])
        end
        joshnt_UniqueRegions.allRgnArray[numTabs] = nil
        timeSlidersVals.Rgn[numTabs] = nil
        numTabs = numTabs - 1
        redrawAll()
        refreshGUIValues()
    end
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


-- TODO adjust position, z layer, name
local function redrawTabContent(tabIndex)
    
    GUI.New("TimeBefore"..tabIndex, "Slider", {
        z = 15,
        x = 144,
        y = 48,
        w = 150,
        caption = "Time Before (s)",
        min = timeSlidersVals.rgn[tabIndex].TimeBefore.min,
        max = timeSlidersVals.rgn[tabIndex].TimeBefore.max,
        defaults = {timeSlidersVals.rgn[tabIndex].TimeBefore.defaults},
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

    GUI.New("TimeBefore_Text"..tabIndex, "Textbox", {
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

    GUI.New("TimeAfter"..tabIndex, "Slider", {
        z = 15,
        x = 144,
        y = 96,
        w = 150,
        caption = "Time After (s)",
        min = timeSlidersVals.rgn[tabIndex].TimeAfter.min,
        max = timeSlidersVals.rgn[tabIndex].TimeAfter.max,
        defaults = {timeSlidersVals.rgn[tabIndex].TimeAfter.defaults},
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

    GUI.New("TimeAfter_Text"..tabIndex, "Textbox", {
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

    GUI.New("Create"..tabIndex, "Checklist", {
        z = 11,
        x = 60,
        y = 308,
        w = 155,
        h = 30,
        caption = "",
        optarray = {"Create"},
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

    GUI.New("isRgn"..tabIndex, "Radio", {
        z = 11,
        x = 60,
        y = 308,
        w = 155,
        h = 30,
        caption = "",
        optarray = {"Region", "Marker"},
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

    GUI.New("RegionName"..tabIndex, "Textbox", {
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

    GUI.New("RRM"..tabIndex, "Menubox", {
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

    local currTimeBefore = GUI.elms["TimeBefore"..tabIndex]
    local currTimeBeforeText = GUI.elms["TimeBefore_Text"..tabIndex]

    function currTimeBefore:onmouseup()
        GUI.Slider.onmouseup(self)
        adjustTimeselection()
        GUI.Val("TimeBefore_Text"..tabIndex, GUI.Val("TimeBefore"..tabIndex))
    end
    function currTimeBefore:ondrag()
        GUI.Slider.ondrag(self)
        adjustTimeselection()
    end
    function currTimeBefore:ondoubleclick()
        GUI.Slider.ondrag(self)
        adjustTimeselection()
    end


    local currTimeAfter = GUI.elms["TimeAfter"..tabIndex]
    local currTimeAfterText = GUI.elms["TimeAfter_Text"..tabIndex]

    function currTimeAfter:onmouseup()
        GUI.Slider.onmouseup(self)
        adjustTimeselection()
        GUI.Val("TimeAfter_Text"..tabIndex, GUI.Val("TimeAfter"..tabIndex))
    end
    function currTimeAfter:ondrag()
        GUI.Slider.ondrag(self)
        adjustTimeselection()
    end
    function currTimeAfter:ondoubleclick()
        GUI.Slider.ondrag(self)
        adjustTimeselection()
    end


    local currCreate = GUI.elms["Create"..tabIndex]

    function currCreate:onmousedown()
        GUI.Checklist.onmousedown(self)
        setVisibilityRgn()
    end

    function currCreate:onmouseup()
        GUI.Checklist.onmouseup(self)
        setVisibilityRgn()
    end


    local currIsRgn = GUI.elms["isRgn"..tabIndex]

    function currIsRgn:onmousedown()
        GUI.Radio.onmousedown(self)
        setVisibilityRgnProperties()
    end

    function currIsRgn:onmouseup()
        GUI.Radio.onmouseup(self)
        setVisibilityRgnProperties()
    end



    currTimeBefore.tooltip = "Adjust how many seconds before each overlapping item group should be part of the corresponding region."
    currTimeAfter.tooltip = "Adjust how many seconds after each overlapping item group should be part of the corresponding region."
    currTimeBeforeText.tooltip = "Corresponding textinput to slider to the left.\nIf input is out of slider bounds, slider gets rescaled automatically.\nUse 'TAB' to cycle between all text-input boxes."
    currTimeAfterText.tooltip = "Corresponding textinput to slider to the left.\nIf input is out of slider bounds, slider gets rescaled automatically.\nUse 'TAB' to cycle between all text-input boxes."
    GUI.elms["RegionName"..tabIndex].tooltip = "Set the name of the individual regions.\nUse '/E(Number) to enumerate from that number, e.g. '/E(3)' to enumerate from 3 onwards. Accepts as well modulo in the syntax of /E(0%4).\nYou can offset that modulo by using /E('start'%'moduloValue''offset'), e.g. /E(1%3-2).\n\nUse '/M(Note_Start: Step)' to enumerate Midinotes starting from 'Note_Start' increasing with 'Step' each time, e.g. /M(C#1,4). No given step size defaults to 1. \n\nUse '/O() to reference the name of an existing region at the corresponding spot. /O(ALTERNATIVE) will either use the original name (if existing) or the given 'ALTERNATIVE'.\nWarning: /O() might lead to unwanted results in situations with a lot of unclear region overlaps by failing to get the original region."
    GUI.elms["RRM"..tabIndex].tooltip = "Choose over which track to route the newly created regions in the region render matrix.\n\n'Master' routes over the Master-Track.\n'First common Parent' routes over the first found parent of all selected items (without any selected items on it) or the Master if no parent can be found.\n'Highest common Parent' uses the highest common parent of all selected items or the Master if no parent can be found.\n'First parent per item' routes over all parent tracks of any items.\n'Each Track' only routes over a track if the track has items from the selection on it.\n'None' doesn't set a link in the RRM."
    GUI.elms["Create"..tabIndex].tooltip = "Toogle if the region tab should even be created."
   

    redrawColFrames(tabIndex)
end

-- TODO ja die main arbeit halt nich
-- global because called from various functions
function redrawAll ()
    GUI.elms_hide[5] = true

    GUI.New("Cat1", "Label", {
        z = 2,
        x = 5,
        y = 5,
        caption = "Adjust Region Length and Distance",
        font = 2,
        color = "elm_fill",
        bg = "elm_frame",
        shadow = true
    })

    -- GENERAL GUI
    GUI.New("Menu", "Menubar", {
        z = 3,
        x = 0,
        y = 0,
        w = 912.0,
        h = 20.0,
        menus = menuTableGUI,
        font = 2,
        col_txt = "txt",
        col_bg = "elm_frame",
        col_over = "elm_fill",
        fullwidth = true
    })

    GUI.New("Button_AddTab", "Button", {
        z = 3,
        x = 48,
        y = 31,
        w = 20,
        h = 20,
        caption = "+",
        font = 3,
        col_txt = "txt",
        col_fill = "elm_frame",
        func = addTab
    })

    GUI.New("Button_RemoveTab", "Button", {
        z = 3,
        x = 16,
        y = 31,
        w = 20,
        h = 20,
        caption = "-",
        font = 3,
        col_txt = "txt",
        col_fill = "elm_frame",
        func = removeTab
    })

    setTabNumButtonVisibility()

    -- TODO adjust position
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

    --------------------
    -- RUN & SETTINGS --
    --------------------
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

    -- TODO adjust position & z layer
    GUI.New("TimeBetween", "Slider", {
        z = 15,
        x = 144,
        y = 144,
        w = 150,
        caption = "Distance between (s)",
        min = timeSlidersVals.general.TimeBetween.min,
        max = timeSlidersVals.general.TimeBetween.max,
        defaults = {timeSlidersVals.general.TimeBetween.defaults},
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

    GUI.New("TimeInclude", "Slider", {
        z = 15,
        x = 144,
        y = 192,
        w = 150,
        caption = "Group tolerance (s)",
        min = timeSlidersVals.general.TimeInclude.min,
        max = timeSlidersVals.general.TimeInclude.max,
        defaults = timeSlidersVals.general.TimeInclude.defaults,
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

    -- seperation frames - visualisation only
    -- TODO adjust position and z layer
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

    -- TODO Copy to all tab-sliders(?)
    for i = 1, #focusArray do
        local currTextboxName = focusArray[i]
        local tempTextbox = GUI.elms[currTextboxName]
        function tempTextbox:lostfocus()
            GUI.Textbox.lostfocus(self)
            setSliderSize(string.gsub(currTextboxName, "_Text", ""),GUI.Val(currTextboxName))
        end
    end

    function GUI.elms.Preview:onmouseup()
        GUI.Checklist.onmouseup(self)
        joshnt_UniqueRegions.previewTimeSelection = GUI.Val("Preview")
        if joshnt_UniqueRegions.previewTimeSelection then adjustTimeselection() end
    end

    -- TODO Adjust z
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

    function GUI.elms.TimeBetween:onmouseup()
        GUI.Slider.onmouseup(self)
        GUI.Val("TimeBetween_Text", GUI.Val("TimeBetween"))
    end

    function GUI.elms.TimeInclude:onmouseup()
        GUI.Slider.onmouseup(self)
        GUI.Val("TimeInclude_Text", GUI.Val("TimeInclude"))
    end

    -- TODO Tooltips content check and name
    -- Tooltips
    GUI.elms.TimeBetween_Text.tooltip = "Corresponding textinput to slider to the left.\nIf input is out of slider bounds, slider gets rescaled automatically.\nUse 'TAB' to cycle between all text-input boxes."
    GUI.elms.TimeInclude_Text.tooltip = "Corresponding textinput to slider to the left.\nIf input is out of slider bounds, slider gets rescaled automatically.\nUse 'TAB' to cycle between all text-input boxes."
    GUI.elms.Preview.tooltip = "Use REAPER's 'Time-Selection' to visualize the first group's region bounds.\nRefreshes on time-value changes; to refresh after a item-selection change, press 'R'."
    GUI.elms.RepositionToggle.tooltip = "Toggle whether the selected items should get moved to ensure the region distance set with the slider to the left."
    GUI.elms.isolateItems.tooltip = "Sets if any and which items should be moved to avoid overlaps of the selected items with non-selected items.\nWARNING: Not moving items if there are other items on the track with the selected items may result in deleting those items between."
    GUI.elms.Run.tooltip = "Execute the script with the current Settings.\nShortcut - 'Shift + RETURN'"
    GUI.elms.Button_AddTab.tooltip = "Add a new region rule tab.\nDisappears if maximum of possible regions is reached."
    GUI.elms.Button_RemoveTab.tooltip = "Removes current selected tab.\nDisappears if only one region tab exists."
    GUI.elms.TimeBetween.tooltip = "Adjust how many seconds between each item group's region should be empty."
    GUI.elms.TimeInclude.tooltip = "Adjust how far away from each other items can be to still be considered as one 'group'.\n\nE.g. 0 means only actually overlapping items count as one group.\n1 means items within 1 second of each others start/ end still count as one group."


    redrawColFrames()
    refreshMenu()
    redrawTabs()
    for i = 1, numTabs do
        redrawTabContent(i)
    end
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

-- load values from CORE to GUI interface
function refreshGUIValues()
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

local menuFunctions = {
    file = {
        initSettings = function()
            local retval = reaper.MB("Are you sure you want to initialize your current settings?\nThis action is irreversible and cannot be undone.", "Unique Regions Warning",4)
            if retval == 6 then
                joshnt_UniqueRegions.Init()
                redrawAll()
                refreshGUIValues()
            end
        end, 
        exportSettingsClipboard = function()
            updateUserValues()
            joshnt_UniqueRegions.settingsToClipboard()
        end,
        importSettingsClipboard = function()
            joshnt_UniqueRegions.settingsFromClipboard()
            refreshGUIValues()
        end,
        exportSettingsFile = function()
            updateUserValues()
            joshnt_UniqueRegions.writeSettingsToFile()
        end,
        importSettingsFile = function()
            joshnt_UniqueRegions.readSettingsFromFile()
            refreshGUIValues()
        end,
        saveDefaults = function()
            updateUserValues()
            joshnt_UniqueRegions.saveDefaults()
        end,
        loadDefaults = function()
            joshnt_UniqueRegions.getDefaults()
            refreshGUIValues()
        end,

    },
    wildcards = {
        leadingZero1 = function()
            joshnt_UniqueRegions.leadingZero = 1
            refreshMenu()
        end,
        leadingZero2 = function()
            joshnt_UniqueRegions.leadingZero = 2
            refreshMenu()
        end,
        leadingZero3 = function()
            joshnt_UniqueRegions.leadingZero = 3
            refreshMenu()
        end,
        leadingZero4 = function()
            joshnt_UniqueRegions.leadingZero = 4
            refreshMenu()
        end,
        -- TODO Add window open function for custom wildcard windows (with texteditor etc.)
        custom1 = function()
        end,
        custom2 = function()
        end,
        custom3 = function()
        end,
        custom4 = function()
        end,
        custom5 = function()
        end,
        -- TODO add window open function for wildcard info
        info = function()
        end
    },
    other = {
        previewTimeSel = function()
            joshnt_UniqueRegions.previewTimeSelection = not joshnt_UniqueRegions.previewTimeSelection
            adjustTimeselection()
            refreshMenu()
        end,
        lockItems = function()
            joshnt_UniqueRegions.lockBoolUser = not joshnt_UniqueRegions.lockBoolUser
            refreshMenu()
        end,
        closeGUI = function()
            joshnt_UniqueRegions.closeGUI = not joshnt_UniqueRegions.closeGUI
            refreshMenu()
        end
    },
    help = {
        -- TODO add shortcut list window
        shortcutList = function()
        end,
        -- Troll only
        quickStart = function()
            pressedHelp = math.max(pressedHelp, 1)
            refreshMenu()
        end,
        documentation = function()
            pressedHelp = math.max(pressedHelp, 2)
            refreshMenu()
        end,
        manual = function()
            pressedHelp = math.max(pressedHelp, 3)
            refreshMenu()
        end, 
        help = function()
            reaper.CF_SetClipboard("https://youtu.be/N4KvafPbauw?si=ib6lRftGceo-TcMH")
            reaper.MB("Here you can find a YouTube-Video with further help: \n\n https://youtu.be/N4KvafPbauw?si=ib6lRftGceo-TcMH \n\n(Copied to your clipboard)", "Help", 0)
            pressedHelp = math.max(pressedHelp, 4)
            refreshMenu()
        end,
        reportIssue = function()
            reaper.ClearConsole()
            reaper.ShowConsoleMsg("Wow you're really invested in trying to understand that weird thing here...")
            refreshMenu()
        end
    }
}

-- public weil braucht vorheriges array aber wird auch von diesem gecalled
function refreshMenu()
    menuTableGUI = {
        
        -- Index 1
        {title = "File", options = {
        
            -- Menu item                        Function to run when clicked
            {"New/ Initialize",                 menuFunctions.file.initSettings},
            {""},
            {"Save as default",                 menuFunctions.file.saveDefaults},
            {"Load default",                    menuFunctions.file.loadDefaults},
            {""},
            {"Export to Clipboard",             menuFunctions.file.exportSettingsClipboard},
            {"Export to File",                  menuFunctions.file.exportSettingsFile},
            {""},
            {"Import from Clipboard",           menuFunctions.file.importSettingsClipboard},
            {"Import from File",                menuFunctions.file.importSettingsFile}
            
        }},
        
        -- Index 2
        {title = "Wildcards", options = {
        
            -- Menu item            Function to run when clicked
            {">Open Custom Wildcard Setting for '/C'"},
                {"Table 1",             menuFunctions.wildcards.custom1},
                {"Table 2",             menuFunctions.wildcards.custom2},
                {"Table 3",             menuFunctions.wildcards.custom3},
                {"Table 4",             menuFunctions.wildcards.custom4},
                {"<Table 5",            menuFunctions.wildcards.custom5},
            {">Add leading zero for '/E'"},
                {"None",                menuFunctions.wildcards.leadingZero1},
                {"2 digits",            menuFunctions.wildcards.leadingZero2},
                {"3 digits",            menuFunctions.wildcards.leadingZero3},
                {"<4 digits",           menuFunctions.wildcards.leadingZero4},
                {"Wildcard Info...",    menuFunctions.wildcards.info}            
        }},

        -- Index 3
        {title = "Other", options = {
        
            -- Menu item            Function to run when clicked
            {"Preview Time-Settings with Time-Selection",               menuFunctions.other.previewTimeSel},
            {"Lock items after execution",                              menuFunctions.other.lockItems},
            {"Close GUI after execution",                               menuFunctions.other.closeGUI}
        }},
        -- Index 4
        {title = "Help", options = {
        
            -- Menu item            Function to run when clicked
            {"Shortcut List",                   menuFunctions.help.shortcutList},
            {"Quick Start Guide...",            menuFunctions.help.quickStart}
        }},
    }

    -- if any custom wildcards set in table, check table
    for i = 1, 5 do
        if joshnt_UniqueRegions.customWildCard[i][1] then
            menuTableGUI[2].options[i+1][1] = "!"..menuTableGUI[2].options[i+1][1]
        end
    end

    -- check correct leading zero option
    menuTableGUI[2].options[joshnt_UniqueRegions.leadingZero + 7][1] =  "!"..menuTableGUI[2].options[joshnt_UniqueRegions.leadingZero + 7][1]

    -- check additional options if set
    if joshnt_UniqueRegions.previewTimeSelection then menuTableGUI[3].options[1][1] =  "!"..menuTableGUI[3].options[1][1] end
    if joshnt_UniqueRegions.lockBoolUser then menuTableGUI[3].options[2][1] =  "!"..menuTableGUI[3].options[2][1] end
    if joshnt_UniqueRegions.closeGUI then menuTableGUI[3].options[3][1] =  "!"..menuTableGUI[3].options[3][1] end

    if pressedHelp >= 1 then
        menuTableGUI[4].options[2][1] =  "#"..menuTableGUI[4].options[2][1]
        menuTableGUI[4].options[3] =  {"Documentation...", menuFunctions.help.documentation}
    end
    if pressedHelp >= 2 then
        menuTableGUI[4].options[3][1] =  "#"..menuTableGUI[4].options[3][1]
        menuTableGUI[4].options[4] =  {"Manual...", menuFunctions.help.manual}
    end
    if pressedHelp >= 3 then
        menuTableGUI[4].options[4][1] =  "#"..menuTableGUI[4].options[4][1]
        menuTableGUI[4].options[5] =  {"Help!", menuFunctions.help.help}
    end
    if pressedHelp >= 4 then
        menuTableGUI[4].options[5][1] =  "#"..menuTableGUI[4].options[5][1]
        menuTableGUI[4].options[6] =  {"Report Issue", menuFunctions.help.reportIssue}
        pressedHelp = 0
    end

    -- TODO Add actual menu name
    GUI.Val("my_menubar", menuTableGUI)
end

local function init()
    joshnt_UniqueRegions.getDefaults()
    -- TODO on new rgn tab, create new rgn color; delete on tab delete (?)
    GUI.colors["Col_1"] = GUI.colors["wnd_bg"] 
    numTabs = joshnt.clamp(#joshnt_UniqueRegions.allRgnArray, numTabsMax, numTabsMin)
    redrawAll()
    refreshGUIValues()
    -- TODO refresh general slider & pro region time before time after; evtl auslagern als gebüpndelte function
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