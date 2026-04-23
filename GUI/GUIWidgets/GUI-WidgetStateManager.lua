---@class NRSKNUI
local NRSKNUI = select(2, ...)
---@class GUIFrame
local GUIFrame = NRSKNUI.GUIFrame

local ipairs = ipairs
local pairs = pairs
local type = type

---@class NUIWidgetStateManagerMixin
---@field groups table<string, Frame[]>
---@field conditions table<string, function>
local NUIWidgetStateManagerMixin = {}

---@param widget Frame
---@param ... string
function NUIWidgetStateManagerMixin:Register(widget, ...)
    if not widget then return end
    local groupNames = { ... }
    for _, groupName in ipairs(groupNames) do
        self.groups[groupName] = self.groups[groupName] or {}
        self.groups[groupName][#self.groups[groupName] + 1] = widget
    end
end

---@param widgets Frame[]
---@param groupName string
function NUIWidgetStateManagerMixin:RegisterGroup(widgets, groupName)
    if not widgets or not groupName then return end
    self.groups[groupName] = self.groups[groupName] or {}
    for _, widget in ipairs(widgets) do
        self.groups[groupName][#self.groups[groupName] + 1] = widget
    end
end

---@param groupName string
---@param conditionFn fun(): boolean
function NUIWidgetStateManagerMixin:SetCondition(groupName, conditionFn)
    self.conditions[groupName] = conditionFn
end

---@param mainEnabled boolean
function NUIWidgetStateManagerMixin:UpdateAll(mainEnabled)
    for groupName, widgets in pairs(self.groups) do
        local groupEnabled = mainEnabled

        if groupEnabled and self.conditions[groupName] then
            local condition = self.conditions[groupName]
            if type(condition) == "function" then
                groupEnabled = condition()
            end
        end

        for _, widget in ipairs(widgets) do
            if widget.SetEnabled then
                widget:SetEnabled(groupEnabled)
            elseif widget.SetDisabled then
                widget:SetDisabled(not groupEnabled)
            end
        end
    end
end

---@param groupName string
---@param enabled boolean
function NUIWidgetStateManagerMixin:UpdateGroup(groupName, enabled)
    local widgets = self.groups[groupName]
    if not widgets then return end

    for _, widget in ipairs(widgets) do
        if widget.SetEnabled then
            widget:SetEnabled(enabled)
        elseif widget.SetDisabled then
            widget:SetDisabled(not enabled)
        end
    end
end

---@param groupName string
---@return Frame[]
function NUIWidgetStateManagerMixin:GetGroup(groupName)
    return self.groups[groupName] or {}
end

function NUIWidgetStateManagerMixin:Clear()
    self.groups = {}
    self.conditions = {}
end

---@return NUIWidgetStateManager
function GUIFrame:CreateWidgetStateManager()
    local manager = {
        groups = {},
        conditions = {},
    }

    Mixin(manager, NUIWidgetStateManagerMixin)

    return manager
end
