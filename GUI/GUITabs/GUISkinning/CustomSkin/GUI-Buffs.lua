-- NorskenUI namespace
---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme
local LSM = NRSKNUI.LSM

-- Localization Setup
local table_insert = table.insert
local ipairs = ipairs
local pairs = pairs

-- Helper to get BuffTracking module
local function GetBuffTrackingModule()
    if NorskenUI then
        return NorskenUI:GetModule("BuffTracking", true)
    end
    return nil
end

----------------------------------------------------------------
-- BUFFS TAB
----------------------------------------------------------------
GUIFrame:RegisterContent("CustomSkin_Buffs", function(scrollChild, yOffset)
    if NRSKNUI:ShouldNotLoadModule() then return yOffset end
    local db = NRSKNUI.db and NRSKNUI.db.profile.Skinning.BuffTracking
    if not db then
        local errorCard = GUIFrame:CreateCard(scrollChild, "Error", yOffset)
        errorCard:AddLabel("Database not available")
        return yOffset + errorCard:GetContentHeight() + Theme.paddingMedium
    end

    local BUFFS = GetBuffTrackingModule()
    local allWidgets = {}

    local function ApplySettings()
        if not BUFFS or not BUFFS:IsEnabled() then return end
        if BUFFS.ApplySettings then
            BUFFS:ApplySettings()
        end
    end

    local function ApplyBuffsState(enabled)
        if not BUFFS then return end
        BUFFS.db.Enabled = enabled
        if enabled then
            NorskenUI:EnableModule("BuffTracking")
        else
            NorskenUI:DisableModule("BuffTracking")
        end
    end

    local function UpdateAllWidgetStates()
        local mainEnabled = db.Enabled ~= false
        for _, widget in ipairs(allWidgets) do
            if widget.SetEnabled then
                widget:SetEnabled(mainEnabled)
            end
        end
    end

    ----------------------------------------------------------------
    -- Card 1: Enable
    ----------------------------------------------------------------
    local card1 = GUIFrame:CreateCard(scrollChild, "Custom Buff Frame", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, 36)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Custom Buff Frame", {
        value = db.Enabled ~= false,
        callback = function(checked)
            db.Enabled = checked
            ApplyBuffsState(checked)
            UpdateAllWidgetStates()
            if not checked then
                NRSKNUI:CreateReloadPrompt("Enabling/Disabling this UI element requires a reload to take full effect.")
            end
        end,
        msgPopup = true,
        msgText = "Custom Buff Frame",
        msgOn = "On",
        msgOff = "Off"
    })
    row1:AddWidget(enableCheck, 0.5)

    -- Preview toggle button
    local previewBtn
    previewBtn = GUIFrame:CreateButton(row1, "Show Preview", {
        width = 130,
        height = 28,
        callback = function()
            if BUFFS and BUFFS.TogglePreview then
                local isActive = BUFFS:TogglePreview()
                previewBtn:SetLabel(isActive and "Hide Preview" or "Show Preview")
            end
        end
    })
    row1:AddWidget(previewBtn, 0.5)

    -- Update button text based on current state
    if BUFFS and BUFFS:IsPreviewActive() then
        previewBtn:SetLabel("Hide Preview")
    end

    card1:AddRow(row1, 36)
    yOffset = yOffset + card1:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 2: Icon Settings
    ----------------------------------------------------------------
    local card2 = GUIFrame:CreateCard(scrollChild, "Icon Settings", yOffset)

    -- Icon Size slider (min, max, step, value, labelWidth, callback)
    local row2a = GUIFrame:CreateRow(card2.content, 40)
    local iconSizeSlider = GUIFrame:CreateSlider(row2a, "Icon Size", {
        min = 16,
        max = 80,
        step = 1,
        value = db.IconSize or 36,
        callback = function(value)
            db.IconSize = value
            NRSKNUI:CreateReloadPrompt("Changing icon size requires a reload to take effect.")
        end
    })
    row2a:AddWidget(iconSizeSlider, 0.5)
    table_insert(allWidgets, iconSizeSlider)

    -- Icon Spacing slider
    local iconSpacingSlider = GUIFrame:CreateSlider(row2a, "Icon Spacing", {
        min = 0,
        max = 10,
        step = 1,
        value = db.IconSpacing or 1,
        callback = function(value)
            db.IconSpacing = value
            NRSKNUI:CreateReloadPrompt("Changing icon spacing requires a reload to take effect.")
        end
    })
    row2a:AddWidget(iconSpacingSlider, 0.5)
    table_insert(allWidgets, iconSpacingSlider)
    card2:AddRow(row2a, 40)

    -- Icons Per Row slider
    local row2b = GUIFrame:CreateRow(card2.content, 40)
    local iconsPerRowSlider = GUIFrame:CreateSlider(row2b, "Icons Per Row", {
        min = 1,
        max = 20,
        step = 1,
        value = db.IconsPerRow or 12,
        callback = function(value)
            db.IconsPerRow = value
            NRSKNUI:CreateReloadPrompt("Changing icons per row requires a reload to take effect.")
        end
    })
    row2b:AddWidget(iconsPerRowSlider, 0.5)
    table_insert(allWidgets, iconsPerRowSlider)

    -- Max Rows slider
    local maxRowsSlider = GUIFrame:CreateSlider(row2b, "Max Rows", {
        min = 1,
        max = 10,
        step = 1,
        value = db.MaxRows or 5,
        callback = function(value)
            db.MaxRows = value
            NRSKNUI:CreateReloadPrompt("Changing max rows requires a reload to take effect.")
        end
    })
    row2b:AddWidget(maxRowsSlider, 0.5)
    table_insert(allWidgets, maxRowsSlider)
    card2:AddRow(row2b, 40)

    -- Icon Zoom slider
    local row2c = GUIFrame:CreateRow(card2.content, 40)
    local iconZoomSlider = GUIFrame:CreateSlider(row2c, "Icon Zoom", {
        min = 0,
        max = 0.5,
        step = 0.01,
        value = db.IconZoom or 0.32,
        callback = function(value)
            db.IconZoom = value
            ApplySettings()
        end
    })
    row2c:AddWidget(iconZoomSlider, 0.5)
    table_insert(allWidgets, iconZoomSlider)
    card2:AddRow(row2c, 40)

    yOffset = yOffset + card2:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 3: Visual Settings
    ----------------------------------------------------------------
    local card3 = GUIFrame:CreateCard(scrollChild, "Visual Settings", yOffset)

    -- Border Color
    local row3a = GUIFrame:CreateRow(card3.content, 40)
    local borderColorPicker = GUIFrame:CreateColorPicker(row3a, "Border Color", {
        color = db.BorderColor,
        callback = function(r, g, b, a)
            db.BorderColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row3a:AddWidget(borderColorPicker, 0.5)
    table_insert(allWidgets, borderColorPicker)

    -- Background Color
    local bgColorPicker = GUIFrame:CreateColorPicker(row3a, "Background Color", {
        color = db.BackgroundColor,
        callback = function(r, g, b, a)
            db.BackgroundColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row3a:AddWidget(bgColorPicker, 0.5)
    table_insert(allWidgets, bgColorPicker)
    card3:AddRow(row3a, 40)

    -- Enchant Border Color
    local row3b = GUIFrame:CreateRow(card3.content, 40)
    local enchantColorPicker = GUIFrame:CreateColorPicker(row3b, "Weapon Enchant Border", {
        color = db.EnchantBorderColor,
        callback = function(r, g, b, a)
            db.EnchantBorderColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row3b:AddWidget(enchantColorPicker, 0.5)
    table_insert(allWidgets, enchantColorPicker)
    card3:AddRow(row3b, 40)

    yOffset = yOffset + card3:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 4: Font Settings
    ----------------------------------------------------------------
    local card4 = GUIFrame:CreateCard(scrollChild, "Font Settings", yOffset)

    -- Font list
    local fontList = {}
    if LSM then
        for name in pairs(LSM:HashTable("font")) do fontList[name] = name end
    else
        fontList["Friz Quadrata TT"] = "Friz Quadrata TT"
    end

    -- Font Face and Outline
    local row4a = GUIFrame:CreateRow(card4.content, 40)
    local fontDropdown = GUIFrame:CreateDropdown(row4a, "Font", {
        options = fontList,
        value = db.FontFace,
        callback = function(key)
            db.FontFace = key
            ApplySettings()
        end,
        searchable = true,
        isFontPreview = true
    })
    row4a:AddWidget(fontDropdown, 0.5)
    table_insert(allWidgets, fontDropdown)

    local outlineList = {
        { key = "NONE",         text = "None" },
        { key = "OUTLINE",      text = "Outline" },
        { key = "THICKOUTLINE", text = "Thick" },
    }
    local outlineDropdown = GUIFrame:CreateDropdown(row4a, "Outline", {
        options = outlineList,
        value = db.FontOutline or "OUTLINE",
        callback = function(key)
            db.FontOutline = key
            ApplySettings()
        end
    })
    row4a:AddWidget(outlineDropdown, 0.5)
    table_insert(allWidgets, outlineDropdown)
    card4:AddRow(row4a, 40)

    -- Font Size
    local row4b = GUIFrame:CreateRow(card4.content, 40)
    local fontSizeSlider = GUIFrame:CreateSlider(row4b, "Count Font Size", {
        min = 8,
        max = 24,
        step = 1,
        value = db.FontSize or 12,
        callback = function(value)
            db.FontSize = value
            ApplySettings()
        end
    })
    row4b:AddWidget(fontSizeSlider, 0.5)
    table_insert(allWidgets, fontSizeSlider)

    -- Timer Font Size
    local timerFontSizeSlider = GUIFrame:CreateSlider(row4b, "Timer Font Size", {
        min = 8,
        max = 32,
        step = 1,
        value = db.TimerFontSize or 14,
        callback = function(value)
            db.TimerFontSize = value
            ApplySettings()
        end
    })
    row4b:AddWidget(timerFontSizeSlider, 0.5)
    table_insert(allWidgets, timerFontSizeSlider)
    card4:AddRow(row4b, 40)

    -- Timer Position Offsets
    local timerPos = db.TimerPosition or {}
    local row4c = GUIFrame:CreateRow(card4.content, 40)
    local timerXSlider = GUIFrame:CreateSlider(row4c, "Timer X Offset", {
        min = -50,
        max = 50,
        step = 1,
        value = timerPos.XOffset or 0,
        callback = function(value)
            db.TimerPosition = db.TimerPosition or {}
            db.TimerPosition.XOffset = value
            ApplySettings()
        end
    })
    row4c:AddWidget(timerXSlider, 0.5)
    table_insert(allWidgets, timerXSlider)

    local timerYSlider = GUIFrame:CreateSlider(row4c, "Timer Y Offset", {
        min = -50,
        max = 50,
        step = 1,
        value = timerPos.YOffset or 0,
        callback = function(value)
            db.TimerPosition = db.TimerPosition or {}
            db.TimerPosition.YOffset = value
            ApplySettings()
        end
    })
    row4c:AddWidget(timerYSlider, 0.5)
    table_insert(allWidgets, timerYSlider)
    card4:AddRow(row4c, 40)

    yOffset = yOffset + card4:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 5: Filtering Options
    ----------------------------------------------------------------
    local card5 = GUIFrame:CreateCard(scrollChild, "Filtering Options", yOffset)

    -- Include Weapon Enchants
    local row5a = GUIFrame:CreateRow(card5.content, 40)
    local includeEnchantsCheck = GUIFrame:CreateCheckbox(row5a, "Include Weapon Enchants", {
        value = db.IncludeWeaponEnchants ~= false,
        callback = function(checked)
            db.IncludeWeaponEnchants = checked
            NRSKNUI:CreateReloadPrompt("Changing weapon enchant setting requires a reload to take effect.")
        end
    })
    row5a:AddWidget(includeEnchantsCheck, 0.5)
    table_insert(allWidgets, includeEnchantsCheck)
    card5:AddRow(row5a, 40)

    -- Sort Method and Direction
    local row5b = GUIFrame:CreateRow(card5.content, 40)
    local sortMethodList = { ["TIME"] = "Time", ["NAME"] = "Name", ["INDEX"] = "Index" }
    local sortMethodDropdown = GUIFrame:CreateDropdown(row5b, "Sort Method", {
        options = sortMethodList,
        value = db.SortMethod,
        callback = function(key)
            db.SortMethod = key
            NRSKNUI:CreateReloadPrompt("Changing sort method requires a reload to take effect.")
        end
    })
    row5b:AddWidget(sortMethodDropdown, 0.5)
    table_insert(allWidgets, sortMethodDropdown)

    local sortDirList = { ["-"] = "Descending", ["+"] = "Ascending" }
    local sortDirDropdown = GUIFrame:CreateDropdown(row5b, "Sort Direction", {
        options = sortDirList,
        value = db.SortDirection,
        callback = function(key)
            db.SortDirection = key
            NRSKNUI:CreateReloadPrompt("Changing sort direction requires a reload to take effect.")
        end
    })
    row5b:AddWidget(sortDirDropdown, 0.5)
    table_insert(allWidgets, sortDirDropdown)
    card5:AddRow(row5b, 40)

    yOffset = yOffset + card5:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 6: Position
    ----------------------------------------------------------------
    local card6 = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        title = "Position",
        db = db,
        showAnchorFrameType = true,
        showStrata = true,
        onChangeCallback = function()
            local BUFFS = GetBuffTrackingModule()
            if BUFFS and BUFFS.ApplyPosition then
                BUFFS:ApplyPosition()
            end
        end,
    })
    yOffset = yOffset + card6:GetContentHeight() + Theme.paddingSmall

    -- Apply initial widget states
    UpdateAllWidgetStates()
    yOffset = yOffset - (Theme.paddingSmall * 3)
    return yOffset
end)
