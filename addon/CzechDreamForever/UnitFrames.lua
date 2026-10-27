local addon = CzechDreamForever

local frameSpecs = {
  { frame = 'PlayerFrame', bar = 'PlayerFrameHealthBar', unit = 'player' },
  { frame = 'TargetFrame', bar = 'TargetFrameHealthBar', unit = 'target' },
  { frame = 'FocusFrame', bar = 'FocusFrameHealthBar', unit = 'focus' }
}
for index = 1, 4 do
  frameSpecs[#frameSpecs + 1] = {
    frame = 'PartyMemberFrame' .. index,
    bar = 'PartyMemberFrame' .. index .. 'HealthBar',
    unit = 'party' .. index
  }
end

-- The same Blizzard palette used by XarMods, with a fallback for older clients.
local fallbackColors = {
  WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
  PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
  HUNTER = { r = 0.67, g = 0.83, b = 0.45 },
  ROGUE = { r = 1, g = 0.96, b = 0.41 },
  PRIEST = { r = 1, g = 1, b = 1 },
  SHAMAN = { r = 0, g = 0.44, b = 0.87 },
  MAGE = { r = 0.41, g = 0.8, b = 0.94 },
  WARLOCK = { r = 0.58, g = 0.51, b = 0.79 },
  DRUID = { r = 1, g = 0.49, b = 0.04 },
  DEATHKNIGHT = { r = 0.77, g = 0.12, b = 0.23 },
  MONK = { r = 0, g = 1, b = 0.59 },
  DEMONHUNTER = { r = 0.64, g = 0.19, b = 0.79 },
  EVOKER = { r = 0.2, g = 0.58, b = 0.5 }
}

local function getHealthBar(spec)
  local holder = _G[spec.frame] or (PartyFrame and PartyFrame[spec.frame])
  if holder then
    if holder.healthbar then return holder.healthbar end
    if holder.HealthBar then return holder.HealthBar end
    if holder.HealthBarContainer then return holder.HealthBarContainer.HealthBar end

    local content = holder.PlayerFrameContent or holder.TargetFrameContent
    local main = content and (content.PlayerFrameContentMain or content.TargetFrameContentMain)
    if main then
      local container = main.HealthBarsContainer
      if container and container.HealthBar then return container.HealthBar end
      if main.HealthBar then return main.HealthBar end
    end
  end
  return _G[spec.bar]
end

local function classColor(unit)
  if not unit or not UnitIsPlayer(unit) then return nil end
  local _, token = UnitClass(unit)
  if not token then return nil end
  return (RAID_CLASS_COLORS and RAID_CLASS_COLORS[token])
    or (C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(token))
    or fallbackColors[token]
end

local bars = setmetatable({}, { __mode = 'k' })
local function applyColor(bar, state)
  if state.applying then return end
  local color = addon:GetSetting('classColoredFrames') and classColor(bar.unit or state.unit)
  local texture = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
  state.applying = true
  if color then
    -- Modern Blizzard health atlases are already green. Desaturate the fill
    -- before tinting so the atlas does not distort purple/blue class colours.
    if texture and texture.SetDesaturated then
      if state.texture ~= texture then
        state.texture = texture
        state.desaturated = texture.IsDesaturated and texture:IsDesaturated() or false
      end
      texture:SetDesaturated(true)
    end
    bar:SetStatusBarColor(color.r, color.g, color.b)
    state.colored = true
  elseif state.colored then
    if state.texture and state.texture.SetDesaturated then
      state.texture:SetDesaturated(state.desaturated)
    end
    local native = state.native
    bar:SetStatusBarColor(native[1], native[2], native[3], native[4])
    state.colored = false
    state.texture = nil
  end
  state.applying = false
end

local function trackBar(bar, unit)
  if not bar or not bar.SetStatusBarColor or not bar.GetStatusBarColor then return end
  local state = bars[bar]
  if not state then
    state = { unit = unit, native = { bar:GetStatusBarColor() } }
    bars[bar] = state
    -- Blizzard can recolour a bar outside UnitFrameHealthBar_Update. A secure
    -- post-hook on this specific health bar also covers those later writes.
    if hooksecurefunc then
      hooksecurefunc(bar, 'SetStatusBarColor', function(_, r, g, b, a)
        if state.applying then return end
        state.native = { r, g, b, a }
        applyColor(bar, state)
      end)
    end
    if bar.HookScript then
      bar:HookScript('OnValueChanged', function() applyColor(bar, state) end)
      bar:HookScript('OnShow', function() applyColor(bar, state) end)
    end
  end
  state.unit = unit
  applyColor(bar, state)
end

function addon:RefreshClassColoredFrames()
  if not self.db then return end
  for _, spec in ipairs(frameSpecs) do
    trackBar(getHealthBar(spec), spec.unit)
  end
end

local hooks = {}
local function onHealthUpdated(bar, unit)
  unit = unit or (bar and bar.unit)
  if not unit then return end
  for _, spec in ipairs(frameSpecs) do
    if spec.unit == unit and getHealthBar(spec) == bar then
      trackBar(bar, unit)
      return
    end
  end
end

local function installHooks()
  if not hooksecurefunc then return end
  for _, name in ipairs({ 'UnitFrameHealthBar_Update', 'HealthBar_OnValueChanged' }) do
    if not hooks[name] and type(_G[name]) == 'function' then
      if name == 'HealthBar_OnValueChanged' then
        hooksecurefunc(name, function(bar) onHealthUpdated(bar) end)
      else
        hooksecurefunc(name, onHealthUpdated)
      end
      hooks[name] = true
    end
  end
end

local refreshQueued = false
local function refresh()
  installHooks()
  addon:RefreshClassColoredFrames()
  if not refreshQueued and C_Timer and C_Timer.After then
    refreshQueued = true
    C_Timer.After(0, function()
      refreshQueued = false
      addon:RefreshClassColoredFrames()
    end)
  end
end

local eventFrame = CreateFrame('Frame')
for _, event in ipairs({ 'PLAYER_LOGIN', 'PLAYER_ENTERING_WORLD', 'PLAYER_TARGET_CHANGED',
  'PLAYER_FOCUS_CHANGED', 'GROUP_ROSTER_UPDATE', 'UNIT_CONNECTION', 'UNIT_FACTION', 'ADDON_LOADED' }) do
  eventFrame:RegisterEvent(event)
end
eventFrame:SetScript('OnEvent', function(_, event, unit)
  if not addon.db then return end
  if event == 'ADDON_LOADED' and unit ~= 'Blizzard_UnitFrame' and unit ~= addon.folderName then return end
  refresh()
end)

function addon:PrintFrameDiagnostics()
  for _, spec in ipairs(frameSpecs) do
    if spec.unit == 'player' or spec.unit == 'target' then
      local bar = getHealthBar(spec)
      local _, token = UnitClass(spec.unit)
      local r, g, b
      if bar then r, g, b = bar:GetStatusBarColor() end
      self:Print(spec.unit .. ': class=' .. tostring(token)
        .. ', player=' .. tostring(UnitIsPlayer(spec.unit))
        .. ', bar=' .. tostring(bar ~= nil)
        .. ', RGB=' .. (r and string.format('%.2f/%.2f/%.2f', r, g, b) or 'unavailable'))
    end
  end
end
