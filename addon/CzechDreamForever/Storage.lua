local addon = CzechDreamForever

local function defaults()
  return { crew = { name = 'CzechDream' }, player = { name = '', inviteCode = '' }, characters = {}, events = {}, peers = {} }
end

function addon:InitStorage()
  CzechDreamForeverDB = CzechDreamForeverDB or defaults()
  local db = CzechDreamForeverDB
  for key, value in pairs(defaults()) do if db[key] == nil then db[key] = value end end
  db.player.name = db.player.name ~= '' and db.player.name or UnitName('player')
  self.db = db
end

function addon:CurrentCharacter()
  local name, realm = UnitName('player'), GetRealmName()
  local key = name .. '-' .. (realm or '')
  local character = self.db.characters[key] or { name = name, realm = realm, events = {}, deaths = 0, pvpKills = 0, level = 1, played = 0 }
  character.level = UnitLevel('player') or character.level
  character.class = select(2, UnitClass('player')) or character.class
  self.db.characters[key] = character
  return character, key
end

function addon:AddEvent(kind, data)
  local character, key = self:CurrentCharacter()
  local event = { id = self:Now() .. '-' .. math.random(1000, 9999), type = kind, character = key, player = self.db.player.name, at = self:Now(), data = data or {} }
  table.insert(self.db.events, event)
  table.insert(character.events, event.id)
  while #self.db.events > self.maxEvents do table.remove(self.db.events, 1) end
  if kind == 'DEATH' then character.deaths = (character.deaths or 0) + 1 end
  if kind == 'PVP_KILL' then character.pvpKills = (character.pvpKills or 0) + 1 end
  return event
end

function addon:FindEvent(id)
  for _, event in ipairs(self.db.events) do if event.id == id then return true end end
  return false
end
