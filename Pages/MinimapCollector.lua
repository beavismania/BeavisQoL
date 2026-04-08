local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content
local L = BeavisQoL.L
local isRefreshingPage = false
local PageMinimapCollector
local CollectorDragState
local CollectorDragProxy
local ModeColumns
local StartCollectorDrag
local FinishCollectorDrag
local RefreshCollectorBoardVisuals

local function CreatePanelSurface(frame)
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()

    local border = frame:CreateTexture(nil, "ARTWORK")
    border:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    border:SetHeight(1)

    return {
        bg = bg,
        border = border,
    }
end

local function ApplyPanelSurface(surface)
    surface.bg:SetColorTexture(0.1, 0.068, 0.046, 0.94)
    surface.border:SetColorTexture(0.88, 0.72, 0.46, 0.82)
end

local function GetTextHeight(fontString, minimumHeight)
    local textHeight = fontString and fontString.GetStringHeight and fontString:GetStringHeight() or 0

    if textHeight == nil or textHeight < (minimumHeight or 0) then
        return minimumHeight or 0
    end

    return textHeight
end

local function GetSectionHeight(section)
    if not section then
        return 0
    end

    return GetTextHeight(section.Title, 15)
        + 6
        + GetTextHeight(section.Description, 11)
        + 8
        + 1
end

local function CreateCheckbox(parent, label, checked, onClick)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(24, 24)
    check:SetChecked(checked)
    check:SetScript("OnClick", onClick)

    local text = check:CreateFontString(nil, "OVERLAY")
    text:SetPoint("LEFT", check, "RIGHT", 8, 0)
    text:SetPoint("RIGHT", parent, "RIGHT", -22, 0)
    text:SetJustifyH("LEFT")
    text:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    text:SetTextColor(0.95, 0.91, 0.85, 1)
    text:SetText(label)

    check.Label = text

    return check
end

local MODE_ORDER = { "collector", "visible", "hidden" }

local function CreateCollectorListEntry(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetHeight(30)
    button:RegisterForDrag("LeftButton")

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()

    local accent = button:CreateTexture(nil, "BORDER")
    accent:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    accent:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    accent:SetWidth(4)

    local border = button:CreateTexture(nil, "ARTWORK")
    border:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    border:SetHeight(1)

    local label = button:CreateFontString(nil, "OVERLAY")
    label:SetPoint("LEFT", button, "LEFT", 14, 0)
    label:SetPoint("RIGHT", button, "RIGHT", -12, 0)
    label:SetJustifyH("LEFT")
    label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    label:SetTextColor(0.95, 0.91, 0.85, 1)
    if label.SetWordWrap then
        label:SetWordWrap(false)
    end

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 0.88, 0.62, 0.08)

    button.Background = bg
    button.Accent = accent
    button.Border = border
    button.Label = label
    button.IsHovered = false

    function button:UpdateVisual()
        local isDraggingSelf = CollectorDragState and CollectorDragState.key == self.ButtonKey

        if isDraggingSelf then
            self:SetAlpha(0.42)
            self.Background:SetColorTexture(0.2, 0.14, 0.09, 0.88)
            self.Accent:SetColorTexture(1, 0.88, 0.62, 0.72)
            self.Border:SetColorTexture(1, 0.88, 0.62, 0.44)
            self.Label:SetTextColor(1, 0.95, 0.86, 1)
        elseif self.IsHovered then
            self:SetAlpha(1)
            self.Background:SetColorTexture(0.14, 0.1, 0.065, 0.92)
            self.Accent:SetColorTexture(1, 0.88, 0.62, 0.78)
            self.Border:SetColorTexture(1, 0.88, 0.62, 0.34)
            self.Label:SetTextColor(1, 0.95, 0.86, 1)
        else
            self:SetAlpha(1)
            self.Background:SetColorTexture(0.08, 0.055, 0.038, 0.86)
            self.Accent:SetColorTexture(0.88, 0.72, 0.46, 0.42)
            self.Border:SetColorTexture(0.88, 0.72, 0.46, 0.2)
            self.Label:SetTextColor(0.95, 0.91, 0.85, 1)
        end
    end

    function button:SetEntry(buttonKey, text, modeKey)
        self.ButtonKey = buttonKey
        self.EntryText = text or buttonKey or L("UNKNOWN")
        self.ModeKey = modeKey
        self.Label:SetText(self.EntryText)
    end

    button:SetScript("OnEnter", function(self)
        self.IsHovered = true
        self:UpdateVisual()

        if not self.EntryText then
            return
        end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.EntryText, 1, 0.88, 0.62)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function(self)
        self.IsHovered = false
        self:UpdateVisual()
        GameTooltip:Hide()
    end)

    button:SetScript("OnDragStart", function(self)
        if StartCollectorDrag then
            StartCollectorDrag(self)
        end
    end)

    button:SetScript("OnDragStop", function()
        if FinishCollectorDrag then
            FinishCollectorDrag(true)
        end
    end)

    button:UpdateVisual()
    return button
