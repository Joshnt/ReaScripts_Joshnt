-- @description Cycle through presets for channel mapper on selected item - accessing unusal channel mappings like in 1/4 to 1/2 out more easily
-- @version 1.0
-- @author Joshnt
-- @about
--    You need to create presets for the channel mapper device for this script to work
--    if you don't have any presets the script only inserts a default channel mapper device    

local function TooltipAtMouse(message)
    local x, y = reaper.GetMousePosition()
    reaper.TrackCtl_SetToolTip(tostring(message), x+17, y+17, false )
  end
  
  local function setNextPresetForChMap(take,chMapInd)
    local retval, numberOfPresets = reaper.TakeFX_GetPresetIndex(take, chMapInd)
    if numberOfPresets ~= 0 and retval ~= -1  then
      local nextPreset = -2
      if numberOfPresets ~= retval+1 then
        nextPreset = (retval +1) %numberOfPresets
      end
      local boolSetFX = reaper.TakeFX_SetPresetByIndex(take, chMapInd, nextPreset)
      if boolSetFX == false then
        TooltipAtMouse("failed to set new preset")
        return -1
      else
        return nextPreset
      end
    elseif numberOfPresets ~= 0 and retval == -1 then
      local boolSetFX = reaper.TakeFX_SetPresetByIndex(take, chMapInd, 0)
      if boolSetFX == false then
        TooltipAtMouse("failed to set new preset")
        return -1
      end
      return 0
    elseif numberOfPresets == 0 then
      TooltipAtMouse("no presets found for channel mapper")
      return -1
    else
      TooltipAtMouse("failed to get current preset for channel mapper")
      return -1
    end
  end
  
  local function insertChannelMapper(take)
    local insertPos = reaper.TakeFX_AddByName(take, "JS: Channel Mapper-Downmixer (Cockos)", 1)
    if insertPos ~= -1 then
      reaper.TakeFX_SetNamedConfigParm(take, insertPos, "renamed_name", "utility/channel_mapper")
      return insertPos
    else
      TooltipAtMouse("failed to initialized channel mapper")
      return -1
    end
  end
  
  local function setOthers(chMapPreset)
    local numItems = reaper.CountSelectedMediaItems()
    if numItems > 1 then
      for i = 1, numItems -1 do
        local item = reaper.GetSelectedMediaItem(0,i)
        if item then
          local take = reaper.GetActiveTake(item)
          if take then
            local numFX = reaper.TakeFX_GetCount(take)
            if numFX ~= 0 and numFX ~= nil then
              local chMapInd = -1
              for i = 0, numFX-1 do
                local _, FXname = reaper.TakeFX_GetFXName(take, i)
                if FXname == "utility/channel_mapper" then
                  chMapInd = i
                  break
                end
              end
              
              if chMapInd ~= -1 then
                reaper.TakeFX_SetPresetByIndex(take, chMapInd, chMapPreset)
              else
                chMapInd = insertChannelMapper(take)
                reaper.TakeFX_SetPresetByIndex(take, chMapInd, chMapPreset)
              end
            else
              chMapInd = insertChannelMapper(take)
              reaper.TakeFX_SetPresetByIndex(take, chMapInd, chMapPreset)
            end
          end
        end
      end
    end
  end
  
  local function setMain() 
    local item = reaper.GetSelectedMediaItem(0,0)
    if item then
      local intPreset = -1
      local take = reaper.GetActiveTake(item)
      if take then
        local numFX = reaper.TakeFX_GetCount(take)
        local chMapInd = -1
        if numFX ~= 0 and numFX ~= nil then
          for i = 0, numFX-1 do
            local _, FXname = reaper.TakeFX_GetFXName(take, i)
            if FXname == "utility/channel_mapper" then
              chMapInd = i
              break
            end
          end
          
          if chMapInd ~= -1 then
            intPreset = setNextPresetForChMap(take, chMapInd)
          else
            chMapInd = insertChannelMapper(take)
            intPreset = setNextPresetForChMap(take, chMapInd)
          end
        else
          chMapInd = insertChannelMapper(take)
          if chMapInd ~= -1 then
            intPreset = setNextPresetForChMap(take, chMapInd)
          end
        end
        if chMapInd ~= -1 and intPreset ~= -1 then
          if intPreset ~= -2 then
            local retval, presetname = reaper.TakeFX_GetPreset(take, chMapInd)
            TooltipAtMouse("set item Channel Mapper\nto preset: "..presetname)
          else
            TooltipAtMouse("set item Channel Mapper\nto default mapping")
          end
          setOthers(intPreset)
        end
      else
        TooltipAtMouse("selected item has no takes")
      end
    else
      TooltipAtMouse("no item selected")
    end
  end
  
  reaper.Undo_BeginBlock()
  setMain()
  reaper.Undo_EndBlock("Change selected items channel mapper preset", -1)
  