---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme
local ipairs = ipairs

local SUB_TABS = {
    { id = "generalCvars", text = "General CVars" },
    { id = "sqwCvars",     text = "SQW CVar" },
    { id = "devCvars",     text = "Dev CVars" },
}

local TAB_BAR_HEIGHT = 30

local currentSubTab = "generalCvars"

local function CreateCVarWidget(card, def, manager, MVAR)
    local key = def.key
    local widgetRow = GUIFrame:CreateRow(card.content, Theme.rowHeight)
    local widget
    local tooltipConfig = def.description and { text = def.description, default = def.default } or nil
    local currentValue = MVAR:GetCVar(key)

    if def.type == "boolean" then
        widget = GUIFrame:CreateCheckbox(widgetRow, def.label, {
            value = currentValue,
            tooltip = tooltipConfig,
            cvartooltip = true,
            callback = function(checked)
                MVAR:SetCVar(key, checked)
            end
        })
        widgetRow:AddWidget(widget, 1)
    elseif def.type == "number" then
        widget = GUIFrame:CreateSlider(widgetRow, def.label, {
            min = def.min,
            max = def.max,
            step = def.step,
            value = currentValue or def.default,
            tooltip = tooltipConfig,
            cvartooltip = true,
            callback = function(value)
                MVAR:SetCVar(key, value)
            end
        })
        widgetRow:AddWidget(widget, 1)
    end

    manager:Register(widget, "all")
    card:AddRow(widgetRow, Theme.rowHeight)
    return widget
end

local function CreateSQWWidget(card, def, manager, MVAR)
    local key = def.key
    local widgetRow = GUIFrame:CreateRow(card.content, Theme.rowHeight)
    local tooltipConfig = def.description and { text = def.description, default = def.default } or nil

    local widget = GUIFrame:CreateSlider(widgetRow, def.label, {
        min = def.min,
        max = def.max,
        step = def.step,
        value = MVAR:GetSQW(key),
        tooltip = tooltipConfig,
        cvartooltip = true,
        callback = function(value)
            MVAR:SetSQW(key, value)
        end
    })
    widgetRow:AddWidget(widget, 1)

    manager:Register(widget, "all")
    card:AddRow(widgetRow, Theme.rowHeight)
    return widget
end

local function AddSeparator(card, manager)
    local sepRow = GUIFrame:CreateRow(card.content, Theme.rowHeightSeparator)
    local sep = GUIFrame:CreateSeparator(sepRow)
    sepRow:AddWidget(sep, 1)
    manager:Register(sep, "all")
    card:AddRow(sepRow, Theme.rowHeightSeparator)
end

