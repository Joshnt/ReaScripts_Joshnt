-- @noindex

joshnt_autoColor = {}

joshnt_autoColor.priorityOrderArray = {}
joshnt_autoColor.colors = {
    reverse = nil,
    FX = nil,
    pitch = nil,
    rate = nil,
    gain = nil,
    volume = nil,
    combined = nil,
    name1 = nil,
    name2 = nil,
    name3 = nil,
    name4 = nil,
    name5 = nil,
    FXnamed1 = nil,
    FXnamed2 = nil,
    FXnamed3 = nil,
    FXnamed4 = nil,
    FXnamed5 = nil
}
-- if gradient, save low value bound and high value bound
joshnt_autoColor.valueRanges = {
    pitch = nil,
    rate = nil,
    gain = nil,
    volume = nil,
    combined = nil
}
joshnt_autoColor.dontOverwrite = false
joshnt_autoColor.recoloredItems = {}
-- save names in synatx priority = {name, compare}; e.g. 1 = {"REC","contains"}
joshnt_autoColor.names = {}
joshnt_autoColor.FXnames = {}
-- Define property detection/ coloring
joshnt_autoColor.propertyColoring = {
    name1 = 
        function(item)
            local boolMatch = false
            local compareString = joshnt_autoColor.names[1][1]
            local compare = joshnt_autoColor.names[1][2]
            if compare == "contains" then
                boolMatch = joshnt_autoColor.isStringInItemName(item,compareString)
            elseif compare == "is exactly" then
                boolMatch = joshnt_autoColor.isStringExactlyItemName(item, compareString)
            elseif compare == "is not containing" then
                boolMatch = joshnt_autoColor.isStringInItemName(item, compareString) == false
            elseif compare == "is not" then
                boolMatch = joshnt_autoColor.isStringExactlyItemName(item, compareString) == false
            end
            if boolMatch == true then
                local colorTEMP = joshnt_autoColor.colors["name1"]
                if colorTEMP == "brighter" then colorTEMP = joshnt_autoColor.getBrighter(item) 
                elseif colorTEMP == "darker" then colorTEMP = joshnt_autoColor.getDarker(item) end
                reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", colorTEMP | 0x1000000)  -- Set item color
                return true
            
            else return false end
        end,
    name2 = 
        function(item)
            local boolMatch = false
            local compareString = joshnt_autoColor.names[2][1]
            local compare = joshnt_autoColor.names[2][2]
            if compare == "contains" then
                boolMatch = joshnt_autoColor.isStringInItemName(item,compareString)
            elseif compare == "is exactly" then
                boolMatch = joshnt_autoColor.isStringExactlyItemName(item, compareString)
            elseif compare == "is not containing" then
                boolMatch = joshnt_autoColor.isStringInItemName(item, compareString) == false
            elseif compare == "is not" then
                boolMatch = joshnt_autoColor.isStringExactlyItemName(item, compareString) == false
            end
            if boolMatch == true then
                local colorTEMP = joshnt_autoColor.colors["name2"]
                if colorTEMP == "brighter" then colorTEMP = joshnt_autoColor.getBrighter(item) 
                elseif colorTEMP == "darker" then colorTEMP = joshnt_autoColor.getDarker(item) end
                reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", colorTEMP | 0x1000000)  -- Set item color
                return true
            
            else return false end
        end,
    name3 = 
        function(item)
            local boolMatch = false
            local compareString = joshnt_autoColor.names[3][1]
            local compare = joshnt_autoColor.names[3][2]
            if compare == "contains" then
                boolMatch = joshnt_autoColor.isStringInItemName(item,compareString)
            elseif compare == "is exactly" then
                boolMatch = joshnt_autoColor.isStringExactlyItemName(item, compareString)
            elseif compare == "is not containing" then
                boolMatch = joshnt_autoColor.isStringInItemName(item, compareString) == false
            elseif compare == "is not" then
                boolMatch = joshnt_autoColor.isStringExactlyItemName(item, compareString) == false
            end
            if boolMatch == true then
                local colorTEMP = joshnt_autoColor.colors["name3"]
                if colorTEMP == "brighter" then colorTEMP = joshnt_autoColor.getBrighter(item) 
                elseif colorTEMP == "darker" then colorTEMP = joshnt_autoColor.getDarker(item) end
                reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", colorTEMP | 0x1000000)  -- Set item color
                return true
            
            else return false end
        end,
    name4 = 
        function(item)
            local boolMatch = false
            local compareString = joshnt_autoColor.names[4][1]
            local compare = joshnt_autoColor.names[4][2]
            if compare == "contains" then
                boolMatch = joshnt_autoColor.isStringInItemName(item,compareString)
            elseif compare == "is exactly" then
                boolMatch = joshnt_autoColor.isStringExactlyItemName(item, compareString)
            elseif compare == "is not containing" then
                boolMatch = joshnt_autoColor.isStringInItemName(item, compareString) == false
            elseif compare == "is not" then
                boolMatch = joshnt_autoColor.isStringExactlyItemName(item, compareString) == false
            end
            if boolMatch == true then
                local colorTEMP = joshnt_autoColor.colors["name4"]
                if colorTEMP == "brighter" then colorTEMP = joshnt_autoColor.getBrighter(item) 
                elseif colorTEMP == "darker" then colorTEMP = joshnt_autoColor.getDarker(item) end
                reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", colorTEMP | 0x1000000)  -- Set item color
                return true
            
            else return false end
        end,
    name5 = 
        function(item)
            local boolMatch = false
            local compareString = joshnt_autoColor.names[5][1]
            local compare = joshnt_autoColor.names[5][2]
            if compare == "contains" then
                boolMatch = joshnt_autoColor.isStringInItemName(item,compareString)
            elseif compare == "is exactly" then
                boolMatch = joshnt_autoColor.isStringExactlyItemName(item, compareString)
            elseif compare == "is not containing" then
                boolMatch = joshnt_autoColor.isStringInItemName(item, compareString) == false
            elseif compare == "is not" then
                boolMatch = joshnt_autoColor.isStringExactlyItemName(item, compareString) == false
            end
            if boolMatch == true then
                local colorTEMP = joshnt_autoColor.colors["name5"]
                if colorTEMP == "brighter" then colorTEMP = joshnt_autoColor.getBrighter(item) 
                elseif colorTEMP == "darker" then colorTEMP = joshnt_autoColor.getDarker(item) end
                reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", colorTEMP | 0x1000000)  -- Set item color
                return true
            
            else return false end
        end,
    reverse = 
        function(item) 
            if joshnt_autoColor.isItemReversed(item) == true then
                local colorTEMP = joshnt_autoColor.colors["reverse"]
                if colorTEMP == "brighter" then colorTEMP = joshnt_autoColor.getBrighter(item) 
                elseif colorTEMP == "darker" then colorTEMP = joshnt_autoColor.getDarker(item) end
                reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", colorTEMP | 0x1000000)  -- Set item color
                return true
            else return false end
        end,
    FX = 
        function(item) 
            if joshnt_autoColor.itemHasFX(item) then
                local colorTEMP = joshnt_autoColor.colors["FX"]
                if colorTEMP == "brighter" then colorTEMP = joshnt_autoColor.getBrighter(item) 
                elseif colorTEMP == "darker" then colorTEMP = joshnt_autoColor.getDarker(item) end
                reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", colorTEMP | 0x1000000)  -- Set item color
                return true
            else return false end
        end,
    FXnamed1 = 
        function(item) 
            local compareString = joshnt_autoColor.FXnames[1]
            if joshnt_autoColor.itemHasnamedFX(item, compareString) then
                local colorTEMP = joshnt_autoColor.colors["FXnamed1"]
                if colorTEMP == "brighter" then colorTEMP = joshnt_autoColor.getBrighter(item) 
                elseif colorTEMP == "darker" then colorTEMP = joshnt_autoColor.getDarker(item) end
                reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", colorTEMP | 0x1000000)  -- Set item color
                return true
            else return false end
        end,
    FXnamed2 = 
    function(item) 
        local compareString = joshnt_autoColor.FXnames[2]
        if joshnt_autoColor.itemHasnamedFX(item, compareString) then
            local colorTEMP = joshnt_autoColor.colors["FXnamed2"]
            if colorTEMP == "brighter" then colorTEMP = joshnt_autoColor.getBrighter(item) 
            elseif colorTEMP == "darker" then colorTEMP = joshnt_autoColor.getDarker(item) end
            reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", colorTEMP | 0x1000000)  -- Set item color
            return true
        else return false end
    end,
    FXnamed3 = 
    function(item) 
        local compareString = joshnt_autoColor.FXnames[3]
        if joshnt_autoColor.itemHasnamedFX(item, compareString) then
            local colorTEMP = joshnt_autoColor.colors["FXnamed3"]
            if colorTEMP == "brighter" then colorTEMP = joshnt_autoColor.getBrighter(item) 
            elseif colorTEMP == "darker" then colorTEMP = joshnt_autoColor.getDarker(item) end
            reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", colorTEMP | 0x1000000)  -- Set item color
            return true
        else return false end
    end,
    FXnamed4 = 
    function(item) 
        local compareString = joshnt_autoColor.FXnames[4]
        if joshnt_autoColor.itemHasnamedFX(item, compareString) then
            local colorTEMP = joshnt_autoColor.colors["FXnamed4"]
            if colorTEMP == "brighter" then colorTEMP = joshnt_autoColor.getBrighter(item) 
            elseif colorTEMP == "darker" then colorTEMP = joshnt_autoColor.getDarker(item) end
            reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", colorTEMP | 0x1000000)  -- Set item color
            return true
        else return false end
    end,
    FXnamed5 = 
    function(item) 
        local compareString = joshnt_autoColor.FXnames[5]
        if joshnt_autoColor.itemHasnamedFX(item, compareString) then
            local colorTEMP = joshnt_autoColor.colors["FXnamed5"]
            if colorTEMP == "brighter" then colorTEMP = joshnt_autoColor.getBrighter(item) 
            elseif colorTEMP == "darker" then colorTEMP = joshnt_autoColor.getDarker(item) end
            reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", colorTEMP | 0x1000000)  -- Set item color
            return true
        else return false end
    end,
    pitch = 
        function(item) 
            local pitch = joshnt.getItemPropertyPitch_WithRatePitch(item)
            if pitch ~= 0 and pitch ~= nil  then
                local colorTEMP = joshnt_autoColor.colors["pitch"]
                if colorTEMP == "brighter" then colorTEMP = joshnt_autoColor.getBrighter(item) 
                elseif colorTEMP == "darker" then colorTEMP = joshnt_autoColor.getDarker(item) 
                elseif type(colorTEMP) == "table" then colorTEMP = joshnt_autoColor.getColorFromRange(colorTEMP[1], colorTEMP[2],joshnt_autoColor.valueRanges["pitch"],pitch,item) end

                reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", colorTEMP | 0x1000000)  -- Set item color
                return true
            else return false end
        end,
    rate = 
        function(item) 
            local rate = joshnt.getItemPropertyRate(item)
            if rate ~= 1 and rate ~= nil then
                local colorTEMP = joshnt_autoColor.colors["rate"]
                if colorTEMP == "brighter" then colorTEMP = joshnt_autoColor.getBrighter(item) 
                elseif colorTEMP == "darker" then colorTEMP = joshnt_autoColor.getDarker(item) 
                elseif type(colorTEMP) == "table" then colorTEMP = joshnt_autoColor.getColorFromRange(colorTEMP[1], colorTEMP[2],joshnt_autoColor.valueRanges["rate"],rate,item) end

                reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", colorTEMP | 0x1000000)  -- Set item color
                return true
            else return false end
        end,
    gain = 
        function(item) 
            local itemGain = reaper.GetMediaItemInfo_Value(item, "D_VOL")
            if itemGain ~= 1 and itemGain ~= nil then
                local colorTEMP = joshnt_autoColor.colors["gain"]
                itemGain = joshnt.getVolumeAsDB(itemGain)
                if colorTEMP == "brighter" then colorTEMP = joshnt_autoColor.getBrighter(item) 
                elseif colorTEMP == "darker" then colorTEMP = joshnt_autoColor.getDarker(item)
                elseif type(colorTEMP) == "table" then colorTEMP = joshnt_autoColor.getColorFromRange(colorTEMP[1], colorTEMP[2],joshnt_autoColor.valueRanges["gain"],itemGain,item) end

                reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", colorTEMP | 0x1000000)  -- Set item color
                return true
            else return false end
        end,
    volume = -- item property volume (f2)
        function(item) 
            local itemVol = joshnt.getItemPropertyVolume(item)
            if itemVol ~= 1 and itemVol ~= nil then
                local colorTEMP = joshnt_autoColor.colors["volume"]
                itemVol = joshnt.getVolumeAsDB(itemVol)
                if colorTEMP == "brighter" then colorTEMP = joshnt_autoColor.getBrighter(item) 
                elseif colorTEMP == "darker" then colorTEMP = joshnt_autoColor.getDarker(item) 
                elseif type(colorTEMP) == "table" then colorTEMP = joshnt_autoColor.getColorFromRange(colorTEMP[1], colorTEMP[2],joshnt_autoColor.valueRanges["volume"],itemVol,item) end

                reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", colorTEMP | 0x1000000)  -- Set item color
                return true
            else return false end
        end,
    combined = -- item property volume (f2) + gain
        function(item) 
            local itemVolSum = (joshnt.getItemPropertyVolume(item) + reaper.GetMediaItemInfo_Value(item, "D_VOL"))/2
            if itemVolSum ~= 1 and itemVolSum ~= nil then
                local colorTEMP = joshnt_autoColor.colors["combined"]
                itemVolSum = joshnt.getVolumeAsDB(itemVolSum)
                if colorTEMP == "brighter" then colorTEMP = joshnt_autoColor.getBrighter(item) 
                elseif colorTEMP == "darker" then colorTEMP = joshnt_autoColor.getDarker(item) 
                elseif type(colorTEMP) == "table" then colorTEMP = joshnt_autoColor.getColorFromRange(colorTEMP[1], colorTEMP[2],joshnt_autoColor.valueRanges["combined"],itemVolSum,item) end

                reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", colorTEMP | 0x1000000)  -- Set item color
                return true
            else return false end
    end,
    colorDefault = 
        function(item) 
            reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", 0)
        end
}

