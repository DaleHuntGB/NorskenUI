---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

GUIFrame:RegisterContent("RerollKeystone", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.RerollKeystone
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type RerollKeystone?
    local RK = NorskenUI and NorskenUI:GetModule("RerollKeystone", true)
    local manager = GUIFrame:CreateWidgetStateManager()

    local function ApplySettings() if RK then RK:ApplySettings() end end
    local function UpdateAllWidgetStates() manager:UpdateAll(db.Enabled) end

    -- Card 1: Enable
    local card1 = GUIFrame:CreateCard(scrollChild, "Reroll Keystone", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Reroll Keystone", {
        value = db.Enabled,
        callback = function(checked)
            db.Enabled = checked
            if RK then
                if checked then NorskenUI:EnableModule("RerollKeystone") else NorskenUI:DisableModule("RerollKeystone") end
            end
            UpdateAllWidgetStates()
        end,
        msgPopup = true,
        msgText = "Reroll Keystone",
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, Theme.rowHeightLast, 0)

    yOffset = card1:GetNextOffset()

    -- Card 2: Appearance
    local card2 = GUIFrame:CreateCard(scrollChild, "Appearance", yOffset)
    manager:Register(card2, "all")

    local row2a = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local sizeSlider = GUIFrame:CreateSlider(row2a, "Icon Size", {
        value = db.Size,
        min = 20,
        max = 120,
        step = 1,
        callback = function(value)
            db.Size = value
            ApplySettings()
        end,
    })
    row2a:AddWidget(sizeSlider, 1)
    manager:Register(sizeSlider, "all")
    card2:AddRow(row2a, Theme.rowHeight)

    local sep2 = GUIFrame:CreateSeparator(card2.content)
    card2:AddRow(sep2, Theme.rowHeightSeparator)

    local row2b = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local fontColorPicker = GUIFrame:CreateColorPicker(row2b, "Text Color", {
        color = db.FontColor,
        callback = function(r, g, b, a)
            db.FontColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row2b:AddWidget(fontColorPicker, 0.5)
    manager:Register(fontColorPicker, "all")

    local fontSizeSlider = GUIFrame:CreateSlider(row2b, "Text Size", {
        value = db.FontSize,
        min = 8,
        max = 32,
        step = 1,
        callback = function(value)
            db.FontSize = value
            ApplySettings()
        end,
    })
    row2b:AddWidget(fontSizeSlider, 0.5)
    manager:Register(fontSizeSlider, "all")
    card2:AddRow(row2b, Theme.rowHeight)

    local row2c = GUIFrame:CreateRow(card2.content, Theme.rowHeightLast)
    local keyColorPicker = GUIFrame:CreateColorPicker(row2c, "Key Text Color", {
        color = db.FontColorKey,
        callback = function(r, g, b, a)
            db.FontColorKey = { r, g, b, a }
            ApplySettings()
        end
    })
    row2c:AddWidget(keyColorPicker, 0.5)
    manager:Register(keyColorPicker, "all")

    local keySizeSlider = GUIFrame:CreateSlider(row2c, "Key Text Size", {
        value = db.FontSizeKey,
        min = 8,
        max = 32,
        step = 1,
        callback = function(value)
            db.FontSizeKey = value
            ApplySettings()
        end,
    })
    row2c:AddWidget(keySizeSlider, 0.5)
    manager:Register(keySizeSlider, "all")
    card2:AddRow(row2c, Theme.rowHeightLast, 0)

    yOffset = card2:GetNextOffset()

    -- Card 3: Font Settings
    local fontCard, fontOffset, fontWidgets = GUIFrame:CreateFontSettingsCard(scrollChild, yOffset, {
        db = db,
        includeSoftOutline = true,
        onChangeCallback = ApplySettings,
        globalOverride = {},
    })
    manager:Register(fontCard, "all")
    manager:RegisterGroup(fontWidgets, "all")

    yOffset = fontOffset

    -- Card 4: Glow Settings
    local glowCard, glowOffset, glowWidgets = GUIFrame:CreateGlowSettingsCard(scrollChild, yOffset, {
        db = db,
        onChangeCallback = ApplySettings,
    })
    manager:Register(glowCard, "all")
    manager:RegisterGroup(glowWidgets, "all")

    yOffset = glowOffset

    -- Card 5: Position
    local posCard, posOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        db = db,
        showAnchorFrameType = true,
        showStrata = true,
        onChangeCallback = ApplySettings,
    })
    manager:Register(posCard, "all")
    if posCard.positionWidgets then manager:RegisterGroup(posCard.positionWidgets, "all") end

    yOffset = posOffset

    UpdateAllWidgetStates()

    return yOffset
end)
