-- NorskenUI namespace
---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme
local LSM = NRSKNUI.LSM
local DUR = NorskenUI:GetModule("Durability", true)

-- Localization Setup
local table_insert = table.insert
local ipairs, pairs = ipairs, pairs
local wipe = wipe
local CreateFrame = CreateFrame

-- Store current sub-tab
local currentSubTab = "general"

-- Sub-tab definitions
local SUB_TABS = {
    { id = "general",     text = "General" },
    { id = "datatext",    text = "Data Text" },
    { id = "warningtext", text = "Repair Now Text" },
}

-- Tab bar height constant
local TAB_BAR_HEIGHT = 28

-- Track widgets for enable/disable logic
local allWidgets = {} -- All widgets (except main toggle)
local customColorWidgets = {}
local warningWidgets = {}
local textWidgets = {}

-- Apply Durability settings
local function ApplySettings()
    if DUR then
        DUR:ApplySettings()
    end
end

local function ApplyFonts()
    if DUR then
        DUR:UpdateFonts()
    end
end

-- Helper to apply new state
local function ApplyDurabilityState(enabled)
    if not DUR then return end
    DUR.db.Enabled = enabled
    if enabled then
        NorskenUI:EnableModule("Durability")
    else
        NorskenUI:DisableModule("Durability")
    end
end

-- Comprehensive widget state update
local function UpdateAllWidgetStates()
    local db = NRSKNUI.db and NRSKNUI.db.profile.Miscellaneous.Durability
    if not db then return end
    local mainEnabled = db.Enabled ~= false
    local warningEnabled = db.WarningText and db.WarningText.Enabled ~= false
    local textEnabled = db.Text and db.Text.Enabled ~= false
    local ccEnabled = textEnabled and db.Text.UseStatusColor == false

    -- Apply main enable state to ALL widgets
    for _, widget in ipairs(allWidgets) do
        if widget.SetEnabled then
            widget:SetEnabled(mainEnabled)
        end
    end

    if mainEnabled then
        for _, widget in ipairs(customColorWidgets) do
            if widget.SetEnabled then
                widget:SetEnabled(ccEnabled)
            end
        end

        for _, widget in ipairs(warningWidgets) do
            if widget.SetEnabled then
                widget:SetEnabled(warningEnabled)
            end
        end

        for _, widget in ipairs(textWidgets) do
            if widget.SetEnabled then
                widget:SetEnabled(textEnabled)
            end
        end
    end
end