joshnt_autoColor.defaultColorTrack, joshnt_autoColor.defaultColorTrack_Brighter, joshnt_autoColor.defaultColorTrack_Darker = {}, {},{}
joshnt_autoColor.defaultColorTrack["r"], joshnt_autoColor.defaultColorTrack["g"], joshnt_autoColor.defaultColorTrack["b"] = reaper.ColorFromNative(reaper.GetThemeColor("col_seltrack2", 0))
joshnt_autoColor.defaultColorTrack_Brighter["r"], joshnt_autoColor.defaultColorTrack_Brighter["g"], joshnt_autoColor.defaultColorTrack_Brighter["b"] = math.min(255,joshnt_autoColor.defaultColorTrack["r"] + 60), math.min(255,joshnt_autoColor.defaultColorTrack["g"] + 60), math.min(255, joshnt_autoColor.defaultColorTrack["b"] + 60)
joshnt_autoColor.defaultColorTrack_Darker["r"], joshnt_autoColor.defaultColorTrack_Darker["g"], joshnt_autoColor.defaultColorTrack_Darker["b"] = math.max(0,joshnt_autoColor.defaultColorTrack["r"] - 50), math.max(0,joshnt_autoColor.defaultColorTrack["g"] - 50), math.max(0, joshnt_autoColor.defaultColorTrack["b"] - 50)


