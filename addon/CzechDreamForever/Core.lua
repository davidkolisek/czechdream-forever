local addonName, addon = ...
CzechDreamForever = addon
addon.name = 'CzechDreamForever'
addon.version = '0.1.0'
addon.prefix = 'CDF'
addon.maxEvents = 500
addon.eventFrame = CreateFrame('Frame')

function addon:Print(message)
  DEFAULT_CHAT_FRAME:AddMessage('|cff78a9ff[CzechDream]|r ' .. tostring(message))
end

function addon:Now()
  return time()
end
