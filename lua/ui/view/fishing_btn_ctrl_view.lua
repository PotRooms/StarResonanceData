local UI = Z.UI
local super = require("ui.ui_subview_base")
local Fishing_btn_ctrlView = class("Fishing_btn_ctrlView", super)

function Fishing_btn_ctrlView:ctor(parent)
  self.uiBinder = nil
  super.ctor(self, "fishing_btn_ctrl", "fishing/fishing_btn_ctrl", UI.ECacheLv.None)
  self.fishingVM = Z.VMMgr.GetVM("fishing")
  self.fishingData = Z.DataMgr.Get("fishing_data")
  self.longPressTimer = nil
  self.isClicking_ = false
  self.uiBinder = nil
  self.fishingIconPath = {
    [E.FishingBtnIconType.CastFishingRod] = "ui/atlas/skill/fishing_icon_prompt",
    [E.FishingBtnIconType.HarvestingRod] = "ui/atlas/skill/fishing_icon_harvest",
    [E.FishingBtnIconType.HookingUp] = "ui/atlas/skill/fishing_icon_bait"
  }
  
  function self.onDownEvent(inputActionEventData)
    self.isClicking_ = true
    if self.uiBinder == nil then
      return
    end
    self.uiBinder.Ref:SetVisible(self.uiBinder.img_select, true)
    self:onFishingBtnClick()
    self.fishingData:SetIsDraging(true)
    Z.PlayerInputController:Fishing(true)
  end
  
  function self.onUpEvent(inputActionEventData)
    self.isClicking_ = false
    if self.uiBinder == nil then
      return
    end
    self.uiBinder.Ref:SetVisible(self.uiBinder.img_select, false)
    self.fishingData:SetIsDraging(false)
    Z.PlayerInputController:Fishing(false)
  end
end

function Fishing_btn_ctrlView:OnActive()
  local btnTrigger = self.uiBinder.touch_area
  if self.uiBinder ~= nil then
    self.uiBinder.Ref:SetVisible(self.uiBinder.img_select, false)
  end
  btnTrigger.onDown:AddListener(function()
    self.onDownEvent()
  end)
  btnTrigger.onUp:AddListener(function()
    self.onUpEvent()
  end)
  self:onFishingStageChanged()
  self:registerBtnEvent()
  if Z.IsPCUI then
    self.uiBinder.Ref.UIComp:SetVisible(false)
  end
  Z.EventMgr:Add(Z.ConstValue.Fishing.FishingStateChange, self.onFishingStageChanged, self)
end

function Fishing_btn_ctrlView:registerBtnEvent()
  if Z.IsPCUI then
    Z.InputMgr:AddInputEventDelegate(self.onDownEvent, Z.InputActionEventType.ButtonJustPressed, Z.RewiredActionsConst.ComAttack)
    Z.InputMgr:AddInputEventDelegate(self.onUpEvent, Z.InputActionEventType.ButtonJustReleased, Z.RewiredActionsConst.ComAttack)
  end
end

function Fishing_btn_ctrlView:unRegisterBtnEvent()
  if Z.IsPCUI then
    Z.InputMgr:RemoveInputEventDelegate(self.onDownEvent, Z.InputActionEventType.ButtonJustPressed, Z.RewiredActionsConst.ComAttack)
    Z.InputMgr:RemoveInputEventDelegate(self.onUpEvent, Z.InputActionEventType.ButtonJustReleased, Z.RewiredActionsConst.ComAttack)
  end
end

function Fishing_btn_ctrlView:OnDeActive()
  self:unRegisterBtnEvent()
  self.uiBinder.img_bg:ClearSteerList()
  Z.EventMgr:Remove(Z.ConstValue.Fishing.FishingStateChange, self.onFishingStageChanged, self)
end

function Fishing_btn_ctrlView:OnRefresh()
end

function Fishing_btn_ctrlView:onFishingBtnClick()
  if self.fishingData.FishingStage == E.FishingStage.EnterFishing then
    self.fishingVM.ThrowFishingRod()
    Z.EventMgr:Dispatch(Z.ConstValue.SteerEventName.OnGuideEvnet, string.zconcat(E.SteerGuideEventType.Fishing, "=", 3))
  elseif self.fishingData.FishingStage == E.FishingStage.FishBiteHook or self.fishingData.FishingStage == E.FishingStage.ThrowFishingRodInWater or self.fishingData.FishingStage == E.FishingStage.BuoyDive then
    self.fishingVM.HarvestingFishingRod()
  elseif self.fishingData.FishingStage == E.FishingStage.QTE then
    self.fishingVM.DragFishingRod()
  end
end

function Fishing_btn_ctrlView:onFishingStageChanged()
  if self.uiBinder == nil then
    return
  end
  if self.fishingData.FishingStage == E.FishingStage.EnterFishing then
    self.uiBinder.Ref:SetVisible(self.uiBinder.ctrl, true)
    self.uiBinder.btn_icon:SetImage(self.fishingIconPath[E.FishingBtnIconType.CastFishingRod])
  elseif self.fishingData.FishingStage == E.FishingStage.FishBiteHook then
    self.uiBinder.Ref:SetVisible(self.uiBinder.ctrl, true)
    self.uiBinder.btn_icon:SetImage(self.fishingIconPath[E.FishingBtnIconType.HarvestingRod])
    Z.AudioMgr:Play("UI_Event_Magic_A")
  elseif self.fishingData.FishingStage == E.FishingStage.QTE then
    self.uiBinder.Ref:SetVisible(self.uiBinder.ctrl, true)
    self.uiBinder.btn_icon:SetImage(self.fishingIconPath[E.FishingBtnIconType.HookingUp])
  elseif self.fishingData.FishingStage == E.FishingStage.ThrowFishingRod then
    self.uiBinder.Ref:SetVisible(self.uiBinder.ctrl, false)
    self.uiBinder.btn_icon:SetImage(self.fishingIconPath[E.FishingBtnIconType.HarvestingRod])
  elseif self.fishingData.FishingStage == E.FishingStage.ThrowFishingRodInWater then
    self.uiBinder.Ref:SetVisible(self.uiBinder.ctrl, true)
  elseif self.fishingData.FishingStage == E.FishingStage.BuoyDive then
    self.uiBinder.Ref:SetVisible(self.uiBinder.ctrl, true)
  else
    self.uiBinder.Ref:SetVisible(self.uiBinder.ctrl, false)
  end
  if self.fishingData.FishingStage == E.FishingStage.QTE then
    self:clearQteTimer()
    self.qteTimer_ = self.timerMgr:StartFrameTimer(function()
      self:refreshNeedDragEffect()
    end, self.fishingData.QTEData.UpdateRate, -1)
  else
    self:clearQteTimer()
  end
  self:ShowDragPrompt(self.fishingData.FishingStage == E.FishingStage.FishBiteHook)
end

function Fishing_btn_ctrlView:clearQteTimer()
  if self.qteTimer_ then
    self.timerMgr:StopFrameTimer(self.qteTimer_)
    self.qteTimer_ = nil
  end
end

function Fishing_btn_ctrlView:ShowDragPrompt(show)
  self.uiBinder.Ref:SetVisible(self.uiBinder.img_dragtip, show)
end

function Fishing_btn_ctrlView:refreshNeedDragEffect()
  self:ShowDragPrompt(self.fishingData.FishingStage == E.FishingStage.QTE and self.fishingData.QTEData.ShowDragEffect)
end

return Fishing_btn_ctrlView
