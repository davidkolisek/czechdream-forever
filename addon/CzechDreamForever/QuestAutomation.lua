local addon = CzechDreamForever

local questFrame = CreateFrame('Frame')
local skipInteraction = false

local function later(callback)
  if C_Timer and C_Timer.After then
    C_Timer.After(0, callback)
  else
    callback()
  end
end

local function isTrue(value)
  return value == true or value == 1 or value == '1'
end

local function isQuestLogEntryComplete(title)
  if not title or not GetNumQuestLogEntries or not GetQuestLogTitle then return nil end

  local count = GetNumQuestLogEntries()
  for index = 1, count do
    local logTitle, _, _, _, isHeader, _, isComplete = GetQuestLogTitle(index)
    if not isHeader and logTitle == title then
      return isTrue(isComplete)
    end
  end

  return nil
end

local function selectClassicGossipQuest()
  if not GetGossipActiveQuests or not GetGossipAvailableQuests then return false end

  if addon:GetSetting('autoTurnIn') then
    local active = { GetGossipActiveQuests() }
    local activeCount = math.floor(#active / 6)
    for index = 1, activeCount do
      local offset = (index - 1) * 6
      local complete = active[offset + 4]
      if isTrue(complete) and SelectGossipActiveQuest then
        SelectGossipActiveQuest(index)
        return true
      end
    end
  end

  if addon:GetSetting('autoAccept') then
    local available = { GetGossipAvailableQuests() }
    local availableCount = math.floor(#available / 6)
    if availableCount > 0 and SelectGossipAvailableQuest then
      SelectGossipAvailableQuest(1)
      return true
    end
  end
  return false
end

local function selectGreetingQuest()
  if not GetNumActiveQuests or not GetNumAvailableQuests then return false end

  -- QUEST_GREETING does not expose a completion flag. Resolve each active
  -- quest against the quest log instead of blindly selecting active quest 1.
  -- Unknown status is deliberately treated as incomplete for safety.
  if addon:GetSetting('autoTurnIn') and GetNumActiveQuests() > 0 and SelectActiveQuest and GetActiveTitle then
    local activeCount = GetNumActiveQuests()
    for index = 1, activeCount do
      local title = GetActiveTitle(index)
      if isQuestLogEntryComplete(title) == true then
        SelectActiveQuest(index)
        return true
      end
    end
  end

  if addon:GetSetting('autoAccept') and GetNumAvailableQuests() > 0 and SelectAvailableQuest then
    SelectAvailableQuest(1)
    return true
  end
  return false
end

local function acceptQuest()
  if not addon:GetSetting('autoAccept') or skipInteraction then return end
  if AcceptQuest then AcceptQuest() end
end

local function turnInQuest()
  if not addon:GetSetting('autoTurnIn') or skipInteraction then return end
  if IsQuestCompletable and IsQuestCompletable() and CompleteQuest then
    CompleteQuest()
  end
end

local function rewardQuest()
  if not addon:GetSetting('autoTurnIn') or not addon:GetSetting('autoReward') or skipInteraction then return end
  local choices = GetNumQuestChoices and GetNumQuestChoices() or 0
  if choices == 0 and GetQuestReward then
    GetQuestReward()
  elseif choices == 1 and GetQuestReward then
    GetQuestReward(1)
  elseif choices > 1 then
    addon:Print('Quest has multiple rewards. Choose the reward manually.')
  end
end

questFrame:RegisterEvent('GOSSIP_SHOW')
questFrame:RegisterEvent('QUEST_GREETING')
questFrame:RegisterEvent('QUEST_DETAIL')
questFrame:RegisterEvent('QUEST_PROGRESS')
questFrame:RegisterEvent('QUEST_COMPLETE')
questFrame:RegisterEvent('QUEST_FINISHED')
questFrame:RegisterEvent('GOSSIP_CLOSED')
questFrame:SetScript('OnEvent', function(_, event)
  if event == 'GOSSIP_SHOW' then
    skipInteraction = addon:IsShiftDown()
    if skipInteraction then return end
    if not addon:GetSetting('autoAccept') and not addon:GetSetting('autoTurnIn') then return end
    later(function()
      if not skipInteraction then selectClassicGossipQuest() end
    end)
  elseif event == 'QUEST_GREETING' then
    skipInteraction = addon:IsShiftDown()
    if skipInteraction then return end
    if not addon:GetSetting('autoAccept') and not addon:GetSetting('autoTurnIn') then return end
    later(function()
      if not skipInteraction then selectGreetingQuest() end
    end)
  elseif event == 'QUEST_DETAIL' then
    if not skipInteraction then acceptQuest() end
  elseif event == 'QUEST_PROGRESS' then
    if not skipInteraction then turnInQuest() end
  elseif event == 'QUEST_COMPLETE' then
    if not skipInteraction then rewardQuest() end
  elseif event == 'QUEST_FINISHED' or event == 'GOSSIP_CLOSED' then
    skipInteraction = false
  end
end)
