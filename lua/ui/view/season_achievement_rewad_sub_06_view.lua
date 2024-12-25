local UI = Z.UI
local super = require("ui.ui_subview_base")
local Season_achievement_rewad_sub_06View = class("Season_achievement_rewad_sub_06View", super)

function Season_achievement_rewad_sub_06View:ctor(parent)
  self.uiBinder = nil
  self.parentView_ = parent
  super.ctor(self, "season_achievement_rewad_sub_06", "season_achievement/season_achievement_rewad_sub_06", UI.ECacheLv.None)
end

function Season_achievement_rewad_sub_06View:OnActive()
  self.gradeList_ = {
    self.uiBinder.grade1,
    self.uiBinder.grade2,
    self.uiBinder.grade3,
    self.uiBinder.grade4,
    self.uiBinder.grade5,
    self.uiBinder.grade6,
    self.uiBinder.grade7,
    self.uiBinder.grade8,
    self.uiBinder.grade9,
    self.uiBinder.grade10,
    self.uiBinder.grade11,
    self.uiBinder.grade12
  }
  self.parentView_:RefreshAchievement(self, self.gradeList_)
end

return Season_achievement_rewad_sub_06View
