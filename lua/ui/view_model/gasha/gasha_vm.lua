local gashaVM = {}

function gashaVM.HandleError(errCode)
  if errCode ~= 0 and Z.PbEnum("EErrorCode", "ErrAsynchronousReturn") ~= errCode then
    Z.TipsVM.ShowTips(errCode)
  end
end

function gashaVM.OpenGashaView(gashaId)
  if type(gashaId) == "string" then
    gashaId = tonumber(gashaId)
  end
  gashaId = tonumber(gashaId)
  local gashaPool = Z.TableMgr.GetRow("GashaPoolTableMgr", gashaId)
  if gashaPool == nil then
    return
  end
  local openGashas_ = gashaVM.GetOpenGashas()
  if openGashas_ and #openGashas_ == 0 then
    Z.TipsVM.ShowTips(1382001)
    return
  end
  if gashaPool.Work == 0 or not Z.TimeTools.CheckIsInTimeByTimeId(gashaPool.TimerId) then
    Z.UIMgr:OpenView("gasha_window")
    return
  end
  Z.UIMgr:OpenView("gasha_window", {gashaId = gashaId})
end

function gashaVM.CloseGashaView(gashaId)
  Z.UIMgr:CloseView("gasha_window")
end

function gashaVM.OpenGashaDetailView(gashaId)
  Z.UIMgr:OpenView("gasha_detail_window", {gashaId = gashaId})
end

function gashaVM.CloseGashaDetailView()
  Z.UIMgr:CloseView("gasha_detail_window")
end

function gashaVM.OpenGashaHighQualityDetailView(gashaId, item)
  Z.UIMgr:OpenView("gasha_highqualitydetail_window", {gashaId = gashaId, item = item})
end

function gashaVM.CloseGashaHighQualityDetailView()
  Z.UIMgr:CloseView("gasha_highqualitydetail_window")
end

function gashaVM.OpenGashaRecordView(gashaId, cancelToken)
  Z.CoroUtil.create_coro_xpcall(function()
    local gashaPoolTableRow_ = Z.TableMgr.GetRow("GashaPoolTableMgr", gashaId)
    if not gashaPoolTableRow_ then
      return
    end
    Z.UIMgr:OpenView("gasha_record_window", {
      gashaShareId = gashaPoolTableRow_.ShareGuarantee
    })
  end, function(err)
    logError(err)
  end)()
end

function gashaVM.CloseGashaRecordView()
  Z.UIMgr:CloseView("gasha_record_window")
end

function gashaVM.OpenGashaResultView(gashaId, items)
  Z.UIMgr:OpenView("gasha_result_window", {gashaId = gashaId, items = items})
end

function gashaVM.CloseGashaResultView()
  Z.UIMgr:CloseView("gasha_result_window")
end

function gashaVM.GetGashaTodayAttempt(gashaId)
  local gashaInfosEntry = Z.ContainerMgr.CharSerialize.gashaData.gashaInfos
  if gashaInfosEntry == nil then
    return 0
  end
  local gashaInfo = gashaInfosEntry[gashaId]
  if gashaInfo == nil then
    return 0
  end
  return gashaInfo.drawCount
end

function gashaVM.GetGashaResidueGuaranteeCount(gashaId)
  local gashaPoolTableRow_ = Z.TableMgr.GetRow("GashaPoolTableMgr", gashaId)
  if not gashaPoolTableRow_ then
    return 0, 0
  end
  local gashaGuaranteeInfosEntry = Z.ContainerMgr.CharSerialize.gashaData.gashaGuaranteeInfos
  if gashaGuaranteeInfosEntry == nil then
    return 0, 0
  end
  local gashaGuaranteeInfo = gashaGuaranteeInfosEntry[gashaPoolTableRow_.ShareGuarantee]
  if gashaGuaranteeInfo == nil or gashaGuaranteeInfo.residueGuaranteeTimeX == nil or gashaGuaranteeInfo.residueGuaranteeTimeY == nil then
    logError("\229\174\185\229\153\168\228\184\173gashaInfo\228\184\186\231\169\186\239\188\140\233\156\128\232\166\129\229\144\142\231\171\175\230\159\165\231\156\139,gashaId:" .. gashaId)
    return 0, 0
  end
  return gashaGuaranteeInfo.residueGuaranteeTimeX, gashaGuaranteeInfo.residueGuaranteeTimeY
end

function gashaVM.AsyncGetGashaRecord(gashaShareId, startIndex, num, cancelToken)
  local gashaData = Z.DataMgr.Get("gasha_data")
  local gashaRecoredData = gashaData:GetHistoryByGashaId(gashaShareId, startIndex, num)
  if gashaRecoredData ~= nil then
    return gashaRecoredData
  end
  local worldProxy = require("zproxy.world_proxy")
  local req = {
    poolId = gashaShareId,
    startId = startIndex,
    count = num * gashaData.RecordPageCount
  }
  local ret = worldProxy.GashaRecord(req, cancelToken)
  if ret ~= nil then
    if ret.errCode ~= 0 then
      gashaVM.HandleError(ret.errCode)
    else
      if startIndex == 0 then
        gashaData:SetRecordTotalCount(gashaShareId, ret.totalCount)
      end
      if ret.totalCount == 0 then
        gashaData:AppendHistory(gashaShareId, {})
        return {}
      end
      gashaData:AppendHistory(gashaShareId, ret.gashaRecordDatas.gashaRecordInfo)
      return gashaData:GetHistoryByGashaId(gashaShareId, startIndex, num)
    end
  end
  return nil
