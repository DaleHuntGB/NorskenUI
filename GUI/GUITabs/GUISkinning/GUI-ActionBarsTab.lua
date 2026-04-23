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
local wipe = wipe
local CreateFrame = CreateFrame

-- Store current sub-tab
local currentSubTab = "global"

-- Widget tracking tables
local allWidgets = {}
local barWidgets = {}

-- Sub-tab definitions
local SUB_TABS = {
    { id = "global",   text = "Global" },
    { id = "position", text = "General & Position" },
    { id = "text",     text = "Texts" },
    { id = "backdrop", text = "Backdrop" },
}

-- Tab bar height constant
local TAB_BAR_HEIGHT = 28

-- Bar selection list
local BAR_LIST = {
    { key = "Bar1",      text = "Action Bar 1" },
    { key = "Bar2",      text = "Action Bar 2" },
    { key = "Bar3",      text = "Action Bar 3" },
    { key = "Bar4",      text = "Action Bar 4" },
    { key = "Bar5",      text = "Action Bar 5" },
    { key = "Bar6",      text = "Action Bar 6" },
    { key = "Bar7",      text = "Action Bar 7" },
    { key = "Bar8",      text = "Action Bar 8" },
    { key = "PetBar",    text = "Pet Bar" },
    { key = "StanceBar", text = "Stance Bar" },
}

-- Bar list as key-value for dropdowns
local BAR_LIST_KV = {}
for _, bar in ipairs(BAR_LIST) do
    BAR_LIST_KV[bar.key] = bar.text
end

-- Anchor options for text positioning
local ANCHOR_OPTIONS = {
    { key = "TOPLEFT",     text = "Top Left" },
    { key = "TOP",         text = "Top" },
    { key = "TOPRIGHT",    text = "Top Right" },
    { key = "LEFT",        text = "Left" },
    { key = "CENTER",      text = "Center" },
    { key = "RIGHT",       text = "Right" },
    { key = "BOTTOMLEFT",  text = "Bottom Left" },
    { key = "BOTTOM",      text = "Bottom" },
    { key = "BOTTOMRIGHT", text = "Bottom Right" },
}

-- Helper to get ActionBars module
local function GetActionBarsModule()
    if NorskenUI then
        return NorskenUI:GetModule("ActionBars", true)
    end
    return nil
end

-- Load database settings
local function GetActionBarsDB()
    if not NRSKNUI.db or not NRSKNUI.db.profile then return nil end
    return NRSKNUI.db.profile.Skinning.ActionBars
end

-- Helper to get current bar key
local function GetCurrentBarKey()
    local db = GetActionBarsDB()
    if not db then return "Bar1" end
    local curEdit = db.currentEdit or "Bar1"
    if not db.Bars[curEdit] then curEdit = "Bar1" end
    return curEdit
end

-- Helper to get current bar DB
local function GetCurrentBarDB()
    local db = GetActionBarsDB()
    if not db then return nil end
    return db.Bars[GetCurrentBarKey()]
end

-- Apply settings helpers
local function ApplyFonts()
    local ACB = GetActionBarsModule()
    if ACB then ACB:UpdateSettings("fonts") end
end

local function ApplyProfTextures()
    local ACB = GetActionBarsModule()
    if ACB then ACB:UpdateSettings("profTextures") end
end

local function ApplyBarSettings()
    local ACB = GetActionBarsModule()
    local curEdit = GetCurrentBarKey()
    if ACB then
        ACB:UpdateSettings("layout", curEdit)
        ACB:UpdateSettings("positions", curEdit)
        ACB:UpdateSettings("mouseover", curEdit)
        ACB:UpdateSettings("fonts")
        ACB:UpdateSettings("backdrops", curEdit)
    end
end

local function ApplyAllBars()
    local ACB = GetActionBarsModule()
    if ACB then ACB:UpdateSettings("all") end
end

-- Helper to apply module state
local function ApplyActionBarsState(enabled)
    local ACB = GetActionBarsModule()
    if not ACB then return end
    local db = GetActionBarsDB()
    if db then db.Enabled = enabled end
    if enabled then
        NorskenUI:EnableModule("ActionBars")
    else
        NorskenUI:DisableModule("ActionBars")
    end
end

-- Comprehensive widget state update
local function UpdateAllWidgetStates()
    local db = GetActionBarsDB()
    if not db then return end

    local mainEnabled = db.Enabled ~= false
    local barDB = GetCurrentBarDB()
    local barEnabled = barDB and barDB.Enabled ~= false

    -- Apply main enable state to ALL widgets
    for _, widget in ipairs(allWidgets) do
        if widget.SetEnabled then
            widget:SetEnabled(mainEnabled)
        end
    end

    -- Apply bar enabled state to bar-specific widgets
    for _, widget in ipairs(barWidgets) do
        if widget.SetEnabled then
            widget:SetEnabled(mainEnabled and barEnabled)
        end
    end
end

