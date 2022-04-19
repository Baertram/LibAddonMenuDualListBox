--[[dualListBoxData = {
    type = "duallistbox",
    reference = "MyAddonCustomControl", -- unique name for your control to use as reference (optional) The <reference>.dualListBox is the direct reference to the dual list box control then
    refreshFunc = function(customControl) end, -- function to call when panel/controls refresh (optional)
    width = "full", -- or "half" (optional)
    minHeight = function() return db.minHeightNumber end, --or number for the minimum height of this control. Default: 26 (optional)
    maxHeight = function() return db.maxHeightNumber end, --or number for the maximum height of this control. Default: 4 * minHeight (optional)
    --The dual lists setup data
    setupData = {
        --The overall dual list box control setup data
        name = "LAM_DUALLISTBOX_EXAMPLE1",
        width       = 580, --the width of both list boxes together
        height      = 200, --the height of both list boxes together. minHeight of the LAm control needs to be >= this value!

        --The setup data for the lists
        -->The custom settings are defined via the library LibShifterBox. You can find the documentation here:
        -->https://github.com/klingo/ESO-LibShifterBox#api-reference    Search for "customSettings"
        customSettings = {
            showMoveAllButtons = true,  -- the >> and << buttons to move all entries can be hidden if set to false
            dragDropEnabled = true,     -- entries can be moved between lsit with drag-and-drop
            sortEnabled = true,         -- sorting of the entries can be disabled
            sortBy = "value",           -- sort the list by value or key (allowed are: "value" or "key")

            leftList = {                -- list-specific settings that apply to the LEFT list
                title = "",                                         -- the title/header of the list
                rowHeight = 32,                                     -- the height of an individual row/entry
                rowTemplateName = "ShifterBoxEntryTemplate",        -- an individual XML (cirtual) control can be provided for the rows/entries
                emptyListText = GetString(LIBSHIFTERBOX_EMPTY),     -- the text to be displayed if there are no entries left in the list
                fontSize = 18,                                      -- size of the font
                rowDataTypeSelectSound = SOUNDS.ABILITY_SLOTTED,    -- an optional sound to play when a row of this data type is selected
                rowOnMouseRightClick = function(rowControl, data)   -- an optional callback function when a right-click is done inside a row element (e.g. for custom context menus)
                    d("LSB: OnMouseRightClick: "..tostring(data.tooltipText))   -- reading custom 'tooltipText' from 'rowSetupAdditionalDataCallback'
                end,
                rowSetupCallback = function(rowControl, data)       -- function that will be called when a control of this type becomes visible
                    d("LSB: RowSetupCallback")                      -- Calls self:SetupRowEntry, then this function, finally ZO_SortFilterList.SetupRow
                end,
                rowSetupAdditionalDataCallback = function(rowControl, data) -- data can be extended with additional data during the 'rowSetupCallback'
                    d("LSB: SetupAdditionalDataCallback")
                    data.tooltipText = data.value
                    return rowControl, data                         -- this callback function must return the rowControl and (enriched) data again
                end,
                rowResetControlCallback = function()                -- an optional callback when the datatype control gets reset
                    d("LSB: RowResetControlCallback")
                end,
            },

            rightList = {               -- list-specific settings that apply to the RIGHT list
                title = "",                                         -- the title/header of the list
                rowHeight = 32,                                     -- the height of an individual row/entry
                rowTemplateName = "ShifterBoxEntryTemplate",        -- an individual XML (cirtual) control can be provided for the rows/entries
                emptyListText = GetString(LIBSHIFTERBOX_EMPTY),     -- the text to be displayed if there are no entries left in the list
                fontSize = 18,                                      -- size of the font
                rowDataTypeSelectSound = SOUNDS.ABILITY_SLOTTED,    -- an optional sound to play when a row of this data type is selected
                rowOnMouseRightClick = function(rowControl, data)   -- an optional callback function when a right-click is done inside a row element (e.g. for custom context menus)
                    d("LSB: OnMouseRightClick: "..tostring(data.tooltipText))   -- reading custom 'tooltipText' from 'rowSetupAdditionalDataCallback'
                end,
                rowSetupCallback = function(rowControl, data)       -- function that will be called when a control of this type becomes visible
                    d("LSB: RowSetupCallback")                      -- Calls self:SetupRowEntry, then this function, finally ZO_SortFilterList.SetupRow
                end,
                rowSetupAdditionalDataCallback = function(rowControl, data) -- data can be extended with additional data during the 'rowSetupCallback'
                    d("LSB: SetupAdditionalDataCallback")
                    data.tooltipText = data.value
                    return rowControl, data                         -- this callback function must return the rowControl and (enriched) data again
                end,
                rowResetControlCallback = function()                -- an optional callback when the datatype control gets reset
                    d("LSB: RowResetControlCallback")
                end,
            },

            callbackRegister = {                                    -- directly register callback functions with any of the exposed events
                [LibShifterBox.EVENT_LEFT_LIST_ROW_ON_MOUSE_ENTER] = function(rowControl, shifterBox, data)
                    d("LSB: LeftListRowOnMouseEnter")
                end,
                [LibShifterBox.EVENT_RIGHT_LIST_ROW_ON_MOUSE_ENTER] = function(rowControl, shifterBox, data)
                    d("LSB: RightListRowOnMouseEnter")
                end
            }
        },

        --Default keys at the lists
        leftListDefaultKeys = { --The default keys at the left list (optional). Left and right list's keys must be unique together!
        },
        rightListDefaultKeys = { --The default keys at the right list (optional). Left and right list's keys must be unique together!
            "Value1", "Value2",
        },
    },
} ]]

