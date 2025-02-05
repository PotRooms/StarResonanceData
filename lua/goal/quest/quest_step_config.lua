local QuestStepConfig = class("QuestStepConfig")

function QuestStepConfig:ctor(stepRes)
  self.StepParam = {}
  self.StepTargetPos = {}
  self.StepTargetInfo = {}
  self.TargetHideTrackedDic = {}
  self.StepTrackedSceneId = {}
  self.StepTargetCondition = {}
  self.TimeLimitedStep = {}
  self.NpcTalkChange = {}
  self.QuestItems = {}
  self:BuildQuestStepRow(stepRes)
end

function QuestStepConfig:BuildQuestStepRow(stepRes)
  self.stepRes = stepRes
  self:processCompleteEvaluators(stepRes)
  self:processTargetCondition(stepRes)
  self:processTimeLimitedStep(stepRes)
  self:processNpcTalkChange(stepRes)
  self:processQuestItems(stepRes)
  self:processOtherAttributes(stepRes)
  self:processProgressBars(stepRes)
end

function QuestStepConfig:processCompleteEvaluators(stepRes)
  if stepRes.targetCompleteEvaluators then
    for i = 0, stepRes.targetCompleteEvaluators.Count - 1 do
      local goal = stepRes.targetCompleteEvaluators[i]
      local goalArray = goal:GetGoalArray()
      local tempParams = {}
      for t = 0, goalArray.Length - 1 do
        table.insert(tempParams, goalArray[t])
      end
      table.insert(self.StepParam, tempParams)
      local goalRes = goal.targetRes
      local tempPos = {
        goalRes.targetPosType:ToInt()
      }
      for t = 0, goalRes.targetPosIdList.Count - 1 do
        table.insert(tempPos, goalRes.targetPosIdList[t])
      end
      table.insert(self.StepTargetPos, tempPos)
      if goalRes.targetInfoProperty and goalRes.targetInfoProperty ~= "" then
        table.insert(self.StepTargetInfo, goalRes.targetInfoProperty)
      end
      self.TargetHideTrackedDic[i] = false
      if goalRes.hideTrackedIcon then
        self.TargetHideTrackedDic[i] = true
      end
      table.insert(self.StepTrackedSceneId, goalRes.trackedSceneId)
    end
  end
end

function QuestStepConfig:processTargetCondition(stepRes)
  if stepRes.stepTargetCondition then
    local processIndexList = function(indexList)
      local temp = {}
      for i = 0, indexList.Count - 1 do
        table.insert(temp, indexList[i])
      end
      return temp
    end
    if stepRes.stepTargetCondition.requiredIndexList then
      table.insert(self.StepTargetCondition, processIndexList(stepRes.stepTargetCondition.requiredIndexList))
    end
    if stepRes.stepTargetCondition.optionalIndexList then
      table.insert(self.StepTargetCondition, processIndexList(stepRes.stepTargetCondition.optionalIndexList))
    end
  end
end

function QuestStepConfig:processTimeLimitedStep(stepRes)
  if stepRes.stepFailEvaluators then
    for i = 0, stepRes.stepFailEvaluators.Count - 1 do
      local limit = stepRes.stepFailEvaluators[i]
      if tostring(limit) == "DreamMaker.Logic.EPFlowEvaluatorTaskStepLimitTime" then
        local timeLimit = limit
        local res = timeLimit.timeLimitRes
        if res then
          table.insert(self.TimeLimitedStep, {
            EvaluatorsType = E.StepTimeLimitType.FailEvaluators,
            Time = res.time,
            IsShowUI = true,
            FailMessageId = 16002003,
            SucceedMessageId = 16002002
          })
        end
      end
    end
  end
  for _, goalInfo in ipairs(self.StepParam) do
    if tonumber(goalInfo[E.GoalParam.Type]) == E.GoalType.TargetTime then
      table.insert(self.TimeLimitedStep, {
        StepTimeLimitType = E.StepTimeLimitType.TargetTime,
        Time = goalInfo[4],
        IsShowUI = self:stringToBool(goalInfo[5]),
        SucceedMessageId = tonumber(goalInfo[6]) or 16002002,
        FailMessageId = tonumber(goalInfo[7]) or 16002003
      })
    end
  end
end

function QuestStepConfig:processNpcTalkChange(stepRes)
  if stepRes.npcTalkChange then
    for i = 0, stepRes.npcTalkChange.Count - 1 do
      local data = stepRes.npcTalkChange[i]
      table.insert(self.NpcTalkChange, {
        data.npcId,
        data.flowId
      })
    end
  end
end

function QuestStepConfig:processQuestItems(stepRes)
  if stepRes.questItems then
    for i = 0, stepRes.questItems.Count - 1 do
      local data = stepRes.questItems[i]
      table.insert(self.QuestItems, {
        data.type:ToInt(),
        data.count,
        data.itemId
      })
    end
  end
end

function QuestStepConfig:processOtherAttributes(stepRes)
  self.StepTips = stepRes.stepTipsProperty or ""
  self.QuestClickJump = stepRes.questClickJump
  self.StepTargetType = stepRes.taskCompletionType:ToInt()
  self.StepMainTitle = stepRes.mainTitleProperty or ""
  self.DisableTransport = stepRes.disableTransport
  self.HideTrackBar = stepRes.hideTrackBar
end

function QuestStepConfig:processProgressBars(stepRes)
  if stepRes == nil or stepRes.progressBars == nil or stepRes.progressBars.Count < 1 then
    return
  end
  local count = stepRes.progressBars.Count - 1
  self.ProgressBarInfos = {}
  for i = 0, count do
    local barInfo = stepRes.progressBars[i]
    local progressBarInfo = {
      showBar = barInfo.showBar,
      barName = barInfo.barNameProperty,
      maxValue = barInfo.maxValue,
      initValue = barInfo.initValue
    }
    table.insert(self.ProgressBarInfos, progressBarInfo)
  end
end

function QuestStepConfig:GetTargetIsHideTrackIcon(index)
  local isHide = self.TargetHideTrackedDic[index]
  if isHide == nil then
    return false
  end
  return isHide
end

function QuestStepConfig:GetStepProgressBarsInfo()
  return self.ProgressBarInfos
end

function QuestStepConfig:stringToBool(str)
  local lowerStr = string.lower(str)
  if lowerStr == "true" or lowerStr == "1" then
    return true
  elseif lowerStr == "false" or lowerStr == "0" then
    return false
  else
    logError("Invalid boolean string: " .. str)
    return nil
  end
end

return QuestStepConfig