end

local function CreateModeColumn(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(1, 1)
    frame:EnableMouse(true)

    local surface = CreatePanelSurface(frame)
    ApplyPanelSurface(surface)

    local headerBg = frame:CreateTexture(nil, "ARTWORK")
    headerBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    headerBg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    headerBg:SetHeight(40)
    headerBg:SetColorTexture(0.16, 0.11, 0.07, 0.96)

    local headerAccent = frame:CreateTexture(nil, "BORDER")
    headerAccent:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    headerAccent:SetPoint("BOTTOMLEFT", headerBg, "BOTTOMLEFT", 0, 0)
    headerAccent:SetWidth(2)
    headerAccent:SetColorTexture(0.88, 0.72, 0.46, 0.56)

    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -12)
    title:SetPoint("RIGHT", frame, "RIGHT", -14, 0)
    title:SetJustifyH("LEFT")
    title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    title:SetTextColor(1, 0.88, 0.62, 1)

    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    divider:SetPoint("RIGHT", frame, "RIGHT", -14, 0)
    divider:SetHeight(1)
    divider:SetColorTexture(0.88, 0.72, 0.46, 0.34)

    local bodyBg = frame:CreateTexture(nil, "BACKGROUND")
    bodyBg:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -12)
    bodyBg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 14)
    bodyBg:SetColorTexture(0.07, 0.05, 0.035, 0.48)

    local dropGlow = frame:CreateTexture(nil, "HIGHLIGHT")
    dropGlow:SetAllPoints()
    dropGlow:SetColorTexture(1, 0.88, 0.62, 0.08)
    dropGlow:Hide()

    local emptyText = frame:CreateFontString(nil, "OVERLAY")
    emptyText:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -10)
    emptyText:SetPoint("RIGHT", frame, "RIGHT", -14, 0)
    emptyText:SetJustifyH("LEFT")
    emptyText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    emptyText:SetTextColor(0.78, 0.74, 0.69, 1)

    frame.Title = title
    frame.Divider = divider
    frame.EmptyText = emptyText
    frame.Rows = {}
    frame.Surface = surface
    frame.HeaderBg = headerBg
    frame.HeaderAccent = headerAccent
    frame.BodyBg = bodyBg
    frame.DropGlow = dropGlow

    function frame:SetDropState(state)
        if state == "target" then
            self.Surface.bg:SetColorTexture(0.14, 0.1, 0.06, 0.96)
            self.Surface.border:SetColorTexture(1, 0.88, 0.62, 0.92)
            self.HeaderBg:SetColorTexture(0.22, 0.16, 0.1, 0.98)
            self.HeaderAccent:SetColorTexture(1, 0.88, 0.62, 0.92)
            self.BodyBg:SetColorTexture(0.12, 0.085, 0.055, 0.66)
            self.DropGlow:Show()
        elseif state == "source" then
            self.Surface.bg:SetColorTexture(0.11, 0.075, 0.05, 0.94)
            self.Surface.border:SetColorTexture(0.88, 0.72, 0.46, 0.48)
            self.HeaderBg:SetColorTexture(0.18, 0.13, 0.08, 0.96)
            self.HeaderAccent:SetColorTexture(0.88, 0.72, 0.46, 0.62)
            self.BodyBg:SetColorTexture(0.08, 0.055, 0.038, 0.54)
            self.DropGlow:Hide()
        else
            ApplyPanelSurface(self.Surface)
            self.HeaderBg:SetColorTexture(0.16, 0.11, 0.07, 0.96)
            self.HeaderAccent:SetColorTexture(0.88, 0.72, 0.46, 0.56)
            self.BodyBg:SetColorTexture(0.07, 0.05, 0.035, 0.48)
            self.DropGlow:Hide()
        end
    end

    frame:SetDropState("normal")

    return frame