local widgetVersion = 1
local widgetName = "LibAddonMenuDualListBox"
local errorPrefix = "[LibAddonMenu]ERROR"

local LAM = LibAddonMenu2
local LSB = LibShifterBox --will be updated at EVENT_ADD_ON_LOADED again

local util = LAM.util
local getDefaultValue = util.GetDefaultValue

local em = EVENT_MANAGER
local wm = WINDOW_MANAGER
local cm = CALLBACK_MANAGER

local tos = tostring
local tins = table.insert
local tsort = table.sort
local strfor = string.format
local strformat = string.format


if not LAM:RegisterWidget("duallistbox", widgetVersion) then return end


local function UpdateValue(control)
    if control.data.refreshFunc then
        control.data.refreshFunc(control)
    end
end

local MIN_HEIGHT = 26


------------------------------------------------------------------------------------------------------------------------
-- variables for LibShifterBox

--The created LibShifterBoxes
local libShifterBoxes = {
    --[[
    --Example entry
    ["dualListBoxData.setupData.name] = {
        lamCustomControl  = <the control of the LAM custom control where the LibShifterBox control will be added to>
        shifterBoxControl = <the control of the LibShifterBox>
    }
    ]]
}


------------------------------------------------------------------------------------------------------------------------
-- functions for LibShifterBox

local function checkShifterBoxValid(customControl, shifterBoxSetupData, newBox)
    newBox = newBox or false
    local boxName = shifterBoxSetupData.name
    if not customControl or not boxName or boxName == "" then
        d(strfor(errorPrefix.." - Widget %q is missing the setupData subtable for box name: %q", tos(widgetName), tos(boxName)))
        return false
    end
    local boxData = libShifterBoxes[boxName]
    if newBox and boxData ~= nil then
        d(strfor(errorPrefix.." - Widget %q tried to register an already existing box name: %q", tos(widgetName), tos(boxName)))
        return false
    elseif not newBox and boxData == nil then
        d(strfor(errorPrefix.." - Widget %q tried to update an non existing box name: %q", tos(widgetName), tos(boxName)))
        return false
    end
    return true
end



local function getLeftListEntriesFull(shifterBox)
    if not shifterBox then return end
    return shifterBox:GetLeftListEntriesFull()
end

local function getRightListEntriesFull(shifterBox)
    if not shifterBox then return end
    return shifterBox:GetRightListEntriesFull()
end

local function getBoxName(shifterBox)
    if not shifterBox then return end
    for k, dataTab in pairs(libShifterBoxes) do
        if dataTab.control ~= nil and dataTab.control == shifterBox then
            return k
        end
    end
    return nil
end

local function checkAndUpdateRightListDefaultEntries(shifterBox, rightListEntries, shifterBoxData)
    if shifterBox and rightListEntries and NonContiguousCount(rightListEntries) == 0 then
        d(FCOIS.preChatVars.preChatTextRed .. locVars["LIBSHIFTERBOX_FCOIS_UNIQUEID_ITEMTYPES_RIGHT_NON_EMPTY"])
        local defaultRightListKeys = shifterBoxData and shifterBoxData.defaultRightListKeys
        if defaultRightListKeys and #defaultRightListKeys > 0 then
            shifterBox:MoveEntriesToRightList(defaultRightListKeys)
        end
    end
