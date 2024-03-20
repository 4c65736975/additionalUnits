-- @author: 4c65736975, All Rights Reserved
-- @version: 1.0.0.0, 13|04|2023
-- @filename: PlaceableHusbandryLiquidManureUnitExtension.lua

PlaceableHusbandryLiquidManureUnitExtension = {}

local PlaceableHusbandryLiquidManureUnitExtension_mt = Class(PlaceableHusbandryLiquidManureUnitExtension)

function PlaceableHusbandryLiquidManureUnitExtension.new(customMt, additionalUnits, fillTypeManager)
  local self = setmetatable({}, customMt or PlaceableHusbandryLiquidManureUnitExtension_mt)

  self.additionalUnits = additionalUnits
  self.fillTypeManager = fillTypeManager

  return self
end

function PlaceableHusbandryLiquidManureUnitExtension:initialize()
  self.additionalUnits:overwriteGameFunction(PlaceableHusbandryLiquidManure, "getConditionInfos", function (_, husbandry, superFunc)
    local infos = superFunc(husbandry)
    local spec = husbandry.spec_husbandryLiquidManure

    local info = {}
    local fillType = self.fillTypeManager:getFillTypeByIndex(spec.fillType)
    local capacity = husbandry:getHusbandryCapacity(spec.fillType)
    local ratio = 0

    info.title = fillType.title
    info.fillType = fillType.name
    info.value = husbandry:getHusbandryFillLevel(spec.fillType)

    if capacity > 0 then
      ratio = info.value / capacity
    end

    info.ratio = MathUtil.clamp(ratio, 0, 1)
    info.invertedBar = true

    table.insert(infos, info)

    return infos
  end)

  self.additionalUnits:overwriteGameFunction(PlaceableHusbandryLiquidManure, "updateInfo", function (_, husbandry, superFunc, infoTable)
    superFunc(husbandry, infoTable)

    local spec = husbandry.spec_husbandryLiquidManure
    local fillLevel = husbandry:getHusbandryFillLevel(spec.fillType)
    local formattedFillLevel, unit = self.additionalUnits:formatFillLevel(fillLevel, self.fillTypeManager:getFillTypeNameByIndex(spec.fillType), 0)

    spec.info.text = formattedFillLevel .. " " .. unit

    table.insert(infoTable, spec.info)
  end)
end