end

local function GetSliderPercentText(value)
    return string.format("%d%%", math.floor(((value or 1) * 100) + 0.5))
end

local SCALE_SLIDER_LEFT_INSET = 4

local function CreateSlider(parent, nameSuffix)
    local sliderName = string.format("%sMinimapCollector%sSlider", ADDON_NAME, tostring(nameSuffix or "Scale"))
    local slider = CreateFrame("Slider", sliderName, parent, "OptionsSliderTemplate")
    slider:SetMinMaxValues(0.85, 1.40)
    slider:SetValueStep(0.05)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(280)

    local lowLabel = _G[slider:GetName() .. "Low"]
    local highLabel = _G[slider:GetName() .. "High"]
    local textLabel = _G[slider:GetName() .. "Text"]

    if lowLabel then
        lowLabel:SetText(GetSliderPercentText(0.85))
    end

    if highLabel then
        highLabel:SetText(GetSliderPercentText(1.40))
    end

    if textLabel then
        textLabel:SetText("")
    end

    return slider, textLabel
end

local function CreateSectionHeader(parent, titleText, descriptionText)
    local title = parent:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
    title:SetTextColor(1, 0.88, 0.62, 1)
    title:SetJustifyH("LEFT")
    title:SetText(titleText)

    local description = parent:CreateFontString(nil, "OVERLAY")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    description:SetPoint("RIGHT", parent, "RIGHT", -22, 0)
    description:SetJustifyH("LEFT")
    description:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    description:SetTextColor(0.78, 0.74, 0.69, 1)
    description:SetText(descriptionText)

    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -8)
    divider:SetPoint("RIGHT", parent, "RIGHT", -22, 0)
    divider:SetHeight(1)
    divider:SetColorTexture(0.88, 0.72, 0.46, 0.28)

    return {
        Title = title,
        Description = description,
        Divider = divider,
    }
end

PageMinimapCollector = CreateFrame("Frame", nil, Content)
PageMinimapCollector:SetAllPoints()

local PageScrollFrame = CreateFrame("ScrollFrame", nil, PageMinimapCollector, "UIPanelScrollFrameTemplate")
PageScrollFrame:SetPoint("TOPLEFT", PageMinimapCollector, "TOPLEFT", 0, 0)
PageScrollFrame:SetPoint("BOTTOMRIGHT", PageMinimapCollector, "BOTTOMRIGHT", -28, 0)
PageScrollFrame:EnableMouseWheel(true)

local PageContent = CreateFrame("Frame", nil, PageScrollFrame)
PageContent:SetSize(1, 1)
PageScrollFrame:SetScrollChild(PageContent)

local IntroPanel = CreateFrame("Frame", nil, PageContent)
IntroPanel:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 20, -20)
IntroPanel:SetPoint("TOPRIGHT", PageContent, "TOPRIGHT", -20, -20)
IntroPanel:SetHeight(1)

local IntroPanelSurface = CreatePanelSurface(IntroPanel)
ApplyPanelSurface(IntroPanelSurface)

local SettingsPanel = CreateFrame("Frame", nil, PageContent)
SettingsPanel:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -18)
SettingsPanel:SetPoint("TOPRIGHT", IntroPanel, "BOTTOMRIGHT", 0, -18)
SettingsPanel:SetHeight(1)

local SettingsPanelSurface = CreatePanelSurface(SettingsPanel)
ApplyPanelSurface(SettingsPanelSurface)

local Title = IntroPanel:CreateFontString(nil, "OVERLAY")
Title:SetPoint("TOPLEFT", IntroPanel, "TOPLEFT", 18, -16)
Title:SetFont("Fonts\\FRIZQT__.TTF", 23, "OUTLINE")
Title:SetTextColor(1, 0.88, 0.62, 1)
Title:SetText(BeavisQoL.GetModulePageTitle("MinimapCollector", L("MINIMAP_COLLECTOR")))

local Subtitle = IntroPanel:CreateFontString(nil, "OVERLAY")
Subtitle:SetPoint("TOPLEFT", Title, "BOTTOMLEFT", 0, -8)
Subtitle:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
Subtitle:SetJustifyH("LEFT")
Subtitle:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
Subtitle:SetTextColor(0.95, 0.91, 0.85, 1)
Subtitle:SetText(L("MINIMAP_COLLECTOR_DESC"))

