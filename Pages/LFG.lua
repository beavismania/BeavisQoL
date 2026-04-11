local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content
local L = BeavisQoL.L
BeavisQoL.LFG = BeavisQoL.LFG or {}
local LFG = BeavisQoL.LFG

-- Diese Datei baut nur die sichtbare LFG-Seite.
-- Die eigentliche Hook- und Flaggenlogik lebt getrennt in `Pages/LFG/Flags.lua`.

-- Auch diese Datei ist bewusst eine duenne UI-Schicht.
-- Alles, was mit Group-Finder-Hooks, Realm-Erkennung und Flaggen-Rendering
-- zu tun hat, lebt in Pages/LFG/Flags.lua.

-- Die LFG-Seite sammelt nur Komfortfunktionen für den Blizzard-Group-Finder.
local sliderCounter = 0
local isRefreshing = false
local PageScrollFrame
local PageContentFrame
local FrameWithBackdrop = BackdropTemplateMixin and "BackdropTemplate" or nil
local LISTING_TEXT_PRESET_COUNT = 5

local function GetTextHeight(fontString, minimumHeight)
    local textHeight = fontString and fontString.GetStringHeight and fontString:GetStringHeight() or 0

    if textHeight == nil or textHeight < (minimumHeight or 0) then
        return minimumHeight or 0
    end

    return textHeight
end

local function GetMeasuredPanelHeight(panel, bottomObject, minimumHeight, bottomPadding)
    if not panel or not bottomObject then
        return minimumHeight or 1
    end

    local panelTop = panel:GetTop()
    local bottom = bottomObject:GetBottom()

    if not panelTop or not bottom then
        return minimumHeight or 1
    end

    return math.max(minimumHeight or 1, math.ceil((panelTop - bottom) + (bottomPadding or 0)))
end

local function GetLowerBottomObject(primaryObject, secondaryObject)
    local primaryBottom = primaryObject and primaryObject.GetBottom and primaryObject:GetBottom()
    local secondaryBottom = secondaryObject and secondaryObject.GetBottom and secondaryObject:GetBottom()

    if primaryBottom and secondaryBottom then
        if primaryBottom <= secondaryBottom then
            return primaryObject
        end

        return secondaryObject
    end

    return primaryBottom and primaryObject or secondaryObject
end

local function FormatSliderValue(value, mode)
    if mode == "scale" or mode == "alpha" then
        return string.format("%d%%", math.floor(((value or 0) * 100) + 0.5))
    end

    return tostring(math.floor((value or 0) + 0.5))
end

local function RefreshSliderCaption(slider)
    if not slider or not slider.Text then
        return
    end

    local labelText = slider.LabelText or ""
    local mode = slider.ValueMode
    slider.Text:SetText(string.format("%s: %s", labelText, FormatSliderValue(slider:GetValue(), mode)))
end

local function CreateValueSlider(parent, labelText, minValue, maxValue, step, mode)
    sliderCounter = sliderCounter + 1

    local sliderName = "BeavisQoLLFGSlider" .. sliderCounter
    local slider = CreateFrame("Slider", sliderName, parent, "OptionsSliderTemplate")
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetWidth(290)
    if slider.SetObeyStepOnDrag then
        slider:SetObeyStepOnDrag(true)
    end

    slider.Text = _G[sliderName .. "Text"]
    slider.Low = _G[sliderName .. "Low"]
    slider.High = _G[sliderName .. "High"]
    slider.LabelText = labelText
    slider.ValueMode = mode

    slider.Text:SetText(labelText)
    slider.Text:SetTextColor(1, 0.88, 0.62, 1)
    slider.Low:SetText(FormatSliderValue(minValue, mode))
    slider.High:SetText(FormatSliderValue(maxValue, mode))

    slider.ValueText = parent:CreateFontString(nil, "OVERLAY")
    slider.ValueText:SetPoint("BOTTOM", slider, "TOP", 0, 8)
    slider.ValueText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    slider.ValueText:SetTextColor(0.95, 0.91, 0.85, 1)
    slider.ValueText:Hide()

    slider:SetScript("OnValueChanged", function(self, value)
        RefreshSliderCaption(self)

        if isRefreshing or not self.ApplyValue then
            return
        end

        self:ApplyValue(value)
    end)

    RefreshSliderCaption(slider)
    return slider
end

local function CreateSectionCheckbox(parent, anchor, titleText, hintText)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    local anchorOffsetX = anchor and anchor.BeavisNextCheckboxOffsetX or -4
    checkbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", anchorOffsetX, -14)

    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetPoint("LEFT", checkbox, "RIGHT", 6, 0)
    label:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    label:SetTextColor(0.95, 0.91, 0.85, 1)
    label:SetText(titleText)
    checkbox.Label = label

    local hint = parent:CreateFontString(nil, "OVERLAY")
    hint:SetPoint("TOPLEFT", checkbox, "BOTTOMLEFT", 34, -2)
    hint:SetPoint("RIGHT", parent, "RIGHT", -18, 0)
    hint:SetJustifyH("LEFT")
    hint:SetJustifyV("TOP")
    hint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    hint:SetTextColor(0.78, 0.74, 0.69, 1)
    hint:SetText(hintText)
    checkbox.Hint = hint
    hint.BeavisNextCheckboxOffsetX = -34
    checkbox.BeavisNextCheckboxOffsetX = 0

    return checkbox
end

local function CreateSingleLineInput(parent, width, height)
    local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editBox:SetSize(width or 240, height or 30)
    editBox:SetAutoFocus(false)
    editBox:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    editBox:SetTextInsets(8, 8, 0, 0)
    editBox:SetMaxLetters(240)
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    editBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    return editBox
end

