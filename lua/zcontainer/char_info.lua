local br = require("sync.blob_reader")
local mergeDataFuncs = {
  [1] = function(container, buffer, watcherList)
    container.baseInfo:MergeData(buffer, watcherList)
    container.Watcher:MarkDirty("baseInfo", {})
  end,
  [2] = function(container, buffer, watcherList)
    container.sceneInfo:MergeData(buffer, watcherList)
    container.Watcher:MarkDirty("sceneInfo", {})
  end,
  [3] = function(container, buffer, watcherList)
    local last = container.__data__.errCode
    container.__data__.errCode = br.ReadInt32(buffer)
    container.Watcher:MarkDirty("errCode", last)
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
  if not pbData.baseInfo then
    container.__data__.baseInfo = {}
  end
  if not pbData.sceneInfo then
    container.__data__.sceneInfo = {}
  end
  if not pbData.errCode then
    container.__data__.errCode = 0
  end
  setForbidenMt(container)
  container.baseInfo:ResetData(pbData.baseInfo)
  container.__data__.baseInfo = nil
  container.sceneInfo:ResetData(pbData.sceneInfo)
  container.__data__.sceneInfo = nil
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
  if container.baseInfo == nil then
    ret.baseInfo = {
      fieldId = 1,
      dataType = 1,
      data = nil
    }
  else
    ret.baseInfo = {
      fieldId = 1,
      dataType = 1,
      data = container.baseInfo:GetContainerElem()
    }
  end
  if container.sceneInfo == nil then
    ret.sceneInfo = {
      fieldId = 2,
      dataType = 1,
      data = nil
    }
  else
    ret.sceneInfo = {
      fieldId = 2,
      dataType = 1,
      data = container.sceneInfo:GetContainerElem()
    }
  end
  ret.errCode = {
    fieldId = 3,
    dataType = 0,
    data = container.errCode
  }
  return ret
end
local new = function()
  local ret = {
    __data__ = {},
    ResetData = resetData,
    MergeData = mergeData,
    GetContainerElem = getContainerElem,
    baseInfo = require("zcontainer.char_base_info").New(),
    sceneInfo = require("zcontainer.scene_info").New()
  }
  ret.Watcher = require("zcontainer.container_watcher").new(ret)
  setForbidenMt(ret)
  return ret
end
return {New = new}