local DisplaySection = CreateSectionHeader(SettingsPanel, L("DISPLAY"), L("MINIMAP_COLLECTOR_LAUNCHER_DESC"))
DisplaySection.Title:SetPoint("TOPLEFT", SettingsPanel, "TOPLEFT", 18, -14)

local EnableCheckbox = CreateCheckbox(SettingsPanel, L("MINIMAP_COLLECTOR_ENABLE"), false, function(self)
    if BeavisQoL.SetMinimapCollectorEnabled then
        BeavisQoL.SetMinimapCollectorEnabled(self:GetChecked())
    end
end)
EnableCheckbox:SetPoint("TOPLEFT", DisplaySection.Divider, "BOTTOMLEFT", 0, -10)

local EnableHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
EnableHint:SetPoint("TOPLEFT", EnableCheckbox, "BOTTOMLEFT", 4, -6)
EnableHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
EnableHint:SetJustifyH("LEFT")
EnableHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
EnableHint:SetTextColor(0.78, 0.74, 0.69, 1)
EnableHint:SetText(L("MINIMAP_COLLECTOR_ENABLE_HINT"))

local ResetButton = CreateFrame("Button", nil, SettingsPanel, "UIPanelButtonTemplate")
ResetButton:SetSize(190, 28)
ResetButton:SetPoint("TOPLEFT", EnableHint, "BOTTOMLEFT", -4, -12)
ResetButton:SetText(L("MINIMAP_COLLECTOR_RESET_POSITION"))
ResetButton:SetScript("OnClick", function()
    if BeavisQoL.ResetMinimapCollectorPosition then
        BeavisQoL.ResetMinimapCollectorPosition()
    end
end)

local LauncherScaleHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
LauncherScaleHint:SetPoint("TOPLEFT", ResetButton, "BOTTOMLEFT", 4, -14)
LauncherScaleHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
LauncherScaleHint:SetJustifyH("LEFT")
LauncherScaleHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
LauncherScaleHint:SetTextColor(0.78, 0.74, 0.69, 1)
LauncherScaleHint:SetText(L("MINIMAP_COLLECTOR_LAUNCHER_SCALE_HINT"))

local LauncherScaleSlider, LauncherScaleSliderText = CreateSlider(SettingsPanel, "LauncherScale")
LauncherScaleSlider:SetPoint("TOPLEFT", LauncherScaleHint, "BOTTOMLEFT", -SCALE_SLIDER_LEFT_INSET, -22)
LauncherScaleSlider:SetScript("OnValueChanged", function(self, value)
    if isRefreshingPage then
        return
    end

    if BeavisQoL.SetMinimapCollectorLauncherScale then
        BeavisQoL.SetMinimapCollectorLauncherScale(value)
    end

    if LauncherScaleSliderText then
        LauncherScaleSliderText:SetText(string.format("%s: %s", L("MINIMAP_COLLECTOR_LAUNCHER_SCALE"), GetSliderPercentText(value)))
    end
end)

local WindowScaleHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
WindowScaleHint:SetPoint("TOPLEFT", LauncherScaleSlider, "BOTTOMLEFT", SCALE_SLIDER_LEFT_INSET, -12)
WindowScaleHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
WindowScaleHint:SetJustifyH("LEFT")
WindowScaleHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
WindowScaleHint:SetTextColor(0.78, 0.74, 0.69, 1)
WindowScaleHint:SetText(L("MINIMAP_COLLECTOR_WINDOW_SCALE_HINT"))

local WindowScaleSlider, WindowScaleSliderText = CreateSlider(SettingsPanel, "WindowScale")
WindowScaleSlider:SetPoint("TOPLEFT", WindowScaleHint, "BOTTOMLEFT", -SCALE_SLIDER_LEFT_INSET, -22)
WindowScaleSlider:SetScript("OnValueChanged", function(self, value)
    if isRefreshingPage then
        return
    end

    if BeavisQoL.SetMinimapCollectorWindowScale then
        BeavisQoL.SetMinimapCollectorWindowScale(value)
    end

    if WindowScaleSliderText then
        WindowScaleSliderText:SetText(string.format("%s: %s", L("MINIMAP_COLLECTOR_WINDOW_SCALE"), GetSliderPercentText(value)))
    end
end)

