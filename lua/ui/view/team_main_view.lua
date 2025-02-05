local UI = Z.UI
local super = require("ui.ui_view_base")
local Team_mainView = class("Team_mainView", super)

function Team_mainView:ctor()
  self.uiBinder = nil
  super.ctor(self, "team_main")
  self.teamHallView_ = require("ui/view/team_hall_view").new()
  self.teamNearView_ = require("ui/view/team_hall_view").new()
  self.teamMineView_ = require("ui/view/team_mine_view").new()
  self.curTogIndex_ = E.TeamFuncId.Hall
  self.nowSelectTogIndex_ = -1
  self.viewList_ = {
    [E.TeamFuncId.Hall] = self.teamHallView_,
    [E.TeamFuncId.Vicinity] = self.teamNearView_,
    [E.TeamFuncId.Mine] = self.teamMineView_
  }
  self.teamMainVM_ = Z.VMMgr.GetVM("team_main")
  self.teamVM_ = Z.VMMgr.GetVM("team")
  self.isInTeam = false
  self.commonVM_ = Z.VMMgr.GetVM("common")
  self.matchVm_ = Z.VMMgr.GetVM("match")
  
  function self.onInputAction_(inputActionEventData)
    self:OnInputBack()
  end
end

function Team_mainView:initBinder()
  self.anim_ = self.uiBinder.anim
  self.cont_btn_return_ = self.uiBinder.cont_btn_return
  self.node_view_ = self.uiBinder.node_view
  self.lab_title_ = self.uiBinder.lab_title
  self.node_empty_ = self.uiBinder.node_empty
  self.cont_tog_team_ = self.uiBinder.node_team
  self.layout_tog_grop_ = self.uiBinder.layout_tog_grop
  self.cont_tog_hall_ = self.uiBinder.cont_tog_hall
  self.cont_tog_nearby_ = self.uiBinder.cont_tog_nearby
  self.cont_tog_team_ = self.uiBinder.cont_tog_team
end

function Team_mainView:OnActive()
  Z.UIMgr:SetUIViewInputIgnore(self.viewConfigKey, 4294967295, true)
  Z.UnrealSceneMgr:InitSceneCamera()
  Z.CoroUtil.create_coro_xpcall(function()
    self.teamVM_.AsyncGetTeamInfo(self.cancelSource:CreateToken())
  end)()
  self:initBinder()
  self:startAnimatedShow()
  Z.RedPointMgr.LoadRedDotItem(E.RedType.TeamApplySystem, self, self.cont_tog_team_.transform)
  local matching = self.matchVm_.GetSelfMatchData("matching")
  if not matching then
    if self.viewData then
      self.matchVm_.SetSelfMatchData(self.viewData, "targetId")
    else
      self.matchVm_.SetSelfMatchData(E.TeamTargetId.All, "targetId")
    end
  end
  self.compList_ = {
    [E.TeamFuncId.Hall] = self.cont_tog_hall_,
    [E.TeamFuncId.Vicinity] = self.cont_tog_nearby_,
    [E.TeamFuncId.Mine] = self.cont_tog_team_
  }
  self:AddClick(self.cont_btn_return_, function()
    self.teamMainVM_.CloseTeamMainView()
  end)
  self:setTog()
  self:BindEvents()
  self:RegisterInputActions()
end

function Team_mainView:setTog()
  for funcId, v in pairs(self.compList_) do
    v.tog_tab_select.group = self.layout_tog_grop_
    v.tog_tab_select:AddListener(function(isOn)
      self:refreshTogState(funcId, isOn)
    end)
  end
  self:setCurTog(true)
end

function Team_mainView:refreshTogState(funcId, isOn)
  local view = self.viewList_[funcId]
  if isOn then
    if self.nowSelectTogIndex_ == funcId then
      return
    end
    self.nowSelectTogIndex_ = funcId
    self.curTogIndex_ = funcId
    self:RefreshEmptyState(false)
    view:Active({parent = self, type = funcId}, self.node_view_.transform)
    self.commonVM_.SetLabText(self.lab_title_, {
      E.TeamFuncId.Team,
      funcId
    })
  else
    view:DeActive()
  end
end

