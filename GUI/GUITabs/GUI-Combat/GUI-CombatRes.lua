---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local ipairs = ipairs
local table_insert = table.insert

GUIFrame:RegisterContent("battleRes", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.BattleRes
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type CombatRes?
    local CR = NorskenUI and NorskenUI:GetModule("CombatRes", true)
    local manager = GUIFrame:CreateWidgetStateManager()
    local postUpdateCallbacks = {}
    local backdropSubWidgets = {}

    local function ApplySettings()
        if CR and CR.ApplySettings then CR:ApplySettings() end
    end

    local function UpdateBackdropState()
        local backdropEnabled = db.Backdrop.Enabled == true
        for _, widget in ipairs(backdropSubWidgets) do
            if widget.SetEnabled then widget:SetEnabled(backdropEnabled) end
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

    local card1 = GUIFrame:CreateCard(scrollChild, "Battle Res Tracker", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Combat Res Tracker", {
        value = db.Enabled ~= false,
        callback = function(checked)
            db.Enabled = checked
            if CR then
                CR.db.Enabled = checked
                if checked then NorskenUI:EnableModule("CombatRes") else NorskenUI:DisableModule("CombatRes") end
            end
            UpdateAllWidgetStates()
        end,
        msgPopup = true,
        msgText = "Combat Res Tracker",
        msgOn = "On",
        msgOff = "Off"
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, Theme.rowHeightLast, 0)
    yOffset = card1:GetNextOffset()

    local positionCard
    positionCard, yOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        db = db,
        showAnchorFrameType = true,
        showStrata = true,
        onChangeCallback = ApplySettings,
    })
    if positionCard.positionWidgets then
        manager:RegisterGroup(positionCard.positionWidgets, "all")
    end

    local fontCard, fontWidgets
    fontCard, yOffset, fontWidgets = GUIFrame:CreateFontSettingsCard(scrollChild, yOffset, {
        db = db,
        includeSoftOutline = true,
        onChangeCallback = ApplySettings,
    })
    manager:Register(fontCard, "all")
    manager:RegisterGroup(fontWidgets, "all")
    if fontCard.UpdateShadowState then table_insert(postUpdateCallbacks, fontCard.UpdateShadowState) end

    local card4 = GUIFrame:CreateCard(scrollChild, "Text Settings", yOffset)

    local row4a = GUIFrame:CreateRow(card4.content, Theme.rowHeight)
    local sepInput = GUIFrame:CreateEditBox(row4a, "Separator", {
        value = db.Separator,
        callback = function(val)
            db.Separator = val
            ApplySettings()
        end
    })
    row4a:AddWidget(sepInput, 0.5)
    manager:Register(sepInput, "all")

    local sepChargeInput = GUIFrame:CreateEditBox(row4a, "Charge Separator", {
        value = db.SeparatorCharges,
        callback = function(val)
            db.SeparatorCharges = val
            ApplySettings()
        end
    })
    row4a:AddWidget(sepChargeInput, 0.5)
    manager:Register(sepChargeInput, "all")
    card4:AddRow(row4a, Theme.rowHeight)

    local row4b = GUIFrame:CreateRow(card4.content, Theme.rowHeight)
    local spacingSlider = GUIFrame:CreateSlider(row4b, "Text Spacing", {
        min = 0,
        max = 20,
        step = 1,
        value = db.TextSpacing,
        labelWidth = 80,
        callback = function(val)
            db.TextSpacing = val
            ApplySettings()
        end
    })
    row4b:AddWidget(spacingSlider, 0.5)
    manager:Register(spacingSlider, "all")

    local growthList = {
        { key = "LEFT",  text = "Left" },
        { key = "RIGHT", text = "Right" },
    }
    local growthDropdown = GUIFrame:CreateDropdown(row4b, "Growth Direction", {
        options = growthList,
        value = db.GrowthDirection,
        callback = function(key)
            db.GrowthDirection = key
            ApplySettings()
        end
    })
    row4b:AddWidget(growthDropdown, 0.5)
    manager:Register(growthDropdown, "all")
    card4:AddRow(row4b, Theme.rowHeight)

    local row4sep = GUIFrame:CreateRow(card4.content, Theme.rowHeightSeparator)
    local sep4 = GUIFrame:CreateSeparator(row4sep)
    row4sep:AddWidget(sep4, 1)
    manager:Register(sep4, "all")
    card4:AddRow(row4sep, Theme.rowHeightSeparator)

    local row4c = GUIFrame:CreateRow(card4.content, Theme.rowHeight)
    local sepColor = GUIFrame:CreateColorPicker(row4c, "Separator Color", {
        color = db.SeparatorColor,
        callback = function(r, g, b, a)
            db.SeparatorColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row4c:AddWidget(sepColor, 0.5)
    manager:Register(sepColor, "all")

    local timerColor = GUIFrame:CreateColorPicker(row4c, "Timer Color", {
        color = db.TimerColor,
        callback = function(r, g, b, a)
            db.TimerColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row4c:AddWidget(timerColor, 0.5)
    manager:Register(timerColor, "all")
    card4:AddRow(row4c, Theme.rowHeight)

    local row4d = GUIFrame:CreateRow(card4.content, Theme.rowHeightLast)
    local chargeAvailColor = GUIFrame:CreateColorPicker(row4d, "Charges Available", {
        color = db.ChargeAvailableColor,
        callback = function(r, g, b, a)
            db.ChargeAvailableColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row4d:AddWidget(chargeAvailColor, 0.5)
    manager:Register(chargeAvailColor, "all")

    local chargeUnavailColor = GUIFrame:CreateColorPicker(row4d, "Charges Unavailable", {
        color = db.ChargeUnavailableColor,
        callback = function(r, g, b, a)
            db.ChargeUnavailableColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row4d:AddWidget(chargeUnavailColor, 0.5)
    manager:Register(chargeUnavailColor, "all")
    card4:AddRow(row4d, Theme.rowHeightLast, 0)
    yOffset = card4:GetNextOffset()

    local card5 = GUIFrame:CreateCard(scrollChild, "Backdrop Settings", yOffset)
    manager:Register(card5, "all")
    table_insert(postUpdateCallbacks, UpdateBackdropState)

    local row5a = GUIFrame:CreateRow(card5.content, Theme.rowHeight)
    local backdropCheck = GUIFrame:CreateCheckbox(row5a, "Enable Backdrop", {
        value = db.Backdrop.Enabled == true,
        callback = function(checked)
            db.Backdrop.Enabled = checked
            ApplySettings()
            UpdateBackdropState()
        end
    })
    row5a:AddWidget(backdropCheck, (1 / 3))
    manager:Register(backdropCheck, "all")

    local bgColor = GUIFrame:CreateColorPicker(row5a, "Background", {
        color = db.Backdrop.Color,
        callback = function(r, g, b, a)
            db.Backdrop.Color = { r, g, b, a }
            ApplySettings()
        end
    })
    row5a:AddWidget(bgColor, (1 / 3))
    manager:Register(bgColor, "all")
    table_insert(backdropSubWidgets, bgColor)

    local borderColor = GUIFrame:CreateColorPicker(row5a, "Border", {
        color = db.Backdrop.BorderColor,
        callback = function(r, g, b, a)
            db.Backdrop.BorderColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row5a:AddWidget(borderColor, (1 / 3))
    manager:Register(borderColor, "all")
    table_insert(backdropSubWidgets, borderColor)
    card5:AddRow(row5a, Theme.rowHeight)

    local row5b = GUIFrame:CreateRow(card5.content, Theme.rowHeightLast)
    local frameWidthSlider = GUIFrame:CreateSlider(row5b, "Width", {
        min = 50,
        max = 300,
        step = 1,
        value = db.Backdrop.FrameWidth,
        labelWidth = 60,
        callback = function(val)
            db.Backdrop.FrameWidth = val
            ApplySettings()
        end
    })
    row5b:AddWidget(frameWidthSlider, 0.5)
    manager:Register(frameWidthSlider, "all")
    table_insert(backdropSubWidgets, frameWidthSlider)

    local frameHeightSlider = GUIFrame:CreateSlider(row5b, "Height", {
        min = 16,
        max = 100,
        step = 1,
        value = db.Backdrop.FrameHeight,
        labelWidth = 60,
        callback = function(val)
            db.Backdrop.FrameHeight = val
            ApplySettings()
        end
    })
    row5b:AddWidget(frameHeightSlider, 0.5)
    manager:Register(frameHeightSlider, "all")
    table_insert(backdropSubWidgets, frameHeightSlider)
    card5:AddRow(row5b, Theme.rowHeightLast, 0)
    yOffset = card5:GetNextOffset()

    UpdateAllWidgetStates()
    return yOffset
end)