----------------------------------------------------------------
-- Sub-Tab: Global Settings
----------------------------------------------------------------
local function RenderGlobalTab(scrollChild, yOffset, activeCards)
    local db = GetActionBarsDB()
    if not db then return yOffset end

    -- Font list
    local fontList = {}
    if LSM then
        for name in pairs(LSM:HashTable("font")) do fontList[name] = name end
    else
        fontList["Friz Quadrata TT"] = "Friz Quadrata TT"
    end

    ----------------------------------------------------------------
    -- Card 1: ActionBars Master Enable
    ----------------------------------------------------------------
    local card1 = GUIFrame:CreateCard(scrollChild, "Action Bars", yOffset)
    table_insert(activeCards, card1)

    local row1 = GUIFrame:CreateRow(card1.content, 36)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Action Bars Skinning", {
        value = db.Enabled ~= false,
        callback = function(checked)
            db.Enabled = checked
            ApplyActionBarsState(checked)
            UpdateAllWidgetStates()
            NRSKNUI:CreateReloadPrompt("Enabling/Disabling Action Bars requires a reload to take full effect.")
        end,
        msgPopup = true, msgText = "Action Bars", msgOn = "On", msgOff = "Off"
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, 36)

    yOffset = yOffset + card1:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 2: General Settings
    ----------------------------------------------------------------
    local card2 = GUIFrame:CreateCard(scrollChild, "General Settings", yOffset)
    table_insert(activeCards, card2)
    table_insert(allWidgets, card2)

    -- Hide Profession Texture and Hide Macro Text
    local row2 = GUIFrame:CreateRow(card2.content, 36)
    local hideProfCheck = GUIFrame:CreateCheckbox(row2, "Hide Profession Texture", {
        value = db.HideProfTexture == true,
        callback = function(checked)
            db.HideProfTexture = checked
            ApplyProfTextures()
        end
    })
    row2:AddWidget(hideProfCheck, 0.5)
    table_insert(allWidgets, hideProfCheck)

    local hideMacroCheck = GUIFrame:CreateCheckbox(row2, "Hide Macro Text", {
        value = db.HideMacroText == true,
        callback = function(checked)
            db.HideMacroText = checked
            ApplyFonts()
        end
    })
    row2:AddWidget(hideMacroCheck, 0.5)
    table_insert(allWidgets, hideMacroCheck)
    card2:AddRow(row2, 36)

    yOffset = yOffset + card2:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 3: Global Font Settings
    ----------------------------------------------------------------
    local card3 = GUIFrame:CreateCard(scrollChild, "Global Font Settings", yOffset)
    table_insert(activeCards, card3)
    table_insert(allWidgets, card3)

    -- Ensure FontSizes table exists
    db.FontSizes = db.FontSizes or {}

    -- Font Face and Outline
    local row3a = GUIFrame:CreateRow(card3.content, 40)
    local fontDropdown = GUIFrame:CreateDropdown(row3a, "Font", {
        options = fontList,
        value = db.FontFace,
        callback = function(key)
            db.FontFace = key
            ApplyFonts()
        end,
        searchable = true,
        isFontPreview = true
    })
    row3a:AddWidget(fontDropdown, 0.5)
    table_insert(allWidgets, fontDropdown)

    local outlineList = { ["NONE"] = "None", ["OUTLINE"] = "Outline", ["THICKOUTLINE"] = "Thick" }
    local outlineDropdown = GUIFrame:CreateDropdown(row3a, "Outline", {
        options = outlineList,
        value = db.FontOutline or "OUTLINE",
        callback = function(key)
            db.FontOutline = key
            ApplyFonts()
        end
    })
    row3a:AddWidget(outlineDropdown, 0.5)
    table_insert(allWidgets, outlineDropdown)
    card3:AddRow(row3a, 40)

    -- Separator
    local row3sep = GUIFrame:CreateRow(card3.content, 8)
    row3sep:AddWidget(GUIFrame:CreateSeparator(row3sep), 1)
    card3:AddRow(row3sep, 8)

    -- Keybind and Cooldown Size
    local row3b = GUIFrame:CreateRow(card3.content, 40)
    local keybindSize = GUIFrame:CreateSlider(row3b, "Keybind Size", {
        min = 6,
        max = 24,
        step = 1,
        value = db.FontSizes.KeybindSize or 12,
        callback = function(val)
            db.FontSizes.KeybindSize = val
            ApplyFonts()
        end
    })
    row3b:AddWidget(keybindSize, 0.5)
    table_insert(allWidgets, keybindSize)

    local cooldownSize = GUIFrame:CreateSlider(row3b, "Cooldown Size", {
        min = 6,
        max = 24,
        step = 1,
        value = db.FontSizes.CooldownSize or 14,
        callback = function(val)
            db.FontSizes.CooldownSize = val
            ApplyFonts()
        end
    })
    row3b:AddWidget(cooldownSize, 0.5)
    table_insert(allWidgets, cooldownSize)
    card3:AddRow(row3b, 40)

    -- Charge and Macro Size
    local row3c = GUIFrame:CreateRow(card3.content, 40)
    local chargeSize = GUIFrame:CreateSlider(row3c, "Charge Size", {
        min = 6,
        max = 24,
        step = 1,
        value = db.FontSizes.ChargeSize or 12,
        callback = function(val)
            db.FontSizes.ChargeSize = val
            ApplyFonts()
        end
    })
    row3c:AddWidget(chargeSize, 0.5)
    table_insert(allWidgets, chargeSize)

    local macroSize = GUIFrame:CreateSlider(row3c, "Macro Size", {
        min = 6,
        max = 24,
        step = 1,
        value = db.FontSizes.MacroSize or 10,
        callback = function(val)
            db.FontSizes.MacroSize = val
            ApplyFonts()
        end
    })
    row3c:AddWidget(macroSize, 0.5)
    table_insert(allWidgets, macroSize)
    card3:AddRow(row3c, 40)

    yOffset = yOffset + card3:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 4: Global Mouseover Settings
    ----------------------------------------------------------------
    local card4 = GUIFrame:CreateCard(scrollChild, "Global Mouseover Settings", yOffset)
    table_insert(activeCards, card4)
    table_insert(allWidgets, card4)

    local row4a = GUIFrame:CreateRow(card4.content, 36)
    local globalMouseoverCheck = GUIFrame:CreateCheckbox(row4a, "Enable Global Mouseover", {
        value = db.Mouseover and db.Mouseover.Enabled == true,
        callback = function(checked)
            db.Mouseover = db.Mouseover or {}
            db.Mouseover.Enabled = checked
            ApplyAllBars()
        end
    })
    row4a:AddWidget(globalMouseoverCheck, 0.5)
    table_insert(allWidgets, globalMouseoverCheck)

    local mouseoverOverrideCheck = GUIFrame:CreateCheckbox(row4a, "Override When Mounted/Vehicle", {
        value = db.MouseoverOverride == true,
        callback = function(checked)
            db.MouseoverOverride = checked
            local ACB = GetActionBarsModule()
            if ACB then ACB:UpdateBonusBarOverride() end
        end
    })
    row4a:AddWidget(mouseoverOverrideCheck, 0.5)
    table_insert(allWidgets, mouseoverOverrideCheck)
    card4:AddRow(row4a, 36)

    -- Separator
    local row4sep = GUIFrame:CreateRow(card4.content, 8)
    row4sep:AddWidget(GUIFrame:CreateSeparator(row4sep), 1)
    card4:AddRow(row4sep, 8)

    -- Global Mouseover Alpha
    local row4b = GUIFrame:CreateRow(card4.content, 40)
    local globalAlpha = GUIFrame:CreateSlider(row4b, "Fade Out Alpha", {
        min = 0,
        max = 1,
        step = 0.05,
        value = db.Mouseover and db.Mouseover.Alpha or 0,
        callback = function(val)
            db.Mouseover = db.Mouseover or {}
            db.Mouseover.Alpha = val
            ApplyAllBars()
        end
    })
    row4b:AddWidget(globalAlpha, 1)
    table_insert(allWidgets, globalAlpha)
    card4:AddRow(row4b, 40)

    -- Fade Durations
    local row4c = GUIFrame:CreateRow(card4.content, 40)
    local fadeIn = GUIFrame:CreateSlider(row4c, "Fade In Duration", {
        min = 0,
        max = 2,
        step = 0.1,
        value = db.Mouseover and db.Mouseover.FadeInDuration or 0.3,
        callback = function(val)
            db.Mouseover = db.Mouseover or {}
            db.Mouseover.FadeInDuration = val
            ApplyAllBars()
        end
    })
    row4c:AddWidget(fadeIn, 0.5)
    table_insert(allWidgets, fadeIn)

    local fadeOut = GUIFrame:CreateSlider(row4c, "Fade Out Duration", {
        min = 0,
        max = 2,
        step = 0.1,
        value = db.Mouseover and db.Mouseover.FadeOutDuration or 1,
        callback = function(val)
            db.Mouseover = db.Mouseover or {}
            db.Mouseover.FadeOutDuration = val
            ApplyAllBars()
        end
    })
    row4c:AddWidget(fadeOut, 0.5)
    table_insert(allWidgets, fadeOut)
    card4:AddRow(row4c, 40)

    yOffset = yOffset + card4:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 5: Bar Enable/Disable
    ----------------------------------------------------------------
    local card5 = GUIFrame:CreateCard(scrollChild, "Bar Enable/Disable", yOffset)
    table_insert(activeCards, card5)
    table_insert(allWidgets, card5)

    -- Create rows of bar toggles (2 per row)
    local barIndex = 1
    while barIndex <= #BAR_LIST do
        local rowHeight = 40
        local row = GUIFrame:CreateRow(card5.content, rowHeight)

        -- First bar in row
        local bar1 = BAR_LIST[barIndex]
        if bar1 then
            local barDB1 = db.Bars[bar1.key]
            local check1 = GUIFrame:CreateCheckbox(row, bar1.text, {
                value = barDB1 and barDB1.Enabled ~= false,
                callback = function(checked)
                    if db.Bars[bar1.key] then
                        db.Bars[bar1.key].Enabled = checked
                        local ACB = GetActionBarsModule()
                        if ACB then ACB:UpdateSettings("enabled", bar1.key) end
                        if checked then
                            NRSKNUI:CreateReloadPrompt("Enabling bars requires a reload to take full effect.")
                        end
                    end
                end
            })
            row:AddWidget(check1, 0.5)
            table_insert(allWidgets, check1)
        end

        -- Second bar in row
        barIndex = barIndex + 1
        local bar2 = BAR_LIST[barIndex]
        if bar2 then
            local barDB2 = db.Bars[bar2.key]
            local check2 = GUIFrame:CreateCheckbox(row, bar2.text, {
                value = barDB2 and barDB2.Enabled ~= false,
                callback = function(checked)
                    if db.Bars[bar2.key] then
                        db.Bars[bar2.key].Enabled = checked
                        local ACB = GetActionBarsModule()
                        if ACB then ACB:UpdateSettings("enabled", bar2.key) end
                        if checked then
                            NRSKNUI:CreateReloadPrompt("Enabling bars requires a reload to take full effect.")
                        end
                    end
                end
            })
            row:AddWidget(check2, 0.5)
            table_insert(allWidgets, check2)
        else
            row:AddWidget(CreateFrame("Frame", nil, row), 0.5)
        end

        card5:AddRow(row, rowHeight)
        barIndex = barIndex + 1
    end

    yOffset = yOffset + card5:GetContentHeight() + Theme.paddingSmall

    UpdateAllWidgetStates()
    yOffset = yOffset - (Theme.paddingSmall * 2)
    return yOffset