-- Sub tab 1, general settings
local function RenderGeneralTab(scrollChild, yOffset, activeCards)
    local db = NRSKNUI.db and NRSKNUI.db.profile.Miscellaneous.Durability
    if not db then return yOffset end

    ----------------------------------------------------------------
    -- Card 1: Durability Util Overview
    ----------------------------------------------------------------
    local card1 = GUIFrame:CreateCard(scrollChild, "Durability Util", yOffset)
    table_insert(activeCards, card1)

    -- Enable Checkbox
    local row1 = GUIFrame:CreateRow(card1.content, 40)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Durability Util", {
        value = db.Enabled ~= false,
        callback = function(checked)
            db.Enabled = checked
            ApplyDurabilityState(checked)
            UpdateAllWidgetStates()
        end,
        msgPopup = true, msgText = "Durability Util", msgOn = "On", msgOff = "Off"
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, 40)

    -- Separator
    local row1sep = GUIFrame:CreateRow(card1.content, 8)
    local sepCBCard = GUIFrame:CreateSeparator(row1sep)
    row1sep:AddWidget(sepCBCard, 1)
    table_insert(allWidgets, sepCBCard)
    card1:AddRow(row1sep, 8)

    -- Enable Checkbox
    local row1b = GUIFrame:CreateRow(card1.content, 36)
    local enabledWarningText = GUIFrame:CreateCheckbox(row1b, "Enable Repair Now Warning", {
        value = db.WarningText.Enabled ~= false,
        callback = function(checked)
            db.WarningText.Enabled = checked
            ApplySettings()
        end
    })
    row1b:AddWidget(enabledWarningText, 0.5)
    table_insert(allWidgets, enabledWarningText)

    local enabledText = GUIFrame:CreateCheckbox(row1b, "Enable Data Text", {
        value = db.Text.Enabled ~= false,
        callback = function(checked)
            db.Text.Enabled = checked
            ApplySettings()
        end
    })
    row1b:AddWidget(enabledText, 0.5)
    table_insert(allWidgets, enabledText)
    card1:AddRow(row1b, 36)

    yOffset = yOffset + card1:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 2: Font Settings
    ----------------------------------------------------------------
    local card2 = GUIFrame:CreateCard(scrollChild, "General Font Settings", yOffset)
    table_insert(allWidgets, card2)
    table_insert(activeCards, card2)

    -- Font lookup
    local fontList = {}
    if LSM then
        for name in pairs(LSM:HashTable("font")) do fontList[name] = name end
    else
        fontList["Friz Quadrata TT"] = "Friz Quadrata TT"
    end

    -- Font Face and Outline Dropdowns
    local row2 = GUIFrame:CreateRow(card2.content, 40)
    local fontDropdown = GUIFrame:CreateDropdown(row2, "Font", {
        options = fontList,
        value = db.FontFace or "Friz Quadrata TT",
        callback = function(key)
            db.FontFace = key
            ApplyFonts()
        end,
        searchable = true,
        isFontPreview = true
    })
    row2:AddWidget(fontDropdown, 0.5)
    table_insert(allWidgets, fontDropdown)

    local outlineList = {
        { key = "NONE",         text = "None" },
        { key = "OUTLINE",      text = "Outline" },
        { key = "THICKOUTLINE", text = "Thick" },
        { key = "SOFTOUTLINE",  text = "Soft" },
    }
    local outlineDropdown = GUIFrame:CreateDropdown(row2, "Outline", {
        options = outlineList,
        value = db.FontOutline or "OUTLINE",
        callback = function(key)
            db.FontOutline = key
            ApplyFonts()
        end
    })
    row2:AddWidget(outlineDropdown, 0.5)
    table_insert(allWidgets, outlineDropdown)
    card2:AddRow(row2, 40)

    yOffset = yOffset + card2:GetContentHeight() + Theme.paddingSmall

    -- Apply initial widget states
    yOffset = yOffset - (Theme.paddingSmall)
    UpdateAllWidgetStates()
    return yOffset
end

