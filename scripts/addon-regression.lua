-- Run from the repository root:
-- npx --yes --package=fengari-node-cli fengari scripts/addon-regression.lua [addon directory]
local root = arg[1] or 'addon/CzechDreamForever'
local failures, count = 0, 0
local unpack = table.unpack or unpack

local function equal(actual, expected, message)
  assert(actual == expected, (message or 'value') .. ': expected ' .. tostring(expected) .. ', got ' .. tostring(actual))
end

local function world(options)
  options = options or {}
  local w = { frames = {}, timers = {}, time = 0, messages = {}, sales = {}, bags = {}, prices = {},
    shown = false, combat = false, money = 0, repairs = 0, repairCost = 0, units = {
      player = 'WARRIOR', target = 'WARLOCK', focus = 'PRIEST', party1 = 'MAGE'
    } }
  local e = setmetatable({}, { __index = _G })
  e._G = e
  w.env = e
  local function region()
    local r = { shown = true }
    for _, method in ipairs({ 'SetSize', 'SetPoint', 'SetAllPoints', 'SetWidth', 'SetHeight',
      'ClearAllPoints', 'SetFont', 'SetText', 'SetJustifyH', 'SetWordWrap', 'SetTexture',
      'SetTexCoord', 'SetColorTexture', 'SetFrameStrata', 'SetMovable', 'SetClampedToScreen',
      'EnableMouse', 'RegisterForDrag', 'SetNormalTexture', 'SetHighlightTexture',
      'SetBackdrop', 'SetBackdropColor', 'SetBackdropBorderColor', 'StartMoving', 'StopMovingOrSizing' }) do
      r[method] = function() end
    end
    function r:GetFont() return 'font', 12, '' end
    function r:GetWidth() return 140 end
    function r:Show() self.shown = true end
    function r:Hide() self.shown = false end
    function r:IsShown() return self.shown end
    function r:SetShown(value) self.shown = value == true end
    function r:CreateTexture() return region() end
    function r:CreateFontString() return region() end
    return r
  end
  e.UIParent, e.Minimap = region(), region()
  e.SlashCmdList = {}
  function e.CreateFrame()
    local f = region()
    f.events, f.scripts = {}, {}
    function f:RegisterEvent(event) self.events[event] = true end
    function f:UnregisterEvent(event) self.events[event] = nil end
    function f:SetScript(name, handler) self.scripts[name] = handler end
    function f:HookScript(name, handler)
      local previous = self.scripts[name]
      self.scripts[name] = function(...)
        if previous then previous(...) end
        handler(...)
      end
    end
    w.frames[#w.frames + 1] = f
    return f
  end
  function w:event(name, ...)
    for _, f in ipairs(self.frames) do
      if f.events[name] and f.scripts.OnEvent then f.scripts.OnEvent(f, name, ...) end
    end
  end
  function w:advance(seconds)
    for _ = 1, math.ceil(seconds / 0.05) do
      self.time = self.time + 0.05
      local ready = {}
      for i = #self.timers, 1, -1 do
        if self.timers[i].at <= self.time then
          ready[#ready + 1] = table.remove(self.timers, i)
        end
      end
      for _, timer in ipairs(ready) do timer.callback() end
      for _, f in ipairs(self.frames) do
        if f.scripts.OnUpdate then f.scripts.OnUpdate(f, 0.05) end
      end
    end
  end
  e.C_Timer = { After = function(delay, callback)
    w.timers[#w.timers + 1] = { at = w.time + delay, callback = callback }
  end }
  e.time = function() return 100 + w.time end
  e.GetTime = function() return w.time end
  e.InCombatLockdown = function() return w.combat end
  e.DEFAULT_CHAT_FRAME = { AddMessage = function(_, message) w.messages[#w.messages + 1] = message end }
  e.MerchantFrame = { IsShown = function() return w.shown end }
  e.CanMerchantRepair = function() return w.repairCost > 0 end
  e.GetRepairAllCost = function() return w.repairCost, w.repairCost > 0 end
  e.GetMoney = function() return w.money end
  e.RepairAllItems = function()
    assert(w.shown and not w.combat and w.money >= w.repairCost, 'invalid repair')
    w.money = w.money - w.repairCost
    w.repairCost = 0
    w.repairs = w.repairs + 1
  end
  local function getSlots(bag) return bag == 0 and 16 or 0 end
  local function itemAt(bag, slot) return bag == 0 and w.bags[slot] or nil end
  local function getInfo(bag, slot)
    local item = itemAt(bag, slot)
    if not item then return nil end
    if options.legacy then
      return 123, item.count, item.locked or 0, item.quality, false, false, item.link, false, item.noValue, item.id
    end
    return { iconFileID = 123, stackCount = item.count, isLocked = item.locked or false,
      quality = item.quality, hyperlink = item.link, itemID = item.id, hasNoValue = item.noValue }
  end
  local function getLink(bag, slot)
    local item = itemAt(bag, slot)
    return item and item.link
  end
  local function getItemInfo(id)
    local price = w.prices[id]
    if price == nil then return nil end
    return 'Item', tostring(id), 0, 1, 1, '', '', 20, '', 123, price
  end
  local function useItem(bag, slot)
    assert(w.shown and not w.combat, 'sale attempted outside merchant or during combat')
    local item = itemAt(bag, slot)
    assert(item and item.quality == 0, 'non-junk sold')
    w.sales[#w.sales + 1] = { at = w.time, id = item.id }
    if not options.rejectSale then
      e.C_Timer.After(0.05, function()
        if w.bags[slot] == item then
          w.money = w.money + (w.prices[item.id] or 0) * item.count
          w.bags[slot] = nil
          w:event('PLAYER_MONEY')
          w:event('BAG_UPDATE_DELAYED')
        end
      end)
    end
  end
  if options.legacy then
    e.GetContainerNumSlots, e.GetContainerItemInfo = getSlots, getInfo
    e.GetContainerItemLink, e.UseContainerItem, e.GetItemInfo = getLink, useItem, getItemInfo
  else
    e.C_Container = { GetContainerNumSlots = getSlots, GetContainerItemInfo = getInfo,
      GetContainerItemLink = getLink, UseContainerItem = useItem }
    e.C_Item = { GetItemInfo = getItemInfo }
  end
  function w:item(slot, id, quality, count, price)
    self.bags[slot] = { id = id, link = 'item:' .. id, quality = quality, count = count or 1 }
    self.prices[id], self.prices['item:' .. id] = price, price
    return self.bags[slot]
  end
  e.UnitIsPlayer = function(unit) return w.units[unit] ~= nil and w.units[unit] ~= 'NPC' end
  e.UnitIsConnected = function() return true end
  e.UnitClass = function(unit) return w.units[unit], w.units[unit] end
  e.RAID_CLASS_COLORS = {
    WARLOCK = { r = 0.58, g = 0.51, b = 0.79 }, WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
    PRIEST = { r = 1, g = 1, b = 1 }, MAGE = { r = 0.41, g = 0.8, b = 0.94 }
  }
  e.hooksecurefunc = function(target, name, callback)
    if type(target) == 'string' then callback, name, target = name, target, e end
    local previous = assert(target[name], 'hook target missing')
    target[name] = function(...)
      previous(...)
      callback(...)
    end
  end
  e.UnitFrameHealthBar_Update = function(bar, unit)
    if bar and bar.unit == unit then bar:SetStatusBarColor(0, 1, 0, 1) end
  end
  e.HealthBar_OnValueChanged = function(bar) bar:SetStatusBarColor(0, 1, 0, 1) end
  function w:bar(unit)
    local b = e.CreateFrame()
    b.unit, b.color = unit, { 0, 1, 0, 1 }
    b.texture = { desaturated = false }
    function b.texture:SetDesaturated(value) self.desaturated = value end
    function b.texture:IsDesaturated() return self.desaturated end
    function b:GetStatusBarTexture() return self.texture end
    function b:GetStatusBarColor() return unpack(self.color) end
    function b:SetStatusBarColor(r, g, blue, a) self.color = { r, g, blue, a or 1 } end
    return b
  end
  function w:load(file, ...)
    local chunk
    if setfenv then
      chunk = assert(loadfile(root .. '/' .. file)); setfenv(chunk, e)
    else
      chunk = assert(loadfile(root .. '/' .. file, 't', e))
    end
    return chunk(...)
  end
  w:load('Core.lua', 'CzechDreamForever', {})
  w.addon = e.CzechDreamForever
  w:load('Storage.lua')
  w:load('UnitFrames.lua')
  if options.ui then w:load('QuestAutomation.lua') end
  w:load('Vendor.lua')
  if options.ui then
    w:load('ErrorFilter.lua')
    w:load('UI.lua')
    w:load('Commands.lua')
  end
  function w:control(key)
    for _, frame in ipairs(self.frames) do
      if frame.key == key then return frame end
    end
    error('Missing checkbox ' .. key)
  end
  function w:login(saved)
    -- WoW runs TOC files first, then restores globals, then ADDON_LOADED.
    e.CzechDreamLiteDB = saved
    self:event('ADDON_LOADED', 'UnrelatedAddon')
    self:event('ADDON_LOADED', 'CzechDreamForever')
    self:event('PLAYER_LOGIN')
    self:advance(0.1)
  end
  function w:merchant()
    self.shown = true
    self:event('MERCHANT_SHOW')
  end
  return w
end

local function test(name, fn)
  count = count + 1
  local ok, err = pcall(fn)
  if ok then print('PASS ' .. name)
  else failures = failures + 1; print('FAIL ' .. name .. ': ' .. tostring(err)) end
end
local function ready(options)
  local w = world(options)
  w:login(nil)
  return w
end
local function assertColor(bar, r, g, b)
  equal(bar.color[1], r, 'red'); equal(bar.color[2], g, 'green'); equal(bar.color[3], b, 'blue')
end

test('saved values bind after ADDON_LOADED using the real folder name', function()
  local w = world()
  local saved = { settings = { autoSellJunk = true, autoAccept = false }, minimap = { angle = 123 } }
  w:login(saved)
  equal(w.addon.db, saved, 'saved table identity')
  equal(w.addon:GetSetting('autoSellJunk'), true)
  equal(w.addon:GetSetting('autoAccept'), false)
  equal(w.addon.db.minimap.angle, 123)
end)

test('checkbox survives two reloads, including explicit false', function()
  local w = ready()
  w.addon:SetSetting('autoSellJunk', true)
  w:event('PLAYER_LOGOUT')
  local afterReload = world()
  afterReload:login(w.env.CzechDreamLiteDB)
  equal(afterReload.addon:GetSetting('autoSellJunk'), true)
  afterReload.addon:SetSetting('autoSellJunk', false)
  afterReload:event('PLAYER_LOGOUT')
  local afterSecond = world()
  afterSecond:login(afterReload.env.CzechDreamLiteDB)
  equal(afterSecond.addon:GetSetting('autoSellJunk'), false)
end)

test('modern containers and C_Item sell grey stacks, keep other qualities', function()
  local w = ready()
  w:item(1, 101, 0, 3, 2); w:item(2, 102, 1, 1, 20); w:item(3, 103, 2, 1, 50)
  w.addon:SetSetting('autoSellJunk', true)
  w:merchant(); w:advance(2)
  equal(#w.sales, 1); equal(w.bags[1], nil); assert(w.bags[2] and w.bags[3])
  equal(w.money, 6)
  assert(table.concat(w.messages):find('Sold 3 grey items', 1, true), 'confirmed stack count missing')
end)

test('legacy API accepts numeric unlocked flag 0', function()
  local w = ready({ legacy = true })
  w:item(1, 101, 0, 1, 2)
  w.addon:SetSetting('autoSellJunk', true)
  w:merchant(); w:advance(2)
  equal(#w.sales, 1)
end)

test('enable auto-sell while vendor is already open', function()
  local w = ready()
  w:item(1, 101, 0, 1, 2)
  w:merchant(); w:advance(1); equal(#w.sales, 0)
  w.addon:SetSetting('autoSellJunk', true)
  w:advance(2); equal(#w.sales, 1)
end)

test('multiple sales are paced rather than sent in a single burst', function()
  local w = ready()
  for i = 1, 5 do w:item(i, 100 + i, 0, 1, 2) end
  w.addon:SetSetting('autoSellJunk', true)
  w:merchant(); w:advance(3); equal(#w.sales, 5)
  for i = 2, #w.sales do assert(w.sales[i].at - w.sales[i - 1].at >= 0.14, 'sales not paced') end
end)

test('locked and uncached items retry after bag/item-data updates', function()
  local w = ready()
  local locked = w:item(1, 101, 0, 1, 2); locked.locked = true
  w:item(2, 102, 0, 1, nil)
  w.addon:SetSetting('autoSellJunk', true); w:merchant(); w:advance(1)
  equal(#w.sales, 0)
  locked.locked = false
  w:event('ITEM_LOCK_CHANGED'); w:advance(1); equal(#w.sales, 1)
  w.prices[102], w.prices['item:102'] = 5, 5
  w:event('GET_ITEM_INFO_RECEIVED', 102, true); w:advance(1); equal(#w.sales, 2)
end)

test('zero-value and explicitly unsellable items are not used', function()
  local w = ready()
  w:item(1, 101, 0, 1, 0)
  w:item(2, 102, 0, 1, 2).noValue = true
  w.addon:SetSetting('autoSellJunk', true); w:merchant(); w:advance(2)
  equal(#w.sales, 0)
end)

test('closing merchant cancels remaining sales', function()
  local w = ready()
  for i = 1, 5 do w:item(i, 100 + i, 0, 1, 2) end
  w.addon:SetSetting('autoSellJunk', true); w:merchant(); w:advance(0.16)
  equal(#w.sales, 1)
  w.shown = false; w:event('MERCHANT_CLOSED'); w:advance(2)
  equal(#w.sales, 1)
end)

test('disabling the checkbox cancels remaining sales', function()
  local w = ready()
  for i = 1, 5 do w:item(i, 100 + i, 0, 1, 2) end
  w.addon:SetSetting('autoSellJunk', true); w:merchant(); w:advance(0.16)
  w.addon:SetSetting('autoSellJunk', false); w:advance(2)
  equal(#w.sales, 1)
end)

test('combat pauses sales and leaving combat resumes at the open merchant', function()
  local w = ready()
  w:item(1, 101, 0, 1, 2)
  w.addon:SetSetting('autoSellJunk', true)
  w.combat = true; w:merchant(); w:advance(1); equal(#w.sales, 0)
  w.combat = false; w:event('PLAYER_REGEN_ENABLED'); w:advance(1); equal(#w.sales, 1)
end)

test('missing merchant frame never permits item use', function()
  local w = ready()
  w.env.MerchantFrame = nil
  w:item(1, 101, 0, 1, 2)
  w.addon:SetSetting('autoSellJunk', true); w:event('MERCHANT_SHOW'); w:advance(1)
  equal(#w.sales, 0)
end)

test('rejected sales do not report success or repeat forever', function()
  local w = ready({ rejectSale = true })
  w:item(1, 101, 0, 1, 2)
  w.addon:SetSetting('autoSellJunk', true); w:merchant(); w:advance(5)
  equal(#w.sales, 1)
  assert(not table.concat(w.messages):find('Sold ', 1, true), 'false success message')
end)

test('junk proceeds can fund a pending repair', function()
  local w = ready()
  w.repairCost = 5
  w:item(1, 101, 0, 3, 2)
  w.addon:SetSetting('autoSellJunk', true); w:merchant(); w:advance(2)
  equal(w.repairs, 1); equal(w.money, 1)
end)

test('Forever nested player/target/focus/party frames get class colours', function()
  local w = world()
  local e = w.env
  local p, t, f, party = w:bar('player'), w:bar('target'), w:bar('focus'), w:bar('party1')
  e.PlayerFrame = { PlayerFrameContent = { PlayerFrameContentMain = { HealthBarsContainer = { HealthBar = p } } } }
  e.TargetFrame = { TargetFrameContent = { TargetFrameContentMain = { HealthBarsContainer = { HealthBar = t } } } }
  e.FocusFrame = { TargetFrameContent = { TargetFrameContentMain = { HealthBarsContainer = { HealthBar = f } } } }
  e.PartyFrame = { PartyMemberFrame1 = { HealthBarContainer = { HealthBar = party } } }
  w:login(nil)
  assertColor(t, 0.58, 0.51, 0.79); assertColor(p, 0.78, 0.61, 0.43)
  assertColor(f, 1, 1, 1); assertColor(party, 0.41, 0.8, 0.94)
end)

test('late Blizzard colour writes cannot overwrite the class colour', function()
  local w = ready()
  local bar = w:bar('target')
  w.env.TargetFrame = { healthbar = bar }
  w:event('PLAYER_TARGET_CHANGED'); w:advance(1)
  bar:SetStatusBarColor(0, 1, 0)
  assertColor(bar, 0.58, 0.51, 0.79)
  w.env.UnitFrameHealthBar_Update(bar, 'target')
  w.env.HealthBar_OnValueChanged(bar)
  assertColor(bar, 0.58, 0.51, 0.79)
end)

test('coloured atlas is desaturated, NPC restores its current native colour', function()
  local w = ready()
  local bar = w:bar('target')
  w.env.TargetFrameHealthBar = bar
  w:event('PLAYER_TARGET_CHANGED'); w:advance(1)
  equal(bar.texture.desaturated, true)
  w.units.target = 'NPC'
  bar:SetStatusBarColor(1, 0, 0)
  w:event('PLAYER_TARGET_CHANGED'); w:advance(1)
  assertColor(bar, 1, 0, 0); equal(bar.texture.desaturated, false)
end)

test('turning class colours off restores native colour and texture immediately', function()
  local w = ready()
  local bar = w:bar('target')
  w.env.TargetFrame = { healthbar = bar }
  w:event('PLAYER_TARGET_CHANGED'); w:advance(1)
  bar:SetStatusBarColor(0, 1, 0)
  w.addon:SetSetting('classColoredFrames', false)
  assertColor(bar, 0, 1, 0); equal(bar.texture.desaturated, false)
end)

test('repeated target changes neither stack hooks nor tint mana bars', function()
  local w = ready()
  local bar, mana = w:bar('target'), w:bar('target')
  w.env.TargetFrame = { healthbar = bar, manabar = mana }
  for i = 1, 20 do
    w.units.target = i % 2 == 0 and 'WARLOCK' or 'MAGE'
    w:event('PLAYER_TARGET_CHANGED'); w:advance(0.1)
  end
  bar:SetStatusBarColor(0, 1, 0)
  assertColor(bar, 0.58, 0.51, 0.79)
  mana:SetStatusBarColor(0, 0, 1)
  assertColor(mana, 0, 0, 1)
end)

test('actual UI checkbox sells at open vendor and stays checked after reopening/reload', function()
  local w = ready({ ui = true })
  w:item(1, 101, 0, 1, 2)
  w:merchant(); w:advance(1)
  w.addon:ToggleUI()
  local control = w:control('autoSellJunk')
  equal(control.box.mark.shown, false)
  control.scripts.OnClick(control)
  equal(control.box.mark.shown, true)
  w.addon:ToggleUI(); w:advance(1)
  equal(#w.sales, 1)
  w.addon:ToggleUI(); equal(control.box.mark.shown, true)
  w:event('PLAYER_LOGOUT')
  local reloaded = world({ ui = true })
  reloaded:login(w.env.CzechDreamLiteDB)
  reloaded.addon:ToggleUI()
  equal(reloaded:control('autoSellJunk').box.mark.shown, true)
  reloaded.env.SlashCmdList.CZECHDREAMLITE('debug')
  assert(table.concat(reloaded.messages):find('saved settings linked=true', 1, true))
end)

print(string.format('%d/%d passed', count - failures, count))
if failures > 0 then os.exit(1) end