end

----------------------------------------------------------------
-- Sub-Tab: Position Settings
----------------------------------------------------------------
local function RenderPositionTab(scrollChild, yOffset, activeCards)
    local db = GetActionBarsDB()
    if not db then return yOffset end

    local curEdit = GetCurrentBarKey()
    local barDB = GetCurrentBarDB()

    ----------------------------------------------------------------
    -- Card 1: Bar Selection
    ----------------------------------------------------------------
    local card1 = GUIFrame:CreateCard(scrollChild, "Select Bar", yOffset)
    table_insert(activeCards, card1)
    table_insert(allWidgets, card1)

    local row1 = GUIFrame:CreateRow(card1.content, 40)
    local barDropdown = GUIFrame:CreateDropdown(row1, "Select Bar to Edit", {
        options = BAR_LIST_KV,
        value = curEdit,
        callback = function(key)
            db.currentEdit = key
            C_Timer.After(0.2, function()
                GUIFrame:RefreshContent()
            end)
        end
    })
    row1:AddWidget(barDropdown, 1)
    table_insert(allWidgets, barDropdown)
    card1:AddRow(row1, 40)

    yOffset = yOffset + card1:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 2: Layout Settings
    ----------------------------------------------------------------
    local card2 = GUIFrame:CreateCard(scrollChild,
        "Layout: " .. "|cffFFFFFF" .. (BAR_LIST_KV[curEdit] or curEdit) .. "|r", yOffset)
    table_insert(activeCards, card2)
    table_insert(allWidgets, card2)
    table_insert(barWidgets, card2)

    -- Button Size and Spacing
    local row2a = GUIFrame:CreateRow(card2.content, 40)
    local buttonSizeSlider = GUIFrame:CreateSlider(row2a, "Button Size", {
        min = 20,
        max = 80,
        step = 1,
        value = barDB and barDB.ButtonSize or 40,
        callback = function(val)
            local bdb = GetCurrentBarDB()
            if bdb then bdb.ButtonSize = val end
            ApplyBarSettings()
        end
    })
    row2a:AddWidget(buttonSizeSlider, 0.5)
    table_insert(allWidgets, buttonSizeSlider)
    table_insert(barWidgets, buttonSizeSlider)

    local spacingSlider = GUIFrame:CreateSlider(row2a, "Spacing", {
        min = 0,
        max = 20,
        step = 1,
        value = barDB and barDB.Spacing or 1,
        callback = function(val)
            local bdb = GetCurrentBarDB()
            if bdb then bdb.Spacing = val end
            ApplyBarSettings()
        end
    })
    row2a:AddWidget(spacingSlider, 0.5)
    table_insert(allWidgets, spacingSlider)
    table_insert(barWidgets, spacingSlider)
    card2:AddRow(row2a, 40)

    -- Total Buttons and Buttons Per Line
    local row2b = GUIFrame:CreateRow(card2.content, 40)
    local totalButtonsSlider = GUIFrame:CreateSlider(row2b, "Total Buttons", {
        min = 1,
        max = 12,
        step = 1,
        value = barDB and barDB.TotalButtons or 12,
        callback = function(val)
            local bdb = GetCurrentBarDB()
            if bdb then bdb.TotalButtons = val end
            ApplyBarSettings()
        end
    })
    row2b:AddWidget(totalButtonsSlider, 0.5)
    table_insert(allWidgets, totalButtonsSlider)
    table_insert(barWidgets, totalButtonsSlider)

    local buttonsPerLineSlider = GUIFrame:CreateSlider(row2b, "Buttons Per Line", {
        min = 1,
        max = 12,
        step = 1,
        value = barDB and barDB.ButtonsPerLine or 12,
        callback = function(val)
            local bdb = GetCurrentBarDB()
            if bdb then bdb.ButtonsPerLine = val end
            ApplyBarSettings()
        end
    })
    row2b:AddWidget(buttonsPerLineSlider, 0.5)
    table_insert(allWidgets, buttonsPerLineSlider)
    table_insert(barWidgets, buttonsPerLineSlider)
    card2:AddRow(row2b, 40)

    -- Layout Direction and Growth Direction
    local row2c = GUIFrame:CreateRow(card2.content, 40)
    local layoutList = { ["HORIZONTAL"] = "Horizontal", ["VERTICAL"] = "Vertical" }
    local layoutDropdown = GUIFrame:CreateDropdown(row2c, "Layout Direction", {
        options = layoutList,
        value = barDB and barDB.Layout or "HORIZONTAL",
        callback = function(key)
            local bdb = GetCurrentBarDB()
            if bdb then bdb.Layout = key end
            ApplyBarSettings()
        end
    })
    row2c:AddWidget(layoutDropdown, 0.5)
    table_insert(allWidgets, layoutDropdown)
    table_insert(barWidgets, layoutDropdown)

    local growthList = { ["RIGHT"] = "Grow Right", ["LEFT"] = "Grow Left" }
    local growthDropdown = GUIFrame:CreateDropdown(row2c, "Growth Direction", {
        options = growthList,
        value = barDB and barDB.GrowthDirection or "RIGHT",
        callback = function(key)
            local bdb = GetCurrentBarDB()
            if bdb then bdb.GrowthDirection = key end
            ApplyBarSettings()
        end
    })
    row2c:AddWidget(growthDropdown, 0.5)
    table_insert(allWidgets, growthDropdown)
    table_insert(barWidgets, growthDropdown)
    card2:AddRow(row2c, 40)

    yOffset = yOffset + card2:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 3: Position Settings
    ----------------------------------------------------------------
    local card3, newOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        title = "Position: " .. "|cffFFFFFF" .. (BAR_LIST_KV[curEdit] or curEdit) .. "|r",
        db = barDB and barDB.Position or {},
        showAnchorFrameType = false,
        showStrata = false,
        onChangeCallback = ApplyBarSettings,
    })
    table_insert(activeCards, card3)
    if card3.positionWidgets then
        for _, widget in ipairs(card3.positionWidgets) do
            table_insert(allWidgets, widget)
            table_insert(barWidgets, widget)
        end
    end
    table_insert(allWidgets, card3)
    table_insert(barWidgets, card3)
    yOffset = newOffset

    ----------------------------------------------------------------
    -- Card 4: Mouseover Settings (Per-Bar)
    ----------------------------------------------------------------
    local card4 = GUIFrame:CreateCard(scrollChild,
        "Mouseover: " .. "|cffFFFFFF" .. (BAR_LIST_KV[curEdit] or curEdit) .. "|r", yOffset)
    table_insert(activeCards, card4)
    table_insert(allWidgets, card4)
    table_insert(barWidgets, card4)

    -- Ensure Mouseover table exists
    if barDB then barDB.Mouseover = barDB.Mouseover or {} end

    local row4a = GUIFrame:CreateRow(card4.content, 36)
    local useGlobalMouseoverCheck = GUIFrame:CreateCheckbox(row4a, "Use Global Mouseover", {
        value = barDB and barDB.Mouseover and barDB.Mouseover.GlobalOverride == true,
        callback = function(checked)
            local bdb = GetCurrentBarDB()
            if bdb then
                bdb.Mouseover = bdb.Mouseover or {}
                bdb.Mouseover.GlobalOverride = checked
            end
            ApplyBarSettings()
            C_Timer.After(0.2, function() GUIFrame:RefreshContent() end)
        end
    })
    row4a:AddWidget(useGlobalMouseoverCheck, 0.5)
    table_insert(allWidgets, useGlobalMouseoverCheck)
    table_insert(barWidgets, useGlobalMouseoverCheck)

    local barMouseoverCheck = GUIFrame:CreateCheckbox(row4a, "Enable Mouseover", {
        value = barDB and barDB.Mouseover and barDB.Mouseover.Enabled == true,
        callback = function(checked)
            local bdb = GetCurrentBarDB()
            if bdb then
                bdb.Mouseover = bdb.Mouseover or {}
                bdb.Mouseover.Enabled = checked
            end
            ApplyBarSettings()
        end
    })
    row4a:AddWidget(barMouseoverCheck, 0.5)
    table_insert(allWidgets, barMouseoverCheck)
    table_insert(barWidgets, barMouseoverCheck)
    card4:AddRow(row4a, 36)

    -- Only show alpha if not using global
    local useGlobalMouseover = barDB and barDB.Mouseover and barDB.Mouseover.GlobalOverride == true
    if not useGlobalMouseover then
        local row4sep = GUIFrame:CreateRow(card4.content, 8)
        row4sep:AddWidget(GUIFrame:CreateSeparator(row4sep), 1)
        card4:AddRow(row4sep, 8)

        local row4b = GUIFrame:CreateRow(card4.content, 40)
        local barAlpha = GUIFrame:CreateSlider(row4b, "Fade Out Alpha", {
            min = 0,
            max = 1,
            step = 0.05,
            value = barDB and barDB.Mouseover and barDB.Mouseover.Alpha or 0,
            callback = function(val)
                local bdb = GetCurrentBarDB()
                if bdb then
                    bdb.Mouseover = bdb.Mouseover or {}
                    bdb.Mouseover.Alpha = val
                end
                ApplyBarSettings()
            end
        })
        row4b:AddWidget(barAlpha, 1)
        table_insert(allWidgets, barAlpha)
        table_insert(barWidgets, barAlpha)
        card4:AddRow(row4b, 40)
    end

    yOffset = yOffset + card4:GetContentHeight() + Theme.paddingSmall

    UpdateAllWidgetStates()
    yOffset = yOffset - (Theme.paddingSmall * 2)
    return yOffset
