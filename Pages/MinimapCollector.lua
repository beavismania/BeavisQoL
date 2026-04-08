local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content
local L = BeavisQoL.L
local isRefreshingPage = false
local PageMinimapCollector
local GetModeLabel

if not rawget(_G, "UIDropDownMenuTemplate") then
    if C_AddOns and C_AddOns.LoadAddOn then
        C_AddOns.LoadAddOn("Blizzard_UIDropDownMenu")
    elseif UIParentLoadAddOn then
        UIParentLoadAddOn("Blizzard_UIDropDownMenu")
    end
end

local function CreatePanelSurface(frame)
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()

    local glow = frame:CreateTexture(nil, "BORDER")
    glow:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    glow:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    glow:SetHeight(34)

    local accent = frame:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -12)
    accent:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 12)
    accent:SetWidth(3)

    local border = frame:CreateTexture(nil, "ARTWORK")
    border:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    border:SetHeight(1)

    return {
        bg = bg,
        glow = glow,
        accent = accent,
        border = border,
    }
end

local function ApplyPanelSurface(surface)
    surface.bg:SetColorTexture(0.085, 0.085, 0.09, 0.94)
    surface.glow:SetColorTexture(1, 0.82, 0, 0.05)
    surface.accent:SetColorTexture(1, 0.82, 0, 0.7)
    surface.border:SetColorTexture(1, 0.82, 0, 0.78)
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
    text:SetTextColor(0.96, 0.96, 0.96, 1)
    text:SetText(label)

    check.Label = text

    return check
end

local function CreateCompactModeControl(parent, dropdownName)
    local control = CreateFrame("Frame", nil, parent)
    control:SetSize(1, 1)

    local text = control:CreateFontString(nil, "OVERLAY")
    text:SetPoint("TOPLEFT", control, "TOPLEFT", 0, 0)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    text:SetTextColor(0.96, 0.96, 0.96, 1)
    if text.SetWordWrap then
        text:SetWordWrap(true)
    end
    text:SetText("")

    local modeDropdown = CreateFrame("Frame", dropdownName, control, "UIDropDownMenuTemplate")
    modeDropdown:SetPoint("TOPLEFT", text, "BOTTOMLEFT", -18, -2)
    UIDropDownMenu_SetWidth(modeDropdown, 104)
    UIDropDownMenu_JustifyText(modeDropdown, "LEFT")

    UIDropDownMenu_Initialize(modeDropdown, function(_, level)
        local options = {
            { value = "collector", text = L("MINIMAP_COLLECTOR_MODE_COLLECT") },
            { value = "visible", text = L("MINIMAP_COLLECTOR_MODE_SHOW") },
            { value = "hidden", text = L("MINIMAP_COLLECTOR_MODE_HIDE") },
        }

        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.value = option.value
            info.func = function()
                if BeavisQoL.SetMinimapCollectorButtonMode and control.ButtonKey then
                    BeavisQoL.SetMinimapCollectorButtonMode(control.ButtonKey, option.value)
                end

                control:SetMode(option.value)
            end
            info.checked = control.Mode == option.value
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    function control:SetLabelWidth(width)
        width = math.max(1, width or 1)
        text:SetWidth(width)
        UIDropDownMenu_SetWidth(modeDropdown, math.max(88, math.min(122, width - 26)))
    end

    function control:GetContentHeight()
        return math.max(18, math.ceil(text:GetStringHeight())) + 6 + math.max(28, modeDropdown:GetHeight())
    end

    control.Label = text
    control.Dropdown = modeDropdown

    function control:SetMode(mode)
        self.Mode = mode
        UIDropDownMenu_SetSelectedValue(modeDropdown, mode)
        UIDropDownMenu_SetText(modeDropdown, GetModeLabel(mode))
    end

    return control
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
    description:SetTextColor(0.76, 0.76, 0.79, 1)
    description:SetText(descriptionText)

    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -8)
    divider:SetPoint("RIGHT", parent, "RIGHT", -22, 0)
    divider:SetHeight(1)
    divider:SetColorTexture(1, 0.82, 0, 0.18)

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

local Panel = CreateFrame("Frame", nil, PageContent)
Panel:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 22, -22)
Panel:SetPoint("TOPRIGHT", PageContent, "TOPRIGHT", -22, -22)
Panel:SetHeight(1)

local PanelSurface = CreatePanelSurface(Panel)
ApplyPanelSurface(PanelSurface)

local Title = Panel:CreateFontString(nil, "OVERLAY")
Title:SetPoint("TOPLEFT", Panel, "TOPLEFT", 22, -18)
Title:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
Title:SetTextColor(1, 0.88, 0.62, 1)
Title:SetText(BeavisQoL.GetModulePageTitle("MinimapCollector", L("MINIMAP_COLLECTOR")))

local Subtitle = Panel:CreateFontString(nil, "OVERLAY")
Subtitle:SetPoint("TOPLEFT", Title, "BOTTOMLEFT", 0, -8)
Subtitle:SetPoint("RIGHT", Panel, "RIGHT", -22, 0)
Subtitle:SetJustifyH("LEFT")
Subtitle:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
Subtitle:SetTextColor(0.84, 0.84, 0.86, 1)
Subtitle:SetText(L("MINIMAP_COLLECTOR_DESC"))

