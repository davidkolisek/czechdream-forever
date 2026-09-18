local addon = CreateFrame('Frame')
local queue = {}
local batchInterval = 60

local function queueEvent(kind, data)
  table.insert(queue, { type = kind, payload = data, occurredAt = date('!%Y-%m-%dT%H:%M:%SZ') })
end

addon:RegisterEvent('PLAYER_LEVEL_UP')
addon:RegisterEvent('PLAYER_DEAD')
addon:RegisterEvent('LOOT_OPENED')
addon:SetScript('OnEvent', function(_, event, ...)
  queueEvent(event, {...})
end)

-- API transport will be supplied by the companion app; SavedVariables remain the durable queue.
local ticker = 0
addon:SetScript('OnUpdate', function(_, elapsed)
  ticker = ticker + elapsed
  if ticker >= batchInterval then
    ticker = 0
    CzechDreamBridgeDB = CzechDreamBridgeDB or {}
    CzechDreamBridgeDB.pending = queue
    queue = {}
  end
end)
