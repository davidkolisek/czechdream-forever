local addon = CzechDreamForever
local frame

function addon:BuildUI()
  frame = CreateFrame('Frame', 'CzechDreamForeverFrame', UIParent, 'BasicFrameTemplateWithInset')
  frame:SetSize(440, 390); frame:SetPoint('CENTER'); frame:Hide()
  frame.title = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight'); frame.title:SetPoint('TOP', 0, -5)
  frame.body = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal'); frame.body:SetPoint('TOPLEFT', 22, -42); frame.body:SetJustifyH('LEFT'); frame.body:SetSpacing(5); frame.body:SetWidth(390)
end

function addon:RefreshUI()
  if not frame then self:BuildUI() end
  local character = self:CurrentCharacter(); frame.title:SetText('CzechDream Forever · ' .. self.db.crew.name)
  local text = 'THE CREW\n\n' .. self.db.player.name .. ' · ' .. (character.name or '-') .. ' · ' .. (character.class or '-') .. ' · level ' .. (character.level or '-') .. '\nDeaths: ' .. (character.deaths or 0) .. '    PvP kills: ' .. (character.pvpKills or 0) .. '\n\nRECENT MOMENTS\n'
  local start = math.max(1, #self.db.events - 5)
  for i = #self.db.events, start, -1 do local event = self.db.events[i]; text = text .. '• ' .. event.type .. ' · ' .. date('%d.%m.%Y %H:%M', event.at) .. '\n' end
  frame.body:SetText(text)
end

function addon:ToggleUI()
  if not frame then self:BuildUI() end
  if frame:IsShown() then frame:Hide() else self:RefreshUI(); frame:Show() end
end

addon:InitSync()