local DisplaySection = CreateSectionHeader(Panel, L("DISPLAY"), L("MINIMAP_COLLECTOR_LAUNCHER_DESC"))
DisplaySection.Title:SetPoint("TOPLEFT", Subtitle, "BOTTOMLEFT", 0, -18)

local EnableCheckbox = CreateCheckbox(Panel, L("MINIMAP_COLLECTOR_ENABLE"), false, function(self)
    if BeavisQoL.SetMinimapCollectorEnabled then
        BeavisQoL.SetMinimapCollectorEnabled(self:GetChecked())
    end
end)
EnableCheckbox:SetPoint("TOPLEFT", DisplaySection.Divider, "BOTTOMLEFT", 0, -10)

local EnableHint = Panel:CreateFontString(nil, "OVERLAY")
EnableHint:SetPoint("TOPLEFT", EnableCheckbox, "BOTTOMLEFT", 4, -6)
EnableHint:SetPoint("RIGHT", Panel, "RIGHT", -22, 0)
EnableHint:SetJustifyH("LEFT")
EnableHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
EnableHint:SetTextColor(0.82, 0.82, 0.82, 1)
EnableHint:SetText(L("MINIMAP_COLLECTOR_ENABLE_HINT"))

local ResetButton = CreateFrame("Button", nil, Panel, "UIPanelButtonTemplate")
ResetButton:SetSize(190, 28)
ResetButton:SetPoint("TOPLEFT", EnableHint, "BOTTOMLEFT", -4, -12)
ResetButton:SetText(L("MINIMAP_COLLECTOR_RESET_POSITION"))
ResetButton:SetScript("OnClick", function()
    if BeavisQoL.ResetMinimapCollectorPosition then
        BeavisQoL.ResetMinimapCollectorPosition()
    end
end)

local LauncherScaleHint = Panel:CreateFontString(nil, "OVERLAY")
LauncherScaleHint:SetPoint("TOPLEFT", ResetButton, "BOTTOMLEFT", 4, -14)
LauncherScaleHint:SetPoint("RIGHT", Panel, "RIGHT", -22, 0)
LauncherScaleHint:SetJustifyH("LEFT")
LauncherScaleHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
LauncherScaleHint:SetTextColor(0.82, 0.82, 0.82, 1)
LauncherScaleHint:SetText(L("MINIMAP_COLLECTOR_LAUNCHER_SCALE_HINT"))

local LauncherScaleSlider, LauncherScaleSliderText = CreateSlider(Panel, "LauncherScale")
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

local WindowScaleHint = Panel:CreateFontString(nil, "OVERLAY")
WindowScaleHint:SetPoint("TOPLEFT", LauncherScaleSlider, "BOTTOMLEFT", SCALE_SLIDER_LEFT_INSET, -12)
WindowScaleHint:SetPoint("RIGHT", Panel, "RIGHT", -22, 0)
WindowScaleHint:SetJustifyH("LEFT")
WindowScaleHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
WindowScaleHint:SetTextColor(0.82, 0.82, 0.82, 1)
WindowScaleHint:SetText(L("MINIMAP_COLLECTOR_WINDOW_SCALE_HINT"))

local WindowScaleSlider, WindowScaleSliderText = CreateSlider(Panel, "WindowScale")
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

local ButtonsSection = CreateSectionHeader(Panel, L("MODULES"), L("MINIMAP_COLLECTOR_BUTTONS_DESC"))
ButtonsSection.Title:SetPoint("TOPLEFT", WindowScaleSlider, "BOTTOMLEFT", SCALE_SLIDER_LEFT_INSET, -20)

local ButtonsHint = Panel:CreateFontString(nil, "OVERLAY")
ButtonsHint:SetPoint("TOPLEFT", ButtonsSection.Divider, "BOTTOMLEFT", 0, -10)
ButtonsHint:SetPoint("RIGHT", Panel, "RIGHT", -22, 0)
ButtonsHint:SetJustifyH("LEFT")
ButtonsHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
ButtonsHint:SetTextColor(0.82, 0.82, 0.82, 1)
ButtonsHint:SetText(L("MINIMAP_COLLECTOR_BUTTONS_HINT"))

local ButtonsContainer = CreateFrame("Frame", nil, Panel)
ButtonsContainer:SetPoint("TOPLEFT", ButtonsHint, "BOTTOMLEFT", 0, -12)
ButtonsContainer:SetPoint("RIGHT", Panel, "RIGHT", -22, 0)
ButtonsContainer:SetHeight(1)

local EmptyStateText = ButtonsContainer:CreateFontString(nil, "OVERLAY")
EmptyStateText:SetPoint("TOPLEFT", ButtonsContainer, "TOPLEFT", 0, 0)
EmptyStateText:SetPoint("RIGHT", ButtonsContainer, "RIGHT", 0, 0)
EmptyStateText:SetJustifyH("LEFT")
EmptyStateText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
EmptyStateText:SetTextColor(0.82, 0.82, 0.82, 1)
EmptyStateText:SetText(L("MINIMAP_COLLECTOR_EMPTY"))

