local addon = CzechDreamForever

local optionsFrame
local minimapButton
local activePage = 'frames'
local pages = {}
local tabs = {}
local controls = {}

local MINIMAP_ICON = 'Interface\\AddOns\\CzechDreamForever\\Media\\CzechDreamLite'

local GOLD = '|cffffd100'
local WHITE = '|cffffffff'
local GREY = '|cffb6becb'
local MUTED = '|cff778291'
local GREEN = '|cff55e6a5'

local function font(parent, value, x, y, size, fontObject)
  local result = parent:CreateFontString(nil, 'OVERLAY', fontObject or 'GameFontNormal')
  result:SetPoint('TOPLEFT', x, y)
  local face, _, flags = result:GetFont()
  if face then result:SetFont(face, size or 12, flags or '') end
  result:SetText(value or '')
  result:SetJustifyH('LEFT')
  return result
end

local function backdrop(parent, width, height, alpha)
  local result = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
  result:SetSize(width, height)
  result:SetBackdrop({
    bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background-Dark',
    edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
  })
  result:SetBackdropColor(0.025, 0.03, 0.04, alpha or 1)
  result:SetBackdropBorderColor(0.58, 0.4, 0.14, 1)
  return result
end

local function applyMinimapPosition()
  if not minimapButton or not addon.db then return end

  minimapButton:ClearAllPoints()
  local angle = math.rad(addon.db.minimap.angle or 45)
  local width = Minimap.GetWidth and Minimap:GetWidth() or 140
  local radius = (width * 0.5) + 12
  minimapButton:SetPoint('CENTER', Minimap, 'CENTER', math.cos(angle) * radius, math.sin(angle) * radius)
end

local function createMinimapButton()
  if minimapButton then
    applyMinimapPosition()
    return
  end

  minimapButton = CreateFrame('Button', 'CzechDreamLiteMinimapButton', Minimap)
  minimapButton:SetSize(34, 34)
  minimapButton:SetFrameStrata('MEDIUM')
  minimapButton:SetNormalTexture('Interface\\Minimap\\UI-Minimap-TrackingBorder')
  minimapButton:SetHighlightTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight')

  local icon = minimapButton:CreateTexture(nil, 'ARTWORK')
  icon:SetSize(26, 26)
  icon:SetPoint('CENTER')
  icon:SetTexture(MINIMAP_ICON)
  icon:SetTexCoord(0.02, 0.98, 0.02, 0.98)
  if icon.AddMaskTexture and minimapButton.CreateMaskTexture then
    local mask = minimapButton:CreateMaskTexture()
    mask:SetAllPoints(icon)
    mask:SetTexture('Interface\\CharacterFrame\\TempPortraitAlphaMask')
    icon:AddMaskTexture(mask)
  end

  minimapButton:RegisterForDrag('LeftButton')
  minimapButton:SetScript('OnDragStart', function(self)
    self:SetScript('OnUpdate', function()
      local scale = UIParent:GetEffectiveScale()
      local cursorX, cursorY = GetCursorPosition()
      local centerX, centerY = Minimap:GetCenter()
      cursorX, cursorY = cursorX / scale, cursorY / scale
      local deltaY, deltaX = cursorY - centerY, cursorX - centerX
      local angle = math.atan2 and math.atan2(deltaY, deltaX) or math.atan(deltaY / (deltaX == 0 and 0.0001 or deltaX))
      addon.db.minimap.angle = math.deg(angle)
      applyMinimapPosition()
    end)
  end)
  minimapButton:SetScript('OnDragStop', function(self)
    self:SetScript('OnUpdate', nil)
  end)
  minimapButton:SetScript('OnClick', function()
    addon:ToggleUI()
  end)
  minimapButton:SetScript('OnEnter', function(self)
    GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
    GameTooltip:AddLine('CzechDream Lite')
    GameTooltip:AddLine('Click to open settings', 1, 1, 1)
    GameTooltip:AddLine('Drag to move around the minimap', 0.7, 0.7, 0.7)
    GameTooltip:Show()
  end)
  minimapButton:SetScript('OnLeave', function() GameTooltip:Hide() end)
  applyMinimapPosition()
end

local function styleTab(tab, selected)
  tab:SetBackdropColor(selected and 0.22 or 0.075, selected and 0.17 or 0.085, selected and 0.1 or 0.11, 1)
  tab:SetBackdropBorderColor(selected and 0.78 or 0.24, selected and 0.54 or 0.25, selected and 0.18 or 0.16, 1)
  tab.label:SetText(selected and GOLD .. tab.text or GREY .. tab.text)
end