end

local function myShifterBoxEventEntryMovedCallbackFunction(shifterBox, key, value, categoryId, isDestListLeftList)
    if not shifterBox or not key then return end
    local boxName = getBoxName(shifterBox)
--d("LSB FCOIS, boxName: " ..tostring(boxName))
    if not boxName or boxName == "" then return end
    local shifterBoxData = libShifterBoxes[boxName]

    --Moved to the ?
    if isDestListLeftList == true then
        if boxName == FCOISuniqueIdItemTypes then
            --Moved to the left? Set SavedVariables value nil
            FCOIS.settingsVars.settings.allowedFCOISUniqueIdItemTypes[key] = nil
            --Check if any entry is left in the right list. If not:
            --Add the default values weapons and armor again and output a chat message.
            local rightListEntries = shifterBox:GetRightListEntriesFull()
            checkAndUpdateRightListDefaultEntries(shifterBox, rightListEntries, shifterBoxData)

        elseif boxName == FCOISexcludedSets then
            hideItemLinkTooltip()
            --Moved to the left? Set SavedVariables value nil
            FCOIS.settingsVars.settings.autoMarkSetsExcludeSetsList[key] = nil
        end
    else
        if boxName == FCOISuniqueIdItemTypes then
            --Moved to the right? Save to SavedVariables with value true
            FCOIS.settingsVars.settings.allowedFCOISUniqueIdItemTypes[key] = true

        elseif boxName == FCOISexcludedSets then
            hideItemLinkTooltip()
            --Moved to the right? Save to SavedVariables with value true
            FCOIS.settingsVars.settings.autoMarkSetsExcludeSetsList[key] = true
        end
    end
end

--[[
local function myShifterBoxEventEntryHighlightedCallbackFunction(control, shifterBox, key, value, categoryId, isLeftList)
    if not shifterBox or not key then return end
    local boxName = getBoxName(shifterBox)
    if not boxName or boxName == "" then return end

FCOIS._lsbHighlightedControl = control

    if isLeftList == true then
        if boxName == FCOISuniqueIdItemTypes then

        end
    else
        if boxName == FCOISuniqueIdItemTypes then

        end
    end
end
]]

local function updateLibShifterBoxEntries(parentCtrl, shifterBox, boxName)
    if not parentCtrl or not boxName or boxName == "" then return end
    local shifterBoxData = libShifterBoxes[boxName]
    shifterBox = shifterBox or shifterBoxData.control
    if not shifterBox then return end
    local settings = FCOIS.settingsVars.settings

    local leftListEntries = {}
    local rightListEntries = {}

    --FCOIS custom UniqueId
    if boxName == FCOISuniqueIdItemTypes then
        if not locVars or not locVars.ItemTypes then
            locVars = FCOISlocVars.fcois_loc
        end

        local allowedFCOISUniqueIdItemTypes = settings.allowedFCOISUniqueIdItemTypes
        for k,v in pairs(allowedFCOISUniqueIdItemTypes) do
            if v == true then
                rightListEntries[k] = strformat("%s [%s]", locVars.ItemTypes[k], tostring(k))
            else
                leftListEntries[k] = strformat("%s [%s]", locVars.ItemTypes[k], tostring(k))
            end
        end

    --Excluded sets
    elseif boxName == FCOISexcludedSets then
        --LibSets is given?
        if FCOIS.libSets then
            local libSets = FCOIS.libSets
            local allSetNames = libSets.GetAllSetNames()
            local clientLang = FCOIS.clientLanguage
            if allSetNames ~= nil then
                local autoMarkSetsExcludeSetsList = settings.autoMarkSetsExcludeSetsList
                for setId, setNamesTable in pairs(allSetNames) do
                    --local setItemId = libSets.GetSetItemId(setId)
                    -->How to add this to the data table of setNamesTable[clientLang] which will be added via AddEntriesToLeftList
                    -->Currently not possible with LibShifterBox
                    if autoMarkSetsExcludeSetsList[setId]~= nil then
                        rightListEntries[setId] = setNamesTable[clientLang]
                    else
                        leftListEntries[setId] = setNamesTable[clientLang]
                    end
                end
            end
        end
    end
    shifterBox:ClearLeftList()
    shifterBox:AddEntriesToLeftList(leftListEntries)

    shifterBox:ClearRightList()
    shifterBox:AddEntriesToRightList(rightListEntries)

    if boxName == FCOISuniqueIdItemTypes then
        checkAndUpdateRightListDefaultEntries(shifterBox, rightListEntries, shifterBoxData)
    end
