-- Colors
local bg_r, bg_g, bg_b = 176 / 255, 176 / 255, 176 / 255
local active_box_r, active_box_g, active_box_b = 136 / 255, 193 / 255, 208 / 255
local inactive_box_r, inactive_box_g, inactive_box_b = 96 / 255, 153 / 255, 168 / 255

-- UI State
local unit_options = {"grid", "beat", "seconds"}
local selected_index = 1
if reaper.HasExtState("joshnt_reposition_GUI", "unitIndex") then
  selected_index = tonumber(reaper.GetExtState("joshnt_reposition_GUI", "unitIndex")) or 1
end

local input1 = "2"
if reaper.HasExtState("joshnt_reposition_GUI", "num_tracks") then
  input1 = reaper.GetExtState("joshnt_reposition_GUI", "num_tracks")
end

local input2 = "1"
if reaper.HasExtState("joshnt_reposition_GUI", "offset") then
  input2 = reaper.GetExtState("joshnt_reposition_GUI", "offset")
end

local focus_field = 0
local dropdown_focused = false
local running = true

-- Layout
local field_w, field_h = 100, 20
local margin = 10
local spacing = 30
local font_size = 16
local win_w = 210
local win_h = 150

-- Center the window
gfx.init("joshnt_reposition", win_w, win_h)

local function mouse_in(x, y, w, h)
  return gfx.mouse_x >= x and gfx.mouse_x <= x + w and gfx.mouse_y >= y and gfx.mouse_y <= y + h
end

function draw_ui()
  -- Background
  gfx.set(bg_r, bg_g, bg_b, 1)
  gfx.rect(0, 0, gfx.w, gfx.h, true)

  gfx.setfont(1, "Arial", font_size)
  gfx.set(0, 0, 0, 1)

  -- === Dropdown ===
  local unit_label_x = margin
  local unit_label_y = margin
  local dropdown_x = unit_label_x + 80
  local dropdown_y = unit_label_y - 2

  gfx.set(dropdown_focused and active_box_r or inactive_box_r,
          dropdown_focused and active_box_g or inactive_box_g,
          dropdown_focused and active_box_b or inactive_box_b, 1)
  gfx.rect(dropdown_x, dropdown_y, 100, 20, true)

  gfx.set(0, 0, 0, 1)
  gfx.x = unit_label_x
  gfx.y = unit_label_y
  gfx.drawstr("Unit: ")
  gfx.x = dropdown_x + 5
  gfx.y = dropdown_y + 2
  gfx.drawstr(unit_options[selected_index])

  -- === Input 1 ===
  local input1_y = margin + spacing
  gfx.set(0, 0, 0, 1)
  gfx.x = margin
  gfx.y = input1_y
  gfx.drawstr("No. Tracks:")

  gfx.set(focus_field == 1 and active_box_r or inactive_box_r,
          focus_field == 1 and active_box_g or inactive_box_g,
          focus_field == 1 and active_box_b or inactive_box_b, 1)
  gfx.rect(margin + 80, input1_y - 2, field_w, field_h, true)

  gfx.set(0, 0, 0, 1)
  gfx.x = margin + 85
  gfx.y = input1_y
  gfx.drawstr(input1)

  -- === Input 2 ===
  local input2_y = margin + spacing * 2
  gfx.set(0, 0, 0, 1)
  gfx.x = margin
  gfx.y = input2_y
  gfx.drawstr("Offset:")

  gfx.set(focus_field == 2 and active_box_r or inactive_box_r,
          focus_field == 2 and active_box_g or inactive_box_g,
          focus_field == 2 and active_box_b or inactive_box_b, 1)
  gfx.rect(margin + 80, input2_y - 2, field_w, field_h, true)

  gfx.set(0, 0, 0, 1)
  gfx.x = margin + 85
  gfx.y = input2_y
  gfx.drawstr(input2)

  -- === OK Button ===
  local ok_x = margin
  local ok_y = margin + spacing * 3
  local ok_w = 60
  local ok_h = 25

  gfx.set(inactive_box_r, inactive_box_g, inactive_box_b, 1)
  gfx.rect(ok_x, ok_y, ok_w, ok_h, true)

  gfx.set(0, 0, 0, 1)
  gfx.x = ok_x + 17
  gfx.y = ok_y + 5
  gfx.drawstr("OK")
end

function run()
  draw_ui()

  dropdown_focused = false
  if gfx.mouse_cap & 1 == 1 and not last_mouse_state then
    -- Dropdown
    if mouse_in(margin + 80, margin - 2, 100, 20) then
      dropdown_focused = true
      local menu = table.concat(unit_options, "|")
      local choice = gfx.showmenu(menu)
      if choice > 0 then selected_index = choice end
    end

    -- Input 1 field
    if mouse_in(margin + 80, margin + spacing - 2, field_w, field_h) then
      focus_field = 1
    end

    -- Input 2 field
    if mouse_in(margin + 80, margin + spacing * 2 - 2, field_w, field_h) then
      focus_field = 2
    end

    -- OK button
    if mouse_in(margin, margin + spacing * 3, 60, 25) then
      running = false
    end
  end

  local char = gfx.getchar()
  if char == 27 or char == -1 then running = false return end -- cancel function
  if char == 13 then running = false end -- call function

  if focus_field > 0 and char >= 32 and char <= 126 then
    local field = focus_field == 1 and input1 or input2
    field = field .. string.char(char)
    if focus_field == 1 then input1 = field else input2 = field end
  elseif char == 8 then
    local field = focus_field == 1 and input1 or input2
    field = field:sub(1, -2)
    if focus_field == 1 then input1 = field else input2 = field end
  end

  gfx.update()
  local last_mouse_state = gfx.mouse_cap & 1 == 1

  if running then
    reaper.defer(run)
  else
    finalize()
  end
end

function finalize()
  local num1 = tonumber(input1)
  local num2 = tonumber(input2)
  local unit = unit_options[selected_index]

  if not num1 or not num2 then
    reaper.ShowMessageBox("Invalid number inputs.", "Error", 0)
    return
  end

  reaper.SetExtState("joshnt_reposition_GUI", "num_tracks", input1, true)
  reaper.SetExtState("joshnt_reposition_GUI", "offset", input2, true)
  reaper.SetExtState("joshnt_reposition_GUI", "unitIndex", tostring(selected_index), true)

  gfx.quit()

  joshnt_repostion.main(num1, unit, num2)
end


-- @noindex

local joshnt_LuaUtils = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/DEVELOPMENT/joshnt_LuaUtilities.lua'
if reaper.file_exists( joshnt_LuaUtils ) then 
  dofile( joshnt_LuaUtils ) 
  if not joshnt or joshnt.version() < 3.7 then 
    reaper.MB("This script requires a newer version of joshnt Lua Utilities. Please run:\n\nExtensions > ReaPack > Synchronize Packages, 'joshnt_LuaUtilities.lua'","Error",0); 
    return 
  end
else 
  reaper.MB("This script requires joshnt Lua Utilities! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt Lua Utilities'","Error",0)
  return
end

-- Load core script
local joshnt_repostionCORE = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/ITEMS/joshnt_Incremental Nudge/swobi-joshnt_Incremental Nudge - CORE.lua'
if reaper.file_exists( joshnt_repostionCORE ) then 
  dofile( joshnt_repostionCORE ) 
else 
  reaper.MB("This script requires an additional script, which gets installed over ReaPack as well. Please re-install the whole 'Incremental Nudge' Pack here:\n\nExtensions > ReaPack > Browse Packages > 'joshnt_Incremental Nudge'","Error",0)
  return
end 

run()