local function makeTab(key, text, texture, y)
  local tab = CreateFrame('Button', nil, optionsFrame.nav, 'BackdropTemplate')
  tab:SetSize(146, 46)
  tab:SetPoint('TOPLEFT', 10, y)
  tab:SetBackdrop({
    bgFile = 'Interface\\Buttons\\WHITE8X8',
    edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
    edgeSize = 6,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
  })
  tab.text = text
  local icon = tab:CreateTexture(nil, 'ARTWORK')
  icon:SetSize(28, 28)
  icon:SetPoint('LEFT', 12, 0)
  icon:SetTexture(texture)
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  tab.label = font(tab, GREY .. text, 48, -14, 10, 'GameFontNormal')
  tab:SetScript('OnClick', function() addon:SelectPage(key) end)
  tab:SetScript('OnEnter', function(self)
    if activePage ~= key then self:SetBackdropColor(0.13, 0.14, 0.17, 1) end
  end)
  tab:SetScript('OnLeave', function(self) styleTab(self, activePage == key) end)
  tabs[key] = tab
  return tab
end

local function makePage(key, title, description)
  local page = CreateFrame('Frame', nil, optionsFrame.content)
  page:SetAllPoints()
  page.title = font(page, GOLD .. title, 22, -22, 17, 'GameFontNormalLarge')
  page.description = font(page, GREY .. description, 22, -50, 10, 'GameFontNormal')

  local line = page:CreateTexture(nil, 'ARTWORK')
  line:SetColorTexture(0.3, 0.22, 0.12, 1)
  line:SetSize(500, 1)
  line:SetPoint('TOPLEFT', 22, -72)

  page.body = CreateFrame('Frame', nil, page)
  page.body:SetPoint('TOPLEFT', 22, -82)
  page.body:SetSize(500, 385)
  pages[key] = page
  return page
end

local function makeToggle(page, key, title, description, y)
  local row = CreateFrame('Button', nil, page.body, 'BackdropTemplate')
  row:SetSize(500, 58)
  row:SetPoint('TOPLEFT', 0, y)
  row:SetBackdrop({
    bgFile = 'Interface\\Buttons\\WHITE8X8',
    edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
    edgeSize = 6,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
  })

  local box = CreateFrame('Frame', nil, row, 'BackdropTemplate')
  box:SetSize(24, 24)
  box:SetPoint('LEFT', 16, 0)
  box:SetBackdrop({
    bgFile = 'Interface\\Buttons\\WHITE8X8',
    edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
    edgeSize = 2,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
  })
  box.mark = box:CreateTexture(nil, 'OVERLAY')
  box.mark:SetSize(22, 22)
  box.mark:SetPoint('CENTER')
  box.mark:SetTexture('Interface\\Buttons\\UI-CheckBox-Check')
  row.box = box

  row.title = font(row, WHITE .. title, 54, -12, 11, 'GameFontNormal')
  row.description = font(row, GREY .. description, 54, -33, 9, 'GameFontNormal')
  row.description:SetWidth(410)
  row.description:SetWordWrap(true)
  row.key = key

  row:SetScript('OnClick', function()
    addon:SetSetting(key, not addon:GetSetting(key))
    addon:RefreshOptions()
  end)
  row:SetScript('OnEnter', function(self)
    self:SetBackdropColor(0.13, 0.14, 0.17, 1)
  end)
  row:SetScript('OnLeave', function() addon:RefreshOptions() end)
  controls[key] = row
  return row
end

function addon:SelectPage(key)
  if not pages[key] then return end
  activePage = key
  for pageKey, page in pairs(pages) do
    if pageKey == key then page:Show() else page:Hide() end
  end
  for tabKey, tab in pairs(tabs) do
    styleTab(tab, tabKey == key)
  end
  self:RefreshOptions()
end

function addon:RefreshOptions()
  for key, control in pairs(controls) do
    local enabled = self:GetSetting(key)
    control.box.mark:SetShown(enabled)
    control.box:SetBackdropColor(enabled and 0.13 or 0.045, enabled and 0.11 or 0.055, enabled and 0.055 or 0.07, 1)
    control.box:SetBackdropBorderColor(enabled and 0.82 or 0.34, enabled and 0.58 or 0.3, enabled and 0.18 or 0.2, 1)
    control:SetBackdropColor(enabled and 0.12 or 0.055, enabled and 0.1 or 0.065, enabled and 0.055 or 0.085, 1)
    control:SetBackdropBorderColor(enabled and 0.68 or 0.22, enabled and 0.47 or 0.2, enabled and 0.16 or 0.13, 1)
  end
  for key, tab in pairs(tabs) do styleTab(tab, key == activePage) end
  if minimapButton then
    if self.db.minimap.hide then minimapButton:Hide() else minimapButton:Show() end
    applyMinimapPosition()
  end
end