function Team_mainView:OnDeActive()
  Z.UIMgr:SetUIViewInputIgnore(self.viewConfigKey, 4294967295, false)
  self:UnRegisterInputActions()
  for _, v in pairs(self.viewList_) do
    v:DeActive()
  end
  self.nowSelectTogIndex_ = -1
  Z.RedPointMgr.RemoveNodeItem(E.RedType.TeamApplySystem)
end

function Team_mainView:OnDestory()
  Z.UnrealSceneMgr:CloseUnrealScene("team_main")
end

function Team_mainView:setCurTog(isInit)
  local havTeam = self.teamVM_.CheckIsInTeam()
  if not isInit and self.isInTeam == havTeam then
    return
  end
  self.isInTeam = havTeam
  if havTeam then
    self.curTogIndex_ = E.TeamFuncId.Mine
  else
    self.teamMineView_:DeActive()
    if self.curTogIndex_ == E.TeamFuncId.Mine then
      self.curTogIndex_ = E.TeamFuncId.Hall
    end
  end
  self.compList_[E.TeamFuncId.Mine].Ref.UIComp:SetVisible(havTeam)
  for funcId, v in pairs(self.compList_) do
    if self.curTogIndex_ == funcId then
      self:refreshTogState(funcId, true)
      v.tog_tab_select.isOn = true
    end
  end
end

function Team_mainView:selfTeamChange()
  self:setCurTog()
end

function Team_mainView:matchWaitTimeOut()
  local targetId = self.matchVm_.GetSelfMatchData("targetId")
  local settingInfo = Z.ContainerMgr.CharSerialize.settingData.settingMap
  local isLeader = settingInfo[Z.PbEnum("ESettingType", "ToBeLeader")] or "0"
  Z.DialogViewDataMgr:OpenNormalDialog(Lang("StartMatchingAgain"), function()
    if self.teamVM_.CheckIsInTeam() then
      self.matchVm_.AsyncBeginMatchNew(E.MatchType.Team, {}, self.teamVM_.CheckIsInTeam(), self.cancelSource:CreateToken())
    else
      local requestParam = {}
      requestParam.targetId = targetId
      requestParam.checkTags = {}
      if isLeader then
        requestParam.wantLeader = 1
      else
        requestParam.wantLeader = 0
      end
      self.matchVm_.AsyncBeginMatchNew(E.MatchType.Team, requestParam, false, self.cancelSource:CreateToken())
    end
    Z.DialogViewDataMgr:CloseDialogView()
  end)
end

function Team_mainView:quitTeam()
  Z.CoroUtil.create_coro_xpcall(function()
    self.teamVM_.LeaveTeamDialog(self.cancelSource)
  end)()
end

function Team_mainView:RefreshEmptyState(isEmpty)
  self.uiBinder.Ref:SetVisible(self.node_empty_, isEmpty)
end

function Team_mainView:BindEvents()
  Z.EventMgr:Add(Z.ConstValue.Team.Refresh, self.selfTeamChange, self)
  Z.EventMgr:Add(Z.ConstValue.Team.MatchWaitTimeOut, self.matchWaitTimeOut, self)
  Z.EventMgr:Add(Z.ConstValue.Team.QuitTeam, self.quitTeam, self)
  Z.EventMgr:Add(Z.ConstValue.Chat.OpenPrivateChat, self.closeTeamView, self)
  Z.EventMgr:Add(Z.ConstValue.Idcard.InviteAction, self.closeTeamView, self)
end

function Team_mainView:closeTeamView()
  self.teamMainVM_.CloseTeamMainView()
end

function Team_mainView:startAnimatedShow()
  self.anim_:Restart(Z.DOTweenAnimType.Open)
end

function Team_mainView:startAnimatedHide()
  self.anim_:Play(Z.DOTweenAnimType.Close)
end

function Team_mainView:RegisterInputActions()
  Z.InputMgr:AddInputEventDelegate(self.onInputAction_, Z.InputActionEventType.ButtonJustPressed, Z.RewiredActionsConst.Team)
end

function Team_mainView:UnRegisterInputActions()
  Z.InputMgr:RemoveInputEventDelegate(self.onInputAction_, Z.InputActionEventType.ButtonJustPressed, Z.RewiredActionsConst.Team)
end

return Team_mainView