local function RenderGeneralCVarsTab(scrollChild, manager, MVAR)
    local yOffset = Theme.paddingSmall

    local generalDefs = {}
    for _, def in ipairs(MVAR.DEFS) do
        if not def.category then
            generalDefs[#generalDefs + 1] = def
        end
    end

    local card = GUIFrame:CreateCard(scrollChild, "CVar Browser", yOffset)
    manager:Register(card, "all")
    for i, def in ipairs(generalDefs) do
        CreateCVarWidget(card, def, manager, MVAR)
        if i < #generalDefs then AddSeparator(card, manager) end
    end
    yOffset = card:GetNextOffset()

    return yOffset
end

local function RenderSQWCVarsTab(scrollChild, manager, MVAR)
    local yOffset = Theme.paddingSmall

    local card = GUIFrame:CreateCard(scrollChild, "Spell Queue Window", yOffset)
    manager:Register(card, "all")

    local position = NRSKNUI.MySpec and NRSKNUI.MySpec.position

    for i, def in ipairs(MVAR.SQW_DEFS) do
        local label = def.label
        if def.position == "MELEE" then
            label = label .. " " .. (position == "MELEE" and "|cff00ff00(Active)|r" or "|cffaaaaaa(Inactive)|r")
        elseif def.position == "RANGED" then
            label = label .. " " .. (position == "RANGED" and "|cff00ff00(Active)|r" or "|cffaaaaaa(Inactive)|r")
        end

        local modifiedDef = {
            key = def.key,
            label = label,
            description = def.description,
            type = def.type,
            min = def.min,
            max = def.max,
            step = def.step,
            default = def.default,
        }

        CreateSQWWidget(card, modifiedDef, manager, MVAR)
        if i < #MVAR.SQW_DEFS then AddSeparator(card, manager) end
    end

    AddSeparator(card, manager)

    local infoHeight = 70
    local infoRow = GUIFrame:CreateRow(card.content, infoHeight)
    local infoText = GUIFrame:CreateText(infoRow, NRSKNUI:ColorTextByTheme("Learn More"), {
        text =
        "The spell queue window determines how early you can\nqueue your next ability before your current cast finishes.\nVisit |cff8788EEXerwo|r's maxroll guide for more information.",
        height = infoHeight,
        bgMode = "hide"
    })
    infoRow:AddWidget(infoText, 0.65)
    manager:Register(infoText, "all")

    local linkBtn = GUIFrame:CreateButton(infoRow, "Open Guide", {
        callback = function()
            NRSKNUI:CreateCopyDialog(
                "Spell Queue Window Guide",
                "https://maxroll.gg/wow/resources/spell-queue-window",
                "Copy to clipboard by pressing CTRL + C"
            )
        end,
        width = 100,
        height = 36,
    })
    infoRow:AddWidget(linkBtn, 0.35)
    manager:Register(linkBtn, "all")
    card:AddRow(infoRow, infoHeight, 0)

    yOffset = card:GetNextOffset()

    return yOffset
end

local function RenderDevCVarsTab(scrollChild, manager, MVAR)
    local yOffset = Theme.paddingSmall

    local devDefs = {}
    for _, def in ipairs(MVAR.DEFS) do
        if def.category == "dev" then
            devDefs[#devDefs + 1] = def
        end
    end

    local card = GUIFrame:CreateCard(scrollChild, "Dev CVars", yOffset)
    manager:Register(card, "all")
    for i, def in ipairs(devDefs) do
        CreateCVarWidget(card, def, manager, MVAR)
        if i < #devDefs then AddSeparator(card, manager) end
    end
    yOffset = card:GetNextOffset()

    return yOffset
end

GUIFrame:RegisterPanel("MiscVars", function(container)
    local db = NRSKNUI.db and NRSKNUI.db.profile.Miscellaneous.MiscVars
    if not db then return nil end

    ---@type MiscVars?
    local MVAR = NRSKNUI:GetModule("MiscVars", true)
    if not MVAR then return nil end

    local manager = GUIFrame:CreateWidgetStateManager()

    local function UpdateAllWidgetStates()
        manager:UpdateAll(db.Enabled ~= false)
    end

    local subTabPanel
    local RenderContent

    RenderContent = function()
        subTabPanel:ClearContent()
        manager:Clear()

        local tabYOffset = Theme.paddingSmall
        if currentSubTab == "generalCvars" then
            tabYOffset = RenderGeneralCVarsTab(subTabPanel.scrollChild, manager, MVAR)
        elseif currentSubTab == "sqwCvars" then
            tabYOffset = RenderSQWCVarsTab(subTabPanel.scrollChild, manager, MVAR)
        elseif currentSubTab == "devCvars" then
            tabYOffset = RenderDevCVarsTab(subTabPanel.scrollChild, manager, MVAR)
        end

        subTabPanel:SetContentHeight(tabYOffset)
        UpdateAllWidgetStates()
    end

    subTabPanel = NRSKNUI.GUI.CreateSubTabPanel(container, SUB_TABS, {
        tabBarHeight = TAB_BAR_HEIGHT,
        defaultTab = currentSubTab,
        onTabChanged = function(tabId)
            currentSubTab = tabId
            RenderContent()
        end,
    })

    RenderContent()

    return subTabPanel.panel
end)