end

----------------------------------------------------------------
-- Sub-Tab: Text Settings
----------------------------------------------------------------
local function RenderTextTab(scrollChild, yOffset, activeCards)
    local db = GetActionBarsDB()
    if not db then return yOffset end

    local curEdit = GetCurrentBarKey()
    local barDB = GetCurrentBarDB()

    ----------------------------------------------------------------
    -- Card 1: Bar Selection
    ----------------------------------------------------------------
    local card1 = GUIFrame:CreateCard(scrollChild, "Select Bar", yOffset)
    table_insert(activeCards, card1)
    table_insert(allWidgets, card1)

    local row1 = GUIFrame:CreateRow(card1.content, 40)
    local barDropdown = GUIFrame:CreateDropdown(row1, "Select Bar to Edit", {
        options = BAR_LIST_KV,
        value = curEdit,
        callback = function(key)
            db.currentEdit = key
            C_Timer.After(0.2, function()
                GUIFrame:RefreshContent()
            end)
        end
    })
    row1:AddWidget(barDropdown, 1)
    table_insert(allWidgets, barDropdown)
    card1:AddRow(row1, 40)

    yOffset = yOffset + card1:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 2: Global Override Toggle
    ----------------------------------------------------------------
    local card2 = GUIFrame:CreateCard(scrollChild,
        "Text Settings: " .. "|cffFFFFFF" .. (BAR_LIST_KV[curEdit] or curEdit) .. "|r", yOffset)
    table_insert(activeCards, card2)
    table_insert(allWidgets, card2)
    table_insert(barWidgets, card2)

    -- Ensure tables exist
    if barDB then
        barDB.FontSizes = barDB.FontSizes or {}
        barDB.TextPositions = barDB.TextPositions or {}
    end

    -- Use Global toggles
    local row2a = GUIFrame:CreateRow(card2.content, 36)
    local useGlobalFontCheck = GUIFrame:CreateCheckbox(row2a, "Use Global Font Sizes", {
        value = barDB and barDB.FontSizes and barDB.FontSizes.GlobalOverride == true,
        callback = function(checked)
            local bdb = GetCurrentBarDB()
            if bdb then
                bdb.FontSizes = bdb.FontSizes or {}
                bdb.FontSizes.GlobalOverride = checked
            end
            ApplyBarSettings()
            C_Timer.After(0.2, function() GUIFrame:RefreshContent() end)
        end
    })
    row2a:AddWidget(useGlobalFontCheck, 0.5)
    table_insert(allWidgets, useGlobalFontCheck)
    table_insert(barWidgets, useGlobalFontCheck)

    local useGlobalPosCheck = GUIFrame:CreateCheckbox(row2a, "Use Global Text Positions", {
        value = barDB and barDB.TextPositions and barDB.TextPositions.GlobalOverride == true,
        callback = function(checked)
            local bdb = GetCurrentBarDB()
            if bdb then
                bdb.TextPositions = bdb.TextPositions or {}
                bdb.TextPositions.GlobalOverride = checked
            end
            ApplyBarSettings()
            C_Timer.After(0.2, function() GUIFrame:RefreshContent() end)
        end
    })
    row2a:AddWidget(useGlobalPosCheck, 0.5)
    table_insert(allWidgets, useGlobalPosCheck)
    table_insert(barWidgets, useGlobalPosCheck)
    card2:AddRow(row2a, 36)

    yOffset = yOffset + card2:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 3: Per-Bar Font Sizes (only if not using global)
    ----------------------------------------------------------------
    local useGlobalFonts = barDB and barDB.FontSizes and barDB.FontSizes.GlobalOverride == true
    if not useGlobalFonts then
        local card3 = GUIFrame:CreateCard(scrollChild,
            "Font Sizes: " .. "|cffFFFFFF" .. (BAR_LIST_KV[curEdit] or curEdit) .. "|r", yOffset)
        table_insert(activeCards, card3)
        table_insert(allWidgets, card3)
        table_insert(barWidgets, card3)

        -- Keybind and Cooldown Size
        local row3a = GUIFrame:CreateRow(card3.content, 40)
        local barKeybindSize = GUIFrame:CreateSlider(row3a, "Keybind Size", {
            min = 6,
            max = 24,
            step = 1,
            value = barDB and barDB.FontSizes and barDB.FontSizes.KeybindSize or 12,
            callback = function(val)
                local bdb = GetCurrentBarDB()
                if bdb then
                    bdb.FontSizes = bdb.FontSizes or {}
                    bdb.FontSizes.KeybindSize = val
                end
                ApplyBarSettings()
            end
        })
        row3a:AddWidget(barKeybindSize, 0.5)
        table_insert(allWidgets, barKeybindSize)
        table_insert(barWidgets, barKeybindSize)

        local barCooldownSize = GUIFrame:CreateSlider(row3a, "Cooldown Size", {
            min = 6,
            max = 24,
            step = 1,
            value = barDB and barDB.FontSizes and barDB.FontSizes.CooldownSize or 14,
            callback = function(val)
                local bdb = GetCurrentBarDB()
                if bdb then
                    bdb.FontSizes = bdb.FontSizes or {}
                    bdb.FontSizes.CooldownSize = val
                end
                ApplyBarSettings()
            end
        })
        row3a:AddWidget(barCooldownSize, 0.5)
        table_insert(allWidgets, barCooldownSize)
        table_insert(barWidgets, barCooldownSize)
        card3:AddRow(row3a, 40)

        -- Charge and Macro Size
        local row3b = GUIFrame:CreateRow(card3.content, 40)
        local barChargeSize = GUIFrame:CreateSlider(row3b, "Charge Size", {
            min = 6,
            max = 24,
            step = 1,
            value = barDB and barDB.FontSizes and barDB.FontSizes.ChargeSize or 12,
            callback = function(val)
                local bdb = GetCurrentBarDB()
                if bdb then
                    bdb.FontSizes = bdb.FontSizes or {}
                    bdb.FontSizes.ChargeSize = val
                end
                ApplyBarSettings()
            end
        })
        row3b:AddWidget(barChargeSize, 0.5)
        table_insert(allWidgets, barChargeSize)
        table_insert(barWidgets, barChargeSize)

        local barMacroSize = GUIFrame:CreateSlider(row3b, "Macro Size", {
            min = 6,
            max = 24,
            step = 1,
            value = barDB and barDB.FontSizes and barDB.FontSizes.MacroSize or 10,
            callback = function(val)
                local bdb = GetCurrentBarDB()
                if bdb then
                    bdb.FontSizes = bdb.FontSizes or {}
                    bdb.FontSizes.MacroSize = val
                end
                ApplyBarSettings()
            end
        })
        row3b:AddWidget(barMacroSize, 0.5)
        table_insert(allWidgets, barMacroSize)
        table_insert(barWidgets, barMacroSize)
        card3:AddRow(row3b, 40)

        yOffset = yOffset + card3:GetContentHeight() + Theme.paddingSmall
    end

    ----------------------------------------------------------------
    -- Card 4: Per-Bar Text Positions (only if not using global)
    ----------------------------------------------------------------
    local useGlobalPos = barDB and barDB.TextPositions and barDB.TextPositions.GlobalOverride == true
    if not useGlobalPos then
        local card4 = GUIFrame:CreateCard(scrollChild,
            "Text Positions: " .. "|cffFFFFFF" .. (BAR_LIST_KV[curEdit] or curEdit) .. "|r", yOffset)
        table_insert(activeCards, card4)
        table_insert(allWidgets, card4)
        table_insert(barWidgets, card4)

        local tp = barDB and barDB.TextPositions or {}

        -- Keybind Position
        local row4a = GUIFrame:CreateRow(card4.content, 40)
        local keybindAnchor = GUIFrame:CreateDropdown(row4a, "Keybind Anchor", {
            options = ANCHOR_OPTIONS,
            value = tp.KeybindAnchor or "TOPRIGHT",
            labelWidth = 80,
            callback = function(key)
                local bdb = GetCurrentBarDB()
                if bdb then
                    bdb.TextPositions = bdb.TextPositions or {}
                    bdb.TextPositions.KeybindAnchor = key
                end
                ApplyBarSettings()
            end
        })
        row4a:AddWidget(keybindAnchor, 0.34)
        table_insert(allWidgets, keybindAnchor)
        table_insert(barWidgets, keybindAnchor)

        local keybindX = GUIFrame:CreateSlider(row4a, "X", {
            min = -20, max = 20, step = 1,
            value = tp.KeybindXOffset or -2,
            labelWidth = 30,
            callback = function(val)
                local bdb = GetCurrentBarDB()
                if bdb then
                    bdb.TextPositions = bdb.TextPositions or {}
                    bdb.TextPositions.KeybindXOffset = val
                end
                ApplyBarSettings()
            end
        })
        row4a:AddWidget(keybindX, 0.33)
        table_insert(allWidgets, keybindX)
        table_insert(barWidgets, keybindX)

        local keybindY = GUIFrame:CreateSlider(row4a, "Y", {
            min = -20, max = 20, step = 1,
            value = tp.KeybindYOffset or -2,
            labelWidth = 30,
            callback = function(val)
                local bdb = GetCurrentBarDB()
                if bdb then
                    bdb.TextPositions = bdb.TextPositions or {}
                    bdb.TextPositions.KeybindYOffset = val
                end
                ApplyBarSettings()
            end
        })
        row4a:AddWidget(keybindY, 0.33)
        table_insert(allWidgets, keybindY)
        table_insert(barWidgets, keybindY)
        card4:AddRow(row4a, 40)

        -- Separator
        local row4sep1 = GUIFrame:CreateRow(card4.content, 8)
        row4sep1:AddWidget(GUIFrame:CreateSeparator(row4sep1), 1)
        card4:AddRow(row4sep1, 8)

        -- Charge Position
        local row4b = GUIFrame:CreateRow(card4.content, 40)
        local chargeAnchor = GUIFrame:CreateDropdown(row4b, "Charge Anchor", {
            options = ANCHOR_OPTIONS,
            value = tp.ChargeAnchor or "BOTTOMRIGHT",
            labelWidth = 80,
            callback = function(key)
                local bdb = GetCurrentBarDB()
                if bdb then
                    bdb.TextPositions = bdb.TextPositions or {}
                    bdb.TextPositions.ChargeAnchor = key
                end
                ApplyBarSettings()
            end
        })
        row4b:AddWidget(chargeAnchor, 0.34)
        table_insert(allWidgets, chargeAnchor)
        table_insert(barWidgets, chargeAnchor)

        local chargeX = GUIFrame:CreateSlider(row4b, "X", {
            min = -20, max = 20, step = 1,
            value = tp.ChargeXOffset or -2,
            labelWidth = 30,
            callback = function(val)
                local bdb = GetCurrentBarDB()
                if bdb then
                    bdb.TextPositions = bdb.TextPositions or {}
                    bdb.TextPositions.ChargeXOffset = val
                end
                ApplyBarSettings()
            end
        })
        row4b:AddWidget(chargeX, 0.33)
        table_insert(allWidgets, chargeX)
        table_insert(barWidgets, chargeX)

        local chargeY = GUIFrame:CreateSlider(row4b, "Y", {
            min = -20, max = 20, step = 1,
            value = tp.ChargeYOffset or 2,
            labelWidth = 30,
            callback = function(val)
                local bdb = GetCurrentBarDB()
                if bdb then
                    bdb.TextPositions = bdb.TextPositions or {}
                    bdb.TextPositions.ChargeYOffset = val
                end
                ApplyBarSettings()
            end
        })
        row4b:AddWidget(chargeY, 0.33)
        table_insert(allWidgets, chargeY)
        table_insert(barWidgets, chargeY)
        card4:AddRow(row4b, 40)

        -- Separator
        local row4sep2 = GUIFrame:CreateRow(card4.content, 8)
        row4sep2:AddWidget(GUIFrame:CreateSeparator(row4sep2), 1)
        card4:AddRow(row4sep2, 8)

        -- Macro Position
        local row4c = GUIFrame:CreateRow(card4.content, 40)
        local macroAnchor = GUIFrame:CreateDropdown(row4c, "Macro Anchor", {
            options = ANCHOR_OPTIONS,
            value = tp.MacroAnchor or "BOTTOM",
            labelWidth = 80,
            callback = function(key)
                local bdb = GetCurrentBarDB()
                if bdb then
                    bdb.TextPositions = bdb.TextPositions or {}
                    bdb.TextPositions.MacroAnchor = key
                end
                ApplyBarSettings()
            end
        })
        row4c:AddWidget(macroAnchor, 0.34)
        table_insert(allWidgets, macroAnchor)
        table_insert(barWidgets, macroAnchor)

        local macroX = GUIFrame:CreateSlider(row4c, "X", {
            min = -20, max = 20, step = 1,
            value = tp.MacroXOffset or 0,
            labelWidth = 30,
            callback = function(val)
                local bdb = GetCurrentBarDB()
                if bdb then
                    bdb.TextPositions = bdb.TextPositions or {}
                    bdb.TextPositions.MacroXOffset = val
                end
                ApplyBarSettings()
            end
        })
        row4c:AddWidget(macroX, 0.33)
        table_insert(allWidgets, macroX)
        table_insert(barWidgets, macroX)

        local macroY = GUIFrame:CreateSlider(row4c, "Y", {
            min = -20, max = 20, step = 1,
            value = tp.MacroYOffset or -2,
            labelWidth = 30,
            callback = function(val)
                local bdb = GetCurrentBarDB()
                if bdb then
                    bdb.TextPositions = bdb.TextPositions or {}
                    bdb.TextPositions.MacroYOffset = val
                end
                ApplyBarSettings()
            end
        })
        row4c:AddWidget(macroY, 0.33)
        table_insert(allWidgets, macroY)
        table_insert(barWidgets, macroY)
        card4:AddRow(row4c, 40)

        yOffset = yOffset + card4:GetContentHeight() + Theme.paddingSmall
    end

    UpdateAllWidgetStates()
    yOffset = yOffset - (Theme.paddingSmall * 2)
    return yOffset
