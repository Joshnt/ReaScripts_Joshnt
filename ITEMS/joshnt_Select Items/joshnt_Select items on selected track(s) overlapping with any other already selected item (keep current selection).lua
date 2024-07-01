-- @noindex

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

-- para-global variables
local countSelTrack = reaper.CountSelectedTracks(0)
if countSelTrack == 0 then return end;

local function main()
    if reaper.CountSelectedMediaItems(0) == 0 then joshnt.TooltipAtMouse("No items selected!") return end
    local _, itemGroupsStartArray, itemGroupsEndArray = joshnt.getOverlappingItemGroupsOfSelectedItems()

    if not itemGroupsStartArray or not itemGroupsEndArray then joshnt.TooltipAtMouse("Unable to get overlapping item groups") return end

    reaper.Undo_BeginBlock() 

    for i = 1,countSelTrack do;
        local track = reaper.GetSelectedTrack(0,i-1);

        local CountTrItem = reaper.CountTrackMediaItems(track);
        for j = 0, CountTrItem-1 do;

            local item = reaper.GetTrackMediaItem(track,j);
            local posTEMP = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local itemEndTEMP = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH') + posTEMP

            if posTEMP >= itemGroupsEndArray[#itemGroupsEndArray] then -- break wenn item schon nach letzter gruppe ist -> alle anderen sind auch später
                break
            end

            for k = 1, #itemGroupsEndArray do
                if posTEMP < itemGroupsEndArray[k] and itemEndTEMP > itemGroupsStartArray[k] then
                    reaper.SetMediaItemInfo_Value(item,'B_UISEL',1);
                    break
                end
            end
        end

    end

    reaper.Undo_EndBlock('Select Items on selected Track Overlapping with selected items', -1)
end

reaper.PreventUIRefresh(1)
main()
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()