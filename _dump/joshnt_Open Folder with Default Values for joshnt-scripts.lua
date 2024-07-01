-- @description Open the user directory for joshnt Scripts
-- @version 1.0
-- @author Joshnt
-- @about
--    Open User directory for joshnt scripts
-- @changelog
--  + init

  if not reaper.CF_ShellExecute then
    reaper.MB("Missing dependency: SWS extension.\nPlease download it from http://www.sws-extension.org/", "Error", 0)
    return false
  end
  
  local os_sep = package.config:sub(1,1)
  joshnt_UserDir = reaper.GetResourcePath()..'/Scripts/Joshnt_ReaScripts/USER'
  
  if joshnt_UserDir ~= "" then
    render_path = render_path:gsub( os_sep .. "+", os_sep ) -- Remove duplicate path separators
    reaper.CF_ShellExecute(render_path )
  else
    reaper.MB( "No User-Directory found for joshnt scripts." )
  end