---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local GetNumSpecializations = GetNumSpecializations
local GetSpecializationInfo = GetSpecializationInfo
local GetSpecialization = GetSpecialization

GUIFrame:RegisterContent("SpellAlert", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.Miscellaneous.SpellAlert
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type SpellAlert?
    local SA = NRSKNUI:GetModule("SpellAlert", true)
    local manager = GUIFrame:CreateWidgetStateManager()

    local function ApplySettings() if SA then SA:ApplySettings() end end
    local function UpdateAllWidgetStates() manager:UpdateAll(db.Enabled) end

    local selectedSpecID = nil
    local scaleSlider, alphaSlider, specDropdown

    local function GetSpecOptions()
        local options = {}
        local numSpecs = GetNumSpecializations()
        for i = 1, numSpecs do
            local specID, specName = GetSpecializationInfo(i)
            if specID and specName then
                table.insert(options, { key = specID, text = specName })
            end
        end
        return options
    end

    local function GetCurrentSpecID()
        local specIndex = GetSpecialization()
        if not specIndex then return nil end
        local specID = GetSpecializationInfo(specIndex)
        return specID
    end

    local function EnsureSpecEntry(specID)
        if not specID then return end
        if not db.Specs[specID] then
            db.Specs[specID] = {
                Scale = db.Global.Scale,
                Alpha = db.Global.Alpha,
            }
        end
    end

    local function GetCurrentValues()
        if db.UseGlobal then
            return db.Global.Scale, db.Global.Alpha
        else
            if selectedSpecID then
                EnsureSpecEntry(selectedSpecID)
                return db.Specs[selectedSpecID].Scale, db.Specs[selectedSpecID].Alpha
            end
            return db.Global.Scale, db.Global.Alpha
        end
    end

    local function SetCurrentValues(scale, alpha)
        if db.UseGlobal then
            if scale then db.Global.Scale = scale end
            if alpha then db.Global.Alpha = alpha end
        else
            if selectedSpecID then
                EnsureSpecEntry(selectedSpecID)
                if scale then db.Specs[selectedSpecID].Scale = scale end
                if alpha then db.Specs[selectedSpecID].Alpha = alpha end
            end
        end
        ApplySettings()
    end

    local function RefreshSliders()
        local scale, alpha = GetCurrentValues()
        if scaleSlider and scaleSlider.SetValue then scaleSlider:SetValue(scale) end
        if alphaSlider and alphaSlider.SetValue then alphaSlider:SetValue(alpha) end
    end

    -- Card 1: Enable
    local card1 = GUIFrame:CreateCard(scrollChild, "Spell Alert Overlay", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Spell Alert Overlay", {
        value = db.Enabled,
        callback = function(checked)
            db.Enabled = checked
            if SA then
                if checked then NRSKNUI:EnableModule("SpellAlert") else NRSKNUI:DisableModule("SpellAlert") end
            end
            UpdateAllWidgetStates()
        end,
        msgPopup = true,
        msgText = "Spell Alert Overlay",
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, Theme.rowHeightLast, 0)

    yOffset = card1:GetNextOffset()

    -- Card 2: Settings
    local card2 = GUIFrame:CreateCard(scrollChild, "Settings", yOffset)
    manager:Register(card2, "all")

    local specOptions = GetSpecOptions()
    local hasSpecs = #specOptions > 0

    if hasSpecs then
        selectedSpecID = GetCurrentSpecID() or specOptions[1].key
        EnsureSpecEntry(selectedSpecID)
    end

    local row2a = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local perSpecCheck = GUIFrame:CreateCheckbox(row2a, "Use Per-Spec Settings", {
        value = not db.UseGlobal,
        callback = function(checked)
            db.UseGlobal = not checked
            ApplySettings()
            RefreshSliders()
            UpdateAllWidgetStates()
        end,
    })
    row2a:AddWidget(perSpecCheck, 0.5)
    manager:Register(perSpecCheck, "all")

    if hasSpecs then
        specDropdown = GUIFrame:CreateDropdown(row2a, "Spec", {
            options = specOptions,
            value = selectedSpecID,
            callback = function(key)
                selectedSpecID = key
                EnsureSpecEntry(selectedSpecID)
                RefreshSliders()
            end,
        })
        row2a:AddWidget(specDropdown, 0.5)
        manager:Register(specDropdown, "all")
        card2:AddRow(row2a, Theme.rowHeight)
    end

    local separator2 = GUIFrame:CreateSeparator(card2.content)
    card2:AddRow(separator2, Theme.rowHeightSeparator)

    local currentScale, currentAlpha = GetCurrentValues()

    local row2c = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    scaleSlider = GUIFrame:CreateSlider(row2c, "Scale", {
        min = 0.1,
        max = 3.0,
        step = 0.05,
        value = currentScale,
        callback = function(value)
            SetCurrentValues(value, nil)
        end,
    })
    row2c:AddWidget(scaleSlider, 0.5)
    manager:Register(scaleSlider, "all")

    alphaSlider = GUIFrame:CreateSlider(row2c, "Alpha", {
        min = 0.0,
        max = 1.0,
        step = 0.05,
        value = currentAlpha,
        callback = function(value)
            SetCurrentValues(nil, value)
        end,
    })
    row2c:AddWidget(alphaSlider, 0.5)
    manager:Register(alphaSlider, "all")
    card2:AddRow(row2c, Theme.rowHeightLast, 0)

    yOffset = card2:GetNextOffset()

    UpdateAllWidgetStates()

    return yOffset
end)