local function CreateMultiLineInput(parent, width, height)
    local container = CreateFrame("Frame", nil, parent, FrameWithBackdrop)
    container:SetSize(width or 300, height or 96)

    if container.SetBackdrop then
        container:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            tile = false,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        })
        container:SetBackdropColor(0.06, 0.06, 0.07, 0.92)
        container:SetBackdropBorderColor(0.40, 0.32, 0.20, 0.95)
    end

    local scrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -28, 8)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll() or 0
        local step = 24
        local nextValue = current - (delta * step)
        if nextValue < 0 then
            nextValue = 0
        end
        self:SetVerticalScroll(nextValue)
    end)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    editBox:SetWidth((width or 300) - 44)
    editBox:SetTextInsets(4, 4, 4, 4)
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    editBox:SetScript("OnCursorChanged", function(self, _, y, _, cursorHeight)
        local scrollTop = scrollFrame:GetVerticalScroll()
        local scrollBottom = scrollTop + scrollFrame:GetHeight()
        local cursorBottom = y + cursorHeight

        if cursorBottom > scrollBottom then
            scrollFrame:SetVerticalScroll(cursorBottom - scrollFrame:GetHeight())
        elseif y < scrollTop then
            scrollFrame:SetVerticalScroll(y)
        end
    end)
    editBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText() or ""
        local _, lineBreakCount = string.gsub(text, "\n", "\n")
        local _, fontHeight = self:GetFont()
        local lineHeight = (tonumber(fontHeight) or 13) + 4
        local totalHeight = ((lineBreakCount + 1) * lineHeight) + 16
        self:SetHeight(math.max(totalHeight, scrollFrame:GetHeight()))
    end)

    scrollFrame:SetScrollChild(editBox)

    container.ScrollFrame = scrollFrame
    container.EditBox = editBox
    return container, editBox
end

local PageLFG = CreateFrame("Frame", nil, Content)
PageLFG:SetAllPoints()
PageLFG:Hide()

PageScrollFrame = CreateFrame("ScrollFrame", nil, PageLFG, "UIPanelScrollFrameTemplate")
PageScrollFrame:SetPoint("TOPLEFT", PageLFG, "TOPLEFT", 0, 0)
PageScrollFrame:SetPoint("BOTTOMRIGHT", PageLFG, "BOTTOMRIGHT", -28, 0)
PageScrollFrame:EnableMouseWheel(true)

PageContentFrame = CreateFrame("Frame", nil, PageScrollFrame)
PageContentFrame:SetSize(1, 1)
PageScrollFrame:SetScrollChild(PageContentFrame)

-- ========================================
-- Header
-- ========================================

local IntroPanel = CreateFrame("Frame", nil, PageContentFrame)
IntroPanel:SetPoint("TOPLEFT", PageContentFrame, "TOPLEFT", 20, -20)
IntroPanel:SetPoint("TOPRIGHT", PageContentFrame, "TOPRIGHT", -20, -20)
IntroPanel:SetHeight(110)

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
IntroTitle:SetText(BeavisQoL.GetModulePageTitle("LFG", L("LFG")))

local IntroText = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroText:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -10)
IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
IntroText:SetJustifyH("LEFT")
IntroText:SetJustifyV("TOP")
IntroText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroText:SetTextColor(0.95, 0.91, 0.85, 1)
IntroText:SetText(L("LFG_DESC"))

-- ========================================
-- Bereich: Länderflaggen
-- ========================================

local FlagsPanel = CreateFrame("Frame", nil, PageContentFrame)
FlagsPanel:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -18)
FlagsPanel:SetPoint("TOPRIGHT", IntroPanel, "BOTTOMRIGHT", 0, -18)
FlagsPanel:SetHeight(115)

local FlagsBg = FlagsPanel:CreateTexture(nil, "BACKGROUND")
FlagsBg:SetAllPoints()
FlagsBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

local FlagsBorder = FlagsPanel:CreateTexture(nil, "ARTWORK")
FlagsBorder:SetPoint("BOTTOMLEFT", FlagsPanel, "BOTTOMLEFT", 0, 0)
FlagsBorder:SetPoint("BOTTOMRIGHT", FlagsPanel, "BOTTOMRIGHT", 0, 0)
FlagsBorder:SetHeight(1)
FlagsBorder:SetColorTexture(0.88, 0.72, 0.46, 0.82)

local FlagsTitle = FlagsPanel:CreateFontString(nil, "OVERLAY")
FlagsTitle:SetPoint("TOPLEFT", FlagsPanel, "TOPLEFT", 18, -14)
FlagsTitle:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
FlagsTitle:SetTextColor(1, 0.88, 0.62, 1)
FlagsTitle:SetText(L("FLAGS_TITLE"))

local FlagsCheckbox = CreateFrame("CheckButton", nil, FlagsPanel, "UICheckButtonTemplate")
FlagsCheckbox:SetPoint("TOPLEFT", FlagsTitle, "BOTTOMLEFT", -4, -12)

local FlagsLabel = FlagsPanel:CreateFontString(nil, "OVERLAY")
FlagsLabel:SetPoint("LEFT", FlagsCheckbox, "RIGHT", 6, 0)
FlagsLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
FlagsLabel:SetTextColor(0.95, 0.91, 0.85, 1)
FlagsLabel:SetText(L("ACTIVE"))

local FlagsHint = FlagsPanel:CreateFontString(nil, "OVERLAY")
FlagsHint:SetPoint("TOPLEFT", FlagsCheckbox, "BOTTOMLEFT", 34, -2)
FlagsHint:SetPoint("RIGHT", FlagsPanel, "RIGHT", -18, 0)
FlagsHint:SetJustifyH("LEFT")
FlagsHint:SetJustifyV("TOP")
FlagsHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
FlagsHint:SetTextColor(0.78, 0.74, 0.69, 1)
FlagsHint:SetText(L("FLAGS_HINT"))

-- ========================================
-- Bereich: Listing-Presets
-- ========================================

local ListingPresetPanel = CreateFrame("Frame", nil, PageContentFrame)
ListingPresetPanel:SetPoint("TOPLEFT", FlagsPanel, "BOTTOMLEFT", 0, -18)
ListingPresetPanel:SetPoint("TOPRIGHT", FlagsPanel, "BOTTOMRIGHT", 0, -18)
ListingPresetPanel:SetHeight(392)

