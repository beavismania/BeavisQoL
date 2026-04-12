local _, BeavisQoL = ...

BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc
local L = BeavisQoL.L

local baseGetMiscDB = Misc.GetMiscDB
local MinimapHudWatcher = CreateFrame("Frame")

local DEFAULT_MINIMAP_HUD_SIZE = 0.58
local MIN_MINIMAP_HUD_SIZE = 0.35
local MAX_MINIMAP_HUD_SIZE = 0.85
local MINIMAP_HUD_SIZE_STEP = 0.05
local DEFAULT_MINIMAP_HUD_MAP_ALPHA = 0.25
local MIN_MINIMAP_HUD_MAP_ALPHA = 0.2
local MAX_MINIMAP_HUD_MAP_ALPHA = 1
local MINIMAP_HUD_MAP_ALPHA_STEP = 0.05

local FLOOR = math.floor
local MAX = math.max
local MIN = math.min
local unpack = unpack or table.unpack
local Minimap_UpdateRotationSetting = Minimap_UpdateRotationSetting or function() end

local OverlayFrame
local MinimapDummy
local OverlayCoords
local OverlayMouseButton
local OverlayCloseButton
local OverlayControls
local OverlayRefreshElapsed = 0

local RuntimeState = {
    active = false,
    hiddenFramesApplied = false,
    hiddenFrames = {},
    minimapState = nil,
    movedChildren = {},
}

local function RefreshMiscPageState()
    local miscPage = BeavisQoL.Pages and BeavisQoL.Pages.Misc
    if miscPage and miscPage:IsShown() and miscPage.RefreshState then
        miscPage:RefreshState()
    end
end

local function PrintAddonMessage(messageText)
    if type(messageText) ~= "string" or messageText == "" then
        return
    end

    local finalText = (L("ADDON_MESSAGE") or "Beavis QoL: %s"):format(messageText)
    if DEFAULT_CHAT_FRAME and type(DEFAULT_CHAT_FRAME.AddMessage) == "function" then
        DEFAULT_CHAT_FRAME:AddMessage(finalText)
        return
    end

    print(finalText)
end

local function GetCVarValue(name)
    if C_CVar and type(C_CVar.GetCVar) == "function" then
        return C_CVar.GetCVar(name)
    end

    if type(GetCVar) == "function" then
        return GetCVar(name)
    end

    return nil
end

local function SetCVarValue(name, value)
    if C_CVar and type(C_CVar.SetCVar) == "function" then
        C_CVar.SetCVar(name, value)
        return
    end

    if type(SetCVar) == "function" then
        SetCVar(name, value)
    end
end

local function Clamp(value, minimumValue, maximumValue)
    if value < minimumValue then
        return minimumValue
    end

    if value > maximumValue then
        return maximumValue
    end

    return value
end

local function NormalizeHudSize(value)
    local numericValue = tonumber(value) or DEFAULT_MINIMAP_HUD_SIZE
    local clampedValue = Clamp(numericValue, MIN_MINIMAP_HUD_SIZE, MAX_MINIMAP_HUD_SIZE)
    local stepIndex = FLOOR((((clampedValue - MIN_MINIMAP_HUD_SIZE) / MINIMAP_HUD_SIZE_STEP) + 0.5))
    local normalizedValue = MIN_MINIMAP_HUD_SIZE + (stepIndex * MINIMAP_HUD_SIZE_STEP)
    return Clamp((FLOOR((normalizedValue * 100) + 0.5) / 100), MIN_MINIMAP_HUD_SIZE, MAX_MINIMAP_HUD_SIZE)
end

local function NormalizeHudMapAlpha(value)
    local numericValue = tonumber(value) or DEFAULT_MINIMAP_HUD_MAP_ALPHA
    local clampedValue = Clamp(numericValue, MIN_MINIMAP_HUD_MAP_ALPHA, MAX_MINIMAP_HUD_MAP_ALPHA)
    local stepIndex = FLOOR((((clampedValue - MIN_MINIMAP_HUD_MAP_ALPHA) / MINIMAP_HUD_MAP_ALPHA_STEP) + 0.5))
    local normalizedValue = MIN_MINIMAP_HUD_MAP_ALPHA + (stepIndex * MINIMAP_HUD_MAP_ALPHA_STEP)
    return Clamp((FLOOR((normalizedValue * 100) + 0.5) / 100), MIN_MINIMAP_HUD_MAP_ALPHA, MAX_MINIMAP_HUD_MAP_ALPHA)
