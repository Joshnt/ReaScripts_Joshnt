-- @noindex

-- INI files in ../Scripts/Reascripts_Joshnt/USER/ - not used (yet), maybe for upcoming larger scripts
-- used to store external states, like default values; using "#####" to say a key doesn't have a default value (as empty can be a valid default value)
-- Function to write a key-value pair to an INI file, adding to the end of the section if it exists, or overwriting the key if it already exists
function joshnt.write_ini(file_path, section, key, value)
    local file = io.open(file_path, "r")
    local lines = {}
    local in_section = false
    local section_found = false
    local key_found = false
  
    -- Read existing file content
    if file then
        for line in file:lines() do
            table.insert(lines, line)
        end
        file:close()
    end
  
    -- Process the lines to find the section and key
    for i = 1, #lines do
        if lines[i]:match("^%[.-%]$") then
            in_section = (lines[i] == "[" .. section .. "]")
            section_found = section_found or in_section
        end
  
        if in_section then
            local k, _ = lines[i]:match("^(.-)=(.-)$")
            if k and k == key then
                lines[i] = key .. "=" .. value
                key_found = true
                break
            end
        end
    end
  
    if not section_found then
        -- Add the new section and key-value pair if the section doesn't exist
        table.insert(lines, "[" .. section .. "]")
        table.insert(lines, key .. "=" .. value)
    elseif not key_found then
        -- Add the key-value pair at the end of the section if the key doesn't exist
        for i = #lines, 1, -1 do
            if lines[i]:match("^%[.-%]$") and lines[i] == "[" .. section .. "]" then
                table.insert(lines, i + 1, key .. "=" .. value)
                break
            end
        end
    end
  
    -- Write back to the file
    file = io.open(file_path, "w")
    if file then
        for _, line in ipairs(lines) do
            file:write(line .. "\n")
        end
        file:close()
    else
        reaper.ShowMessageBox("joshnt_Scripts: Unable to open\n\n"..file_path.."\n\nfor writing default values.", "Error", 0)
    end
  end
  
  -- Function to read a value from an INI file
  function joshnt.read_ini(file_path,section, key)
    local file = io.open(file_path, "r")
    if file then
        local in_section = false
        for line in file:lines() do
            if line:match("^%[.-%]$") then
                in_section = (line == "[" .. section .. "]")
            elseif in_section then
                local k, v = line:match("^(.-)=(.-)$")
                if k and k == key then
                    file:close()
                    return v
                end
            end
        end
        file:close()
    else
      reaper.ShowMessageBox("joshnt_Scripts: Unable to open\n\n"..file_path.."\n\nfor reading default values.", "Error", 0)
    end
    return nil
  end
  
  -- Function to delete a key from an INI file
  function joshnt.delete_ini_key(file_path, section, key)
    local file = io.open(file_path, "r")
    if not file then
      reaper.ShowMessageBox("joshnt_Scripts: Unable to open\n\n"..file_path.."\n\nfor reading default values.", "Error", 0)
        return
    end
  
    local lines = {}
    local in_section = false
    for line in file:lines() do
        if line:match("^%[.-%]$") then
            if in_section and #lines > 0 then
                table.remove(lines) -- Remove the last key in section if it's empty
            end
            in_section = (line == "[" .. section .. "]")
            table.insert(lines, line)
        elseif in_section then
            local k, v = line:match("^(.-)=(.-)$")
            if not (k and k == key) then
                table.insert(lines, line)
            end
        else
            table.insert(lines, line)
        end
    end
    file:close()
  
    local file = io.open(file_path, "w")
    if file then
        for _, line in ipairs(lines) do
            file:write(line .. "\n")
        end
        file:close()
    else
      reaper.ShowMessageBox("joshnt_Scripts: Unable to open\n\n"..file_path.."\n\nfor deleting default values.", "Error", 0)
    end
  end
  
  function joshnt.checkForDefaultValFile()
    
  end
  
  function joshnt.getDefaultValTable(section, defaultsFromScriptTable)
    local returnTable = {}
    local checkedTable = {}
    local otherValuesInSection = {}
    for parameter, value in pairs(defaultsFromScriptTable) do
      returnTable[parameter] = value
      checkedTable[parameter] = false
    end
  
    local file, error = io.open(joshnt.getDefaultValPath(), "r")
  
    -- if default val file doesnt exist, create it
    if error and string.match(error, "No such file or directory") then 
      file = io.open(joshnt.getDefaultValPath(), "w")
      if file then
        file:write("[[Default values for joshnt scripts]]")
        file:close()
      end
      file = io.open(joshnt.getDefaultValPath(), "r")
    end
    if file then
  
      -- find existing values
      local in_section = false
      for line in file:lines() do
          if line:match("^%[.-%]$") then
              if not in_section then
                  in_section = (line == "[" .. section .. "]")
              else break end
          elseif in_section then
              local k, v = line:match("^(.-)=(.-)$")
              if k and v and v ~= "#####" then
                returnTable[k] = v
              end
          end
      end
      file:close()
  
      -- delete other values in section & create non-existent ones
      if not joshnt.allValuesEqualTo(checkedTable, true) or otherValuesInSection[1] ~= nil then
        local tableCreate = {}
        for parameters,boolChecked in checkedTable do
          if boolChecked == false then
            tableCreate[#tableCreate+1] = parameters
          end
        end
        joshnt.addDefaultKeysWithHashsAsValues(section, tableCreate)
  
        for i = 1, #otherValuesInSection do
          if otherValuesInSection[i] then
            joshnt.delete_ini_key(joshnt.getDefaultValPath, section, otherValuesInSection[i])
          end
        end
      end
    end
    return returnTable
  end
  
  function joshnt.addDefaultKeysWithHashsAsValues(section, keyTable)
    for index, key in pairs(keyTable) do
      joshnt.write_ini(joshnt.getDefaultValPath(), section, key, "#####")
    end
  end
  
  function joshnt.getDefaultValPath()
    return reaper.GetResourcePath() .. "/Scripts/Joshnt_ReaScripts/USER/joshnt_DefaultValues.ini"
  end
  
  function joshnt.getExtStatesPath()
    return reaper.GetResourcePath() .. "/Scripts/Joshnt_ReaScripts/USER/joshnt_ExtStates.ini"
  end