local ButtonsSection = CreateSectionHeader(SettingsPanel, L("MODULES"), L("MINIMAP_COLLECTOR_BUTTONS_DESC"))
ButtonsSection.Title:SetPoint("TOPLEFT", WindowScaleSlider, "BOTTOMLEFT", SCALE_SLIDER_LEFT_INSET, -20)

local ButtonsHint = SettingsPanel:CreateFontString(nil, "OVERLAY")
ButtonsHint:SetPoint("TOPLEFT", ButtonsSection.Divider, "BOTTOMLEFT", 0, -10)
ButtonsHint:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
ButtonsHint:SetJustifyH("LEFT")
ButtonsHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
ButtonsHint:SetTextColor(0.78, 0.74, 0.69, 1)
ButtonsHint:SetText(L("MINIMAP_COLLECTOR_BUTTONS_HINT"))

local ButtonsContainer = CreateFrame("Frame", nil, SettingsPanel)
ButtonsContainer:SetPoint("TOPLEFT", ButtonsHint, "BOTTOMLEFT", 0, -12)
ButtonsContainer:SetPoint("RIGHT", SettingsPanel, "RIGHT", -18, 0)
ButtonsContainer:SetHeight(1)

local ButtonsBoardSurface = CreatePanelSurface(ButtonsContainer)
ButtonsBoardSurface.bg:SetColorTexture(0.06, 0.042, 0.03, 0.36)
ButtonsBoardSurface.border:SetColorTexture(0.88, 0.72, 0.46, 0.24)

local ButtonsBoardTop = ButtonsContainer:CreateTexture(nil, "ARTWORK")
ButtonsBoardTop:SetPoint("TOPLEFT", ButtonsContainer, "TOPLEFT", 0, 0)
ButtonsBoardTop:SetPoint("TOPRIGHT", ButtonsContainer, "TOPRIGHT", 0, 0)
ButtonsBoardTop:SetHeight(1)
ButtonsBoardTop:SetColorTexture(0.88, 0.72, 0.46, 0.2)

local EmptyStateText = ButtonsContainer:CreateFontString(nil, "OVERLAY")
EmptyStateText:SetPoint("TOPLEFT", ButtonsContainer, "TOPLEFT", 16, -16)
EmptyStateText:SetPoint("RIGHT", ButtonsContainer, "RIGHT", -16, 0)
EmptyStateText:SetJustifyV("TOP")
EmptyStateText:SetJustifyH("LEFT")
EmptyStateText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
EmptyStateText:SetTextColor(0.78, 0.74, 0.69, 1)
EmptyStateText:SetText(L("MINIMAP_COLLECTOR_EMPTY"))

local ColumnsFrame = CreateFrame("Frame", nil, ButtonsContainer)
ColumnsFrame:SetPoint("TOPLEFT", ButtonsContainer, "TOPLEFT", 16, -14)
ColumnsFrame:SetPoint("RIGHT", ButtonsContainer, "RIGHT", -16, 0)
ColumnsFrame:SetHeight(1)

local CollectorColumn = CreateModeColumn(ColumnsFrame)
local VisibleColumn = CreateModeColumn(ColumnsFrame)
local HiddenColumn = CreateModeColumn(ColumnsFrame)

ModeColumns = {
    collector = CollectorColumn,
    visible = VisibleColumn,
    hidden = HiddenColumn,
}

CollectorColumn.ModeKey = "collector"
VisibleColumn.ModeKey = "visible"
HiddenColumn.ModeKey = "hidden"