end

local function SetHudRotationEnabled(enabled)
    local targetValue = enabled and "1" or "0"
    if GetCVarValue("rotateMinimap") == targetValue then
        return
    end

    SetCVarValue("rotateMinimap", targetValue)
    Minimap_UpdateRotationSetting()
end

function Misc.GetMiscDB()
    local db

    if baseGetMiscDB then
        db = baseGetMiscDB()
    else
        BeavisQoLDB = BeavisQoLDB or {}
        BeavisQoLDB.misc = BeavisQoLDB.misc or {}
        db = BeavisQoLDB.misc
    end

    if db.minimapHudEnabled == nil then
        db.minimapHudEnabled = true
    end

    if db.minimapHudSize == nil then
        db.minimapHudSize = DEFAULT_MINIMAP_HUD_SIZE
    end

    if db.minimapHudShowCoordinates == nil then
        db.minimapHudShowCoordinates = true
    end

    if db.minimapHudMouseEnabled == nil then
        db.minimapHudMouseEnabled = false
    end

    if db.minimapHudHideElements == nil then
        db.minimapHudHideElements = true
    end

    if db.minimapHudMapAlpha == nil then
        db.minimapHudMapAlpha = DEFAULT_MINIMAP_HUD_MAP_ALPHA
    end

    db.minimapHudSize = NormalizeHudSize(db.minimapHudSize)
    db.minimapHudMapAlpha = NormalizeHudMapAlpha(db.minimapHudMapAlpha)

    return db
end

function Misc.IsMinimapHudEnabled()
    return Misc.GetMiscDB().minimapHudEnabled == true
end

function Misc.IsMinimapHudActive()
    return RuntimeState.active == true
end

function Misc.GetMinimapHudSize()
    return NormalizeHudSize(Misc.GetMiscDB().minimapHudSize)
end

function Misc.IsMinimapHudCoordinatesShown()
    return Misc.GetMiscDB().minimapHudShowCoordinates ~= false
end

function Misc.IsMinimapHudMouseEnabled()
    return Misc.GetMiscDB().minimapHudMouseEnabled == true
end

function Misc.ShouldMinimapHudHideElements()
    return Misc.GetMiscDB().minimapHudHideElements ~= false
end

function Misc.GetMinimapHudMapAlpha()
    return NormalizeHudMapAlpha(Misc.GetMiscDB().minimapHudMapAlpha)
end

local function GetHudAnchorFrame()
    return rawget(_G, "WorldFrame") or UIParent
end

local function GetHudDiameter()
    local anchorFrame = GetHudAnchorFrame()
    local width, height = anchorFrame:GetSize()
    if width <= 0 or height <= 0 then
        width, height = UIParent:GetSize()
    end

    return MAX(220, FLOOR((MIN(width, height) * Misc.GetMinimapHudSize()) + 0.5))
end

local function IsMinimapReference(value)
    return value == Minimap or value == "Minimap"
end

