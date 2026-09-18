local addon = CzechDreamForever

addon.eventFrame:RegisterEvent('PLAYER_LOGIN')
addon.eventFrame:RegisterEvent('PLAYER_LEVEL_UP')
addon.eventFrame:RegisterEvent('PLAYER_DEAD')
addon.eventFrame:RegisterEvent('PLAYER_PVP_KILLS_CHANGED')
addon.eventFrame:SetScript('OnEvent', function(_, event, ...)
  if event == 'PLAYER_LOGIN' then addon:InitStorage(); addon:RefreshUI(); return end
  if event == 'PLAYER_LEVEL_UP' then addon:AddEvent('LEVEL_UP', { level = ... }); addon:BroadcastLatest(); addon:RefreshUI()
  elseif event == 'PLAYER_DEAD' then addon:AddEvent('DEATH'); addon:BroadcastLatest(); addon:RefreshUI()
  elseif event == 'PLAYER_PVP_KILLS_CHANGED' then addon:AddEvent('PVP_KILL'); addon:BroadcastLatest(); addon:RefreshUI() end
end)
