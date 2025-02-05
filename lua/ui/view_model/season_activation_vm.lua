local getAllOpenFuncId = function()
  local switchVM = Z.VMMgr.GetVM("switch")
  local rowList = {}
  for id, row in pairs(Z.TableMgr.GetTable("MainIconTableMgr").GetDatas()) do
    if row.SystemPlace == 5 and switchVM.CheckFuncSwitch(id) then
      table.insert(rowList, row)
    end
  end
  table.sort(rowList, function(left, right)
    if left.SortId ~= right.SortId then
      return left.SortId < right.SortId
    end
    return left.Id < right.Id
  end)
  local idList = {}
  for _, row in ipairs(rowList) do
    table.insert(idList, row.Id)
  end
  return idList
end
local openSurveys = function()
  local questionnaireVM = Z.VMMgr.GetVM("questionnaire")
  local allQuestionnaireInfos = questionnaireVM.GetAllOpenedQuestionnaireInfos()
  if 0 < #allQuestionnaireInfos then
    questionnaireVM.OpenQuestionnaireView()
  end
end
local getActivationAwards = function()
  local awardData = Z.TableMgr.GetTable("ActivationAwardTableMgr"):GetDatas()
  return awardData
end
local checkShowMainIconEffect = function()
  local curPoint = Z.ContainerMgr.CharSerialize.seasonActivation.activationPoint
  local awardData = getActivationAwards()
  if 0 < #awardData and curPoint < awardData[#awardData - 1].Activation then
    return true
  end
  return false
end
local getRefreshCount = function()
  local keyCounterCfgData = Z.TableMgr.GetTable("CounterTableMgr").GetRow(Z.Global.ActivationRefreshCount)
  if not keyCounterCfgData or not next(keyCounterCfgData) then
    return 0
  end
  local counterData = Z.ContainerMgr.CharSerialize.counterList.counterMap[Z.Global.ActivationRefreshCount]
  local refreshCount = counterData and counterData.counter or 0
  local currentNum = keyCounterCfgData.Limit - refreshCount
  currentNum = math.max(0, currentNum)
  return currentNum, keyCounterCfgData.Limit
end
local getImageDatePath = function()
  local color_Data = {
    [1] = Color.New(1.0, 1.0, 0.8666666666666667, 1.0),
    [2] = Color.New(0.42745098039215684, 0 / 255, 0 / 255, 1.0),
    [3] = Color.New(0.4235294117647059, 0.25882352941176473, 0.16470588235294117, 1.0)
  }
  local imageTable = Z.Global.ActivationTimesIcon
  local index = 1
  local dataPath = {}
  for i, v in pairs(imageTable) do
    dataPath[i] = {}
    dataPath[i].colorText = color_Data[index]
    dataPath[i].imagePath = v
    index = index + 1
  end
  return dataPath
end
local assembleDataList = function(rateTempTable, tempTable)
  local dataList = {
    [1] = {Type = 1, Index = 1}
  }
  local maxLineNum = 0
  for i, v in ipairs(rateTempTable) do
    local lineNum = math.ceil(i / 2)
    local rowNum = i % 2 == 0 and 2 or i % 2
    if dataList[lineNum + 1] == nil then
      dataList[lineNum + 1] = {}
    end
    dataList[lineNum + 1][rowNum] = v
    if maxLineNum < lineNum then
      maxLineNum = lineNum
    end
  end
  dataList[#dataList + 1] = {Type = 1, Index = 2}
  maxLineNum = maxLineNum + 2
  for i, v in ipairs(tempTable) do
    local lineNum = math.ceil(i / 3)
    local rowNum = i % 3 == 0 and 3 or i % 3
    if dataList[lineNum + maxLineNum] == nil then
      dataList[lineNum + maxLineNum] = {}
    end
    dataList[lineNum + maxLineNum][rowNum] = v
  end
  return dataList
end
local classifyAndSortData = function(data)
  local rateTempTable = {}
  local tempTable = {}
  local funcVm = Z.VMMgr.GetVM("gotofunc")
  for k, v in pairs(data) do
    local funcOpen = true
    local activationCfg = Z.TableMgr.GetTable("ActivationTableMgr").GetRow(v.id)
    if activationCfg.IfFunctionOpen == 1 then
      funcOpen = funcVm.FuncIsOn(activationCfg.FunctionId, true)
    end
    if funcOpen then
      if v.rewardRate and v.rewardRate > 100 then
        table.insert(rateTempTable, v)
      else
        table.insert(tempTable, v)
      end
    end
  end
  table.sort(rateTempTable, function(a, b)
    return a.rewardRate > b.rewardRate
  end)
  table.sort(tempTable, function(a, b)
    local aTableData = Z.TableMgr.GetTable("ActivationTableMgr").GetRow(a.id)
    local bTableData = Z.TableMgr.GetTable("ActivationTableMgr").GetRow(b.id)
    return aTableData.Sort < bTableData.Sort
  end)
  return rateTempTable, tempTable
end
local getActivationTargetData = function()
  local data = Z.ContainerMgr.CharSerialize.seasonActivation.activationTargets
  if data and table.zcount(data) > 0 then
    local rateTempTable, tempTable = classifyAndSortData(data)
    local dataList = assembleDataList(rateTempTable, tempTable)
    return dataList
  else
    return {
      {Type = 1, Index = 1}
    }
  end
end
local checkAwardIsGet = function(id)
  local seasonRewardStatus = Z.ContainerMgr.CharSerialize.seasonActivation.stageRewardStatus
  if seasonRewardStatus and table.zcount(seasonRewardStatus) > 0 then
    for k, v in pairs(seasonRewardStatus) do
      if id == k then
        return v
      end
    end
  end
  return false
end
local hasRedPoint = function()
  local seasonRewardStatus = Z.ContainerMgr.CharSerialize.seasonActivation.stageRewardStatus
  if seasonRewardStatus and table.zcount(seasonRewardStatus) > 0 then
    for k, v in pairs(seasonRewardStatus) do
      if v == E.DrawState.AlreadyDraw then
        return true
      end
    end
  end
  return false
end
local asyncGetActivationTargetRequest = function(cancelToken)
  local worldProxy = require("zproxy.world_proxy")
  worldProxy.GetSeasonActivationTarget(cancelToken)
end
local asyncRefreshCountRequest = function(cancelToken)
  local worldProxy = require("zproxy.world_proxy")
  local ret = worldProxy.RefreshSeasonActivation(cancelToken)
  if ret and ret ~= 0 then
    Z.TipsVM.ShowTips(ret)
  elseif ret and ret == 0 then
    Z.TipsVM.ShowTips(1400002)
  end
end
local asyncReceiveActivationAwardRequest = function(stage, cancelToken)
  local worldProxy = require("zproxy.world_proxy")
  worldProxy.ReceiveSeasonActivationAward(stage, cancelToken)
end
local ret = {
  GetAllOpenFuncId = getAllOpenFuncId,
  OpenSurveys = openSurveys,
  GetActivationAwards = getActivationAwards,
  GetRefreshCount = getRefreshCount,
  GetActivationTargetData = getActivationTargetData,
  CheckAwardIsGet = checkAwardIsGet,
  HasRedPoint = hasRedPoint,
  AsyncRefreshCountRequest = asyncRefreshCountRequest,
  AsyncGetActivationTargetRequest = asyncGetActivationTargetRequest,
  AsyncReceiveActivationAwardRequest = asyncReceiveActivationAwardRequest,
  GetImageDatePath = getImageDatePath,
  CheckShowMainIconEffect = checkShowMainIconEffect
}
return ret
