local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content
local L = BeavisQoL.L

BeavisQoL.MarkerBarModule = BeavisQoL.MarkerBarModule or {}
local MarkerBarModule = BeavisQoL.MarkerBarModule

local DEFAULT_OVERLAY_SCALE = 1.00
local MIN_OVERLAY_SCALE = 0.75
local MAX_OVERLAY_SCALE = 1.60
local DEFAULT_POINT = "CENTER"
local DEFAULT_RELATIVE_POINT = "CENTER"
local DEFAULT_OFFSET_X = 0
local DEFAULT_OFFSET_Y = -180

local MARKER_BUTTONS = {
    { index = 8, texture = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8" },
    { index = 7, texture = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7" },
    { index = 6, texture = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6" },
    { index = 5, texture = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5" },
    { index = 4, texture = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4" },
    { index = 3, texture = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3" },
    { index = 2, texture = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2" },
    { index = 1, texture = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1" },
}

local BUTTON_SIZE = 34
local BUTTON_SPACING = 6
local OVERLAY_PADDING_X = 6
local OVERLAY_PADDING_Y = 4
local BASE_OVERLAY_WIDTH = (OVERLAY_PADDING_X * 2) + (#MARKER_BUTTONS * BUTTON_SIZE) + ((#MARKER_BUTTONS - 1) * BUTTON_SPACING)
local BASE_OVERLAY_HEIGHT = (OVERLAY_PADDING_Y * 2) + BUTTON_SIZE

local OverlayFrame
local OverlayButtons = {}
local PageMarkerBar
local ShowOverlayCheckbox
local LockOverlayCheckbox
local ScaleSlider
local ScaleSliderText
local LayoutMarkerBarPage
local isRefreshingPage = false
local pendingOverlayRefresh = false
local pendingOverlayStop = false
local overlayDragActive = false

local function Clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end

local function GetTextHeight(fontString, minimumHeight)
    local textHeight = fontString and fontString.GetStringHeight and fontString:GetStringHeight() or 0
    if textHeight == nil or textHeight < (minimumHeight or 0) then
        return minimumHeight or 0
    end

    return textHeight
end

local function GetSliderPercentText(value)
    return string.format("%d%%", math.floor(((tonumber(value) or DEFAULT_OVERLAY_SCALE) * 100) + 0.5))
end

local function GetMarkerBarSettings()
    BeavisQoLDB = BeavisQoLDB or {}
    BeavisQoLDB.markerBar = BeavisQoLDB.markerBar or {}

    local db = BeavisQoLDB.markerBar

    if db.overlayEnabled == nil then
        db.overlayEnabled = false
    end

    if db.overlayLocked == nil then
        db.overlayLocked = false
    end

    if type(db.overlayScale) ~= "number" then
        db.overlayScale = DEFAULT_OVERLAY_SCALE
    end
    db.overlayScale = Clamp(db.overlayScale, MIN_OVERLAY_SCALE, MAX_OVERLAY_SCALE)

    if type(db.point) ~= "string" or db.point == "" then
        db.point = DEFAULT_POINT
    end

    if type(db.relativePoint) ~= "string" or db.relativePoint == "" then
        db.relativePoint = DEFAULT_RELATIVE_POINT
    end

    if type(db.offsetX) ~= "number" then
        db.offsetX = DEFAULT_OFFSET_X
    end

    if type(db.offsetY) ~= "number" then
        db.offsetY = DEFAULT_OFFSET_Y
    end

    return db
end

local function SaveOverlayGeometry()
    if not OverlayFrame then
        return
    end

    local point, _, relativePoint, offsetX, offsetY = OverlayFrame:GetPoint(1)
    local settings = GetMarkerBarSettings()

    settings.point = point or DEFAULT_POINT
    settings.relativePoint = relativePoint or DEFAULT_RELATIVE_POINT
    settings.offsetX = math.floor((offsetX or DEFAULT_OFFSET_X) + 0.5)
    settings.offsetY = math.floor((offsetY or DEFAULT_OFFSET_Y) + 0.5)
end

local function ApplyOverlayGeometry()
    if not OverlayFrame then
        return
    end

    local settings = GetMarkerBarSettings()
    OverlayFrame:ClearAllPoints()
    OverlayFrame:SetPoint(settings.point, UIParent, settings.relativePoint, settings.offsetX, settings.offsetY)
end

local function RefreshScaleSliderText()
    if not ScaleSliderText or not ScaleSlider then
        return
    end

    ScaleSliderText:SetText(string.format("%s: %s", L("MARKER_BAR_SCALE"), GetSliderPercentText(ScaleSlider:GetValue())))
end

local function RefreshOverlayWindow()
    if not OverlayFrame then
        return
    end

    if InCombatLockdown and InCombatLockdown() then
        pendingOverlayRefresh = true
        return
    end

    pendingOverlayRefresh = false

    local settings = GetMarkerBarSettings()

    OverlayFrame:SetScale(settings.overlayScale)
    ApplyOverlayGeometry()

    OverlayFrame:SetMovable(settings.overlayLocked ~= true)
    OverlayFrame:EnableMouse(true)

    if settings.overlayEnabled then
        OverlayFrame:Show()
    else
        OverlayFrame:Hide()
    end
end

function MarkerBarModule.IsOverlayEnabled()
    return GetMarkerBarSettings().overlayEnabled == true
end

function MarkerBarModule.SetOverlayEnabled(enabled)
    GetMarkerBarSettings().overlayEnabled = enabled == true
    RefreshOverlayWindow()
end

function MarkerBarModule.IsOverlayLocked()
    return GetMarkerBarSettings().overlayLocked == true
end

function MarkerBarModule.SetOverlayLocked(locked)
    GetMarkerBarSettings().overlayLocked = locked == true
    RefreshOverlayWindow()
end

function MarkerBarModule.GetOverlayScale()
    return GetMarkerBarSettings().overlayScale
end

function MarkerBarModule.SetOverlayScale(scale)
    GetMarkerBarSettings().overlayScale = Clamp(scale or DEFAULT_OVERLAY_SCALE, MIN_OVERLAY_SCALE, MAX_OVERLAY_SCALE)
    RefreshOverlayWindow()
end

function MarkerBarModule.ResetOverlayPosition()
    local settings = GetMarkerBarSettings()
    settings.point = DEFAULT_POINT
    settings.relativePoint = DEFAULT_RELATIVE_POINT
    settings.offsetX = DEFAULT_OFFSET_X
    settings.offsetY = DEFAULT_OFFSET_Y
    RefreshOverlayWindow()
end

local function CreateSecureMarkerButton(parent, markerData, anchorTo)
    local button = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)

    if anchorTo then
        button:SetPoint("LEFT", anchorTo, "RIGHT", BUTTON_SPACING, 0)
    else
        button:SetPoint("TOPLEFT", parent, "TOPLEFT", OVERLAY_PADDING_X, -OVERLAY_PADDING_Y)
    end

    button:SetAttribute("useOnKeyDown", false)
    button:RegisterForClicks("LeftButtonUp")
    button:SetAttribute("type1", "macro")
    button:SetAttribute("macrotext1", string.format("/tm %d", markerData.index))
    button:SetAttribute("shift-type1", "worldmarker")
    button:SetAttribute("marker1", markerData.index)
    button:SetAttribute("action1", "set")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.04, 0.04, 0.05, 0.54)
    button.Background = background

    local border = button:CreateTexture(nil, "ARTWORK")
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    border:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
    border:SetHeight(1)
    border:SetColorTexture(0.88, 0.72, 0.46, 0.35)
    button.BorderTop = border

    local borderBottom = button:CreateTexture(nil, "ARTWORK")
    borderBottom:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    borderBottom:SetHeight(1)
    borderBottom:SetColorTexture(0.88, 0.72, 0.46, 0.25)
    button.BorderBottom = borderBottom

    local hoverGlow = button:CreateTexture(nil, "BORDER")
    hoverGlow:SetAllPoints()
    hoverGlow:SetColorTexture(0.88, 0.72, 0.46, 0)
    button.HoverGlow = hoverGlow

    local icon = button:CreateTexture(nil, "OVERLAY")
    icon:SetSize(22, 22)
    icon:SetPoint("CENTER")
    icon:SetTexture(markerData.texture)

    button.Icon = icon
    button.MarkerIndex = markerData.index

    button:SetScript("OnEnter", function()
        background:SetColorTexture(0.20, 0.20, 0.22, 0.92)
        border:SetColorTexture(0.88, 0.72, 0.46, 0.85)
        borderBottom:SetColorTexture(0.88, 0.72, 0.46, 0.72)
        hoverGlow:SetColorTexture(0.88, 0.72, 0.46, 0.14)
    end)

    button:SetScript("OnLeave", function()
        background:SetColorTexture(0.04, 0.04, 0.05, 0.54)
        border:SetColorTexture(0.88, 0.72, 0.46, 0.35)
        borderBottom:SetColorTexture(0.88, 0.72, 0.46, 0.25)
        hoverGlow:SetColorTexture(0.88, 0.72, 0.46, 0)
    end)

    return button
end

local function CreateOverlayFrame()
    if OverlayFrame then
        return
    end

    OverlayFrame = CreateFrame("Frame", "BeavisQoLMarkerBarOverlay", UIParent)
    OverlayFrame:SetSize(BASE_OVERLAY_WIDTH, BASE_OVERLAY_HEIGHT)
    OverlayFrame:SetClampedToScreen(true)
    OverlayFrame:SetMovable(true)
    OverlayFrame:EnableMouse(true)
    OverlayFrame:RegisterForDrag("LeftButton")
    OverlayFrame:SetFrameStrata("MEDIUM")

    OverlayFrame:SetScript("OnDragStart", function(self)
        if InCombatLockdown and InCombatLockdown() then
            return
        end

        if MarkerBarModule.IsOverlayLocked and MarkerBarModule.IsOverlayLocked() then
            return
        end

        overlayDragActive = true
        pendingOverlayStop = false
        self:StartMoving()
    end)

    OverlayFrame:SetScript("OnDragStop", function(self)
        if not overlayDragActive then
            return
        end

        if InCombatLockdown and InCombatLockdown() then
            pendingOverlayStop = true
            pendingOverlayRefresh = true
            return
        end

        self:StopMovingOrSizing()
        overlayDragActive = false
        pendingOverlayStop = false
        SaveOverlayGeometry()
    end)

    local background = OverlayFrame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.035, 0.035, 0.04, 0.26)

    local glow = OverlayFrame:CreateTexture(nil, "BORDER")
    glow:SetPoint("TOPLEFT", OverlayFrame, "TOPLEFT", 0, 0)
    glow:SetPoint("TOPRIGHT", OverlayFrame, "TOPRIGHT", 0, 0)
    glow:SetHeight(20)
    glow:SetColorTexture(0.88, 0.72, 0.46, 0.05)

    local borderTop = OverlayFrame:CreateTexture(nil, "ARTWORK")
    borderTop:SetPoint("TOPLEFT", OverlayFrame, "TOPLEFT", 0, 0)
    borderTop:SetPoint("TOPRIGHT", OverlayFrame, "TOPRIGHT", 0, 0)
    borderTop:SetHeight(1)
    borderTop:SetColorTexture(0.88, 0.72, 0.46, 0.34)

    local borderBottom = OverlayFrame:CreateTexture(nil, "ARTWORK")
    borderBottom:SetPoint("BOTTOMLEFT", OverlayFrame, "BOTTOMLEFT", 0, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", OverlayFrame, "BOTTOMRIGHT", 0, 0)
    borderBottom:SetHeight(1)
    borderBottom:SetColorTexture(0.88, 0.72, 0.46, 0.22)

    local accent = OverlayFrame:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", OverlayFrame, "TOPLEFT", 0, 0)
    accent:SetPoint("BOTTOMLEFT", OverlayFrame, "BOTTOMLEFT", 0, 0)
    accent:SetWidth(2)
    accent:SetColorTexture(0.88, 0.72, 0.46, 0.55)

    local previousButton
    for _, markerData in ipairs(MARKER_BUTTONS) do
        local button = CreateSecureMarkerButton(OverlayFrame, markerData, previousButton)

        if previousButton then
            button:ClearAllPoints()
            button:SetPoint("LEFT", previousButton, "RIGHT", BUTTON_SPACING, 0)
        else
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", OverlayFrame, "TOPLEFT", OVERLAY_PADDING_X, -OVERLAY_PADDING_Y)
        end

        OverlayButtons[#OverlayButtons + 1] = button
        previousButton = button
    end

    ApplyOverlayGeometry()
end

local function CreateCheckbox(parent, label, onClick)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetSize(24, 24)
    checkbox:SetScript("OnClick", onClick)

    local text = parent:CreateFontString(nil, "OVERLAY")
    text:SetPoint("LEFT", checkbox, "RIGHT", 8, 0)
    text:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    text:SetTextColor(0.96, 0.96, 0.96, 1)
    text:SetText(label)

    checkbox.Label = text

    return checkbox
end

local function CreateSlider(parent)
    local slider = CreateFrame("Slider", ADDON_NAME .. "MarkerBarScaleSlider", parent, "OptionsSliderTemplate")
    slider:SetMinMaxValues(MIN_OVERLAY_SCALE, MAX_OVERLAY_SCALE)
    slider:SetValueStep(0.05)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(260)

    local lowLabel = _G[slider:GetName() .. "Low"]
    local highLabel = _G[slider:GetName() .. "High"]
    local textLabel = _G[slider:GetName() .. "Text"]

    if lowLabel then
        lowLabel:SetText(GetSliderPercentText(MIN_OVERLAY_SCALE))
    end

    if highLabel then
        highLabel:SetText(GetSliderPercentText(MAX_OVERLAY_SCALE))
    end

    if textLabel then
        textLabel:SetText("")
    end

    return slider, textLabel
end

PageMarkerBar = CreateFrame("Frame", nil, Content)
PageMarkerBar:SetAllPoints()
PageMarkerBar:Hide()

local PageMarkerBarScrollFrame = CreateFrame("ScrollFrame", nil, PageMarkerBar, "UIPanelScrollFrameTemplate")
PageMarkerBarScrollFrame:SetPoint("TOPLEFT", PageMarkerBar, "TOPLEFT", 0, 0)
PageMarkerBarScrollFrame:SetPoint("BOTTOMRIGHT", PageMarkerBar, "BOTTOMRIGHT", -28, 0)
PageMarkerBarScrollFrame:EnableMouseWheel(true)

local PageMarkerBarContent = CreateFrame("Frame", nil, PageMarkerBarScrollFrame)
PageMarkerBarContent:SetSize(1, 1)
PageMarkerBarScrollFrame:SetScrollChild(PageMarkerBarContent)

local IntroPanel = CreateFrame("Frame", nil, PageMarkerBarContent)
IntroPanel:SetPoint("TOPLEFT", PageMarkerBarContent, "TOPLEFT", 20, -18)
IntroPanel:SetPoint("RIGHT", PageMarkerBarContent, "RIGHT", -20, 0)
IntroPanel:SetHeight(128)

local IntroBg = IntroPanel:CreateTexture(nil, "BACKGROUND")
IntroBg:SetAllPoints()
IntroBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

local IntroBorder = IntroPanel:CreateTexture(nil, "ARTWORK")
IntroBorder:SetPoint("BOTTOMLEFT", IntroPanel, "BOTTOMLEFT", 0, 0)
IntroBorder:SetPoint("BOTTOMRIGHT", IntroPanel, "BOTTOMRIGHT", 0, 0)
IntroBorder:SetHeight(1)
IntroBorder:SetColorTexture(0.88, 0.72, 0.46, 0.82)

local IntroTitle = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroTitle:SetPoint("TOPLEFT", IntroPanel, "TOPLEFT", 18, -16)
IntroTitle:SetFont("Fonts\\FRIZQT__.TTF", 23, "OUTLINE")
IntroTitle:SetTextColor(1, 0.88, 0.62, 1)

local IntroText = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroText:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -10)
IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
IntroText:SetJustifyH("LEFT")
IntroText:SetJustifyV("TOP")
IntroText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroText:SetTextColor(0.95, 0.91, 0.85, 1)

local UsageHint = IntroPanel:CreateFontString(nil, "OVERLAY")
UsageHint:SetPoint("TOPLEFT", IntroText, "BOTTOMLEFT", 0, -12)
UsageHint:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
UsageHint:SetJustifyH("LEFT")
UsageHint:SetJustifyV("TOP")
UsageHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
UsageHint:SetTextColor(0.84, 0.84, 0.86, 1)

local SettingsPanel = CreateFrame("Frame", nil, PageMarkerBarContent)
SettingsPanel:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -18)
SettingsPanel:SetPoint("RIGHT", PageMarkerBarContent, "RIGHT", -20, 0)

local SettingsBg = SettingsPanel:CreateTexture(nil, "BACKGROUND")
SettingsBg:SetAllPoints()
SettingsBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

local SettingsBorder = SettingsPanel:CreateTexture(nil, "ARTWORK")
SettingsBorder:SetPoint("BOTTOMLEFT", SettingsPanel, "BOTTOMLEFT", 0, 0)
SettingsBorder:SetPoint("BOTTOMRIGHT", SettingsPanel, "BOTTOMRIGHT", 0, 0)
SettingsBorder:SetHeight(1)
SettingsBorder:SetColorTexture(0.88, 0.72, 0.46, 0.82)

local SettingsTitle = SettingsPanel:CreateFontString(nil, "OVERLAY")
SettingsTitle:SetPoint("TOPLEFT", SettingsPanel, "TOPLEFT", 18, -14)
SettingsTitle:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
SettingsTitle:SetTextColor(1, 0.88, 0.62, 1)
SettingsTitle:SetText(L("DISPLAY"))

ShowOverlayCheckbox = CreateCheckbox(SettingsPanel, L("MARKER_BAR_SHOW_OVERLAY"), function(self)
    if MarkerBarModule.SetOverlayEnabled then
        MarkerBarModule.SetOverlayEnabled(self:GetChecked())
    end

    if PageMarkerBar and PageMarkerBar.RefreshState then
        PageMarkerBar:RefreshState()
    end
end)
ShowOverlayCheckbox:SetPoint("TOPLEFT", SettingsTitle, "BOTTOMLEFT", -4, -14)

LockOverlayCheckbox = CreateCheckbox(SettingsPanel, L("MARKER_BAR_LOCK_OVERLAY"), function(self)
    if MarkerBarModule.SetOverlayLocked then
        MarkerBarModule.SetOverlayLocked(self:GetChecked())
    end

    if PageMarkerBar and PageMarkerBar.RefreshState then
        PageMarkerBar:RefreshState()
    end
end)
LockOverlayCheckbox:SetPoint("TOPLEFT", ShowOverlayCheckbox, "BOTTOMLEFT", 0, -10)

local MinimapContextCheckbox = CreateCheckbox(SettingsPanel, L("MINIMAP_CONTEXT_MENU_ENTRY_VISIBLE"), function(self)
    if BeavisQoL.SetMinimapContextMenuEntryVisible then
        BeavisQoL.SetMinimapContextMenuEntryVisible("markerBar", self:GetChecked())
    end
end)
MinimapContextCheckbox:SetPoint("TOPLEFT", LockOverlayCheckbox, "BOTTOMLEFT", 0, -10)

local MinimapContextHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
MinimapContextHint:SetPoint("TOPLEFT", MinimapContextCheckbox, "BOTTOMLEFT", 34, -10)
MinimapContextHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
MinimapContextHint:SetJustifyH("LEFT")
MinimapContextHint:SetJustifyV("TOP")
MinimapContextHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
MinimapContextHint:SetTextColor(0.78, 0.74, 0.69, 1)

local ScaleHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
ScaleHint:SetPoint("TOPLEFT", MinimapContextHint, "BOTTOMLEFT", 0, -16)
ScaleHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
ScaleHint:SetJustifyH("LEFT")
ScaleHint:SetJustifyV("TOP")
ScaleHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
ScaleHint:SetTextColor(0.78, 0.74, 0.69, 1)

ScaleSlider, ScaleSliderText = CreateSlider(SettingsPanel)
ScaleSlider:SetPoint("TOPLEFT", ScaleHint, "BOTTOMLEFT", -16, -24)
ScaleSlider:SetScript("OnValueChanged", function(self, value)
    if isRefreshingPage then
        return
    end

    MarkerBarModule.SetOverlayScale(value)
    RefreshScaleSliderText()
end)

local ResetButton = CreateFrame("Button", nil, SettingsPanel, "UIPanelButtonTemplate")
ResetButton:SetSize(190, 26)
ResetButton:SetPoint("TOPLEFT", ScaleSlider, "BOTTOMLEFT", 16, -18)
ResetButton:SetScript("OnClick", function()
    if MarkerBarModule.ResetOverlayPosition then
        MarkerBarModule.ResetOverlayPosition()
    end

    if PageMarkerBar and PageMarkerBar.RefreshState then
        PageMarkerBar:RefreshState()
    end
end)

local DragHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
DragHint:SetPoint("TOPLEFT", ResetButton, "BOTTOMLEFT", 2, -12)
DragHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
DragHint:SetJustifyH("LEFT")
DragHint:SetJustifyV("TOP")
DragHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
DragHint:SetTextColor(0.72, 0.72, 0.75, 1)

function PageMarkerBar:RefreshState()
    isRefreshingPage = true

    IntroTitle:SetText(BeavisQoL.GetModulePageTitle("MarkerBar", L("MARKER_BAR")))
    IntroText:SetText(L("MARKER_BAR_DESC"))
    UsageHint:SetText(L("MARKER_BAR_USAGE_HINT") .. "\n\n" .. L("MARKER_BAR_PERMISSION_HINT"))
    SettingsTitle:SetText(L("DISPLAY"))
    ShowOverlayCheckbox.Label:SetText(L("MARKER_BAR_SHOW_OVERLAY"))
    LockOverlayCheckbox.Label:SetText(L("MARKER_BAR_LOCK_OVERLAY"))
    MinimapContextCheckbox.Label:SetText(L("MINIMAP_CONTEXT_MENU_ENTRY_VISIBLE"))
    MinimapContextHint:SetText(L("MINIMAP_CONTEXT_MENU_ENTRY_VISIBLE_HINT"))
    ScaleHint:SetText(L("MARKER_BAR_SCALE_HINT"))
    ResetButton:SetText(L("MARKER_BAR_RESET_POSITION"))
    DragHint:SetText(L("MARKER_BAR_DRAG_HINT"))

    ShowOverlayCheckbox:SetChecked(MarkerBarModule.IsOverlayEnabled and MarkerBarModule.IsOverlayEnabled() or false)
    LockOverlayCheckbox:SetChecked(MarkerBarModule.IsOverlayLocked and MarkerBarModule.IsOverlayLocked() or false)
    MinimapContextCheckbox:SetChecked(BeavisQoL.IsMinimapContextMenuEntryVisible and BeavisQoL.IsMinimapContextMenuEntryVisible("markerBar") or true)

    ScaleSlider:SetValue(MarkerBarModule.GetOverlayScale and MarkerBarModule.GetOverlayScale() or DEFAULT_OVERLAY_SCALE)
    RefreshScaleSliderText()

    isRefreshingPage = false
    LayoutMarkerBarPage()
end

LayoutMarkerBarPage = function()
    local contentWidth = math.max(1, PageMarkerBarScrollFrame:GetWidth())
    if contentWidth <= 1 then
        return
    end

    PageMarkerBarContent:SetWidth(contentWidth)

    IntroPanel:ClearAllPoints()
    IntroPanel:SetPoint("TOPLEFT", PageMarkerBarContent, "TOPLEFT", 20, -18)
    IntroPanel:SetPoint("RIGHT", PageMarkerBarContent, "RIGHT", -20, 0)

    IntroText:ClearAllPoints()
    IntroText:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -8)
    IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)

    UsageHint:ClearAllPoints()
    UsageHint:SetPoint("TOPLEFT", IntroText, "BOTTOMLEFT", 0, -10)
    UsageHint:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)

    local introHeight = math.ceil(
        16
        + GetTextHeight(IntroTitle, 24)
        + 8
        + GetTextHeight(IntroText, 34)
        + 10
        + GetTextHeight(UsageHint, 34)
        + 16
    )
    IntroPanel:SetHeight(math.max(116, introHeight))

    SettingsPanel:ClearAllPoints()
    SettingsPanel:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -14)
    SettingsPanel:SetPoint("RIGHT", PageMarkerBarContent, "RIGHT", -20, 0)

    SettingsTitle:ClearAllPoints()
    SettingsTitle:SetPoint("TOPLEFT", SettingsPanel, "TOPLEFT", 18, -14)

    ShowOverlayCheckbox:ClearAllPoints()
    ShowOverlayCheckbox:SetPoint("TOPLEFT", SettingsTitle, "BOTTOMLEFT", -4, -12)

    LockOverlayCheckbox:ClearAllPoints()
    LockOverlayCheckbox:SetPoint("TOPLEFT", ShowOverlayCheckbox, "BOTTOMLEFT", 0, -8)

    MinimapContextCheckbox:ClearAllPoints()
    MinimapContextCheckbox:SetPoint("TOPLEFT", LockOverlayCheckbox, "BOTTOMLEFT", 0, -8)

    MinimapContextHint:ClearAllPoints()
    MinimapContextHint:SetPoint("TOPLEFT", MinimapContextCheckbox, "BOTTOMLEFT", 34, -8)
    MinimapContextHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)

    ScaleHint:ClearAllPoints()
    ScaleHint:SetPoint("TOPLEFT", MinimapContextHint, "BOTTOMLEFT", 0, -14)
    ScaleHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)

    local innerWidth = math.max(320, contentWidth - 40)
    ScaleSlider:ClearAllPoints()
    ScaleSlider:SetPoint("TOPLEFT", ScaleHint, "BOTTOMLEFT", -16, -20)
    ScaleSlider:SetWidth(math.max(240, math.min(360, innerWidth - 92)))

    ResetButton:ClearAllPoints()
    ResetButton:SetSize(190, 28)
    ResetButton:SetPoint("TOPLEFT", ScaleSlider, "BOTTOMLEFT", 16, -16)

    DragHint:ClearAllPoints()
    DragHint:SetPoint("TOPLEFT", ResetButton, "BOTTOMLEFT", 2, -10)
    DragHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)

    local settingsHeight = math.ceil(
        14
        + GetTextHeight(SettingsTitle, 15)
        + 12
        + ShowOverlayCheckbox:GetHeight()
        + 8
        + LockOverlayCheckbox:GetHeight()
        + 8
        + MinimapContextCheckbox:GetHeight()
        + 8
        + GetTextHeight(MinimapContextHint, 34)
        + 14
        + GetTextHeight(ScaleHint, 34)
        + 20
        + 42
        + 16
        + ResetButton:GetHeight()
        + 10
        + GetTextHeight(DragHint, 34)
        + 16
    )
    SettingsPanel:SetHeight(math.max(248, settingsHeight))

    local contentHeight = 18
        + IntroPanel:GetHeight()
        + 14 + SettingsPanel:GetHeight()
        + 20

    PageMarkerBarContent:SetHeight(math.max(PageMarkerBarScrollFrame:GetHeight(), contentHeight))
