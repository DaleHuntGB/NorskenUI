-- NorskenUI namespace
---@class NRSKNUI
local NRSKNUI = select(2, ...)
---@class GUIFrame
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

-- Localization
local math = math
local C_Timer = C_Timer
local ipairs = ipairs
local CreateFrame = CreateFrame
local CreateColor = CreateColor
local wipe = wipe

-- Section header pool
GUIFrame.sidebarHeaderPool = {}
GUIFrame.currentExpandedSection = nil

-- Module locals
local headerHeight = 32
local itemHeight = 28

-- Animation timing (based on UX research)
local HOVER_DURATION = 0.12 -- 100-150ms for simple feedback
local ARROW_DURATION = 0.2  -- 200ms for expand/collapse
local ACCENT_BAR_WIDTH = 2  -- Clear but not heavy

-- Release section headers
function GUIFrame:ReleaseSectionHeaders()
    for _, header in ipairs(self.sidebarHeaderPool or {}) do
        header.inUse = false
        header.disabled = nil
        if header.hoverBg then
            header.hoverBg:SetAlpha(0)
        end
        header:Hide()
        header:ClearAllPoints()
    end
end

-- Create section header
function GUIFrame:CreateSectionHeader()
    local ARROW_SIZE = 14
    local arrowTex = "Interface\\AddOns\\NorskenUI\\Media\\GUITextures\\collapse.tga"

    local header = CreateFrame("Button", nil, UIParent)
    header:SetHeight(headerHeight)
    header:EnableMouse(true)
    header:RegisterForClicks("LeftButtonUp")

    -- Hover background - simple solid tint
    local hoverBg = header:CreateTexture(nil, "BACKGROUND")
    hoverBg:SetAllPoints()
    hoverBg:SetColorTexture(1, 1, 1, 0.04)
    hoverBg:SetAlpha(0)
    header.hoverBg = hoverBg

    -- Label
    local fontPath = "Fonts\\FRIZQT__.TTF"
    local fontSize = Theme.fontSizeLarge or 14
    local label = header:CreateFontString(nil, "OVERLAY")
    label:SetPoint("LEFT", header, "LEFT", Theme.paddingSmall, 0)
    label:SetFont(fontPath, fontSize, "")
    label:SetTextColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
    label:SetShadowOffset(1, -1)
    label:SetShadowColor(0, 0, 0, 0.5)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    header.label = label

    -- Arrow icon (chevron at end per UX research)
    local arrow = header:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(ARROW_SIZE, ARROW_SIZE)
    arrow:SetPoint("RIGHT", header, "RIGHT", -Theme.paddingSmall, 0)
    arrow:SetTexture(arrowTex)
    arrow:SetVertexColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 0.7)
    arrow:SetTexelSnappingBias(0)
    arrow:SetSnapToPixelGrid(false)
    header.arrow = arrow

    -- Arrow animation (200ms with ease-out)
    local arrowAnimGroup = arrow:CreateAnimationGroup()
    local arrowRotation = arrowAnimGroup:CreateAnimation("Rotation")
    arrowRotation:SetDuration(ARROW_DURATION)
    arrowRotation:SetOrigin("CENTER", 0, 0)
    arrowRotation:SetSmoothing("OUT")
    header.arrowAnimGroup = arrowAnimGroup
    header.arrowRotation = arrowRotation

    header.AnimateArrowOpen = function(self)
        if self.isExpanded then return end
        self.arrowAnimGroup:Stop()
        self.arrowRotation:SetRadians(math.pi / 2)
        self.isExpanded = true
        self.arrowAnimGroup:Play()
    end

    header.AnimateArrowClose = function(self)
        if not self.isExpanded then return end
        self.arrowAnimGroup:Stop()
        self.arrowRotation:SetRadians(-math.pi / 2)
        self.isExpanded = false
        self.arrowAnimGroup:Play()
    end

    arrowAnimGroup:SetScript("OnFinished", function()
        arrow:SetRotation(header.isExpanded and 0 or -math.pi / 2)
    end)

    header.SetArrowState = function(self, expanded)
        self.arrowAnimGroup:Stop()
        self.isExpanded = expanded
        self.arrow:SetRotation(expanded and 0 or -math.pi / 2)
    end

    -- Hover animation using OnUpdate for smooth fade
    local hoverTarget = 0
    header:SetScript("OnUpdate", function(self, elapsed)
        local current = hoverBg:GetAlpha()
        if math.abs(current - hoverTarget) > 0.01 then
            local speed = elapsed / HOVER_DURATION
            if hoverTarget > current then
                hoverBg:SetAlpha(math.min(current + speed, hoverTarget))
            else
                hoverBg:SetAlpha(math.max(current - speed, hoverTarget))
            end
        end
    end)

    header:SetScript("OnEnter", function(self)
        if header.disabled then return end
        hoverTarget = 1
        -- Brighten arrow on hover
        header.arrow:SetVertexColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 1)
    end)

    header:SetScript("OnLeave", function(self)
        hoverTarget = 0
        if not header.disabled then
            header.arrow:SetVertexColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 0.7)
        end
    end)

    header:SetScript("OnClick", function(self)
        if not header.disabled then
            GUIFrame:ToggleSection(self.sectionId)
        end
    end)

    return header