local ListingPresetPanelBg = ListingPresetPanel:CreateTexture(nil, "BACKGROUND")
ListingPresetPanelBg:SetAllPoints()
ListingPresetPanelBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

local ListingPresetPanelBorder = ListingPresetPanel:CreateTexture(nil, "ARTWORK")
ListingPresetPanelBorder:SetPoint("BOTTOMLEFT", ListingPresetPanel, "BOTTOMLEFT", 0, 0)
ListingPresetPanelBorder:SetPoint("BOTTOMRIGHT", ListingPresetPanel, "BOTTOMRIGHT", 0, 0)
ListingPresetPanelBorder:SetHeight(1)
ListingPresetPanelBorder:SetColorTexture(0.88, 0.72, 0.46, 0.82)

local ListingPresetTitle = ListingPresetPanel:CreateFontString(nil, "OVERLAY")
ListingPresetTitle:SetPoint("TOPLEFT", ListingPresetPanel, "TOPLEFT", 18, -14)
ListingPresetTitle:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
ListingPresetTitle:SetTextColor(1, 0.88, 0.62, 1)
ListingPresetTitle:SetText(L("LFG_LISTING_PRESET_TITLE"))

local ListingPresetHint = ListingPresetPanel:CreateFontString(nil, "OVERLAY")
ListingPresetHint:SetPoint("TOPLEFT", ListingPresetTitle, "BOTTOMLEFT", 0, -8)
ListingPresetHint:SetPoint("RIGHT", ListingPresetPanel, "RIGHT", -18, 0)
ListingPresetHint:SetJustifyH("LEFT")
ListingPresetHint:SetJustifyV("TOP")
ListingPresetHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
ListingPresetHint:SetTextColor(0.78, 0.74, 0.69, 1)
ListingPresetHint:SetText(L("LFG_LISTING_PRESET_HINT"))

local ListingPresetEnableCheckbox = CreateSectionCheckbox(ListingPresetPanel, ListingPresetHint, L("LFG_LISTING_PRESET_ENABLE"), L("LFG_LISTING_PRESET_ENABLE_HINT"))

local ListingPresetNameLabel = ListingPresetPanel:CreateFontString(nil, "OVERLAY")
ListingPresetNameLabel:SetPoint("TOPLEFT", ListingPresetEnableCheckbox.Hint, "BOTTOMLEFT", 4, -18)
ListingPresetNameLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
ListingPresetNameLabel:SetTextColor(1, 0.88, 0.62, 1)
ListingPresetNameLabel:SetText(L("LFG_LISTING_NAME_SUFFIX"))

local ListingPresetNameLabels = {}
local ListingPresetNameInputs = {}
for index = 1, LISTING_TEXT_PRESET_COUNT do
    local rowLabel = ListingPresetPanel:CreateFontString(nil, "OVERLAY")
    rowLabel:SetSize(78, 22)
    rowLabel:SetJustifyH("LEFT")
    rowLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    rowLabel:SetTextColor(0.95, 0.91, 0.85, 1)
    rowLabel:SetText(string.format(L("LFG_LISTING_PRESET_SLOT"), index))
    if index == 1 then
        rowLabel:SetPoint("TOPLEFT", ListingPresetNameLabel, "BOTTOMLEFT", 0, -8)
    else
        rowLabel:SetPoint("TOPLEFT", ListingPresetNameInputs[index - 1], "BOTTOMLEFT", -88, -10)
    end

    local input = CreateSingleLineInput(ListingPresetPanel, 420, 30)
    input:SetPoint("LEFT", rowLabel, "RIGHT", 10, 0)
    input:SetPoint("RIGHT", ListingPresetPanel, "RIGHT", -28, 0)

    ListingPresetNameLabels[index] = rowLabel
    ListingPresetNameInputs[index] = input
end

local ListingPresetNameHint = ListingPresetPanel:CreateFontString(nil, "OVERLAY")
ListingPresetNameHint:SetPoint("TOPLEFT", ListingPresetNameInputs[LISTING_TEXT_PRESET_COUNT], "BOTTOMLEFT", 4, -10)
ListingPresetNameHint:SetPoint("RIGHT", ListingPresetPanel, "RIGHT", -18, 0)
ListingPresetNameHint:SetJustifyH("LEFT")
ListingPresetNameHint:SetJustifyV("TOP")
ListingPresetNameHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
ListingPresetNameHint:SetTextColor(0.72, 0.72, 0.72, 1)
ListingPresetNameHint:SetText(L("LFG_LISTING_NAME_SUFFIX_HINT"))

local ListingPresetDetailsLabel = ListingPresetPanel:CreateFontString(nil, "OVERLAY")
ListingPresetDetailsLabel:SetPoint("TOPLEFT", ListingPresetNameHint, "BOTTOMLEFT", 0, -18)
ListingPresetDetailsLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
ListingPresetDetailsLabel:SetTextColor(1, 0.88, 0.62, 1)
ListingPresetDetailsLabel:SetText(L("LFG_LISTING_DETAILS"))

local ListingPresetDetailsLabels = {}
local ListingPresetDetailsInputFrames = {}
local ListingPresetDetailsInputs = {}
for index = 1, LISTING_TEXT_PRESET_COUNT do
    local rowLabel = ListingPresetPanel:CreateFontString(nil, "OVERLAY")
    rowLabel:SetSize(78, 22)
    rowLabel:SetJustifyH("LEFT")
    rowLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    rowLabel:SetTextColor(0.95, 0.91, 0.85, 1)
    rowLabel:SetText(string.format(L("LFG_LISTING_PRESET_SLOT"), index))
    if index == 1 then
        rowLabel:SetPoint("TOPLEFT", ListingPresetDetailsLabel, "BOTTOMLEFT", 0, -8)
    else
        rowLabel:SetPoint("TOPLEFT", ListingPresetDetailsInputFrames[index - 1], "BOTTOMLEFT", -88, -12)
    end

    local inputFrame, input = CreateMultiLineInput(ListingPresetPanel, 420, 58)
    inputFrame:SetPoint("TOPLEFT", rowLabel, "TOPRIGHT", 10, 0)
    inputFrame:SetPoint("RIGHT", ListingPresetPanel, "RIGHT", -28, 0)
    inputFrame:SetHeight(58)

    ListingPresetDetailsLabels[index] = rowLabel
    ListingPresetDetailsInputFrames[index] = inputFrame
    ListingPresetDetailsInputs[index] = input