end

PageMarkerBarScrollFrame:SetScript("OnSizeChanged", LayoutMarkerBarPage)
PageMarkerBarScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local step = 40
    local currentScroll = self:GetVerticalScroll()
    local maxScroll = math.max(0, PageMarkerBarContent:GetHeight() - self:GetHeight())
    local nextScroll = currentScroll - (delta * step)

    if nextScroll < 0 then
        nextScroll = 0
    elseif nextScroll > maxScroll then
        nextScroll = maxScroll
    end

    self:SetVerticalScroll(nextScroll)
end)

PageMarkerBar:SetScript("OnShow", function()
    PageMarkerBarScrollFrame:SetVerticalScroll(0)
    PageMarkerBar:RefreshState()
    LayoutMarkerBarPage()
end)

local refreshWatcher = CreateFrame("Frame")
refreshWatcher:RegisterEvent("PLAYER_LOGIN")
refreshWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
refreshWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
refreshWatcher:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" then
        if pendingOverlayStop and OverlayFrame then
            OverlayFrame:StopMovingOrSizing()
            overlayDragActive = false
            pendingOverlayStop = false
            SaveOverlayGeometry()
        end

        if not pendingOverlayRefresh and not pendingOverlayStop then
            return
        end
    end

    RefreshOverlayWindow()
end)

CreateOverlayFrame()
PageMarkerBar:RefreshState()
RefreshOverlayWindow()

BeavisQoL.Pages.MarkerBar = PageMarkerBar
