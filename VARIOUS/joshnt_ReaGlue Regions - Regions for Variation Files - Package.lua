-- @description ReaGlue adaption to Regions (with user input)
-- @version 4.01
-- @changelog 
--      added RRM Link
-- @author Joshnt
-- @metapackage
-- @provides
--   [nomain] joshnt_Regions for Variation File (ReaGlue-Regions)/joshnt_ReaGlue Regions - CORE.lua
--   [main] joshnt_Regions for Variation File (ReaGlue-Regions)/joshnt_ReaGlue Regions - create region over selected items and adjust distance between to render as variation file.lua
--   [main] joshnt_Regions for Variation File (ReaGlue-Regions)/joshnt_ReaGlue Regions (with user input) - create region over selected items and adjust distance between to render as variation file.lua
-- @about 
--    ## ReaGlue Region
--    Basically the light version of "joshnt_Create unique regions for each group of overlapping items"
--    For detailed explanation, refer this script
--    **Credits** to Aaron Cendan (for acendan_Set nearest regions edges to selected media items.lua; https://aaroncendan.me), David Arnoldy, Joshua Hank
--    **Usecase:** 
--    multiple Multi-Track Recordings or Sounddesigns across multiple tracks which needs to be exported to a single variation file.
--    Script creates region across those selected items (including beginning and end silence), adjusting the space between them, moving other non selected items away
