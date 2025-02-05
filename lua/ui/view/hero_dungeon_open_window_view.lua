local UI = Z.UI
local super = require("ui.ui_view_base")
local HeroDungeonOpen = class("HeroDungeonOpen", super)
local loopListView = require("ui.component.loop_list_view")
local affixLoopItem = require("ui.component.dungeon.dungeon_open_affix_loop_item")

function HeroDungeonOpen:ctor()
  self.uiBinder = nil
  super.ctor(self, "hero_dungeon_open_window")
  self.vm_ = Z.VMMgr.GetVM("hero_dungeon_main")
  self.data_ = Z.DataMgr.Get("hero_dungeon_main_data")
  self.dungeonVm_ = Z.VMMgr.GetVM("dungeon")
  self.itemVm_ = Z.VMMgr.GetVM("items")
  self.teamData_ = Z.DataMgr.Get("team_data")
end

function HeroDungeonOpen:OnActive()
  Z.UIMgr:SetUIViewInputIgnore(self.viewConfigKey, 4294967295, true)
  self.uiBinder.scenemask:SetSceneMaskByKey(self.SceneMaskKey)
  
  function self.onChangeFunc_()
    self:showBtn()
  end
  
  self.flowInfo_ = Z.ContainerMgr.DungeonSyncData.flowInfo
  if self.flowInfo_ then
    self.flowInfo_.Watcher:RegWatcher(self.onChangeFunc_)
  end
  self.dungeonId_ = Z.StageMgr.GetCurrentDungeonId()
  local dungeonsTableMgr = Z.TableMgr.GetTable("SceneEventDuneonConfigTableMgr")
  self.challengeCfg_ = dungeonsTableMgr.GetRow(self.dungeonId_)
  self.dungeonCfg_ = Z.TableMgr.GetTable("DungeonsTableMgr").GetRow(self.dungeonId_)
  self:initWidgets()
  self:initBtn()
  self:initItem()
  self:setState()
  self:showBtn()
end

function HeroDungeonOpen:initBtn()
  self.isUseKey_ = false
  local keyData = self.data_:GetDungeonKeyInfo()
  if keyData and keyData.useItem and keyData.useItem.uuid > 0 then
    self.isUseKey_ = true
  end
  self:SetUIVisible(self.countdown_, false)
  self:setShowStart(false)
  self:AddClick(self.btn_cancel_, function()
    self.vm_.CloseDungeonOpenView()
  end)
  self:AddAsyncClick(self.btn_ok_, function()
    local ret = self.vm_.AsyncStartPlayingDungeon(self.cancelSource, self.isUseKey_)
    if ret == 0 then
      local data = {}
      data.charId = Z.ContainerMgr.CharSerialize.charBase.charId
      data.isUseKey = self.isUseKey_
      self:setState(data)
      self.data_.DunegonEndTime = 0
    end
  end)
  if self.dungeonCfg_ then
    self.lab_title_.text = self.dungeonCfg_.Name
    self.open_lab_title_.text = self.dungeonCfg_.Name
    self.lab_deadreduce_.text = Lang("Second", {
      val = self.dungeonCfg_.DeathReleaseTime
    })
  end
  if self.challengeCfg_ then
    if self.challengeCfg_.LimitTime <= 0 then
      self.lab_time_.text = Lang("NoTimeLimit")
    else
      self.lab_time_.text = Z.TimeTools.S2MSFormat(self.challengeCfg_.LimitTime)
    end
  end
  local isChalle = self.vm_.IsHeroChallengeDungeonScene()
  local showTime = self.dungeonCfg_ and self.dungeonCfg_.DeathReleaseTime > 0
  self.uiBinder.Ref:SetVisible(self.uiBinder.node_entry_deadreduce, showTime and isChalle)
  self.uiBinder.Ref:SetVisible(self.uiBinder.node_entry_time, not isChalle or showTime ~= false)
end

function HeroDungeonOpen:getkeyConfigInfo()
  if self.dungeonCfg_ and self.challengeCfg_ then
    self.consumeItemId_ = self.dungeonCfg_.ItemConsume[1]
    self.consumeItemCount_ = self.dungeonCfg_.ItemConsume[2]
    self.keyTtemCfgData_ = Z.TableMgr.GetTable("ItemTableMgr").GetRow(self.consumeItemId_)
  end
end