-- Sub tab 2, data text
local function RenderDataTextTab(scrollChild, yOffset, activeCards)
    local db = NRSKNUI.db and NRSKNUI.db.profile.Miscellaneous.Durability
    if not db then return yOffset end
    local DT = db.Text

    ----------------------------------------------------------------
    -- Card 1: General Settings
    ----------------------------------------------------------------
    local card1 = GUIFrame:CreateCard(scrollChild, "General Settings", yOffset)
    table_insert(activeCards, card1)
    table_insert(allWidgets, card1)
    table_insert(textWidgets, card1)

    local red = NRSKNUI:ColorText("25%", { 1, 0, 0 })
    local orange = NRSKNUI:ColorText("50%", { 1, 0.42, 0 })
    local yellow = NRSKNUI:ColorText("75%", { 1, 0.82, 0 })
    local green = NRSKNUI:ColorText("100%", { 0, 1, 0 })
    local statusColorEx = "Use Status Color: " .. red .. " / " .. orange .. " / " .. yellow .. " / " .. green

    -- Use status coloring
    local row1 = GUIFrame:CreateRow(card1.content, 40)
    local statusColor = GUIFrame:CreateCheckbox(row1, statusColorEx, {
        value = DT.UseStatusColor ~= false,
        callback = function(checked)
            DT.UseStatusColor = checked
            ApplySettings()
            UpdateAllWidgetStates()
        end
    })
    row1:AddWidget(statusColor, 0.5)
    table_insert(allWidgets, statusColor)
    table_insert(textWidgets, statusColor)

    local DTcolor = GUIFrame:CreateColorPicker(row1, "Static Color", {
        color = DT.Color,
        callback = function(r, g, b, a)
            DT.Color = { r, g, b, a }
            ApplySettings()
        end
    })
    row1:AddWidget(DTcolor, 0.5)
    table_insert(allWidgets, DTcolor)
    table_insert(customColorWidgets, DTcolor)
    card1:AddRow(row1, 40)

    local row1a = GUIFrame:CreateRow(card1.content, 39)
    local DurText = GUIFrame:CreateEditBox(row1a, "Prefix", {
        value = DT.DurText,
        callback = function(val)
            DT.DurText = val
            ApplySettings()
        end
    })
    row1a:AddWidget(DurText, 0.5)
    table_insert(allWidgets, DurText)
    table_insert(textWidgets, DurText)

    local Durcolor = GUIFrame:CreateColorPicker(row1a, "Prefix Color", {
        color = DT.DurColor,
        callback = function(r, g, b, a)
            DT.DurColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row1a:AddWidget(Durcolor, 0.5)
    table_insert(allWidgets, Durcolor)
    table_insert(textWidgets, Durcolor)
    card1:AddRow(row1a, 39)

    -- Separator
    local row1sep = GUIFrame:CreateRow(card1.content, 8)
    local sepCBCard = GUIFrame:CreateSeparator(row1sep)
    row1sep:AddWidget(sepCBCard, 1)
    table_insert(allWidgets, sepCBCard)
    table_insert(textWidgets, sepCBCard)
    card1:AddRow(row1sep, 8)

    -- Font Size
    local row2 = GUIFrame:CreateRow(card1.content, 36)
    local fontSizeSlider = GUIFrame:CreateSlider(row2, "Font Size", {
        min = 6,
        max = 80,
        step = 1,
        value = DT.FontSize,
        labelWidth = 60,
        callback = function(val)
            DT.FontSize = val
            ApplyFonts()
        end
    })
    row2:AddWidget(fontSizeSlider, 1)
    table_insert(allWidgets, fontSizeSlider)
    table_insert(textWidgets, fontSizeSlider)
    card1:AddRow(row2, 36)

    yOffset = yOffset + card1:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 2: Position Settings (using reusable position card)
    ----------------------------------------------------------------
    local card2, newOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        db = db.Text,
        showAnchorFrameType = true,
        showStrata = true,
        onChangeCallback = ApplySettings,
    })
    -- Add position card widgets to allWidgets for enable/disable
    if card2.positionWidgets then
        for _, widget in ipairs(card2.positionWidgets) do
            table_insert(allWidgets, widget)
        end
    end
    table_insert(allWidgets, card2)
    table_insert(textWidgets, card2)
    yOffset = newOffset

    UpdateAllWidgetStates()
    yOffset = yOffset - (Theme.paddingSmall)
    return yOffset
end

