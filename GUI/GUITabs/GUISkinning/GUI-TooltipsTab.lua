-- NorskenUI namespace
---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

-- Helper to get Tooltips module
local function GetTooltipsModule()
    if NorskenUI then
        return NorskenUI:GetModule("Tooltips", true)
    end
    return nil
end

-- Register Content
GUIFrame:RegisterContent("tooltips", function(scrollChild, yOffset)
    if NRSKNUI:ShouldNotLoadModule() then return end
    local db = NRSKNUI.db and NRSKNUI.db.profile.Skinning.Tooltips
    if not db then
        local errorCard = GUIFrame:CreateCard(scrollChild, "Error", yOffset)
        errorCard:AddLabel("Database not available")
        return yOffset + errorCard:GetContentHeight() + Theme.paddingMedium
    end

    local TT = GetTooltipsModule()

    local function ApplyTooltipState(enabled)
        if not TT then return end
        TT.db.Enabled = enabled
        if enabled then
            NorskenUI:EnableModule("Tooltips")
        else
            NorskenUI:DisableModule("Tooltips")
        end
    end

    ----------------------------------------------------------------
    -- Card: Tooltip Skinning
    ----------------------------------------------------------------
    local card = GUIFrame:CreateCard(scrollChild, "Tooltip Skinning", yOffset)

    local row1 = GUIFrame:CreateRow(card.content, 40)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Tooltip Skinning", db.Enabled ~= false,
        function(checked)
            db.Enabled = checked
            ApplyTooltipState(checked)
            if not checked then
                NRSKNUI:CreateReloadPrompt("Enabling Blizzard UI elements requires a reload to take full effect.")
            end
        end,
        true,
        "Tooltip Skinning",
        "On",
        "Off"
    )
    row1:AddWidget(enableCheck, 1)
    card:AddRow(row1, 40)

    yOffset = yOffset + card:GetContentHeight() + Theme.paddingSmall

    return yOffset
end)
