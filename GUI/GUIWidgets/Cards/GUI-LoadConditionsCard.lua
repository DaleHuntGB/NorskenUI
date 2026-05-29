---@class NRSKNUI
local NRSKNUI = select(2, ...)
---@class GUIFrame
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local ipairs = ipairs
local pairs = pairs
local table_insert = table.insert

local INSTANCE_TYPES = {
    { key = "none",     label = "Open World" },
    { key = "party",    label = "Dungeon" },
    { key = "raid",     label = "Raid" },
    { key = "pvp",      label = "Battleground" },
    { key = "arena",    label = "Arena" },
    { key = "scenario", label = "Scenario" },
}

local GROUP_TYPES = {
    { key = "solo",  label = "Solo" },
    { key = "party", label = "Party" },
    { key = "raid",  label = "Raid" },
}

local function HasAnyEnabled(tbl)
    if not tbl then return false end
    for _, enabled in pairs(tbl) do
        if enabled then return true end
    end
    return false
end

local function IsCategoryActive(db, category)
    if category == "Instance" then
        return HasAnyEnabled(db.Instance and db.Instance.Types)
    elseif category == "Group" then
        return HasAnyEnabled(db.Group and db.Group.Types)
    elseif category == "Combat" then
        return (db.Combat and db.Combat.InCombat) or (db.Combat and db.Combat.OutOfCombat)
    end
    return false
end

local function GetActiveCount(db)
    local count = 0
    if IsCategoryActive(db, "Instance") then count = count + 1 end
    if IsCategoryActive(db, "Group") then count = count + 1 end
    if IsCategoryActive(db, "Combat") then count = count + 1 end
    return count
end

local GREEN = { 0, 1, 0 }
local RED = { 1, 0, 0 }

local function BuildCategoryOptions(db)
    local instanceActive = IsCategoryActive(db, "Instance")
    local groupActive = IsCategoryActive(db, "Group")
    local combatActive = IsCategoryActive(db, "Combat")

    return {
        { key = "Instance", text = "Instance", indicator = instanceActive and GREEN or RED },
        { key = "Group",    text = "Group",    indicator = groupActive and GREEN or RED },
        { key = "Combat",   text = "Combat",   indicator = combatActive and GREEN or RED },
    }
end

