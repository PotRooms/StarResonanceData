local ret = {}

function ret.AsyncUseItem(configId, cancelToken)
  local itemFunctionTableMgr = Z.TableMgr.GetTable("ItemFunctionTableMgr")
  local itemFunctionTable = itemFunctionTableMgr.GetRow(configId)
  if itemFunctionTable == nil then
    return
  end
  local itemsVM = Z.VMMgr.GetVM("items")
  local count = itemsVM.GetItemTotalCount(configId)
  local isOk = itemsVM.OpenSelectGiftPackageView(configId, nil, count)
  if isOk then
    return
  end
  isOk = itemsVM.OpenBatchUseView(configId, nil, count)
  if isOk then
    return
  end
  return itemsVM.AsyncUseItemByConfigId(configId, cancelToken)
end

function ret.checkCanQuickUse(configId)
  local itemTableMgr = Z.TableMgr.GetTable("ItemTableMgr")
  local itemTable = itemTableMgr.GetRow(configId)
  if itemTable == nil or itemTable.QuickUse == 0 then
    return false
  end
  local itemFunctionTableMgr = Z.TableMgr.GetTable("ItemFunctionTableMgr")
  local itemFunctionTable = itemFunctionTableMgr.GetRow(configId, true)
  if itemFunctionTable == nil then
    return false
  end
  if itemFunctionTable.Type == E.ItemFunctionType.Gift then
    return true
  end
  return false
end

function ret.AddItemToQuickUseQueue(configId)
  if not ret.checkCanQuickUse(configId) then
    return
  end
  local quickItemUsageData = Z.DataMgr.Get("quick_item_usage_data")
  quickItemUsageData:EnItemQuickQueue(configId)
  ret.ShowQuickUseView()
end

function ret.ShowQuickUseView()
  local quickItemUsageData = Z.DataMgr.Get("quick_item_usage_data")
  if not quickItemUsageData:HasQuickUseItem() then
    return
  end
  Z.UIMgr:OpenView("quick_item_usage")
end

function ret.DelQuickItemData(configId)
  local quickItemUsageData = Z.DataMgr.Get("quick_item_usage_data")
  if not quickItemUsageData:CheckItemVail(configId) then
    return
  end
  quickItemUsageData:DeItemQuickQueue(configId)
  Z.UIMgr:OpenView("quick_item_usage")
end

function ret.CloseQuickUseView()
  Z.UIMgr:CloseView("quick_item_usage")
end

return ret