end

-- Get section header from pool
function GUIFrame:GetSectionHeader()
    for _, header in ipairs(self.sidebarHeaderPool) do
        if not header.inUse then
            header.inUse = true
            header:Show()
            return header
        end
    end

    local header = self:CreateSectionHeader()
    header.inUse = true
    table.insert(self.sidebarHeaderPool, header)
    return header
end

local initSideBar = false
function GUIFrame:InitializeSidebarExpansion()
    if initSideBar then return end
    wipe(self.sidebarExpanded)

    local config = self.SidebarConfig[self.selectedTab]
    if not config then return end

    for _, section in ipairs(config) do
        if section.type == "header" and section.defaultExpanded then
            self.sidebarExpanded[section.id] = true
        end
    end
    initSideBar = true
end

-- Configure section header
local arrowInitPos = false
function GUIFrame:ConfigureSectionHeader(header, config, yOffset, isExpanded)
    local scrollChild = self.sidebar.scrollChild
    local horizontalPadding = Theme.paddingSmall

    header:SetParent(scrollChild)
    header:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", horizontalPadding, -yOffset)
    header:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -horizontalPadding, -yOffset)
    header.sectionId = config.id
    header.label:SetText(config.text or "")

    -- Grey out if ElvUI-disabled
    if config.elvUIDisabled and NRSKNUI:ShouldNotLoadModule() then
        header.label:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 0.35)
        header.arrow:SetVertexColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 0.35)
        header.disabled = true
    else
        header.label:SetTextColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
        header.arrow:SetVertexColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 0.7)
        header.disabled = false
    end

    -- Store expanded state
    header.isExpanded = isExpanded

    -- Set arrow rotation based on expanded state once
    if not arrowInitPos then
        C_Timer.After(0.1, function()
            header:SetArrowState(isExpanded)
            arrowInitPos = true
        end)
    end
    header.hoverBg:SetAlpha(0)
    return header
end

function GUIFrame:GetHeaderBySectionId(sectionId)
    for _, header in ipairs(self.sidebarHeaderPool) do
        if header.inUse and header.sectionId == sectionId then
            return header
        end
    end
end

-- Toggle section expand/collapse (allows multiple sections open)
function GUIFrame:ToggleSection(sectionId)
    local wasExpanded = self.sidebarExpanded[sectionId]

    -- Toggle this section
    if wasExpanded then
        -- Collapse this section
        local header = self:GetHeaderBySectionId(sectionId)
        if header then
            header:AnimateArrowClose()
        end
        self.sidebarExpanded[sectionId] = nil
    else
        -- Expand this section
        local header = self:GetHeaderBySectionId(sectionId)
        if header then
            header:AnimateArrowOpen()
        end

        self.sidebarExpanded[sectionId] = true
    end
    -- Refresh sidebar (rebuilds the visual items)
    C_Timer.After(0.01, function()
        self:RefreshSidebar()
        self:RefreshContent()
    end)
end

-- Static sidebar item pool
GUIFrame.staticSidebarItemPool = {}