---Load conditions card with compact category selector
---@param scrollChild Frame
---@param yOffset number
---@param config table
---@return table card
---@return number newYOffset
function GUIFrame:CreateLoadConditionsCard(scrollChild, yOffset, config)
    config = config or {}
    local title = config.title or "Load Conditions"
    local db = config.db
    local onChange = config.onChangeCallback
    local onRefresh = config.onRefreshCallback

    db.Enabled = db.Enabled or false
    db.SelectedCategory = db.SelectedCategory or "Instance"
    db.Instance = db.Instance or { Types = {} }
    db.Group = db.Group or { Types = {} }
    db.Combat = db.Combat or {}

    local widgets = {}
    local card = GUIFrame:CreateCard(scrollChild, title, yOffset)

    local isEnabled = db.Enabled
    local selectedCategory = db.SelectedCategory

    -- Main row: Enable toggle + Category dropdown
    local mainRowHeight = isEnabled and Theme.rowHeight or Theme.rowHeightLast
    local mainRow = GUIFrame:CreateRow(card.content, mainRowHeight)

    local activeCount = GetActiveCount(db)
    local accentHex = string.format("%02x%02x%02x", Theme.accent[1] * 255, Theme.accent[2] * 255, Theme.accent[3] * 255)
    local enableLabel = activeCount > 0 and ("Enable |cff" .. accentHex .. "(" .. activeCount .. " active)|r") or
        "Enable"
    local enableToggle = GUIFrame:CreateCheckbox(mainRow, enableLabel, {
        value = isEnabled,
        callback = function(checked)
            db.Enabled = checked
            if onChange then onChange() end
            if onRefresh then onRefresh() end
        end
    })
    mainRow:AddWidget(enableToggle, 0.5)
    table_insert(widgets, enableToggle)

    if isEnabled then
        local categoryDropdown = GUIFrame:CreateDropdown(mainRow, "Category", {
            options = BuildCategoryOptions(db),
            value = selectedCategory,
            callback = function(value)
                db.SelectedCategory = value
                if onRefresh then onRefresh() end
            end
        })
        mainRow:AddWidget(categoryDropdown, 0.5)
        table_insert(widgets, categoryDropdown)
    end

    card:AddRow(mainRow, mainRowHeight, not isEnabled and 0 or nil)

    if not isEnabled then
        card.conditionWidgets = widgets
        return card, card:GetNextOffset()
    end

    local sep = GUIFrame:CreateSeparator(card.content)
    card:AddRow(sep, Theme.rowHeightSeparator)

    -- Category-specific content
    if selectedCategory == "Instance" then
        local instanceDb = db.Instance
        instanceDb.Types = instanceDb.Types or {}

        for i = 1, #INSTANCE_TYPES, 2 do
            local isLastRow = i + 1 >= #INSTANCE_TYPES
            local rowHeight = isLastRow and Theme.rowHeightLast or Theme.rowHeight
            local row = GUIFrame:CreateRow(card.content, rowHeight)

            local type1 = INSTANCE_TYPES[i]
            local check1 = GUIFrame:CreateCheckbox(row, type1.label, {
                value = instanceDb.Types[type1.key] == true,
                callback = function(checked)
                    instanceDb.Types[type1.key] = checked or nil
                    if onChange then onChange() end
                    if onRefresh then onRefresh() end
                end
            })
            row:AddWidget(check1, 0.5)
            table_insert(widgets, check1)

            local type2 = INSTANCE_TYPES[i + 1]
            if type2 then
                local check2 = GUIFrame:CreateCheckbox(row, type2.label, {
                    value = instanceDb.Types[type2.key] == true,
                    callback = function(checked)
                        instanceDb.Types[type2.key] = checked or nil
                        if onChange then onChange() end
                        if onRefresh then onRefresh() end
                    end
                })
                row:AddWidget(check2, 0.5)
                table_insert(widgets, check2)
            end

            card:AddRow(row, rowHeight, isLastRow and 0 or nil)
        end
    elseif selectedCategory == "Group" then
        local groupDb = db.Group
        groupDb.Types = groupDb.Types or {}

        local typeRow = GUIFrame:CreateRow(card.content, Theme.rowHeightLast)
        for _, groupType in ipairs(GROUP_TYPES) do
            local check = GUIFrame:CreateCheckbox(typeRow, groupType.label, {
                value = groupDb.Types[groupType.key] == true,
                callback = function(checked)
                    groupDb.Types[groupType.key] = checked or nil
                    if onChange then onChange() end
                    if onRefresh then onRefresh() end
                end
            })
            typeRow:AddWidget(check, 0.33)
            table_insert(widgets, check)
        end
        card:AddRow(typeRow, Theme.rowHeightLast, 0)
    elseif selectedCategory == "Combat" then
        local combatDb = db.Combat

        local combatRow = GUIFrame:CreateRow(card.content, Theme.rowHeightLast)
        local inCombatCheck = GUIFrame:CreateCheckbox(combatRow, "In Combat", {
            value = combatDb.InCombat == true,
            callback = function(checked)
                combatDb.InCombat = checked or nil
                if onChange then onChange() end
                if onRefresh then onRefresh() end
            end
        })
        combatRow:AddWidget(inCombatCheck, 0.5)
        table_insert(widgets, inCombatCheck)

        local outCombatCheck = GUIFrame:CreateCheckbox(combatRow, "Out of Combat", {
            value = combatDb.OutOfCombat == true,
            callback = function(checked)
                combatDb.OutOfCombat = checked or nil
                if onChange then onChange() end
                if onRefresh then onRefresh() end
            end
        })
        combatRow:AddWidget(outCombatCheck, 0.5)
        table_insert(widgets, outCombatCheck)

        card:AddRow(combatRow, Theme.rowHeightLast, 0)
    end

    card.conditionWidgets = widgets

    function card:SetEnabled(enabled)
        self:SetAlpha(enabled and 1 or 0.5)
        for _, widget in ipairs(self.conditionWidgets) do
            if widget.SetEnabled then widget:SetEnabled(enabled) end
        end
    end

    return card, card:GetNextOffset()
end