function addon:BuildUI()
  if optionsFrame then return end

  optionsFrame = backdrop(UIParent, 760, 580, 1)
  optionsFrame:SetPoint('CENTER')
  optionsFrame:SetFrameStrata('DIALOG')
  optionsFrame:SetMovable(true)
  optionsFrame:SetClampedToScreen(true)
  optionsFrame:EnableMouse(true)
  optionsFrame:RegisterForDrag('LeftButton')
  optionsFrame:SetScript('OnDragStart', optionsFrame.StartMoving)
  optionsFrame:SetScript('OnDragStop', optionsFrame.StopMovingOrSizing)
  optionsFrame:Hide()

  local header = optionsFrame:CreateTexture(nil, 'ARTWORK')
  header:SetPoint('TOPLEFT', 8, -8)
  header:SetPoint('TOPRIGHT', -8, -8)
  header:SetHeight(58)
  header:SetColorTexture(0.08, 0.065, 0.045, 1)
  font(optionsFrame, WHITE .. 'CzechDream Lite', 22, -17, 17, 'GameFontHighlightLarge')
  font(optionsFrame, GREY .. 'Small quality-of-life tools for WoW Forever', 24, -43, 10)

  local close = CreateFrame('Button', nil, optionsFrame, 'UIPanelCloseButton')
  close:SetPoint('TOPRIGHT', -8, -8)
  close:SetScript('OnClick', function() optionsFrame:Hide() end)

  optionsFrame.nav = backdrop(optionsFrame, 166, 490, 0.96)
  optionsFrame.nav:SetPoint('TOPLEFT', 16, -78)
  font(optionsFrame.nav, GOLD .. 'TOOLS', 16, -18, 11, 'GameFontNormalLarge')
  font(optionsFrame.nav, MUTED .. 'Choose a section', 16, -40, 9)

  optionsFrame.content = backdrop(optionsFrame, 558, 490, 0.96)
  optionsFrame.content:SetPoint('TOPLEFT', 190, -78)

  makeTab('frames', 'Unit Frames', 'Interface\\Icons\\Spell_Nature_SkinofEarth', -62)
  makeTab('quests', 'Quests', 'Interface\\Icons\\INV_Misc_Book_09', -114)
  makeTab('vendors', 'Vendors', 'Interface\\Icons\\INV_Misc_Coin_01', -166)
  makeTab('messages', 'Messages', 'Interface\\Icons\\Spell_Shadow_MindRot', -218)
  font(optionsFrame.nav, MUTED .. 'Click the minimap icon', 16, -425, 9)
  font(optionsFrame.nav, MUTED .. 'again to close this panel.', 16, -443, 9)

  local frames = makePage('frames', 'UNIT FRAMES', 'Make friendly and enemy health bars easier to identify at a glance.')
  makeToggle(frames, 'classColoredFrames', 'Class-coloured health bars', 'Player, target, focus and party frames use the class colour of the unit.', -4)

  local quests = makePage('quests', 'QUESTS', 'Speed up routine quest turn-ins without taking control away from you.')
  makeToggle(quests, 'autoAccept', 'Auto-accept quests', 'Accept a quest as soon as the quest dialog opens.', -4)
  makeToggle(quests, 'autoTurnIn', 'Auto-turn in quests', 'Complete ready quests when you talk to the NPC.', -72)
  makeToggle(quests, 'autoReward', 'Auto-select one reward', 'Select a reward only when the quest offers exactly one choice. Multiple rewards stay manual.', -140)

  local vendors = makePage('vendors', 'VENDORS', 'Keep repairs and inventory cleanup automatic when it is safe to do so.')
  makeToggle(vendors, 'autoRepair', 'Auto-repair gear', 'Repair automatically at a merchant and wait until you have enough gold if necessary.', -4)
  makeToggle(vendors, 'autoSellJunk', 'Auto-sell grey items', 'Sell poor-quality grey items when a merchant window is open.', -72)

  local messages = makePage('messages', 'MESSAGES', 'Reduce repetitive combat errors without hiding useful quest or information messages.')
  makeToggle(messages, 'errorFilter', 'Error filter', 'Enable filtering of repetitive red error messages.', -4)
  makeToggle(messages, 'filterAllErrors', 'Filter all red errors', 'Use only if you want a completely quiet error frame.', -72)
  makeToggle(messages, 'filterResourceErrors', 'Resource errors', 'Not enough mana, rage, energy or focus.', -140)
  makeToggle(messages, 'filterCooldownErrors', 'Cooldown errors', 'Ability or item is not ready yet.', -208)
  makeToggle(messages, 'filterRangeErrors', 'Range errors', 'Out of range or bad attack position.', -276)
  makeToggle(messages, 'filterInventoryErrors', 'Inventory errors', 'Full bags and item-related errors.', -344)

  self:SelectPage('frames')
end

function addon:ToggleUI()
  self:BuildUI()
  createMinimapButton()
  if optionsFrame:IsShown() then
    optionsFrame:Hide()
  else
    self:RefreshOptions()
    optionsFrame:Show()
  end
end

function addon:RefreshUI()
  if optionsFrame and optionsFrame:IsShown() then self:RefreshOptions() end
end

local eventFrame = CreateFrame('Frame')
eventFrame:RegisterEvent('PLAYER_LOGIN')
eventFrame:SetScript('OnEvent', function()
  createMinimapButton()
  addon:RefreshOptions()
end)
