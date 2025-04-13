local item = reaper.GetSelectedMediaItem(0,1)
reaper.SetMediaItemSelected(item, false)
reaper.UpdateArrange()
