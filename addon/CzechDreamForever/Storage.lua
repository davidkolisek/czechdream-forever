local addon = CzechDreamForever

local function defaults()
  return {
    settings = {
      classColoredFrames = true,
      autoAccept = true,
      autoTurnIn = true,
      autoReward = true,
      autoRepair = true,
      autoSellJunk = false,
      errorFilter = false,
      filterAllErrors = false,
      filterResourceErrors = true,
      filterCooldownErrors = true,
      filterRangeErrors = true,
      filterInventoryErrors = false,
      breakReminder = false,
      breakReminderMinutes = 60
    },
    minimap = {
      hide = false,
      angle = 45
    }
  }
end

local function mergeMissing(target, source)
  for key, value in pairs(source) do
    if target[key] == nil then
      if type(value) == 'table' then
        target[key] = {}
        mergeMissing(target[key], value)
      else
        target[key] = value
      end
    elseif type(value) == 'table' and type(target[key]) == 'table' then
      mergeMissing(target[key], value)
    end
  end
end

function addon:InitDB()
  if type(CzechDreamLiteDB) ~= 'table' then CzechDreamLiteDB = {} end
  if type(CzechDreamLiteDB.settings) ~= 'table' then CzechDreamLiteDB.settings = {} end
  if type(CzechDreamLiteDB.minimap) ~= 'table' then CzechDreamLiteDB.minimap = {} end
  mergeMissing(CzechDreamLiteDB, defaults())

  -- The original build placed the button well inside the minimap. Move only
  -- that untouched default once; a position chosen by the player is kept.
  if (CzechDreamLiteDB.layoutVersion or 1) < 2 then
    if CzechDreamLiteDB.minimap.angle == 225 then
      CzechDreamLiteDB.minimap.angle = 45
    end
    CzechDreamLiteDB.layoutVersion = 2
  end

  self.db = CzechDreamLiteDB
end

local saveFrame = CreateFrame('Frame')
saveFrame:RegisterEvent('ADDON_LOADED')
saveFrame:RegisterEvent('PLAYER_LOGOUT')
saveFrame:SetScript('OnEvent', function(self, event, loadedAddon)
  if event == 'ADDON_LOADED' and loadedAddon == addon.folderName then
    -- SavedVariables are loaded AFTER the files in the TOC. Binding earlier
    -- leaves addon.db pointing at defaults instead of the restored table.
    addon:InitDB()
    self:UnregisterEvent('ADDON_LOADED')
  elseif event == 'PLAYER_LOGOUT' then
    addon:SaveDB()
  end
end)
