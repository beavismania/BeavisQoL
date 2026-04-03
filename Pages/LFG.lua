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
    slider.Text:SetTextColor(1, 0.82, 0, 1)
    slider.Low:SetText(FormatSliderValue(minValue, mode))
    slider.High:SetText(FormatSliderValue(maxValue, mode))

    slider.ValueText = parent:CreateFontString(nil, "OVERLAY")
    slider.ValueText:SetPoint("BOTTOM", slider, "TOP", 0, 8)
    slider.ValueText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    slider.ValueText:SetTextColor(1, 1, 1, 1)
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
    checkbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -4, -14)

    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetPoint("LEFT", checkbox, "RIGHT", 6, 0)
    label:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    label:SetTextColor(1, 1, 1, 1)
    label:SetText(titleText)
    checkbox.Label = label

    local hint = parent:CreateFontString(nil, "OVERLAY")
    hint:SetPoint("TOPLEFT", checkbox, "BOTTOMLEFT", 34, -2)
    hint:SetPoint("RIGHT", parent, "RIGHT", -18, 0)
    hint:SetJustifyH("LEFT")
    hint:SetJustifyV("TOP")
    hint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    hint:SetTextColor(0.80, 0.80, 0.80, 1)
    hint:SetText(hintText)
    checkbox.Hint = hint

    return checkbox
end

local PageLFG = CreateFrame("Frame", nil, Content)
PageLFG:SetAllPoints()
PageLFG:Hide()

-- ========================================
-- Header
-- ========================================

local IntroPanel = CreateFrame("Frame", nil, PageLFG)
IntroPanel:SetPoint("TOPLEFT", PageLFG, "TOPLEFT", 20, -20)
IntroPanel:SetPoint("TOPRIGHT", PageLFG, "TOPRIGHT", -20, -20)
IntroPanel:SetHeight(110)

local IntroBg = IntroPanel:CreateTexture(nil, "BACKGROUND")
IntroBg:SetAllPoints()
IntroBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local IntroBorder = IntroPanel:CreateTexture(nil, "ARTWORK")
IntroBorder:SetPoint("BOTTOMLEFT", IntroPanel, "BOTTOMLEFT", 0, 0)
IntroBorder:SetPoint("BOTTOMRIGHT", IntroPanel, "BOTTOMRIGHT", 0, 0)
IntroBorder:SetHeight(1)
IntroBorder:SetColorTexture(1, 0.82, 0, 0.9)

local IntroTitle = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroTitle:SetPoint("TOPLEFT", IntroPanel, "TOPLEFT", 18, -16)
IntroTitle:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
IntroTitle:SetTextColor(1, 0.82, 0, 1)
IntroTitle:SetText(L("LFG"))

local IntroText = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroText:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -10)
IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
IntroText:SetJustifyH("LEFT")
IntroText:SetJustifyV("TOP")
IntroText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroText:SetTextColor(1, 1, 1, 1)
IntroText:SetText(L("LFG_DESC"))

-- ========================================
-- Bereich: Länderflaggen
-- ========================================

local FlagsPanel = CreateFrame("Frame", nil, PageLFG)
FlagsPanel:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -18)
FlagsPanel:SetPoint("TOPRIGHT", IntroPanel, "BOTTOMRIGHT", 0, -18)
FlagsPanel:SetHeight(115)

local FlagsBg = FlagsPanel:CreateTexture(nil, "BACKGROUND")
FlagsBg:SetAllPoints()
FlagsBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local FlagsBorder = FlagsPanel:CreateTexture(nil, "ARTWORK")
FlagsBorder:SetPoint("BOTTOMLEFT", FlagsPanel, "BOTTOMLEFT", 0, 0)
FlagsBorder:SetPoint("BOTTOMRIGHT", FlagsPanel, "BOTTOMRIGHT", 0, 0)
FlagsBorder:SetHeight(1)
FlagsBorder:SetColorTexture(1, 0.82, 0, 0.9)