end

local ListingPresetDetailsHint = ListingPresetPanel:CreateFontString(nil, "OVERLAY")
ListingPresetDetailsHint:SetPoint("TOPLEFT", ListingPresetDetailsInputFrames[LISTING_TEXT_PRESET_COUNT], "BOTTOMLEFT", 4, -10)
ListingPresetDetailsHint:SetPoint("RIGHT", ListingPresetPanel, "RIGHT", -18, 0)
ListingPresetDetailsHint:SetJustifyH("LEFT")
ListingPresetDetailsHint:SetJustifyV("TOP")
ListingPresetDetailsHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
ListingPresetDetailsHint:SetTextColor(0.72, 0.72, 0.72, 1)
ListingPresetDetailsHint:SetText(L("LFG_LISTING_DETAILS_HINT"))

local ListingPresetPlaystyleLabel = ListingPresetPanel:CreateFontString(nil, "OVERLAY")
ListingPresetPlaystyleLabel:SetPoint("TOPLEFT", ListingPresetDetailsHint, "BOTTOMLEFT", 0, -18)
ListingPresetPlaystyleLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
ListingPresetPlaystyleLabel:SetTextColor(1, 0.88, 0.62, 1)
ListingPresetPlaystyleLabel:SetText(L("LFG_LISTING_PLAYSTYLE"))

local ListingPresetPlaystyleDropdown = CreateFrame("Frame", nil, ListingPresetPanel, "UIDropDownMenuTemplate")
ListingPresetPlaystyleDropdown:SetPoint("TOPLEFT", ListingPresetPlaystyleLabel, "BOTTOMLEFT", -16, -2)
UIDropDownMenu_SetWidth(ListingPresetPlaystyleDropdown, 240)
UIDropDownMenu_SetText(ListingPresetPlaystyleDropdown, L("LFG_LISTING_PLAYSTYLE_NONE"))

local ListingPresetPlaystyleHint = ListingPresetPanel:CreateFontString(nil, "OVERLAY")
ListingPresetPlaystyleHint:SetPoint("TOPLEFT", ListingPresetPlaystyleDropdown, "BOTTOMLEFT", 20, -4)
ListingPresetPlaystyleHint:SetPoint("RIGHT", ListingPresetPanel, "RIGHT", -18, 0)
ListingPresetPlaystyleHint:SetJustifyH("LEFT")
ListingPresetPlaystyleHint:SetJustifyV("TOP")
ListingPresetPlaystyleHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
ListingPresetPlaystyleHint:SetTextColor(0.72, 0.72, 0.72, 1)
ListingPresetPlaystyleHint:SetText(L("LFG_LISTING_PLAYSTYLE_HINT"))

-- ========================================
-- Bereich: Easy LFG
-- ========================================

local EasyLFGPanel = CreateFrame("Frame", nil, PageContentFrame)
EasyLFGPanel:SetPoint("TOPLEFT", ListingPresetPanel, "BOTTOMLEFT", 0, -18)
EasyLFGPanel:SetPoint("TOPRIGHT", ListingPresetPanel, "BOTTOMRIGHT", 0, -18)
EasyLFGPanel:SetHeight(300)

local EasyLFGPanelBg = EasyLFGPanel:CreateTexture(nil, "BACKGROUND")
EasyLFGPanelBg:SetAllPoints()
EasyLFGPanelBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

local EasyLFGPanelBorder = EasyLFGPanel:CreateTexture(nil, "ARTWORK")
EasyLFGPanelBorder:SetPoint("BOTTOMLEFT", EasyLFGPanel, "BOTTOMLEFT", 0, 0)
EasyLFGPanelBorder:SetPoint("BOTTOMRIGHT", EasyLFGPanel, "BOTTOMRIGHT", 0, 0)
EasyLFGPanelBorder:SetHeight(1)
EasyLFGPanelBorder:SetColorTexture(0.88, 0.72, 0.46, 0.82)

local EasyLFGTitle = EasyLFGPanel:CreateFontString(nil, "OVERLAY")
EasyLFGTitle:SetPoint("TOPLEFT", EasyLFGPanel, "TOPLEFT", 18, -14)
EasyLFGTitle:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
EasyLFGTitle:SetTextColor(1, 0.88, 0.62, 1)
EasyLFGTitle:SetText(L("EASY_LFG_TITLE"))

local EasyLFGHint = EasyLFGPanel:CreateFontString(nil, "OVERLAY")
EasyLFGHint:SetPoint("TOPLEFT", EasyLFGTitle, "BOTTOMLEFT", 0, -8)
EasyLFGHint:SetPoint("RIGHT", EasyLFGPanel, "RIGHT", -18, 0)
EasyLFGHint:SetJustifyH("LEFT")
EasyLFGHint:SetJustifyV("TOP")
EasyLFGHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
EasyLFGHint:SetTextColor(0.78, 0.74, 0.69, 1)
EasyLFGHint:SetText(L("EASY_LFG_HINT"))

local EasyLFGShowOverlayCheckbox = CreateSectionCheckbox(EasyLFGPanel, EasyLFGHint, L("EASY_LFG_SHOW_OVERLAY"), L("EASY_LFG_SHOW_OVERLAY_HINT"))
local EasyLFGOverlayLockCheckbox = CreateSectionCheckbox(EasyLFGPanel, EasyLFGShowOverlayCheckbox.Hint, L("EASY_LFG_LOCK_OVERLAY"), L("EASY_LFG_LOCK_OVERLAY_HINT"))

