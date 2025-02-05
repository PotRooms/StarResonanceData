local DEF = {}
DEF.ModType = {
  Attack = 1,
  Assistant = 2,
  Defend = 3
}
DEF.ModEffectMaxCount = 3
DEF.ModSlotMaxCount = 4
DEF.MaxEffectIntensifyCount = 30
DEF.ModIntensifyType = {Intensify = 1, Decompose = 2}
DEF.QualityCornerPath = {
  [E.ItemQuality.White] = "ui/atlas/weaponhero/profession/profes_img_b",
  [E.ItemQuality.Green] = "ui/atlas/weaponhero/profession/profes_img_b",
  [E.ItemQuality.Blue] = "ui/atlas/weaponhero/profession/profes_img_b",
  [E.ItemQuality.Purple] = "ui/atlas/weaponhero/profession/profes_img_p",
  [E.ItemQuality.Yellow] = "ui/atlas/weaponhero/profession/profes_img_r",
  [E.ItemQuality.Red] = "ui/atlas/weaponhero/profession/profes_img_r"
}
DEF.SuccessTimesIcon = {
  Empty = "ui/atlas/mod_new/mod_dot_unactivated",
  Success = "ui/atlas/mod_new/mod_dot_activated",
  Failed = "ui/atlas/mod_new/mod_dot_failure",
  Level = "ui/atlas/mod_new/mod_dot_full",
  LevelEmpty = "ui/atlas/mod_new/mod_dot_full_unactivated"
}
DEF.ModEffectLevelTipsIcon = {
  Warning = "ui/atlas/mod_new/mod_tips",
  Over = "ui/atlas/mod_new/mod_tips_red"
}
DEF.ModEffectType = {
  One = 1,
  Two = 2,
  Three = 3
}
DEF.ModSlotItemIconPath = {
  [1] = "ui/atlas/mod_new/mod_item_use1",
  [2] = "ui/atlas/mod_new/mod_item_use2",
  [3] = "ui/atlas/mod_new/mod_item_use3",
  [4] = "ui/atlas/mod_new/mod_item_use4",
  [5] = "ui/atlas/mod_new/mod_item_use5",
  [6] = "ui/atlas/mod_new/mod_item_use6"
}
DEF.ModEffectIsNegative = {
  [1] = "ui/atlas/mod_new/mod_bottom_green",
  [2] = "ui/atlas/mod_new/mod_bottom_red"
}
DEF.ModEffectBgType = {
  Attack = 1,
  Assistant = 2,
  Defend = 3,
  Other = 4,
  Negative = 5
}
DEF.ModEffectBgPath = {
  [DEF.ModEffectBgType.Attack] = "ui/atlas/mod_new/mod_device_3_frame",
  [DEF.ModEffectBgType.Assistant] = "ui/atlas/mod_new/mod_device_5_frame",
  [DEF.ModEffectBgType.Defend] = "ui/atlas/mod_new/mod_device_2_frame",
  [DEF.ModEffectBgType.Other] = "ui/atlas/mod_new/mod_device_6_frame",
  [DEF.ModEffectBgType.Negative] = "ui/atlas/mod_new/mod_device_4_frame"
}
DEF.ModMainViewAttrEffect = {
  [1] = "ui/uieffect/prefab/ui_sfx_mod_001/ui_sfx_group_mod_fankui_saoguang_green",
  [2] = "ui/uieffect/prefab/ui_sfx_mod_001/ui_sfx_group_mod_fankui_saoguang_red"
}
DEF.ModIntensifyEffect = {
  [1] = {
    [1] = "ui/uieffect/prefab/ui_sfx_mod_001/ui_sfx_group_mod_fankui_jihuo_blue_01",
    [2] = "ui/uieffect/prefab/ui_sfx_mod_001/ui_sfx_group_mod_fankui_jihuo_blue_02"
  },
  [2] = {
    [1] = "ui/uieffect/prefab/ui_sfx_mod_001/ui_sfx_group_mod_fankui_jihuo_yellow_01",
    [2] = "ui/uieffect/prefab/ui_sfx_mod_001/ui_sfx_group_mod_fankui_jihuo_yellow_02"
  }
}
return DEF