-- Get static sidebar item from pool or create new
function GUIFrame:GetStaticSidebarItem()
    for _, item in ipairs(self.staticSidebarItemPool) do
        if not item.inUse then
            item.inUse = true
            item:Show()
            return item
        end
    end

    local item = self:CreateStaticSidebarItem()
    item.inUse = true
    table.insert(self.staticSidebarItemPool, item)
    return item
end

-- Release all static sidebar items back to pool
function GUIFrame:ReleaseStaticSidebarItems()
    for _, item in ipairs(self.staticSidebarItemPool) do
        item.inUse = false
        item.hoverTarget = 0
        if item.hoverBg then
            item.hoverBg:SetAlpha(0)
        end
        if item.accentBar then
            item.accentBar:Hide()
        end
        if item.selectedBg then
            item.selectedBg:Hide()
        end
        item:Hide()
        item:ClearAllPoints()
        item.id = nil
        item.disabled = nil
    end
end

-- Create a static sidebar item
function GUIFrame:CreateStaticSidebarItem()
    local item = CreateFrame("Button", nil, UIParent)
    item:SetHeight(itemHeight)
    item:EnableMouse(true)
    item:RegisterForClicks("LeftButtonUp")

    -- Hover background - simple solid tint
    local hoverBg = item:CreateTexture(nil, "BACKGROUND")
    hoverBg:SetAllPoints()
    hoverBg:SetColorTexture(1, 1, 1, 0.05)
    hoverBg:SetAlpha(0)
    item.hoverBg = hoverBg

    -- Selected background - subtle accent tint for distinction from headers
    local selectedBg = item:CreateTexture(nil, "BACKGROUND", nil, 1)
    selectedBg:SetAllPoints()
    selectedBg:SetColorTexture(Theme.accent[1], Theme.accent[2], Theme.accent[3], 0.08)
    selectedBg:Hide()
    item.selectedBg = selectedBg

    -- Accent bar - clear selection indicator (2px, full height)
    local accentBar = item:CreateTexture(nil, "OVERLAY")
    accentBar:SetWidth(ACCENT_BAR_WIDTH)
    accentBar:SetPoint("TOPLEFT", item, "TOPLEFT", 0, 0)
    accentBar:SetPoint("BOTTOMLEFT", item, "BOTTOMLEFT", 0, 0)
    accentBar:SetColorTexture(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
    accentBar:Hide()
    item.accentBar = accentBar

    -- Label
    local fontPath = "Fonts\\FRIZQT__.TTF"
    local fontSize = Theme.fontSizeNormal or 12
    local label = item:CreateFontString(nil, "OVERLAY")
    label:SetPoint("LEFT", item, "LEFT", 10, 0)
    label:SetPoint("RIGHT", item, "RIGHT", -Theme.paddingSmall, 0)
    label:SetFont(fontPath, fontSize, "")
    label:SetShadowOffset(1, -1)
    label:SetShadowColor(0, 0, 0, 0.4)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    item.label = label

    -- Hover animation using OnUpdate for smooth fade
    item.hoverTarget = 0
    item:SetScript("OnUpdate", function(self, elapsed)
        local current = hoverBg:GetAlpha()
        if math.abs(current - self.hoverTarget) > 0.01 then
            local speed = elapsed / HOVER_DURATION
            if self.hoverTarget > current then
                hoverBg:SetAlpha(math.min(current + speed, self.hoverTarget))
            else
                hoverBg:SetAlpha(math.max(current - speed, self.hoverTarget))
            end
        end
    end)

    item:SetScript("OnEnter", function(self)
        if self.disabled then return end
        self.hoverTarget = 1
        -- Only brighten text if not selected (selected already has accent color)
        if self.id ~= GUIFrame.selectedSidebarItem then
            self.label:SetTextColor(Theme.textPrimary[1], Theme.textPrimary[2], Theme.textPrimary[3], 1)
        end
    end)

    item:SetScript("OnLeave", function(self)
        self.hoverTarget = 0
        -- Only dim text if not selected (selected keeps accent color)
        if self.id ~= GUIFrame.selectedSidebarItem and not self.disabled then
            self.label:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 1)
        end
    end)

    item:SetScript("OnClick", function(self, button)
        if button == "LeftButton" and not self.disabled then
            GUIFrame:SelectSidebarItem(self.id)
        end
    end)

    return item
end

