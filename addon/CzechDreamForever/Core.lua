local folderName, addon = ...

CzechDreamForever = addon

addon.name = 'CzechDreamLite'
addon.folderName = folderName
addon.displayName = 'CzechDream Lite'
addon.version = '0.4.2'
addon.prefix = 'CDL'
addon.eventFrame = CreateFrame('Frame')

function addon:Print(message)
  DEFAULT_CHAT_FRAME:AddMessage('|cff78a9ff[CzechDream Lite]|r ' .. tostring(message))
end

function addon:Now()
  return time()
end

function addon:IsShiftDown()
  return IsShiftKeyDown and IsShiftKeyDown() or false
end

function addon:SaveDB()
  if self.db then CzechDreamLiteDB = self.db end
end

function addon:GetSetting(key)
  return self.db and self.db.settings and self.db.settings[key] == true
end

function addon:SetSetting(key, value)
  if not self.db then return end
  self.db.settings[key] = value == true
  self:SaveDB()
  if key == 'classColoredFrames' and self.RefreshClassColoredFrames then
    self:RefreshClassColoredFrames()
  elseif (key == 'autoSellJunk' or key == 'autoRepair') and self.RefreshVendorAutomation then
    self:RefreshVendorAutomation()
  elseif (key == 'errorFilter' or key:find('^filter')) and self.RefreshErrorFilter then
    self:RefreshErrorFilter()
  end
end
