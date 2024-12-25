local SeasonTaskTableRow
local mgr = require("utility.table_manager")
local TableInitUtility = Panda.TableInitUtility
local super = require("table.table_manager_base")
local SeasonTaskTableMgr = class("SeasonTaskTableMgr", super)

function SeasonTaskTableMgr:ctor(ptr, fields)
  super.ctor(self, ptr, fields)
end

function SeasonTaskTableMgr:GetRow(key, notErrorWhenNotFound)
  local ret = self.__rows[key]
  if ret ~= nil then
    return ret
  end
  ret = super.GetRow(self, key, "int")
  if not ret then
    if not notErrorWhenNotFound then
      logError("SeasonTaskTableMgr:GetRow key:{0} failed  in scene:{1}", key, self.GetCurrentSceneId())
    end
    return nil
  end
  return ret
end

function SeasonTaskTableMgr:GetDatas()
  return super.GetDatas(self)
end

function SeasonTaskTableMgr:ClearCache()
  local mgr = require("utility.table_manager")
  self.__rows = {}
  setmetatable(self.__rows, mgr.table_manager_mt)
end

local wrapper
return {
  __init = function(ptr, fields)
    wrapper = SeasonTaskTableMgr.new(ptr, fields)
  end,
  GetRow = function(key, notErrorWhenNotFound)
    return wrapper:GetRow(key, notErrorWhenNotFound)
  end,
  GetDatas = function()
    return wrapper:GetDatas()
  end,
  ClearCache = function()
    wrapper:ClearCache()
  end
}
