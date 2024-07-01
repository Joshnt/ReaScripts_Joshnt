-- @description alternative to reaper in-built "Item edit: Trim left edge of item to edit cursor"
-- @version 1.0
-- @author Joshnt
-- @about
--    adapted from X-Raym_Trim left edge of item under mouse or the next one without changing fade-in end.lua
--    as I prefer working with the edit cursor
-- @changelog
--  + init

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

            if item_end > cursorPos then

                local item_FadeLen = reaper.GetMediaItemInfo_Value(item_TEMP, "D_FADEINLEN")
                local item_FadeLenAbsolute = item_pos + item_FadeLen
                local new_fadein = math.max( 0, item_FadeLenAbsolute - cursorPos)

                reaper.BR_SetItemEdges( item_TEMP, cursorPos, item_end )

                reaper.SetMediaItemInfo_Value(item_TEMP, "D_FADEINLEN", new_fadein)

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
