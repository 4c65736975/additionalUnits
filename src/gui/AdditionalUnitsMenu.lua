-- @author: 4c65736975, All Rights Reserved
-- @version: 1.0.0.0, 05|04|2023
-- @filename: AdditionalUnitsMenu.lua

AdditionalUnitsMenu = {}

local AdditionalUnitsMenu_mt = Class(AdditionalUnitsMenu, ScreenElement)

AdditionalUnitsMenu.CONTROLS = {
  "fillTypesList",
  "unitsList",
  "smoothListLayout",
  "deleteButton"
}

function AdditionalUnitsMenu.new(target, customMt, additionalUnits, gui, l10n, fillTypeManager)
  local self = AdditionalUnitsMenu:superClass().new(target, customMt or AdditionalUnitsMenu_mt)

  self.additionalUnits = additionalUnits
  self.gui = gui
  self.l10n = l10n
  self.fillTypeManager = fillTypeManager
  self.fillTypes = {}

  self:registerControls(AdditionalUnitsMenu.CONTROLS)

  return self
end

function AdditionalUnitsMenu.createFromExistingGui(gui, guiName)
  local newGui = AdditionalUnitsMenu.new(nil, nil, gui.additionalUnits, gui.gui, gui.l10n, gui.fillTypeManager)

  g_gui.guis[gui.name].target:delete()
  g_gui.guis[gui.name]:delete()

  g_gui:loadGui(gui.xmlFilename, guiName, newGui)

  return newGui
end

function AdditionalUnitsMenu:copyAttributes(src)
  AdditionalUnitsMenu:superClass().copyAttributes(self, src)

  self.additionalUnits = src.additionalUnits
  self.gui = src.gui
  self.l10n = src.l10n
  self.fillTypeManager = src.fillTypeManager
end

function AdditionalUnitsMenu:onGuiSetupFinished()
  AdditionalUnitsMenu:superClass().onGuiSetupFinished(self)

  self.fillTypesList:setDataSource(self)
  self.unitsList:setDataSource(self)
end

function AdditionalUnitsMenu:onOpen()
  AdditionalUnitsMenu:superClass().onOpen(self)

  self:rebuildTables()

  FocusManager:setFocus(self.fillTypesList)
end

function AdditionalUnitsMenu:updateMenuButtons()
  local disabled = false

  if FocusManager:getFocusedElement() == self.fillTypesList then
    disabled = true
  elseif FocusManager:getFocusedElement() == self.unitsList and self.additionalUnits:getUnitByIndex(self.unitsList.selectedIndex).isDefault == true then
    disabled = true
  end

  self.deleteButton:setDisabled(disabled)
end

function AdditionalUnitsMenu:rebuildTables()
  self.fillTypes = {}

  for _, fillTypesDesc in pairs(self.fillTypeManager:getFillTypes()) do
    if fillTypesDesc.showOnPriceTable or MISSING_FILLTYPE[fillTypesDesc.name] == true then
      table.insert(self.fillTypes, fillTypesDesc)
    end
  end

  self.fillTypesList:reloadData()
  self.unitsList:reloadData()
end

function AdditionalUnitsMenu:getNumberOfItemsInSection(list, section)
  if list == self.fillTypesList then
    return #self.fillTypes
  else
    return #self.additionalUnits.units
  end
end

function AdditionalUnitsMenu:populateCellForItemInSection(list, section, index, cell)
  if list == self.fillTypesList then
    local fillTypeDesc = self.fillTypes[index]
    local fillTypeUnit = self.additionalUnits:getUnitById(self.additionalUnits:getFillTypeUnitByFillTypeName(fillTypeDesc.name))
    local massFactor = self.additionalUnits:getMassFactorByFillTypeName(fillTypeDesc.name)

    cell:getAttribute("icon"):setImageFilename(fillTypeDesc.hudOverlayFilename)
    cell:getAttribute("title"):setText(fillTypeDesc.title)
    cell:getAttribute("unit"):setText(fillTypeUnit.unitShort)
    cell:getAttribute("mass"):setText(massFactor and string.format(self.l10n:getText("ui_additionalUnits_massFactor"), math.ceil(massFactor * 1000)) or "-")
  else
    local unit = self.additionalUnits:getUnitByIndex(index)

    cell:getAttribute("name"):setText(unit.name .. " - " .. unit.unitShort)
    cell:getAttribute("precision"):setText(unit.precision)
    cell:getAttribute("factor"):setText(MathUtil.round(unit.factor, 3))
  end
end

