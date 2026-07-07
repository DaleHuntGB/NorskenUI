---@class NRSKNUI
local NRSKNUI = select(2, ...)

-- Module used to hide frames safely

local CreateFrame = CreateFrame
local type = type
local select = select
local pcall = pcall
local ipairs = ipairs
local _G = _G

-- Hidden dummy frame we anchor stuff we want to hide to
local hidden = CreateFrame('Frame')
hidden:Hide()

---Hide objects safely and reparent them to a hidden frame
---@param object any
function NRSKNUI:Hide(object, ...)
    if type(object) == 'string' then
        object = _G[object]
    end

    if ... then
        -- Iterate through arguments, they're children referenced by key
        for index = 1, select('#', ...) do
            object = object[select(index, ...)]
        end
    end

    if object then
        if object.HideBase then
            object:HideBase(true) -- Edit mode adds this fallback when it overrides Hide
        else
            object:Hide(true)
        end

        if object.EnableMouse then
            object:EnableMouse(false)
        end

        if object.UnregisterAllEvents then
            object:UnregisterAllEvents()
            object:SetAttribute('statehidden', true) -- Useful for hiding secure template based objects
        end

        if object.SetUserPlaced then
            -- Useful for hiding blizzard objects that respect user placement
            pcall(object.SetUserPlaced, object, true)
            pcall(object.SetDontSavePosition, object, true)
        end

        object:SetParent(hidden)
    end
end

-- Expose frame so it can be accessed
NRSKNUI.HiddenFrame = hidden

---Iterates over a frame's child frames and hides each Texture region.
---@param frame Frame | string
function NRSKNUI:HideTextures(frame, ...)
    if type(frame) == 'string' then
        frame = _G[frame]
    end

    for _, region in ipairs({ frame:GetRegions() }) do
        if ... then
            if region:IsObjectType("Texture") and region:GetAtlas() == ... then
                region:Hide()
            end
        else
            if region:IsObjectType("Texture") then
                region:Hide()
            end
        end
    end
end
