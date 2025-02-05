local Parkour_count_down_tplView = class("Parkour_count_down_tplView")

function Parkour_count_down_tplView:ctor()
  self.timerMgr = Z.TimerMgr.new()
end

function Parkour_count_down_tplView:Init(go, name)
  self.name = name
  self.unit = UICompBindLua(go)
  self.unit.Ref:SetOffSetMin(0, 0)
  self.unit.Ref:SetOffSetMax(0, 0)
  self.unit.Ref:SetVisible(true)
  self.img_num = self.unit.img_num
  self.img_bg = self.unit.img_bg
  self.unit.Ref:SetVisible(false)
end

function Parkour_count_down_tplView:DeActive()
  self.timerMgr:Clear()
end

function Parkour_count_down_tplView:CountDownFunc(timeNumber, limitTime, timeFinishFunc, timeCallFunc, timeLimitFunc, isEndShow)
  local detailTime = timeNumber
  if detailTime <= 0 then
    return
  end
  self:SetNumberImg(detailTime - 1)
  local isFirst = true
  local isShow = false
  self.timerMgr:Clear()
  self.timerMgr:StartTimer(function()
    if not isShow then
      isShow = true
      self.unit.Ref:SetVisible(true)
    end
    detailTime = detailTime - 1
    if limitTime ~= nil and detailTime <= limitTime and isFirst then
      isFirst = false
      if timeLimitFunc then
        timeLimitFunc()
      end
    end
    if timeCallFunc then
      timeCallFunc()
    end
    self:SetNumberImg(detailTime)
    self.unit.node_time.Audio:PlayByTrigger(Panda.ZUi.UIAudioTrigger.commonAudio_1)
    self.unit.anim_parkour.anim:PlayOnce("ui_anim_parkour_count_down_tpl_countdown_2")
  end, 0.5, detailTime, true, function()
    if isEndShow == nil or isEndShow == false then
      self.unit.Ref:SetVisible(false)
    end
    if timeFinishFunc then
      timeFinishFunc()
    end
  end)
end

function Parkour_count_down_tplView:SetNumberImg(path)
  self.img_num.Img:SetImage(self.unit.Ref.PrefabCacheData:GetString(path))
end

function Parkour_count_down_tplView:SetBgImg(path, color)
  if not path or string.len(path) < 1 then
    return
  end
  self.img_bg.Img:SetImage(path)
  if color then
    self.img_bg.Img:SetColor(color)
  end
end

function Parkour_count_down_tplView:SetPosition(position)
  if not position or not next(position) then
    return
  end
  self.img_bg.Ref:SetPosition(position.x, position.y)
end

function Parkour_count_down_tplView:SetLabelColor(color)
  if not color then
    return
  end
  self.lab_num.TMPLab.color = color
end

return Parkour_count_down_tplView