function joshnt_autoColor.getBrighter(item)
    local trackColor_Native = reaper.GetTrackColor(reaper.GetMediaItemTrack(item)) -- weird integer value
    if trackColor_Native ~= 0 then
        local trackColor_r, trackColor_g, trackColor_b = reaper.ColorFromNative(trackColor_Native)
        return reaper.ColorToNative(math.min(255,trackColor_r + 50), math.min(255,trackColor_g + 50), math.min(255, trackColor_b + 50)) | 0x1000000
    else
        return reaper.ColorToNative(joshnt_autoColor.defaultColorTrack_Brighter["r"], joshnt_autoColor.defaultColorTrack_Brighter["g"], joshnt_autoColor.defaultColorTrack_Brighter["b"]) | 0x1000000
    end
end

function joshnt_autoColor.getDarker(item)
    local trackColor_Native = reaper.GetTrackColor(reaper.GetMediaItemTrack(item)) -- weird integer value
    if trackColor_Native ~= 0 then
        local trackColor_r, trackColor_g, trackColor_b = reaper.ColorFromNative(trackColor_Native)
        return reaper.ColorToNative(math.max(0,trackColor_r - 50), math.max(0,trackColor_g - 50),  math.max(0, trackColor_b - 50)) | 0x1000000
    else
        return reaper.ColorToNative(joshnt_autoColor.defaultColorTrack_Darker["r"], joshnt_autoColor.defaultColorTrack_Darker["g"], joshnt_autoColor.defaultColorTrack_Darker["b"]) | 0x1000000
    end
