local TrackTargetItem = class("TrackTargetItem")
local SubUnitPath = {
  [1] = "ui/prefabs/main/track/task_pace_sub_tpl_pc",
  [2] = "ui/prefabs/main/track/task_pace_sub_tpl"
}

function TrackTargetItem:ctor()
end

function TrackTargetItem:Init(unit, parentView)
  self.unit_ = unit
  self.parentView_ = parentView
  self.subUnitDic_ = {}
  self.subUnitToken_ = {}
  Z.EventMgr:Add(Z.ConstValue.Dungeon.UpdateDungeonVar, self.RefreshDungeonVar, self)
end

function TrackTargetItem:UnInit()
  Z.EventMgr:Remove(Z.ConstValue.Dungeon.UpdateDungeonVar, self.RefreshDungeonVar, self)
  self:ClearUiUnit()
  self.unit_ = nil
  self.parentView_ = nil
  self.targetData_ = nil
  self.customIcon_ = nil
end

function TrackTargetItem:SetData(targetData, customIcon)
  self:ResetUnit()
  self.targetData_ = targetData
  self.customIcon_ = customIcon
  local targetCfg = Z.TableMgr.GetTable("TargetTableMgr").GetRow(targetData.targetId)
  if not targetCfg then
    return
  end
  local isCompelete = targetData.complete == 1
  self:SetIcon(isCompelete, customIcon, targetCfg)
  self:SetProgress(targetCfg, targetData)
  self:RefreshContent(isCompelete, targetCfg, targetData)
  Z.CoroUtil.create_coro_xpcall(function()
    self:SetDungeonVar(targetData.targetId)
  end)()
end

function TrackTargetItem:RefreshData(targetData)
  self:ResetUnit()
  self.targetData_ = targetData
  local targetCfg = Z.TableMgr.GetTable("TargetTableMgr").GetRow(targetData.targetId)
  local isCompelete = targetData.complete == 1
  self:RefreshProgress(targetData)
  self:RefreshContent(isCompelete, targetCfg, targetData)
  self:RefreshIcon(isCompelete)
end

function TrackTargetItem:SetIcon(isComplete, customIcon, targetCfg)
  if customIcon then
    self.unit_.img_bar.Img:SetImage(customIcon)
  end
  if targetCfg.TargetDes and targetCfg.TargetDes ~= "" then
    self.unit_.group_dot.Go:SetActive(true)
  else
    self.unit_.group_dot.Go:SetActive(false)
  end
  self:RefreshIcon(isComplete)
end

function TrackTargetItem:RefreshIcon(isComplete)
  if isComplete then
    self.unit_.img_on:SetVisible(true)
  elseif self.customIcon_ then
    self.unit_.img_bar:SetVisible(true)
  else
    self.unit_.img_off:SetVisible(true)
  end
end

function TrackTargetItem:efreshEffect(isComplete)
  self.unit_.ui_effect.ZEff:SetEffectGoVisible(isComplete)
end

function TrackTargetItem:RefreshContent(isComplete, targetCfg, targetData)
  if targetCfg.TargetDes and targetCfg.TargetDes ~= "" then
    self.unit_.lab_task_content.Go:SetActive(true)
    local contentNum = Lang("dungeonTargetValue", {
      val1 = targetData.nums,
      val2 = targetCfg.Num
    })
    local content = contentNum .. "  " .. targetCfg.TargetDes
    if isComplete then
      content = Z.RichTextHelper.ApplyStyleTag(content, E.TextStyleTag.JobNotActive)
    end
    self.unit_.lab_task_content.TMPLab.text = content
  else
    self.unit_.lab_task_content.Go:SetActive(false)
  end
end

function TrackTargetItem:SetProgress(targetCfg, targetData)
  self.unit_.slider_task:SetVisible(targetCfg.IsShowProgress)
  self.unit_.group_slider:SetVisible(targetCfg.IsShowProgress)
  self.unit_.slider_task.Slider.maxValue = targetCfg.Num
  self:RefreshProgress(targetData)
end

function TrackTargetItem:RefreshProgress(targetData)
  self.unit_.slider_task.Slider.value = targetData.nums
end

function TrackTargetItem:SetDungeonVar(targetId)
  local dungeonTrackVm = Z.VMMgr.GetVM("dungeon_track")
  local subTargetInfo = dungeonTrackVm.GetTargetOfDungeonVar(targetId)
  self:ClearUiUnit()
  for index, info in ipairs(subTargetInfo) do
    local name = string.format("sub_%s", info.varName)
    local token = self.parentView_.cancelSource:CreateToken()
    self.subUnitToken_[name] = token
    self.subUnitDic_[info.varName] = name
    local path = Z.IsPCUI and SubUnitPath[1] or SubUnitPath[2]
    local subUnit = self.parentView_:AsyncLoadUiUnit(path, name, self.unit_.layout_sub.Trans, token)
    self:RefreshSubUnit(subUnit, info)
  end
end

function TrackTargetItem:RefreshDungeonVar()
  Z.CoroUtil.create_coro_xpcall(function()
    if self.parentView_ == nil or not self.parentView_.IsActive then
      return
    end
    self:SetDungeonVar(self.targetData_.targetId)
  end)()
end

function TrackTargetItem:RefreshSubUnit(subUnit, info)
  if not subUnit then
    return
  end
  subUnit.lab_task_content.TMPLab.text = string.zconcat(info.varLang, "(", info.varCurVal, "/", info.varMaxVal, ")")
  subUnit.group_slider:SetVisible(info.bShowProgs == 1)
  subUnit.slider_task:SetVisible(info.bShowProgs == 1)
  subUnit.slider_task.Slider.maxValue = info.varMaxVal
  subUnit.slider_task.Slider.value = info.varCurVal
end

function TrackTargetItem:ResetUnit()
  self.unit_.img_on:SetVisible(false)
  self.unit_.img_off:SetVisible(false)
  self.unit_.img_bar:SetVisible(false)
  self.unit_.lab_task_content.TMPLab.text = ""
end

function TrackTargetItem:ClearUiUnit()
  for k, v in pairs(self.subUnitToken_) do
    Z.CancelSource.ReleaseToken(v)
  end
  self.subUnitToken_ = {}
  for varName, unitName in pairs(self.subUnitDic_) do
    self.parentView_:RemoveUiUnit(unitName)
  end
  self.subUnitDic_ = {}
end

function TrackTargetItem:OnLanguageChange()
  self:RefreshData(self.targetData_)
end

return TrackTargetItem