local EasyLFGScaleSlider = CreateValueSlider(EasyLFGPanel, L("EASY_LFG_SCALE"), 0.70, 1.15, 0.05, "scale")
EasyLFGScaleSlider:SetPoint("TOPLEFT", EasyLFGOverlayLockCheckbox.Hint, "BOTTOMLEFT", 18, -34)

local EasyLFGScaleHint = EasyLFGPanel:CreateFontString(nil, "OVERLAY")
EasyLFGScaleHint:SetPoint("TOPLEFT", EasyLFGScaleSlider, "BOTTOMLEFT", -2, -12)
EasyLFGScaleHint:SetPoint("RIGHT", EasyLFGPanel, "RIGHT", -18, 0)
EasyLFGScaleHint:SetJustifyH("LEFT")
EasyLFGScaleHint:SetJustifyV("TOP")
EasyLFGScaleHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
EasyLFGScaleHint:SetTextColor(0.74, 0.74, 0.74, 1)

local EasyLFGTextScaleSlider = CreateValueSlider(EasyLFGPanel, L("EASY_LFG_TEXT_SCALE"), 0.75, 1.50, 0.05, "scale")
EasyLFGTextScaleSlider:SetPoint("TOPLEFT", EasyLFGScaleHint, "BOTTOMLEFT", 2, -30)

local EasyLFGTextScaleHint = EasyLFGPanel:CreateFontString(nil, "OVERLAY")
EasyLFGTextScaleHint:SetPoint("TOPLEFT", EasyLFGTextScaleSlider, "BOTTOMLEFT", -2, -12)
EasyLFGTextScaleHint:SetPoint("RIGHT", EasyLFGPanel, "RIGHT", -18, 0)
EasyLFGTextScaleHint:SetJustifyH("LEFT")
EasyLFGTextScaleHint:SetJustifyV("TOP")
EasyLFGTextScaleHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
EasyLFGTextScaleHint:SetTextColor(0.74, 0.74, 0.74, 1)

local EasyLFGAlphaSlider = CreateValueSlider(EasyLFGPanel, L("EASY_LFG_BACKGROUND_ALPHA"), 0.25, 0.85, 0.05, "alpha")
EasyLFGAlphaSlider:SetPoint("TOPLEFT", EasyLFGTextScaleHint, "BOTTOMLEFT", 2, -30)

local EasyLFGAlphaHint = EasyLFGPanel:CreateFontString(nil, "OVERLAY")
EasyLFGAlphaHint:SetPoint("TOPLEFT", EasyLFGAlphaSlider, "BOTTOMLEFT", -2, -12)
EasyLFGAlphaHint:SetPoint("RIGHT", EasyLFGPanel, "RIGHT", -18, 0)
EasyLFGAlphaHint:SetJustifyH("LEFT")
EasyLFGAlphaHint:SetJustifyV("TOP")
EasyLFGAlphaHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
EasyLFGAlphaHint:SetTextColor(0.74, 0.74, 0.74, 1)

local EasyLFGResetButton = CreateFrame("Button", nil, EasyLFGPanel, "UIPanelButtonTemplate")
EasyLFGResetButton:SetSize(182, 26)
EasyLFGResetButton:SetPoint("TOPLEFT", EasyLFGAlphaHint, "BOTTOMLEFT", 2, -18)
EasyLFGResetButton:SetText(L("RESET_POSITION"))

local EasyLFGResetHint = EasyLFGPanel:CreateFontString(nil, "OVERLAY")
EasyLFGResetHint:SetPoint("LEFT", EasyLFGResetButton, "RIGHT", 12, 0)
EasyLFGResetHint:SetPoint("RIGHT", EasyLFGPanel, "RIGHT", -18, 0)
EasyLFGResetHint:SetJustifyH("LEFT")
EasyLFGResetHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
EasyLFGResetHint:SetTextColor(0.72, 0.72, 0.72, 1)
EasyLFGResetHint:SetText(L("EASY_LFG_RESET_HINT"))

-- ========================================
-- Bereich: Einladungs-Timer
-- ========================================

local InviteTimerPanel = CreateFrame("Frame", nil, PageContentFrame)
InviteTimerPanel:SetPoint("TOPLEFT", EasyLFGPanel, "BOTTOMLEFT", 0, -18)
InviteTimerPanel:SetPoint("TOPRIGHT", EasyLFGPanel, "BOTTOMRIGHT", 0, -18)
InviteTimerPanel:SetHeight(152)

local InviteTimerPanelBg = InviteTimerPanel:CreateTexture(nil, "BACKGROUND")
InviteTimerPanelBg:SetAllPoints()
InviteTimerPanelBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

local InviteTimerPanelBorder = InviteTimerPanel:CreateTexture(nil, "ARTWORK")
InviteTimerPanelBorder:SetPoint("BOTTOMLEFT", InviteTimerPanel, "BOTTOMLEFT", 0, 0)
InviteTimerPanelBorder:SetPoint("BOTTOMRIGHT", InviteTimerPanel, "BOTTOMRIGHT", 0, 0)
InviteTimerPanelBorder:SetHeight(1)
InviteTimerPanelBorder:SetColorTexture(0.88, 0.72, 0.46, 0.82)

local InviteTimerTitle = InviteTimerPanel:CreateFontString(nil, "OVERLAY")
InviteTimerTitle:SetPoint("TOPLEFT", InviteTimerPanel, "TOPLEFT", 18, -14)
InviteTimerTitle:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
InviteTimerTitle:SetTextColor(1, 0.88, 0.62, 1)
InviteTimerTitle:SetText(L("INVITE_TIMER_TITLE"))

