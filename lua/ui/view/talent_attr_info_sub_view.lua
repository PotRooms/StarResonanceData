local UI = Z.UI
local super = require("ui.ui_subview_base")
local Talent_attr_info_subView = class("Talent_attr_info_subView", super)
local TalentSkillDefine = require("ui.model.talent_skill_define")
local itemClass = require("common.item_binder")
local LEFT_ITEM_COUNT = 4

function Talent_attr_info_subView:ctor(parent)
  self.uiBinder = nil
  self.viewData = nil
  super.ctor(self, "talent_attr_info_sub", "talent_new/talent_attr_info_sub", UI.ECacheLv.None)
  self.weaponVm_ = Z.VMMgr.GetVM("weapon")
  self.fightAttrParseVm_ = Z.VMMgr.GetVM("fight_attr_parse")
  self.itemVm_ = Z.VMMgr.GetVM("items")
  self.talentSkillVm_ = Z.VMMgr.GetVM("talent_skill")
  self.talentSkillData_ = Z.DataMgr.Get("talent_skill_data")
  self.parentView_ = parent
end

function Talent_attr_info_subView:OnActive()
  self.uiBinder.Trans:SetOffsetMin(0, 0)
  self.uiBinder.Trans:SetOffsetMax(0, 0)
  self:AddAsyncClick(self.uiBinder.btn_close, function()
    self.viewData.closeFunc()
  end)
  self:AddAsyncClick(self.uiBinder.btn_level_up.btn, function()
    if self.viewData.type == TalentSkillDefine.TalentAttrInfoSubViewType.Weapon then
      self:upgradeWeapon()
    elseif self.viewData.type == TalentSkillDefine.TalentAttrInfoSubViewType.Talent or self.viewData.type == TalentSkillDefine.TalentAttrInfoSubViewType.TalentBD then
      self:unlockTalentBtn()
    end
  end)
  self:AddAsyncClick(self.uiBinder.btn_talentup.btn, function()
    self.parentView_:clearPreviewStage()
    self:unlockTalent()
  end)
  self:AddAsyncClick(self.uiBinder.btn_preview.btn, function()
    local talentTreeTableConfig = Z.TableMgr.GetTable("TalentTreeTableMgr").GetRow(self.viewData.id)
    if self.parentView_.talentTreeIsInPreview_[talentTreeTableConfig.TalentStage + 1] == -1 then
      self.parentView_:previewTalentTree(self.viewData.id)
    else
      self.parentView_:resetPreviewTalentTree(talentTreeTableConfig.TalentStage)
    end
    self:refreshNodeInfo()
  end)
  self:AddClick(self.uiBinder.btn_clear, function()
    self:clearRecordItem()
    self:refreshDefaultAttr()
    self:refreshItemCost()
    self.uiBinder.Ref:SetVisible(self.uiBinder.img_reddot, false)
  end)
  self:AddClick(self.uiBinder.btn_join, function()
    if self.weaponVm_.GetCurWeapon() ~= self.viewData.professionId then
      Z.TipsVM.ShowTipsLang(1042016)
      return
    end
    self:oneKeyAdd()
    self:refreshItemCost()
  end)
  self:AddAsyncClick(self.uiBinder.btn_talent_source, function()
    self:openSourceTip()
  end)
  self:AddAsyncClick(self.uiBinder.btn_talent_icon, function()
    self:openNotEnoughItemTips(self.talentSkillData_:GetTalentPointConfigId())
  end)
  self.uiBinder.group_video:AddListener(function()
    self.uiBinder.Ref:SetVisible(self.uiBinder.btn_play, false)
  end, function()
    self.uiBinder.Ref:SetVisible(self.uiBinder.btn_play, true)
  end)
  self:AddAsyncClick(self.uiBinder.btn_play, function()
    self.uiBinder.Ref:SetVisible(self.uiBinder.btn_play, false)
    self.uiBinder.group_video:PlayCurrent(true)
  end)
  self.itemClassTab_ = {}
  self.attrUnits_ = {}
  self.itemUnits_ = {}
  self.subTipsIdList_ = {}
  self:BindLuaAttrWatchers()
  if self.viewData.type == TalentSkillDefine.TalentAttrInfoSubViewType.Weapon then
    self.weapon_ = self.weaponVm_.GetWeaponInfo(self.viewData.id)
    self.cacheLv_ = self.weapon_.level
    self.maxLv_ = self.talentSkillData_:GetMaxWeaponLv()
    self.recordExp_ = 0
    self.recordLv_ = self.weapon_.level
    self.recordCoin_ = {}
    self.upGradeMat_ = {}
    self.levelItem_ = {}
    self.costItemIDs_ = {}
    local materials = Z.Global.WeaponLevelUpItem
    for _, info in ipairs(materials) do
      local item = {}
      item.itemID = info[1]
      item.effect = info[2]
      item.costItemID = info[3]
      item.costItemCnt = info[4]
      table.insert(self.levelItem_, item)
      table.insert(self.costItemIDs_, info[3])
      self.upGradeMat_[info[1]] = 0
    end
    self:refreshNodeUpgrade()
  else
    self:refreshNodeInfo(true)
  end
end

function Talent_attr_info_subView:OnDeActive()
  Z.CommonTipsVM.CloseRichText()
  for _, itemClass in pairs(self.itemClassTab_) do
    itemClass:UnInit()
  end
  for _, value in ipairs(self.attrUnits_) do
    self:RemoveUiUnit(value)
  end
  self:closeSourceTip()
  self:UnBindLuaAttrWatchers()
  local currencyVm = Z.VMMgr.GetVM("currency")
  currencyVm.CloseCurrencyView(self)
  for _, tipsId in pairs(self.subTipsIdList_) do
    Z.TipsVM.CloseItemTipsView(tipsId)
  end
  self.subTipsIdList_ = {}
end

function Talent_attr_info_subView:BindLuaAttrWatchers()
  function self.onContainerChanged(container, dirty)
    if dirty.professionList then
      if self.viewData.type == TalentSkillDefine.TalentAttrInfoSubViewType.Weapon then
        if self.cacheLv_ ~= self.weapon_.level then
          local viewData = {
            viewType = self.upGradeType,
            
            preLevel = self.cacheLv_,
            professionId = self.weapon_.professionId
          }
          self.weaponVm_.OpenUpgradeView(viewData)
        end
        Z.CoroUtil.create_coro_xpcall(function()
          self:clearRecordItem()
          self:refreshNodeUpgrade()
        end)()
      elseif self.viewData.type == TalentSkillDefine.TalentAttrInfoSubViewType.Skill then
        self:refreshNodeInfo()
      end
    elseif dirty.talentList and (self.viewData.type == TalentSkillDefine.TalentAttrInfoSubViewType.Talent or self.viewData.type == TalentSkillDefine.TalentAttrInfoSubViewType.TalentBD) then
      self:refreshNodeInfo()
    end
  end
  
  Z.ContainerMgr.CharSerialize.professionList.Watcher:RegWatcher(self.onContainerChanged)
  
  function self.onCostItemChanged(container, dirty)
    if dirty and self.viewData.type == TalentSkillDefine.TalentAttrInfoSubViewType.Weapon then
      local config = Z.TableMgr.GetTable("WeaponLevelTableMgr").GetRow(self.weapon_.level)
      if config == nil then
        return
      end
      if not config.Broke or self.weapon_.experience < config.Exp then
        self:refreshItemMat()
      end
    end
  end
  
  Z.ContainerMgr.CharSerialize.itemPackage.Watcher:RegWatcher(self.onCostItemChanged)
  Z.EventMgr:Add(Z.ConstValue.Backpack.AddItem, self.onItemChange, self)
  Z.EventMgr:Add(Z.ConstValue.Backpack.DelItem, self.onItemChange, self)
  Z.EventMgr:Add(Z.ConstValue.Backpack.ItemCountChange, self.onItemChange, self)
end