local FlagsTitle = FlagsPanel:CreateFontString(nil, "OVERLAY")
FlagsTitle:SetPoint("TOPLEFT", FlagsPanel, "TOPLEFT", 18, -14)
FlagsTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
FlagsTitle:SetTextColor(1, 0.82, 0, 1)
FlagsTitle:SetText(L("FLAGS_TITLE"))

local FlagsCheckbox = CreateFrame("CheckButton", nil, FlagsPanel, "UICheckButtonTemplate")
FlagsCheckbox:SetPoint("TOPLEFT", FlagsTitle, "BOTTOMLEFT", -4, -12)

local FlagsLabel = FlagsPanel:CreateFontString(nil, "OVERLAY")
FlagsLabel:SetPoint("LEFT", FlagsCheckbox, "RIGHT", 6, 0)
FlagsLabel:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
FlagsLabel:SetTextColor(1, 1, 1, 1)
FlagsLabel:SetText(L("ACTIVE"))

local FlagsHint = FlagsPanel:CreateFontString(nil, "OVERLAY")
FlagsHint:SetPoint("TOPLEFT", FlagsCheckbox, "BOTTOMLEFT", 34, -2)
FlagsHint:SetPoint("RIGHT", FlagsPanel, "RIGHT", -18, 0)
FlagsHint:SetJustifyH("LEFT")
FlagsHint:SetJustifyV("TOP")
FlagsHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
FlagsHint:SetTextColor(0.80, 0.80, 0.80, 1)
FlagsHint:SetText(L("FLAGS_HINT"))

-- ========================================
-- Bereich: Easy LFG
-- ========================================

local EasyLFGPanel = CreateFrame("Frame", nil, PageLFG)
EasyLFGPanel:SetPoint("TOPLEFT", FlagsPanel, "BOTTOMLEFT", 0, -18)
EasyLFGPanel:SetPoint("TOPRIGHT", FlagsPanel, "BOTTOMRIGHT", 0, -18)
EasyLFGPanel:SetHeight(300)

local EasyLFGPanelBg = EasyLFGPanel:CreateTexture(nil, "BACKGROUND")
EasyLFGPanelBg:SetAllPoints()
EasyLFGPanelBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local EasyLFGPanelBorder = EasyLFGPanel:CreateTexture(nil, "ARTWORK")
EasyLFGPanelBorder:SetPoint("BOTTOMLEFT", EasyLFGPanel, "BOTTOMLEFT", 0, 0)
EasyLFGPanelBorder:SetPoint("BOTTOMRIGHT", EasyLFGPanel, "BOTTOMRIGHT", 0, 0)
EasyLFGPanelBorder:SetHeight(1)
EasyLFGPanelBorder:SetColorTexture(1, 0.82, 0, 0.9)

local EasyLFGTitle = EasyLFGPanel:CreateFontString(nil, "OVERLAY")
EasyLFGTitle:SetPoint("TOPLEFT", EasyLFGPanel, "TOPLEFT", 18, -14)
EasyLFGTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
EasyLFGTitle:SetTextColor(1, 0.82, 0, 1)
EasyLFGTitle:SetText(L("EASY_LFG_TITLE"))

local EasyLFGHint = EasyLFGPanel:CreateFontString(nil, "OVERLAY")
EasyLFGHint:SetPoint("TOPLEFT", EasyLFGTitle, "BOTTOMLEFT", 0, -8)
EasyLFGHint:SetPoint("RIGHT", EasyLFGPanel, "RIGHT", -18, 0)
EasyLFGHint:SetJustifyH("LEFT")
EasyLFGHint:SetJustifyV("TOP")
EasyLFGHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
EasyLFGHint:SetTextColor(0.80, 0.80, 0.80, 1)
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
EasyLFGScaleHint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
EasyLFGScaleHint:SetTextColor(0.74, 0.74, 0.74, 1)

local EasyLFGAlphaSlider = CreateValueSlider(EasyLFGPanel, L("EASY_LFG_BACKGROUND_ALPHA"), 0.25, 0.85, 0.05, "alpha")
EasyLFGAlphaSlider:SetPoint("TOPLEFT", EasyLFGScaleHint, "BOTTOMLEFT", 2, -30)