local InviteTimerHint = InviteTimerPanel:CreateFontString(nil, "OVERLAY")
InviteTimerHint:SetPoint("TOPLEFT", InviteTimerTitle, "BOTTOMLEFT", 0, -8)
InviteTimerHint:SetPoint("RIGHT", InviteTimerPanel, "RIGHT", -18, 0)
InviteTimerHint:SetJustifyH("LEFT")
InviteTimerHint:SetJustifyV("TOP")
InviteTimerHint:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
InviteTimerHint:SetTextColor(0.78, 0.74, 0.69, 1)
InviteTimerHint:SetText(L("INVITE_TIMER_HINT"))

local InviteTimerCheckbox = CreateSectionCheckbox(InviteTimerPanel, InviteTimerHint, L("INVITE_TIMER_ENABLED"), L("INVITE_TIMER_ENABLED_HINT"))
local InviteTimerCountdownCheckbox = CreateSectionCheckbox(InviteTimerPanel, InviteTimerCheckbox.Hint, L("INVITE_TIMER_COUNTDOWN_SOUND"), L("INVITE_TIMER_COUNTDOWN_SOUND_HINT"))

local function RefreshListingPresetPlaystyleDropdown()
    local selectedValue = 0
    local selectedLabel = L("LFG_LISTING_PLAYSTYLE_NONE")

    if LFG.GetListingPlaystylePreset then
        selectedValue = LFG.GetListingPlaystylePreset()
    end

    if LFG.GetListingPlaystylePresetLabel then
        selectedLabel = LFG.GetListingPlaystylePresetLabel(selectedValue)
    end

    UIDropDownMenu_SetWidth(ListingPresetPlaystyleDropdown, 240)
    UIDropDownMenu_SetSelectedValue(ListingPresetPlaystyleDropdown, selectedValue)
    UIDropDownMenu_SetText(ListingPresetPlaystyleDropdown, selectedLabel)
end

local function SetListingPresetWidgetsEnabled(enabled)
    local widgetAlpha = enabled and 1 or 0.55

    for index, input in ipairs(ListingPresetNameInputs) do
        if input.SetEnabled then
            input:SetEnabled(enabled)
        end
        input:EnableMouse(enabled)
        input:SetAlpha(widgetAlpha)
        ListingPresetNameLabels[index]:SetAlpha(widgetAlpha)
    end

    for index, input in ipairs(ListingPresetDetailsInputs) do
        if input.SetEnabled then
            input:SetEnabled(enabled)
        end
        input:EnableMouse(enabled)
        ListingPresetDetailsInputFrames[index]:SetAlpha(widgetAlpha)
        ListingPresetDetailsLabels[index]:SetAlpha(widgetAlpha)
    end

    if enabled then
        UIDropDownMenu_EnableDropDown(ListingPresetPlaystyleDropdown)
    else
        UIDropDownMenu_DisableDropDown(ListingPresetPlaystyleDropdown)
    end
    ListingPresetPlaystyleDropdown:SetAlpha(widgetAlpha)
end

function PageLFG:UpdateLayout()
    local contentWidth = math.max(1, PageScrollFrame:GetWidth())
    PageContentFrame:SetWidth(contentWidth)

    if not self:IsShown() then
        return
    end

    IntroPanel:SetHeight(math.max(
        110,
        math.ceil(
            16
            + GetTextHeight(IntroTitle, 24)
            + 10
            + GetTextHeight(IntroText, 13)
            + 18
        )
    ))

    FlagsPanel:SetHeight(math.max(
        115,
        math.ceil(
            14
            + GetTextHeight(FlagsTitle, 16)
            + 12
            + FlagsCheckbox:GetHeight()
            + 2
            + GetTextHeight(FlagsHint, 12)
            + 18
        )
    ))

    local listingPresetBottomObject = GetLowerBottomObject(ListingPresetPlaystyleDropdown, ListingPresetPlaystyleHint)
    ListingPresetPanel:SetHeight(GetMeasuredPanelHeight(ListingPresetPanel, listingPresetBottomObject, 392, 20))

    local easyLFGBottomObject = GetLowerBottomObject(EasyLFGResetButton, EasyLFGResetHint)
    EasyLFGPanel:SetHeight(GetMeasuredPanelHeight(EasyLFGPanel, easyLFGBottomObject, 300, 20))

    local inviteTimerBottomObject = GetLowerBottomObject(InviteTimerCountdownCheckbox, InviteTimerCountdownCheckbox.Hint)
    InviteTimerPanel:SetHeight(GetMeasuredPanelHeight(InviteTimerPanel, inviteTimerBottomObject, 152, 20))

    local contentHeight = 20
        + IntroPanel:GetHeight()
        + 18 + FlagsPanel:GetHeight()
        + 18 + ListingPresetPanel:GetHeight()
        + 18 + EasyLFGPanel:GetHeight()
        + 18 + InviteTimerPanel:GetHeight()
        + 20

    PageContentFrame:SetHeight(math.max(PageScrollFrame:GetHeight(), contentHeight))
end

function PageLFG:ScrollToListingPresets()
    self:RefreshState()
    self:UpdateLayout()

    local contentTop = PageContentFrame:GetTop()
    local panelTop = ListingPresetPanel:GetTop()
    if not contentTop or not panelTop then
        return
    end

    local maxScroll = math.max(0, PageContentFrame:GetHeight() - PageScrollFrame:GetHeight())
    local targetScroll = math.max(0, math.min(maxScroll, contentTop - panelTop - 8))
    PageScrollFrame:SetVerticalScroll(targetScroll)
end