local function EnsureCollectorDragProxy()
    if CollectorDragProxy then
        return CollectorDragProxy
    end

    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetSize(180, 30)
    frame:EnableMouse(false)
    frame:Hide()

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.16, 0.11, 0.07, 0.96)

    local accent = frame:CreateTexture(nil, "BORDER")
    accent:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    accent:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    accent:SetWidth(3)
    accent:SetColorTexture(1, 0.88, 0.62, 0.88)

    local border = frame:CreateTexture(nil, "ARTWORK")
    border:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    border:SetHeight(1)
    border:SetColorTexture(1, 0.88, 0.62, 0.56)

    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetPoint("LEFT", frame, "LEFT", 12, 0)
    label:SetPoint("RIGHT", frame, "RIGHT", -12, 0)
    label:SetJustifyH("LEFT")
    label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    label:SetTextColor(1, 0.95, 0.86, 1)

    frame.Label = label
    frame:SetScript("OnUpdate", function(self)
        if not CollectorDragState then
            return
        end

        local cursorX, cursorY = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        local targetMode

        self:ClearAllPoints()
        self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", math.floor((cursorX / scale) + 14), math.floor((cursorY / scale) - 8))

        if MouseIsOver and ModeColumns then
            for _, mode in ipairs(MODE_ORDER) do
                local column = ModeColumns[mode]
                if column and column:IsShown() and MouseIsOver(column) then
                    targetMode = mode
                    break
                end
            end
        end

        CollectorDragState.targetMode = targetMode
        if RefreshCollectorBoardVisuals then
            RefreshCollectorBoardVisuals()
        end
    end)

    CollectorDragProxy = frame
    return CollectorDragProxy
end

RefreshCollectorBoardVisuals = function()
    if not ModeColumns then
        return
    end

    for _, mode in ipairs(MODE_ORDER) do
        local column = ModeColumns[mode]

        if column and column.SetDropState then
            local state = "normal"

            if CollectorDragState then
                if CollectorDragState.targetMode == mode then
                    state = "target"
                elseif CollectorDragState.sourceMode == mode then
                    state = "source"
                end
            end

            column:SetDropState(state)

            for _, row in ipairs(column.Rows or {}) do
                if row and row.UpdateVisual then
                    row:UpdateVisual()
                end
            end
        end
    end
end

StartCollectorDrag = function(button)
    if not button or not button.ButtonKey or not button.EntryText then
        return
    end

    if GameTooltip then
        GameTooltip:Hide()
    end

    CollectorDragState = {
        key = button.ButtonKey,
        label = button.EntryText,
        sourceMode = button.ModeKey or (BeavisQoL.GetMinimapCollectorButtonMode and BeavisQoL.GetMinimapCollectorButtonMode(button.ButtonKey)) or "collector",
        targetMode = nil,
    }

    local proxy = EnsureCollectorDragProxy()
    proxy.Label:SetText(button.EntryText)
    proxy:SetWidth(math.min(320, math.max(160, math.ceil(proxy.Label:GetStringWidth()) + 32)))
    proxy:Show()

    if RefreshCollectorBoardVisuals then
        RefreshCollectorBoardVisuals()
    end
end

FinishCollectorDrag = function(applyDrop)
    local dragState = CollectorDragState
    if not dragState then
        return
    end

    CollectorDragState = nil

    if CollectorDragProxy then
        CollectorDragProxy:Hide()
    end

    if applyDrop
        and dragState.key
        and dragState.targetMode
        and dragState.targetMode ~= dragState.sourceMode
        and BeavisQoL.SetMinimapCollectorButtonMode
    then
        BeavisQoL.SetMinimapCollectorButtonMode(dragState.key, dragState.targetMode)
    end

    if RefreshCollectorBoardVisuals then
        RefreshCollectorBoardVisuals()
    end

    if PageMinimapCollector and PageMinimapCollector.RefreshState then
        PageMinimapCollector:RefreshState()
    end
end

local function GetCollectorButtons()
    if BeavisQoL.GetMinimapCollectorButtons then
        return BeavisQoL.GetMinimapCollectorButtons()
    end

    return {}
end

local function EnsureColumnRow(column, index)
    local row = column.Rows[index]
    if row then
        return row
    end

    row = CreateCollectorListEntry(column)
    column.Rows[index] = row
    return row
end

