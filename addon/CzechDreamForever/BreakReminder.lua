local addon = CzechDreamForever

local elapsed = 0
local reminderFrame = CreateFrame('Frame')

local function intervalSeconds()
  local minutes = addon.db and addon.db.settings and addon.db.settings.breakReminderMinutes or 60
  if minutes ~= 30 and minutes ~= 60 and minutes ~= 90 then minutes = 60 end
  return minutes * 60
end

local function showReminder()
  local message = 'Dad break: stand up, stretch and drink some water.'
  if RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo and ChatTypeInfo.RAID_WARNING then
    RaidNotice_AddMessage(RaidWarningFrame, message, ChatTypeInfo.RAID_WARNING)
  else
    addon:Print(message)
  end
  if PlaySound then
    local sound = SOUNDKIT and (SOUNDKIT.READY_CHECK or SOUNDKIT.ALARM_CLOCK_WARNING_3)
    PlaySound(sound or 8960, 'Master')
  end
end

function addon:RefreshBreakReminder()
  elapsed = 0
end

reminderFrame:SetScript('OnUpdate', function(_, delta)
  if not addon.db or not addon:GetSetting('breakReminder') then
    elapsed = 0
    return
  end

  elapsed = elapsed + delta
  if elapsed >= intervalSeconds() then
    elapsed = elapsed - intervalSeconds()
    showReminder()
  end
end)