function HeroDungeonOpen:initWidgets()
  self.lab_title_ = self.uiBinder.lab_title
  self.open_lab_title_ = self.uiBinder.lab_title
  self.lab_time_ = self.uiBinder.lab_double_digit1
  self.lab_deadreduce_ = self.uiBinder.lab_double_digit2
  self.btn_cancel_ = self.uiBinder.btn_cancel
  self.btn_ok_ = self.uiBinder.btn_ok
  self.node_content_ = self.uiBinder.node_content
  self.node_bg_ = self.uiBinder.node_bg
  self.countdown_ = self.uiBinder.lab_time
  self.affixScrollRect_ = loopListView.new(self, self.uiBinder.loop_item, affixLoopItem, "hero_dungeon_open_item_tpl")
  local dataList = {}
  self.affixScrollRect_:Init(dataList)
end

function HeroDungeonOpen:initItem()
  local keyAffixList = {}
  if self.isUseKey_ then
    local keyData = self.data_:GetDungeonKeyInfo()
    local affixList = keyData.useItem.affixData.affixIds
    for _, value in ipairs(affixList) do
      keyAffixList[value] = 1
    end
  end
  local dataList = {}
  local affixList = self.data_:GetAffixArray()
  for _, value in ipairs(affixList) do
    local d = {}
    d.isKey = keyAffixList[value] ~= nil
    d.affixId = value
    dataList[#dataList + 1] = d
  end
  self.affixScrollRect_:RefreshListView(dataList, true)
end

function HeroDungeonOpen:showBtn()
  self.state_ = self.vm_.GetDungeonState()
  self:SetUIVisible(self.btn_cancel_, self.state_ == E.DungeonState.DungeonStateActive)
  self:SetUIVisible(self.btn_ok_, self.state_ == E.DungeonState.DungeonStateActive)
  if self.state_ == E.DungeonState.DungeonStateReady then
    self:setTime()
    self.frameTimer = self.timerMgr:StartTimer(function()
      self:setShowStart(true)
    end, self.vm_.GetStartOpenTime() + 1)
  elseif self.state_ >= E.DungeonState.DungeonStatePlaying then
    self.vm_.CloseDungeonOpenView()
  end
end

function HeroDungeonOpen:setTime()
  self:SetUIVisible(self.countdown_, true)
  self.time = self.vm_.GetReadyStateTime(self.dungeonId_)
  self.countdown_.text = self.time
  self.countdownTimer = self.timerMgr:StartTimer(function()
    self.time = self.time - 1
    if self.time <= 0 then
      self.time = 0
      self:SetUIVisible(self.countdown_, false)
    end
    self.countdown_.text = self.time
  end, 1, self.time)
end

function HeroDungeonOpen:setShowStart(show)
  self:SetUIVisible(self.node_content_, not show)
  self:SetUIVisible(self.node_bg_, not show)
  self:SetUIVisible(self.uiBinder.lab_star, show)
end

function HeroDungeonOpen:OnDeActive()
  Z.UIMgr:SetUIViewInputIgnore(self.viewConfigKey, 4294967295, false)
  if self.flowInfo_ then
    self.flowInfo_.Watcher:UnregWatcher(self.onChangeFunc_)
  end
  self.flowInfo_ = nil
  self.affixItemList_ = nil
  if self.frameTimer then
    self.timerMgr:StopTimer(self.frameTimer)
  end
  self.frameTimer = nil
  if self.countdownTimer then
    self.timerMgr:StopTimer(self.countdownTimer)
  end
  self.countdownTimer = nil
  self.affixScrollRect_:UnInit()
  self.affixScrollRect_ = nil
end

function HeroDungeonOpen:setState()
  local str = ""
  if self.isUseKey_ then
    local keyData = self.data_:GetDungeonKeyInfo()
    local charId = keyData.charId
    local isSelfUseKey = charId == Z.ContainerMgr.CharSerialize.charBase.charId
    local limtCount = 0
    local normalAwardCount = 0
    local limitID = 0
    if isSelfUseKey then
      limitID = Z.Global.KeyRewardLimitId
      limtCount = Z.CounterHelper.GetCounterLimitCount(limitID)
      normalAwardCount = Z.CounterHelper.GetCounterResidueLimitCount(limitID, limtCount)
      str = Lang("RewardSelfUseKey") .. normalAwardCount .. "/" .. limtCount
    else
      limitID = Z.Global.RollRewardLimitId
      limtCount = Z.CounterHelper.GetCounterLimitCount(limitID)
      normalAwardCount = Z.CounterHelper.GetCounterResidueLimitCount(limitID, limtCount)
      str = Lang("RewardNotSelfUseKey") .. normalAwardCount .. "/" .. limtCount
    end
  end
end

function HeroDungeonOpen:OnRefresh()
end

function HeroDungeonOpen:startAnimatedHide()
end

return HeroDungeonOpen