function Talent_attr_info_subView:UnBindLuaAttrWatchers()
  if self.onContainerChanged ~= nil then
    Z.ContainerMgr.CharSerialize.professionList.Watcher:UnregWatcher(self.onContainerChanged)
    self.onContainerChanged = nil
  end
  if self.onCostItemChanged ~= nil then
    Z.ContainerMgr.CharSerialize.itemPackage.Watcher:UnregWatcher(self.onCostItemChanged)
    self.onCostItemChanged = nil
  end
  Z.EventMgr:Remove(Z.ConstValue.Backpack.AddItem, self.onItemChange, self)
  Z.EventMgr:Remove(Z.ConstValue.Backpack.DelItem, self.onItemChange, self)
  Z.EventMgr:Remove(Z.ConstValue.Backpack.ItemCountChange, self.onItemChange, self)
end

function Talent_attr_info_subView:onItemChange(item)
  if item == nil or item.configId == nil then
    return
  end
  local itemsVM = Z.VMMgr.GetVM("items")
  if itemsVM.CheckPackageTypeByConfigId(item.configId, E.BackPackItemPackageType.Currency) or itemsVM.CheckPackageTypeByConfigId(item.configId, E.BackPackItemPackageType.Item) or itemsVM.CheckPackageTypeByConfigId(item.configId, E.BackPackItemPackageType.SpecialItem) then
    if self.viewData.type == TalentSkillDefine.TalentAttrInfoSubViewType.Weapon then
      self:clearRecordItem()
      self:refreshNodeUpgrade()
    else
      self:refreshNodeInfo(false)
    end
  end
end

function Talent_attr_info_subView:refreshNodeUpgrade()
  self.uiBinder.Ref:SetVisible(self.uiBinder.node_upgrade, true)
  self.uiBinder.Ref:SetVisible(self.uiBinder.node_info, false)
  self.uiBinder.btn_level_up.Ref.UIComp:SetVisible(true)
  self.uiBinder.Ref:SetVisible(self.uiBinder.lab_weapon_no_build, false)
  self.uiBinder.lab_weapon_no_build.text = Lang("TalentPreviewHaveNotTips")
  self.uiBinder.Ref:SetVisible(self.uiBinder.img_talentskill_icon, false)
  self.uiBinder.Ref:SetVisible(self.uiBinder.rimg_icon_weapon, true)
  self.uiBinder.Ref:SetVisible(self.uiBinder.img_reddot, false)
  self.uiBinder.Ref:SetVisible(self.uiBinder.img_frame, true)
  self.uiBinder.Ref:SetVisible(self.uiBinder.node_video, false)
  self.uiBinder.layout_info_1:SetAnchorPosition(0, 0)
  self.uiBinder.layout_info_2:SetAnchorPosition(0, 0)
  self.uiBinder.Ref:SetVisible(self.uiBinder.img_line, true)
  local currencyVm = Z.VMMgr.GetVM("currency")
  currencyVm.OpenCurrencyView(self.costItemIDs_, self.uiBinder.anim, self)
  local weaponSystemTable = Z.TableMgr.GetTable("ProfessionSystemTableMgr").GetRow(self.viewData.id)
  self.uiBinder.lab_title.text = weaponSystemTable.Name
  self.uiBinder.rimg_icon_weapon:SetImage(weaponSystemTable.MainTalentIcon)
  if self.weapon_.level < self.maxLv_ then
    self.uiBinder.Ref:SetVisible(self.uiBinder.weapon_info_line, true)
    self.uiBinder.Ref:SetVisible(self.uiBinder.group_upgrade, true)
    self.uiBinder.btn_level_up.Ref.UIComp:SetVisible(true)
    self.uiBinder.Ref:SetVisible(self.uiBinder.lab_weapon_no_build, false)
    local config = Z.TableMgr.GetTable("WeaponLevelTableMgr").GetRow(self.weapon_.level)
    if config == nil then
      return
    end
    if config.Broke and self.weapon_.experience >= config.Exp then
      self.uiBinder.Ref:SetVisible(self.uiBinder.group_btn_clear, false)
      self.uiBinder.Ref:SetVisible(self.uiBinder.lab_overstep, true)
      self.img_reddot_ = false
      self:refreshOverStep()
      self:refreshOverStepAttr()
    else
      self:refreshDefaultAttr()
      self.uiBinder.Ref:SetVisible(self.uiBinder.group_btn_clear, true)
      self.uiBinder.Ref:SetVisible(self.uiBinder.lab_overstep, false)
      self.img_reddot_ = true
      self:refreshLevelUpGrade()
      self:refreshItemCost()
    end
  else
    self:refreshDefaultAttr()
    self.uiBinder.Ref:SetVisible(self.uiBinder.group_upgrade, false)
    self.uiBinder.btn_level_up.Ref.UIComp:SetVisible(false)
    self.uiBinder.Ref:SetVisible(self.uiBinder.lab_weapon_no_build, self.weaponVm_.GetCurWeapon() == self.viewData.professionId)
    self.uiBinder.lab_weapon_no_build.text = Lang("ProfessionLevelMax")
    self.uiBinder.Ref:SetVisible(self.uiBinder.weapon_info_line, false)
  end
end

function Talent_attr_info_subView:refreshOverStep()
  self.uiBinder.Ref:SetVisible(self.uiBinder.group_btn_clear, false)
  local config = Z.TableMgr.GetTable("WeaponLevelTableMgr").GetRow(self.weapon_.level)
  if config == nil then
    return
  end
  local tempCondition = true
  for _, condition in ipairs(config.Conditions) do
    local bRes, tipsStr, progress = Z.ConditionHelper.GetSingleConditionDesc(condition[1], condition[2])
    if not bRes then
      tempCondition = false
      if condition[1] == E.ConditionType.Level then
        self.uiBinder.btn_level_up.lab_normal.text = Lang("PlayerLevelCanGoOnBroken", {
          val = condition[2]
        })
      elseif condition[1] == E.ConditionType.OpenServerDay then
        self.uiBinder.btn_level_up.lab_normal.text = Lang("ServerOpenCanGoOnBroken", {
          val = condition[2]
        })
      end
    end
  end
  if tempCondition then
    self.uiBinder.btn_level_up.lab_normal.text = Lang("Breach")
    self.img_reddot_ = true
  else
    self.img_reddot_ = false
  end
  local weaponSysTableRow = Z.TableMgr.GetTable("ProfessionSystemTableMgr").GetRow(self.weapon_.professionId)
  if weaponSysTableRow == nil then
    return
  end
  local costMat = {}
  for _, value in pairs(config.ItemPrice) do
    local temp = {}
    temp.itemID = value[1]
    temp.itemCount = value[2]
    table.insert(costMat, temp)
  end
  for _, value in pairs(config.ExtrCost) do
    local temp = {}
    temp.itemID = weaponSysTableRow.ProfessionBrokeExtraItem[1][value[1]]
    temp.itemCount = value[2]
    table.insert(costMat, temp)
  end
  self.itemNotCountEnoughId_ = nil
  local parent = self.uiBinder.layout_list_fixed
  for name, value in pairs(self.itemUnits_) do
    self:RemoveUiUnit(name)
  end
  self.itemUnits_ = {}
  for _, value in ipairs(costMat) do
    local uiUnitName = value.itemID
    if self.cancelTokens[uiUnitName] then
      Z.CancelSource.ReleaseToken(self.cancelTokens[uiUnitName])
      self.cancelTokens[uiUnitName] = nil
    end
  end
  self.uiBinder.Ref:SetVisible(self.uiBinder.group_gold_anim, false)
  for _, value in ipairs(costMat) do
    local totalCount = self.itemVm_.GetItemTotalCount(value.itemID)
    if totalCount < value.itemCount then
      self.itemNotCountEnoughId_ = value.itemID
    end
  end
  self.uiBinder.btn_level_up.btn.IsDisabled = self.itemNotCountEnoughId_ ~= nil
  self.img_reddot_ = self.itemNotCountEnoughId_ == nil and self.img_reddot_
  Z.CoroUtil.create_coro_xpcall(function()
    for _, value in ipairs(costMat) do
      local totalCount = self.itemVm_.GetItemTotalCount(value.itemID)
      local path = self.uiBinder.uiprefab_cashedata:GetString("item")
      local unit = self:AsyncLoadUiUnit(path, value.itemID, parent)
      self.itemUnits_[value.itemID] = unit
      self.itemClassTab_[value.itemID] = itemClass.new(self)
      self.itemClassTab_[value.itemID]:Init({
        uiBinder = unit,
        configId = value.itemID,
        labType = E.ItemLabType.Expend,
        lab = totalCount,
        expendCount = value.itemCount
      })
    end
    if #costMat >= LEFT_ITEM_COUNT then
      self.uiBinder.layout_list_fixed_Hlayoutgroup.childAlignment = UnityEngine.TextAnchor.UpperLeft
    else
      self.uiBinder.layout_list_fixed_Hlayoutgroup.childAlignment = UnityEngine.TextAnchor.UpperCenter
    end
  end)()