end

function gashaVM.GetGashaDetail(gashaId)
  local gashaPool = Z.TableMgr.GetRow("GashaPoolTableMgr", gashaId)
  if gashaPool == nil then
    return nil
  end
  local gashaDetailData = {}
  gashaDetailData.gashaId = gashaId
  gashaDetailData.gashaPoolName = gashaPool.Name
  gashaDetailData.gashaPoolDesc = gashaPool.PoolDesc
  local awardVm = Z.VMMgr.GetVM("awardpreview")
  local awardPackageGroup = {}
  for index, value in ipairs(gashaPool.AwardPackageGroup) do
    local awards = awardVm.GetAllAwardPreListByIds(value)
    local name = gashaPool.QualityTitle[index]
    table.insert(awardPackageGroup, 1, {name = name, awards = awards})
  end
  gashaDetailData.awardPackageGroup = awardPackageGroup
  return gashaDetailData
end

function gashaVM.CheckGashaCost(gashaId, count)
  local gashaPool = Z.TableMgr.GetRow("GashaPoolTableMgr", gashaId)
  if gashaPool == nil then
    return false
  end
  local cost
  if count == 10 then
    cost = gashaPool.CostSecond
  elseif count == 1 then
    cost = gashaPool.Cost
  else
    logError("\231\173\150\229\136\146\230\156\170\233\133\141\231\189\174\230\138\189\229\165\150\230\182\136\232\128\151\233\129\147\229\133\183 \230\138\189\229\165\150\230\172\161\230\149\176\228\184\186\239\188\154" .. count)
    return false
  end
  local itemsVm = Z.VMMgr.GetVM("items")
  local totalCount = itemsVm.GetItemTotalCount(cost[1])
  return totalCount >= cost[2], cost[1]
end

function gashaVM.ValidateDrawConditions(gashaId, count)
  local isEnough, costId = gashaVM.CheckGashaCost(gashaId, count)
  if not isEnough then
    local itemTableRow = Z.TableMgr.GetRow("ItemTableMgr", costId)
    Z.TipsVM.ShowTips(100010, {
      item = {
        name = itemTableRow.Name
      }
    })
    return false
  end
  local row = Z.TableMgr.GetRow("GashaPoolTableMgr", gashaId)
  if row == nil then
    return false
  end
  if gashaVM.GetGashaTodayAttempt(gashaId) >= row.Limit then
    gashaVM.HandleError(7022)
    return false
  end
  return true
end

function gashaVM.AsyncGashaRequest(gashaId, count, cancelToken)
  local itemsData = Z.DataMgr.Get("items_data")
  itemsData:SetIgnoreItemTips(true)
  local personalzoneData = Z.DataMgr.Get("personal_zone_data")
  personalzoneData:SetIgnorePopup(true)
  local req = {poolId = gashaId, count = count}
  local worldProxy = require("zproxy.world_proxy")
  local ret = worldProxy.GashaDraw(req, cancelToken)
  return ret
end

function gashaVM.PlayGashaCutScene(gashaId, param, bestResultQuality, isSingleDraw, beforeInitAction, stopCallback, finishCallback)
  local gashaPool = Z.TableMgr.GetRow("GashaPoolTableMgr", gashaId)
  if gashaPool == nil then
    return
  end
  local cutSceneIdMap = gashaPool.Cutscene
  local cutSceneId = 0
  if isSingleDraw then
    cutSceneId = cutSceneIdMap[1][bestResultQuality]
  else
    cutSceneId = cutSceneIdMap[2][bestResultQuality]
  end
  if gashaPool.Show == 0 or cutSceneId == 0 then
    if finishCallback ~= nil and type(finishCallback) == "function" then
      finishCallback()
    end
    return
  end
  Z.UITimelineDisplay:Play(cutSceneId, finishCallback, stopCallback, beforeInitAction)
end

function gashaVM.StopGashaCutScene(gashaId)
  local gashaPool = Z.TableMgr.GetRow("GashaPoolTableMgr", gashaId)
  if gashaPool == nil then
    return
  end
  local cutSceneId = gashaPool.Cutscene
  if gashaPool.Show == 0 or cutSceneId == 0 then
    return
  end
  Z.UITimelineDisplay:Stop()
end

function gashaVM.GetOpenGashas()
  local gashas = Z.TableMgr.GetTable("GashaPoolTableMgr").GetDatas()
  local openGashas = {}
  for k, v in pairs(gashas) do
    if gashaVM.CheckGashaOpen(v) then
      table.insert(openGashas, v)
    end
  end
  table.sort(openGashas, function(a, b)
    return a.Sort < b.Sort
  end)
  return openGashas
end

function gashaVM.CheckGashaOpen(gashaPoolTableRow)
  if gashaPoolTableRow.Work == 0 then
    return false
  end
  local gashaTimeID = gashaPoolTableRow.TimerId
  if not Z.TimeTools.CheckIsInTimeByTimeId(gashaTimeID) then
    return false
  end
  return true
end

function gashaVM.RegisteFuncShow()
  local mainUiVm_ = Z.VMMgr.GetVM("mainui")
  mainUiVm_.RegistClientFuncShow(800820, gashaVM.ShowFuncIcon)
end

function gashaVM.ShowFuncIcon()
  local openGashas_ = gashaVM.GetOpenGashas()
  if openGashas_ and 0 < #openGashas_ then
    return true
  end
  return false
end

return gashaVM
