--    Changes Fade closest to mouse on selected item to S-Shape or Log-Shape -- credits to me2beats


if reaper.NamedCommandLookup("_SWS_ABOUT") == 0 then reaper.MB("This script requires the SWS Extension. Please install it from here:\n\nhttps://www.sws-extension.org/","Error",0) return end

local function nothing() end; local function bla() reaper.defer(nothing) end

local window, segment, details = reaper.BR_GetMouseCursorContext()
local mouse = reaper.BR_GetMouseCursorContext_Position()
if not mouse or mouse ==-1 then bla() return end

local mainItem = reaper.BR_GetMouseCursorContext_Item()
if not mainItem or mainItem ==-1 then bla() return end

local numItems = reaper.CountSelectedMediaItems()
if not numItems or numItems ==0 then bla() return end

local mainItemPos = reaper.GetMediaItemInfo_Value(mainItem, 'D_POSITION')
local mainItemFadeInPos = mainItemPos + reaper.GetMediaItemInfo_Value(mainItem, 'D_FADEINLEN')
local mainItemFadeOutPos = mainItemPos + reaper.GetMediaItemInfo_Value(mainItem, 'D_LENGTH') - reaper.GetMediaItemInfo_Value(mainItem, 'D_FADEOUTLEN')
local changeStart = (mainItemFadeOutPos - mouse) > (mouse - mainItemFadeInPos)
local fadeShape = ""

if changeStart then
  fadeShape = "C_FADEINSHAPE"
else
  fadeShape = "C_FADEOUTSHAPE"
end

local mainFadeCurve = reaper.GetMediaItemInfo_Value(mainItem, fadeShape)


reaper.Undo_BeginBlock() reaper.PreventUIRefresh(1)

for i = 0, numItems do
  local item = reaper.GetSelectedMediaItem(0,i)
  if item then
    if mainFadeCurve < 5 then
      reaper.SetMediaItemInfo_Value(item, fadeShape, 5)
    else
      reaper.SetMediaItemInfo_Value(item, fadeShape, 1)
    end
  end
end

reaper.PreventUIRefresh(-1) 
reaper.UpdateArrange()
reaper.Undo_EndBlock('Change Item Fades', -1)

