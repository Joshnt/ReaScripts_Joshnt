-- @description Unique Region per overlapping item bundle in selection (with Mother Region over them) - Game Audio/ SD Use
-- @version 2.0
-- @changelog
--  - added Lokasenna GUI + RRM Link
-- @author Joshnt
-- @about 
--    ## Unique Regions - Joshnt
--    **User input explanation:**
--    - Time before item group start: Time in seconds between region start and item group start (per region) (use numbers above 0)
--    - Time after item group end: Time in seconds between item group end and region end (per region) (use numbers above 0)
--    - Space between regions: space between each item group's region and the next (use numbers above 0)
--    - Lock items: write "y" to lock the items after adjusting the position
--    - Region names/ Mother Region name: Eachs overlapping item group region name; use the wildcard [$incrX] to start numbering the regions from X and increase it per region (e.g. "Footsteps_[$incr3]" would name the first region "Footsteps_03", the next "Footsteps_04", ...)
--    - Region Color/ Mother Region Color: input anything to open the REAPER's Color-Picker to color the region; leave empty to use default color
--    - Link to RRM: Input to create a link to the moved/ created region(s); Input can be "HP" for highest hierachy common parent track of selected Items, "P" for first common parent of selected items, "T" for each track if it has items in the region, "M" for Master-Track, "N" (or anything else) for no link to Region Render Matrix
--    
--
--    **Credits** to Aaron Cendan (for acendan_Set nearest regions edges to selected media items.lua; https://aaroncendan.me), David Arnoldy, Joshua Hank, Yannick Winter
--
--    **Usecase:**  
--    creating incremental numbered regions for single layered sounds (for e.g. game audio) - mother region possibly useful for reapers region render dialog and naming via $region(=name) 
--    Script creates regions for overlapping selected items (including beginning and end silence), adjusting the space between them, moving other non selected items away.
-- @metapackage
-- @provides
--   [main] joshnt_Create unique regions for each group of overlapping items/joshnt_Create unique regions for each group of overlapping items of selected items (with mother region) - GUI.lua
--   [main] joshnt_Create unique regions for each group of overlapping items/joshnt_Create unique regions for each group of overlapping items of the selected items + isolate (with mother region).lua
--   [main] joshnt_Create unique regions for each group of overlapping items/joshnt_Create unique regions for each group of overlapping items of the selected items + isolate.lua
--   [nomain] joshnt_Create unique regions for each group of overlapping items/joshnt_Unique Regions for overlapping items - CORE.lua