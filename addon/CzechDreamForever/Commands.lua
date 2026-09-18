local addon = CzechDreamForever

SLASH_CZECHDREAMFOREVER1 = '/forever'
SlashCmdList.CZECHDREAMFOREVER = function(message)
  local command, value = message:match('^(%S*)%s*(.-)$')
  if command == 'crew' and value ~= '' then addon.db.crew.name = value; addon:Print('Crew nastavená na: ' .. value)
  elseif command == 'hello' then addon:Send('HELLO', nil, 'GUILD'); addon:Print('Hľadám CzechDream hráčov v guilde...')
  elseif command == 'reset' then addon:Print('Reset vyžaduje vymazanie SavedVariables mimo hry.')
  elseif command == 'moment' and value ~= '' then addon:AddEvent('MOMENT', { text = value }); addon:BroadcastLatest(); addon:RefreshUI()
  else addon:ToggleUI() end
end
