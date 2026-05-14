---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then
    error("SpellAlert: Addon object not initialized. Check file load order!")
    return
end

---@class SpellAlert: AceModule, AceEvent-3.0
local SA = NorskenUI:NewModule("SpellAlert", "AceEvent-3.0")

local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo
local C_Timer = C_Timer
local SetCVar = SetCVar

local SpellActivationOverlayFrame = SpellActivationOverlayFrame

function SA:UpdateDB()
    self.db = NRSKNUI.db.profile.Miscellaneous.SpellAlert
end

function SA:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

function SA:GetCurrentSpecID()
    local specIndex = GetSpecialization()
    if not specIndex then return nil end
    local specID = GetSpecializationInfo(specIndex)
    return specID
end

function SA:GetCurrentSettings()
    if self.db.UseGlobal then
        return self.db.Global
    end

    local specID = self:GetCurrentSpecID()
    if specID and self.db.Specs[specID] then
        local specSettings = self.db.Specs[specID]
        if specSettings.UseGlobal then return self.db.Global end
        return specSettings
    end

    return self.db.Global
end

function SA:EnsureSpecEntry(specID)
    if not specID then return end
    if not self.db.Specs[specID] then
        self.db.Specs[specID] = {
            Scale = self.db.Global.Scale,
            Alpha = self.db.Global.Alpha,
            UseGlobal = true,
        }
    end
end

function SA:ApplySettings()
    if not self:IsEnabled() then return end
    if not SpellActivationOverlayFrame then return end

    local settings = self:GetCurrentSettings()
    if not settings then return end

    SetCVar("displaySpellActivationOverlays", 1)
    SetCVar("spellAlertOpacity", 1)

    SpellActivationOverlayFrame:SetScale(settings.Scale)
    SpellActivationOverlayFrame:SetAlpha(settings.Alpha)

    self.currentSpecID = self:GetCurrentSpecID()
end

function SA:OnSpecChanged()
    C_Timer.After(1, function()
        if self:IsEnabled() then self:ApplySettings() end
    end)
end

function SA:OnEnable()
    if not self.db.Enabled then return end

    C_Timer.After(1, function() self:ApplySettings() end)

    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", "OnSpecChanged")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        C_Timer.After(0.5, function() self:ApplySettings() end)
    end)
end

function SA:OnDisable()
    self:UnregisterAllEvents()

    if SpellActivationOverlayFrame then
        SpellActivationOverlayFrame:SetScale(1.0)
        SpellActivationOverlayFrame:SetAlpha(1.0)
    end
end

function SA:ShowPreview()
    self.isPreview = true
    self:ApplySettings()
end

function SA:HidePreview()
    self.isPreview = false
    if not self.db.Enabled then
        if SpellActivationOverlayFrame then
            SpellActivationOverlayFrame:SetScale(1.0)
            SpellActivationOverlayFrame:SetAlpha(1.0)
        end
    end
end