end

function joshnt_autoColor.getColorFromRange(colorRangeLow,colorRangeHigh, valueRangeArray, value, item)
    -- Normalize the value within the value range
    local valueRangeLow, valueRangeHigh = valueRangeArray[1], valueRangeArray[2]
    local normalizedVal = (value - valueRangeLow) / (valueRangeHigh - valueRangeLow)

    -- Clamp the normalized value between 0 and 1
    normalizedVal = math.max(0, math.min(1, normalizedVal))
    
    -- Interpolate between the two colors based on the normalized values
    local r1,g1,b1,r2,g2,b2;
    if colorRangeLow == "darker" then r1, g1, b1 = reaper.ColorFromNative(joshnt_autoColor.getDarker(item))
    else r1, g1, b1 = reaper.ColorFromNative(colorRangeLow) end
    if colorRangeHigh == "brighter" or colorRangeHigh == "" or colorRangeHigh == nil then r2, g2, b2 = reaper.ColorFromNative(joshnt_autoColor.getBrighter(item))
    else r2, g2, b2 = reaper.ColorFromNative(colorRangeHigh) end

    local r = r1 + (r2 - r1) * normalizedVal
    local g = g1 + (g2 - g1) * normalizedVal
    local b = b1 + (b2 - b1) * normalizedVal

    return reaper.ColorToNative(math.floor(r), math.floor(g), math.floor(b))
