local addon = CzechDreamForever
local vendorFrame = CreateFrame('Frame')
local open = false
local running = false
local elapsed = 0
local pending
local attempted = {}
local sold = 0
local repairPending = false
local lastRepairNotice = 0

local function merchantIsOpen()
  return MerchantFrame and MerchantFrame:IsShown()
end

local function inCombat()
  return InCombatLockdown and InCombatLockdown()
end

local function repair()
  if not addon:GetSetting('autoRepair') or not merchantIsOpen() or inCombat()
    or not CanMerchantRepair or not CanMerchantRepair() then return end
  local cost = GetRepairAllCost and GetRepairAllCost() or 0
  if cost <= 0 then repairPending = false; return end
  local money = GetMoney and GetMoney() or 0
  if money >= cost then
    if RepairAllItems then RepairAllItems(false) end
    repairPending = false
  else
    repairPending = true
    if addon:Now() - lastRepairNotice > 10 then
      addon:Print('Repair waiting for ' .. (cost - money) .. ' copper.')
      lastRepairNotice = addon:Now()
    end
  end
end

local function isTrue(value)
  return value == true or value == 1
end

local function containerSlots(bag)
  local getSlots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
  return getSlots and getSlots(bag) or 0
end

local function containerInfo(bag, slot)
  local getInfo = C_Container and C_Container.GetContainerItemInfo or GetContainerItemInfo
  if not getInfo then return nil end
  local icon, count, locked, quality, _, _, link, _, noValue, itemID = getInfo(bag, slot)
  if type(icon) == 'table' then
    local info = icon
    count, locked = info.stackCount or info.count, info.isLocked
    quality, link = info.quality or info.itemQuality, info.hyperlink
    noValue, itemID = info.hasNoValue, info.itemID
  elseif not icon then
    return nil
  end
  if not link then
    local getLink = C_Container and C_Container.GetContainerItemLink or GetContainerItemLink
    link = getLink and getLink(bag, slot)
  end
  local price
  local getItem = C_Item and C_Item.GetItemInfo or GetItemInfo
  if getItem and (link or itemID) then
    local _, _, itemQuality, _, _, _, _, _, _, _, sellPrice = getItem(link or itemID)
    if quality == nil then quality = itemQuality end
    price = sellPrice
  end
  return {
    count = count or 1, locked = isTrue(locked), quality = quality,
    noValue = isTrue(noValue), price = price, identity = itemID or link
  }
end

local function stop()
  running = false
  vendorFrame:SetScript('OnUpdate', nil)
  if sold > 0 then
    addon:Print('Sold ' .. sold .. ' grey item' .. (sold == 1 and '' or 's') .. '.')
    sold = 0
  end
end

local function step()
  -- Each item is rechecked immediately before selling. Closing the vendor,
  -- disabling the option or entering combat cancels the rest of the batch.
  if not open or not merchantIsOpen() or inCombat() or not addon:GetSetting('autoSellJunk') then
    pending = nil
    stop()
    return
  end

  if pending then
    local current = containerInfo(pending.bag, pending.slot)
    if not current or current.identity ~= pending.identity or current.count < pending.count then
      sold = sold + (current and current.identity == pending.identity
        and (pending.count - current.count) or pending.count)
      pending = nil
    else
      pending.wait = pending.wait + 0.15
      if pending.wait < 1.5 then return end
      -- A rejected sale must not spin forever or be reported as successful.
      pending = nil
    end
  end

  local useItem = C_Container and C_Container.UseContainerItem or UseContainerItem
  if not useItem then stop(); return end
  for bag = 0, (NUM_BAG_SLOTS or 4) do
    for slot = containerSlots(bag), 1, -1 do
      local info = containerInfo(bag, slot)
      if info and info.quality == 0 and not info.locked and not info.noValue
        and info.price and info.price > 0 and info.identity then
        local key = bag .. ':' .. slot .. ':' .. tostring(info.identity) .. ':' .. info.count
        if not attempted[key] then
          attempted[key] = true
          pending = {
            bag = bag, slot = slot, identity = info.identity, count = info.count, wait = 0
          }
          -- XarMods spaces sales by 0.15 s. Keep that pacing, but never use a
          -- stale queued bag slot after the player closes the merchant.
          useItem(bag, slot)
          return
        end
      end
    end
  end
  stop()
end

local function wake()
  if running or not open or not merchantIsOpen() or inCombat()
    or not addon:GetSetting('autoSellJunk') then return end
  elapsed = 0
  running = true
  vendorFrame:SetScript('OnUpdate', function(_, delta)
    elapsed = elapsed + delta
    if elapsed >= 0.15 then
      elapsed = 0
      step()
    end
  end)
end

function addon:RefreshVendorAutomation()
  if not merchantIsOpen() then return end
  open = true
  attempted = {}
  if not self:GetSetting('autoSellJunk') then
    pending = nil
    stop()
  else
    wake()
  end
  if not self:GetSetting('autoRepair') then repairPending = false end
  repair()
end

for _, event in ipairs({ 'MERCHANT_SHOW', 'MERCHANT_CLOSED', 'PLAYER_MONEY',
  'BAG_UPDATE_DELAYED', 'ITEM_LOCK_CHANGED', 'GET_ITEM_INFO_RECEIVED',
  'PLAYER_REGEN_ENABLED', 'PLAYER_REGEN_DISABLED' }) do
  vendorFrame:RegisterEvent(event)
end
vendorFrame:SetScript('OnEvent', function(_, event)
  if event == 'MERCHANT_SHOW' then
    stop()
    open = true
    attempted = {}
    pending = nil
    wake()
    repair()
  elseif event == 'MERCHANT_CLOSED' then
    open = false
    pending = nil
    repairPending = false
    stop()
  elseif event == 'PLAYER_REGEN_DISABLED' then
    pending = nil
    stop()
  elseif event == 'PLAYER_MONEY' then
    if repairPending then repair() end
    wake()
  elseif event == 'PLAYER_REGEN_ENABLED' then
    if open then repair(); wake() end
  elseif open then
    -- Cache misses and locked items are retried when the bag data changes.
    wake()
  end
end)

function addon:PrintVendorDiagnostics()
  local grey, eligible, locked, uncached = 0, 0, 0, 0
  for bag = 0, (NUM_BAG_SLOTS or 4) do
    for slot = 1, containerSlots(bag) do
      local info = containerInfo(bag, slot)
      if info and info.quality == 0 then
        grey = grey + 1
        if info.locked then locked = locked + 1 end
        if info.price == nil then uncached = uncached + 1 end
        if not info.locked and not info.noValue and info.price and info.price > 0 then
          eligible = eligible + 1
        end
      end
    end
  end
  self:Print('Vendor open=' .. tostring(merchantIsOpen() or false)
    .. ', grey stacks=' .. grey .. ', sellable=' .. eligible
    .. ', locked=' .. locked .. ', waiting for item data=' .. uncached)
end
