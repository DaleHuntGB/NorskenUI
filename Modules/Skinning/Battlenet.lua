---@class NRSKNUI
local NRSKNUI = select(2, ...)

---@class Battlenet: AceModule, AceEvent-3.0
local BNET = NRSKNUI:NewModule("Battlenet", "AceEvent-3.0")

local CreateFrame = CreateFrame
local ipairs = ipairs
local _G = _G
local UIParent = UIParent
local hooksecurefunc = hooksecurefunc

local anchorFrame = nil
local isRepositioning = false

local skins = {
    _G.BNToastFrame,
    _G.TimeAlertFrame,
    _G.TicketStatusFrameButton and _G.TicketStatusFrameButton.NineSlice,
}

local function SkinFrame(frame)
    if not frame or frame.__NRSKNSkinned then return end
    if frame.StripTextures then
        frame:StripTextures(true)
    elseif frame.SetBackdrop then
        frame:SetBackdrop(nil)
    end
    if frame.NineSlice then frame.NineSlice:Hide() end
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            tile = false,
            edgeSize = 1,
        })
        frame:SetBackdropColor(0, 0, 0, 0.8)
        frame:SetBackdropBorderColor(0, 0, 0, 1)
    end
    frame.__NRSKNSkinned = true
end

local function CreateAnchorFrame()
    if anchorFrame then return anchorFrame end
    anchorFrame = CreateFrame("Frame", "NRSKNUI_BNToastAnchor", UIParent)
    anchorFrame:SetSize(300, 50)
    anchorFrame:SetFrameStrata("DIALOG")
    return anchorFrame
end

local function PositionAnchorFrame()
    if not anchorFrame then return end
    local posDB = BNET.db.Position
    anchorFrame:ClearAllPoints()
    anchorFrame:SetPoint(posDB.AnchorFrom, UIParent, posDB.AnchorTo, posDB.XOffset, posDB.YOffset)
end

local function AttachToastToAnchor()
    if not anchorFrame or not _G.BNToastFrame then return end
    if isRepositioning then return end
    isRepositioning = true

    _G.BNToastFrame:ClearAllPoints()
    _G.BNToastFrame:SetPoint("BOTTOMLEFT", anchorFrame, "BOTTOMLEFT", 0, 0)

    local width = _G.BNToastFrame:GetWidth()
    local height = _G.BNToastFrame:GetHeight()
    if width and width > 0 and height and height > 0 then anchorFrame:SetSize(width, height) end

    isRepositioning = false
end

local function SetupPositionHooks()
    if not _G.BNToastFrame then return end
    hooksecurefunc(_G.BNToastFrame, "SetPoint", function() AttachToastToAnchor() end)
    _G.BNToastFrame:HookScript("OnShow", function() C_Timer.After(0, AttachToastToAnchor) end)
end

function BNET:UpdateDB()
    self.db = NRSKNUI.db.profile.Skinning.Battlenet
end

function BNET:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

function BNET:OnEnable()
    if NRSKNUI:ShouldNotLoadModule() then return end -- Skip if ElvUI is loaded, to avoid conflicts
    if not self.db.Enabled then return end
    for _, frame in ipairs(skins) do SkinFrame(frame) end
    CreateAnchorFrame()
    PositionAnchorFrame()
    SetupPositionHooks()
    AttachToastToAnchor()

    NRSKNUI.EditMode:RegisterElement({
        key = "BNETModule",
        displayName = "BNet Popup",
        frame = anchorFrame,
        getPosition = function()
            return self.db.Position
        end,
        setPosition = function(pos)
            self.db.Position.AnchorFrom = pos.AnchorFrom
            self.db.Position.AnchorTo = pos.AnchorTo
            self.db.Position.XOffset = pos.XOffset
            self.db.Position.YOffset = pos.YOffset
            PositionAnchorFrame()
        end,
        getParentFrame = function()
            return UIParent
        end,
    })
end

function BNET:ApplySettings()
    if NRSKNUI:ShouldNotLoadModule() then return end
    PositionAnchorFrame()
end
