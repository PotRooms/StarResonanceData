local br = require("sync.blob_reader")
local mergeDataFuncs = {
  [1] = function(container, buffer, watcherList)
    local last = container.__data__.seasonId
    container.__data__.seasonId = br.ReadInt32(buffer)
    container.Watcher:MarkDirty("seasonId", last)
  end,
  [2] = function(container, buffer, watcherList)
    local last = container.__data__.activationPoint
    container.__data__.activationPoint = br.ReadInt32(buffer)
    container.Watcher:MarkDirty("activationPoint", last)
  end,
  [3] = function(container, buffer, watcherList)
    local last = container.__data__.refreshTime
    container.__data__.refreshTime = br.ReadInt32(buffer)
    container.Watcher:MarkDirty("refreshTime", last)
  end,
  [4] = function(container, buffer, watcherList)
    local add = br.ReadInt32(buffer)
    local remove = 0
    local update = 0
    if add == -4 then
      return
    end
    if add == -1 then
      add = br.ReadInt32(buffer)
    else
      remove = br.ReadInt32(buffer)
      update = br.ReadInt32(buffer)
    end
    for i = 1, add do
      local dk = br.ReadInt32(buffer)
      local v = require("zcontainer.season_activation_target").New()
      v:MergeData(buffer, watcherList)
      container.activationTargets.__data__[dk] = v
      container.Watcher:MarkMapDirty("activationTargets", dk, nil)
    end
    for i = 1, remove do
      local dk = br.ReadInt32(buffer)
      local last = container.activationTargets.__data__[dk]
      container.activationTargets.__data__[dk] = nil
      container.Watcher:MarkMapDirty("activationTargets", dk, last)
    end
    for i = 1, update do
      local dk = br.ReadInt32(buffer)
      local last = container.activationTargets.__data__[dk]
      if last == nil then
        logWarning("last is nil: " .. dk)
        last = require("zcontainer.season_activation_target").New()
        container.activationTargets.__data__[dk] = last
      end
      last:MergeData(buffer, watcherList)
      container.Watcher:MarkMapDirty("activationTargets", dk, {})
    end
  end,
  [5] = function(container, buffer, watcherList)
    local add = br.ReadInt32(buffer)
    local remove = 0
    local update = 0
    if add == -4 then
      return
    end
    if add == -1 then
      add = br.ReadInt32(buffer)
    else
      remove = br.ReadInt32(buffer)
      update = br.ReadInt32(buffer)
    end
    for i = 1, add do
      local dk = br.ReadUInt32(buffer)
      local dv = br.ReadInt32(buffer)
      container.stageRewardStatus.__data__[dk] = dv
      container.Watcher:MarkMapDirty("stageRewardStatus", dk, nil)
    end
    for i = 1, remove do
      local dk = br.ReadUInt32(buffer)
      local last = container.stageRewardStatus.__data__[dk]
      container.stageRewardStatus.__data__[dk] = nil
      container.Watcher:MarkMapDirty("stageRewardStatus", dk, last)
    end
    for i = 1, update do
      local dk = br.ReadUInt32(buffer)
      local dv = br.ReadInt32(buffer)
      local last = container.stageRewardStatus.__data__[dk]
      container.stageRewardStatus.__data__[dk] = dv
      container.Watcher:MarkMapDirty("stageRewardStatus", dk, last)
    end
  end
}
local setForbidenMt = function(t)
  local mt = {
    __index = t.__data__,
    __newindex = function(_, _, _)
      error("__newindex is forbidden for container")
    end,
    __pairs = function(tbl)
      local stateless_iter = function(tbl, k)
        local v
        k, v = next(t.__data__, k)
        if nil ~= v or "__data__" ~= k then
          return k, v
        end
      end
      return stateless_iter, tbl, nil
    end
  }
  setmetatable(t, mt)