function AdditionalUnitsMenu:onListSelectionChanged(list, section, index)
  self:updateMenuButtons()
end

function AdditionalUnitsMenu:onClickEdit(list, section, index, element)
  if list == self.fillTypesList then
    local selectedIndex = self.fillTypesList.selectedIndex

    self.additionalUnits.gui:showEditFillTypeUnitDialog({
      fillType = self.fillTypes[selectedIndex],
      unitId = self.additionalUnits:getFillTypeUnitByFillTypeName(self.fillTypes[selectedIndex].name) or self.additionalUnits:getDefaultUnitId(),
      massFactor = self.additionalUnits:getMassFactorByFillTypeName(self.fillTypes[selectedIndex].name),
      callback = self.onEditFillTypeUnit,
      target = self
    })
  else
    self.additionalUnits.gui:showEditUnitDialog({
      data = self.additionalUnits:getUnitByIndex(self.unitsList.selectedIndex),
      callback = self.onEditUnit,
      target = self
    })
  end
end

function AdditionalUnitsMenu:onEditFillTypeUnit(fillType, unit, massFactor)
  if fillType ~= nil then
    self.additionalUnits.fillTypesUnits[fillType] = unit
    self.additionalUnits.massFactors[fillType] = massFactor
  end

  self.fillTypesList:reloadData()

  self.additionalUnits:saveMassFactorsToXMLFile()
  self.additionalUnits:saveFillTypesUnitsToXMLFile()
end

function AdditionalUnitsMenu:onEditUnit(unit)
  local unitIndex = self.additionalUnits:getUnitIndexById(unit.id)

  if unitIndex ~= nil then
    self.additionalUnits.units[unitIndex] = unit

    self.additionalUnits:saveUnitsToXMLFile()
  end

  self:rebuildTables()
end

function AdditionalUnitsMenu:onClickNew()
  self.additionalUnits.gui:showEditUnitDialog({
    callback = self.onNewUnit,
    target = self
  })
end

function AdditionalUnitsMenu:onNewUnit(unit)
  table.insert(self.additionalUnits.units, unit)

  self.gui:showInfoDialog({
    dialogType = DialogElement.TYPE_INFO,
    text = string.format(self.l10n:getText("ui_additionalUnits_createdNewUnit"), unit.name)
  })

  self.unitsList:reloadData()

  self.additionalUnits:saveUnitsToXMLFile()
end

function AdditionalUnitsMenu:onClickDelete()
  local unit = self.additionalUnits:getUnitByIndex(self.unitsList.selectedIndex)

  self.gui:showYesNoDialog({
    text = string.format(self.l10n:getText("ui_additionalUnits_youWantToDeleteUnit"), unit.name),
    title = self.l10n:getText("button_delete"),
    dialogType = DialogElement.TYPE_QUESTION,
    callback = self.onYesNoDeleteUnit,
    target = self
  })
end

function AdditionalUnitsMenu:onYesNoDeleteUnit(yes)
  if yes then
    for name, value in pairs(self.additionalUnits.fillTypesUnits) do
      if value == self.additionalUnits:getUnitByIndex(self.unitsList.selectedIndex).id then
        self.additionalUnits.fillTypesUnits[name] = self.additionalUnits:getDefaultUnitId()
      end
    end

    table.remove(self.additionalUnits.units, self.unitsList.selectedIndex)

    self.gui:showInfoDialog({
      dialogType = DialogElement.TYPE_INFO,
      text = self.l10n:getText("ui_additionalUnits_deletedUnit")
    })

    self.additionalUnits:saveUnitsToXMLFile()
    self.additionalUnits:saveFillTypesUnitsToXMLFile()

    self:rebuildTables()
  end
end

function AdditionalUnitsMenu:onClickReset()
  self.gui:showYesNoDialog({
    text = self.l10n:getText("ui_loadDefaultSettings"),
    title = self.l10n:getText("button_reset"),
    dialogType = DialogElement.TYPE_WARNING,
    callback = self.onYesNoResetSettings,
    target = self
  })
end

function AdditionalUnitsMenu:onYesNoResetSettings(yes)
  if yes then
    self.additionalUnits:reset()

    self.gui:showInfoDialog({
      dialogType = DialogElement.TYPE_INFO,
      text = self.l10n:getText("ui_loadedDefaultSettings")
    })

    self:rebuildTables()
  end
end

function AdditionalUnitsMenu:onClickBack()
  AdditionalUnitsMenu:superClass().onClickBack(self)

  self:changeScreen(nil)
end