local function LayoutModeColumn(column, width, titleText, entries)
    local rowHeight = 30
    local rowSpacing = 6
    local topPadding = 12
    local bottomPadding = 14
    local contentOffset = 16

    column:SetWidth(width)
    column.Title:SetText(titleText)
    column.EmptyText:SetText(L("MINIMAP_COLLECTOR_COLUMN_EMPTY"))

    local contentHeight = 0

    if #entries == 0 then
        column.EmptyText:Show()
        contentHeight = GetTextHeight(column.EmptyText, 12)
    else
        column.EmptyText:Hide()

        for index, entry in ipairs(entries) do
            local row = EnsureColumnRow(column, index)
            row:SetEntry(entry.key, entry.label, column.ModeKey)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", column.Divider, "BOTTOMLEFT", 0, -(contentOffset + ((index - 1) * (rowHeight + rowSpacing))))
            row:SetPoint("RIGHT", column, "RIGHT", -14, 0)
            row:SetHeight(rowHeight)
            row:UpdateVisual()
            row:Show()
        end

        for index = #entries + 1, #column.Rows do
            column.Rows[index]:Hide()
        end

        contentHeight = (#entries * rowHeight) + math.max(0, (#entries - 1) * rowSpacing)
    end

    if #entries == 0 then
        for index = 1, #column.Rows do
            column.Rows[index]:Hide()
        end
    end

    local columnHeight = topPadding
        + GetTextHeight(column.Title, 14)
        + 8
        + 1
        + contentOffset
        + contentHeight
        + bottomPadding

    column:SetHeight(math.max(96, columnHeight))
    return column:GetHeight()
end

local function LayoutPage()
    local contentWidth = math.max(1, PageScrollFrame:GetWidth())

    if contentWidth <= 1 then
        return
    end

    PageContent:SetWidth(contentWidth)

    local buttonRowsHeight = ButtonsContainer:GetHeight()

    local introHeight = 16
        + GetTextHeight(Title, 24)
        + 8
        + GetTextHeight(Subtitle, 34)
        + 18

    local settingsHeight = 18
        + GetSectionHeight(DisplaySection)
        + 10
        + EnableCheckbox:GetHeight()
        + 6
        + GetTextHeight(EnableHint, 11)
        + 12
        + ResetButton:GetHeight()
        + 14
        + GetTextHeight(LauncherScaleHint, 11)
        + 22
        + LauncherScaleSlider:GetHeight()
        + 12
        + GetTextHeight(WindowScaleHint, 11)
        + 22
        + WindowScaleSlider:GetHeight()
        + 20
        + GetSectionHeight(ButtonsSection)
        + 10
        + GetTextHeight(ButtonsHint, 11)
        + 12
        + buttonRowsHeight
        + 22

    IntroPanel:SetHeight(math.max(90, math.ceil(introHeight)))
    SettingsPanel:SetHeight(math.max(1, math.ceil(settingsHeight)))
    PageContent:SetHeight(math.max(PageScrollFrame:GetHeight(), IntroPanel:GetHeight() + 18 + SettingsPanel:GetHeight() + 40))
end

function PageMinimapCollector:RefreshState()
    local collectorEnabled = BeavisQoL.IsMinimapCollectorEnabled and BeavisQoL.IsMinimapCollectorEnabled() or false
    local launcherScale = BeavisQoL.GetMinimapCollectorLauncherScale and BeavisQoL.GetMinimapCollectorLauncherScale() or 1
    local windowScale = BeavisQoL.GetMinimapCollectorWindowScale and BeavisQoL.GetMinimapCollectorWindowScale() or 1
    local buttons = GetCollectorButtons()
    local availableWidth = math.max(ButtonsContainer:GetWidth() - 32, SettingsPanel:GetWidth() - 68, 540)
    local columnSpacing = 16
    local columnWidth = math.max(180, math.floor((availableWidth - (columnSpacing * 2)) / 3))
    local groupedButtons = {
        collector = {},
        visible = {},
        hidden = {},
    }
    local totalButtons = #buttons

    isRefreshingPage = true
    EnableCheckbox:SetChecked(collectorEnabled)
    EnableCheckbox.Label:SetText(L("MINIMAP_COLLECTOR_ENABLE"))
    EnableHint:SetText(L("MINIMAP_COLLECTOR_ENABLE_HINT"))
    ResetButton:SetText(L("MINIMAP_COLLECTOR_RESET_POSITION"))
    LauncherScaleHint:SetText(L("MINIMAP_COLLECTOR_LAUNCHER_SCALE_HINT"))
    WindowScaleHint:SetText(L("MINIMAP_COLLECTOR_WINDOW_SCALE_HINT"))
    EmptyStateText:SetText(L("MINIMAP_COLLECTOR_EMPTY"))
    ButtonsHint:SetText(L("MINIMAP_COLLECTOR_BUTTONS_HINT"))
    LauncherScaleSlider:SetValue(launcherScale)
    WindowScaleSlider:SetValue(windowScale)
    if LauncherScaleSliderText then
        LauncherScaleSliderText:SetText(string.format("%s: %s", L("MINIMAP_COLLECTOR_LAUNCHER_SCALE"), GetSliderPercentText(launcherScale)))
    end
    if WindowScaleSliderText then
        WindowScaleSliderText:SetText(string.format("%s: %s", L("MINIMAP_COLLECTOR_WINDOW_SCALE"), GetSliderPercentText(windowScale)))
    end

    for _, buttonInfo in ipairs(buttons) do
        local mode = buttonInfo.mode or (buttonInfo.enabled ~= false and "collector" or "visible")
        local bucket = groupedButtons[mode] or groupedButtons.collector
        local entry = {
            key = buttonInfo.key,
            label = buttonInfo.label or buttonInfo.key or L("UNKNOWN"),
            mode = mode,
        }

        bucket[#bucket + 1] = entry
    end

    if totalButtons == 0 then
        ColumnsFrame:Hide()
        EmptyStateText:Show()
        ButtonsContainer:SetHeight(GetTextHeight(EmptyStateText, 14) + 32)
    else
        local columnsHeight = 0

        ColumnsFrame:Show()
        EmptyStateText:Hide()

        CollectorColumn:ClearAllPoints()
        CollectorColumn:SetPoint("TOPLEFT", ColumnsFrame, "TOPLEFT", 0, 0)

        VisibleColumn:ClearAllPoints()
        VisibleColumn:SetPoint("TOPLEFT", CollectorColumn, "TOPRIGHT", columnSpacing, 0)

        HiddenColumn:ClearAllPoints()
        HiddenColumn:SetPoint("TOPLEFT", VisibleColumn, "TOPRIGHT", columnSpacing, 0)

        columnsHeight = math.max(
            LayoutModeColumn(CollectorColumn, columnWidth, L("MINIMAP_COLLECTOR_COLUMN_COLLECT"), groupedButtons.collector),
            LayoutModeColumn(VisibleColumn, columnWidth, L("MINIMAP_COLLECTOR_COLUMN_VISIBLE"), groupedButtons.visible),
            LayoutModeColumn(HiddenColumn, columnWidth, L("MINIMAP_COLLECTOR_COLUMN_HIDE"), groupedButtons.hidden)
        )

        for _, mode in ipairs(MODE_ORDER) do
            ModeColumns[mode]:SetHeight(columnsHeight)
        end

        ColumnsFrame:SetHeight(columnsHeight)
        ButtonsContainer:SetHeight(columnsHeight + 28)
    end

    isRefreshingPage = false
    if RefreshCollectorBoardVisuals then
        RefreshCollectorBoardVisuals()
    end
    LayoutPage()
end

BeavisQoL.UpdateMinimapCollectorPage = function()
    Title:SetText(BeavisQoL.GetModulePageTitle("MinimapCollector", L("MINIMAP_COLLECTOR")))
    Subtitle:SetText(L("MINIMAP_COLLECTOR_DESC"))
    DisplaySection.Title:SetText(L("DISPLAY"))
    DisplaySection.Description:SetText(L("MINIMAP_COLLECTOR_LAUNCHER_DESC"))
    LauncherScaleHint:SetText(L("MINIMAP_COLLECTOR_LAUNCHER_SCALE_HINT"))
    WindowScaleHint:SetText(L("MINIMAP_COLLECTOR_WINDOW_SCALE_HINT"))
    ButtonsSection.Title:SetText(L("MODULES"))
    ButtonsSection.Description:SetText(L("MINIMAP_COLLECTOR_BUTTONS_DESC"))
    PageMinimapCollector:RefreshState()
end

PageScrollFrame:SetScript("OnSizeChanged", LayoutPage)
PageScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local step = 40
    local currentScroll = self:GetVerticalScroll()
    local maxScroll = math.max(0, PageContent:GetHeight() - self:GetHeight())
    local nextScroll = currentScroll - (delta * step)

    if nextScroll < 0 then
        nextScroll = 0
    elseif nextScroll > maxScroll then
        nextScroll = maxScroll
    end

    self:SetVerticalScroll(nextScroll)
end)

PageMinimapCollector:SetScript("OnShow", function(self)
    self:RefreshState()
    PageScrollFrame:SetVerticalScroll(0)
end)

PageMinimapCollector:SetScript("OnHide", function()
    if FinishCollectorDrag then
        FinishCollectorDrag(false)
    end
end)

BeavisQoL.Pages.MinimapCollector = PageMinimapCollector

