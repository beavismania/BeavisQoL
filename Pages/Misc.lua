local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content
BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc
-- Diese Datei ist bewusst nur die UI-Huelle der Misc-Seite.
-- Die eigentliche Logik der einzelnen Features lebt in den Dateien unter
-- Pages/Misc/*.lua, damit Anzeige und Verhalten sauber getrennt bleiben.

-- Die Misc-Seite ist lang genug für einen eigenen ScrollFrame.
-- So können neue QoL-Module dazukommen, ohne dass unten etwas abgeschnitten wirkt.
local PageMisc = CreateFrame("Frame", nil, Content)
PageMisc:SetAllPoints()
PageMisc:Hide()

local PageMiscScrollFrame = CreateFrame("ScrollFrame", nil, PageMisc, "UIPanelScrollFrameTemplate")
PageMiscScrollFrame:SetPoint("TOPLEFT", PageMisc, "TOPLEFT", 0, 0)
PageMiscScrollFrame:SetPoint("BOTTOMRIGHT", PageMisc, "BOTTOMRIGHT", -28, 0)
PageMiscScrollFrame:EnableMouseWheel(true)

local PageMiscContent = CreateFrame("Frame", nil, PageMiscScrollFrame)
PageMiscContent:SetSize(1, 1)
PageMiscScrollFrame:SetScrollChild(PageMiscContent)

-- ========================================
-- Header
-- ========================================

local IntroPanel = CreateFrame("Frame", nil, PageMiscContent)
IntroPanel:SetPoint("TOPLEFT", PageMiscContent, "TOPLEFT", 20, -20)
IntroPanel:SetPoint("TOPRIGHT", PageMiscContent, "TOPRIGHT", -20, -20)
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
IntroTitle:SetText("Misc")

local IntroText = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroText:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -10)
IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
IntroText:SetJustifyH("LEFT")
IntroText:SetJustifyV("TOP")
IntroText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroText:SetTextColor(1, 1, 1, 1)
IntroText:SetText("Hier findest du kleinere Quality-of-Life-Funktionen, die unabhängig vom Rest des Addons genutzt werden können.")

-- ========================================
-- Bereich: Auto Sell Junk
-- ========================================

local AutoSellPanel = CreateFrame("Frame", nil, PageMiscContent)
AutoSellPanel:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -18)
AutoSellPanel:SetPoint("TOPRIGHT", IntroPanel, "BOTTOMRIGHT", 0, -18)
AutoSellPanel:SetHeight(115)

local AutoSellBg = AutoSellPanel:CreateTexture(nil, "BACKGROUND")
AutoSellBg:SetAllPoints()
AutoSellBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local AutoSellBorder = AutoSellPanel:CreateTexture(nil, "ARTWORK")
AutoSellBorder:SetPoint("BOTTOMLEFT", AutoSellPanel, "BOTTOMLEFT", 0, 0)
AutoSellBorder:SetPoint("BOTTOMRIGHT", AutoSellPanel, "BOTTOMRIGHT", 0, 0)
AutoSellBorder:SetHeight(1)
AutoSellBorder:SetColorTexture(1, 0.82, 0, 0.9)

local AutoSellTitle = AutoSellPanel:CreateFontString(nil, "OVERLAY")
AutoSellTitle:SetPoint("TOPLEFT", AutoSellPanel, "TOPLEFT", 18, -14)
AutoSellTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
AutoSellTitle:SetTextColor(1, 0.82, 0, 1)
AutoSellTitle:SetText("Auto Sell Junk")

local AutoSellCheckbox = CreateFrame("CheckButton", nil, AutoSellPanel, "UICheckButtonTemplate")
AutoSellCheckbox:SetPoint("TOPLEFT", AutoSellTitle, "BOTTOMLEFT", -4, -12)

local AutoSellLabel = AutoSellPanel:CreateFontString(nil, "OVERLAY")
AutoSellLabel:SetPoint("LEFT", AutoSellCheckbox, "RIGHT", 6, 0)
AutoSellLabel:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
AutoSellLabel:SetTextColor(1, 1, 1, 1)
AutoSellLabel:SetText("Aktiv")

local AutoSellHint = AutoSellPanel:CreateFontString(nil, "OVERLAY")
AutoSellHint:SetPoint("TOPLEFT", AutoSellCheckbox, "BOTTOMLEFT", 34, -2)
AutoSellHint:SetPoint("RIGHT", AutoSellPanel, "RIGHT", -18, 0)
AutoSellHint:SetJustifyH("LEFT")
AutoSellHint:SetJustifyV("TOP")
AutoSellHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
AutoSellHint:SetTextColor(0.80, 0.80, 0.80, 1)
AutoSellHint:SetText("Verkauft beim Öffnen eines Händlers automatisch alle grauen Gegenstände mit Händlerwert.")

-- ========================================
-- Bereich: Auto Repair
-- ========================================

local AutoRepairPanel = CreateFrame("Frame", nil, PageMiscContent)
AutoRepairPanel:SetPoint("TOPLEFT", AutoSellPanel, "BOTTOMLEFT", 0, -18)
AutoRepairPanel:SetPoint("TOPRIGHT", AutoSellPanel, "BOTTOMRIGHT", 0, -18)
AutoRepairPanel:SetHeight(180)

local AutoRepairBg = AutoRepairPanel:CreateTexture(nil, "BACKGROUND")
AutoRepairBg:SetAllPoints()
AutoRepairBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local AutoRepairBorder = AutoRepairPanel:CreateTexture(nil, "ARTWORK")
AutoRepairBorder:SetPoint("BOTTOMLEFT", AutoRepairPanel, "BOTTOMLEFT", 0, 0)
AutoRepairBorder:SetPoint("BOTTOMRIGHT", AutoRepairPanel, "BOTTOMRIGHT", 0, 0)
AutoRepairBorder:SetHeight(1)
AutoRepairBorder:SetColorTexture(1, 0.82, 0, 0.9)

local AutoRepairTitle = AutoRepairPanel:CreateFontString(nil, "OVERLAY")
AutoRepairTitle:SetPoint("TOPLEFT", AutoRepairPanel, "TOPLEFT", 18, -14)
AutoRepairTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
AutoRepairTitle:SetTextColor(1, 0.82, 0, 1)
AutoRepairTitle:SetText("Auto Repair")

local AutoRepairCheckbox = CreateFrame("CheckButton", nil, AutoRepairPanel, "UICheckButtonTemplate")
AutoRepairCheckbox:SetPoint("TOPLEFT", AutoRepairTitle, "BOTTOMLEFT", -4, -12)

local AutoRepairLabel = AutoRepairPanel:CreateFontString(nil, "OVERLAY")
AutoRepairLabel:SetPoint("LEFT", AutoRepairCheckbox, "RIGHT", 6, 0)
AutoRepairLabel:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
AutoRepairLabel:SetTextColor(1, 1, 1, 1)
AutoRepairLabel:SetText("Aktiv")

local AutoRepairHint = AutoRepairPanel:CreateFontString(nil, "OVERLAY")
AutoRepairHint:SetPoint("TOPLEFT", AutoRepairCheckbox, "BOTTOMLEFT", 34, -2)
AutoRepairHint:SetPoint("RIGHT", AutoRepairPanel, "RIGHT", -18, 0)
AutoRepairHint:SetJustifyH("LEFT")
AutoRepairHint:SetJustifyV("TOP")
AutoRepairHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
AutoRepairHint:SetTextColor(0.80, 0.80, 0.80, 1)
AutoRepairHint:SetText("Repariert beim Öffnen eines Händlers automatisch beschädigte Gegenstände.")

local AutoRepairGuildCheckbox = CreateFrame("CheckButton", nil, AutoRepairPanel, "UICheckButtonTemplate")
AutoRepairGuildCheckbox:SetPoint("TOPLEFT", AutoRepairHint, "BOTTOMLEFT", -14, -18)
AutoRepairGuildCheckbox:SetScale(0.85)

local AutoRepairGuildLabel = AutoRepairPanel:CreateFontString(nil, "OVERLAY")
AutoRepairGuildLabel:SetPoint("LEFT", AutoRepairGuildCheckbox, "RIGHT", 4, 0)
AutoRepairGuildLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
AutoRepairGuildLabel:SetTextColor(1, 1, 1, 1)
AutoRepairGuildLabel:SetText("Per Gilde vorrangig")

local AutoRepairGuildHint = AutoRepairPanel:CreateFontString(nil, "OVERLAY")
AutoRepairGuildHint:SetPoint("TOPLEFT", AutoRepairGuildCheckbox, "BOTTOMLEFT", 30, -4)
AutoRepairGuildHint:SetPoint("RIGHT", AutoRepairPanel, "RIGHT", -18, 0)
AutoRepairGuildHint:SetJustifyH("LEFT")
AutoRepairGuildHint:SetJustifyV("TOP")
AutoRepairGuildHint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
AutoRepairGuildHint:SetTextColor(0.80, 0.80, 0.80, 1)
AutoRepairGuildHint:SetText("Wenn möglich, wird zuerst Gildengold für die Reparatur verwendet.")

-- ========================================
-- Bereich: Easy Delete
-- ========================================

local EasyDeletePanel = CreateFrame("Frame", nil, PageMiscContent)
EasyDeletePanel:SetPoint("TOPLEFT", AutoRepairPanel, "BOTTOMLEFT", 0, -18)
EasyDeletePanel:SetPoint("TOPRIGHT", AutoRepairPanel, "BOTTOMRIGHT", 0, -18)
EasyDeletePanel:SetHeight(115)

local EasyDeleteBg = EasyDeletePanel:CreateTexture(nil, "BACKGROUND")
EasyDeleteBg:SetAllPoints()
EasyDeleteBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local EasyDeleteBorder = EasyDeletePanel:CreateTexture(nil, "ARTWORK")
EasyDeleteBorder:SetPoint("BOTTOMLEFT", EasyDeletePanel, "BOTTOMLEFT", 0, 0)
EasyDeleteBorder:SetPoint("BOTTOMRIGHT", EasyDeletePanel, "BOTTOMRIGHT", 0, 0)
EasyDeleteBorder:SetHeight(1)
EasyDeleteBorder:SetColorTexture(1, 0.82, 0, 0.9)

local EasyDeleteTitle = EasyDeletePanel:CreateFontString(nil, "OVERLAY")
EasyDeleteTitle:SetPoint("TOPLEFT", EasyDeletePanel, "TOPLEFT", 18, -14)
EasyDeleteTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
EasyDeleteTitle:SetTextColor(1, 0.82, 0, 1)
EasyDeleteTitle:SetText("Easy Delete")

local EasyDeleteCheckbox = CreateFrame("CheckButton", nil, EasyDeletePanel, "UICheckButtonTemplate")
EasyDeleteCheckbox:SetPoint("TOPLEFT", EasyDeleteTitle, "BOTTOMLEFT", -4, -12)

local EasyDeleteLabel = EasyDeletePanel:CreateFontString(nil, "OVERLAY")
EasyDeleteLabel:SetPoint("LEFT", EasyDeleteCheckbox, "RIGHT", 6, 0)
EasyDeleteLabel:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
EasyDeleteLabel:SetTextColor(1, 1, 1, 1)
EasyDeleteLabel:SetText("Aktiv")

local EasyDeleteHint = EasyDeletePanel:CreateFontString(nil, "OVERLAY")
EasyDeleteHint:SetPoint("TOPLEFT", EasyDeleteCheckbox, "BOTTOMLEFT", 34, -2)
EasyDeleteHint:SetPoint("RIGHT", EasyDeletePanel, "RIGHT", -18, 0)
EasyDeleteHint:SetJustifyH("LEFT")
EasyDeleteHint:SetJustifyV("TOP")
EasyDeleteHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
EasyDeleteHint:SetTextColor(0.80, 0.80, 0.80, 1)
EasyDeleteHint:SetText("Entfernt bei Items mit LÖSCHEN-Abfrage die Texteingabe und ersetzt sie durch eine einfache Bestätigung.")

-- ========================================
-- Bereich: Fast Loot
-- ========================================

local FastLootPanel = CreateFrame("Frame", nil, PageMiscContent)
FastLootPanel:SetPoint("TOPLEFT", EasyDeletePanel, "BOTTOMLEFT", 0, -18)
FastLootPanel:SetPoint("TOPRIGHT", EasyDeletePanel, "BOTTOMRIGHT", 0, -18)
FastLootPanel:SetHeight(115)

local FastLootBg = FastLootPanel:CreateTexture(nil, "BACKGROUND")
FastLootBg:SetAllPoints()
FastLootBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local FastLootBorder = FastLootPanel:CreateTexture(nil, "ARTWORK")
FastLootBorder:SetPoint("BOTTOMLEFT", FastLootPanel, "BOTTOMLEFT", 0, 0)
FastLootBorder:SetPoint("BOTTOMRIGHT", FastLootPanel, "BOTTOMRIGHT", 0, 0)
FastLootBorder:SetHeight(1)
FastLootBorder:SetColorTexture(1, 0.82, 0, 0.9)

local FastLootTitle = FastLootPanel:CreateFontString(nil, "OVERLAY")
FastLootTitle:SetPoint("TOPLEFT", FastLootPanel, "TOPLEFT", 18, -14)
FastLootTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
FastLootTitle:SetTextColor(1, 0.82, 0, 1)
FastLootTitle:SetText("Fast Loot")

local FastLootCheckbox = CreateFrame("CheckButton", nil, FastLootPanel, "UICheckButtonTemplate")
FastLootCheckbox:SetPoint("TOPLEFT", FastLootTitle, "BOTTOMLEFT", -4, -12)

local FastLootLabel = FastLootPanel:CreateFontString(nil, "OVERLAY")
FastLootLabel:SetPoint("LEFT", FastLootCheckbox, "RIGHT", 6, 0)
FastLootLabel:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
FastLootLabel:SetTextColor(1, 1, 1, 1)
FastLootLabel:SetText("Aktiv")

local FastLootHint = FastLootPanel:CreateFontString(nil, "OVERLAY")
FastLootHint:SetPoint("TOPLEFT", FastLootCheckbox, "BOTTOMLEFT", 34, -2)
FastLootHint:SetPoint("RIGHT", FastLootPanel, "RIGHT", -18, 0)
FastLootHint:SetJustifyH("LEFT")
FastLootHint:SetJustifyV("TOP")
FastLootHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
FastLootHint:SetTextColor(0.80, 0.80, 0.80, 1)
FastLootHint:SetText("Lootet Beute direkt beim Öffnen und blendet das Lootfenster dabei aus.")

-- ========================================
-- UI-Status
-- ========================================

-- Die Checkboxen lesen ihren Zustand direkt aus den Modulen.
function PageMisc:RefreshState()
    local autoSellEnabled = false
    local autoRepairEnabled = false
    local autoRepairGuildEnabled = false
    local easyDeleteEnabled = false
    local fastLootEnabled = false

    if Misc.IsAutoSellJunkEnabled then
        autoSellEnabled = Misc.IsAutoSellJunkEnabled()
    end

    if Misc.IsAutoRepairEnabled then
        autoRepairEnabled = Misc.IsAutoRepairEnabled()
    end

    if Misc.IsAutoRepairGuildEnabled then
        autoRepairGuildEnabled = Misc.IsAutoRepairGuildEnabled()
    end

    if Misc.IsEasyDeleteEnabled then
        easyDeleteEnabled = Misc.IsEasyDeleteEnabled()
    end

    if Misc.IsFastLootEnabled then
        fastLootEnabled = Misc.IsFastLootEnabled()
    end
    -- Die Seite fragt die Modul-Funktionen bewusst nur optional ab.
    -- So bleibt die UI robust, selbst wenn ein Teilmodul spaeter einmal
    -- umgebaut oder voruebergehend nicht geladen sein sollte.

    AutoSellCheckbox:SetChecked(autoSellEnabled)
    AutoRepairCheckbox:SetChecked(autoRepairEnabled)
    AutoRepairGuildCheckbox:SetChecked(autoRepairGuildEnabled)
    EasyDeleteCheckbox:SetChecked(easyDeleteEnabled)
    FastLootCheckbox:SetChecked(fastLootEnabled)

    -- Die Gilden-Option ergibt nur Sinn, wenn Auto Repair aktiv ist.
    AutoRepairGuildCheckbox:SetEnabled(autoRepairEnabled)

    if autoRepairEnabled then
        AutoRepairGuildLabel:SetTextColor(1, 1, 1, 1)
        AutoRepairGuildHint:SetTextColor(0.80, 0.80, 0.80, 1)
    else
        AutoRepairGuildLabel:SetTextColor(0.50, 0.50, 0.50, 1)
        AutoRepairGuildHint:SetTextColor(0.45, 0.45, 0.45, 1)
        AutoRepairGuildCheckbox:SetChecked(false)
    end
end

-- Die Höhe setzen wir aus den sichtbaren Blöcken zusammen.
function PageMisc:UpdateScrollLayout()
    -- Statt den Inhalt an feste Pixelpositionen zu ketten, berechnen wir die
    -- Gesamtgroesse aus allen Panels. Das ist fuer spaetere Erweiterungen
    -- deutlich wartbarer als viele verstreute Einzel-Offsets.
    local contentWidth = math.max(1, PageMiscScrollFrame:GetWidth())
    local contentHeight = 20
        + IntroPanel:GetHeight()
        + 18 + AutoSellPanel:GetHeight()
        + 18 + AutoRepairPanel:GetHeight()
        + 18 + EasyDeletePanel:GetHeight()
        + 18 + FastLootPanel:GetHeight()
        + 20

    PageMiscContent:SetWidth(contentWidth)
    PageMiscContent:SetHeight(contentHeight)
end

PageMiscScrollFrame:SetScript("OnSizeChanged", function()
    PageMisc:UpdateScrollLayout()
end)

-- Mit dem Mausrad fühlt sich die Seite etwas angenehmer an.
PageMiscScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local step = 40
    local currentScroll = self:GetVerticalScroll()
    local maxScroll = math.max(0, PageMiscContent:GetHeight() - self:GetHeight())
    local nextScroll = currentScroll - (delta * step)

    if nextScroll < 0 then
        nextScroll = 0
    elseif nextScroll > maxScroll then
        nextScroll = maxScroll
    end

    self:SetVerticalScroll(nextScroll)
end)

-- ========================================
-- Klicklogik
-- ========================================

-- Jede Checkbox gibt die Änderung direkt an ihr Modul weiter.
AutoSellCheckbox:SetScript("OnClick", function(self)
    if Misc.SetAutoSellJunkEnabled then
        Misc.SetAutoSellJunkEnabled(self:GetChecked())
    end

    PageMisc:RefreshState()
end)

AutoRepairCheckbox:SetScript("OnClick", function(self)
    if Misc.SetAutoRepairEnabled then
        Misc.SetAutoRepairEnabled(self:GetChecked())
    end

    PageMisc:RefreshState()
end)

AutoRepairGuildCheckbox:SetScript("OnClick", function(self)
    if Misc.SetAutoRepairGuildEnabled then
        Misc.SetAutoRepairGuildEnabled(self:GetChecked())
    end

    PageMisc:RefreshState()
end)

EasyDeleteCheckbox:SetScript("OnClick", function(self)
    if Misc.SetEasyDeleteEnabled then
        Misc.SetEasyDeleteEnabled(self:GetChecked())
    end

    PageMisc:RefreshState()
end)

FastLootCheckbox:SetScript("OnClick", function(self)
    if Misc.SetFastLootEnabled then
        Misc.SetFastLootEnabled(self:GetChecked())
    end

    PageMisc:RefreshState()
end)

PageMisc:SetScript("OnShow", function()
    -- Beim Öffnen springen wir wieder nach oben, damit die Seite immer gleich startet.
    PageMisc:RefreshState()
    PageMisc:UpdateScrollLayout()
    PageMiscScrollFrame:SetVerticalScroll(0)
end)

PageMisc:UpdateScrollLayout()
PageMisc:RefreshState()

BeavisQoL.Pages.Misc = PageMisc
