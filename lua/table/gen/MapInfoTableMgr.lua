local MapInfoTableRow
local mgr = require("utility.table_manager")
local TableInitUtility = Panda.TableInitUtility
local super = require("table.table_manager_base")
local MapInfoTableMgr = class("MapInfoTableMgr", super)

function MapInfoTableMgr:ctor(ptr, fields)
  super.ctor(self, ptr, fields)
end

function MapInfoTableMgr:GetRow(key, notErrorWhenNotFound)
  local ret = self.__rows[key]
  if ret ~= nil then
    return ret
  end
  ret = super.GetRow(self, key, "int")
  if not ret then
    if not notErrorWhenNotFound then
      logError("MapInfoTableMgr:GetRow key:{0} failed  in scene:{1}", key, self.GetCurrentSceneId())
    end
    return nil
  end
  return ret
end

function MapInfoTableMgr:GetDatas()
  return super.GetDatas(self)
end

local wrapper
return {
  __init = function(ptr, fields)
    wrapper = MapInfoTableMgr.new(ptr, fields)
  end,
  GetRow = function(key, notErrorWhenNotFound)
    return wrapper:GetRow(key, notErrorWhenNotFound)
  end,
  GetDatas = function()
    return wrapper:GetDatas()
  end
}
