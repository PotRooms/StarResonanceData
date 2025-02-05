local itemSourceVm = {}

function itemSourceVm.SetPanelItemSource(rootPanel, configId, tipsId, sourceData, isResident, goToCallFunc)
  local itemPackagePath = GetLoadAssetPath("ObtainWayPackageUnit")
  if itemPackagePath == "" or itemPackagePath == nil then
    return
  end
  local itemPath = GetLoadAssetPath("ObtainWayUnit")
  if itemPath == "" or itemPath == nil then
    return
  end
  local itemSourceTab = sourceData or itemSourceVm.GetItemSource(configId)
  local itemSourcePackages = {}
  for i = 1, #itemSourceTab do
    if itemSourceTab[i].functionId == 100103 then
      table.insert(itemSourcePackages, itemSourceTab[i])
    end
  end
  table.sort(itemSourcePackages, function(a, b)
    return a.param < b.param
  end)
  for index, functionSearchData in ipairs(itemSourcePackages) do
    local itemsVM = Z.VMMgr.GetVM("items")
    if itemsVM.GetItemTotalCount(functionSearchData.param) > 0 then
      local unit = rootPanel:AsyncLoadUiUnit(itemPackagePath, "botain_item" .. index, rootPanel.uiBinder.node_Source.transform, rootPanel.cancelSource:CreateToken())
      if unit then
        local packageConfigId = functionSearchData.param
        local itemRow = Z.TableMgr.GetTable("ItemTableMgr").GetRow(packageConfigId)
        if itemRow then
          unit.img_icon:SetImage(itemsVM.GetItemIcon(packageConfigId))
          unit.lab_package_name.text = Lang("ItemSourcePackageName", {
            val = itemRow.Name
          })
          local packageCount = itemsVM.GetItemTotalCount(packageConfigId)
          unit.lab_count.text = Lang("ItemSourcePackageCount", {val = packageCount})
        end
        local cancelSource = Z.CancelSource.Rent()
        rootPanel:AddAsyncClick(unit.img_bg, function()
          local quickItemUsageVm_ = Z.VMMgr.GetVM("quick_item_usage")
          quickItemUsageVm_.AsyncUseItem(packageConfigId, cancelSource:CreateToken())
          if rootPanel.viewData.isIgnoreItemClick then
            Z.TipsVM.CloseAllNoResidentTips()
          end
          if goToCallFunc then
            goToCallFunc()
          end
          cancelSource:Recycle()
        end)
      end
    end
  end
  for index, functionSearchData in ipairs(itemSourceTab) do
    if functionSearchData.functionId ~= 100103 then
      local unit = rootPanel:AsyncLoadUiUnit(itemPath, "botain_item" .. index, rootPanel.uiBinder.node_Source.transform, rootPanel.cancelSource:CreateToken())
      if unit then
        if functionSearchData.icon ~= "" then
          unit.img_icon:SetImage(functionSearchData.icon)
        end
        unit.lab_gameplay.text = functionSearchData.name
        unit.lab_level_open.text = ""
        rootPanel:AddClick(unit.img_bg, function()
          local quickJumpType = itemSourceVm.JumpToSource(functionSearchData)
          if not isResident and quickJumpType ~= E.QuickJumpType.Message then
            Z.TipsVM.CloseAllNoResidentTips()
          end
          if goToCallFunc then
            goToCallFunc()
          end
        end)
      end
    end
  end
end

function itemSourceVm.GetUIQuickJumpItemSource(configId)
  local itemSourceTab = itemSourceVm.GetItemSource(configId)
  local itemSourcePackages = {}
  for i = 1, #itemSourceTab do
    if itemSourceTab[i].functionId ~= E.BackpackFuncId.ItemBp then
      table.insert(itemSourcePackages, itemSourceTab[i])
    end
  end
  table.sort(itemSourcePackages, function(a, b)
    return a.param < b.param
  end)
  return itemSourcePackages
end

function itemSourceVm.JumpToSource(itemSourceData)
  local funcVM = Z.VMMgr.GetVM("gotofunc")
  if not funcVM.CheckFuncCanUse(itemSourceData.functionId) then
    return
  end
  local functionSearchCfgData = Z.TableMgr.GetTable("FunctionSearchTableMgr").GetRow(itemSourceData.functionId, true)
  if not itemSourceVm.CheckGuildSourceOpen(functionSearchCfgData) then
    return
  end
  local functionSearchCfgData = Z.TableMgr.GetTable("FunctionSearchTableMgr").GetRow(itemSourceData.functionId, true)
  local quickJumpType = functionSearchCfgData.QuickJumpType
  if quickJumpType == 0 then
    quickJumpType = E.QuickJumpType.Function
  end
  local jumpParam = {}
  if quickJumpType == E.QuickJumpType.Message then
    jumpParam.messageId = functionSearchCfgData.QuickJumpParam[1]
  elseif quickJumpType == E.QuickJumpType.Function then
    jumpParam.funcId = itemSourceData.functionId
    jumpParam.otherParam = itemSourceData.param
  elseif quickJumpType == E.QuickJumpType.TraceNearestTarget then
    local trackType = functionSearchCfgData.QuickJumpParam[1]
    jumpParam.nearTraceTargetType = trackType
    if trackType == E.NearTraceTargetType.Npc then
      jumpParam.funcId = itemSourceData.functionId
    else
      jumpParam.tagId = functionSearchCfgData.QuickJumpParam[2]
    end
    jumpParam.nearTraceTargetType = trackType
    jumpParam.goalGuideSource = E.GoalGuideSource.GetItem
  elseif quickJumpType == E.QuickJumpType.TraceSceneTarget and #functionSearchCfgData.QuickJumpParam == 3 then
    jumpParam.sceneId = functionSearchCfgData.QuickJumpParam[1]
    jumpParam.trackType = functionSearchCfgData.QuickJumpParam[2]
    jumpParam.entityId = functionSearchCfgData.QuickJumpParam[3]
    jumpParam.goalGuideSource = E.GoalGuideSource.MapFlag
  end
  local quickJumpVm = Z.VMMgr.GetVM("quick_jump")
  quickJumpVm.Jump(quickJumpType, jumpParam)
  return quickJumpType
