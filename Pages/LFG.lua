local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content
BeavisQoL.LFG = BeavisQoL.LFG or {}
local LFG = BeavisQoL.LFG

-- Die LFG-Seite sammelt nur Komfortfunktionen für den Blizzard-Group-Finder.
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
IntroTitle:SetText("Gruppensuche")

local IntroText = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroText:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -10)
IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
IntroText:SetJustifyH("LEFT")
IntroText:SetJustifyV("TOP")
IntroText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroText:SetTextColor(1, 1, 1, 1)
IntroText:SetText("Hier findest du Komfortfunktionen für die Premade-Gruppensuche.")

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
FlagsTitle:SetText("Länderflaggen")

local FlagsCheckbox = CreateFrame("CheckButton", nil, FlagsPanel, "UICheckButtonTemplate")
FlagsCheckbox:SetPoint("TOPLEFT", FlagsTitle, "BOTTOMLEFT", -4, -12)

local FlagsLabel = FlagsPanel:CreateFontString(nil, "OVERLAY")
FlagsLabel:SetPoint("LEFT", FlagsCheckbox, "RIGHT", 6, 0)
FlagsLabel:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
FlagsLabel:SetTextColor(1, 1, 1, 1)
FlagsLabel:SetText("Aktiv")

local FlagsHint = FlagsPanel:CreateFontString(nil, "OVERLAY")
FlagsHint:SetPoint("TOPLEFT", FlagsCheckbox, "BOTTOMLEFT", 34, -2)
FlagsHint:SetPoint("RIGHT", FlagsPanel, "RIGHT", -18, 0)
FlagsHint:SetJustifyH("LEFT")
FlagsHint:SetJustifyV("TOP")
FlagsHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
FlagsHint:SetTextColor(0.80, 0.80, 0.80, 1)
FlagsHint:SetText("Zeigt in der Premade-Gruppensuche neben Bewerbern eine kleine Flagge auf Basis ihres Realms an.")

-- Die Checkbox liest ihren Zustand direkt aus dem Modul, damit die Seite kaum eigene Logik braucht.
function PageLFG:RefreshState()
    local flagsEnabled = false

    if LFG.IsFlagsEnabled then
        flagsEnabled = LFG.IsFlagsEnabled()
    end

    FlagsCheckbox:SetChecked(flagsEnabled)
end

FlagsCheckbox:SetScript("OnClick", function(self)
    if LFG.SetFlagsEnabled then
        LFG.SetFlagsEnabled(self:GetChecked())
    end

    PageLFG:RefreshState()
end)

PageLFG:SetScript("OnShow", function()
    PageLFG:RefreshState()
end)

PageLFG:RefreshState()

BeavisQoL.Pages.LFG = PageLFG