end

function Talent_attr_info_subView:refreshLevelUpGrade()
  self.uiBinder.Ref:SetVisible(self.uiBinder.group_btn_clear, true)
  local config = Z.TableMgr.GetTable("WeaponLevelTableMgr").GetRow(self.weapon_.level)
  if config == nil then
    return
  end
  local tempCondition = true
  if not config.Broke then
    for _, condition in ipairs(config.Conditions) do
      local bRes, tipsStr, progress = Z.ConditionHelper.GetSingleConditionDesc(condition[1], condition[2])
      if not bRes then
        tempCondition = false
        if condition[1] == E.ConditionType.Level then
          self.uiBinder.btn_level_up.lab_normal.text = Lang("PlayerLevelCanGoOnLevelUp", {
            val = condition[2]
          })
        elseif condition[1] == E.ConditionType.OpenServerDay then
          self.uiBinder.btn_level_up.lab_normal.text = Lang("ServerOpenCanGoOnLevelUp", {
            val = condition[2]
          })
        end
      end
    end
  end
  if tempCondition then
    self.uiBinder.btn_level_up.lab_normal.text = Lang("levelUp")
  end
  self:refreshItemMat()
  if #self.levelItem_ >= LEFT_ITEM_COUNT then
    self.uiBinder.layout_list_fixed_Hlayoutgroup.childAlignment = UnityEngine.TextAnchor.UpperLeft
  else
    self.uiBinder.layout_list_fixed_Hlayoutgroup.childAlignment = UnityEngine.TextAnchor.UpperCenter
  end
end

function Talent_attr_info_subView:refreshItemMat()
  local parent = self.uiBinder.layout_list_fixed
  for name, _ in pairs(self.itemUnits_) do
    self:RemoveUiUnit(name)
  end
  for _, value in ipairs(self.levelItem_) do
    local uiUnitName = value.itemID
    if self.cancelTokens[uiUnitName] then
      Z.CancelSource.ReleaseToken(self.cancelTokens[uiUnitName])
      self.cancelTokens[uiUnitName] = nil
    end
  end
  self.itemUnits_ = {}
  Z.CoroUtil.create_coro_xpcall(function()
    for _, value in ipairs(self.levelItem_) do
      local totalCount = self.itemVm_.GetItemTotalCount(value.itemID)
      local path = self.uiBinder.uiprefab_cashedata:GetString("item")
      local unit = self:AsyncLoadUiUnit(path, value.itemID, parent)
      self.itemUnits_[value.itemID] = unit
      self.itemClassTab_[value.itemID] = itemClass.new(self)
      local itemClassData = {
        uiBinder = unit,
        configId = value.itemID,
        isShowZero = true,
        lab = totalCount
      }
      if totalCount ~= 0 then
        function itemClassData.clickCallFunc()
          if self.weaponVm_.GetCurWeapon() ~= self.viewData.professionId then
            Z.TipsVM.ShowTipsLang(1042016)
            
            return
          end
          self:calculateExpItem(value, true)
        end
      else
        function itemClassData.clickCallFunc()
          self:openNotEnoughItemTips(value.itemID)
        end
      end
      self.itemClassTab_[value.itemID]:Init(itemClassData)
      self:AddClick(unit.btn_minus, function()
        self:calculateExpItem(value, false)
      end)
    end
  end)()
end

function Talent_attr_info_subView:calculateExpItem(item, add)
  local heroLvConfig = Z.TableMgr.GetTable("WeaponLevelTableMgr").GetRow(self.recordLv_)
  if not heroLvConfig then
    return
  end
  if add and not self:checkProfessionCondition(self.recordLv_, false) then
    return
  end
  if add and self.recordExp_ >= self:getLevelUpMaxExp() and (heroLvConfig.Broke or self.recordLv_ >= self.maxLv_) then
    Z.TipsVM.ShowTipsLang(130020)
    return
  end
  if self.upGradeMat_[item.itemID] == 0 and add == false then
    return
  end
  local totalCount = self.itemVm_.GetItemTotalCount(item.itemID)
  if totalCount <= self.upGradeMat_[item.itemID] and add then
    return
  end
  if add then
    self.recordExp_ = self.recordExp_ + item.effect
    self.upGradeMat_[item.itemID] = self.upGradeMat_[item.itemID] + 1
  else
    self.recordExp_ = self.recordExp_ - item.effect
    self.upGradeMat_[item.itemID] = self.upGradeMat_[item.itemID] - 1
  end
  local allExp = self.weapon_.experience + self.recordExp_
  local recordLv = self.weapon_.level
  for lv = self.weapon_.level, self.maxLv_ do
    local recordconfig = Z.TableMgr.GetTable("WeaponLevelTableMgr").GetRow(lv)
    if allExp < recordconfig.Exp or recordconfig.Broke then
      recordLv = lv
      break
    end
    if lv == self.maxLv_ then
      recordLv = lv
      break
    end
    allExp = allExp - recordconfig.Exp
  end
  self.recordLv_ = recordLv
  self:refreshRecordAttr(recordLv, allExp)
  self:refreshItemCost()
end

function Talent_attr_info_subView:oneKeyAdd()
  if not self:checkProfessionCondition(self.weapon_.level, false) then
    return
  end
  self:clearRecordItem()
  local allExp = self:getLevelUpMaxExp()
  local empty = true
  local levelItem = table.zdeepCopy(self.levelItem_)
  table.sort(levelItem, function(a, b)
    return a.effect > b.effect
  end)
  local totalCoinCount = self.itemVm_.GetItemTotalCount(self.levelItem_[1].costItemID)
  for _, item in ipairs(levelItem) do
    local needCount = math.ceil(allExp / item.effect)
    local totalItemCount = self.itemVm_.GetItemTotalCount(item.itemID)
    if 0 < totalItemCount then
      empty = false
    end
    local maxAddCount = math.floor(totalCoinCount / item.costItemCnt)
    if totalItemCount < maxAddCount then
      maxAddCount = totalItemCount
    end
    totalCoinCount = totalCoinCount - maxAddCount * item.costItemCnt
    if needCount <= maxAddCount then
      allExp = allExp - needCount * item.effect
      self.upGradeMat_[item.itemID] = needCount
      break
    end
    allExp = allExp - maxAddCount * item.effect
    self.upGradeMat_[item.itemID] = maxAddCount
  end
  if empty then
    local itemConfig = Z.TableMgr.GetTable("ItemTableMgr").GetRow(levelItem[1].itemID)
    if itemConfig then
      Z.TipsVM.ShowTipsLang(1042022, {
        val = itemConfig.Name
      })
      self:openNotEnoughItemTips(levelItem[1].itemID)
    end
    return
  end
  local emptyCoin = true
  for _, value in pairs(self.upGradeMat_) do
    if value ~= 0 then
      emptyCoin = false
    end
  end
  if emptyCoin then
    local coinId = self.levelItem_[1].costItemID
    local coinConfig = Z.TableMgr.GetTable("ItemTableMgr").GetRow(coinId)
    if coinConfig then
      Z.TipsVM.ShowTipsLang(1042022, {
        val = coinConfig.Name
      })
      self:openNotEnoughItemTips(coinId)
    end
    return
  end
  self.recordExp_ = 0
  for _, item in ipairs(levelItem) do
    local count = self.upGradeMat_[item.itemID]
    if count and 0 < count then
      local exp = count * item.effect
      self.recordExp_ = self.recordExp_ + exp
    end
  end
  local exp = self.recordExp_ + self.weapon_.experience
  for lv = self.weapon_.level, self.maxLv_ do
    local config = Z.TableMgr.GetTable("WeaponLevelTableMgr").GetRow(lv)
    if exp < config.Exp or config.Broke then
      self.recordLv_ = lv
      break
    end
    if lv == self.maxLv_ then
      self.recordLv_ = lv
      break
    end
    exp = exp - config.Exp
  end
  self:refreshRecordAttr(self.recordLv_, exp)