end

function joshnt_autoColor.isItemReversed(item)
    if not item then
        return false
    end

    local take = reaper.GetActiveTake(item)
    if not take then
        return false
    end

    local source = reaper.GetMediaItemTake_Source(take)
    if not source then
        return false
    end

    local retval, start_time, length, is_reversed = reaper.PCM_Source_GetSectionInfo(source)
    
    return is_reversed
end

function joshnt_autoColor.itemHasFX(item)
    if not item then
        return false
    end

    local takeCount = reaper.CountTakes(item)
    for i = 0, takeCount - 1 do
        local take = reaper.GetTake(item, i)
        if take and reaper.TakeFX_GetCount(take) > 0 then
            return true
        end
    end

    return false
end

function joshnt_autoColor.itemHasnamedFX(item, name)
    if not item then
        return false
    end

    local takeCount = reaper.CountTakes(item)
    for i = 0, takeCount - 1 do
        local take = reaper.GetTake(item, i)
        if take then
            local numFX = reaper.TakeFX_GetCount(take)
            for j = 0, numFX -1 do
                local retval, FXname = reaper.TakeFX_GetFXName(take, j)
                if retval and FXname:find(name) then
                    return true
                end
            end
        end
    end

    return false
end

function joshnt_autoColor.isStringInItemName(item, searchString)
    if not item then
        return false
    end

    local take = reaper.GetActiveTake(item)
    if not take then
        return false
    end

    local takeName = reaper.GetTakeName(take)
    
    if takeName:find(searchString) then
        return true
    else
        return false
    end
end

function joshnt_autoColor.isStringExactlyItemName(item, searchString)
    if not item then
        return false
    end

    local take = reaper.GetActiveTake(item)
    if not take then
        return false
    end

    local takeName = reaper.GetTakeName(take)
    
    if takeName == searchString then
        return true
    else
        return false
    end
end

function joshnt_autoColor.main(item)
    for i, action in ipairs(joshnt_autoColor.priorityOrderArray) do
        local retval = joshnt_autoColor.propertyColoring[action](item)
        if retval == true then return end
    end
    joshnt_autoColor.propertyColoring["colorDefault"](item)
end

function joshnt_autoColor.main_dontOverwrite(item)
    for i, action in ipairs(joshnt_autoColor.priorityOrderArray) do
        local retval = joshnt_autoColor.propertyColoring[action](item)
        if retval == true then 
            joshnt_autoColor.recoloredItems[item] = joshnt_autoColor.colors[action] | 0x1000000
            return 
        end
    end
    joshnt_autoColor.propertyColoring["colorDefault"](item)
    joshnt_autoColor.recoloredItems[item] = nil
end

-- call from outside: run function for selected items
function joshnt_autoColor.selItems()
    if reaper.CountSelectedMediaItems() > 0 then
        for i = 0, reaper.CountSelectedMediaItems()-1 do
            -- Get the selected media item
            local item = reaper.GetSelectedMediaItem(0, i)
            if item then
                joshnt_autoColor.main(item)
            end
        end
    end
    reaper.UpdateArrange()
