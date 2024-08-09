-- @noindex
--    alternative to reaper in-built "Item edit: Trim right edge of item to edit cursor"
--    adapted from X-Raym_Trim right edge of item under mouse or the previous one to mouse cursor without changing fade-out start.lua
--    as I prefer working with the edit cursor


if reaper.NamedCommandLookup("_SWS_ABOUT") == 0 then reaper.MB("This script requires the SWS Extension. Please install it from here:\n\nhttps://www.sws-extension.org/","Error",0) return end

--MAIN
local function main()

    local numItems = reaper.CountSelectedMediaItems()
    if numItems == 0 then 
        local x, y = reaper.GetMousePosition()
        reaper.TrackCtl_SetToolTip( "No selected Items!", x+17, y+17, false )
        return 
    end
        
    local cursorPos = reaper.GetCursorPosition()

    for i = 0, numItems-1 do
        local item_TEMP = reaper.GetSelectedMediaItem(0,i)
        if item_TEMP then
            local item_pos = reaper.GetMediaItemInfo_Value(item_TEMP,"D_POSITION")
            local item_len = reaper.GetMediaItemInfo_Value(item_TEMP,"D_LENGTH")
            local item_end = item_pos + item_len

            if item_pos < cursorPos then

                local item_FadeLen = reaper.GetMediaItemInfo_Value(item_TEMP, "D_FADEOUTLEN")
                local item_FadeLenAbsolute = item_end - item_FadeLen
                local new_fadeout = math.max( 0, cursorPos - item_FadeLenAbsolute)

                reaper.BR_SetItemEdges( item_TEMP, item_pos, cursorPos )

                reaper.SetMediaItemInfo_Value(item_TEMP, "D_FADEOUTLEN", new_fadeout)

            end
        end
    end

end



reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock("Trim right edge of selected item to edit cursor without changing fade-out start", -1)

reaper.UpdateArrange()

reaper.PreventUIRefresh(-1)