end

function Talent_attr_info_subView:refreshItemCost()
  for name, unit in pairs(self.itemUnits_) do
    local itemID = tonumber(name)
    local totalCount = self.itemVm_.GetItemTotalCount(itemID)
    if self.upGradeMat_[itemID] > 0 then
      unit.Ref:SetVisible(unit.btn_minus, true)
      self.itemClassTab_[name]:SetSelected(true, false)
      self.itemClassTab_[name]:SetExpendCount(totalCount, self.upGradeMat_[itemID])
    else
      unit.Ref:SetVisible(unit.btn_minus, false)
      self.itemClassTab_[name]:SetSelected(false, false)
      self.itemClassTab_[name]:SetLab(totalCount)
    end
  end
  self.recordCoin_ = {}
  for _, value in ipairs(self.levelItem_) do
    if self.upGradeMat_[value.itemID] ~= 0 then
      if self.recordCoin_[value.costItemID] == nil then
        self.recordCoin_[value.costItemID] = 0
      end
      self.recordCoin_[value.costItemID] = self.upGradeMat_[value.itemID] * value.costItemCnt + self.recordCoin_[value.costItemID]
    end
  end
  local itemConfig = Z.TableMgr.GetTable("ItemTableMgr").GetRow(self.levelItem_[1].costItemID)
  if itemConfig == nil then
    return
  end
  self.uiBinder.rimg_gold:SetImage(self.itemVm_.GetItemIcon(self.levelItem_[1].costItemID))
  if self.recordCoin_[self.levelItem_[1].costItemID] == nil then
    self.recordCoin_[self.levelItem_[1].costItemID] = 0
  end
  local count = self.recordCoin_[self.levelItem_[1].costItemID]
  local totalCount = self.itemVm_.GetItemTotalCount(self.levelItem_[1].costItemID)
  local btnDisable = true
  self.uiBinder.btn_level_up.btn.IsDisabled = true
  if count == 0 then
    for _, value in pairs(self.upGradeMat_) do
      if value ~= 0 then
        self.uiBinder.btn_level_up.IsDisabled = false
        btnDisable = false
        break
      end
    end
  else
    btnDisable = count > totalCount
    self.uiBinder.btn_level_up.btn.IsDisabled = btnDisable
  end
  if btnDisable then
    self.img_reddot_ = false
  end
  self.uiBinder.Ref:SetVisible(self.uiBinder.img_reddot, self.img_reddot_)
  if count == 0 then
    self.uiBinder.Ref:SetVisible(self.uiBinder.group_gold_anim, false)
  else
    self.uiBinder.Ref:SetVisible(self.uiBinder.group_gold_anim, true)
    if count <= totalCount then
      self.uiBinder.lab_digit.text = Z.RichTextHelper.ApplyStyleTag(count, E.TextStyleTag.White)
    else
      self.uiBinder.lab_digit.text = Z.RichTextHelper.ApplyStyleTag(count, E.TextStyleTag.ItemNotEnough)
    end
  end
end

function Talent_attr_info_subView:getLevelUpMaxExp()
  local mgr = Z.TableMgr.GetTable("WeaponLevelTableMgr")
  local allexp = 0 - self.weapon_.experience
  for lv = self.weapon_.level, self.maxLv_ - 1 do
    local config = mgr.GetRow(lv)
    if config.Broke then
      allexp = allexp + config.Exp
      if not Z.ConditionHelper.CheckCondition(config.Conditions) then
        return allexp
      end
    else
      if not Z.ConditionHelper.CheckCondition(config.Conditions) then
        return allexp
      end
      allexp = allexp + config.Exp
    end
    if config.Broke then
      break
    end
  end
  return allexp
end

function Talent_attr_info_subView:getOverStepSmallMaxLevelUp()
  local mgr = Z.TableMgr.GetTable("WeaponLevelTableMgr")
  local level = 0
  for lv = self.weapon_.level + 1, self.maxLv_ - 1 do
    level = level + 1
    local config = mgr.GetRow(lv)
    if config.Broke then
      break
    end
  end
  return level
end

function Talent_attr_info_subView:clearRecordItem()
  self.recordExp_ = 0
  self.recordLv_ = self.weapon_.level
  self.recordCoin_ = {}
  for key, _ in pairs(self.upGradeMat_) do
    self.upGradeMat_[key] = 0
  end
  self.img_reddot_ = false
end

function Talent_attr_info_subView:refreshDefaultAttr()
  self.uiBinder.lab_name.text = Lang("WeaponProficiency") .. self.weapon_.level .. "/" .. self.maxLv_
  if self.weapon_.level == self.maxLv_ then
    local config = Z.TableMgr.GetTable("WeaponLevelTableMgr").GetRow(self.maxLv_ - 1)
    if config == nil then
      return
    end
    self.uiBinder.slider.fillAmount = 1
    self.uiBinder.lab_value.text = config.Exp .. "/" .. config.Exp
  else
    local config = Z.TableMgr.GetTable("WeaponLevelTableMgr").GetRow(self.weapon_.level)
    if config == nil then
      return
    end
    self.uiBinder.slider.fillAmount = self.weapon_.experience / config.Exp
    self.uiBinder.lab_value.text = self.weapon_.experience .. "/" .. config.Exp
  end
  self.uiBinder.slider_sens.fillAmount = 0
  local attr = self.weaponVm_.GetAttrPreview(self.weapon_.professionId, self.weapon_.level, true)
  local path = self.uiBinder.uiprefab_cashedata:GetString("attr_tpl")
  local root = self.uiBinder.layout_info
  for _, value in ipairs(self.attrUnits_) do
    self:RemoveUiUnit(value)
  end
  self.attrUnits_ = {}
  Z.CoroUtil.create_coro_xpcall(function()
    for _, value in ipairs(attr) do
      local name = value.attrId
      table.insert(self.attrUnits_, name)
      local unit = self:AsyncLoadUiUnit(path, name, root)
      local str = self.fightAttrParseVm_.ParseFightAttrNumber(value.attrId, value.number, true)
      self:refreshAttrUnit(unit, value.attrId, str)
    end
  end)()
end

function Talent_attr_info_subView:refreshRecordAttr(recordLv, extraExp)
  local showLevelUpRedLevel = self.weaponVm_.GetWeaponUpLevelShowRed(self.weapon_.level)
  self.img_reddot_ = recordLv >= self.weapon_.level + showLevelUpRedLevel
  if recordLv == self.weapon_.level and extraExp == self.weapon_.experience then
    self:refreshDefaultAttr()
    self.uiBinder.Ref:SetVisible(self.uiBinder.img_reddot, self.img_reddot_)
    return
  end
  local recordconfig = Z.TableMgr.GetTable("WeaponLevelTableMgr").GetRow(recordLv)
  if not recordconfig then
    return
  end
  if extraExp < 0 then
    extraExp = 0
  end
  self.uiBinder.lab_name.text = Lang("WeaponProficiency") .. recordLv .. "/" .. self.maxLv_
  if recordLv == self.maxLv_ then
    local config = Z.TableMgr.GetTable("WeaponLevelTableMgr").GetRow(self.maxLv_ - 1)
    if config == nil then
      return
    end
    self.uiBinder.slider_sens.fillAmount = 0
    self.uiBinder.slider.fillAmount = 1
    self.uiBinder.lab_value.text = extraExp + config.Exp .. "/" .. config.Exp
  else
    local config = Z.TableMgr.GetTable("WeaponLevelTableMgr").GetRow(self.weapon_.level)
    if config == nil then
      return
    end
    self.uiBinder.slider_sens.fillAmount = extraExp / recordconfig.Exp
    self.uiBinder.lab_value.text = extraExp .. "/" .. recordconfig.Exp
    if recordLv == self.weapon_.level then
      self.uiBinder.slider.fillAmount = self.weapon_.experience / config.Exp
    else
      self.uiBinder.slider.fillAmount = 0
    end
  end
  local nowAttr = self.weaponVm_.GetAttrPreview(self.weapon_.professionId, self.weapon_.level, false)
  local nextAttr = self.weaponVm_.GetAttrPreview(self.weapon_.professionId, recordLv, true)
  local attr = {}
  for index, value in ipairs(nextAttr) do
    if nowAttr[value.attrId] == nil then
      nowAttr[value.attrId] = 0
    end
    attr[index] = {}
    attr[index].attrId = value.attrId
    attr[index].number = value.number - nowAttr[value.attrId]
  end
  local path = self.uiBinder.uiprefab_cashedata:GetString("attr_tpl")
  local root = self.uiBinder.layout_info
  for _, value in ipairs(self.attrUnits_) do
    self:RemoveUiUnit(value)
  end
  self.attrUnits_ = {}
  Z.CoroUtil.create_coro_xpcall(function()
    for _, value in ipairs(attr) do
      local name = value.attrId
      table.insert(self.attrUnits_, name)
      local unit = self:AsyncLoadUiUnit(path, name, root)
      local nowvalue = self.fightAttrParseVm_.ParseFightAttrNumber(value.attrId, nowAttr[value.attrId], true)
      local diffValue = self.fightAttrParseVm_.ParseFightAttrNumber(value.attrId, value.number, true)
      local str = nowvalue
      if value.number > 0 then
        str = nowvalue .. Z.Placeholder.SetTextSize(Z.RichTextHelper.ApplyStyleTag("+" .. diffValue, E.TextStyleTag.AttrUp))
      end
      self:refreshAttrUnit(unit, value.attrId, str)
    end
  end)()
