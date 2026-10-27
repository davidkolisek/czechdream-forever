local addon = CzechDreamForever

local errorFilter = {
  installed = false,
  original = nil,
  messages = {}
}

local constants = {
  resource = {
    'ERR_OUT_OF_MANA', 'ERR_OUT_OF_RAGE', 'ERR_OUT_OF_ENERGY', 'ERR_OUT_OF_FOCUS',
    'ERR_OUT_OF_RUNES', 'ERR_NO_ATTACK_TARGET'
  },
  cooldown = {
    'ERR_ABILITY_COOLDOWN', 'ERR_SPELL_COOLDOWN', 'ERR_ITEM_COOLDOWN'
  },
  range = {
    'ERR_OUT_OF_RANGE', 'ERR_BADATTACKPOS', 'ERR_TOO_FAR_TO_INTERACT'
  },
  inventory = {
    'ERR_INV_FULL', 'ERR_ITEM_MAX_COUNT', 'ERR_CANT_EQUIP_LEVEL', 'ERR_CANT_EQUIP_RACE',
    'ERR_CANT_EQUIP_REPUTATION', 'ERR_ITEM_CANT_BE_DESTROYED'
  }
}

local function rebuildMessages()
  errorFilter.messages = {}
  for category, names in pairs(constants) do
    for _, name in ipairs(names) do
      local value = _G[name]
      if value and value ~= '' then
        errorFilter.messages[value] = category
      end
    end
  end
end

function addon:ShouldFilterError(message, red, green, blue)
  if not self:GetSetting('errorFilter') or not message then return false end
  if self:GetSetting('filterAllErrors') then
    local isRedError = red == nil or (red > 0.75 and green < 0.55 and blue < 0.55)
    return isRedError
  end
  local category = errorFilter.messages[message]
  if not category then
    for knownMessage, knownCategory in pairs(errorFilter.messages) do
      if tostring(message):find(tostring(knownMessage), 1, true) then
        category = knownCategory
        break
      end
    end
  end
  if not category then return false end
  return self:GetSetting('filter' .. category:sub(1, 1):upper() .. category:sub(2) .. 'Errors')
end

function addon:RefreshErrorFilter()
  if not UIErrorsFrame then return end
  rebuildMessages()
  local enabled = self:GetSetting('errorFilter')
  if enabled and not errorFilter.installed then
    errorFilter.original = UIErrorsFrame.AddMessage
    UIErrorsFrame.AddMessage = function(frame, message, red, green, blue, ...)
      if addon:ShouldFilterError(message, red, green, blue) then return end
      return errorFilter.original(frame, message, red, green, blue, ...)
    end
    errorFilter.installed = true
  elseif not enabled and errorFilter.installed then
    UIErrorsFrame.AddMessage = errorFilter.original
    errorFilter.original = nil
    errorFilter.installed = false
  end
end

local eventFrame = CreateFrame('Frame')
eventFrame:RegisterEvent('PLAYER_LOGIN')
eventFrame:SetScript('OnEvent', function()
  addon:RefreshErrorFilter()
end)
