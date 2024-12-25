local super = require("ui.model.data_base")
local ThunderElementalData = class("ThunderElementalData", super)

function ThunderElementalData:ctor()
  super.ctor(self)
  self.MainViewHideTag = false
  self.DungeonHideTag = false
  self.WorldEventDungeonData = {}
  self.WorldEventDungeonData.DungeonInfo = nil
  self.WorldEventDungeonData.ViewType = nil
end

function ThunderElementalData:SetMainViewHideTag(isShow)
  if self.MainViewHideTag ~= isShow then
    self.MainViewHideTag = isShow
  end
end

function ThunderElementalData:SetDungeonViewHideTag(isShow)
  if self.DungeonHideTag ~= isShow then
    self.DungeonHideTag = isShow
  end
end

function ThunderElementalData:SetWorldEventDungeonData(worldEventData)
  if not worldEventData then
    return
  end
  self.WorldEventDungeonData.DungeonInfo = worldEventData.dungeonInfo
  self.WorldEventDungeonData.ViewType = worldEventData.viewType
end

return ThunderElementalData
