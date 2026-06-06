---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

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

GUIFrame:RegisterContent("Minimap", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.Skinning.Minimap
    if not db or NRSKNUI:ShouldNotLoadModule() then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    local MAP = NorskenUI:GetModule("Minimap", true)
    local manager = GUIFrame:CreateWidgetStateManager()

    manager:SetCondition("bugWidgets", function() return db.BugSack.Enabled end)
    manager:SetCondition("AddonCompWidgets", function() return not db.HideAddOnComp end)

    local function ApplySettings() if MAP then MAP:ApplySettings() end end
    local function UpdateAllWidgetStates() manager:UpdateAll(db.Enabled) end

    -- Card 1: Toggle
    local card1 = GUIFrame:CreateCard(scrollChild, "Minimap", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeight)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Minimap", {
        value = db.Enabled,
        callback = function(checked)
            db.Enabled = checked
            if checked then
                NorskenUI:EnableModule("Minimap")
            else
                NorskenUI:DisableModule("Minimap")
            end
            UpdateAllWidgetStates()
            NRSKNUI:CreateReloadPrompt("Enabling/Disabling this UI element requires a reload to take full effect.")
        end,
        msgPopup = true,
        msgText = "Minimap",
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, Theme.rowHeight)

    local sepRowInfo = GUIFrame:CreateSeparator(card1.content)
    card1:AddRow(sepRowInfo, Theme.rowHeightSeparator)

    local textRow1Size = 50
    local row1b = GUIFrame:CreateRow(card1.content, textRow1Size)
    local ttInfoText = GUIFrame:CreateText(row1b, NRSKNUI:ColorTextByTheme("Information"), {
        text = NRSKNUI:ColorTextByTheme("• ") .. "Mouse Middle-click: Opens calendar." .. "\n" ..
            NRSKNUI:ColorTextByTheme("• ") .. "Mouse Right-click: Opens tracking menu.",
        height = textRow1Size,
        bgMode = "hide"
    })
    row1b:AddWidget(ttInfoText, 1)
    manager:Register(ttInfoText, "all")
    card1:AddRow(row1b, textRow1Size)

    yOffset = card1:GetNextOffset()

    -- Card 2: Minimap Settings
    local card2 = GUIFrame:CreateCard(scrollChild, "Minimap Settings", yOffset)
    manager:Register(card2, "all")

    local row2 = GUIFrame:CreateRow(card2.content, Theme.rowHeightLast)
    local MinimapSize = GUIFrame:CreateSlider(row2, "Minimap Size", {
        min = 50,
        max = 500,
        step = 1,
        value = db.Size,
        callback = function(val)
            db.Size = val
            if MAP then MAP:ApplyLayout({ deferZoom = true }) end
        end
    })
    row2:AddWidget(MinimapSize, 0.5)
    manager:Register(MinimapSize, "all")

    local MinimapScale = GUIFrame:CreateSlider(row2, "Minimap Scale", {
        min = 0.5,
        max = 2,
        step = 0.1,
        value = db.Scale,
        callback = function(val)
            db.Scale = val
            if MAP then MAP:ApplySettings({ scaleChanged = true }) end
        end
    })
    row2:AddWidget(MinimapScale, 0.5)
    manager:Register(MinimapScale, "all")
    card2:AddRow(row2, Theme.rowHeight)

    local sepRow1 = GUIFrame:CreateSeparator(card2.content)
    card2:AddRow(sepRow1, Theme.rowHeightSeparator)

    local row2b = GUIFrame:CreateRow(card2.content, Theme.rowHeightLast)
    local BorderSize = GUIFrame:CreateSlider(row2b, "Border Size", {
        min = 1,
        max = 10,
        step = 1,
        value = db.Border.Thickness,
        callback = function(val)
            db.Border.Thickness = val
            if MAP then MAP:UpdateMinimapBorder() end
        end
    })
    row2b:AddWidget(BorderSize, 0.5)
    manager:Register(BorderSize, "all")

    local BorderColor = GUIFrame:CreateColorPicker(row2b, "Border Color", {
        color = db.Border.Color,
        callback = function(r, g, b, a)
            db.Border.Color = { r, g, b, a }
            ApplySettings()
        end
    })
    row2b:AddWidget(BorderColor, 0.5)
    manager:Register(BorderColor, "all")
    card2:AddRow(row2b, Theme.rowHeightLast, 0)

    yOffset = card2:GetNextOffset()

    -- Card 4
    local card4 = GUIFrame:CreateCard(scrollChild, "BugSack Settings", yOffset)
    manager:Register(card4, "all")

    local row4a = GUIFrame:CreateRow(card4.content, Theme.rowHeight)
    local BugSackEnbl = GUIFrame:CreateCheckbox(row4a, "Toggle BugSack Frame", {
        value = db.BugSack.Enabled ~= false,
        callback = function(checked)
            db.BugSack.Enabled = checked
            if MAP then MAP:CreateBugSackButton() end
            UpdateAllWidgetStates()
        end
    })
    row4a:AddWidget(BugSackEnbl, 1)
    manager:Register(BugSackEnbl, "all")
    card4:AddRow(row4a, Theme.rowHeight)

    local sepRow2 = GUIFrame:CreateSeparator(card4.content)
    card4:AddRow(sepRow2, Theme.rowHeightSeparator)

    local row4 = GUIFrame:CreateRow(card4.content, Theme.rowHeight)
    local BugSackSize = GUIFrame:CreateSlider(row4, "BugSack Size", {
        min = 5,
        max = 50,
        step = 1,
        value = db.BugSack.Size,
        callback = function(val)
            db.BugSack.Size = val
            if MAP then MAP:UpdateBugSackButton() end
        end
    })
    row4:AddWidget(BugSackSize, 0.5)
    manager:Register(BugSackSize, "all", "bugWidgets")

    local BugSackAnchor = GUIFrame:CreateDropdown(row4, "Anchorpoint", {
        options = ANCHOR_OPTIONS,
        value = db.BugSack.Anchor,
        callback = function(key)
            db.BugSack.Anchor = key
            ApplySettings()
        end
    })
    row4:AddWidget(BugSackAnchor, 0.5)
    manager:Register(BugSackAnchor, "all", "bugWidgets")
    card4:AddRow(row4, Theme.rowHeight)

    local row4b = GUIFrame:CreateRow(card4.content, Theme.rowHeightLast)
    local BugSackX = GUIFrame:CreateSlider(row4b, "X Offset", {
        min = -500,
        max = 500,
        step = 1,
        value = db.BugSack.X,
        callback = function(val)
            db.BugSack.X = val
            if MAP then MAP:UpdateBugSackButton() end
        end
    })
    row4b:AddWidget(BugSackX, 0.5)
    manager:Register(BugSackX, "all", "bugWidgets")

    local BugSackY = GUIFrame:CreateSlider(row4b, "Y Offset", {
        min = -500,
        max = 500,
        step = 1,
        value = db.BugSack.Y,
        callback = function(val)
            db.BugSack.Y = val
            if MAP then MAP:UpdateBugSackButton() end
        end
    })
    row4b:AddWidget(BugSackY, 0.5)
    manager:Register(BugSackY, "all", "bugWidgets")
    card4:AddRow(row4b, Theme.rowHeightLast, 0)

    yOffset = card4:GetNextOffset()

    -- Card 5
    local card5 = GUIFrame:CreateCard(scrollChild, "AddOn Compartment Settings", yOffset)
    manager:Register(card5, "all")

    local row1comp = GUIFrame:CreateRow(card5.content, Theme.rowHeight)
    local HideAddOn = GUIFrame:CreateCheckbox(row1comp, "Hide AddOn Compartment", {
        value = db.HideAddOnComp,
        callback = function(checked)
            db.HideAddOnComp = checked
            ApplySettings()
            UpdateAllWidgetStates()
        end
    })
    row1comp:AddWidget(HideAddOn, 1)
    manager:Register(HideAddOn, "all")
    card5:AddRow(row1comp, Theme.rowHeight)

    local sepRowComp = GUIFrame:CreateSeparator(card5.content)
    card5:AddRow(sepRowComp, Theme.rowHeightSeparator)

    local row2comp = GUIFrame:CreateRow(card5.content, Theme.rowHeight)
    local compSize = GUIFrame:CreateSlider(row2comp, "AddOn Compartment Size", {
        min = 5,
        max = 50,
        step = 1,
        value = db.AddOnComp.Size,
        callback = function(val)
            db.AddOnComp.Size = val
            if MAP then MAP:UpdateAddonCompartment() end
        end
    })
    row2comp:AddWidget(compSize, 0.5)
    manager:Register(compSize, "all", "AddonCompWidgets")

    local compAnchor = GUIFrame:CreateDropdown(row2comp, "Anchorpoint", {
        options = ANCHOR_OPTIONS,
        value = db.AddOnComp.Anchor,
        callback = function(key)
            db.AddOnComp.Anchor = key
            ApplySettings()
        end
    })
    row2comp:AddWidget(compAnchor, 0.5)
    manager:Register(compAnchor, "all", "AddonCompWidgets")
    card5:AddRow(row2comp, Theme.rowHeight)

    local row3comp = GUIFrame:CreateRow(card5.content, Theme.rowHeightLast)
    local compX = GUIFrame:CreateSlider(row3comp, "X Offset", {
        min = -500,
        max = 500,
        step = 1,
        value = db.AddOnComp.X,
        callback = function(val)
            db.AddOnComp.X = val
            if MAP then MAP:UpdateAddonCompartment() end
        end
    })
    row3comp:AddWidget(compX, 0.5)
    manager:Register(compX, "all", "AddonCompWidgets")

    local compY = GUIFrame:CreateSlider(row3comp, "Y Offset", {
        min = -500,
        max = 500,
        step = 1,
        value = db.AddOnComp.Y,
        callback = function(val)
            db.AddOnComp.Y = val
            if MAP then MAP:UpdateAddonCompartment() end
        end
    })
    row3comp:AddWidget(compY, 0.5)
    manager:Register(compY, "all", "AddonCompWidgets")
    card5:AddRow(row3comp, Theme.rowHeightLast, 0)

    yOffset = card5:GetNextOffset()

    -- Card 3
    local card3 = GUIFrame:CreateCard(scrollChild, "Mail Icon Settings", yOffset)
    manager:Register(card3, "all")

    local row3a = GUIFrame:CreateRow(card3.content, Theme.rowHeight)
    local MailScale = GUIFrame:CreateSlider(row3a, "Scale", {
        min = 0.5,
        max = 2,
        step = 0.1,
        value = db.Mail.Scale,
        callback = function(val)
            db.Mail.Scale = val
            ApplySettings()
        end
    })
    row3a:AddWidget(MailScale, 0.5)
    manager:Register(MailScale, "all")

    local mailAnchor = GUIFrame:CreateDropdown(row3a, "Anchorpoint", {
        options = ANCHOR_OPTIONS,
        value = db.Mail.Anchor,
        callback = function(key)
            db.Mail.Anchor = key
            ApplySettings()
        end
    })
    row3a:AddWidget(mailAnchor, 0.5)
    manager:Register(mailAnchor, "all")
    card3:AddRow(row3a, Theme.rowHeight)

    local row3b = GUIFrame:CreateRow(card3.content, Theme.rowHeightLast)
    local MailX = GUIFrame:CreateSlider(row3b, "X Offset", {
        min = -500,
        max = 500,
        step = 1,
        value = db.Mail.X,
        callback = function(val)
            db.Mail.X = val
            ApplySettings()
        end
    })
    row3b:AddWidget(MailX, 0.5)
    manager:Register(MailX, "all")

    local MailY = GUIFrame:CreateSlider(row3b, "Y Offset", {
        min = -500,
        max = 500,
        step = 1,
        value = db.Mail.Y,
        callback = function(val)
            db.Mail.Y = val
            ApplySettings()
        end
    })
    row3b:AddWidget(MailY, 0.5)
    manager:Register(MailY, "all")
    card3:AddRow(row3b, Theme.rowHeightLast, 0)

    yOffset = card3:GetNextOffset()

    -- Card Q
    local cardQ = GUIFrame:CreateCard(scrollChild, "Queue Icon Settings", yOffset)
    manager:Register(cardQ, "all")

    local row1q = GUIFrame:CreateRow(cardQ.content, Theme.rowHeight)
    local QueueScale = GUIFrame:CreateSlider(row1q, "Scale", {
        min = 0.5,
        max = 2,
        step = 0.1,
        value = db.QueueStatus.Scale,
        callback = function(val)
            db.QueueStatus.Scale = val
            ApplySettings()
        end
    })
    row1q:AddWidget(QueueScale, 0.5)
    manager:Register(QueueScale, "all")

    local queueAnchor = GUIFrame:CreateDropdown(row1q, "Anchorpoint", {
        options = ANCHOR_OPTIONS,
        value = db.QueueStatus.Anchor,
        callback = function(key)
            db.QueueStatus.Anchor = key
            ApplySettings()
        end
    })
    row1q:AddWidget(queueAnchor, 0.5)
    manager:Register(queueAnchor, "all")
    cardQ:AddRow(row1q, Theme.rowHeight)

    local row2q = GUIFrame:CreateRow(cardQ.content, Theme.rowHeightLast)
    local QueueX = GUIFrame:CreateSlider(row2q, "X Offset", {
        min = -500,
        max = 500,
        step = 1,
        value = db.QueueStatus.X,
        callback = function(val)
            db.QueueStatus.X = val
            ApplySettings()
        end
    })
    row2q:AddWidget(QueueX, 0.5)
    manager:Register(QueueX, "all")

    local QueueY = GUIFrame:CreateSlider(row2q, "Y Offset", {
        min = -500,
        max = 500,
        step = 1,
        value = db.QueueStatus.Y,
        callback = function(val)
            db.QueueStatus.Y = val
            ApplySettings()
        end
    })
    row2q:AddWidget(QueueY, 0.5)
    manager:Register(QueueY, "all")
    cardQ:AddRow(row2q, Theme.rowHeightLast, 0)

    yOffset = cardQ:GetNextOffset()

    -- Card 6
    local posCard, posOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        db = db,
        dbKeys = {
            xOffset = "X",
            yOffset = "Y",
        },
        showAnchorFrameType = false,
        showStrata = false,
        onChangeCallback = ApplySettings,
    })
    manager:Register(posCard, "all")

    yOffset = posOffset

    UpdateAllWidgetStates()

    return yOffset
end)