end

----------------------------------------------------------------
-- Sub-Tab: Backdrop Settings
----------------------------------------------------------------
local function RenderBackdropTab(scrollChild, yOffset, activeCards)
    local db = GetActionBarsDB()
    if not db then return yOffset end

    local curEdit = GetCurrentBarKey()
    local barDB = GetCurrentBarDB()

    ----------------------------------------------------------------
    -- Card 1: Bar Selection
    ----------------------------------------------------------------
    local card1 = GUIFrame:CreateCard(scrollChild, "Select Bar", yOffset)
    table_insert(activeCards, card1)
    table_insert(allWidgets, card1)

    local row1 = GUIFrame:CreateRow(card1.content, 40)
    local barDropdown = GUIFrame:CreateDropdown(row1, "Select Bar to Edit", {
        options = BAR_LIST_KV,
        value = curEdit,
        callback = function(key)
            db.currentEdit = key
            C_Timer.After(0.2, function()
                GUIFrame:RefreshContent()
            end)
        end
    })
    row1:AddWidget(barDropdown, 1)
    table_insert(allWidgets, barDropdown)
    card1:AddRow(row1, 40)

    yOffset = yOffset + card1:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 2: Backdrop Settings
    ----------------------------------------------------------------
    local card2 = GUIFrame:CreateCard(scrollChild,
        "Backdrop: " .. "|cffFFFFFF" .. (BAR_LIST_KV[curEdit] or curEdit) .. "|r", yOffset)
    table_insert(activeCards, card2)
    table_insert(allWidgets, card2)
    table_insert(barWidgets, card2)

    -- Hide Empty Backdrops
    local row2a = GUIFrame:CreateRow(card2.content, 36)
    local hideEmptyCheck = GUIFrame:CreateCheckbox(row2a, "Hide Empty Backdrops", {
        value = barDB and barDB.HideEmptyBackdrops == true,
        callback = function(checked)
            local bdb = GetCurrentBarDB()
            if bdb then bdb.HideEmptyBackdrops = checked end
            ApplyBarSettings()
        end
    })
    row2a:AddWidget(hideEmptyCheck, 1)
    table_insert(allWidgets, hideEmptyCheck)
    table_insert(barWidgets, hideEmptyCheck)
    card2:AddRow(row2a, 36)

    -- Separator
    local row2sep = GUIFrame:CreateRow(card2.content, 8)
    row2sep:AddWidget(GUIFrame:CreateSeparator(row2sep), 1)
    card2:AddRow(row2sep, 8)

    -- Backdrop Color
    local row2b = GUIFrame:CreateRow(card2.content, 39)
    local backdropColor = GUIFrame:CreateColorPicker(row2b, "Backdrop Color", {
        color = barDB and barDB.BackdropColor or { 0, 0, 0, 0.8 },
        callback = function(r, g, b, a)
            local bdb = GetCurrentBarDB()
            if bdb then bdb.BackdropColor = { r, g, b, a } end
            ApplyBarSettings()
        end
    })
    row2b:AddWidget(backdropColor, 0.5)
    table_insert(allWidgets, backdropColor)
    table_insert(barWidgets, backdropColor)

    -- Border Color
    local borderColor = GUIFrame:CreateColorPicker(row2b, "Border Color", {
        color = barDB and barDB.BorderColor or { 0, 0, 0, 1 },
        callback = function(r, g, b, a)
            local bdb = GetCurrentBarDB()
            if bdb then bdb.BorderColor = { r, g, b, a } end
            ApplyBarSettings()
        end
    })
    row2b:AddWidget(borderColor, 0.5)
    table_insert(allWidgets, borderColor)
    table_insert(barWidgets, borderColor)
    card2:AddRow(row2b, 39)

    yOffset = yOffset + card2:GetContentHeight() + Theme.paddingSmall

    UpdateAllWidgetStates()
    yOffset = yOffset - (Theme.paddingSmall * 2)
    return yOffset
