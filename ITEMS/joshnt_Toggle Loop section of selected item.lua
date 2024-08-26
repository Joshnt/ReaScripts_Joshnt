    
-- @description Toggle Loop item section
-- @version 1.00001
-- @author Joshnt, Archie
-- @about
--      adjusted version of archie's 'Script: Archie_Item; 'Toggle (Loop source OFF) - (SWS Loop section of selected item(s)).lua'
--      as his version keeps the section bounds set of the loop section
-- @changelog
--  + init
    -------------------------------------------------------
    local function no_undo()reaper.defer(function()end)end;
    -------------------------------------------------------



    local item_cnt = reaper.CountSelectedMediaItems(0);
    if item_cnt == 0 then no_undo()return end;


    local itemSelFirst = reaper.GetSelectedMediaItem(0,0);
    local item_loop = reaper.GetMediaItemInfo_Value(itemSelFirst,"B_LOOPSRC");

    local Tip;
    if item_loop == 1 then;
        reaper.Undo_BeginBlock();
        for i = 1,item_cnt do;
            local itemSel = reaper.GetSelectedMediaItem(0,i-1);
            reaper.SetMediaItemInfo_Value(itemSel,"B_LOOPSRC",0);
            reaper.Main_OnCommand(40547,0)
            reaper.UpdateItemInProject(itemSel);
        end;
        reaper.Undo_EndBlock('Loop source OFF',-1);
        Tip = 'Loop source OFF';
    else;
        reaper.Main_OnCommand(reaper.NamedCommandLookup('_SWS_LOOPITEMSECTION'),0);
        -- SWS: Loop section of selected item(s)
        Tip = 'SWS: Loop section of selected item(s)';
    end;

    reaper.UpdateArrange();


    local x, y = reaper.GetMousePosition();
    reaper.TrackCtl_SetToolTip(Tip,x+20,y-20,0);