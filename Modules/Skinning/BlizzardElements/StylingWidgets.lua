---@class NRSKNUI
local NRSKNUI = select(2, ...)

local hooksecurefunc = hooksecurefunc
local strfind = string.find
local Mixin = Mixin
local CreateFrame = CreateFrame
local pairs = pairs

NRSKNUI.BlizzSkin = NRSKNUI.BlizzSkin or {}
local BSKIN = NRSKNUI.BlizzSkin

---@param frame Frame
---@param kill boolean? Kill the texture instead of just clearing
function BSKIN:StripTextures(frame, kill)
    if not frame or not frame.GetRegions then return end

    for _, region in pairs({ frame:GetRegions() }) do
        if region and region:IsObjectType("Texture") then
            if kill then
                region:Hide()
                region.Show = region.Hide
            else
                region:SetTexture(nil)
                region:SetAtlas("")
            end
        end
    end
end

---@param bar StatusBar
---@param template string? Backdrop template type
function BSKIN:CreateStatusBarBackdrop(bar, template)
    if not bar or bar.backdrop then return end

    local backdrop = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    backdrop:SetPoint("TOPLEFT", bar, -1, 1)
    backdrop:SetPoint("BOTTOMRIGHT", bar, 1, -1)
    backdrop:SetFrameLevel(math.max(0, bar:GetFrameLevel() - 1))
    backdrop:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })

    if template == "Transparent" then
        backdrop:SetBackdropColor(0, 0, 0, 0.5)
    else
        backdrop:SetBackdropColor(0, 0, 0, 0.8)
    end

    NRSKNUI:AddBorders(backdrop, { 0, 0, 0, 1 })
    bar.backdrop = backdrop

    return backdrop
end

---@param icon Texture
---@param createBackdrop boolean? Create a backdrop frame behind the icon
function BSKIN:HandleIcon(icon, createBackdrop)
    if not icon then return end

    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    if createBackdrop and not icon.backdrop then
        local parent = icon:GetParent()
        local backdrop = CreateFrame("Frame", nil, parent)
        backdrop:SetPoint("TOPLEFT", icon, -1, 1)
        backdrop:SetPoint("BOTTOMRIGHT", icon, 1, -1)
        NRSKNUI:AddBorders(backdrop, { 0, 0, 0, 1 })
        icon.backdrop = backdrop
    end
end

-- Collapse button mixins and styling

---@class CollapseButtonMixin: Button
---@field __texture Texture
---@field __highlight Texture
---@field bg Frame
---@field settingTexture boolean?
---@field styled boolean?
local CollapseButtonMixin = {}

local EXPAND_ATLAS = "UI-QuestTrackerButton-Secondary-Expand"
local COLLAPSE_ATLAS = "UI-QuestTrackerButton-Secondary-Collapse"
local HIGHTLIGHT_ATLAS = "UI-QuestTrackerButton-Yellow-Highlight"

function CollapseButtonMixin:DoCollapse(collapsed)
    if collapsed then
        self.__texture:SetAtlas(EXPAND_ATLAS, true)
    else
        self.__texture:SetAtlas(COLLAPSE_ATLAS, true)
    end
end

function CollapseButtonMixin:ResetTexture(texture)
    if self.settingTexture then return end
    self.settingTexture = true
    self:SetNormalTexture(0)

    if texture and texture ~= "" then
        if strfind(texture, "Plus") or strfind(texture, "[Cc]losed") then
            self:DoCollapse(true)
        elseif strfind(texture, "Minus") or strfind(texture, "[Oo]pen") then
            self:DoCollapse(false)
        end
    end
    self.settingTexture = nil
end

function CollapseButtonMixin:ResetAtlas(atlas)
    if self.settingTexture then return end
    self.settingTexture = true
    self:SetNormalAtlas("")

    if atlas and atlas ~= "" then
        if strfind(atlas, "Plus") or strfind(atlas, "[Cc]losed") or strfind(atlas, "Expand") then
            self:DoCollapse(true)
        elseif strfind(atlas, "Minus") or strfind(atlas, "[Oo]pen") or strfind(atlas, "Collapse") then
            self:DoCollapse(false)
        end
    end
    self.settingTexture = nil
end

function CollapseButtonMixin:OnEnter() if self:IsEnabled() and self.__highlight then self.__highlight:Show() end end

function CollapseButtonMixin:OnLeave() if self.__highlight then self.__highlight:Hide() end end

---@param button Button
---@param isAtlas boolean?
function BSKIN:ReskinCollapse(button, isAtlas)
    if not button or button.styled then return end

    Mixin(button, CollapseButtonMixin)

    button:SetNormalTexture(0)
    button:SetHighlightTexture(0)
    button:SetPushedTexture(0)

    local normalTex = button:GetNormalTexture()
    if normalTex then normalTex:SetAlpha(0) end

    local pushedTex = button:GetPushedTexture()
    if pushedTex then pushedTex:SetAlpha(0) end

    local container = CreateFrame("Frame", nil, button)
    container:SetAllPoints(button)
    container:SetFrameLevel(button:GetFrameLevel() + 1)
    button.bg = container

    local texture = container:CreateTexture(nil, "OVERLAY", nil, 6)
    texture:SetPoint("CENTER")
    texture:SetAtlas(COLLAPSE_ATLAS, true)
    button.__texture = texture

    local highlight = container:CreateTexture(nil, "OVERLAY", nil, 7)
    highlight:SetPoint("CENTER")
    highlight:SetAtlas(HIGHTLIGHT_ATLAS, true)
    highlight:Hide()
    button.__highlight = highlight

    button:HookScript("OnEnter", button.OnEnter)
    button:HookScript("OnLeave", button.OnLeave)

    if isAtlas then
        hooksecurefunc(button, "SetNormalAtlas", button.ResetAtlas)
    else
        hooksecurefunc(button, "SetNormalTexture", button.ResetTexture)
    end

    button.styled = true
end