end

----------------------------------------------------------------
-- Create ActionBars Panel (with secondary tab bar)
----------------------------------------------------------------
local function CreateActionBarsPanel(container)
    local db = GetActionBarsDB()

    -- Check for pending context from EditMode navigation
    if GUIFrame.pendingContext and db then
        local contextBar = GUIFrame.pendingContext
        -- Validate that the context is a valid bar key
        if BAR_LIST_KV[contextBar] then
            db.currentEdit = contextBar
            -- Switch to position tab since that's where per-bar settings are
            currentSubTab = "position"
        end
        -- Clear the pending context so it doesn't persist
        GUIFrame.pendingContext = nil
    end

    -- Forward reference for tabPanel
    local tabPanel

    -- Render content for selected tab
    local function RenderContent(tabId)
        if not tabPanel then return end

        -- Clear widget tracking tables
        wipe(allWidgets)
        wipe(barWidgets)

        -- Clear panel content
        tabPanel:ClearContent()

        local scrollChild = tabPanel.scrollChild
        local yOffset = Theme.paddingMedium

        -- Collect cards for width updates
        local activeCards = {}

        -- Render selected tab content
        if tabId == "global" then
            yOffset = RenderGlobalTab(scrollChild, yOffset, activeCards)
        elseif tabId == "position" then
            yOffset = RenderPositionTab(scrollChild, yOffset, activeCards)
        elseif tabId == "text" then
            yOffset = RenderTextTab(scrollChild, yOffset, activeCards)
        elseif tabId == "backdrop" then
            yOffset = RenderBackdropTab(scrollChild, yOffset, activeCards)
        end

        -- Register cards for width updates
        for _, card in ipairs(activeCards) do
            tabPanel:RegisterCard(card)
        end

        -- Update scroll child height
        tabPanel:SetContentHeight(yOffset + Theme.paddingLarge)

        UpdateAllWidgetStates()
    end

    -- Create sub-tab panel using the widget
    tabPanel = NRSKNUI.GUI.CreateSubTabPanel(container, SUB_TABS, {
        tabBarHeight = TAB_BAR_HEIGHT,
        defaultTab = currentSubTab,
        onTabChanged = function(tabId)
            currentSubTab = tabId
            RenderContent(tabId)
        end
    })

    -- Render initial content
    RenderContent(currentSubTab)

    return tabPanel.panel
end

----------------------------------------------------------------
-- Register Panel (full control of content area)
----------------------------------------------------------------
GUIFrame:RegisterPanel("ActionBars", CreateActionBarsPanel)