-- Sub tab 3, warning text
local function RenderWarningTextTab(scrollChild, yOffset, activeCards)
    local db = NRSKNUI.db and NRSKNUI.db.profile.Miscellaneous.Durability
    if not db then return yOffset end
    local WT = db.WarningText

    ----------------------------------------------------------------
    -- Card 1: General Settings
    ----------------------------------------------------------------
    local card1 = GUIFrame:CreateCard(scrollChild, "General Settings", yOffset)
    table_insert(activeCards, card1)
    table_insert(allWidgets, card1)
    table_insert(warningWidgets, card1)

    -- Use status coloring
    local row1 = GUIFrame:CreateRow(card1.content, 40)
    local WarningText = GUIFrame:CreateEditBox(row1, "Low Durability Text", {
        value = WT.WarningText,
        callback = function(val)
            WT.WarningText = val
            ApplySettings()
        end
    })
    row1:AddWidget(WarningText, 0.5)
    table_insert(allWidgets, WarningText)
    table_insert(warningWidgets, WarningText)

    local WTcolor = GUIFrame:CreateColorPicker(row1, "Color", {
        color = WT.WarningColor or { 0, 0, 0, 0.6 },
        callback = function(r, g, b, a)
            WT.WarningColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row1:AddWidget(WTcolor, 0.5)
    table_insert(allWidgets, WTcolor)
    table_insert(warningWidgets, WTcolor)
    card1:AddRow(row1, 40)

    local row1a = GUIFrame:CreateRow(card1.content, 40)
    local ShowPercent = GUIFrame:CreateSlider(row1a, "|cff4dff00Out of Combat|r Durability % Trigger", {
        min = 1,
        max = 100,
        step = 1,
        value = WT.ShowPercent,
        labelWidth = 60,
        callback = function(val)
            WT.ShowPercent = val
            ApplyFonts()
        end
    })
    row1a:AddWidget(ShowPercent, 0.5)
    table_insert(allWidgets, ShowPercent)
    table_insert(warningWidgets, ShowPercent)

    local CombatShowPercent = GUIFrame:CreateSlider(row1a, "|cffff0000In Combat|r Durability % Trigger", {
        min = 0,
        max = 100,
        step = 1,
        value = WT.CombatShowPercent,
        labelWidth = 60,
        callback = function(val)
            WT.CombatShowPercent = val
            ApplyFonts()
        end
    })
    row1a:AddWidget(CombatShowPercent, 0.5)
    table_insert(allWidgets, CombatShowPercent)
    table_insert(warningWidgets, CombatShowPercent)
    card1:AddRow(row1a, 40)

    -- Separator
    local row1sep = GUIFrame:CreateRow(card1.content, 8)
    local sepCBCard = GUIFrame:CreateSeparator(row1sep)
    row1sep:AddWidget(sepCBCard, 1)
    table_insert(allWidgets, sepCBCard)
    table_insert(warningWidgets, sepCBCard)
    card1:AddRow(row1sep, 8)

    -- Font Size
    local row2 = GUIFrame:CreateRow(card1.content, 36)
    local fontSizeSlider = GUIFrame:CreateSlider(row2, "Font Size", {
        min = 6,
        max = 80,
        step = 1,
        value = WT.FontSize,
        labelWidth = 60,
        callback = function(val)
            WT.FontSize = val
            ApplyFonts()
        end
    })
    row2:AddWidget(fontSizeSlider, 1)
    table_insert(allWidgets, fontSizeSlider)
    table_insert(warningWidgets, fontSizeSlider)
    card1:AddRow(row2, 36)

    yOffset = yOffset + card1:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 2: Position Settings (using reusable position card)
    ----------------------------------------------------------------
    local card2, newOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        db = db.WarningText,
        showAnchorFrameType = false,
        showStrata = true,
        onChangeCallback = ApplySettings,
    })
    -- Add position card widgets to allWidgets for enable/disable
    if card2.positionWidgets then
        for _, widget in ipairs(card2.positionWidgets) do
            table_insert(allWidgets, widget)
        end
    end
    table_insert(allWidgets, card2)
    table_insert(warningWidgets, card2)
    yOffset = newOffset

    UpdateAllWidgetStates()
    yOffset = yOffset - (Theme.paddingSmall)
    return yOffset
end

----------------------------------------------------------------
-- Create Durability Panel
----------------------------------------------------------------
local function CreateDurabilityPanel(container)
    -- Forward reference for tabPanel
    local tabPanel

    -- Render content for selected tab
    local function RenderContent(tabId)
        if not tabPanel then return end

        -- Clear widget tracking tables
        wipe(allWidgets)
        wipe(customColorWidgets)
        wipe(warningWidgets)
        wipe(textWidgets)

        -- Clear panel content
        tabPanel:ClearContent()

        local scrollChild = tabPanel.scrollChild
        local yOffset = Theme.paddingMedium

        -- Collect cards for width updates
        local activeCards = {}

        -- Render selected tab content
        if tabId == "general" then
            yOffset = RenderGeneralTab(scrollChild, yOffset, activeCards)
        elseif tabId == "datatext" then
            yOffset = RenderDataTextTab(scrollChild, yOffset, activeCards)
        elseif tabId == "warningtext" then
            yOffset = RenderWarningTextTab(scrollChild, yOffset, activeCards)
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
GUIFrame:RegisterPanel("Durability", CreateDurabilityPanel)