local EasyLFGAlphaHint = EasyLFGPanel:CreateFontString(nil, "OVERLAY")
EasyLFGAlphaHint:SetPoint("TOPLEFT", EasyLFGAlphaSlider, "BOTTOMLEFT", -2, -12)
EasyLFGAlphaHint:SetPoint("RIGHT", EasyLFGPanel, "RIGHT", -18, 0)
EasyLFGAlphaHint:SetJustifyH("LEFT")
EasyLFGAlphaHint:SetJustifyV("TOP")
EasyLFGAlphaHint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
EasyLFGAlphaHint:SetTextColor(0.74, 0.74, 0.74, 1)

local EasyLFGResetButton = CreateFrame("Button", nil, EasyLFGPanel, "UIPanelButtonTemplate")
EasyLFGResetButton:SetSize(182, 26)
EasyLFGResetButton:SetPoint("TOPLEFT", EasyLFGAlphaHint, "BOTTOMLEFT", 2, -18)
EasyLFGResetButton:SetText(L("RESET_POSITION"))

local EasyLFGResetHint = EasyLFGPanel:CreateFontString(nil, "OVERLAY")
EasyLFGResetHint:SetPoint("LEFT", EasyLFGResetButton, "RIGHT", 12, 0)
EasyLFGResetHint:SetPoint("RIGHT", EasyLFGPanel, "RIGHT", -18, 0)
EasyLFGResetHint:SetJustifyH("LEFT")
EasyLFGResetHint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
EasyLFGResetHint:SetTextColor(0.72, 0.72, 0.72, 1)
EasyLFGResetHint:SetText(L("EASY_LFG_RESET_HINT"))

-- ========================================
-- Bereich: Einladungs-Timer
-- ========================================

local InviteTimerPanel = CreateFrame("Frame", nil, PageLFG)
InviteTimerPanel:SetPoint("TOPLEFT", EasyLFGPanel, "BOTTOMLEFT", 0, -18)
InviteTimerPanel:SetPoint("TOPRIGHT", EasyLFGPanel, "BOTTOMRIGHT", 0, -18)
InviteTimerPanel:SetHeight(152)

local InviteTimerPanelBg = InviteTimerPanel:CreateTexture(nil, "BACKGROUND")
InviteTimerPanelBg:SetAllPoints()
InviteTimerPanelBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local InviteTimerPanelBorder = InviteTimerPanel:CreateTexture(nil, "ARTWORK")
InviteTimerPanelBorder:SetPoint("BOTTOMLEFT", InviteTimerPanel, "BOTTOMLEFT", 0, 0)
InviteTimerPanelBorder:SetPoint("BOTTOMRIGHT", InviteTimerPanel, "BOTTOMRIGHT", 0, 0)
InviteTimerPanelBorder:SetHeight(1)
InviteTimerPanelBorder:SetColorTexture(1, 0.82, 0, 0.9)

local InviteTimerTitle = InviteTimerPanel:CreateFontString(nil, "OVERLAY")
InviteTimerTitle:SetPoint("TOPLEFT", InviteTimerPanel, "TOPLEFT", 18, -14)
InviteTimerTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
InviteTimerTitle:SetTextColor(1, 0.82, 0, 1)
InviteTimerTitle:SetText(L("INVITE_TIMER_TITLE"))

local InviteTimerHint = InviteTimerPanel:CreateFontString(nil, "OVERLAY")
InviteTimerHint:SetPoint("TOPLEFT", InviteTimerTitle, "BOTTOMLEFT", 0, -8)
InviteTimerHint:SetPoint("RIGHT", InviteTimerPanel, "RIGHT", -18, 0)
InviteTimerHint:SetJustifyH("LEFT")
InviteTimerHint:SetJustifyV("TOP")
InviteTimerHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
InviteTimerHint:SetTextColor(0.80, 0.80, 0.80, 1)
InviteTimerHint:SetText(L("INVITE_TIMER_HINT"))

