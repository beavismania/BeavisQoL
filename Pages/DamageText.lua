local ADDON_NAME, BeavisAddon = ...

local Content = BeavisAddon.Content
BeavisAddon.DamageText = BeavisAddon.DamageText or {}
local DamageText = BeavisAddon.DamageText

-- Die Seite kann mit Hinweisen und Reglern schnell länger werden.
-- Darum hängt sie wie Misc an einem eigenen ScrollFrame.
local PageDamageText = CreateFrame("Frame", nil, Content)
PageDamageText:SetAllPoints()
PageDamageText:Hide()

local PageDamageTextScrollFrame = CreateFrame("ScrollFrame", nil, PageDamageText, "UIPanelScrollFrameTemplate")
PageDamageTextScrollFrame:SetPoint("TOPLEFT", PageDamageText, "TOPLEFT", 0, 0)
PageDamageTextScrollFrame:SetPoint("BOTTOMRIGHT", PageDamageText, "BOTTOMRIGHT", -28, 0)
PageDamageTextScrollFrame:EnableMouseWheel(true)

local PageDamageTextContent = CreateFrame("Frame", nil, PageDamageTextScrollFrame)
PageDamageTextContent:SetSize(1, 1)
PageDamageTextScrollFrame:SetScrollChild(PageDamageTextContent)

local isRefreshing = false
local sliderCounter = 0

local function FormatValue(value)
    if math.abs(value - math.floor(value)) < 0.01 then
        return tostring(math.floor(value))
    end

    return string.format("%.1f", value)
end

local function CreateValueSlider(parent, labelText, minValue, maxValue, step)
    sliderCounter = sliderCounter + 1

    local sliderName = "BeavisAddonDamageTextSlider" .. sliderCounter
    local slider = CreateFrame("Slider", sliderName, parent, "OptionsSliderTemplate")
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetWidth(320)
    if slider.SetObeyStepOnDrag then
        slider:SetObeyStepOnDrag(true)
    end

    slider.Text = _G[sliderName .. "Text"]
    slider.Low = _G[sliderName .. "Low"]
    slider.High = _G[sliderName .. "High"]

    slider.Text:SetText(labelText)
    slider.Text:SetTextColor(1, 0.82, 0, 1)
    slider.Low:SetText(FormatValue(minValue))
    slider.High:SetText(FormatValue(maxValue))

    slider.ValueText = parent:CreateFontString(nil, "OVERLAY")
    slider.ValueText:SetPoint("BOTTOM", slider, "TOP", 0, 8)
    slider.ValueText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    slider.ValueText:SetTextColor(1, 1, 1, 1)

    slider:SetScript("OnValueChanged", function(self, value)
        self.ValueText:SetText(FormatValue(value))

        if isRefreshing or not self.ApplyValue then
            return
        end

        self:ApplyValue(value)
    end)

    return slider
end

-- ========================================
-- Header
-- ========================================

local IntroPanel = CreateFrame("Frame", nil, PageDamageTextContent)
IntroPanel:SetPoint("TOPLEFT", PageDamageTextContent, "TOPLEFT", 20, -20)
IntroPanel:SetPoint("TOPRIGHT", PageDamageTextContent, "TOPRIGHT", -20, -20)
IntroPanel:SetHeight(145)

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
IntroTitle:SetText("Combat Text")

local IntroText = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroText:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -10)
IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
IntroText:SetJustifyH("LEFT")
IntroText:SetJustifyV("TOP")
IntroText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroText:SetTextColor(1, 1, 1, 1)
IntroText:SetText("Hier kannst du die Blizzard-Schadenszahlen optisch anpassen. Schrift und Bewegungsverhalten werden direkt über die vorhandenen Combat-Text-Systeme umgestellt.")