end

function Talent_attr_info_subView:refreshOverStepAttr()
  if self.weapon_.level == self.maxLv_ then
    self:refreshDefaultAttr()
    return
  end
  local recordLv = self.weapon_.level + 1
  local recordconfig = Z.TableMgr.GetTable("WeaponLevelTableMgr").GetRow(recordLv)
  if not recordconfig then
    return
  end
  self.uiBinder.lab_name.text = Lang("WeaponProficiency") .. self.weapon_.level .. "/" .. self.maxLv_
  self.uiBinder.Ref:SetVisible(self.uiBinder.img_reddot, recordLv ~= self.weapon_.level and self.img_reddot_)
  if recordLv == self.maxLv_ then
    local config = Z.TableMgr.GetTable("WeaponLevelTableMgr").GetRow(self.maxLv_ - 1)
    if config == nil then
      return
    end
    self.uiBinder.slider_sens.fillAmount = 0
    self.uiBinder.slider.fillAmount = 1
    self.uiBinder.lab_value.text = config.Exp .. "/" .. config.Exp
  else
    local config = Z.TableMgr.GetTable("WeaponLevelTableMgr").GetRow(self.weapon_.level)
    if config == nil then
      return
    end
    self.uiBinder.slider_sens.fillAmount = 0 / recordconfig.Exp
    self.uiBinder.lab_value.text = "0/" .. recordconfig.Exp
    if recordLv == self.weapon_.level then
      self.uiBinder.slider.fillAmount = self.weapon_.experience / config.Exp
    else
      self.uiBinder.slider.fillAmount = 0
    end
  end
  local nowAttr = self.weaponVm_.GetAttrPreview(self.weapon_.professionId, self.weapon_.level, false)
  local nextAttr = self.weaponVm_.GetAttrPreview(self.weapon_.professionId, recordLv, true)
  local attr = {}
  for index, value in ipairs(nextAttr) do
    if nowAttr[value.attrId] == nil then
      nowAttr[value.attrId] = 0
    end
    attr[index] = {}
    attr[index].attrId = value.attrId
    attr[index].number = value.number - nowAttr[value.attrId]
  end
  local canUpLevel = self:getOverStepSmallMaxLevelUp()
  if 0 < canUpLevel then
    attr[#attr + 1] = {attrId = -1, number = canUpLevel}
  end
  local path = self.uiBinder.uiprefab_cashedata:GetString("attr_tpl")
  local root = self.uiBinder.layout_info
  for _, value in ipairs(self.attrUnits_) do
    self:RemoveUiUnit(value)
  end
  self.attrUnits_ = {}
  Z.CoroUtil.create_coro_xpcall(function()
    for _, value in ipairs(attr) do
      local name = value.attrId
      table.insert(self.attrUnits_, name)
      local unit = self:AsyncLoadUiUnit(path, name, root)
      local str
      if value.attrId == -1 then
        str = self.weapon_.level .. Z.Placeholder.SetTextSize(Z.RichTextHelper.ApplyStyleTag("+" .. value.number, E.TextStyleTag.AttrUp))
      else
        local nowvalue = self.fightAttrParseVm_.ParseFightAttrNumber(value.attrId, nowAttr[value.attrId], true)
        local diffValue = self.fightAttrParseVm_.ParseFightAttrNumber(value.attrId, value.number, true)
        str = nowvalue
        if value.number > 0 then
          str = nowvalue .. Z.Placeholder.SetTextSize(Z.RichTextHelper.ApplyStyleTag("+" .. diffValue, E.TextStyleTag.AttrUp))
        end
      end
      self:refreshAttrUnit(unit, value.attrId, str)
    end
  end)()
end

function Talent_attr_info_subView:refreshAttrUnit(uibinder, id, str)
  if uibinder == nil then
    return
  end
  if id == -1 then
    uibinder.lab_num.text = str
    uibinder.lab_name.text = Lang("WeaponCanOnkeyLevelUpMax")
    uibinder.img_icon:SetImage("ui/atlas/weaponhero/new/common_attrfightpoint")
  else
    local fightAttrData = self.fightAttrParseVm_.GetFightAttrTableRow(id)
    if fightAttrData == nil then
      return
    end
    uibinder.lab_num.text = str
    uibinder.lab_name.text = fightAttrData.OfficialName
    uibinder.img_icon:SetImage(fightAttrData.Icon)
  end
end

function Talent_attr_info_subView:upgradeWeapon()
  if self.weaponVm_.GetCurWeapon() ~= self.viewData.professionId then
    Z.TipsVM.ShowTipsLang(1042016)
    return
  end
  local config = Z.TableMgr.GetTable("WeaponLevelTableMgr").GetRow(self.weapon_.level)
  if config == nil then
    return
  end
  if config.Broke and self.weapon_.experience >= config.Exp then
    for _, condition in ipairs(config.Conditions) do
      local bRes, tipsStr, progress = Z.ConditionHelper.GetSingleConditionDesc(condition[1], condition[2])
      if not bRes then
        if condition[1] == E.ConditionType.Level then
          Z.TipsVM.ShowTipsLang(1042030, {
            val = condition[2]
          })
        elseif condition[1] == E.ConditionType.OpenServerDay then
          Z.TipsVM.ShowTipsLang(1042031, {
            val = condition[2]
          })
        end
        return
      end
    end
    if self.itemNotCountEnoughId_ == nil then
      self.upGradeType = E.UpgradeType.WeaponHeroOverstep
      self.cacheLv_ = self.weapon_.level
      self.weaponVm_.AsyncWeaponOverStep(self.weapon_.professionId, self.cancelSource:CreateToken())
    else
      local itemConfig = Z.TableMgr.GetTable("ItemTableMgr").GetRow(self.itemNotCountEnoughId_)
      if itemConfig then
        Z.TipsVM.ShowTipsLang(1042022, {
          val = itemConfig.Name
        })
        self:openNotEnoughItemTips(self.itemNotCountEnoughId_)
      end
      return
    end
  else
    if not config.Broke then
      for _, condition in ipairs(config.Conditions) do
        local bRes, tipsStr, progress = Z.ConditionHelper.GetSingleConditionDesc(condition[1], condition[2])
        if not bRes then
          if condition[1] == E.ConditionType.Level then
            Z.TipsVM.ShowTipsLang(1042028, {
              val = condition[2]
            })
          elseif condition[1] == E.ConditionType.OpenServerDay then
            Z.TipsVM.ShowTipsLang(1042029, {
              val = condition[2]
            })
          end
          return
        end
      end
    end
    local matEnough = false
    for _, value in pairs(self.upGradeMat_) do
      if 0 < value then
        matEnough = true
      end
    end
    if not matEnough then
      Z.TipsVM.ShowTipsLang(130018)
      return
    end
    local coinEnough = true
    for itemid, count in pairs(self.recordCoin_) do
      local totalCount = self.itemVm_.GetItemTotalCount(itemid)
      if count > totalCount then
        coinEnough = false
        break
      end
    end
    if coinEnough == false then
      local coinId = self.levelItem_[1].costItemID
      local coinConfig = Z.TableMgr.GetTable("ItemTableMgr").GetRow(coinId)
      if coinConfig then
        Z.TipsVM.ShowTipsLang(1042022, {
          val = coinConfig.Name
        })
        self:openNotEnoughItemTips(coinId)
      end
      return
    end
    self.upGradeType = E.UpgradeType.WeaponHeroLevel
    self.cacheLv_ = self.weapon_.level
    self.weaponVm_.AsyncWeaponLevelUp(self.weapon_.professionId, self.upGradeMat_, self.cancelSource:CreateToken())
  end
end

function Talent_attr_info_subView:checkProfessionCondition(level, isIngoreTips)
  local config = Z.TableMgr.GetTable("WeaponLevelTableMgr").GetRow(level)
  if config == nil then
    return false
  end
  if not config.Broke then
    for _, condition in ipairs(config.Conditions) do
      local bRes, tipsStr, progress = Z.ConditionHelper.GetSingleConditionDesc(condition[1], condition[2])
      if not bRes then
        if condition[1] == E.ConditionType.Level and not isIngoreTips then
          Z.TipsVM.ShowTipsLang(1042028, {
            val = condition[2]
          })
        end
        return false
      end
    end
  end
  return true
end

function Talent_attr_info_subView:refreshNodeInfo(isShow)
  self.uiBinder.Ref:SetVisible(self.uiBinder.node_upgrade, false)
  self.uiBinder.Ref:SetVisible(self.uiBinder.node_info, true)
  self.uiBinder.Ref:SetVisible(self.uiBinder.img_talentskill_icon, true)
  self.uiBinder.Ref:SetVisible(self.uiBinder.rimg_icon_weapon, false)
  self.uiBinder.Ref:SetVisible(self.uiBinder.lab_content_down, false)
  self.uiBinder.btn_level_up.btn.IsDisabled = false
  self.uiBinder.layout_info_1:SetAnchorPosition(0, 0)
  self.uiBinder.layout_info_2:SetAnchorPosition(0, 0)
  self.itemNotCountEnoughId_ = nil
  self.conditionAllFinish_ = true
  self.talentCanPreview_ = false
  self.uiBinder.Ref:SetVisible(self.uiBinder.img_reddot, false)
  self.uiBinder.Ref:SetVisible(self.uiBinder.img_reddot_1, false)
  if self.viewData.type == TalentSkillDefine.TalentAttrInfoSubViewType.Talent or self.viewData.type == TalentSkillDefine.TalentAttrInfoSubViewType.TalentBD then
    local showVideo = self.talentSkillData_:GetTalentShowVideo(self.viewData.id)
    if showVideo then
      self.uiBinder.Ref:SetVisible(self.uiBinder.img_frame, false)
      self.uiBinder.Ref:SetVisible(self.uiBinder.node_video, true)
      if isShow then
        self.uiBinder.group_video:Prepare(showVideo[1] .. ".mp4", false, true)
        self.uiBinder.group_video:PlayCurrent(true)
        self.uiBinder.Ref:SetVisible(self.uiBinder.btn_play, false)
      end
    else
      self.uiBinder.Ref:SetVisible(self.uiBinder.img_frame, true)
      self.uiBinder.Ref:SetVisible(self.uiBinder.node_video, false)
    end
    local talentTreeTableConfig = Z.TableMgr.GetTable("TalentTreeTableMgr").GetRow(self.viewData.id)
    local talentTable = Z.TableMgr.GetTable("TalentTableMgr").GetRow(talentTreeTableConfig.TalentId)
    self.uiBinder.lab_title.text = talentTable.TalentName
    self.uiBinder.img_talentskill_icon:SetImage(talentTable.TalentIcon)
    self.uiBinder.Ref:SetVisible(self.uiBinder.node_skill, false)
    self.uiBinder.Ref:SetVisible(self.uiBinder.node_talent, true)
    self.uiBinder.lab_equip_basics.text = Lang("EnvSkillEffect")
    Z.RichTextHelper.SetTmpLabTextWithCommonLinkNew(self.uiBinder.lab_equip_basics2, self.talentSkillVm_.ParseTalentEffectDesc(talentTable.Id))
    local isActive = self.talentSkillVm_.CheckTalentIsActive(self.viewData.professionId, self.viewData.id)
    local tempTalentStageTips = self.parentView_.talentTreeUnlockTipsLang_[talentTreeTableConfig.TalentStage]
    local isSpecialNode = self.talentSkillVm_.CheckTalentNodeIsSpecialNode(self.viewData.professionId, self.viewData.id)
    if isSpecialNode then
      self.uiBinder.Ref:SetVisible(self.uiBinder.lab_weapon_no_build, false)
      if self.talentSkillVm_.CheckOtherSchoolIsChoose(self.viewData.professionId, self.viewData.id) then
        self.uiBinder.Ref:SetVisible(self.uiBinder.node_unlock_condition_down, true)
        self.uiBinder.btn_preview.Ref.UIComp:SetVisible(false)
        self.uiBinder.btn_talentup.Ref.UIComp:SetVisible(false)
        self.uiBinder.btn_level_up.Ref.UIComp:SetVisible(true)
        self.talentCanPreview_ = true
        if self.parentView_.talentTreeIsInPreview_[talentTreeTableConfig.TalentStage + 1] == -1 then
          self.uiBinder.btn_level_up.lab_normal.text = Lang("PreviewTalentTree")
        else
          self.uiBinder.btn_level_up.lab_normal.text = Lang("ReturnTalentSchoolChoose")
        end
        if self.weaponVm_.GetCurWeapon() ~= self.viewData.professionId then
          self.uiBinder.Ref:SetVisible(self.uiBinder.lab_weapon_no_build, true)
          self.uiBinder.lab_weapon_no_build.text = Lang("TalentPreviewHaveNotTips")
        elseif tempTalentStageTips ~= nil then
          self.uiBinder.Ref:SetVisible(self.uiBinder.lab_weapon_no_build, true)
          self.uiBinder.lab_weapon_no_build.text = tempTalentStageTips
        else
          self.uiBinder.Ref:SetVisible(self.uiBinder.lab_weapon_no_build, true)
          self.uiBinder.lab_weapon_no_build.text = Lang("TalentIsChoosOtherSchoolResetPlease")
        end
      elseif isActive then
        self.uiBinder.Ref:SetVisible(self.uiBinder.node_unlock_condition_down, false)
        self.uiBinder.btn_level_up.Ref.UIComp:SetVisible(true)
        self.talentCanPreview_ = true
        if self.parentView_.isInPreview_ then
          self.uiBinder.btn_level_up.lab_normal.text = Lang("PreviewTalentTree")
        else
          self.uiBinder.btn_level_up.lab_normal.text = Lang("ReturnTalentSchoolChoose")
        end
        self.uiBinder.btn_preview.Ref.UIComp:SetVisible(false)
        self.uiBinder.btn_talentup.Ref.UIComp:SetVisible(false)
        if self.weaponVm_.GetCurWeapon() ~= self.viewData.professionId then
          self.uiBinder.Ref:SetVisible(self.uiBinder.lab_weapon_no_build, true)
          self.uiBinder.lab_weapon_no_build.text = Lang("TalentPreviewHaveNotTips")
        else
          self.uiBinder.Ref:SetVisible(self.uiBinder.lab_weapon_no_build, false)
        end
      else
        self.uiBinder.Ref:SetVisible(self.uiBinder.node_unlock_condition_down, true)
        if tempTalentStageTips == nil then
          self.uiBinder.btn_level_up.Ref.UIComp:SetVisible(false)
          self.uiBinder.btn_preview.Ref.UIComp:SetVisible(true)
          self.uiBinder.btn_talentup.Ref.UIComp:SetVisible(true)
          if self.parentView_.talentTreeIsInPreview_[talentTreeTableConfig.TalentStage + 1] == -1 then
            self.uiBinder.btn_preview.lab_normal.text = Lang("PreviewTalentTree")
          else
            self.uiBinder.btn_preview.lab_normal.text = Lang("ReturnTalentSchoolChoose")
          end
        else
          self.uiBinder.Ref:SetVisible(self.uiBinder.lab_weapon_no_build, true)
          self.uiBinder.lab_weapon_no_build.text = tempTalentStageTips
          self.uiBinder.btn_level_up.Ref.UIComp:SetVisible(true)
          self.talentCanPreview_ = true
          if self.parentView_.talentTreeIsInPreview_[talentTreeTableConfig.TalentStage + 1] == -1 then
            self.uiBinder.btn_level_up.lab_normal.text = Lang("PreviewTalentTree")
          else
            self.uiBinder.btn_level_up.lab_normal.text = Lang("ReturnTalentSchoolChoose")
          end
          self.uiBinder.btn_preview.Ref.UIComp:SetVisible(false)
          self.uiBinder.btn_talentup.Ref.UIComp:SetVisible(false)
        end
        if self.weaponVm_.GetCurWeapon() ~= self.viewData.professionId then
          self.uiBinder.Ref:SetVisible(self.uiBinder.lab_weapon_no_build, true)
          self.uiBinder.lab_weapon_no_build.text = Lang("TalentPreviewHaveNotTips")
        end
      end
    else
      self.uiBinder.btn_preview.Ref.UIComp:SetVisible(false)
      self.uiBinder.btn_talentup.Ref.UIComp:SetVisible(false)
      self.uiBinder.btn_level_up.lab_normal.text = Lang("TalentOperateDes")
      self.talentCanPreview_ = false
      if self.weaponVm_.GetCurWeapon() ~= self.viewData.professionId then
        self.uiBinder.Ref:SetVisible(self.uiBinder.lab_weapon_no_build, true)
        self.uiBinder.lab_weapon_no_build.text = Lang("TalentPreviewHaveNotTips")
        self.uiBinder.btn_level_up.Ref.UIComp:SetVisible(false)
        if isActive then
          self.uiBinder.Ref:SetVisible(self.uiBinder.node_unlock_condition_down, false)
        else
          self.uiBinder.Ref:SetVisible(self.uiBinder.node_unlock_condition_down, true)
        end
        self.uiBinder.btn_level_up.Ref.UIComp:SetVisible(false)
      elseif isActive then
        self.uiBinder.Ref:SetVisible(self.uiBinder.lab_weapon_no_build, true)
        self.uiBinder.lab_weapon_no_build.text = Lang("Unlocked")
        self.uiBinder.Ref:SetVisible(self.uiBinder.node_unlock_condition_down, false)
        self.uiBinder.btn_level_up.Ref.UIComp:SetVisible(false)
      else
        self.uiBinder.Ref:SetVisible(self.uiBinder.node_unlock_condition_down, true)
        if tempTalentStageTips == nil then
          local talentTreeTableConfig = Z.TableMgr.GetTable("TalentTreeTableMgr").GetRow(self.viewData.id)
          if talentTreeTableConfig and self.talentSkillVm_.GetProfessionTalentStageBdType(self.viewData.professionId, talentTreeTableConfig.TalentStage) == talentTreeTableConfig.BdType then
            self.uiBinder.Ref:SetVisible(self.uiBinder.lab_weapon_no_build, false)
            local curWeaponIsUnlock = self.weaponVm_.CheckWeaponUnlock(self.viewData.professionId) and self.weaponVm_.GetCurWeapon() == self.viewData.professionId
            self.uiBinder.btn_level_up.Ref.UIComp:SetVisible(curWeaponIsUnlock and tempTalentStageTips == nil)
          else
            self.uiBinder.Ref:SetVisible(self.uiBinder.lab_weapon_no_build, true)
            self.uiBinder.lab_weapon_no_build.text = Lang("TalentIsChoosOtherSchoolResetPlease")
            self.uiBinder.btn_level_up.Ref.UIComp:SetVisible(false)
          end
        else
          self.uiBinder.Ref:SetVisible(self.uiBinder.lab_weapon_no_build, true)
          self.uiBinder.lab_weapon_no_build.text = tempTalentStageTips
          self.uiBinder.btn_level_up.Ref.UIComp:SetVisible(false)
        end
      end
    end
    if isActive then
      self.uiBinder.node_skill:SetHeight(370)
      self.uiBinder.node_talent:SetHeight(370)
      self.uiBinder.Ref:SetVisible(self.uiBinder.img_line, false)
    else
      self:loadLockCondition()
      self:loalLockItems()
      self.uiBinder.node_skill:SetHeight(197)
      self.uiBinder.node_talent:SetHeight(197)
      self.uiBinder.Ref:SetVisible(self.uiBinder.img_line, true)
    end
    local reddot = false
    local nodes = self.talentSkillData_:GetCurUnActiveUnlockTalentTreeNodes()
    for _, node in ipairs(nodes) do
      if node == self.viewData.id then
        reddot = true
        break
      end
    end
    self.uiBinder.Ref:SetVisible(self.uiBinder.img_reddot, reddot)
    self.uiBinder.Ref:SetVisible(self.uiBinder.img_reddot_1, reddot)
    self.uiBinder.lab_talentpoint_num.text = self.talentSkillVm_.GetSurpluseTalentPointCount(self.viewData.professionId) .. "/" .. self.talentSkillVm_.GetAllTalentPointCount()
  end
end

function Talent_attr_info_subView:loadLockCondition()
  self:unloadLockCondition()
  local unlockCondition = {}
  if self.viewData.type == TalentSkillDefine.TalentAttrInfoSubViewType.Skill then
    local skillConfig = Z.TableMgr.GetTable("SkillTableMgr").GetRow(self.viewData.id)
    unlockCondition = skillConfig.UnlockCondition
  elseif self.viewData.type == TalentSkillDefine.TalentAttrInfoSubViewType.Talent or self.viewData.type == TalentSkillDefine.TalentAttrInfoSubViewType.TalentBD then
    local talentTreeTableConfig = Z.TableMgr.GetTable("TalentTreeTableMgr").GetRow(self.viewData.id)
    unlockCondition = talentTreeTableConfig.Unlock
  end
  if unlockCondition and 0 < #unlockCondition then
    self.uiBinder.Ref:SetVisible(self.uiBinder.lab_unlock_condition, true)
    local count = #unlockCondition
    local path = self.uiBinder.uiprefab_cashedata:GetString("tog")
    Z.CoroUtil.create_coro_xpcall(function()
      for i = 1, count do
        local name = "tog_" .. i
        local unit = self:AsyncLoadUiUnit(path, name, self.uiBinder.node_basics_item)
        if unit then
          self.conditionUnits_[i] = {
            name = name,
            unit = unit,
            condition = unlockCondition[i]
          }
        end
      end
      self:refreshLockCondition()
    end)()
  else
    self.uiBinder.Ref:SetVisible(self.uiBinder.lab_unlock_condition, false)
    self:refreshLockCondition()
  end
end

function Talent_attr_info_subView:unloadLockCondition()
  if self.conditionUnits_ then
    for _, value in ipairs(self.conditionUnits_) do
      self:RemoveUiUnit(value.name)
    end
  end
  self.conditionUnits_ = {}
end

function Talent_attr_info_subView:refreshLockCondition()
  self.conditionAllFinish_ = true
  for _, value in ipairs(self.conditionUnits_) do
    local params = {
      [1] = value.condition[2],
      [2] = self.viewData.professionId
    }
    local bResult, unlockDesc, progress = Z.ConditionHelper.GetSingleConditionDesc(value.condition[1], table.unpack(params))
    value.unit.lab_title.text = unlockDesc
    value.unit.tog_condition.isOn = bResult
    self.conditionAllFinish_ = self.conditionAllFinish_ and bResult
  end
  if self.talentCanPreview_ then
    self.uiBinder.btn_level_up.btn.IsDisabled = false
  else
    self.uiBinder.btn_level_up.btn.IsDisabled = self.itemNotCountEnoughId_ ~= nil and not self.conditionAllFinish_
  end
end

function Talent_attr_info_subView:loalLockItems()
  self:unloadLockItems()
  self.lockItems_ = {}
  self.itemNotCountEnoughId_ = nil
  if self.viewData.type == TalentSkillDefine.TalentAttrInfoSubViewType.Skill then
    local weaponSkillVM = Z.VMMgr.GetVM("weapon_skill")
    local upgradeId = weaponSkillVM.GetSkillUpgradeId(self.viewData.id)
    local skillLevelConfig = self.talentSkillData_:GetSkillLevelConfig(upgradeId, 1)
    if skillLevelConfig then
      local i = 1
      for _, cost in ipairs(skillLevelConfig.Cost) do
        if self.itemVm_.GetItemTotalCount(cost[1]) < cost[2] and self.itemNotCountEnoughId_ == nil then
          self.itemNotCountEnoughId_ = cost[1]
        end
        self.lockItems_[i] = {
          Id = cost[1],
          count = cost[2]
        }
        i = i + 1
      end
    end
  elseif self.viewData.type == TalentSkillDefine.TalentAttrInfoSubViewType.Talent or self.viewData.type == TalentSkillDefine.TalentAttrInfoSubViewType.TalentBD then
    local talentTreeTableConfig = Z.TableMgr.GetTable("TalentTreeTableMgr").GetRow(self.viewData.id)
    local talentTableConfig = Z.TableMgr.GetTable("TalentTableMgr").GetRow(talentTreeTableConfig.TalentId)
    local i = 1
    if talentTableConfig.UnlockConsume and #talentTableConfig.UnlockConsume > 0 then
      for _, unlockConsume in ipairs(talentTableConfig.UnlockConsume) do
        if self.itemVm_.GetItemTotalCount(unlockConsume[1]) < unlockConsume[2] and self.itemNotCountEnoughId_ == nil then
          self.itemNotCountEnoughId_ = unlockConsume[1]
        end
        self.lockItems_[i] = {
          Id = unlockConsume[1],
          count = unlockConsume[2]
        }
        i = i + 1
      end
    end
    if self.talentSkillVm_.GetSurpluseTalentPointCount(self.viewData.professionId) < talentTableConfig.TalentPointsConsume and self.itemNotCountEnoughId_ == nil then
      self.itemNotCountEnoughId_ = self.talentSkillData_:GetTalentPointConfigId()
    end
    self.lockItems_[i] = {
      Id = self.talentSkillData_:GetTalentPointConfigId(),
      count = talentTableConfig.TalentPointsConsume
    }
  end
  if self.talentCanPreview_ then
    self.uiBinder.btn_level_up.btn.IsDisabled = false
  else
    self.uiBinder.btn_level_up.btn.IsDisabled = self.itemNotCountEnoughId_ ~= nil and not self.conditionAllFinish_
  end
  self.uiBinder.Ref:SetVisible(self.uiBinder.lab_unlock_item, #self.lockItems_ > 0)
  Z.CoroUtil.create_coro_xpcall(function()
    for _, value in ipairs(self.lockItems_) do
      local totalCount = 0
      if value.Id == self.talentSkillData_:GetTalentPointConfigId() then
        totalCount = self.talentSkillVm_.GetSurpluseTalentPointCount(self.viewData.professionId)
      else
        totalCount = self.itemVm_.GetItemTotalCount(value.Id)
      end
      local path = self.uiBinder.uiprefab_cashedata:GetString("item")
      local unit = self:AsyncLoadUiUnit(path, value.Id, self.uiBinder.layout_item)
      self.itemUnits_[value.Id] = unit
      self.itemClassTab_[value.Id] = itemClass.new(self)
      self.itemClassTab_[value.Id]:Init({
        uiBinder = unit,
        configId = value.Id,
        labType = E.ItemLabType.Expend,
        lab = totalCount,
        expendCount = value.count,
        isSquareItem = true
      })
    end
  end)()
end

function Talent_attr_info_subView:unloadLockItems()
  if self.itemUnits_ then
    for name, _ in pairs(self.itemUnits_) do
      self:RemoveUiUnit(name)
    end
  end
  self.itemUnits_ = {}
end

function Talent_attr_info_subView:unlockTalent()
  if not self.talentSkillVm_.CheckTalentIsUnlock(self.viewData.professionId, self.viewData.id) then
    Z.TipsVM.ShowTipsLang(1042014)
    return
  end
  local talentTreeTableConfig = Z.TableMgr.GetTable("TalentTreeTableMgr").GetRow(self.viewData.id)
  if talentTreeTableConfig and talentTreeTableConfig.Unlock and not Z.ConditionHelper.CheckCondition(talentTreeTableConfig.Unlock, true, self.viewData.professionId) then
    return
  end
  local unlockbd = self.talentSkillVm_.GetUnlockTalentBD(self.viewData.professionId)
  if talentTreeTableConfig.BdType ~= 0 and unlockbd ~= 0 and unlockbd ~= talentTreeTableConfig.BdType then
    Z.TipsVM.ShowTipsLang(1042012)
    return
  end
  if self.itemNotCountEnoughId_ ~= nil then
    local itemConfig = Z.TableMgr.GetTable("ItemTableMgr").GetRow(self.itemNotCountEnoughId_)
    if itemConfig then
      Z.TipsVM.ShowTipsLang(1042023, {
        val = itemConfig.Name
      })
      self:openNotEnoughItemTips(self.itemNotCountEnoughId_)
    end
    return
  end
  if self.viewData.type == TalentSkillDefine.TalentAttrInfoSubViewType.Talent then
    self.talentSkillVm_.UnlockTalentTreeNode(self.viewData.professionId, {
      self.viewData.id
    }, self.cancelSource:CreateToken())
  else
    local dialogViewData = {
      dlgType = E.DlgType.YesNo,
      labDesc = Lang("TalentActiveAttention"),
      onConfirm = function()
        Z.DialogViewDataMgr:CloseDialogView()
        self.talentSkillVm_.UnlockTalentTreeNode(self.viewData.professionId, {
          self.viewData.id
        }, self.cancelSource:CreateToken())
      end
    }
    Z.DialogViewDataMgr:OpenDialogView(dialogViewData, E.EDialogViewDataType.Game)
  end
end

function Talent_attr_info_subView:closeSourceTip()
  if self.sourceTipId_ then
    Z.TipsVM.CloseItemTipsView(self.sourceTipId_)
    self.sourceTipId_ = nil
  end
end

function Talent_attr_info_subView:openNotEnoughItemTips(itemId)
  self:closeSourceTip()
  self.sourceTipId_ = Z.TipsVM.OpenSourceTips(itemId, self.uiBinder.rect_talent_icon)
end

function Talent_attr_info_subView:openSourceTip()
  self:closeSourceTip()
  local configId = self.talentSkillData_:GetTalentPointConfigId()
  self.sourceTipId_ = Z.TipsVM.ShowItemTipsView(self.uiBinder.rect_talent_icon, configId)
end

function Talent_attr_info_subView:unlockTalentBtn()
  local isActive = self.talentSkillVm_.CheckTalentIsActive(self.viewData.professionId, self.viewData.id)
  local isSpecialNode = self.talentSkillVm_.CheckTalentNodeIsSpecialNode(self.viewData.professionId, self.viewData.id)
  if isSpecialNode then
    if isActive then
      local talentTreeTableConfig = Z.TableMgr.GetTable("TalentTreeTableMgr").GetRow(self.viewData.id)
      if self.parentView_.isInPreview_ then
        self.parentView_:previewTalentTree(self.viewData.id)
      else
        self.parentView_:resetPreviewTalentTree(talentTreeTableConfig.TalentStage)
      end
    else
      local talentTreeTableConfig = Z.TableMgr.GetTable("TalentTreeTableMgr").GetRow(self.viewData.id)
      if self.parentView_.talentTreeIsInPreview_[talentTreeTableConfig.TalentStage + 1] == -1 then
        self.parentView_:previewTalentTree(self.viewData.id)
      else
        self.parentView_:resetPreviewTalentTree(talentTreeTableConfig.TalentStage)
      end
    end
    self:refreshNodeInfo()
  elseif not isActive then
    if self.weaponVm_.GetCurWeapon() ~= self.viewData.professionId then
      Z.TipsVM.ShowTipsLang(1042016)
      return
    end
    self:unlockTalent()
  end
end

return Talent_attr_info_subView