-- Die Checkbox liest ihren Zustand direkt aus dem Modul, damit die Seite kaum eigene Logik braucht.
function PageLFG:RefreshState()
    local flagsEnabled = false
    local listingPresetEnabled = false
    local listingNamePresets = {}
    local listingDetailsPresets = {}
    local easyLFGEnabled = false
    local easyLFGLocked = false
    local easyLFGScale = 1.0
    local easyLFGTextScale = 1.0
    local easyLFGAlpha = 0.58
    local inviteTimerEnabled = false
    local inviteTimerCountdownEnabled = false

    IntroTitle:SetText(BeavisQoL.GetModulePageTitle("LFG", L("LFG")))
    IntroText:SetText(L("LFG_DESC"))
    FlagsTitle:SetText(L("FLAGS_TITLE"))
    FlagsLabel:SetText(L("ACTIVE"))
    FlagsHint:SetText(L("FLAGS_HINT"))
    ListingPresetTitle:SetText(L("LFG_LISTING_PRESET_TITLE"))
    ListingPresetHint:SetText(L("LFG_LISTING_PRESET_HINT"))
    ListingPresetEnableCheckbox.Label:SetText(L("LFG_LISTING_PRESET_ENABLE"))
    ListingPresetEnableCheckbox.Hint:SetText(L("LFG_LISTING_PRESET_ENABLE_HINT"))
    ListingPresetNameLabel:SetText(L("LFG_LISTING_NAME_SUFFIX"))
    ListingPresetNameHint:SetText(L("LFG_LISTING_NAME_SUFFIX_HINT"))
    ListingPresetDetailsLabel:SetText(L("LFG_LISTING_DETAILS"))
    ListingPresetDetailsHint:SetText(L("LFG_LISTING_DETAILS_HINT"))
    for index, label in ipairs(ListingPresetNameLabels) do
        label:SetText(string.format(L("LFG_LISTING_PRESET_SLOT"), index))
    end
    for index, label in ipairs(ListingPresetDetailsLabels) do
        label:SetText(string.format(L("LFG_LISTING_PRESET_SLOT"), index))
    end
    ListingPresetPlaystyleLabel:SetText(L("LFG_LISTING_PLAYSTYLE"))
    ListingPresetPlaystyleHint:SetText(L("LFG_LISTING_PLAYSTYLE_HINT"))
    EasyLFGTitle:SetText(L("EASY_LFG_TITLE"))
    EasyLFGHint:SetText(L("EASY_LFG_HINT"))
    EasyLFGShowOverlayCheckbox.Label:SetText(L("EASY_LFG_SHOW_OVERLAY"))
    EasyLFGShowOverlayCheckbox.Hint:SetText(L("EASY_LFG_SHOW_OVERLAY_HINT"))
    EasyLFGOverlayLockCheckbox.Label:SetText(L("EASY_LFG_LOCK_OVERLAY"))
    EasyLFGOverlayLockCheckbox.Hint:SetText(L("EASY_LFG_LOCK_OVERLAY_HINT"))
    EasyLFGScaleSlider.LabelText = L("EASY_LFG_SCALE")
    EasyLFGScaleHint:SetText(L("EASY_LFG_SCALE_HINT"))
    EasyLFGTextScaleSlider.LabelText = L("EASY_LFG_TEXT_SCALE")
    EasyLFGTextScaleHint:SetText(L("EASY_LFG_TEXT_SCALE_HINT"))
    EasyLFGAlphaSlider.LabelText = L("EASY_LFG_BACKGROUND_ALPHA")
    EasyLFGAlphaHint:SetText(L("EASY_LFG_BACKGROUND_ALPHA_HINT"))
    EasyLFGResetButton:SetText(L("RESET_POSITION"))
    EasyLFGResetHint:SetText(L("EASY_LFG_RESET_HINT"))
    InviteTimerTitle:SetText(L("INVITE_TIMER_TITLE"))
    InviteTimerHint:SetText(L("INVITE_TIMER_HINT"))
    InviteTimerCheckbox.Label:SetText(L("INVITE_TIMER_ENABLED"))
    InviteTimerCheckbox.Hint:SetText(L("INVITE_TIMER_ENABLED_HINT"))
    InviteTimerCountdownCheckbox.Label:SetText(L("INVITE_TIMER_COUNTDOWN_SOUND"))
    InviteTimerCountdownCheckbox.Hint:SetText(L("INVITE_TIMER_COUNTDOWN_SOUND_HINT"))

    if LFG.IsFlagsEnabled then
        flagsEnabled = LFG.IsFlagsEnabled()
    end

    if LFG.IsListingAutoFillEnabled then
        listingPresetEnabled = LFG.IsListingAutoFillEnabled()
    end

    if LFG.GetListingNamePresetSlots then
        listingNamePresets = LFG.GetListingNamePresetSlots()
    elseif LFG.GetListingNameSuffix then
        listingNamePresets[1] = LFG.GetListingNameSuffix()
    end

    if LFG.GetListingDetailsPresetSlots then
        listingDetailsPresets = LFG.GetListingDetailsPresetSlots()
    elseif LFG.GetListingDetailsPreset then
        listingDetailsPresets[1] = LFG.GetListingDetailsPreset()
    end

    if LFG.IsEasyLFGEnabled then
        easyLFGEnabled = LFG.IsEasyLFGEnabled()
    end

    if LFG.IsEasyLFGLocked then
        easyLFGLocked = LFG.IsEasyLFGLocked()
    end

    if LFG.GetEasyLFGScale then
        easyLFGScale = LFG.GetEasyLFGScale()
    end

    if LFG.GetEasyLFGTextScale then
        easyLFGTextScale = LFG.GetEasyLFGTextScale()
    end

    if LFG.GetEasyLFGBackgroundAlpha then
        easyLFGAlpha = LFG.GetEasyLFGBackgroundAlpha()
    end

    if LFG.IsInviteTimerEnabled then
        inviteTimerEnabled = LFG.IsInviteTimerEnabled()
    end

    if LFG.IsInviteTimerCountdownEnabled then
        inviteTimerCountdownEnabled = LFG.IsInviteTimerCountdownEnabled()
    end

    isRefreshing = true
    FlagsCheckbox:SetChecked(flagsEnabled)
    ListingPresetEnableCheckbox:SetChecked(listingPresetEnabled)
    for index, input in ipairs(ListingPresetNameInputs) do
        input:SetText(listingNamePresets[index] or "")
    end
    for index, input in ipairs(ListingPresetDetailsInputs) do
        input:SetText(listingDetailsPresets[index] or "")
    end
    EasyLFGShowOverlayCheckbox:SetChecked(easyLFGEnabled)
    EasyLFGOverlayLockCheckbox:SetChecked(easyLFGLocked)
    EasyLFGScaleSlider:SetValue(easyLFGScale)
    EasyLFGTextScaleSlider:SetValue(easyLFGTextScale)
    EasyLFGAlphaSlider:SetValue(easyLFGAlpha)
    InviteTimerCheckbox:SetChecked(inviteTimerEnabled)
    InviteTimerCountdownCheckbox:SetChecked(inviteTimerCountdownEnabled)
    isRefreshing = false

    RefreshSliderCaption(EasyLFGScaleSlider)
    RefreshSliderCaption(EasyLFGTextScaleSlider)
    RefreshSliderCaption(EasyLFGAlphaSlider)
    RefreshListingPresetPlaystyleDropdown()
    SetListingPresetWidgetsEnabled(listingPresetEnabled)
    self:UpdateLayout()