-- Create Sidebar
function GUIFrame:CreateSidebar(parent)
    local sidebar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -Theme.headerHeight)
    sidebar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, Theme.footerHeight)
    sidebar:SetPoint("RIGHT", parent.content or parent, "LEFT", 0, 0)
    sidebar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    sidebar:SetBackdropColor(Theme.bgMedium[1], Theme.bgMedium[2], Theme.bgMedium[3], Theme.bgMedium[4])

    local rightBorder = sidebar:CreateTexture(nil, "BORDER")
    rightBorder:SetWidth(Theme.borderSize)
    rightBorder:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT", 0, 0)
    rightBorder:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", 0, 0)
    rightBorder:SetColorTexture(Theme.border[1], Theme.border[2], Theme.border[3], Theme.border[4])

    local scrollbarWidth = Theme.scrollbarWidth or 16

    local scrollFrame = CreateFrame("ScrollFrame", nil, sidebar)
    scrollFrame:SetFrameLevel(sidebar:GetFrameLevel() + 5)
    scrollFrame:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 0, -Theme.paddingSmall)
    scrollFrame:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", -Theme.borderSize, Theme.paddingSmall)
    scrollFrame:SetClipsChildren(true)
    sidebar.scrollFrameDefaultTop = -Theme.paddingSmall

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetHeight(1)
    scrollChild:SetFrameLevel(scrollFrame:GetFrameLevel() + 1)
    scrollFrame:SetScrollChild(scrollChild)

    -- Create custom styled scrollbar
    local scrollbar = NRSKNUI.GUI.CreateScrollbar(scrollFrame, {
        width = 16,
        thumbHeight = 40,
        padding = { top = -1, bottom = -1, right = 0 },
        scrollStep = 40
    })
    sidebar.scrollbar = scrollbar

    local sidebarScrollbarVisible = false
    local function UpdateSidebarScrollChildWidth()
        local sidebarActualWidth = sidebar:GetWidth()
        if sidebarActualWidth and sidebarActualWidth > 0 then
            if sidebarScrollbarVisible then
                scrollChild:SetWidth(sidebarActualWidth - Theme.borderSize - scrollbarWidth)
            else
                scrollChild:SetWidth(sidebarActualWidth - Theme.borderSize)
            end
        end
    end
    local function UpdateSidebarScrollBarVisibility()
        local contentHeight = scrollChild:GetHeight()
        local frameHeight = scrollFrame:GetHeight()
        sidebarScrollbarVisible = scrollbar:UpdateVisibility(contentHeight, frameHeight)
        UpdateSidebarScrollChildWidth()
    end
    sidebar.UpdateScrollBarVisibility = UpdateSidebarScrollBarVisibility
    scrollChild:HookScript("OnSizeChanged", UpdateSidebarScrollBarVisibility)
    scrollFrame:HookScript("OnSizeChanged", UpdateSidebarScrollBarVisibility)
    scrollFrame:HookScript("OnShow", function()
        C_Timer.After(0, UpdateSidebarScrollBarVisibility)
    end)
    sidebar:SetScript("OnSizeChanged", function()
        UpdateSidebarScrollChildWidth()
    end)
    scrollChild:SetWidth(Theme.sidebarWidth - Theme.borderSize)
    sidebar.scrollFrame = scrollFrame
    sidebar.scrollChild = scrollChild
    parent.sidebar = sidebar
    self.sidebar = sidebar
    return sidebar
end

-- Select Sidebar Item
function GUIFrame:SelectSidebarItem(itemId)
    self.selectedSidebarItem = itemId
    for _, item in ipairs(self.staticSidebarItemPool) do
        if item.inUse then
            if item.disabled then
                item.accentBar:Hide()
                item.selectedBg:Hide()
            elseif item.id == itemId then
                -- Selected: show accent bar + background, accent text color
                item.accentBar:Show()
                item.selectedBg:Show()
                item.label:SetTextColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
            else
                -- Not selected: hide accent bar + background, secondary text color
                item.accentBar:Hide()
                item.selectedBg:Hide()
                item.label:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 1)
            end
        end
    end
    self:RefreshContent()
end

-- Sidebar state
GUIFrame.sidebarExpanded = GUIFrame.sidebarExpanded or {}
GUIFrame.sidebarRefreshPending = false
GUIFrame.SIDEBAR_THROTTLE = 0.05

