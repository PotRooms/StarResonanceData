local CommonTipsVM = {}
local AffixColor = {
  [1] = "#62b3ff",
  [2] = "#fd6c63",
  [3] = "#ffc26d"
}

function CommonTipsVM.OpenAffixTips(affixArray, posTrans)
  if affixArray == nil then
    return
  end
  local affixDesList = {}
  for _, affixId in pairs(affixArray) do
    local affCfgData = Z.TableMgr.GetTable("AffixTableMgr").GetRow(affixId)
    if affCfgData then
      local affixName = affCfgData.Name
      local des = affCfgData.Description
      local colorStr = AffixColor[affCfgData.EffectType]
      if colorStr then
        affixName = string.format("<color=%s>%s</color>", colorStr, affixName .. Lang(":"))
      end
      affixDesList[#affixDesList + 1] = affixName .. des
    end
  end
  CommonTipsVM.ShowTipsTitleContent(posTrans, Lang("AffixInfo"), table.concat(affixDesList, [[


]]))
end

function CommonTipsVM.ShowTipsTitleContent(rect, title, content, isRightFirst)
  local viewData = {
    rect = rect,
    title = title,
    content = content,
    isRightFirst = isRightFirst ~= nil
  }
  Z.UIMgr:OpenView("tips_title_content", viewData)
end

function CommonTipsVM.CloseTipsTitleContent()
  Z.UIMgr:CloseView("tips_title_content")
end

function CommonTipsVM.ShowTipsContent(rect, content, isRightFirst)
  local viewData = {
    rect = rect,
    content = content,
    isRightFirst = isRightFirst ~= nil
  }
  Z.UIMgr:OpenView("tips_content", viewData)
end

function CommonTipsVM.CloseTipsContent()
  Z.UIMgr:CloseView("tips_content")
end

function CommonTipsVM.OpenRichText(showTable)
  local viewData = {showTable = showTable}
  Z.UIMgr:OpenView("tips_richtext", viewData)
end

function CommonTipsVM.CloseRichText()
  Z.UIMgr:CloseView("tips_richtext")
end

function CommonTipsVM.OpenUnderline(skillId)
  local viewData = {configId = skillId}
  Z.UIMgr:OpenView("tips_underline", viewData)
end

function CommonTipsVM.CloseUnderline()
  Z.UIMgr:CloseView("tips_underline")
end

function CommonTipsVM.OpenTitleContentItems(rect, title, content, itemDataArray, isRightFirst)
  local viewData = {
    rect = rect,
    title = title,
    content = content,
    itemDataArray = itemDataArray,
    isRightFirst = isRightFirst ~= nil
  }
  Z.UIMgr:OpenView("tips_title_content_items", viewData)
end

function CommonTipsVM.CloseTitleContentItems()
  Z.UIMgr:CloseView("tips_title_content_items")
end

return CommonTipsVM