end

-- call from outside: run function for selected items; dont overwrite custom color
function joshnt_autoColor.selItems_dontOverwrite()
    if reaper.CountSelectedMediaItems() > 0 then
        for i = 0, reaper.CountSelectedMediaItems()-1 do
            -- Get the selected media item
            local item = reaper.GetSelectedMediaItem(0, i)
            if item then
                local itemColor_TEMP = reaper.GetMediaItemInfo_Value(item, "I_CUSTOMCOLOR")
                if itemColor_TEMP ~= 0 then
                    if joshnt_autoColor.recoloredItems[item] == itemColor_TEMP or joshnt_autoColor.recoloredItems[item] == true then 
                        joshnt_autoColor.main_dontOverwrite(item) 
                    else
                        joshnt_autoColor.recoloredItems[item] = nil
                    end
                else
                    joshnt_autoColor.main_dontOverwrite(item)
                end
            end
        end
    end
    reaper.UpdateArrange()
end

-- call from outside: run function for all items (potentially very cpu heavy!)
function joshnt_autoColor.allItems()
    if reaper.CountMediaItems(0) > 0 then
        for i = 0, reaper.CountMediaItems(0)-1 do
            -- Get the selected media item
            local item = reaper.GetMediaItem(0, i)
            if item then
                joshnt_autoColor.main(item)
            end
        end
    end 
    reaper.UpdateArrange()
end

-- call from outside to check if all defaults are defined before running
function joshnt_autoColor.checkDefaultsSet()
    if joshnt_autoColor.priorityOrderArray == nil or joshnt_autoColor.priorityOrderArray[1] == nil then 
        reaper.ShowMessageBox("No properties set to color items.\nConsider running 'joshnt_Auto-Color items - Settings GUI.lua'\n\nScript execution cancelled", "Auto-Coloring Error",0) 
        return false
    end
    for i, property in ipairs(joshnt_autoColor.priorityOrderArray) do
        if not joshnt_autoColor.propertyColoring[property] then
            reaper.ShowMessageBox("Invalid property in priorty list: " .. property.."\n\n Script execution cancelled", "Auto-Coloring Error",0)
            return false
        elseif joshnt_autoColor.colors[property] == nil then
            reaper.ShowMessageBox("Color for " .. property.." not defined.\n\nScript execution cancelled", "Auto-Coloring Error",0)
            return false
        elseif type(joshnt_autoColor.colors[property]) == "table" and (joshnt_autoColor.colors[property][1] == nil or joshnt_autoColor.colors[property][2] == nil ) then
            reaper.ShowMessageBox("Color for "..property.." is set to gradient, but no or only one color is defined.\n\nScript execution cancelled", "Auto-Coloring Error",0)
            return false
        elseif type(joshnt_autoColor.colors[property]) == "table" and (joshnt_autoColor.valueRanges[property] == nil or joshnt_autoColor.valueRanges[property][1] == nil or joshnt_autoColor.valueRanges[property][2] == nil) then
            reaper.ShowMessageBox("Color for "..property.." is set to gradient, but no value range is defined.\n\nScript execution cancelled", "Auto-Coloring Error",0)
            return false
        elseif property:find("FXnamed") then
            local nameNum = tonumber(string.sub(property,8,8))
            if not joshnt_autoColor.FXnames[nameNum] or joshnt_autoColor.FXnames[nameNum]=="" or type(joshnt_autoColor.FXnames[nameNum])~="string" then
                reaper.ShowMessageBox("No Name-Setting for "..property.." found.\n\nScript execution cancelled", "Auto-Coloring Error",0)
                return false
            end
        elseif property:find("name") then
            local nameNum = tonumber(string.sub(property,5,5))
            if not joshnt_autoColor.names[nameNum] or joshnt_autoColor.names[nameNum][1]=="" or joshnt_autoColor.names[nameNum][2]=="" or type(joshnt_autoColor.names[nameNum][1])~="string" or type(joshnt_autoColor.names[nameNum][2])~="string" then
                reaper.ShowMessageBox("No Name-Setting for "..property.." found.\n\nScript execution cancelled", "Auto-Coloring Error",0)
                return false
            end
        end
    end
    return true
end

return joshnt_autoColor