end

local function updateLibShifterBoxState(parentCtrl, shifterBox, boxName)
    if not parentCtrl or not boxName or boxName == "" then return end
    local shifterBoxData = libShifterBoxes[boxName]
    shifterBox = shifterBox or shifterBoxData.control
    if not shifterBox then return end

    local isEnabled = true
    --FCOIS uniqueId itemTypes
    if boxName == FCOISuniqueIdItemTypes then
        isEnabled = FCOIS.uniqueIdIsEnabledAndSetToFCOIS()
    elseif boxName == FCOISexcludedSets then
        isEnabled = (FCOIS.libSets ~= nil and FCOIS.settingsVars.settings.autoMarkSetsExcludeSets == true) or false
    end

    parentCtrl:SetHidden(false)
    parentCtrl:SetMouseEnabled(isEnabled)
    shifterBox:SetHidden(false)
    shifterBox:SetEnabled(isEnabled)
end
FCOIS.updateLibShifterBoxState = updateLibShifterBoxState

local function myShifterBoxEventEntryHighlightedCallbackFunction(selectedRow, shifterBox, key, value, categoryId, isLeftList)
    if not shifterBox or not key then return end
    local boxName = getBoxName(shifterBox)
--df("LSB FCOIS, boxName: %s, key: %s, value: %s", tostring(boxName), tostring(key), tostring(value))
    if not boxName or boxName == "" then return end

    if boxName == FCOISexcludedSets then
        local anchorVar1 = RIGHT
        local anchorVar2 = LEFT
        if not isLeftList then
            anchorVar1 = LEFT
            anchorVar2 = RIGHT
        end
        showItemLinkTooltip(selectedRow, selectedRow, anchorVar1, 5, 0, anchorVar2)
    end
end

local function myShifterBoxEventEntryUnHighlightedCallbackFunction(selectedRow, shifterBox, key, value, categoryId, isLeftList)
    if not shifterBox or not key then return end
    local boxName = getBoxName(shifterBox)
--d("LSB FCOIS, boxName: " ..tostring(boxName))
    if not boxName or boxName == "" then return end

    if boxName == FCOISexcludedSets then
        hideItemLinkTooltip()
    end
end

local function updateLibShifterBox(parentCtrl, shifterBox, shifterBoxSetupData)
    if not checkShifterBoxValid(parentCtrl, shifterBoxSetupData, false) then return end

    local boxName = shifterBoxSetupData.name
    shifterBoxSetupData = shifterBoxSetupData or libShifterBoxes[boxName].shifterBoxSetupData
    if not shifterBoxSetupData then return end
    shifterBox = shifterBox or shifterBoxSetupData.shifterBoxControl
    if not shifterBox then return end

    parentCtrl:SetResizeToFitDescendents(true)

    shifterBox:SetAnchor(TOPLEFT, parentCtrl, TOPLEFT, 0, 0) -- will automatically call ClearAnchors
    shifterBox:SetDimensions(shifterBoxData.width, shifterBoxData.height)

    --Add the entries to the left and right shifter box
    updateLibShifterBoxEntries(parentCtrl, shifterBox, boxName)
    --Update the enabled state of the shifter box
    updateLibShifterBoxState(parentCtrl, shifterBox, boxName)

    --Add the callback function to the entry was moved event
    shifterBox:RegisterCallback(lsb.EVENT_ENTRY_MOVED,          myShifterBoxEventEntryMovedCallbackFunction)
    --Add the callback as an entry was highlighted at the left side
    shifterBox:RegisterCallback(lsb.EVENT_ENTRY_HIGHLIGHTED,    myShifterBoxEventEntryHighlightedCallbackFunction)
    shifterBox:RegisterCallback(lsb.EVENT_ENTRY_UNHIGHLIGHTED,  myShifterBoxEventEntryUnHighlightedCallbackFunction)
end

------------------------------------------------------------------------------------------------------------------------

