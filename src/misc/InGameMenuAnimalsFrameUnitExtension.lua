-- @author: 4c65736975, All Rights Reserved
-- @version: 1.0.0.0, 13|04|2023
-- @filename: InGameMenuAnimalsFrameUnitExtension.lua

InGameMenuAnimalsFrameUnitExtension = {}

function InGameMenuAnimalsFrameUnitExtension:updateConditionDisplay(superFunc, husbandry)
  superFunc(self, husbandry)

  local infos = husbandry:getConditionInfos()

  for index, row in ipairs(self.conditionRow) do
    local info = infos[index]

    if info ~= nil then
      local formattedFillLevel, unit = g_additionalUnits:formatFillLevel(info.value, info.fillType)
      local valueText = info.valueText or g_i18n:formatVolume(formattedFillLevel, 0, info.customUnitText or unit.shortName)

      self.conditionValue[index]:setText(valueText)
    end
  end
end

function InGameMenuAnimalsFrameUnitExtension:updateFoodDisplay(superFunc, husbandry)
  superFunc(self, husbandry)

  local infos = husbandry:getFoodInfos()

  for index, row in ipairs(self.foodRow) do
    local info = infos[index]

    if info ~= nil then
      local formattedFillLevel, unit = g_additionalUnits:formatFillLevel(info.value, g_fillTypeManager:getFillTypeNameByIndex(info.fillType))
      local valueText = g_i18n:formatVolume(formattedFillLevel, 0, unit.shortName)

      self.foodValue[index]:setText(valueText)
    end
  end
end

function InGameMenuAnimalsFrameUnitExtension:overwriteGameFunctions()
  InGameMenuAnimalsFrame.updateConditionDisplay = Utils.overwrittenFunction(InGameMenuAnimalsFrame.updateConditionDisplay, InGameMenuAnimalsFrameUnitExtension.updateConditionDisplay)
  InGameMenuAnimalsFrame.updateFoodDisplay = Utils.overwrittenFunction(InGameMenuAnimalsFrame.updateFoodDisplay, InGameMenuAnimalsFrameUnitExtension.updateFoodDisplay)
end