local ButtonControls = {}

GetModeLabel = function(mode)
    if mode == "hidden" then
        return L("MINIMAP_COLLECTOR_MODE_HIDE")
    end

    if mode == "visible" then
        return L("MINIMAP_COLLECTOR_MODE_SHOW")
    end

    return L("MINIMAP_COLLECTOR_MODE_COLLECT")
end

local function GetCollectorButtons()
    if BeavisQoL.GetMinimapCollectorButtons then
        return BeavisQoL.GetMinimapCollectorButtons()
    end

    return {}
end

local function EnsureButtonControl(index)
    local control = ButtonControls[index]
    if control then
        return control
    end

    control = CreateCompactModeControl(
        ButtonsContainer,
        string.format("%sMinimapCollectorModeDropdown%d", ADDON_NAME, index)
    )

    ButtonControls[index] = control
    return control
end

local function LayoutPage()
    local contentWidth = math.max(1, PageScrollFrame:GetWidth())

    if contentWidth <= 1 then
        return
    end

    PageContent:SetWidth(contentWidth)

    local buttonRowsHeight = ButtonsContainer:GetHeight()

    local requiredHeight = 18
        + GetTextHeight(Title, 24)
        + 8
        + GetTextHeight(Subtitle, 12)
        + 18
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

    Panel:SetHeight(math.max(1, math.ceil(requiredHeight)))
    PageContent:SetHeight(math.max(PageScrollFrame:GetHeight(), Panel:GetHeight() + 44))
end

function PageMinimapCollector:RefreshState()
    local collectorEnabled = BeavisQoL.IsMinimapCollectorEnabled and BeavisQoL.IsMinimapCollectorEnabled() or false
    local launcherScale = BeavisQoL.GetMinimapCollectorLauncherScale and BeavisQoL.GetMinimapCollectorLauncherScale() or 1
    local windowScale = BeavisQoL.GetMinimapCollectorWindowScale and BeavisQoL.GetMinimapCollectorWindowScale() or 1
    local buttons = GetCollectorButtons()
    local availableWidth = math.max(ButtonsContainer:GetWidth(), Panel:GetWidth() - 44, 320)
    local columnSpacing = 10
    local rowSpacing = 8
    local columns = 2
    local rowHeights = {}
    local layoutEntries = {}

    if availableWidth >= 780 then
        columns = 4
    elseif availableWidth >= 500 then
        columns = 3
    end

    local columnWidth = math.floor((availableWidth - ((columns - 1) * columnSpacing)) / columns)

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

    for index, buttonInfo in ipairs(buttons) do
        local control = EnsureButtonControl(index)
        local rowIndex = math.floor((index - 1) / columns) + 1
        local columnIndex = (index - 1) % columns
        local mode = buttonInfo.mode or (buttonInfo.enabled ~= false and "collector" or "visible")

        control.ButtonKey = buttonInfo.key
        control.Mode = mode
        control.Label:SetText(buttonInfo.label or buttonInfo.key or L("UNKNOWN"))
        control:SetLabelWidth(columnWidth)
        control:ClearAllPoints()
        control.Label:SetWidth(columnWidth)
        control:SetMode(mode)

        local entryHeight = math.max(52, control:GetContentHeight())
        rowHeights[rowIndex] = math.max(rowHeights[rowIndex] or 0, entryHeight)
        layoutEntries[#layoutEntries + 1] = {
            control = control,
            row = rowIndex,
            column = columnIndex,
            height = entryHeight,
        }

        control:Show()
    end

    for index = #buttons + 1, #ButtonControls do
        ButtonControls[index]:Hide()
    end

    if #buttons == 0 then
        EmptyStateText:Show()
        ButtonsContainer:SetHeight(GetTextHeight(EmptyStateText, 14))
    else
        local rowOffsets = {}
        local currentOffsetY = 0
        local rowCount = math.ceil(#buttons / columns)

        EmptyStateText:Hide()

        for rowIndex = 1, rowCount do
            rowOffsets[rowIndex] = currentOffsetY
            currentOffsetY = currentOffsetY + (rowHeights[rowIndex] or 20) + rowSpacing
        end

        for _, layoutEntry in ipairs(layoutEntries) do
            layoutEntry.control:SetPoint(
                "TOPLEFT",
                ButtonsContainer,
                "TOPLEFT",
                layoutEntry.column * (columnWidth + columnSpacing),
                -(rowOffsets[layoutEntry.row] or 0)
            )
            layoutEntry.control:SetSize(columnWidth, rowHeights[layoutEntry.row] or layoutEntry.height or 40)
        end

        EmptyStateText:Hide()
        ButtonsContainer:SetHeight(math.max(20, currentOffsetY - rowSpacing))
    end

    isRefreshingPage = false
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

BeavisQoL.Pages.MinimapCollector = PageMinimapCollector

