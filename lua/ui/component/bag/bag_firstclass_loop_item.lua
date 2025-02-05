local super = require("ui.component.toggleitem")
local BagFirstClassLoopItem = class("BagFirstClassLoopItem", super)
local bagRed = require("rednode.bag_red")

function BagFirstClassLoopItem:ctor()
  self.commonVM_ = Z.VMMgr.GetVM("common")
end

function BagFirstClassLoopItem:OnInit()
  self.backpackVm_ = Z.VMMgr.GetVM("backpack")
end

function BagFirstClassLoopItem:Refresh()
  self.isSelected = false
  self.packageId_ = self.backpackVm_.GetFirstClassSortIdList()[self.index]
  self.itemPackageItem_ = Z.TableMgr.GetTable("ItemPackageTableMgr").GetRow(self.packageId_)
  if self.itemPackageItem_ == nil then
    return
  end
  local backpackVm = Z.VMMgr.GetVM("backpack")
  local datas = backpackVm.GetFirstClassSortIdList()
  self.totalCount_ = #datas
  self.uiBinder.img_on:SetImage(self.itemPackageItem_.Icon)
  self.uiBinder.img_off:SetImage(self.itemPackageItem_.Icon)
  self:refreshLines()
  local newNodeId = bagRed.GetNewTabRedId(self.packageId_)
  Z.RedPointMgr.LoadRedDotItem(newNodeId, self.view, self.uiBinder.Trans)
  local resonanceNodeId = bagRed.GetResonanceTabRedId(self.packageId_)
  Z.RedPointMgr.LoadRedDotItem(resonanceNodeId, self.view, self.uiBinder.Trans)
end

function BagFirstClassLoopItem:OnSelected(isOn)
  self.isSelected = isOn
  self:refreshLines()
  if isOn then
    self.commonVM_.CommonPlayTogAnim(self.uiBinder.anim_tog, self.view.cancelSource:CreateToken())
    Z.RedPointMgr.OnClickRedDot(E.RedType.Backpack .. self.packageId_)
  end
end

function BagFirstClassLoopItem:refreshLines()
end

function BagFirstClassLoopItem:UnInit()
  self.component.group = nil
  self.component.isOn = false
  self.view.cancelSource = nil
  local newNodeId = bagRed.GetNewTabRedId(self.packageId_)
  Z.RedPointMgr.RemoveNodeItem(newNodeId)
  local resonanceNodeId = bagRed.GetResonanceTabRedId(self.packageId_)
  Z.RedPointMgr.RemoveNodeItem(resonanceNodeId)
end

return BagFirstClassLoopItem