local ConflictWarning = IntroPanel:CreateFontString(nil, "OVERLAY")
ConflictWarning:SetPoint("TOPLEFT", IntroText, "BOTTOMLEFT", 0, -8)
ConflictWarning:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
ConflictWarning:SetJustifyH("LEFT")
ConflictWarning:SetJustifyV("TOP")
ConflictWarning:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
ConflictWarning:SetTextColor(1, 0.22, 0.22, 1)
ConflictWarning:SetText("Konflikt: NiceDamage ist geladen und kann deinen Combat Text überschreiben. Bitte NiceDamage für diesen Charakter deaktivieren, wenn du Beavis QoL nutzen willst.")
ConflictWarning:Hide()

-- ========================================
-- Bereich: Aktivierung
-- ========================================

local EnablePanel = CreateFrame("Frame", nil, PageDamageTextContent)
EnablePanel:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -18)
EnablePanel:SetPoint("TOPRIGHT", IntroPanel, "BOTTOMRIGHT", 0, -18)
EnablePanel:SetHeight(115)

local EnableBg = EnablePanel:CreateTexture(nil, "BACKGROUND")
EnableBg:SetAllPoints()
EnableBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local EnableBorder = EnablePanel:CreateTexture(nil, "ARTWORK")
EnableBorder:SetPoint("BOTTOMLEFT", EnablePanel, "BOTTOMLEFT", 0, 0)
EnableBorder:SetPoint("BOTTOMRIGHT", EnablePanel, "BOTTOMRIGHT", 0, 0)
EnableBorder:SetHeight(1)
EnableBorder:SetColorTexture(1, 0.82, 0, 0.9)

local EnableTitle = EnablePanel:CreateFontString(nil, "OVERLAY")
EnableTitle:SetPoint("TOPLEFT", EnablePanel, "TOPLEFT", 18, -14)
EnableTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
EnableTitle:SetTextColor(1, 0.82, 0, 1)
EnableTitle:SetText("Nice Damage Style")

local EnableCheckbox = CreateFrame("CheckButton", nil, EnablePanel, "UICheckButtonTemplate")
EnableCheckbox:SetPoint("TOPLEFT", EnableTitle, "BOTTOMLEFT", -4, -12)

local EnableLabel = EnablePanel:CreateFontString(nil, "OVERLAY")
EnableLabel:SetPoint("LEFT", EnableCheckbox, "RIGHT", 6, 0)
EnableLabel:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
EnableLabel:SetTextColor(1, 1, 1, 1)
EnableLabel:SetText("Aktiv")

local EnableHint = EnablePanel:CreateFontString(nil, "OVERLAY")
EnableHint:SetPoint("TOPLEFT", EnableCheckbox, "BOTTOMLEFT", 34, -2)
EnableHint:SetPoint("RIGHT", EnablePanel, "RIGHT", -18, 0)
EnableHint:SetJustifyH("LEFT")
EnableHint:SetJustifyV("TOP")
EnableHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
EnableHint:SetTextColor(0.80, 0.80, 0.80, 1)
EnableHint:SetText("Ersetzt die Blizzard-Kampftext-Schrift und passt die Bewegung der Schadenszahlen über Scale, Gravity und Ramp Duration an.")

-- ========================================
-- Bereich: Darstellung
-- ========================================

local AppearancePanel = CreateFrame("Frame", nil, PageDamageTextContent)
AppearancePanel:SetPoint("TOPLEFT", EnablePanel, "BOTTOMLEFT", 0, -18)
AppearancePanel:SetPoint("TOPRIGHT", EnablePanel, "BOTTOMRIGHT", 0, -18)
AppearancePanel:SetHeight(350)

local AppearanceBg = AppearancePanel:CreateTexture(nil, "BACKGROUND")
AppearanceBg:SetAllPoints()
AppearanceBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local AppearanceBorder = AppearancePanel:CreateTexture(nil, "ARTWORK")
AppearanceBorder:SetPoint("BOTTOMLEFT", AppearancePanel, "BOTTOMLEFT", 0, 0)
AppearanceBorder:SetPoint("BOTTOMRIGHT", AppearancePanel, "BOTTOMRIGHT", 0, 0)
AppearanceBorder:SetHeight(1)
AppearanceBorder:SetColorTexture(1, 0.82, 0, 0.9)

