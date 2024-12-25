local br = require("sync.blob_reader")
local mergeDataFuncs = {
  [1] = function(container, buffer, watcherList)
    local last = container.__data__.dungeonID
    container.__data__.dungeonID = br.ReadInt32(buffer)
    container.Watcher:MarkDirty("dungeonID", last)
  end,
  [2] = function(container, buffer, watcherList)
    local last = container.__data__.completeCount
    container.__data__.completeCount = br.ReadInt32(buffer)
    container.Watcher:MarkDirty("completeCount", last)
  end,
  [3] = function(container, buffer, watcherList)
    local last = container.__data__.awardFlg
    container.__data__.awardFlg = br.ReadInt32(buffer)
    container.Watcher:MarkDirty("awardFlg", last)
  end,
  [4] = function(container, buffer, watcherList)
    local last = container.__data__.score
    container.__data__.score = br.ReadInt32(buffer)
    container.Watcher:MarkDirty("score", last)
  end,
  [5] = function(container, buffer, watcherList)
    local last = container.__data__.passTime
    container.__data__.passTime = br.ReadInt32(buffer)
    container.Watcher:MarkDirty("passTime", last)
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
  if not pbData.dungeonID then
    container.__data__.dungeonID = 0
  end
  if not pbData.completeCount then
    container.__data__.completeCount = 0
  end
  if not pbData.awardFlg then
    container.__data__.awardFlg = 0
  end
  if not pbData.score then
    container.__data__.score = 0
  end
  if not pbData.passTime then
    container.__data__.passTime = 0
  end
  setForbidenMt(container)
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
  ret.dungeonID = {
    fieldId = 1,
    dataType = 0,
    data = container.dungeonID
  }
  ret.completeCount = {
    fieldId = 2,
    dataType = 0,
    data = container.completeCount
  }
  ret.awardFlg = {
    fieldId = 3,
    dataType = 0,
    data = container.awardFlg
  }
  ret.score = {
    fieldId = 4,
    dataType = 0,
    data = container.score
  }
  ret.passTime = {
    fieldId = 5,
    dataType = 0,
    data = container.passTime
  }
  return ret
end
local new = function()
  local ret = {
    __data__ = {},
    ResetData = resetData,
    MergeData = mergeData,
    GetContainerElem = getContainerElem
  }
  ret.Watcher = require("zcontainer.container_watcher").new(ret)
  setForbidenMt(ret)
  return ret
end
return {New = new}
