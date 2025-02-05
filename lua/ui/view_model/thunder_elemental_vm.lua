local closeTooltipView = function()
  Z.UIMgr:CloseView("thunder_elemental_tooltip_window")
end
local openTooltipView = function()
  local thunderElementalData = Z.DataMgr.Get("thunder_elemental_tooltip_data")
  if thunderElementalData.DungeonHideTag and thunderElementalData.MainViewHideTag then
    Z.UIMgr:OpenView("thunder_elemental_tooltip_window")
  elseif Z.UIMgr:IsActive("thunder_elemental_tooltip_window") then
    Z.UIMgr:GetView("thunder_elemental_tooltip_window"):Hide()
  end
end
local setMainViewHideTag = function(isVisible)
  local thunderElementalData = Z.DataMgr.Get("thunder_elemental_tooltip_data")
  thunderElementalData:SetMainViewHideTag(isVisible)
  openTooltipView()
end
local setDungeonHideTag = function(isVisible)
  local thunderElementalData = Z.DataMgr.Get("thunder_elemental_tooltip_data")
  thunderElementalData:SetDungeonViewHideTag(isVisible)
  openTooltipView()
end
local getDungeonTimerData = function(timerType)
  local timerData = {}
  if timerType == E.DungeonTimerType.DungeonTimerTypeMiddlerCommon then
    local limitTime = Z.Global.TimeLimitQuestAlert
    if not string.zisEmpty(limitTime) then
      limitTime = tonumber(limitTime)
    end
    timerData.timeLimitNumber = limitTime
  end
  return timerData
end
local ret = {
  OpenTooltipView = openTooltipView,
  CloseTooltipView = closeTooltipView,
  SetMainViewHideTag = setMainViewHideTag,
  SetDungeonHideTag = setDungeonHideTag,
  GetDungeonTimerData = getDungeonTimerData
}
return ret