local AppearanceTitle = AppearancePanel:CreateFontString(nil, "OVERLAY")
AppearanceTitle:SetPoint("TOPLEFT", AppearancePanel, "TOPLEFT", 18, -14)
AppearanceTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
AppearanceTitle:SetTextColor(1, 0.82, 0, 1)
AppearanceTitle:SetText("Darstellung")

local AppearanceHint = AppearancePanel:CreateFontString(nil, "OVERLAY")
AppearanceHint:SetPoint("TOPLEFT", AppearanceTitle, "BOTTOMLEFT", 0, -8)
AppearanceHint:SetPoint("RIGHT", AppearancePanel, "RIGHT", -18, 0)
AppearanceHint:SetJustifyH("LEFT")
AppearanceHint:SetJustifyV("TOP")
AppearanceHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
AppearanceHint:SetTextColor(0.80, 0.80, 0.80, 1)
AppearanceHint:SetText("Die mitgelieferten Fonts aus dem Font-Ordner des Addons stehen dir direkt in der Auswahl zur Verfügung, inklusive Pepsi Modern. Scale, Gravity und Ramp Duration wirken direkt.")

local RestartWarning = AppearancePanel:CreateFontString(nil, "OVERLAY")
RestartWarning:SetPoint("TOPLEFT", AppearanceHint, "BOTTOMLEFT", 0, -10)
RestartWarning:SetPoint("RIGHT", AppearancePanel, "RIGHT", -18, 0)
RestartWarning:SetJustifyH("LEFT")
RestartWarning:SetJustifyV("TOP")
RestartWarning:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
RestartWarning:SetTextColor(1, 0.22, 0.22, 1)
RestartWarning:SetText("Wichtig: Nach einem Font-Wechsel muss das Spiel komplett beendet und neu gestartet werden, damit die Änderung sicher übernommen wird.")

local RestartWarningUnderline = AppearancePanel:CreateTexture(nil, "ARTWORK")
RestartWarningUnderline:SetPoint("TOPLEFT", RestartWarning, "BOTTOMLEFT", 0, -3)
RestartWarningUnderline:SetPoint("TOPRIGHT", RestartWarning, "BOTTOMRIGHT", 0, -3)
RestartWarningUnderline:SetHeight(1)
RestartWarningUnderline:SetColorTexture(1, 0.22, 0.22, 0.95)

local FontDropdownLabel = AppearancePanel:CreateFontString(nil, "OVERLAY")
FontDropdownLabel:SetPoint("TOPLEFT", RestartWarning, "BOTTOMLEFT", 0, -22)
FontDropdownLabel:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
FontDropdownLabel:SetTextColor(1, 0.82, 0, 1)
FontDropdownLabel:SetText("Schriftart")

local FontPickerButton = CreateFrame("Button", nil, AppearancePanel, BackdropTemplateMixin and "BackdropTemplate")
FontPickerButton:SetPoint("TOPLEFT", FontDropdownLabel, "BOTTOMLEFT", 0, -8)
FontPickerButton:SetSize(260, 34)
if FontPickerButton.SetMotionScriptsWhileDisabled then
    FontPickerButton:SetMotionScriptsWhileDisabled(true)
end
FontPickerButton:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 8,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
FontPickerButton:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
FontPickerButton:SetBackdropBorderColor(0.55, 0.55, 0.55, 0.95)

local FontPickerHighlight = FontPickerButton:CreateTexture(nil, "HIGHLIGHT")
FontPickerHighlight:SetAllPoints()
FontPickerHighlight:SetColorTexture(1, 0.82, 0, 0.08)

