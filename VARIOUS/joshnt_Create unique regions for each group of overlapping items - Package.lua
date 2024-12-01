-- @description Unique Region per overlapping item bundle in selection (with Mother Region over them) - Game Audio/ SD Use
-- @version 3.3
-- @changelog
--  - brought back the "mother variants" from v2 to not mess up anybody's shortcuts for existing setups - as the new versions have different names now (thanks to Yannick W. for the feedback!)
-- @author Joshnt
-- @about 
--    ## Unique Regions - Joshnt
--    **Usecase**
--    naming and creating multiple regions after complex rules (e.g. for SFX- or Kontakt-Sample-Editing) - larger everyX Values possibly useful for reapers region render dialog and naming via $region(=name) 
--    Script creates regions for overlapping selected items (including beginning and end silence), adjusting the space between them, moving other non selected items away.
--
--    **Credits** to Aaron Cendan (for acendan_Set nearest regions edges to selected media items.lua; https://aaroncendan.me), Joshua Hank + Yannick Winter, Luka Swoboda, David Arnoldy (for additional brainpower)
-- @metapackage
-- @provides
--   [main] joshnt_Create unique regions for each group of overlapping items/joshnt_Create unique regions for groups of overlapping items - use File....lua
--   [main] joshnt_Create unique regions for each group of overlapping items/joshnt_Create unique regions for groups of overlapping items - use defaults.lua
--   [main] joshnt_Create unique regions for each group of overlapping items/joshnt_Create unique regions for groups of overlapping items - use Clipboard.lua
--   [main] joshnt_Create unique regions for each group of overlapping items/joshnt_Create unique regions for groups of overlapping items - GUI.lua
--   [main] joshnt_Create unique regions for each group of overlapping items/joshnt_Create unique regions for each group of overlapping items of selected items (with mother region) - GUI.lua
--   [main] joshnt_Create unique regions for each group of overlapping items/joshnt_Create unique regions for each group of overlapping items of the selected items + isolate (with mother region).lua
--   [main] joshnt_Create unique regions for each group of overlapping items/joshnt_Create unique regions for each group of overlapping items of the selected items + isolate.lua
--   [nomain] joshnt_Create unique regions for each group of overlapping items/joshnt_Unique Regions for overlapping items - CORE.lua
