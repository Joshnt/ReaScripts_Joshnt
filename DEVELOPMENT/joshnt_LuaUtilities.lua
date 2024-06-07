-- @description Adding own functions and functionalities as lua-functions
-- @version 1.0
-- @author Joshnt
-- @about
--    Credits to Aaron Cendan https://aaroncendan.me - I partly straight up copied code from him; as well thanks for the awesome work in the scripting domain of reaper!


joshnt = {}

function joshnt.version()
    local file = io.open((reaper.GetResourcePath()..'/Scripts/ReaScripts_Joshnt/DEVELOPMENT/joshnt_LuaUtilities.lua'):gsub('\\','/'),"r")
    local vers_header = "-- @version "
    io.input(file)
    local t = 0
    for line in io.lines() do
        if line:find(vers_header) then
        t = line:gsub(vers_header,"")
        break
        end
    end
    io.close(file)
    return tonumber(t)
end

-----------------
----- ITEMS -----
-----------------

-- get start and end of selected items
function startAndEndOfSelectedItems()
    local itemsInTimeSelection = r.CountSelectedMediaItems(0)
    local selItemsStart = 0
    local selItemsEnd = 0
    for i = 0, itemsInTimeSelection - 1 do
        local itemTempTime = r.GetSelectedMediaItem(0, i)
        if itemTempTime then
            local it_len = r.GetMediaItemInfo_Value(itemTempTime, 'D_LENGTH')
            local it_start = reaper.GetMediaItemInfo_Value(itemTempTime, "D_POSITION")
            local it_end = it_start + it_len
            if i == 0 then
              selItemsStart = it_start
              selItemsEnd = it_end
            else
              selItemsStart = math.min(selItemsStart, it_start)
              selItemsEnd = math.max(selItemsEnd, it_end)
            end
        end
    end
    return selItemsStart, selItemsEnd
end

-- save selected items in a table to recall later (see reselectItems)
function saveItemSelection()
    local itemTable = {}
    local numSelItems_TEMP = r.CountSelectedMediaItems(0)
    for i = 0, numSelItems_TEMP - 1 do
      local SelItem_TEMP = r.GetSelectedMediaItem(0, i)
      if SelItem_TEMP then
        table.insert(itemTable,SelItem_TEMP)
      end
    end
    return itemTable
end

-- reselect a table of items
function reselectItems(itemTable)
    local numSelItems_TEMP = #itemTable
    for i = 0, numSelItems_TEMP do
      local SelItem_TEMP = itemTable[i]
      if SelItem_TEMP then
        if reaper.ValidatePtr(SelItem_TEMP, "MediaItem*") then
          reaper.SetMediaItemSelected(SelItem_TEMP, true)
        end
      end
    end
end

-- unselect Items given in a table (to have e.g. everything but items x selected)
function unselectItems(itemTable)
    local numSelItems_TEMP = #itemTable
    for i = 0, numSelItems_TEMP do
      local SelItem_TEMP = itemTable[i]
      if SelItem_TEMP then
          if reaper.ValidatePtr(SelItem_TEMP, "MediaItem*") then
            reaper.SetMediaItemSelected(SelItem_TEMP, false)
          end
      end
    end
end

------------------
----- TRACKS -----
------------------

-- Function to unselect all tracks
function unselectAllTracks()
    local num_tracks = reaper.CountTracks(0) -- Get the total number of tracks in the project
    for i = 0, num_tracks - 1 do
        local track = reaper.GetTrack(0, i) -- Get each track by index
        reaper.SetTrackSelected(track, false) -- Set the track as unselected
    end
end

-- !!ADJUST!
-- Function to check for overlapping regions with selected items 
local function checkOverlapWithRegions(boolReturnRegionBounds)

    local proj = r.EnumProjects(-1, "")
    local numRegions = r.CountProjectMarkers(proj, 0)
    if numRegions == 0 then
        if boolReturnRegionBounds then
          return -1, -1
        else  
          return false
        end
    end
    local numItems_TEMP = reaper.CountSelectedMediaItems()

    local overlapDetected = false
    local regionStart = -1
    local regionEnd = -1
    
    for i = 0, numItems_TEMP - 1 do
        local item = r.GetSelectedMediaItem(0, i)
        local itemStart = r.GetMediaItemInfo_Value(item, "D_POSITION")
        local itemEnd = itemStart + r.GetMediaItemInfo_Value(item, "D_LENGTH")

        for j = 0, numRegions - 1 do
            local _, isrgn, rgnstart, rgnend = r.EnumProjectMarkers( j)
            if isrgn then
                if itemStart < rgnend and itemEnd > rgnstart then
                    overlapDetected = true
                    regionStart = rgnstart
                    regionEnd = rgnend
                    break
                end
            end
        end

        if overlapDetected then
            break
        end
    end
  if boolReturnRegionBounds then
    return regionStart, regionEnd
  else  
    return overlapDetected
  end
end

----------------
----- USER -----
----------------

-- Convert from CSV string to table (converts a single line of a CSV file) - for reading user input
function joshnt.fromCSV(s)
    s = s .. ','        -- ending comma
    local q = {}        -- table to collect fields
    local fieldstart = 1
    repeat
        -- next field is quoted? (start with `"'?)
        if string.find(s, '^"', fieldstart) then
            local a, c
            local i  = fieldstart
            repeat
                -- find closing quote
                a, i, c = string.find(s, '"("?)', i+1)
            until c ~= '"'    -- quote not followed by quote?
            if not i then error('unmatched "') end
            local f = string.sub(s, fieldstart+1, i-1)
            table.insert(q, (string.gsub(f, '""', '"')))
            fieldstart = string.find(s, ',', i) + 1
        else                -- unquoted; find next comma
            local nexti = string.find(s, ',', fieldstart)
            table.insert(q, string.sub(s, fieldstart, nexti-1))
            fieldstart = nexti + 1
        end
    until fieldstart > string.len(s)
    return q
end

-----------------
----- DEBUG -----
-----------------

--DEBUG function
function pauseForUserInput(prompt)
    local ok, input = reaper.GetUserInputs(prompt, 1, "Press OK to continue", "")
    if not ok then
        -- User canceled the input dialog; you can handle it if needed
        reaper.ShowConsoleMsg("Script paused, user canceled the input.\n")
    end
end

return joshnt