local FontPickerArrow = FontPickerButton:CreateTexture(nil, "ARTWORK")
FontPickerArrow:SetSize(16, 16)
FontPickerArrow:SetPoint("RIGHT", FontPickerButton, "RIGHT", -10, 0)
FontPickerArrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")

local FontPickerPreviewText = FontPickerButton:CreateFontString(nil, "OVERLAY")
FontPickerPreviewText:SetPoint("LEFT", FontPickerButton, "LEFT", 12, 0)
FontPickerPreviewText:SetPoint("RIGHT", FontPickerArrow, "LEFT", -8, 0)
FontPickerPreviewText:SetJustifyH("LEFT")
FontPickerPreviewText:SetFont("Fonts\\FRIZQT__.TTF", 15, "")
if FontPickerPreviewText.SetWordWrap then
    FontPickerPreviewText:SetWordWrap(false)
end
if FontPickerPreviewText.SetMaxLines then
    FontPickerPreviewText:SetMaxLines(1)
end
FontPickerPreviewText:SetTextColor(1, 1, 1, 1)
FontPickerPreviewText:SetShadowOffset(1, -1)
FontPickerPreviewText:SetShadowColor(0, 0, 0, 1)

local FontPickerPopup = CreateFrame("Frame", nil, BeavisAddon.Frame or UIParent, BackdropTemplateMixin and "BackdropTemplate")
FontPickerPopup:SetSize(320, 260)
FontPickerPopup:SetFrameStrata("DIALOG")
FontPickerPopup:SetClampedToScreen(true)
FontPickerPopup:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 9 },
})
FontPickerPopup:Hide()

local FontPickerScrollFrame = CreateFrame("ScrollFrame", nil, FontPickerPopup, "UIPanelScrollFrameTemplate")
FontPickerScrollFrame:SetPoint("TOPLEFT", FontPickerPopup, "TOPLEFT", 14, -14)
FontPickerScrollFrame:SetPoint("BOTTOMRIGHT", FontPickerPopup, "BOTTOMRIGHT", -30, 12)

local FontPickerContent = CreateFrame("Frame", nil, FontPickerScrollFrame)
FontPickerContent:SetSize(1, 1)
FontPickerScrollFrame:SetScrollChild(FontPickerContent)

local fontPickerEntries = {}
local fontPickerBackdropColors = {
    normal = { 0.05, 0.05, 0.05, 0.01 },
    hover = { 1.00, 0.82, 0.00, 0.14 },
    selected = { 1.00, 0.82, 0.00, 0.22 },
}

local function SortFontOptions(fontOptions)
    table.sort(fontOptions, function(left, right)
        return string.lower(left.label) < string.lower(right.label)
    end)
    return fontOptions
end

local function GetSortedFontOptions()
    local fontOptions = {}

    for _, fontOption in ipairs(DamageText.GetAvailableFonts()) do
        table.insert(fontOptions, fontOption)
    end

    return SortFontOptions(fontOptions)
end

-- Manche Fonts fallen in WoW sehr unterschiedlich aus.
-- Für die Vorschau ziehen wir die Größe so weit zusammen, bis sie sauber in die Zeile passt.
local function SetPreviewText(fontString, fontKey, text, preferredSize, maxWidth, maxHeight)
    local previewPath = "Fonts\\FRIZQT__.TTF"
    if DamageText.GetPreviewFontPath then
        previewPath = DamageText.GetPreviewFontPath(fontKey)
    end

    text = text or ""

    local function FitsIntoBounds()
        local widthFits = not maxWidth or fontString:GetUnboundedStringWidth() <= maxWidth
        local heightFits = not maxHeight or fontString:GetStringHeight() <= maxHeight
        return widthFits and heightFits
    end

    local function TryFontPath(fontPath)
        for fontSize = preferredSize or 16, 10, -1 do
            if fontString:SetFont(fontPath, fontSize, "") then
                fontString:SetText(text)
                if FitsIntoBounds() then
                    return true
                end
            end
        end

        return false
    end

    if not TryFontPath(previewPath) then
        TryFontPath("Fonts\\FRIZQT__.TTF")
    end

    fontString:SetText(text)
