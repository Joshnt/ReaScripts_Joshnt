-- @noindex

joshnt_savedItems = {}

-- parameter: i = item, section (string)
function joshnt_savedItems.saveItemToSection(i, section)
    local item = reaper.GetSelectedMediaItem(0, i)
    local track = reaper.GetMediaItemTrack(item)
    local trackIdx = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
    local _, trackName = reaper.GetTrackName(track)
    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local fadeInLen = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
    local fadeOutLen = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
    local fadeInShape = reaper.GetMediaItemInfo_Value(item, "C_FADEINSHAPE")
    local fadeOutShape = reaper.GetMediaItemInfo_Value(item, "C_FADEOUTSHAPE")

    local takeCount = reaper.CountTakes(item)
    local activeTakeIdx = -1
    local takeData = {}

    for t = 0, takeCount - 1 do
        local take = reaper.GetMediaItemTake(item, t)
        if take == reaper.GetActiveTake(item) then
            activeTakeIdx = t
        end

        local vol = reaper.GetMediaItemTakeInfo_Value(take, "D_VOL")
        local pitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
        local rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
        local startOffset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
        local source = reaper.GetMediaItemTake_Source(take)
        local srcPath = reaper.GetMediaSourceFileName(source, "")

        table.insert(takeData, table.concat({srcPath, vol, pitch, rate, startOffset}, "~"))
    end

    local entry = table.concat({
        pos, length, trackIdx, trackName,
        fadeInLen, fadeOutLen,
        fadeInShape, fadeOutShape,
        activeTakeIdx,
        table.concat(takeData, "||")
    }, "|||")

    reaper.SetProjExtState(0, section, tostring(i), entry)
end

function joshnt_savedItems.saveAllItemsToSection(section)
    reaper.SetProjExtState(0, section, "count", "0") -- Clear previous

    local itemCount = reaper.CountMediaItems(0)
    reaper.SelectAllMediaItems(0, true)

    for i = 0, itemCount - 1 do
        joshnt_savedItems.saveItemToSection(i, section)
    end

    reaper.SetProjExtState(0, section, "count", tostring(itemCount))
end

function joshnt_savedItems.saveSelectedItemsToSection(section)
    reaper.SetProjExtState(0, section, "count", "0") -- Clear previous

    local itemCount = reaper.CountSelectedMediaItems(0)

    for i = 0, itemCount - 1 do
        joshnt_savedItems.saveItemToSection(i, section)
    end

    reaper.SetProjExtState(0, section, "count", tostring(itemCount))
end

function joshnt_savedItems.clearSnapshotForSection(section)
    local _, countStr = reaper.GetProjExtState(0, section, "count")
    local count = tonumber(countStr) or 0

    for i = 0, count - 1 do
        reaper.SetProjExtState(0, section, tostring(i), "") -- Clear each saved entry
    end

    reaper.SetProjExtState(0, section, "count", "") -- Clear count entry too
end

function joshnt_savedItems.restoreItemsFromSection(section, boolAddTracks, boolSortByNameIfPossible)

    local _, countStr = reaper.GetProjExtState(0, section, "count")
    local count = tonumber(countStr) or 0
    local restoredItems = {}

    for i = 0, count - 1 do
        local _, entry = reaper.GetProjExtState(0, section, tostring(i))
        if entry ~= "" then
            local parts = {}
            for part in string.gmatch(entry .. "|||", "(.-)|||") do table.insert(parts, part) end

            local pos = tonumber(parts[1])
            local length = tonumber(parts[2])
            local trackIdx = tonumber(parts[3])
            local trackName = parts[4]
            local fadeInLen = tonumber(parts[5])
            local fadeOutLen = tonumber(parts[6])
            local fadeInShape = tonumber(parts[7])
            local fadeOutShape = tonumber(parts[8])
            local activeTakeIdx = tonumber(parts[9])
            -- local takeListStr = parts[10]

            local takeList = {}
            for tStr in string.gmatch(parts[10] .. "||", "(.-)||") do
                local takeParts = {}
                for p in string.gmatch(tStr, "([^~]+)") do
                    table.insert(takeParts, p)
                end
                table.insert(takeList, takeParts)
            end

            local track 
            if trackName ~= "Track "..trackIdx and boolSortByNameIfPossible then
                track = joshnt.findTrackByName(trackName)
            else
                track = reaper.GetTrack(0, trackIdx - 1)
            end
            local item
            if track then
                item = reaper.AddMediaItemToTrack(track)
            else
                if boolAddTracks then
                    local currNumTracks = reaper.CountTracks(0)
                    for j = currNumTracks, trackIdx - 1 do
                        reaper.Main_OnCommand(40702, 0) -- Insert empty track
                    end
                    track = reaper.GetTrack(0, trackIdx - 1)
                    item = reaper.AddMediaItemToTrack(track)
                end
            end
            restoredItems[#restoredItems + 1] = item
            -- Add new media item to track
            reaper.SetMediaItemInfo_Value(item, "D_POSITION", pos)
            reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length)
            reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", fadeInLen)
            reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", fadeOutLen)
            reaper.SetMediaItemInfo_Value(item, "C_FADEINSHAPE", fadeInShape)
            reaper.SetMediaItemInfo_Value(item, "C_FADEOUTSHAPE", fadeOutShape)

            -- Add and set each take
            local lastTake
            for t, takeData in ipairs(takeList) do
                local srcPath = takeData[1]
                local vol = tonumber(takeData[2])
                local pitch = tonumber(takeData[3])
                local rate = tonumber(takeData[4])
                local offset = tonumber(takeData[5])

                local take = reaper.AddTakeToMediaItem(item)
                local source = reaper.PCM_Source_CreateFromFile(srcPath)
                if source then
                    reaper.SetMediaItemTake_Source(take, source)
                    reaper.SetMediaItemTakeInfo_Value(take, "D_VOL", vol)
                    reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", pitch)
                    reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", rate)
                    reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", offset)
                end
                lastTake = take
            end

            -- Set the active take to the correct one
            if activeTakeIdx >= 0 and activeTakeIdx < #takeList then
                reaper.SetMediaItemInfo_Value(item, "I_CURTAKE", activeTakeIdx)
            else
                reaper.SetActiveTake(lastTake)
            end


        end
    end

    reaper.UpdateArrange()

    return restoredItems
end

function joshnt_savedItems.restoreInTimeSelection(section, boolAddTracks, boolSortByNameIfPossible)
    local prevSelItems = joshnt.saveItemSelection()
    reaper.SelectAllMediaItems(0, false)
    local restoredItems = joshnt_savedItems.restoreItemsFromSection(section, boolAddTracks, boolSortByNameIfPossible)
    local itemsOutOfTS = {}
    local tsStart, tsEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    for i = 1, #restoredItems do
        local item = restoredItems[i]
        local itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local itemLen = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        if itemPos < tsEnd and (itemPos + itemLen) > tsStart then
        else itemsOutOfTS[#itemsOutOfTS + 1] = item
        end
    end
    joshnt.reselectItems(itemsOutOfTS)
    reaper.UpdateArrange()
    reaper.Main_OnCommand(40006,0) -- delete selected Items
    reaper.SelectAllMediaItems(0, false)
    joshnt.reselectItems(prevSelItems)
    reaper.UpdateArrange()
end

return joshnt_savedItems