--Create a LibShifterBox for e.g. LAM settings panel
local function createLibShifterBox(customControl, shifterBoxSetupData)
    if not checkShifterBoxValid(customControl, shifterBoxSetupData, true) then return end

    --Create the new LibShifterBox now
    local boxName = shifterBoxSetupData.name

    --LSB(... = LSB:New( ... via metatables
    -- @param uniqueAddonName - the unique name of your addon
    -- @param uniqueShifterBoxName - the unique name of this shifterBox (within your addon)
    -- @param parentControl - the control reference to which the shifterBox should be added as a child
    -- @param customSettings - OPTIONAL: override the default settings
    -- @param dimensionOptions - OPTIONAL: directly provide dimensionOptions instead of calling :SetDimensions afterwards (must be table with: number width, number height)
    -- @param anchorOptions - OPTIONAL: directly provide anchorOptions instead of calling :SetAnchor afterwards (must be table with: number whereOnMe, object anchorTargetControl, number whereOnTarget, number offsetX, number offsetY)
    -- @param leftListEntries - OPTIONAL: directly provide entries for left listBox (a table or a function returning a table)
    -- @param rightListEntries - OPTIONAL: directly provide entries for right listBox (a table or a function returning a table)
    --LibShifterBox:New(uniqueAddonName, uniqueShifterBoxName, parentControl, customSettings, anchorOptions, dimensionOptions, leftListEntries, rightListEntries)
    local shifterBox = LSB(widgetName, boxName, customControl, shifterBoxSetupData.customSettings, nil, nil, nil, nil)
    if shifterBox ~= nil then
        libShifterBoxes[boxName] = {}
        libShifterBoxes[boxName].shifterBoxSetupData = shifterBoxSetupData
        libShifterBoxes[boxName].lamCustomControl = customControl
        libShifterBoxes[boxName].shifterBoxControl = shifterBox

        --Update the shifter box position, entries, state
        updateLibShifterBox(customControl, shifterBox, shifterBoxSetupData)

        return shifterBox
    else
        d(strfor(errorPrefix.." - Widget %q was unable to create the LibShifterBox control for box name: %q", tos(widgetName), tos(boxName)))
        return
    end
end

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

local function createFunc(parent, customControl, dualListBoxData)
    --Create the LibShifterBox boxes with the provided leftList and rightList setup data
    local shifterBoxSetupData = dualListBoxData.setupData
    if not shifterBoxSetupData then
        d(strfor(errorPrefix.." - Widget %q is missing the setupData subtable for box custom control: %q", tos(widgetName), tos(customControl:GetName())))
        return
    end
    return createLibShifterBox(customControl, shifterBoxSetupData)
end


function LAMCreateControl.duallistbox(parent, dualListBoxData, controlName)
    if dualListBoxData.listsSetup == nil then return end

    local control = LAM.util.CreateBaseControl(parent, dualListBoxData, controlName)
    local width = control:GetWidth()
    control:SetResizeToFitDescendents(true)

    local minHeight = (control.data.minHeight and getDefaultValue(control.data.minHeight)) or MIN_HEIGHT
    local maxHeight = (control.data.maxHeight and getDefaultValue(control.data.maxHeight)) or (minHeight * 4)

    if control.isHalfWidth then --note these restrictions
        control:SetDimensionConstraints(width / 2, minHeight, width / 2, maxHeight)
    else
        control:SetDimensionConstraints(width, minHeight, width, maxHeight)
    end

    control.UpdateValue = UpdateValue

    LAM.util.RegisterForRefreshIfNeeded(control)

    local dualListBoxControl = createFunc(parent, control, dualListBoxData)
    if dualListBoxControl == nil then
        d(strfor(errorPrefix.." - Widget %q did not create the dual list boxes for control %q", tos(widgetName), tos(control:GetName())))
        return
    end
    control.dualListBox = dualListBoxControl
    return control
end


--Load the widget into LAM
local eventAddOnLoadedForWidgetName = widgetName .. "_EVENT_ADD_ON_LOADED"
local function registerWidget(eventId, addonName)
    if addonName ~= widgetName then return end
    em:UnregisterForEvent(eventAddOnLoadedForWidgetName, EVENT_ADD_ON_LOADED)

    LSB = LibShifterBox
    if not LSB then return end

    if not LAM:RegisterWidget("soundslider", widgetVersion) then return end
end
em:RegisterForEvent(eventAddOnLoadedForWidgetName, EVENT_ADD_ON_LOADED, registerWidget)
