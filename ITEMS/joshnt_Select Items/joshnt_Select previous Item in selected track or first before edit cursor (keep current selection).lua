-- @noindex
--   adapted from acendan's "Select Next Item Track Keep Current Selection"

local countSelTrack = reaper.CountSelectedTracks(0)
if countSelTrack == 0 then return end;

local function main()
    reaper.Undo_BeginBlock();
    reaper.PreventUIRefresh(1);
    local cursorPos = reaper.GetCursorPosition()

    for i = 1,countSelTrack do;
        local track = reaper.GetSelectedTrack(0,i-1);

        local CountTrItem = reaper.CountTrackMediaItems(track);
        local sel2,item2, itemBeforeCursor;
        local selItemOnTrack = false
        for j = 0, CountTrItem-1 do;

            local item = reaper.GetTrackMediaItem(track,j);
            local sel = reaper.GetMediaItemInfo_Value(item,'B_UISEL')
            local posTEMP = reaper.GetMediaItemInfo_Value(item, "D_POSITION")

            if posTEMP < cursorPos then
                itemBeforeCursor = item
            end

            if sel == 1 then
                selItemOnTrack = true
                if sel2 == 0 then
                    reaper.SetMediaItemInfo_Value(item2,'B_UISEL',1);
                    reaper.SetMediaItemInfo_Value(item,'B_UISEL',1);
                    sel = 0;
                end
            end;
            sel2 = sel;
            item2 = item;
        end;
        
        if selItemOnTrack == false and itemBeforeCursor then
            reaper.SetMediaItemInfo_Value(itemBeforeCursor,'B_UISEL',1);
        end

    end;
    reaper.PreventUIRefresh(-1);
    reaper.Undo_EndBlock('Select previous item in selected track',-1);
end

main()


reaper.UpdateArrange();