local function CaptureFramePoints(frame)
    local points = {}
    if not frame or not frame.GetNumPoints then
        return points
    end

    for pointIndex = 1, frame:GetNumPoints() do
        points[#points + 1] = { frame:GetPoint(pointIndex) }
    end

    return points
end

local function RestoreFramePoints(frame, points, replaceMinimapWith, setPointFunc)
    if not frame or not frame.ClearAllPoints then
        return
    end

    frame:ClearAllPoints()
    if type(points) ~= "table" or #points == 0 then
        return
    end

    local setter = setPointFunc or frame.SetPoint
    if type(setter) ~= "function" then
        return
    end

    for _, pointData in ipairs(points) do
        local point, relativeTo, relativePoint, x, y = unpack(pointData)
        if replaceMinimapWith and IsMinimapReference(relativeTo) then
            relativeTo = replaceMinimapWith
        end
        setter(frame, point, relativeTo, relativePoint, x, y)
    end
end

local function EnsureMinimapDummy()
    if MinimapDummy then
        return MinimapDummy
    end

    local frame = CreateFrame("Frame", "BeavisQoLMinimapHudDummy", UIParent)
    frame:SetClampedToScreen(true)
    frame:Hide()
    MinimapDummy = frame
    return frame
end

local function CaptureMinimapState()
    if not Minimap then
        return nil
    end

    return {
        parent = Minimap:GetParent(),
        points = CaptureFramePoints(Minimap),
        scale = Minimap:GetScale(),
        size = { Minimap:GetSize() },
        strata = Minimap:GetFrameStrata(),
        level = Minimap:GetFrameLevel(),
        alpha = Minimap:GetAlpha(),
        mouseEnabled = Minimap:IsMouseEnabled(),
        mouseWheelEnabled = Minimap:IsMouseWheelEnabled(),
        rotateMinimap = GetCVarValue("rotateMinimap"),
    }
end

local function SyncDummyToMinimap(state)
    if not Minimap then
        return
    end

    local dummy = EnsureMinimapDummy()
    local sourceState = state or CaptureMinimapState()
    if not sourceState then
        return
    end

    dummy:SetParent(sourceState.parent or UIParent)
    dummy:SetScale(sourceState.scale or 1)
    if type(sourceState.size) == "table" then
        dummy:SetSize(sourceState.size[1] or 0, sourceState.size[2] or 0)
    end
    if sourceState.strata then
        dummy:SetFrameStrata(sourceState.strata)
    end
    if sourceState.level then
        dummy:SetFrameLevel(sourceState.level)
    end

    RestoreFramePoints(dummy, sourceState.points)
end

local function RedirectObjectToDummy(object)
    if not object or RuntimeState.movedChildren[object] then
        return
    end

    local originalSetParent = object.SetParent
    local originalSetPoint = object.SetPoint
    if type(originalSetParent) ~= "function" or type(originalSetPoint) ~= "function" then
        return
    end

    local objectState = {
        parent = object.GetParent and object:GetParent() or nil,
        points = CaptureFramePoints(object),
        setParent = originalSetParent,
        setPoint = originalSetPoint,
    }

    if object.GetFrameStrata and object.GetFrameLevel then
        objectState.strata = object:GetFrameStrata()
        objectState.level = object:GetFrameLevel()
    end

    RuntimeState.movedChildren[object] = objectState

    object.SetParent = function(self, parent)
        if RuntimeState.active and IsMinimapReference(parent) then
            parent = EnsureMinimapDummy()
        end
        return objectState.setParent(self, parent)
    end

    object.SetPoint = function(self, point, relativeTo, relativePoint, x, y)
        if RuntimeState.active and IsMinimapReference(relativeTo) then
            relativeTo = EnsureMinimapDummy()
        end
        return objectState.setPoint(self, point, relativeTo, relativePoint, x, y)
    end

    if object.GetParent and object:GetParent() == Minimap then
        objectState.setParent(object, EnsureMinimapDummy())
    end
    RestoreFramePoints(object, objectState.points, EnsureMinimapDummy(), objectState.setPoint)

    if objectState.strata then
        object:SetFrameStrata(objectState.strata)
        object:SetFrameLevel(objectState.level or 0)
    end
end

local function RedirectObjectTreeToDummy(object)
    if not object then
        return
    end

    RedirectObjectToDummy(object)

    if object.GetChildren then
        local children = { object:GetChildren() }
        for _, child in ipairs(children) do
            RedirectObjectTreeToDummy(child)
        end
    end

    if not object.GetRegions then
        return
    end

    local regions = { object:GetRegions() }
    for _, region in ipairs(regions) do
        RedirectObjectToDummy(region)
    end
end

local function MoveMinimapChildrenToDummy()
    if not Minimap then
        return
    end

    local children = { Minimap:GetChildren() }
    for _, child in ipairs(children) do
        RedirectObjectToDummy(child)
    end

    RedirectObjectTreeToDummy(rawget(_G, "MinimapBackdrop"))
end

local function RestoreMovedChildren()
    for child, childState in pairs(RuntimeState.movedChildren) do
        if type(childState.setParent) == "function" then
            child.SetParent = childState.setParent
        end
        if type(childState.setPoint) == "function" then
            child.SetPoint = childState.setPoint
        end

        if childState.parent then
            childState.setParent(child, childState.parent)
        end
        RestoreFramePoints(child, childState.points, nil, childState.setPoint)

        if childState.strata then
            child:SetFrameStrata(childState.strata)
            child:SetFrameLevel(childState.level or 0)
        end
    end

    wipe(RuntimeState.movedChildren)
end

local function RestoreHiddenFrames()
    wipe(RuntimeState.hiddenFrames)
    RuntimeState.hiddenFramesApplied = false
end

local function ApplyHiddenFrames()
    RuntimeState.hiddenFramesApplied = true
end

local function UpdateHiddenFramesForMode()
    if not RuntimeState.active then
        RestoreHiddenFrames()
        return
    end

    if Misc.ShouldMinimapHudHideElements() then
        ApplyHiddenFrames()
    else
        RestoreHiddenFrames()
    end
end

local function UpdateHudMinimapState()
    if not RuntimeState.active or not Minimap then
        return
    end

    Minimap:SetAlpha(Misc.GetMinimapHudMapAlpha())
end

local function UpdateMouseButtonText()
    if not OverlayMouseButton then
        return
    end

    if Misc.IsMinimapHudMouseEnabled() then
        OverlayMouseButton:SetText(L("MINIMAP_HUD_MOUSE_ON"))
    else
        OverlayMouseButton:SetText(L("MINIMAP_HUD_MOUSE_OFF"))
    end
end

local function UpdateCoordinatesText()
    if not OverlayCoords then
        return
    end

    if not RuntimeState.active or not Misc.IsMinimapHudCoordinatesShown() then
        OverlayCoords:Hide()
        return
    end

    if not C_Map or not C_Map.GetBestMapForUnit or not C_Map.GetPlayerMapPosition then
        OverlayCoords:Hide()
        return
    end

    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then
        OverlayCoords:Hide()
        return
    end

    local position = C_Map.GetPlayerMapPosition(mapID, "player")
    if not position then
        OverlayCoords:Hide()
        return
    end

    local mapInfo = C_Map.GetMapInfo and C_Map.GetMapInfo(mapID) or nil
    local mapName = mapInfo and mapInfo.name or ""
    local x = FLOOR((position.x * 1000) + 0.5) / 10
    local y = FLOOR((position.y * 1000) + 0.5) / 10

    if mapName ~= "" then
        OverlayCoords:SetText(string.format("%s  %.1f, %.1f", mapName, x, y))
    else
        OverlayCoords:SetText(string.format("%.1f, %.1f", x, y))
    end

    OverlayCoords:Show()
end

local function EnsureOverlayFrame()
    if OverlayFrame then
        return OverlayFrame
    end

    local frame = CreateFrame("Frame", "BeavisQoLMinimapHudFrame", UIParent)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(20)
    frame:SetClampedToScreen(true)
    frame:Hide()

    local coords = frame:CreateFontString(nil, "OVERLAY")
    coords:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    coords:SetTextColor(1, 0.88, 0.62, 1)
    coords:SetShadowOffset(1, -1)
    coords:SetShadowColor(0, 0, 0, 0.8)
    OverlayCoords = coords

    local controls = CreateFrame("Frame", nil, frame)
    controls:SetSize(180, 24)
    OverlayControls = controls

    local mouseButton = CreateFrame("Button", nil, controls, "UIPanelButtonTemplate")
    mouseButton:SetSize(96, 22)
    mouseButton:SetPoint("RIGHT", controls, "CENTER", -4, 0)
    mouseButton:SetScript("OnClick", function()
        if Misc.SetMinimapHudMouseEnabled then
            Misc.SetMinimapHudMouseEnabled(not Misc.IsMinimapHudMouseEnabled())
        end
    end)
    OverlayMouseButton = mouseButton

    local closeButton = CreateFrame("Button", nil, controls, "UIPanelButtonTemplate")
    closeButton:SetSize(72, 22)
    closeButton:SetPoint("LEFT", controls, "CENTER", 4, 0)
    closeButton:SetText(L("CLOSE"))
    closeButton:SetScript("OnClick", function()
        if Misc.ToggleMinimapHud then
            Misc.ToggleMinimapHud(false)
        end
    end)
    OverlayCloseButton = closeButton

    OverlayFrame = frame
    UpdateMouseButtonText()
    return frame
end

local function ApplyMouseMode()
    if not RuntimeState.active or not Minimap then
        return
    end

    local mouseEnabled = Misc.IsMinimapHudMouseEnabled()
    Minimap:EnableMouse(mouseEnabled)
    Minimap:EnableMouseWheel(mouseEnabled)
end

local function UpdateOverlayLayout()
    local frame = EnsureOverlayFrame()
    local anchorFrame = GetHudAnchorFrame()
    local diameter = GetHudDiameter()

    frame:ClearAllPoints()
    frame:SetPoint("CENTER", anchorFrame, "CENTER", 0, 0)
    frame:SetSize(diameter, diameter)

    if OverlayCoords then
        OverlayCoords:ClearAllPoints()
        OverlayCoords:SetPoint("TOP", frame, "BOTTOM", 0, -12)
    end

    if OverlayControls then
        OverlayControls:ClearAllPoints()
        OverlayControls:SetPoint("TOP", frame, "BOTTOM", 0, -34)
    end

    if OverlayCloseButton then
        OverlayCloseButton:SetText(L("CLOSE"))
    end

    UpdateMouseButtonText()
    UpdateCoordinatesText()

    if RuntimeState.active and Minimap then
        Minimap:ClearAllPoints()
        Minimap:SetPoint("CENTER", frame, "CENTER", 0, 0)
        Minimap:SetSize(diameter, diameter)
        Minimap:SetScale(1)
        Minimap:SetFrameStrata("LOW")
        Minimap:SetFrameLevel(1)
        Minimap:SetAlpha(Misc.GetMinimapHudMapAlpha())
    end
end

local function IsCombatLocked()
    return InCombatLockdown and InCombatLockdown() == true
end

local function ActivateHud()
    if RuntimeState.active or not Minimap then
        return false
    end

    EnsureOverlayFrame()
    RuntimeState.minimapState = CaptureMinimapState()
    SyncDummyToMinimap(RuntimeState.minimapState)

    RuntimeState.active = true
    MoveMinimapChildrenToDummy()
    UpdateHiddenFramesForMode()
    SetHudRotationEnabled(true)

    if MinimapDummy then
        MinimapDummy:Show()
    end

    Minimap:Hide()
    Minimap:SetParent(OverlayFrame)
    UpdateOverlayLayout()
    ApplyMouseMode()
    UpdateHudMinimapState()
    OverlayFrame:Show()
    Minimap:Show()

    UpdateCoordinatesText()
    RefreshMiscPageState()
    return true
end

local function DeactivateHud()
    if not RuntimeState.active or not Minimap then
        return false
    end

    RuntimeState.active = false
    RestoreHiddenFrames()

    Minimap:Hide()

    local minimapState = RuntimeState.minimapState
    if minimapState then
        Minimap:SetParent(minimapState.parent or UIParent)
        Minimap:SetScale(minimapState.scale or 1)
        if type(minimapState.size) == "table" then
            Minimap:SetSize(minimapState.size[1] or 0, minimapState.size[2] or 0)
        end
        if minimapState.strata then
            Minimap:SetFrameStrata(minimapState.strata)
        end
        if minimapState.level then
            Minimap:SetFrameLevel(minimapState.level)
        end
        Minimap:SetAlpha(minimapState.alpha or 1)
        Minimap:EnableMouse(minimapState.mouseEnabled == true)
        Minimap:EnableMouseWheel(minimapState.mouseWheelEnabled == true)
        RestoreFramePoints(Minimap, minimapState.points)
        if minimapState.rotateMinimap ~= nil then
            SetCVarValue("rotateMinimap", minimapState.rotateMinimap)
            Minimap_UpdateRotationSetting()
        end
    end

    RestoreMovedChildren()
    RuntimeState.minimapState = nil

    if MinimapDummy then
        MinimapDummy:Hide()
    end

    if OverlayFrame then
        OverlayFrame:Hide()
    end

    Minimap:Show()
    UpdateCoordinatesText()
    RefreshMiscPageState()
    return true
end

function Misc.ToggleMinimapHud(forceState)
    if not Minimap then
        return false
    end

    local targetState = forceState
    if targetState == nil then
        targetState = not RuntimeState.active
    end

    targetState = targetState == true

    if targetState and not Misc.IsMinimapHudEnabled() then
        RefreshMiscPageState()
        return false
    end

    if IsCombatLocked() then
        PrintAddonMessage(L("MINIMAP_HUD_COMBAT_BLOCKED"))
        RefreshMiscPageState()
        return false
    end

    if targetState then
        return ActivateHud()
    end

    return DeactivateHud()
end

function Misc.SetMinimapHudEnabled(enabled)
    local db = Misc.GetMiscDB()
    local targetState = enabled == true

    if db.minimapHudEnabled == targetState then
        RefreshMiscPageState()
        return true
    end

    if not targetState and RuntimeState.active and IsCombatLocked() then
        PrintAddonMessage(L("MINIMAP_HUD_COMBAT_BLOCKED"))
        RefreshMiscPageState()
        return false
    end

    db.minimapHudEnabled = targetState

    if not targetState and RuntimeState.active then
        DeactivateHud()
    else
        RefreshMiscPageState()
    end

    return true
end

function Misc.SetMinimapHudSize(sizeValue)
    Misc.GetMiscDB().minimapHudSize = NormalizeHudSize(sizeValue)
    if RuntimeState.active then
        UpdateOverlayLayout()
    end
    RefreshMiscPageState()
end

function Misc.SetMinimapHudCoordinatesShown(enabled)
    Misc.GetMiscDB().minimapHudShowCoordinates = enabled ~= false
    UpdateCoordinatesText()
    RefreshMiscPageState()
end

function Misc.SetMinimapHudMouseEnabled(enabled)
    Misc.GetMiscDB().minimapHudMouseEnabled = enabled == true
    if RuntimeState.active then
        ApplyMouseMode()
        UpdateMouseButtonText()
    end
    RefreshMiscPageState()
end

function Misc.SetMinimapHudHideElements(enabled)
    Misc.GetMiscDB().minimapHudHideElements = enabled ~= false
    UpdateHiddenFramesForMode()
    RefreshMiscPageState()
end

function Misc.SetMinimapHudMapAlpha(alphaValue)
    Misc.GetMiscDB().minimapHudMapAlpha = NormalizeHudMapAlpha(alphaValue)
    UpdateHudMinimapState()
    RefreshMiscPageState()
end

MinimapHudWatcher:RegisterEvent("DISPLAY_SIZE_CHANGED")
MinimapHudWatcher:RegisterEvent("MINIMAP_UPDATE_ZOOM")
MinimapHudWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
MinimapHudWatcher:RegisterEvent("UI_SCALE_CHANGED")
MinimapHudWatcher:SetScript("OnEvent", function(_, event)
    if event == "DISPLAY_SIZE_CHANGED" or event == "UI_SCALE_CHANGED" or event == "PLAYER_ENTERING_WORLD" or event == "MINIMAP_UPDATE_ZOOM" then
        if RuntimeState.active then
            UpdateOverlayLayout()
            UpdateHiddenFramesForMode()
            UpdateHudMinimapState()
        end
    end
end)

MinimapHudWatcher:SetScript("OnUpdate", function(_, elapsed)
    if not RuntimeState.active then
        OverlayRefreshElapsed = 0
        return
    end

    OverlayRefreshElapsed = OverlayRefreshElapsed + (elapsed or 0)
    if OverlayRefreshElapsed >= 0.10 then
        OverlayRefreshElapsed = 0
        UpdateCoordinatesText()
    end
end)

BeavisQoL.IsMinimapHudEnabled = function()
    return Misc.IsMinimapHudEnabled()
end

BeavisQoL.IsMinimapHudActive = function()
    return Misc.IsMinimapHudActive()
end

BeavisQoL.ToggleMinimapHud = function(forceState)
    return Misc.ToggleMinimapHud(forceState)
end