end

FlagsCheckbox:SetScript("OnClick", function(self)
    if LFG.SetFlagsEnabled then
        LFG.SetFlagsEnabled(self:GetChecked())
    end

    PageLFG:RefreshState()
end)

UIDropDownMenu_Initialize(ListingPresetPlaystyleDropdown, function(_, level)
    local selectedValue = LFG.GetListingPlaystylePreset and LFG.GetListingPlaystylePreset() or 0
    local options = LFG.GetListingPlaystylePresetOptions and LFG.GetListingPlaystylePresetOptions() or {
        {
            value = 0,
            label = L("LFG_LISTING_PLAYSTYLE_NONE"),
        },
    }

    for _, option in ipairs(options) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = option.label
        info.value = option.value
        info.checked = selectedValue == option.value
        info.func = function()
            if LFG.SetListingPlaystylePreset then
                LFG.SetListingPlaystylePreset(option.value)
            end
            RefreshListingPresetPlaystyleDropdown()
        end
        UIDropDownMenu_AddButton(info, level)
    end
end)

ListingPresetEnableCheckbox:SetScript("OnClick", function(self)
    if LFG.SetListingAutoFillEnabled then
        LFG.SetListingAutoFillEnabled(self:GetChecked())
    end

    PageLFG:RefreshState()
end)

for index, input in ipairs(ListingPresetNameInputs) do
    local presetIndex = index
    input:HookScript("OnTextChanged", function(self)
        if isRefreshing or not LFG.SetListingNamePreset then
            return
        end

        LFG.SetListingNamePreset(presetIndex, self:GetText())
    end)

    input:HookScript("OnEditFocusLost", function(self)
        if LFG.SetListingNamePreset then
            LFG.SetListingNamePreset(presetIndex, self:GetText())
        end
    end)
end

for index, input in ipairs(ListingPresetDetailsInputs) do
    local presetIndex = index
    input:HookScript("OnTextChanged", function(self)
        if isRefreshing or not LFG.SetListingDetailsPresetSlot then
            return
        end

        LFG.SetListingDetailsPresetSlot(presetIndex, self:GetText())
    end)

    input:HookScript("OnEditFocusLost", function(self)
        if LFG.SetListingDetailsPresetSlot then
            LFG.SetListingDetailsPresetSlot(presetIndex, self:GetText())
        end
    end)
end

EasyLFGScaleSlider.ApplyValue = function(_, value)
    if LFG.SetEasyLFGScale then
        LFG.SetEasyLFGScale(value)
    end
end

EasyLFGTextScaleSlider.ApplyValue = function(_, value)
    if LFG.SetEasyLFGTextScale then
        LFG.SetEasyLFGTextScale(value)
    end
end

EasyLFGAlphaSlider.ApplyValue = function(_, value)
    if LFG.SetEasyLFGBackgroundAlpha then
        LFG.SetEasyLFGBackgroundAlpha(value)
    end
end

EasyLFGShowOverlayCheckbox:SetScript("OnClick", function(self)
    if LFG.SetEasyLFGEnabled then
        LFG.SetEasyLFGEnabled(self:GetChecked())
    end

    PageLFG:RefreshState()
end)

EasyLFGOverlayLockCheckbox:SetScript("OnClick", function(self)
    if LFG.SetEasyLFGLocked then
        LFG.SetEasyLFGLocked(self:GetChecked())
    end

    PageLFG:RefreshState()
end)

EasyLFGResetButton:SetScript("OnClick", function()
    if LFG.ResetEasyLFGPosition then
        LFG.ResetEasyLFGPosition()
    end
end)

InviteTimerCheckbox:SetScript("OnClick", function(self)
    if LFG.SetInviteTimerEnabled then
        LFG.SetInviteTimerEnabled(self:GetChecked())
    end

    PageLFG:RefreshState()
end)

InviteTimerCountdownCheckbox:SetScript("OnClick", function(self)
    if LFG.SetInviteTimerCountdownEnabled then
        LFG.SetInviteTimerCountdownEnabled(self:GetChecked())
    end

    PageLFG:RefreshState()
end)

PageScrollFrame:SetScript("OnSizeChanged", function()
    PageLFG:UpdateLayout()
end)

PageScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local step = 40
    local currentScroll = self:GetVerticalScroll()
    local maxScroll = math.max(0, PageContentFrame:GetHeight() - self:GetHeight())
    local nextScroll = currentScroll - (delta * step)

    if nextScroll < 0 then
        nextScroll = 0
    elseif nextScroll > maxScroll then
        nextScroll = maxScroll
    end

    self:SetVerticalScroll(nextScroll)
end)

PageLFG:SetScript("OnShow", function()
    PageLFG:RefreshState()
    PageLFG:UpdateLayout()
    PageScrollFrame:SetVerticalScroll(0)
end)

PageLFG:RefreshState()

BeavisQoL.Pages.LFG = PageLFG

