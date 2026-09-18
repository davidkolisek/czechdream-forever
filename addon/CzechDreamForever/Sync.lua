local addon = CzechDreamForever
local syncFrame = CreateFrame('Frame')

local function encode(value)
  if type(value) == 'table' then
    local parts = {}
    for key, item in pairs(value) do table.insert(parts, encode(key) .. '=' .. encode(item)) end
    return '{' .. table.concat(parts, ',') .. '}'
  end
  return tostring(value or ''):gsub('%%', '%%25'):gsub(';', '%%3B'):gsub('=', '%%3D'):gsub(',', '%%2C')
end

local function decode(value)
  return value:gsub('%%2C', ','):gsub('%%3D', '='):gsub('%%3B', ';'):gsub('%%25', '%%')
end

function addon:Serialize(event)
  local fields = { id = event.id, type = event.type, character = event.character, player = event.player, at = event.at }
  for key, value in pairs(event.data or {}) do fields['data_' .. key] = value end
  local result = {}
  for key, value in pairs(fields) do table.insert(result, key .. '=' .. encode(value)) end
  return table.concat(result, ';')
end

function addon:Deserialize(raw)
  local result = {}
  for pair in raw:gmatch('[^;]+') do local key, value = pair:match('^([^=]+)=(.*)$'); if key then result[key] = decode(value) end end
  result.at = tonumber(result.at) or self:Now()
  return result
end

function addon:InitSync()
  C_ChatInfo.RegisterAddonMessagePrefix(self.prefix)
  syncFrame:RegisterEvent('CHAT_MSG_ADDON')
  syncFrame:SetScript('OnEvent', function(_, event, prefix, message, channel, sender)
    if event ~= 'CHAT_MSG_ADDON' or prefix ~= addon.prefix or sender == UnitName('player') then return end
    local command, body = message:match('^(%w+)|?(.*)$')
    if command == 'HELLO' then addon:Send('WELCOME', { player = addon.db.player.name }, 'WHISPER', sender)
    elseif command == 'EVENT' and body ~= '' then addon:ReceiveEvent(body, sender)
    elseif command == 'WELCOME' then addon:AddPeer(sender); addon:Print(sender .. ' je online v CzechDream crew.')
    elseif command == 'REQUEST' then addon:SendEvents(sender) end
  end)
end

function addon:Send(command, body, channel, target)
  local payload = command
  if type(body) == 'table' and body.id then payload = payload .. '|' .. self:Serialize(body)
  elseif type(body) == 'table' then payload = payload .. '|' .. encode(body)
  elseif body then payload = payload .. '|' .. tostring(body) end
  C_ChatInfo.SendAddonMessage(self.prefix, payload, channel or 'GUILD', target)
end

function addon:BroadcastLatest()
  local event = self.db.events[#self.db.events]
  if event then self:Send('EVENT', event, 'GUILD') end
end

function addon:ReceiveEvent(raw, sender)
  local event = self:Deserialize(raw)
  if event.id and not self:FindEvent(event.id) then
    event.remoteSender = sender; table.insert(self.db.events, event); self:AddPeer(sender); self:RefreshUI(); self:Print('Nový event od ' .. sender .. '.')
  end
end

function addon:AddPeer(name)
  self.db.peers[name] = self.db.peers[name] or { name = name, lastSeen = self:Now() }
  self.db.peers[name].lastSeen = self:Now()
end

function addon:SendEvents(target)
  for _, event in ipairs(self.db.events) do self:Send('EVENT', event, 'WHISPER', target) end
end