end

function itemSourceVm.CheckGuildSourceOpen(functionSearchCfgData)
  if functionSearchCfgData.Guild ~= 1 then
    return true
  end
  local funcVM = Z.VMMgr.GetVM("gotofunc")
  local unionFuncId = 500100
  if not funcVM.FuncIsOn(unionFuncId) then
    return false
  end
  local unionVM = Z.VMMgr.GetVM("union")
  local unionId = unionVM:GetPlayerUnionId()
  local hasGuild = unionId ~= 0
  if not hasGuild then
    Z.TipsVM.ShowTips(1000595)
    return false
  end
  local quickJumpType = functionSearchCfgData.QuickJumpType
  if quickJumpType == E.QuickJumpType.TraceNearestTarget or quickJumpType == E.QuickJumpType.TraceSceneTarget then
    if unionVM:GetUnionSceneIsUnlock() then
      local unionSceneID = 12000
      local curSceneId = Z.StageMgr.GetCurrentSceneId()
      if curSceneId == unionSceneID then
        return true
      else
        Z.TipsVM.ShowTipsLang(140402)
      end
    else
      Z.TipsVM.ShowTips(1000594)
    end
    return false
  end
  return true
end

function itemSourceVm.GetItemSource(configId)
  local tb = {}
  local obtainWayCfgData = Z.TableMgr.GetTable("ObtainWayTableMgr").GetRow(configId, true)
  if obtainWayCfgData == nil then
    return tb
  end
  tb = itemSourceVm.GetItemSourceByWayDatas(obtainWayCfgData.GetWays, configId)
  return tb
end

function itemSourceVm.GetSourceByFunctionId(functionId)
  local functionSearchCfgData = Z.TableMgr.GetTable("FunctionSearchTableMgr").GetRow(functionId, true)
  if functionSearchCfgData and functionSearchCfgData.IsHide == 0 then
    local t = {}
    t.sortId = functionSearchCfgData.Sort
    t.functionId = functionId
    local functionCfgData = Z.TableMgr.GetTable("FunctionTableMgr").GetRow(functionSearchCfgData.Id)
    if functionCfgData then
      t.icon = functionCfgData.Icon
      t.name = functionCfgData.Name
    end
    return t
  end
end

function itemSourceVm.GetItemSourceByWayDatas(wayDatas, configId)
  local tb = {}
  for _, value in pairs(wayDatas) do
    local functionSearchCfgData = Z.TableMgr.GetTable("FunctionSearchTableMgr").GetRow(value[1], true)
    if functionSearchCfgData then
      if functionSearchCfgData.IsHide == 0 then
        local t = {}
        t.sortId = functionSearchCfgData.Sort
        t.functionId = value[1]
        local functionCfgData = Z.TableMgr.GetTable("FunctionTableMgr").GetRow(functionSearchCfgData.Id)
        if functionCfgData then
          t.icon = functionCfgData.Icon
          t.name = functionCfgData.Name
        end
        if functionSearchCfgData.Id == E.FunctionID.Trade then
          t.param = configId
        end
        if 1 < #value then
          t.param = value[2]
          if functionSearchCfgData.Id == E.FunctionID.HeroChallengeDungeon or functionSearchCfgData.Id == E.FunctionID.HeroNormalDungeon then
            local dungeonCfgData = Z.TableMgr.GetTable("DungeonsTableMgr").GetRow(value[2])
            if dungeonCfgData then
              t.name = dungeonCfgData.Name
            end
          elseif functionSearchCfgData.Id == E.FunctionID.Collect then
            local collectionCfgData = Z.TableMgr.GetTable("CollectionTableMgr").GetRow(value[2])
            if collectionCfgData then
              t.name = collectionCfgData.CollectionName
              t.icon = functionCfgData.Icon
            end
          elseif functionSearchCfgData.Id == E.FunctionID.Monster then
            local monsterCfgData = Z.TableMgr.GetTable("MonsterTableMgr").GetRow(value[2])
            if monsterCfgData then
              t.name = monsterCfgData.Name
              local modelCfgData = Z.TableMgr.GetTable("ModelTableMgr").GetRow(monsterCfgData.ModelID)
              if modelCfgData then
                t.icon = modelCfgData.Image
              end
            end
          end
        end
        tb[#tb + 1] = t
      end
    else
      logError("FunctionSearchTableMgr find functionId is nil  functionId = {0}", value[1])
    end
  end
  table.sort(tb, function(a, b)
    return a.sortId < b.sortId
  end)
  return tb
end

return itemSourceVm
