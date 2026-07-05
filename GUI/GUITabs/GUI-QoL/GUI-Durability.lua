---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local table_insert = table.insert
local ipairs = ipairs

GUIFrame:RegisterContent("Durability", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.Miscellaneous.Durability
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type Durability?
    local DUR = NRSKNUI:GetModule("Durability", true)
    local manager = GUIFrame:CreateWidgetStateManager()
    local postUpdateCallbacks = {}
    local textWidgets = {}
    local warningWidgets = {}
    local statusColorWidgets = {}

    local function ApplySettings()
        if DUR and DUR.ApplySettings then DUR:ApplySettings() end
    end

    local function UpdateTextState()
        local enabled = db.Text.Enabled
        for _, widget in ipairs(textWidgets) do
            if widget.SetEnabled then widget:SetEnabled(enabled) end
        end
        if enabled then
            local statusEnabled = not db.Text.UseStatusColor
            for _, widget in ipairs(statusColorWidgets) do
                if widget.SetEnabled then widget:SetEnabled(statusEnabled) end
            end
        end
    end

    local function UpdateWarningState()
        local enabled = db.WarningText.Enabled
        for _, widget in ipairs(warningWidgets) do
            if widget.SetEnabled then widget:SetEnabled(enabled) end
        end
    end

    local function UpdateAllWidgetStates()
        manager:UpdateAll(db.Enabled)
        if db.Enabled then
            for _, callback in ipairs(postUpdateCallbacks) do
                callback()
            end
        end
    end

    -- Card 1: Enable
    local card1 = GUIFrame:CreateCard(scrollChild, "Durability Util", yOffset)

    local row1a = GUIFrame:CreateRow(card1.content, Theme.rowHeight)
    local enableCheck = GUIFrame:CreateCheckbox(row1a, "Enable Durability Util", {
        value = db.Enabled,
        callback = function(checked)
            db.Enabled = checked
            if DUR then
                if checked then NRSKNUI:EnableModule("Durability") else NRSKNUI:DisableModule("Durability") end
            end
            UpdateAllWidgetStates()
        end,
        msgPopup = true,
        msgText = "Durability Util",
    })
    row1a:AddWidget(enableCheck, 1)
    card1:AddRow(row1a, Theme.rowHeight)

    local rowSep = GUIFrame:CreateRow(card1.content, Theme.rowHeightSeparator)
    local sep = GUIFrame:CreateSeparator(rowSep)
    rowSep:AddWidget(sep, 1)
    manager:Register(sep, "all")
    card1:AddRow(rowSep, Theme.rowHeightSeparator)

    local row1b = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
    local textEnableCheck = GUIFrame:CreateCheckbox(row1b, "Enable Data Text", {
        value = db.Text.Enabled,
        callback = function(checked)
            db.Text.Enabled = checked
            ApplySettings()
            UpdateTextState()
        end
    })
    row1b:AddWidget(textEnableCheck, 0.5)
    manager:Register(textEnableCheck, "all")

    local warningEnableCheck = GUIFrame:CreateCheckbox(row1b, "Enable Repair Warning", {
        value = db.WarningText.Enabled,
        callback = function(checked)
            db.WarningText.Enabled = checked
            ApplySettings()
            UpdateWarningState()
        end
    })
    row1b:AddWidget(warningEnableCheck, 0.5)
    manager:Register(warningEnableCheck, "all")
    card1:AddRow(row1b, Theme.rowHeightLast, 0)

    yOffset = card1:GetNextOffset()

    -- Card 2: Data Text Options
    local card2 = GUIFrame:CreateCard(scrollChild, "Data Text", yOffset)
    manager:Register(card2, "all")
    table_insert(textWidgets, card2)
    table_insert(postUpdateCallbacks, UpdateTextState)

    local red = NRSKNUI:ColorText("25%", { 1, 0, 0 })
    local orange = NRSKNUI:ColorText("50%", { 1, 0.42, 0 })
    local yellow = NRSKNUI:ColorText("75%", { 1, 0.82, 0 })
    local green = NRSKNUI:ColorText("100%", { 0, 1, 0 })
    local statusColorLabel = "Status Color: " .. red .. " / " .. orange .. " / " .. yellow .. " / " .. green

    local row2a = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local statusColorCheck = GUIFrame:CreateCheckbox(row2a, statusColorLabel, {
        value = db.Text.UseStatusColor,
        callback = function(checked)
            db.Text.UseStatusColor = checked
            ApplySettings()
            UpdateTextState()
        end
    })
    row2a:AddWidget(statusColorCheck, 0.5)
    manager:Register(statusColorCheck, "all")
    table_insert(textWidgets, statusColorCheck)

    local staticColor = GUIFrame:CreateColorPicker(row2a, "Static Color", {
        color = db.Text.Color,
        callback = function(r, g, b, a)
            db.Text.Color = { r, g, b, a }
            ApplySettings()
        end
    })
    row2a:AddWidget(staticColor, 0.5)
    manager:Register(staticColor, "all")
    table_insert(textWidgets, staticColor)
    table_insert(statusColorWidgets, staticColor)
    card2:AddRow(row2a, Theme.rowHeight)

    local row2b = GUIFrame:CreateRow(card2.content, Theme.rowHeightLast)
    local prefixEdit = GUIFrame:CreateEditBox(row2b, "Prefix", {
        value = db.Text.DurText,
        callback = function(val)
            db.Text.DurText = val
            ApplySettings()
        end
    })
    row2b:AddWidget(prefixEdit, 0.5)
    manager:Register(prefixEdit, "all")
    table_insert(textWidgets, prefixEdit)

    local prefixColor = GUIFrame:CreateColorPicker(row2b, "Prefix Color", {
        color = db.Text.DurColor,
        callback = function(r, g, b, a)
            db.Text.DurColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row2b:AddWidget(prefixColor, 0.5)
    manager:Register(prefixColor, "all")
    table_insert(textWidgets, prefixColor)
    card2:AddRow(row2b, Theme.rowHeightLast, 0)

    yOffset = card2:GetNextOffset()

    -- Card 3: Warning Text Options
    local card3 = GUIFrame:CreateCard(scrollChild, "Repair Warning", yOffset)
    manager:Register(card3, "all")
    table_insert(warningWidgets, card3)
    table_insert(postUpdateCallbacks, UpdateWarningState)

    local row3a = GUIFrame:CreateRow(card3.content, Theme.rowHeight)
    local warningTextEdit = GUIFrame:CreateEditBox(row3a, "Warning Text", {
        value = db.WarningText.WarningText,
        callback = function(val)
            db.WarningText.WarningText = val
            ApplySettings()
        end
    })
    row3a:AddWidget(warningTextEdit, 0.5)
    manager:Register(warningTextEdit, "all")
    table_insert(warningWidgets, warningTextEdit)

    local warningColor = GUIFrame:CreateColorPicker(row3a, "Warning Color", {
        color = db.WarningText.WarningColor,
        callback = function(r, g, b, a)
            db.WarningText.WarningColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row3a:AddWidget(warningColor, 0.5)
    manager:Register(warningColor, "all")
    table_insert(warningWidgets, warningColor)
    card3:AddRow(row3a, Theme.rowHeight)

    local row3b = GUIFrame:CreateRow(card3.content, Theme.rowHeightLast)
    local oocThreshold = GUIFrame:CreateSlider(row3b, "|cff4dff00Out of Combat|r Threshold %", {
        min = 1,
        max = 100,
        step = 1,
        value = db.WarningText.ShowPercent,
        callback = function(val)
            db.WarningText.ShowPercent = val
            ApplySettings()
        end
    })
    row3b:AddWidget(oocThreshold, 0.5)
    manager:Register(oocThreshold, "all")
    table_insert(warningWidgets, oocThreshold)

    local icThreshold = GUIFrame:CreateSlider(row3b, "|cffff0000In Combat|r Threshold %", {
        min = 0,
        max = 100,
        step = 1,
        value = db.WarningText.CombatShowPercent,
        callback = function(val)
            db.WarningText.CombatShowPercent = val
            ApplySettings()
        end
    })
    row3b:AddWidget(icThreshold, 0.5)
    manager:Register(icThreshold, "all")
    table_insert(warningWidgets, icThreshold)
    card3:AddRow(row3b, Theme.rowHeightLast, 0)

    yOffset = card3:GetNextOffset()

    -- Card 4: Font Settings
    local fontCard, fontOffset, fontWidgets = GUIFrame:CreateFontSettingsCard(scrollChild, yOffset, {
        title = "Font Settings",
        db = db,
        dbKeys = {
            fontFace = "FontFace",
            fontOutline = "FontOutline",
        },
        fontSizes = {
            { label = "Data Text Size", dbKey = "Text.FontSize" },
            { label = "Warning Size",   dbKey = "WarningText.FontSize" },
        },
        fontSizeRange = { 6, 80 },
        includeSoftOutline = true,
        onChangeCallback = ApplySettings,
        globalOverride = {},
    })
    manager:Register(fontCard, "all")
    manager:RegisterGroup(fontWidgets, "all")
    if fontCard.UpdateShadowState then table_insert(postUpdateCallbacks, fontCard.UpdateShadowState) end

    yOffset = fontOffset

    -- Card 5: Data Text Position
    local posCard1, posOffset1 = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        title = "Data Text Position",
        db = db.Text,
        showAnchorFrameType = true,
        showStrata = true,
        onChangeCallback = ApplySettings,
    })
    manager:Register(posCard1, "all")
    table_insert(textWidgets, posCard1)
    if posCard1.positionWidgets then
        manager:RegisterGroup(posCard1.positionWidgets, "all")
        for _, w in ipairs(posCard1.positionWidgets) do
            table_insert(textWidgets, w)
        end
    end

    yOffset = posOffset1

    -- Card 6: Warning Position
    local posCard2, posOffset2 = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        title = "Repair Warning Position",
        db = db.WarningText,
        showAnchorFrameType = false,
        showStrata = true,
        onChangeCallback = ApplySettings,
    })
    manager:Register(posCard2, "all")
    table_insert(warningWidgets, posCard2)
    if posCard2.positionWidgets then
        manager:RegisterGroup(posCard2.positionWidgets, "all")
        for _, w in ipairs(posCard2.positionWidgets) do
            table_insert(warningWidgets, w)
        end
    end

    yOffset = posOffset2

    UpdateAllWidgetStates()

    return yOffset
end)