end
local resetData = function(container, pbData)
  if not container or not container.__data__ then
    error("container is nil or not container")
  end
  if not pbData then
    return
  end
  container.__data__ = pbData
  if not pbData.seasonId then
    container.__data__.seasonId = 0
  end
  if not pbData.activationPoint then
    container.__data__.activationPoint = 0
  end
  if not pbData.refreshTime then
    container.__data__.refreshTime = 0
  end
  if not pbData.activationTargets then
    container.__data__.activationTargets = {}
  end
  if not pbData.stageRewardStatus then
    container.__data__.stageRewardStatus = {}
  end
  setForbidenMt(container)
  container.activationTargets.__data__ = {}
  setForbidenMt(container.activationTargets)
  for k, v in pairs(pbData.activationTargets) do
    container.activationTargets.__data__[k] = require("zcontainer.season_activation_target").New()
    container.activationTargets[k]:ResetData(v)
  end
  container.__data__.activationTargets = nil
  container.stageRewardStatus.__data__ = pbData.stageRewardStatus
  setForbidenMt(container.stageRewardStatus)
  container.__data__.stageRewardStatus = nil
end
local mergeData = function(container, buffer, watcherList)
  if not container or not container.__data__ then
    error("container is nil or not container")
  end
  local tag = br.ReadInt32(buffer)
  if tag ~= -2 then
    error("Invalid begin tag:" .. tag)
    return
  end
  local size = br.ReadInt32(buffer)
  if size == -3 then
    return
  end
  local offset = br.Offset(buffer)
  local index = br.ReadInt32(buffer)
  while 0 < index do
    local func = mergeDataFuncs[index]
    if func ~= nil then
      func(container, buffer, watcherList)
    else
      logWarning("Unknown field: " .. index)
      br.SetOffset(buffer, offset + size)
    end
    index = br.ReadInt32(buffer)
  end
  if index ~= -3 then
    error("Invalid end tag:" .. index)
  end
  if watcherList and container.Watcher.isDirty then
    watcherList[#watcherList + 1] = container.Watcher
  end
end
local getContainerElem = function(container)
  if container == nil then
    return nil
  end
  local ret = {}
  ret.seasonId = {
    fieldId = 1,
    dataType = 0,
    data = container.seasonId
  }
  ret.activationPoint = {
    fieldId = 2,
    dataType = 0,
    data = container.activationPoint
  }
  ret.refreshTime = {
    fieldId = 3,
    dataType = 0,
    data = container.refreshTime
  }
  if container.activationTargets ~= nil then
    local data = {}
    for key, repeatedItem in pairs(container.activationTargets) do
      if repeatedItem == nil then
        data[key] = {
          fieldId = 4,
          dataType = 1,
          data = nil
        }
      else
        data[key] = {
          fieldId = 4,
          dataType = 1,
          data = repeatedItem:GetContainerElem()
        }
      end
    end
    ret.activationTargets = {
      fieldId = 4,
      dataType = 2,
      data = data
    }
  else
    ret.activationTargets = {
      fieldId = 4,
      dataType = 2,
      data = {}
    }
  end
  if container.stageRewardStatus ~= nil then
    local data = {}
    for key, repeatedItem in pairs(container.stageRewardStatus) do
      data[key] = {
        fieldId = 0,
        dataType = 0,
        data = repeatedItem
      }
    end
    ret.stageRewardStatus = {
      fieldId = 5,
      dataType = 2,
      data = data
    }
  else
    ret.stageRewardStatus = {
      fieldId = 5,
      dataType = 2,
      data = {}
    }
  end
  return ret
end
local new = function()
  local ret = {
    __data__ = {},
    ResetData = resetData,
    MergeData = mergeData,
    GetContainerElem = getContainerElem,
    activationTargets = {
      __data__ = {}
    },
    stageRewardStatus = {
      __data__ = {}
    }
  }
  ret.Watcher = require("zcontainer.container_watcher").new(ret)
  setForbidenMt(ret)
  setForbidenMt(ret.activationTargets)
  setForbidenMt(ret.stageRewardStatus)
  return ret
end
return {New = new}
