local addon = CzechDreamForever

SLASH_CZECHDREAMLITE1 = '/cd'
SLASH_CZECHDREAMLITE2 = '/czechdream'
SLASH_CZECHDREAMLITE3 = '/forever'
SlashCmdList.CZECHDREAMLITE = function(message)
  local command = tostring(message or ''):lower():match('^%s*(%S*)') or ''
  if command == 'help' then
    addon:Print('/cd opens settings. Hold Shift while talking to an NPC to keep quest handling manual.')
  elseif command == 'reload' then
    ReloadUI()
  elseif command == 'debug' then
    addon:Print('Version ' .. addon.version .. ', saved settings linked=' .. tostring(addon.db == CzechDreamLiteDB)
      .. ', auto-sell=' .. tostring(addon:GetSetting('autoSellJunk'))
      .. ', class colours=' .. tostring(addon:GetSetting('classColoredFrames')))
    if addon.PrintFrameDiagnostics then addon:PrintFrameDiagnostics() end
    if addon.PrintVendorDiagnostics then addon:PrintVendorDiagnostics() end
  else
    addon:ToggleUI()
  end
end
