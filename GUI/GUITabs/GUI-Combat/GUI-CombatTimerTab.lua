---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local table_insert = table.insert
local ipairs = ipairs

GUIFrame:RegisterContent("combatTimer", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.CombatTimer
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type CombatTimer?
    local CT = NorskenUI and NorskenUI:GetModule("CombatTimer", true)
    local manager = GUIFrame:CreateWidgetStateManager()
    local postUpdateCallbacks = {}
    local combatOnlyWidgets = {}

    local function UpdateCombatOnlyState()
        local enabled = not db.CombatOnly
        for _, widget in ipairs(combatOnlyWidgets) do
            if widget.SetEnabled then widget:SetEnabled(enabled) end
        end
    end

    local function UpdateAllWidgetStates()
        local mainEnabled = db.Enabled ~= false
        manager:UpdateAll(mainEnabled)
        if mainEnabled then
            for _, callback in ipairs(postUpdateCallbacks) do
                callback()
            end
        end
    end

    -- Card 1
    local card1 = GUIFrame:CreateCard(scrollChild, "Combat Timer", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeight)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Combat Timer", {
        value = db.Enabled ~= false,
        callback = function(checked)
            db.Enabled = checked
            if CT then
                CT.db.Enabled = checked
                if checked then NorskenUI:EnableModule("CombatTimer") else NorskenUI:DisableModule("CombatTimer") end
            end
            UpdateAllWidgetStates()
        end,
        msgPopup = true,
        msgText = "Combat Timer",
        msgOn = "On",
        msgOff = "Off"
    })
    row1:AddWidget(enableCheck, 0.5)

    local formatList = { ["MM:SS"] = "MM:SS", ["MM:SS:MS"] = "MM:SS:MS" }
    local formatDropdown = GUIFrame:CreateDropdown(row1, "Format", {
        options = formatList,
        value = db.Format,
        callback = function(key)
            db.Format = key
            if CT then CT:ApplySettings() end
        end
    })
    row1:AddWidget(formatDropdown, 0.5)
    manager:Register(formatDropdown, "all")
    card1:AddRow(row1, Theme.rowHeight)

    local row1sep = GUIFrame:CreateRow(card1.content, Theme.rowHeightSeparator)
    local sep1Card = GUIFrame:CreateSeparator(row1sep)
    row1sep:AddWidget(sep1Card, 1)
    manager:Register(sep1Card, "all")
    card1:AddRow(row1sep, Theme.rowHeightSeparator)

    local row1a = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
    local combatOnlyCheck = GUIFrame:CreateCheckbox(row1a, "Combat Only", {
        value = db.CombatOnly == true,
        callback = function(checked)
            db.CombatOnly = checked
            if CT then
                if CT.frame then
                    if checked and not CT.running and not CT.isPreview then
                        CT.frame:Hide()
                    elseif not checked then
                        CT.frame:Show()
                    end
                end
                CT:ApplySettings()
            end
            UpdateCombatOnlyState()
        end
    })
    row1a:AddWidget(combatOnlyCheck, 0.5)
    manager:Register(combatOnlyCheck, "all")

    local printCheck = GUIFrame:CreateCheckbox(row1a, "Print Duration to Chat", {
        value = db.PrintEnd == true,
        callback = function(checked)
            db.PrintEnd = checked
        end
    })
    row1a:AddWidget(printCheck, 0.5)
    manager:Register(printCheck, "all")
    card1:AddRow(row1a, Theme.rowHeightLast, 0)

    yOffset = card1:GetNextOffset()

    -- Card 2
    local card2, newOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        db = db,
        showAnchorFrameType = true,
        showStrata = true,
        onChangeCallback = function() if CT then CT:ApplyPosition() end end,
    })

    if card2.positionWidgets then
        manager:RegisterGroup(card2.positionWidgets, "all")
    end
    manager:Register(card2, "all")

    yOffset = newOffset

    -- Card 3
    local card3, newOffset3, fontWidgets = GUIFrame:CreateFontSettingsCard(scrollChild, yOffset, {
        db = db,
        includeSoftOutline = true,
        onChangeCallback = function() if CT then CT:ApplySettings() end end,
    })
    manager:Register(card3, "all")
    manager:RegisterGroup(fontWidgets, "all")
    if card3.UpdateShadowState then table_insert(postUpdateCallbacks, card3.UpdateShadowState) end

    yOffset = newOffset3

    -- Card 4
    local card4 = GUIFrame:CreateCard(scrollChild, "Color Settings", yOffset)
    manager:Register(card4, "all")

    local row4a = GUIFrame:CreateRow(card4.content, Theme.rowHeight)
    local inCombatColor = GUIFrame:CreateColorPicker(row4a, "In Combat Color", {
        color = db.ColorInCombat,
        callback = function(r, g, b, a)
            db.ColorInCombat = { r, g, b, a }
            if CT then CT:ApplySettings() end
        end
    })
    row4a:AddWidget(inCombatColor, 1)
    manager:Register(inCombatColor, "all")
    card4:AddRow(row4a, Theme.rowHeight)

    local row4b = GUIFrame:CreateRow(card4.content, Theme.rowHeightLast)
    local outCombatColor = GUIFrame:CreateColorPicker(row4b, "Non Combat Color", {
        color = db.ColorOutOfCombat,
        callback = function(r, g, b, a)
            db.ColorOutOfCombat = { r, g, b, a }
            if CT then CT:ApplySettings() end
        end
    })
    row4b:AddWidget(outCombatColor, 1)
    manager:Register(outCombatColor, "all")
    table_insert(combatOnlyWidgets, outCombatColor)
    table_insert(postUpdateCallbacks, UpdateCombatOnlyState)
    card4:AddRow(row4b, Theme.rowHeightLast, 0)
    yOffset = card4:GetNextOffset()

    -- Card 5
    local card5 = GUIFrame:CreateCard(scrollChild, "Backdrop Settings", yOffset)
    manager:Register(card5, "all")
    db.Backdrop = db.Backdrop or {}
    local backdropSubWidgets = {}

    local function UpdateBackdropState()
        local backdropEnabled = db.Backdrop.Enabled ~= false
        for _, widget in ipairs(backdropSubWidgets) do
            if widget.SetEnabled then
                widget:SetEnabled(backdropEnabled)
            end
        end
    end
    table_insert(postUpdateCallbacks, UpdateBackdropState)

    local row5a = GUIFrame:CreateRow(card5.content, Theme.rowHeight)
    local backdropCheck = GUIFrame:CreateCheckbox(row5a, "Enable Backdrop", {
        value = db.Backdrop.Enabled ~= false,
        callback = function(checked)
            db.Backdrop.Enabled = checked
            if CT then CT:ApplySettings() end
            UpdateBackdropState()
        end
    })
    row5a:AddWidget(backdropCheck, 1)
    manager:Register(backdropCheck, "all")
    card5:AddRow(row5a, Theme.rowHeight)

    local row5ba = GUIFrame:CreateRow(card5.content, Theme.rowHeight)
    local bgWidth = GUIFrame:CreateSlider(row5ba, "Backdrop Width", {
        min = 1,
        max = 600,
        step = 1,
        value = db.Backdrop.bgWidth,
        callback = function(val)
            db.Backdrop.bgWidth = val
            if CT then CT:ApplySettings() end
        end
    })
    row5ba:AddWidget(bgWidth, 0.4)
    manager:Register(bgWidth, "all")
    table_insert(backdropSubWidgets, bgWidth)

    local bgHeight = GUIFrame:CreateSlider(row5ba, "Backdrop Height", {
        min = 1,
        max = 600,
        step = 1,
        value = db.Backdrop.bgHeight,
        callback = function(val)
            db.Backdrop.bgHeight = val
            if CT then CT:ApplySettings() end
        end
    })
    row5ba:AddWidget(bgHeight, 0.39)
    manager:Register(bgHeight, "all")
    table_insert(backdropSubWidgets, bgHeight)

    local bgColor = GUIFrame:CreateColorPicker(row5ba, "Backdrop Color", {
        color = db.Backdrop.Color,
        callback = function(r, g, b, a)
            db.Backdrop.Color = { r, g, b, a }
            if CT then CT:ApplySettings() end
        end
    })
    row5ba:AddWidget(bgColor, 0.21)
    manager:Register(bgColor, "all")
    table_insert(backdropSubWidgets, bgColor)
    card5:AddRow(row5ba, Theme.rowHeight)

    local row5sep = GUIFrame:CreateRow(card5.content, Theme.rowHeightSeparator)
    local sepBgCard = GUIFrame:CreateSeparator(row5sep)
    row5sep:AddWidget(sepBgCard, 1)
    manager:Register(sepBgCard, "all")
    table_insert(backdropSubWidgets, sepBgCard)
    card5:AddRow(row5sep, Theme.rowHeightSeparator)

    local row5c = GUIFrame:CreateRow(card5.content, Theme.rowHeightLast)
    local borderSize = GUIFrame:CreateSlider(row5c, "Border Size", {
        min = 1,
        max = 10,
        step = 1,
        value = db.Backdrop.BorderSize,
        callback = function(val)
            db.Backdrop.BorderSize = val
            if CT then CT:ApplySettings() end
        end
    })
    row5c:AddWidget(borderSize, 0.79)
    manager:Register(borderSize, "all")
    table_insert(backdropSubWidgets, borderSize)

    local borderColor = GUIFrame:CreateColorPicker(row5c, "Border Color", {
        color = db.Backdrop.BorderColor,
        callback = function(r, g, b, a)
            db.Backdrop.BorderColor = { r, g, b, a }
            if CT then CT:ApplySettings() end
        end
    })
    row5c:AddWidget(borderColor, 0.21)
    manager:Register(borderColor, "all")
    table_insert(backdropSubWidgets, borderColor)
    card5:AddRow(row5c, Theme.rowHeightLast, 0)

    yOffset = card5:GetNextOffset()
    UpdateAllWidgetStates()

    return yOffset
end)