end

local function HideFontPicker()
    FontPickerPopup:Hide()
    FontPickerArrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
end

local function UpdateFontPickerSelectionState()
    local selectedFontKey = "blizzard"
    if DamageText.GetSelectedFontKey then
        selectedFontKey = DamageText.GetSelectedFontKey()
    end

    for _, entry in ipairs(fontPickerEntries) do
        local isSelected = entry.fontKey == selectedFontKey
        entry.Check:SetShown(isSelected)

        if isSelected then
            entry.Background:SetColorTexture(unpack(fontPickerBackdropColors.selected))
        else
            entry.Background:SetColorTexture(unpack(fontPickerBackdropColors.normal))
        end
    end
end

local function RefreshFontPickerEntries()
    local sortedFonts = GetSortedFontOptions()
    local entryHeight = 30
    local lastEntry = nil
    local contentWidth = math.max(260, FontPickerPopup:GetWidth() - 54)

    FontPickerContent:SetWidth(contentWidth)

    for index, fontOption in ipairs(sortedFonts) do
        local entry = fontPickerEntries[index]
        if not entry then
            entry = CreateFrame("Button", nil, FontPickerContent)
            entry:SetHeight(entryHeight)

            local background = entry:CreateTexture(nil, "BACKGROUND")
            background:SetAllPoints()
            background:SetColorTexture(unpack(fontPickerBackdropColors.normal))
            entry.Background = background

            local check = entry:CreateTexture(nil, "OVERLAY")
            check:SetSize(14, 14)
            check:SetPoint("LEFT", entry, "LEFT", 6, 0)
            check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
            check:Hide()
            entry.Check = check

            local text = entry:CreateFontString(nil, "OVERLAY")
            text:SetPoint("LEFT", check, "RIGHT", 8, 0)
            text:SetPoint("RIGHT", entry, "RIGHT", -8, 0)
            text:SetJustifyH("LEFT")
            text:SetFont("Fonts\\FRIZQT__.TTF", 18, "")
            if text.SetWordWrap then
                text:SetWordWrap(false)
            end
            if text.SetMaxLines then
                text:SetMaxLines(1)
            end
            text:SetTextColor(1, 1, 1, 1)
            text:SetShadowOffset(1, -1)
            text:SetShadowColor(0, 0, 0, 1)
            entry.Text = text

            entry:SetScript("OnEnter", function(self)
                if self.fontKey == (DamageText.GetSelectedFontKey and DamageText.GetSelectedFontKey() or "") then
                    self.Background:SetColorTexture(unpack(fontPickerBackdropColors.selected))
                else
                    self.Background:SetColorTexture(unpack(fontPickerBackdropColors.hover))
                end
            end)

            entry:SetScript("OnLeave", function(self)
                if self.fontKey == (DamageText.GetSelectedFontKey and DamageText.GetSelectedFontKey() or "") then
                    self.Background:SetColorTexture(unpack(fontPickerBackdropColors.selected))
                else
                    self.Background:SetColorTexture(unpack(fontPickerBackdropColors.normal))
                end
            end)

            entry:SetScript("OnClick", function(self)
                if DamageText.SetSelectedFontKey then
                    DamageText.SetSelectedFontKey(self.fontKey)
                end

                HideFontPicker()
                PageDamageText:RefreshState()
            end)

            fontPickerEntries[index] = entry
        end

        entry.fontKey = fontOption.key
        entry:ClearAllPoints()
        if lastEntry then
            entry:SetPoint("TOPLEFT", lastEntry, "BOTTOMLEFT", 0, 0)
            entry:SetPoint("TOPRIGHT", FontPickerContent, "TOPRIGHT", 0, 0)
        else
            entry:SetPoint("TOPLEFT", FontPickerContent, "TOPLEFT", 0, 0)
            entry:SetPoint("TOPRIGHT", FontPickerContent, "TOPRIGHT", 0, 0)
        end

        SetPreviewText(entry.Text, fontOption.key, fontOption.label, 18, contentWidth - 40, entryHeight - 8)
        entry:Show()
        lastEntry = entry
    end

    for index = #sortedFonts + 1, #fontPickerEntries do
        fontPickerEntries[index]:Hide()
    end

    FontPickerContent:SetHeight(math.max(1, #sortedFonts * entryHeight))
    UpdateFontPickerSelectionState()
end

FontPickerButton:SetScript("OnClick", function()
    if FontPickerPopup:IsShown() then
        HideFontPicker()
        return
    end

    FontPickerPopup:ClearAllPoints()
    FontPickerPopup:SetPoint("TOPLEFT", FontPickerButton, "BOTTOMLEFT", -6, -2)
    FontPickerPopup:Show()
    RefreshFontPickerEntries()
    FontPickerScrollFrame:SetVerticalScroll(0)
    FontPickerArrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
end)

local ScaleSlider = CreateValueSlider(AppearancePanel, "World Text Scale", 0.5, 5.0, 0.1)
ScaleSlider:SetPoint("TOPLEFT", FontPickerButton, "BOTTOMLEFT", 20, -18)

local GravitySlider = CreateValueSlider(AppearancePanel, "World Text Gravity", -10.0, 10.0, 0.1)
GravitySlider:SetPoint("TOPLEFT", ScaleSlider, "BOTTOMLEFT", 0, -44)

local RampSlider = CreateValueSlider(AppearancePanel, "Ramp Duration", 0.1, 3.0, 0.1)
RampSlider:SetPoint("TOPLEFT", GravitySlider, "BOTTOMLEFT", 0, -44)

local function SetControlColors(enabled)
    local titleColor = enabled and 1 or 0.50
    local hintColor = enabled and 0.80 or 0.45

    FontDropdownLabel:SetTextColor(titleColor, enabled and 0.82 or 0.50, 0, 1)
    AppearanceHint:SetTextColor(hintColor, hintColor, hintColor, 1)
    FontPickerButton:Enable()
    FontPickerPreviewText:SetTextColor(1, 1, 1, 1)
    FontPickerButton:SetBackdropBorderColor(0.55, 0.55, 0.55, 0.95)

    if enabled then
        ScaleSlider:Enable()
        GravitySlider:Enable()
        RampSlider:Enable()
        ScaleSlider.Text:SetTextColor(1, 0.82, 0, 1)
        GravitySlider.Text:SetTextColor(1, 0.82, 0, 1)
        RampSlider.Text:SetTextColor(1, 0.82, 0, 1)
        ScaleSlider.ValueText:SetTextColor(1, 1, 1, 1)
        GravitySlider.ValueText:SetTextColor(1, 1, 1, 1)
        RampSlider.ValueText:SetTextColor(1, 1, 1, 1)
    else
        HideFontPicker()
        ScaleSlider:Disable()
        GravitySlider:Disable()
        RampSlider:Disable()
        ScaleSlider.Text:SetTextColor(0.50, 0.50, 0.50, 1)
        GravitySlider.Text:SetTextColor(0.50, 0.50, 0.50, 1)
        RampSlider.Text:SetTextColor(0.50, 0.50, 0.50, 1)
        ScaleSlider.ValueText:SetTextColor(0.50, 0.50, 0.50, 1)
        GravitySlider.ValueText:SetTextColor(0.50, 0.50, 0.50, 1)
        RampSlider.ValueText:SetTextColor(0.50, 0.50, 0.50, 1)
    end
end

function PageDamageText:RefreshState()
    local enabled = false
    local selectedFontKey = "blizzard"
    local selectedFontLabel = "Blizzard Standard"
    local worldTextScale = 1.0
    local worldTextGravity = 0.5
    local worldTextRampDuration = 1.0
    local conflictLoaded = false

    if DamageText.IsEnabled then
        enabled = DamageText.IsEnabled()
    end

    if DamageText.IsConflictingAddonLoaded then
        conflictLoaded = DamageText.IsConflictingAddonLoaded()
    end

    if DamageText.GetSelectedFontKey then
        selectedFontKey = DamageText.GetSelectedFontKey()
    end

    if DamageText.GetSelectedFontLabel then
        selectedFontLabel = DamageText.GetSelectedFontLabel()
    end

    if DamageText.GetWorldTextScale then
        worldTextScale = DamageText.GetWorldTextScale()
    end

    if DamageText.GetWorldTextGravity then
        worldTextGravity = DamageText.GetWorldTextGravity()
    end

    if DamageText.GetWorldTextRampDuration then
        worldTextRampDuration = DamageText.GetWorldTextRampDuration()
    end

    isRefreshing = true
    EnableCheckbox:SetChecked(enabled)
    SetPreviewText(FontPickerPreviewText, selectedFontKey, selectedFontLabel, 16, FontPickerButton:GetWidth() - 46, 18)
    UpdateFontPickerSelectionState()
    ScaleSlider:SetValue(worldTextScale)
    GravitySlider:SetValue(worldTextGravity)
    RampSlider:SetValue(worldTextRampDuration)
    isRefreshing = false

    if conflictLoaded then
        ConflictWarning:Show()
    else
        ConflictWarning:Hide()
    end

    SetControlColors(enabled)
end

-- Die Scroll-Höhe wird aus den sichtbaren Blöcken aufgebaut.
-- So bleibt der Abschluss unten sauber, auch wenn noch mehr Optionen dazukommen.
function PageDamageText:UpdateScrollLayout()
    local contentWidth = math.max(1, PageDamageTextScrollFrame:GetWidth())
    local contentHeight = 20
        + IntroPanel:GetHeight()
        + 18 + EnablePanel:GetHeight()
        + 18 + AppearancePanel:GetHeight()
        + 20

    PageDamageTextContent:SetWidth(contentWidth)
    PageDamageTextContent:SetHeight(contentHeight)
end

PageDamageTextScrollFrame:SetScript("OnSizeChanged", function()
    PageDamageText:UpdateScrollLayout()
end)

PageDamageTextScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local step = 40
    local currentScroll = self:GetVerticalScroll()
    local maxScroll = math.max(0, PageDamageTextContent:GetHeight() - self:GetHeight())
    local nextScroll = currentScroll - (delta * step)

    if nextScroll < 0 then
        nextScroll = 0
    elseif nextScroll > maxScroll then
        nextScroll = maxScroll
    end

    self:SetVerticalScroll(nextScroll)
end)

EnableCheckbox:SetScript("OnClick", function(self)
    if DamageText.SetEnabled then
        DamageText.SetEnabled(self:GetChecked())
    end

    PageDamageText:RefreshState()
end)

ScaleSlider.ApplyValue = function(_, value)
    if DamageText.SetWorldTextScale then
        DamageText.SetWorldTextScale(value)
    end
end

GravitySlider.ApplyValue = function(_, value)
    if DamageText.SetWorldTextGravity then
        DamageText.SetWorldTextGravity(value)
    end
end

RampSlider.ApplyValue = function(_, value)
    if DamageText.SetWorldTextRampDuration then
        DamageText.SetWorldTextRampDuration(value)
    end
end

PageDamageText:SetScript("OnShow", function()
    PageDamageText:RefreshState()
    PageDamageText:UpdateScrollLayout()
    PageDamageTextScrollFrame:SetVerticalScroll(0)
end)

PageDamageText:HookScript("OnHide", function()
    HideFontPicker()
end)

PageDamageText:UpdateScrollLayout()
PageDamageText:RefreshState()

BeavisAddon.Pages.DamageText = PageDamageText
