--[[dualListBoxData = {
    type = "duallistbox",
    reference = "MyAddonDualListBox1", -- unique name for your control to use as reference (optional) The <reference>.dualListBox is the direct reference to the dual list box control then
    refreshFunc = function(customControl) end, -- function to call when panel/controls refresh (optional)
    width = "full", -- or "half" (optional)
    minHeight = function() return db.minHeightNumber end, --or number for the minimum height of this control. Default: 26 (optional)
    maxHeight = function() return db.maxHeightNumber end, --or number for the maximum height of this control. Default: 4 * minHeight (optional)
    disabled  = false,    --boolean value or function returning a boolean to tell if the dual list box widget is disabled (default = false). (optional)
--======================================================================================================================
    -- -v- The dual lists setup data                                                                                -v-
--======================================================================================================================
    setupData = {
        --The overall dual list box control setup data
        name = "LAM_DUALLISTBOX_EXAMPLE1",
        width       = 580,      --number or function returning a number for the width of both list boxes together. If > the width of the LAM control container then the width willbe the LAM control container's width.
        height      = 200,      --number or function returning a number for the height of both list boxes together. minHeight of the LAM control needs to be >= this value! If > maxHeight then maxHeight of the LAM contro will be used

--======================================================================================================================
    ----  -v- The custom settings for the dual lists                                                            -v-
--======================================================================================================================
        --The setup data for the lists
        -->The custom settings are defined via the library LibShifterBox. You can find the documentation here:
        -->https://github.com/klingo/ESO-LibShifterBox#api-reference    Search for "customSettings"
        customSettings = {
            showMoveAllButtons = true,  -- the >> and << buttons to move all entries can be hidden if set to false (default = true). (optional)
            dragDropEnabled = true,     -- entries can be moved between lsit with drag-and-drop (default = true). (optional)
            sortEnabled = true,         -- sorting of the entries can be disabled (default = true). (optional)
            sortBy = "value",           -- sort the list by value or key (allowed are: "value" or "key")  (default = "value"). (optional)

--======================================================================================================================
            leftList = {                -- list-specific settings that apply to the LEFT list
                title = "",                                         -- the title/header of the list (default = ""). (optional)
                rowHeight = 32,                                     -- the height of an individual row/entry (default = 32). (optional)
                rowTemplateName = "ShifterBoxEntryTemplate",        -- an individual XML (cirtual) control can be provided for the rows/entries (default = "ShifterBoxEntryTemplate"). (optional)
                emptyListText = GetString(LIBSHIFTERBOX_EMPTY),     -- the text to be displayed if there are no entries left in the list (default = GetString(LIBSHIFTERBOX_EMPTY)). (optional)
                fontSize = 18,                                      -- size of the font (default = 18). (optional)
                rowDataTypeSelectSound = SOUNDS.ABILITY_SLOTTED,    -- an optional String for an internal soundName to play when a row of this data type is selected (default = SOUNDS.ABILITY_SLOTTED). (optional)
                rowOnMouseRightClick = function(rowControl, data)   -- an optional callback function when a right-click is done inside a row element (e.g. for custom context menus) (optional)
                    d("LSB: OnMouseRightClick: "..tostring(data.tooltipText))   -- reading custom 'tooltipText' from 'rowSetupAdditionalDataCallback'
                end,
                rowSetupCallback = function(rowControl, data)       -- function that will be called when a control of this type becomes visible (optional)
                    d("LSB: RowSetupCallback")                      -- Calls self:SetupRowEntry, then this function, finally ZO_SortFilterList.SetupRow
                end,
                rowSetupAdditionalDataCallback = function(rowControl, data) -- an optional function to extended data table of the row with additional data during the 'rowSetupCallback' (optional)
                    d("LSB: SetupAdditionalDataCallback")
                    data.tooltipText = data.value
                    return rowControl, data                         -- this callback function must return the rowControl and (enriched) data again
                end,
                rowResetControlCallback = function()                -- an optional callback function when the datatype control gets reset (optional)
                    d("LSB: RowResetControlCallback")
                end,
            },

--======================================================================================================================
            rightList = {               -- list-specific settings that apply to the RIGHT list
                title = "" ,
                ...
                --> See "leftList = {" above -> The entries are the same!
            },

--======================================================================================================================
            --Callbacks that fire as a list is created, filled, cleared, entry is slected, unselected, row mouseOver, row mouseExit, dragDropStart, dragDropEnd, etc. happens
            callbackRegister = {                                    -- directly register callback functions with any of the exposed events
                [LibShifterBox.EVENT_LEFT_LIST_ROW_ON_MOUSE_ENTER] = function(rowControl, shifterBox, data)
                    d("LSB: LeftListRowOnMouseEnter")
                end,
                [LibShifterBox.EVENT_RIGHT_LIST_ROW_ON_MOUSE_ENTER] = function(rowControl, shifterBox, data)
                    d("LSB: RightListRowOnMouseEnter")
                end
                ...
                -> For a complete list of the events please visit the LibShifterBox documentation:
                -> https://github.com/klingo/ESO-LibShifterBox#api-reference  Search for "ShifterBox:RegisterCallback"
            }
        },

--======================================================================================================================
        --Default keys at the lists
        leftListDefaultKeys = { --table or function returning a table with the default keys at the left list (optional). Left and right list's keys must be unique in total!
        },
        rightListDefaultKeys = { --table or function returning a table with the  default keys at the right list (optional). Left and right list's keys must be unique in total!
            "Value1", "Value2",
        },
--======================================================================================================================
    ----  -^- The custom settings for the dual lists                                                            -^-
--======================================================================================================================
    },
--======================================================================================================================
    -- -^- The dual lists setup data                                                                                -^-
--======================================================================================================================
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
local strfor = string.format
local zocl = zo_clamp

if not LAM:RegisterWidget("duallistbox", widgetVersion) then return end


local MIN_HEIGHT = 26
local MIN_WIDTH = 50
local MAX_WIDTH = 0


--LibShifterBox dependent variables
local libShifterBoxPossibleEventNames = LSB ~= nil and LSB.allowedEventNames    --will be updated at EVENT_ADD_ON_LOADED again
local libShifterBoxEventNameToId = {}                                           --will be updated at EVENT_ADD_ON_LOADED
local myShifterBoxLocalEventFunctions = {}                                      --The table with the local event callback functions for each eventId. See function assignLocalCallbackFunctionsToEventNames

------------------------------------------------------------------------------------------------------------------------
-- variables for LibShifterBox

--The created LibShifterBoxes
local libShifterBoxes = {
    --[[
    --Example entry
    ["dualListBoxData.setupData.name] = {
        name                = dualListBoxData.setupData.name,
        shifterBoxSetupData = dualListBoxData.setupData,
        lamCustomControl    = <the control of the LAM custom control where the LibShifterBox control will be added to>
        shifterBoxControl   = <the control of the LibShifterBox>
    }
    ]]
}


------------------------------------------------------------------------------------------------------------------------
-- functions for LibShifterBox

local function getBoxName(shifterBox)
    if not shifterBox then return end
    for k, dataTab in pairs(libShifterBoxes) do
        local shifterBoxControl = dataTab.shifterBoxControl
        if shifterBoxControl ~= nil and shifterBoxControl == shifterBox then
            return k
        end
    end
    return nil
end


local function checkAndGetShifterBoxNameAndData(shifterBox)
    if not shifterBox then return nil, nil end
    local boxName = shifterBox.boxName or getBoxName(shifterBox)
    if not boxName or boxName == "" then return nil, nil end
    local shifterBoxData = libShifterBoxes[boxName]
    if not shifterBoxData then return nil, nil end
    return boxName, shifterBoxData
end


local function checkShifterBoxValid(customControl, shifterBoxSetupData, newBox)
    newBox = newBox or false
    if not shifterBoxSetupData then
        d(strfor(errorPrefix.." - Widget %q is missing the subtable setupData for the customControl name: %q", tos(widgetName), tos(customControl:GetName())))
        return false
    end
    local boxName = shifterBoxSetupData.name
    if not customControl or not boxName or boxName == "" then
        d(strfor(errorPrefix.." - Widget %q is missing the setupData subtable for box name: %q", tos(widgetName), tos(boxName)))
        return false
    end
    local boxData = libShifterBoxes[boxName]
    if newBox and boxData ~= nil then
        d(strfor(errorPrefix.." - Widget %q tried to register an already existing box name: %q", tos(widgetName), tos(boxName)))
        return false
    elseif not newBox then
        if boxData == nil then
            d(strfor(errorPrefix.." - Widget %q tried to update an non existing box name: %q", tos(widgetName), tos(boxName)))
            return false
        elseif boxData ~= nil and boxData.shifterBoxControl == nil then
            d(strfor(errorPrefix.." - Widget %q tried to update an non existing LibShifterBox control of box name: %q", tos(widgetName), tos(boxName)))
            return false
        end
    end
    return true
end


------------------------------------------------------------------------------------------------------------------------

local function getLeftListEntriesFull(customControl)
    if not customControl then return end
    local shifterBox = customControl.dualListBoxData
    if not shifterBox then return end
    return shifterBox:GetLeftListEntriesFull()
end


local function getRightListEntriesFull(customControl)
    if not customControl then return end
    local shifterBox = customControl.dualListBoxData
    if not shifterBox then return end
    return shifterBox:GetRightListEntriesFull()
end

------------------------------------------------------------------------------------------------------------------------


local function checkAndUpdateRightListDefaultEntries(shifterBox, rightListEntries, shifterBoxData)
    if shifterBox and rightListEntries and NonContiguousCount(rightListEntries) == 0 then
        --d("Right list is empty!")
        local defaultRightListKeys = shifterBoxData and shifterBoxData.defaultRightListKeys
        if defaultRightListKeys and #defaultRightListKeys > 0 then
            shifterBox:MoveEntriesToRightList(defaultRightListKeys)
        end
    end
end


local function updateLibShifterBoxEntries(customControl, dualListBoxData, shifterBoxControl, isLeftList, newValues)
    local shifterBoxSetupData = dualListBoxData.setupData
    if not checkShifterBoxValid(customControl, shifterBoxSetupData, false) then return end

    isLeftList = isLeftList or false
    local boxName = shifterBoxSetupData.name
    local shifterBoxData = libShifterBoxes[boxName]
    shifterBoxSetupData = shifterBoxSetupData or shifterBoxData.shifterBoxSetupData
    if not shifterBoxSetupData then return end
    shifterBoxControl = shifterBoxControl or shifterBoxData.shifterBoxControl
    if not shifterBoxControl then return end

    --Force defaults?
    local forceDefaults = (newValues == nil and true) or false
    local leftListEntries, rightListEntries

    --Use default left list entries or nothing provided?
    if forceDefaults == true then
        if isLeftList == true and shifterBoxSetupData.leftListDefaultKeys ~= nil then
            leftListEntries = getDefaultValue(shifterBoxSetupData.leftListDefaultKeys)
            leftListEntries = leftListEntries or {}

        elseif not isLeftList and shifterBoxSetupData.rightListDefaultKeys ~= nil then
            rightListEntries = getDefaultValue(shifterBoxSetupData.rightListDefaultKeys)
            rightListEntries = rightListEntries or {}
        end
    else
        if isLeftList == true then
            leftListEntries = newValues
        else
            rightListEntries = newValues
        end
    end

    --Update the lists visually now
    if isLeftList == true then
        shifterBoxControl:ClearLeftList()
        shifterBoxControl:AddEntriesToLeftList(leftListEntries)
    else
        shifterBoxControl:ClearRightList()
        shifterBoxControl:AddEntriesToRightList(rightListEntries)
    end
    --Check for empty right list? fill up with default values again
    --checkAndUpdateRightListDefaultEntries(shifterBoxControl, rightListEntries, shifterBoxData)
end


local function updateLibShifterBoxEnabledState(customControl, shifterBoxControl, isEnabled)
    if not customControl then return end
    if not shifterBoxControl then return end

    customControl:SetHidden(false)
    customControl:SetMouseEnabled(isEnabled)
    shifterBoxControl:SetHidden(false)
    shifterBoxControl:SetEnabled(isEnabled)
end


local function UpdateDisabled(control)
    local disable = getDefaultValue(control.data.disabled)
    --[[
    --No label given!
    if disable == true then
        control.label:SetColor(ZO_DEFAULT_DISABLED_COLOR:UnpackRGBA())
    else
        control.label:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
    end
    ]]
    if control.dualListBox ~= nil then
        updateLibShifterBoxEnabledState(control, control.dualListBox, not disable)
    end
end


local function UpdateValue(control)
    if control.data.refreshFunc then
        control.data.refreshFunc(control)
    end
end


local function UpdateValues(control, isLeftList, newValues)
d("[LAM2 dualListBox widget]UpdateValues")
    local shifterBoxControl = control.dualListBox
    if not shifterBoxControl then return false end

    local newValuesTable = newValues ~= nil and getDefaultValue(newValues)

    --customControl, dualListBoxData, shifterBoxControl, isLeftList, newValues
    updateLibShifterBoxEntries(control, control.data, shifterBoxControl, isLeftList, newValuesTable)
    UpdateValue(control)
end


local function UpdateLeftListValues(control, values)
    UpdateValues(control, true, values)
end


local function UpdateRightListValues(control, values)
    UpdateValues(control, false, values)
end


------------------------------------------------------------------------------------------------------------------------
-- LibShifterBox - Event callback functions
local function assignLocalCallbackFunctionsToEventNames()
    --Set the local event callback function for each event Id, inside table myShifterBoxLocalEventFunctions
--[[
    --At date: 2022-04-19
    -->LibShifterBox possible event ID = event name constant (e.g. LibShifterBox.EVENT_ENTRY_HIGHLIGHTED
    -->See table LibShifterBox.allowedEventNames
    [1]  = "EVENT_ENTRY_HIGHLIGHTED",
    [2]  = "EVENT_ENTRY_UNHIGHLIGHTED",
    [3]  = "EVENT_ENTRY_MOVED",
    [4]  = "EVENT_LEFT_LIST_CLEARED",
    [5]  = "EVENT_RIGHT_LIST_CLEARED",
    [6]  = "EVENT_LEFT_LIST_ENTRY_ADDED",
    [7]  = "EVENT_RIGHT_LIST_ENTRY_ADDED",
    [8]  = "EVENT_LEFT_LIST_ENTRY_REMOVED",
    [9]  = "EVENT_RIGHT_LIST_ENTRY_REMOVED",
    [10] = "EVENT_LEFT_LIST_CREATED",
    [11] = "EVENT_RIGHT_LIST_CREATED",
    [12] = "EVENT_LEFT_LIST_ROW_ON_MOUSE_ENTER",
    [13] = "EVENT_RIGHT_LIST_ROW_ON_MOUSE_ENTER",
    [14] = "EVENT_LEFT_LIST_ROW_ON_MOUSE_EXIT",
    [15] = "EVENT_RIGHT_LIST_ROW_ON_MOUSE_EXIT",
    [16] = "EVENT_LEFT_LIST_ROW_ON_MOUSE_UP",
    [17] = "EVENT_RIGHT_LIST_ROW_ON_MOUSE_UP",
    [18] = "EVENT_LEFT_LIST_ROW_ON_DRAG_START",
    [19] = "EVENT_RIGHT_LIST_ROW_ON_DRAG_START",
    [20] = "EVENT_LEFT_LIST_ROW_ON_DRAG_END",
    [21] = "EVENT_RIGHT_LIST_ROW_ON_DRAG_END",
]]

    myShifterBoxLocalEventFunctions[LSB.EVENT_ENTRY_HIGHLIGHTED] = function(selectedRow, shifterBox, key, value, categoryId, isLeftList)
        local boxName, shifterBoxData = checkAndGetShifterBoxNameAndData(shifterBox)
        if not boxName or not shifterBoxData or not key then return end

    end

    myShifterBoxLocalEventFunctions[LSB.EVENT_ENTRY_UNHIGHLIGHTED] = function(selectedRow, shifterBox, key, value, categoryId, isLeftList)
        local boxName, shifterBoxData = checkAndGetShifterBoxNameAndData(shifterBox)
        if not boxName or not shifterBoxData or not key then return end

    end

    myShifterBoxLocalEventFunctions[LSB.EVENT_ENTRY_MOVED] = function(shifterBox, key, value, categoryId, isToListLeftList, fromList, toList)
        local boxName, shifterBoxData = checkAndGetShifterBoxNameAndData(shifterBox)
        if not boxName or not shifterBoxData then return end
    end

    myShifterBoxLocalEventFunctions[LSB.EVENT_LEFT_LIST_CLEARED] = function(shifterBox)
        local boxName, shifterBoxData = checkAndGetShifterBoxNameAndData(shifterBox)
        if not boxName or not shifterBoxData then return end
    end

    myShifterBoxLocalEventFunctions[LSB.EVENT_RIGHT_LIST_CLEARED] = function(shifterBox)
        local boxName, shifterBoxData = checkAndGetShifterBoxNameAndData(shifterBox)
        if not boxName or not shifterBoxData then return end
    end

    myShifterBoxLocalEventFunctions[LSB.EVENT_LEFT_LIST_ENTRY_ADDED] = function(shifterBox, list, entryAdded)
        local boxName, shifterBoxData = checkAndGetShifterBoxNameAndData(shifterBox)
        if not boxName or not shifterBoxData then return end
    end

    myShifterBoxLocalEventFunctions[LSB.EVENT_RIGHT_LIST_ENTRY_ADDED] = function(shifterBox, list, entryAdded)
        local boxName, shifterBoxData = checkAndGetShifterBoxNameAndData(shifterBox)
        if not boxName or not shifterBoxData then return end
    end

    myShifterBoxLocalEventFunctions[LSB.EVENT_LEFT_LIST_ENTRY_REMOVED] = function(shifterBox, list, entryRemoved)
        local boxName, shifterBoxData = checkAndGetShifterBoxNameAndData(shifterBox)
        if not boxName or not shifterBoxData then return end
    end

    myShifterBoxLocalEventFunctions[LSB.EVENT_RIGHT_LIST_ENTRY_REMOVED] = function(shifterBox, list, entryRemoved)
        local boxName, shifterBoxData = checkAndGetShifterBoxNameAndData(shifterBox)
        if not boxName or not shifterBoxData then return end
    end

    myShifterBoxLocalEventFunctions[LSB.EVENT_LEFT_LIST_CREATED] = function(leftListControl, shifterBox)
        local boxName, shifterBoxData = checkAndGetShifterBoxNameAndData(shifterBox)
        if not boxName or not shifterBoxData then return end
    end

    myShifterBoxLocalEventFunctions[LSB.EVENT_RIGHT_LIST_CREATED] = function(rightListControl, shifterBox)
        local boxName, shifterBoxData = checkAndGetShifterBoxNameAndData(shifterBox)
        if not boxName or not shifterBoxData then return end
    end

    myShifterBoxLocalEventFunctions[LSB.EVENT_LEFT_LIST_ROW_ON_MOUSE_ENTER] = function(rowControl, shifterBox, rawRowData)
        local boxName, shifterBoxData = checkAndGetShifterBoxNameAndData(shifterBox)
        if not boxName or not shifterBoxData then return end
    end

    myShifterBoxLocalEventFunctions[LSB.EVENT_RIGHT_LIST_ROW_ON_MOUSE_ENTER] = function(rowControl, shifterBox, rawRowData)
        local boxName, shifterBoxData = checkAndGetShifterBoxNameAndData(shifterBox)
        if not boxName or not shifterBoxData then return end
    end

    myShifterBoxLocalEventFunctions[LSB.EVENT_LEFT_LIST_ROW_ON_MOUSE_EXIT] = function(rowControl, shifterBox, rawRowData)
        local boxName, shifterBoxData = checkAndGetShifterBoxNameAndData(shifterBox)
        if not boxName or not shifterBoxData then return end
    end

    myShifterBoxLocalEventFunctions[LSB.EVENT_RIGHT_LIST_ROW_ON_MOUSE_EXIT] = function(rowControl, shifterBox, rawRowData)
        local boxName, shifterBoxData = checkAndGetShifterBoxNameAndData(shifterBox)
        if not boxName or not shifterBoxData then return end
    end

    myShifterBoxLocalEventFunctions[LSB.EVENT_LEFT_LIST_ROW_ON_MOUSE_UP] = function(rowControl, shifterBox, mouseButton, isInside, altKey, shiftKey, commandKey, rawRowData)
        local boxName, shifterBoxData = checkAndGetShifterBoxNameAndData(shifterBox)
        if not boxName or not shifterBoxData then return end
    end

    myShifterBoxLocalEventFunctions[LSB.EVENT_RIGHT_LIST_ROW_ON_MOUSE_UP] = function(rowControl, shifterBox, mouseButton, isInside, altKey, shiftKey, commandKey, rawRowData)
        local boxName, shifterBoxData = checkAndGetShifterBoxNameAndData(shifterBox)
        if not boxName or not shifterBoxData then return end
    end

    myShifterBoxLocalEventFunctions[LSB.EVENT_LEFT_LIST_ROW_ON_DRAG_START] = function(draggedControl, shifterBox, mouseButton, rawDraggedRowData)
        local boxName, shifterBoxData = checkAndGetShifterBoxNameAndData(shifterBox)
        if not boxName or not shifterBoxData then return end
    end

    myShifterBoxLocalEventFunctions[LSB.EVENT_RIGHT_LIST_ROW_ON_DRAG_START] = function(draggedControl, shifterBox, mouseButton, rawDraggedRowData)
        local boxName, shifterBoxData = checkAndGetShifterBoxNameAndData(shifterBox)
        if not boxName or not shifterBoxData then return end
    end

    myShifterBoxLocalEventFunctions[LSB.EVENT_LEFT_LIST_ROW_ON_DRAG_END] = function(draggedOnToControl, shifterBox, mouseButton, rawDraggedRowData, hasSameShifterBoxParent, wasDragSuccessful)
        local boxName, shifterBoxData = checkAndGetShifterBoxNameAndData(shifterBox)
        if not boxName or not shifterBoxData then return end
    end

    myShifterBoxLocalEventFunctions[LSB.EVENT_RIGHT_LIST_ROW_ON_DRAG_END] = function(draggedOnToControl, shifterBox, mouseButton, rawDraggedRowData, hasSameShifterBoxParent, wasDragSuccessful)
        local boxName, shifterBoxData = checkAndGetShifterBoxNameAndData(shifterBox)
        if not boxName or not shifterBoxData then return end
    end
end


local function updateLibShifterBoxEventCallbacks(customControl, dualListBoxData, shifterBoxControl, alreadyChecked)
    alreadyChecked = alreadyChecked or false
    local shifterBoxSetupData = dualListBoxData.setupData
    if alreadyChecked == false and not checkShifterBoxValid(customControl, shifterBoxSetupData, false) then return end

    --Add the callback functions, if provided
    local customSettings = shifterBoxSetupData.customSettings
    if not customSettings then return end

    local callbackRegister = customSettings.callbackRegister
    if callbackRegister ~= nil then
        shifterBoxControl.LAMduallistBox_EventCallbacks = {}
        local LAMduallistBox_EventCallbacks = shifterBoxControl.LAMduallistBox_EventCallbacks

        --Dynamic
        --Enable the callback functions if they are added to the customSettings of the LibShifterBox
        for eventId, eventName in ipairs(libShifterBoxPossibleEventNames) do
            if callbackRegister[eventId] ~= nil then
                local callbackFuncForEventName = myShifterBoxLocalEventFunctions[eventId]
                if callbackFuncForEventName ~= nil then
                    shifterBoxControl:RegisterCallback(eventId, callbackFuncForEventName)
                    --Better readability at the control
                    LAMduallistBox_EventCallbacks[eventId] = {
                        eventId =   eventId,
                        eventName = eventName,
                        callback =  callbackFuncForEventName
                    }
                end
            end
        end
    end
end


------------------------------------------------------------------------------------------------------------------------

local function updateLibShifterBoxState(customControl, dualListBoxData, shifterBoxControl, alreadyChecked)
    alreadyChecked = alreadyChecked or false
    local shifterBoxSetupData = dualListBoxData.setupData
    if alreadyChecked == false and not checkShifterBoxValid(customControl, shifterBoxSetupData, false) then return end

    local boxName = shifterBoxSetupData.name
    local shifterBoxData = libShifterBoxes[boxName]
    shifterBoxSetupData = shifterBoxSetupData or shifterBoxData.shifterBoxSetupData
    if not shifterBoxSetupData then return end
    shifterBoxControl = shifterBoxControl or shifterBoxData.shifterBoxControl
    if not shifterBoxControl then return end

    local isEnabled = shifterBoxSetupData.enabled ~= nil and getDefaultValue(shifterBoxSetupData.enabled)
    if isEnabled == nil then isEnabled = true end

    updateLibShifterBoxEnabledState(customControl, shifterBoxControl, isEnabled)
end


local function updateLibShifterBox(customControl, dualListBoxData, shifterBoxControl)
    local shifterBoxSetupData = dualListBoxData.setupData
    if not checkShifterBoxValid(customControl, shifterBoxSetupData, false) then return end

    local boxName = shifterBoxSetupData.name
    local shifterBoxData = libShifterBoxes[boxName]
    shifterBoxSetupData = shifterBoxSetupData or shifterBoxData.shifterBoxSetupData
    if not shifterBoxSetupData then return end
    shifterBoxControl = shifterBoxControl or shifterBoxData.shifterBoxControl
    if not shifterBoxControl then return end

    --Tell the custom control to auto-resize dependent on the dual list boxes size
    customControl:SetResizeToFitDescendents(true)
    --Re-Anchor to the custom control
    shifterBoxControl:SetAnchor(TOPLEFT, customControl, TOPLEFT, 0, 0) -- will automatically call ClearAnchors
    --Change the dimensions
    local width = shifterBoxSetupData.width ~= nil and getDefaultValue(shifterBoxSetupData.width)
    local newWidth = zocl(width, MIN_WIDTH, MAX_WIDTH - 1)

    local height =    (shifterBoxSetupData.height ~= nil    and getDefaultValue(shifterBoxSetupData.height)) or MIN_HEIGHT
    local minHeight = (dualListBoxData.minHeight ~= nil and getDefaultValue(dualListBoxData.minHeight)) or MIN_HEIGHT
    local maxHeight = (dualListBoxData.maxHeight ~= nil and getDefaultValue(dualListBoxData.maxHeight)) or (minHeight * 4)
    local newHeight = zocl(height, minHeight, maxHeight)
    shifterBoxControl:SetDimensions(newWidth, newHeight)


    --Add the entries to the left and right shifter boxes
    -->Currently not needed. Use shifterBoxSetupData.leftListDefaultKeys and shifterBoxSetupData.rightListDefaultKeys
    --updateLibShifterBoxEntries(customControl, shifterBoxSetupData, shifterBoxControl)

    --Upate the EVENT callback functions of the shifter box
    updateLibShifterBoxEventCallbacks(customControl, dualListBoxData, shifterBoxControl, true)

    --Update the enabled state of the shifter box
    --updateLibShifterBoxState(customControl, dualListBoxData, shifterBoxControl, true)
end

------------------------------------------------------------------------------------------------------------------------

--Create a LibShifterBox for e.g. LAM settings panel
local function createLibShifterBox(customControl, dualListBoxData)
    local shifterBoxSetupData = dualListBoxData.setupData
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
    local shifterBox = LSB(widgetName,                  --uniqueAddonName
            boxName,                                    --uniqueShifterBoxName
            customControl,                              --parentControl
            shifterBoxSetupData.customSettings,         --customSettings
            nil,                                        --dimensionOptions
            nil,                                        --anchorOptions
            shifterBoxSetupData.leftListDefaultKeys,    --leftListEntries
            shifterBoxSetupData.rightListDefaultKeys    --rightListEntries
    )
    if shifterBox ~= nil then
        shifterBox.boxName = boxName

        libShifterBoxes[boxName] = {}
        libShifterBoxes[boxName].name =                 boxName
        libShifterBoxes[boxName].dualListBoxData =      dualListBoxData
        libShifterBoxes[boxName].shifterBoxSetupData =  shifterBoxSetupData
        libShifterBoxes[boxName].lamCustomControl =     customControl
        libShifterBoxes[boxName].shifterBoxControl =    shifterBox

        --Update the shifter box position, entries, state
        updateLibShifterBox(customControl, dualListBoxData, shifterBox)

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
    return createLibShifterBox(customControl, dualListBoxData)
end


function LAMCreateControl.duallistbox(parent, dualListBoxData, controlName)
    if dualListBoxData.setupData == nil then return end
    dualListBoxData.disabled = dualListBoxData.disabled or false

    local control = LAM.util.CreateBaseControl(parent, dualListBoxData, controlName)
    local width = control:GetWidth()
    control:SetResizeToFitDescendents(true)

    local data = control.data
    local minHeight = (data.minHeight and getDefaultValue(data.minHeight)) or MIN_HEIGHT
    local maxHeight = (data.maxHeight and getDefaultValue(data.maxHeight)) or (minHeight * 4)

    if control.isHalfWidth then --note these restrictions
        control:SetDimensionConstraints(width / 2, minHeight, width / 2, maxHeight)
    else
        control:SetDimensionConstraints(width, minHeight, width, maxHeight)
    end
    MAX_WIDTH = control:GetWidth()

    --Create the LibShifterBox dual list boxes (left and right)
    local dualListBoxControl = createFunc(parent, control, dualListBoxData)
    if dualListBoxControl == nil then
        d(strfor(errorPrefix.." - Widget %q did not create the dual list boxes for control %q", tos(widgetName), tos(control:GetName())))
        return
    end
    control.dualListBox = dualListBoxControl
    control.dualListBox.dualListBoxData = dualListBoxData

    LAM.util.RegisterForRefreshIfNeeded(control)

    --Get functions
    control.GetLeftListEntries = getLeftListEntriesFull
    control.GetRightListEntries = getRightListEntriesFull

    --Set functions
    --Only for the refresh
    control.UpdateValue = UpdateValue

    --Left list/right list entries handling
    control.UpdateLeftListValues =  UpdateLeftListValues
    control.UpdateRightListValues = UpdateRightListValues

    --Disabled state handling
    control.UpdateDisabled =        UpdateDisabled
    control:UpdateDisabled()

    return control --the LAM custom control containing the .dualListBox subTable/control
end


--Load the widget into LAM
local eventAddOnLoadedForWidgetName = widgetName .. "_EVENT_ADD_ON_LOADED"
local function registerWidget(_, addonName)
    if addonName ~= widgetName then return end
    em:UnregisterForEvent(eventAddOnLoadedForWidgetName, EVENT_ADD_ON_LOADED)

    --LibShifterBox
    LSB = LibShifterBox
    if not LSB then return end

    --Update the LibShifterBox EVENT_* callback names which are possible with their ID number (lookup table)
    libShifterBoxPossibleEventNames = LSB.allowedEventNames
    for eventId, eventName in ipairs(libShifterBoxPossibleEventNames) do
        libShifterBoxEventNameToId[eventName] = eventId
    end
    --Assign the local callback functions to the eventNames, inside table myShifterBoxLocalEventFunctions
    assignLocalCallbackFunctionsToEventNames()

    if not LAM:RegisterWidget("duallistbox", widgetVersion) then return end
end
em:RegisterForEvent(eventAddOnLoadedForWidgetName, EVENT_ADD_ON_LOADED, registerWidget)