-- Throttled refresh
function GUIFrame:RefreshSidebar()
    if self.sidebarRefreshPending then return end
    self.sidebarRefreshPending = true
    C_Timer.After(self.SIDEBAR_THROTTLE, function()
        self.sidebarRefreshPending = false
        self:RefreshSidebarImmediate()
    end)
end

-- Check if a sidebar item's parent section is currently expanded
function GUIFrame:IsItemParentExpanded(itemId)
    if not itemId then return false end
    local config = self.SidebarConfig[self.selectedTab]
    if not config then return false end
    for _, section in ipairs(config) do
        if section.type == "header" and section.items then
            for _, item in ipairs(section.items) do
                if item.id == itemId then
                    -- Found the item, check if its parent section is expanded
                    return self.sidebarExpanded[section.id] == true
                end
            end
        end
    end
    return false
end

-- Immediate refresh
function GUIFrame:RefreshSidebarImmediate()
    if not self.sidebar then return end
    self:ReleaseStaticSidebarItems()
    self:ReleaseSectionHeaders()
    local scrollChild = self.sidebar.scrollChild
    local scrollFrame = self.sidebar.scrollFrame
    for _, region in ipairs({ scrollChild:GetRegions() }) do
        if region:GetObjectType() == "FontString" then
            region:Hide()
            region:SetText("")
        end
    end
    local config = self.SidebarConfig[self.selectedTab]
    scrollFrame:ClearAllPoints()
    scrollFrame:SetPoint("TOPLEFT", self.sidebar, "TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", self.sidebar, "BOTTOMRIGHT", -Theme.borderSize, Theme.paddingSmall)
    if not config then
        scrollChild:SetHeight(1)
        return
    end
    local yOffset = Theme.paddingSmall
    local itemSpacing = 1
    local sectionSpacing = 4 -- More space between sections for clear grouping
    local itemIndent = 0     -- Indent items to show hierarchy under headers
    if self.sidebarEmptyText then
        self.sidebarEmptyText:Hide()
    end
    -- Build sections
    for _, sectionConfig in ipairs(config) do
        if sectionConfig.type == "header" then
            local isExpanded = self.sidebarExpanded[sectionConfig.id]
            local header = self:GetSectionHeader()
            self:ConfigureSectionHeader(header, sectionConfig, yOffset, isExpanded)
            yOffset = yOffset + headerHeight
            if isExpanded and sectionConfig.items then
                local sectionDisabled = sectionConfig.elvUIDisabled and NRSKNUI:ShouldNotLoadModule()
                for _, itemConfig in ipairs(sectionConfig.items) do
                    local item = self:GetStaticSidebarItem()
                    item:SetParent(scrollChild)
                    local horizontalPadding = Theme.paddingSmall
                    item:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", horizontalPadding + itemIndent, -yOffset)
                    item:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -horizontalPadding, -yOffset)
                    item.id = itemConfig.id
                    item.label:SetText(itemConfig.text or "")

                    if sectionDisabled then
                        item.label:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3],
                            0.35)
                        item.accentBar:Hide()
                        item.selectedBg:Hide()
                        item:EnableMouse(false)
                        item.disabled = true
                    else
                        item.disabled = false
                        item:EnableMouse(true)
                        if itemConfig.id == self.selectedSidebarItem then
                            item.accentBar:Show()
                            item.selectedBg:Show()
                            item.label:SetTextColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
                        else
                            item.accentBar:Hide()
                            item.selectedBg:Hide()
                            item.label:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2],
                                Theme.textSecondary[3], 1)
                        end
                    end
                    yOffset = yOffset + itemHeight + itemSpacing
                end
            end
            yOffset = yOffset + sectionSpacing
        end
    end
    scrollChild:SetHeight(yOffset + Theme.paddingSmall)
end

function GUIFrame:OpenPage(itemId, sectionId, context)
    self:Show()

    if sectionId then
        self.sidebarExpanded[sectionId] = true
        self:RefreshSidebar()
    end

    -- Store context for granular navigation
    -- Content builders can check this and apply it, then clear it
    self.pendingContext = context

    self:SelectSidebarItem(itemId)
end
