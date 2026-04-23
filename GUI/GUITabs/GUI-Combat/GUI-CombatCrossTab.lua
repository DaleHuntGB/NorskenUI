---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme
local ipairs = ipairs
local table_insert = table.insert

GUIFrame:RegisterContent("combatCross", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.CombatCross
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type CombatCross?
    local CC = NorskenUI and NorskenUI:GetModule("CombatCross", true)
    local manager = GUIFrame:CreateWidgetStateManager()
    local colorModeWidgets = {}
    local rangeColorWidgets = {}
    local postUpdateCallbacks = {}

    local function UpdateAllWidgetStates()
        local mainEnabled = db.Enabled ~= false
        manager:UpdateAll(mainEnabled)
        if mainEnabled then
            local isCustomColor = db.ColorMode == "custom"
            local isRangeEnabled = db.RangeColorMeleeEnabled or db.RangeColorRangedEnabled
            for _, widget in ipairs(colorModeWidgets) do
                if widget.SetEnabled then widget:SetEnabled(isCustomColor) end
            end
            for _, widget in ipairs(rangeColorWidgets) do
                if widget.SetEnabled then widget:SetEnabled(isRangeEnabled) end
            end
            for _, callback in ipairs(postUpdateCallbacks) do
                callback()
            end
        end
    end

    -- Card 1
    local card1 = GUIFrame:CreateCard(scrollChild, "Combat Cross", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Combat Cross", {
        value = db.Enabled ~= false,
        callback = function(checked)
            db.Enabled = checked
            if CC then
                CC.db.Enabled = checked
                if checked then NorskenUI:EnableModule("CombatCross") else NorskenUI:DisableModule("CombatCross") end
            end
            UpdateAllWidgetStates()
        end,
        msgPopup = true,
        msgText = "Combat Cross",
        msgOn = "On",
        msgOff = "Off"
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, Theme.rowHeightLast, 0)
    yOffset = card1:GetNextOffset()

    -- Card 2
    local card2, newOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        db = db,
        showAnchorFrameType = false,
        showStrata = true,
        onChangeCallback = function() if CC then CC:ApplySettings() end end,
    })
    if card2.positionWidgets then manager:RegisterGroup(card2.positionWidgets, "all") end
    manager:Register(card2, "all")
    yOffset = newOffset

    -- Card 3
    local card3 = GUIFrame:CreateCard(scrollChild, "Cross Size", yOffset)
    manager:Register(card3, "all")

    local row3a = GUIFrame:CreateRow(card3.content, Theme.rowHeight)
    local outlineCheck = GUIFrame:CreateCheckbox(row3a, "Font Outline", {
        value = db.Outline ~= false,
        callback = function(checked)
            db.Outline = checked
            if CC then CC:ApplySettings() end
        end
    })
    row3a:AddWidget(outlineCheck, 0.5)
    manager:Register(outlineCheck, "all")

    local sizeSlider = GUIFrame:CreateSlider(row3a, "Size", {
        min = 8,
        max = 72,
        step = 1,
        value = db.Thickness,
        labelWidth = 60,
        callback = function(val)
            db.Thickness = val
            if CC then CC:ApplySettings() end
        end
    })
    row3a:AddWidget(sizeSlider, 0.5)
    manager:Register(sizeSlider, "all")
    card3:AddRow(row3a, Theme.rowHeightLast, 0)
    yOffset = card3:GetNextOffset()

    -- Card 4
    local card4 = GUIFrame:CreateCard(scrollChild, "Color", yOffset)
    manager:Register(card4, "all")

    local row4a = GUIFrame:CreateRow(card4.content, Theme.rowHeight)
    local colorModeDropdown = GUIFrame:CreateDropdown(row4a, "Color Mode", {
        options = NRSKNUI.ColorModeOptions,
        value = db.ColorMode,
        callback = function(key)
            db.ColorMode = key
            if CC then CC:ApplySettings() end
            UpdateAllWidgetStates()
        end
    })
    row4a:AddWidget(colorModeDropdown, 0.5)
    manager:Register(colorModeDropdown, "all")

    local colorPicker = GUIFrame:CreateColorPicker(row4a, "Custom Color", {
        color = db.Color,
        callback = function(r, g, b, a)
            db.Color = { r, g, b, a }
            if CC then CC:ApplySettings() end
        end
    })
    row4a:AddWidget(colorPicker, 0.5)
    manager:Register(colorPicker, "all")
    table_insert(colorModeWidgets, colorPicker)
    card4:AddRow(row4a, Theme.rowHeightLast, 0)
    yOffset = card4:GetNextOffset()

    -- Card 5
    local card5 = GUIFrame:CreateCard(scrollChild, "Range Warning", yOffset)
    manager:Register(card5, "all")

    local row5a = GUIFrame:CreateRow(card5.content, Theme.rowHeight)
    local meleeRangeCheck = GUIFrame:CreateCheckbox(row5a, "Enable for melee specs", {
        value = db.RangeColorMeleeEnabled == true,
        callback = function(checked)
            db.RangeColorMeleeEnabled = checked
            if CC then CC:ApplySettings() end
            UpdateAllWidgetStates()
        end
    })
    row5a:AddWidget(meleeRangeCheck, 0.5)
    manager:Register(meleeRangeCheck, "all")

    local rangedRangeCheck = GUIFrame:CreateCheckbox(row5a, "Enable for ranged specs", {
        value = db.RangeColorRangedEnabled == true,
        callback = function(checked)
            db.RangeColorRangedEnabled = checked
            if CC then CC:ApplySettings() end
            UpdateAllWidgetStates()
        end
    })
    row5a:AddWidget(rangedRangeCheck, 0.5)
    manager:Register(rangedRangeCheck, "all")
    card5:AddRow(row5a, Theme.rowHeight)

    local row5b = GUIFrame:CreateRow(card5.content, Theme.rowHeightLast)
    local outOfRangeColorPicker = GUIFrame:CreateColorPicker(row5b, "Out of Range Color", {
        color = db.OutOfRangeColor,
        callback = function(r, g, b, a)
            db.OutOfRangeColor = { r, g, b, a }
            if CC then CC.lastInRange = nil end
        end
    })
    row5b:AddWidget(outOfRangeColorPicker, 1)
    manager:Register(outOfRangeColorPicker, "all")
    table_insert(rangeColorWidgets, outOfRangeColorPicker)
    card5:AddRow(row5b, Theme.rowHeightLast, 0)
    yOffset = card5:GetNextOffset()

    UpdateAllWidgetStates()
    return yOffset
end)