local InviteTimerCheckbox = CreateSectionCheckbox(InviteTimerPanel, InviteTimerHint, L("INVITE_TIMER_ENABLED"), L("INVITE_TIMER_ENABLED_HINT"))
local InviteTimerCountdownCheckbox = CreateSectionCheckbox(InviteTimerPanel, InviteTimerCheckbox.Hint, L("INVITE_TIMER_COUNTDOWN_SOUND"), L("INVITE_TIMER_COUNTDOWN_SOUND_HINT"))

function PageLFG:UpdateLayout()
    if not self:IsShown() then
        return
    end

    local panelTop = EasyLFGPanel:GetTop()
    local buttonBottom = EasyLFGResetButton:GetBottom()
    local hintBottom = EasyLFGResetHint:GetBottom()
    if not panelTop or not buttonBottom or not hintBottom then
        return
    end

    local desiredHeight = math.ceil((panelTop - math.min(buttonBottom, hintBottom)) + 20)
    EasyLFGPanel:SetHeight(math.max(300, desiredHeight))
end

-- Die Checkbox liest ihren Zustand direkt aus dem Modul, damit die Seite kaum eigene Logik braucht.
function PageLFG:RefreshState()
    local flagsEnabled = false
    local easyLFGEnabled = false
    local easyLFGLocked = false
    local easyLFGScale = 1.0
    local easyLFGAlpha = 0.58
    local inviteTimerEnabled = false
    local inviteTimerCountdownEnabled = false

    IntroTitle:SetText(L("LFG"))
    IntroText:SetText(L("LFG_DESC"))
    FlagsTitle:SetText(L("FLAGS_TITLE"))
    FlagsLabel:SetText(L("ACTIVE"))
    FlagsHint:SetText(L("FLAGS_HINT"))
    EasyLFGTitle:SetText(L("EASY_LFG_TITLE"))
    EasyLFGHint:SetText(L("EASY_LFG_HINT"))
    EasyLFGShowOverlayCheckbox.Label:SetText(L("EASY_LFG_SHOW_OVERLAY"))
    EasyLFGShowOverlayCheckbox.Hint:SetText(L("EASY_LFG_SHOW_OVERLAY_HINT"))
    EasyLFGOverlayLockCheckbox.Label:SetText(L("EASY_LFG_LOCK_OVERLAY"))
    EasyLFGOverlayLockCheckbox.Hint:SetText(L("EASY_LFG_LOCK_OVERLAY_HINT"))
    EasyLFGScaleSlider.LabelText = L("EASY_LFG_SCALE")
    EasyLFGScaleHint:SetText(L("EASY_LFG_SCALE_HINT"))
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

    if LFG.IsEasyLFGEnabled then
        easyLFGEnabled = LFG.IsEasyLFGEnabled()
    end

    if LFG.IsEasyLFGLocked then
        easyLFGLocked = LFG.IsEasyLFGLocked()
    end

    if LFG.GetEasyLFGScale then
        easyLFGScale = LFG.GetEasyLFGScale()
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
    EasyLFGShowOverlayCheckbox:SetChecked(easyLFGEnabled)
    EasyLFGOverlayLockCheckbox:SetChecked(easyLFGLocked)
    EasyLFGScaleSlider:SetValue(easyLFGScale)
    EasyLFGAlphaSlider:SetValue(easyLFGAlpha)
    InviteTimerCheckbox:SetChecked(inviteTimerEnabled)
    InviteTimerCountdownCheckbox:SetChecked(inviteTimerCountdownEnabled)
    isRefreshing = false

    RefreshSliderCaption(EasyLFGScaleSlider)
    RefreshSliderCaption(EasyLFGAlphaSlider)
    self:UpdateLayout()
end

FlagsCheckbox:SetScript("OnClick", function(self)
    if LFG.SetFlagsEnabled then
        LFG.SetFlagsEnabled(self:GetChecked())
    end

    PageLFG:RefreshState()
end)

EasyLFGScaleSlider.ApplyValue = function(_, value)
    if LFG.SetEasyLFGScale then
        LFG.SetEasyLFGScale(value)
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

PageLFG:SetScript("OnShow", function()
    PageLFG:RefreshState()
    PageLFG:UpdateLayout()
end)

PageLFG:RefreshState()

BeavisQoL.Pages.LFG = PageLFG
