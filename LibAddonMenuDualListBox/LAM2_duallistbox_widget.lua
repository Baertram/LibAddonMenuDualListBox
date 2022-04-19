--[[dualListBoxData = {
    type = "duallistbox",
    reference = "MyAddonCustomControl", -- unique name for your control to use as reference (optional) The <reference>.dualListBox is the direct reference to the dual list box control then
    refreshFunc = function(customControl) end, -- function to call when panel/controls refresh (optional)
    width = "full", -- or "half" (optional)
    minHeight = function() return db.minHeightNumber end, --or number for the minimum height of this control. Default: 26 (optional)
    maxHeight = function() return db.maxHeightNumber end, --or number for the maximum height of this control. Default: 4 * minHeight (optional)
--======================================================================================================================
    -- -v- The dual lists setup data                                                                                -v-
--======================================================================================================================
    setupData = {
        --The overall dual list box control setup data
        name = "LAM_DUALLISTBOX_EXAMPLE1",
        width       = 580, --number of function returning a number for the width of both list boxes together
        height      = 200, --number of function returning a number for the height of both list boxes together. minHeight of the LAM control needs to be >= this value!

--======================================================================================================================
    ----  -v- The custom settings for the dual lists                                                            -v-
--======================================================================================================================
        --The setup data for the lists
        -->The custom settings are defined via the library LibShifterBox. You can find the documentation here:
        -->https://github.com/klingo/ESO-LibShifterBox#api-reference    Search for "customSettings"
        customSettings = {
            enabled = true,             -- boolean value or function returning a boolean to tell if the dual list box widget is enabled (default = true)? (optional)
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
                rowDataTypeSelectSound = SOUNDS.ABILITY_SLOTTED,    -- an optional sound to play when a row of this data type is selected (default = SOUNDS.ABILITY_SLOTTED). (optional)
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

local function getLeftListEntriesFull(shifterBox)
    if not shifterBox then return end
    return shifterBox:GetLeftListEntriesFull()
end

local function getRightListEntriesFull(shifterBox)
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


------------------------------------------------------------------------------------------------------------------------
-- LibShifterBox - Event callback functions

local function myShifterBoxEventEntryMovedCallbackFunction(shifterBox, key, value, categoryId, isDestListLeftList)
    if not shifterBox or not key then return end
    local boxName = getBoxName(shifterBox)
    if not boxName or boxName == "" then return end
    local shifterBoxData = libShifterBoxes[boxName]

    --Moved to the left
    if isDestListLeftList == true then
        local rightListEntries = shifterBox:GetRightListEntriesFull()
        checkAndUpdateRightListDefaultEntries(shifterBox, rightListEntries, shifterBoxData)

    else
        --Moved to the right? Save to SavedVariables with value true
    end
end

local function myShifterBoxEventLeftListCreatedCallbackFunction(leftListControl, shifterBox)
end

local function myShifterBoxEventRightListCreatedCallbackFunction(rightListControl, shifterBox)
end

local function myShifterBoxEventLeftListClearedCallbackFunction(shifterBox)
end

local function myShifterBoxEventRightListClearedCallbackFunction(shifterBox)
end

local function myShifterBoxEventLeftListEntryAddedCallbackFunction(shifterBox, list, entryAdded)
end

local function myShifterBoxEventRightListEntryAddedCallbackFunction(shifterBox, list, entryAdded)
end

local function myShifterBoxEventLeftListEntryCallbackRemovedFunction(shifterBox, list, entryRemoved)
end

local function myShifterBoxEventRightListEntryCallbackRemovedFunction(shifterBox, list, entryRemoved)
end

local function myShifterBoxEventLeftListRowMouseEnterCallbackFunction(rowControl, shifterBox, rawRowData)
end

local function myShifterBoxEventRightListRowMouseEnterCallbackFunction(rowControl, shifterBox, rawRowData)
end

local function myShifterBoxEventLeftListRowMouseExitCallbackFunction(rowControl, shifterBox, rawRowData)
end

local function myShifterBoxEventRightListRowMouseExitCallbackFunction(rowControl, shifterBox, rawRowData)
end

local function myShifterBoxEventLeftListRowMouseUpCallbackFunction(rowControl, shifterBox, mouseButton, isInside, altKey, shiftKey, commandKey, rawRowData)
end

local function myShifterBoxEventRightListRowMouseUpCallbackFunction(rowControl, shifterBox, mouseButton, isInside, altKey, shiftKey, commandKey, rawRowData)
end

local function myShifterBoxEventLeftListRowDragStartCallbackFunction(draggedControl, shifterBox, mouseButton, rawDraggedRowData)
end

local function myShifterBoxEventRightListRowDragStartCallbackFunction(draggedControl, shifterBox, mouseButton, rawDraggedRowData)
end

local function myShifterBoxEventLeftListRowDragEndCallbackFunction(draggedOnToControl, shifterBox, mouseButton, rawDraggedRowData, hasSameShifterBoxParent, wasDragSuccessful)
end

local function myShifterBoxEventRightListRowDragEndCallbackFunction(draggedOnToControl, shifterBox, mouseButton, rawDraggedRowData, hasSameShifterBoxParent, wasDragSuccessful)
end


------------------------------------------------------------------------------------------------------------------------
local function updateLibShifterBoxEntries(customControl, dualListBoxData, shifterBoxControl)
    local shifterBoxSetupData = dualListBoxData.setupData
    if not checkShifterBoxValid(customControl, shifterBoxSetupData, false) then return end

    local boxName = shifterBoxSetupData.name
    local shifterBoxData = libShifterBoxes[boxName]
    shifterBoxSetupData = shifterBoxSetupData or shifterBoxData.shifterBoxSetupData
    if not shifterBoxSetupData then return end
    shifterBoxControl = shifterBoxControl or shifterBoxData.shifterBoxControl
    if not shifterBoxControl then return end

    --Use default left list entries or nothing provided?
    if shifterBoxSetupData.leftListDefaultKeys == nil then
        --todo We need a function here that provides the leftList entries?
        -->simply use shifterBoxSetupData.leftListDefaultKeys!
        local leftListEntries = {}

        shifterBoxControl:ClearLeftList()
        shifterBoxControl:AddEntriesToLeftList(leftListEntries)
    end

    if shifterBoxSetupData.rightListDefaultKeys == nil then
        --todo We need a function here that provides the rightList entries?
        -->simply use shifterBoxSetupData.rightListDefaultKeys!
        local rightListEntries = {}

        shifterBoxControl:ClearRightList()
        shifterBoxControl:AddEntriesToRightList(rightListEntries)
    end

    --Check for empty right list? fill up with default values again
    --checkAndUpdateRightListDefaultEntries(shifterBoxControl, rightListEntries, shifterBoxData)
end


local function updateLibShifterBoxState(customControl, dualListBoxData, shifterBoxControl)
    local shifterBoxSetupData = dualListBoxData.setupData
    if not checkShifterBoxValid(customControl, shifterBoxSetupData, false) then return end

    local boxName = shifterBoxSetupData.name
    local shifterBoxData = libShifterBoxes[boxName]
    shifterBoxSetupData = shifterBoxSetupData or shifterBoxData.shifterBoxSetupData
    if not shifterBoxSetupData then return end
    shifterBoxControl = shifterBoxControl or shifterBoxData.shifterBoxControl
    if not shifterBoxControl then return end

    local isEnabled = shifterBoxSetupData.enabled ~= nil and getDefaultValue(shifterBoxSetupData.enabled)
    if isEnabled == nil then isEnabled = true end

    customControl:SetHidden(false)
    customControl:SetMouseEnabled(isEnabled)
    shifterBoxControl:SetHidden(false)
    shifterBoxControl:SetEnabled(isEnabled)
end

local function myShifterBoxEventEntryHighlightedCallbackFunction(selectedRow, shifterBox, key, value, categoryId, isLeftList)
    if not shifterBox or not key then return end
    local boxName = getBoxName(shifterBox)
--df("LSB FCOIS, boxName: %s, key: %s, value: %s", tostring(boxName), tostring(key), tostring(value))
    if not boxName or boxName == "" then return end

    --todo
end

local function myShifterBoxEventEntryUnHighlightedCallbackFunction(selectedRow, shifterBox, key, value, categoryId, isLeftList)
    if not shifterBox or not key then return end
    local boxName = getBoxName(shifterBox)
--d("LSB FCOIS, boxName: " ..tostring(boxName))
    if not boxName or boxName == "" then return end

    --todo
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
    local height = shifterBoxSetupData.height ~= nil and getDefaultValue(shifterBoxSetupData.height)
    height = zo_clamp(shifterBoxSetupData.minHeight, shifterBoxSetupData.maxHeigth)
    shifterBoxControl:SetDimensions(width, height)



    --Add the entries to the left and right shifter boxes
    -->Currently not needed. Use shifterBoxSetupData.leftListDefaultKeys and shifterBoxSetupData.rightListDefaultKeys
    --updateLibShifterBoxEntries(customControl, shifterBoxSetupData, shifterBoxControl)

    --Update the enabled state of the shifter box
    updateLibShifterBoxState(customControl, shifterBoxSetupData, shifterBoxControl)


    --Add the callback functions, if provided
    local customSettings = shifterBoxSetupData.customSettings
    local callbackRegister = customSettings.callbackRegister
    shifterBoxControl.LAMduallistBox_EventCallbacks = {}
    local LAMduallistBox_EventCallbacks = shifterBoxControl.LAMduallistBox_EventCallbacks
    if callbackRegister ~= nil then
        --Add the callback as he left list was created
        if callbackRegister.EVENT_LEFT_LIST_CREATED then
            shifterBoxControl:RegisterCallback(LSB.EVENT_LEFT_LIST_CREATED,             myShifterBoxEventLeftListCreatedCallbackFunction)
            LAMduallistBox_EventCallbacks[LSB.EVENT_LEFT_LIST_CREATED] =                myShifterBoxEventLeftListCreatedCallbackFunction
        end

        --Add the callback as he left list was created
        if callbackRegister.EVENT_RIGHT_LIST_CREATED then
            shifterBoxControl:RegisterCallback(LSB.EVENT_RIGHT_LIST_CREATED,            myShifterBoxEventRightListCreatedCallbackFunction)
            LAMduallistBox_EventCallbacks[LSB.EVENT_RIGHT_LIST_CREATED] =               myShifterBoxEventRightListCreatedCallbackFunction
        end

        --Add the callback as an entry was moved
        if callbackRegister.EVENT_ENTRY_MOVED then
            shifterBoxControl:RegisterCallback(LSB.EVENT_ENTRY_MOVED,                   myShifterBoxEventEntryMovedCallbackFunction)
            LAMduallistBox_EventCallbacks[LSB.EVENT_ENTRY_MOVED] =                      myShifterBoxEventEntryMovedCallbackFunction
        end

        --Add the callback as an entry was highlighted at the left side
        if callbackRegister.EVENT_ENTRY_HIGHLIGHTED then
            shifterBoxControl:RegisterCallback(LSB.EVENT_ENTRY_HIGHLIGHTED,             myShifterBoxEventEntryHighlightedCallbackFunction)
            LAMduallistBox_EventCallbacks[LSB.EVENT_ENTRY_HIGHLIGHTED] =                myShifterBoxEventEntryHighlightedCallbackFunction
        end

        --Add the callback as an entry was unhighlighted again at the left side
        if callbackRegister.EVENT_ENTRY_UNHIGHLIGHTED then
            shifterBoxControl:RegisterCallback(LSB.EVENT_ENTRY_UNHIGHLIGHTED,           myShifterBoxEventEntryUnHighlightedCallbackFunction)
            LAMduallistBox_EventCallbacks[LSB.EVENT_ENTRY_UNHIGHLIGHTED] =              myShifterBoxEventEntryUnHighlightedCallbackFunction
        end

        --Add the callback as the left list was cleared
        if callbackRegister.EVENT_LEFT_LIST_CLEARED then
            shifterBoxControl:RegisterCallback(LSB.EVENT_LEFT_LIST_CLEARED,             myShifterBoxEventLeftListClearedCallbackFunction)
            LAMduallistBox_EventCallbacks[LSB.EVENT_LEFT_LIST_CLEARED] =                myShifterBoxEventLeftListClearedCallbackFunction
        end

        --Add the callback as the right list was cleared
        if callbackRegister.EVENT_RIGHT_LIST_CLEARED then
            shifterBoxControl:RegisterCallback(LSB.EVENT_RIGHT_LIST_CLEARED,            myShifterBoxEventRightListClearedCallbackFunction)
            LAMduallistBox_EventCallbacks[LSB.EVENT_RIGHT_LIST_CLEARED] =               myShifterBoxEventRightListClearedCallbackFunction
        end

        --Add the callback as the left list got a new added entry
        if callbackRegister.EVENT_LEFT_LIST_ENTRY_ADDED then
            shifterBoxControl:RegisterCallback(LSB.EVENT_LEFT_LIST_ENTRY_ADDED,         myShifterBoxEventLeftListEntryAddedCallbackFunction)
            LAMduallistBox_EventCallbacks[LSB.EVENT_LEFT_LIST_ENTRY_ADDED] =            myShifterBoxEventLeftListEntryAddedCallbackFunction
        end

        --Add the callback as the left list got a new added entry
        if callbackRegister.EVENT_RIGHT_LIST_ENTRY_ADDED then
            shifterBoxControl:RegisterCallback(LSB.EVENT_RIGHT_LIST_ENTRY_ADDED,        myShifterBoxEventRightListEntryAddedCallbackFunction)
            LAMduallistBox_EventCallbacks[LSB.EVENT_LEFT_LIST_ENTRY_ADDED] =            myShifterBoxEventRightListEntryAddedCallbackFunction
        end

        --Add the callback as the left list got a new added entry
        if callbackRegister.EVENT_LEFT_LIST_ENTRY_REMOVED then
            shifterBoxControl:RegisterCallback(LSB.EVENT_LEFT_LIST_ENTRY_REMOVED,       myShifterBoxEventLeftListEntryCallbackRemovedFunction)
            LAMduallistBox_EventCallbacks[LSB.EVENT_LEFT_LIST_ENTRY_REMOVED] =          myShifterBoxEventLeftListEntryCallbackRemovedFunction
        end

        --Add the callback as the left list got a new added entry
        if callbackRegister.EVENT_RIGHT_LIST_ENTRY_REMOVED then
            shifterBoxControl:RegisterCallback(LSB.EVENT_RIGHT_LIST_ENTRY_REMOVED,      myShifterBoxEventRightListEntryCallbackRemovedFunction)
            LAMduallistBox_EventCallbacks[LSB.EVENT_RIGHT_LIST_ENTRY_REMOVED] =         myShifterBoxEventRightListEntryCallbackRemovedFunction
        end


        --Add the callback as the left row's OnMouseEnter fires
        if callbackRegister.EVENT_LEFT_LIST_ROW_ON_MOUSE_ENTER then
            shifterBoxControl:RegisterCallback(LSB.EVENT_LEFT_LIST_ROW_ON_MOUSE_ENTER,  myShifterBoxEventLeftListRowMouseEnterCallbackFunction)
            LAMduallistBox_EventCallbacks[LSB.EVENT_LEFT_LIST_ROW_ON_MOUSE_ENTER] =     myShifterBoxEventLeftListRowMouseEnterCallbackFunction
        end

        --Add the callback as the right row's OnMouseEnter fires
        if callbackRegister.EVENT_RIGHT_LIST_ROW_ON_MOUSE_ENTER then
            shifterBoxControl:RegisterCallback(LSB.EVENT_RIGHT_LIST_ROW_ON_MOUSE_ENTER, myShifterBoxEventRightListRowMouseEnterCallbackFunction)
            LAMduallistBox_EventCallbacks[LSB.EVENT_RIGHT_LIST_ROW_ON_MOUSE_ENTER] =    myShifterBoxEventRightListRowMouseEnterCallbackFunction
        end

        --Add the callback as the left row's OnMouseExit fires
        if callbackRegister.EVENT_LEFT_LIST_ROW_ON_MOUSE_EXIT then
            shifterBoxControl:RegisterCallback(LSB.EVENT_LEFT_LIST_ROW_ON_MOUSE_EXIT,   myShifterBoxEventLeftListRowMouseExitCallbackFunction)
            LAMduallistBox_EventCallbacks[LSB.EVENT_LEFT_LIST_ROW_ON_MOUSE_EXIT] =      myShifterBoxEventLeftListRowMouseExitCallbackFunction
        end

        --Add the callback as the right row's OnMouseExit fires
        if callbackRegister.EVENT_RIGHT_LIST_ROW_ON_MOUSE_EXIT then
            shifterBoxControl:RegisterCallback(LSB.EVENT_RIGHT_LIST_ROW_ON_MOUSE_EXIT,  myShifterBoxEventRightListRowMouseExitCallbackFunction)
            LAMduallistBox_EventCallbacks[LSB.EVENT_RIGHT_LIST_ROW_ON_MOUSE_EXIT] =     myShifterBoxEventRightListRowMouseExitCallbackFunction
        end

        --Add the callback as the left row's OnMouseUp fires
        if callbackRegister.EVENT_LEFT_LIST_ROW_ON_MOUSE_UP then
            shifterBoxControl:RegisterCallback(LSB.EVENT_LEFT_LIST_ROW_ON_MOUSE_UP,     myShifterBoxEventLeftListRowMouseUpCallbackFunction)
            LAMduallistBox_EventCallbacks[LSB.EVENT_LEFT_LIST_ROW_ON_MOUSE_UP] =        myShifterBoxEventLeftListRowMouseUpCallbackFunction
        end

        --Add the callback as the rightrow's OnMouseUp fires
        if callbackRegister.EVENT_RIGHT_LIST_ROW_ON_MOUSE_UP then
            shifterBoxControl:RegisterCallback(LSB.EVENT_RIGHT_LIST_ROW_ON_MOUSE_UP,    myShifterBoxEventRightListRowMouseUpCallbackFunction)
            LAMduallistBox_EventCallbacks[LSB.EVENT_RIGHT_LIST_ROW_ON_MOUSE_UP] =       myShifterBoxEventRightListRowMouseUpCallbackFunction
        end

        --Add the callback as the left row's OnDragStart fires
        if callbackRegister.EVENT_LEFT_LIST_ROW_ON_DRAG_START then
            shifterBoxControl:RegisterCallback(LSB.EVENT_LEFT_LIST_ROW_ON_DRAG_START,   myShifterBoxEventLeftListRowDragStartCallbackFunction)
            LAMduallistBox_EventCallbacks[LSB.EVENT_LEFT_LIST_ROW_ON_DRAG_START] =      myShifterBoxEventLeftListRowDragStartCallbackFunction
        end

        --Add the callback as the right row's OnDragStart fires
        if callbackRegister.EVENT_RIGHT_LIST_ROW_ON_DRAG_START then
            shifterBoxControl:RegisterCallback(LSB.EVENT_LEFT_LIST_ROW_ON_DRAG_START,   myShifterBoxEventRightListRowDragStartCallbackFunction)
            LAMduallistBox_EventCallbacks[LSB.EVENT_LEFT_LIST_ROW_ON_DRAG_START] =      myShifterBoxEventRightListRowDragStartCallbackFunction
        end

        --Add the callback as the left row's OnDragEnd fires
        if callbackRegister.EVENT_LEFT_LIST_ROW_ON_DRAG_END then
            shifterBoxControl:RegisterCallback(LSB.EVENT_LEFT_LIST_ROW_ON_DRAG_END,     myShifterBoxEventLeftListRowDragEndCallbackFunction)
            LAMduallistBox_EventCallbacks[LSB.EVENT_LEFT_LIST_ROW_ON_DRAG_END] =        myShifterBoxEventLeftListRowDragEndCallbackFunction
        end

        --Add the callback as the right row's OnDragEnd fires
        if callbackRegister.EVENT_RIGHT_LIST_ROW_ON_DRAG_END then
            shifterBoxControl:RegisterCallback(LSB.EVENT_RIGHT_LIST_ROW_ON_DRAG_END,    myShifterBoxEventRightListRowDragEndCallbackFunction)
            LAMduallistBox_EventCallbacks[LSB.EVENT_RIGHT_LIST_ROW_ON_DRAG_END] =       myShifterBoxEventRightListRowDragEndCallbackFunction
        end
    end
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
