-- @noindex
--    If selected items have no fades, create 1ms fade in and fade out (use to not override fades on multi-selection)

local function nothing() end; local function bla() reaper.defer(nothing) end

local numItems = reaper.CountSelectedMediaItems()
if not numItems or numItems ==0 then bla() return end

reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)

for i = 0, numItems do
  local item = reaper.GetSelectedMediaItem(0,i)
  if item then
    if reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN") == 0 then
      reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", 0.001)
    end
    if reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN") == 0 then
      reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", 0.001)
    end
  end
end

reaper.PreventUIRefresh(-1) 
reaper.UpdateArrange()
reaper.Undo_EndBlock('Change Item Fades', -1)

