local ADDON_NAME, BeavisAddon = ...

local Content = BeavisAddon.Content
BeavisAddon.PetStuff = BeavisAddon.PetStuff or {}
local PetStuff = BeavisAddon.PetStuff

-- Eine kleine Seite mit genau einem Thema und einem Schalter.
local PagePetStuff = CreateFrame("Frame", nil, Content)
PagePetStuff:SetAllPoints()
PagePetStuff:Hide()

-- ========================================
-- Header
-- ========================================

local IntroPanel = CreateFrame("Frame", nil, PagePetStuff)
IntroPanel:SetPoint("TOPLEFT", PagePetStuff, "TOPLEFT", 20, -20)
IntroPanel:SetPoint("TOPRIGHT", PagePetStuff, "TOPRIGHT", -20, -20)
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
IntroTitle:SetText("Pet Stuff")

local IntroText = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroText:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -10)
IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
IntroText:SetJustifyH("LEFT")
IntroText:SetJustifyV("TOP")
IntroText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroText:SetTextColor(1, 1, 1, 1)
IntroText:SetText("Hier findest du kleine Komfortfunktionen rund um Begleiter und Pets.")

-- ========================================
-- Bereich: Auto Respawn Pet
-- ========================================

local AutoRespawnPetPanel = CreateFrame("Frame", nil, PagePetStuff)
AutoRespawnPetPanel:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -18)
AutoRespawnPetPanel:SetPoint("TOPRIGHT", IntroPanel, "BOTTOMRIGHT", 0, -18)
AutoRespawnPetPanel:SetHeight(115)

local AutoRespawnPetBg = AutoRespawnPetPanel:CreateTexture(nil, "BACKGROUND")
AutoRespawnPetBg:SetAllPoints()
AutoRespawnPetBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local AutoRespawnPetBorder = AutoRespawnPetPanel:CreateTexture(nil, "ARTWORK")
AutoRespawnPetBorder:SetPoint("BOTTOMLEFT", AutoRespawnPetPanel, "BOTTOMLEFT", 0, 0)
AutoRespawnPetBorder:SetPoint("BOTTOMRIGHT", AutoRespawnPetPanel, "BOTTOMRIGHT", 0, 0)
AutoRespawnPetBorder:SetHeight(1)
AutoRespawnPetBorder:SetColorTexture(1, 0.82, 0, 0.9)

local AutoRespawnPetTitle = AutoRespawnPetPanel:CreateFontString(nil, "OVERLAY")
AutoRespawnPetTitle:SetPoint("TOPLEFT", AutoRespawnPetPanel, "TOPLEFT", 18, -14)
AutoRespawnPetTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
AutoRespawnPetTitle:SetTextColor(1, 0.82, 0, 1)
AutoRespawnPetTitle:SetText("Auto Respawn Pet")

local AutoRespawnPetCheckbox = CreateFrame("CheckButton", nil, AutoRespawnPetPanel, "UICheckButtonTemplate")
AutoRespawnPetCheckbox:SetPoint("TOPLEFT", AutoRespawnPetTitle, "BOTTOMLEFT", -4, -12)

local AutoRespawnPetLabel = AutoRespawnPetPanel:CreateFontString(nil, "OVERLAY")
AutoRespawnPetLabel:SetPoint("LEFT", AutoRespawnPetCheckbox, "RIGHT", 6, 0)
AutoRespawnPetLabel:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
AutoRespawnPetLabel:SetTextColor(1, 1, 1, 1)
AutoRespawnPetLabel:SetText("Aktiv")

local AutoRespawnPetHint = AutoRespawnPetPanel:CreateFontString(nil, "OVERLAY")
AutoRespawnPetHint:SetPoint("TOPLEFT", AutoRespawnPetCheckbox, "BOTTOMLEFT", 34, -2)
AutoRespawnPetHint:SetPoint("RIGHT", AutoRespawnPetPanel, "RIGHT", -18, 0)
AutoRespawnPetHint:SetJustifyH("LEFT")
AutoRespawnPetHint:SetJustifyV("TOP")
AutoRespawnPetHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
AutoRespawnPetHint:SetTextColor(0.80, 0.80, 0.80, 1)
AutoRespawnPetHint:SetText("Beschwört dein zuletzt aktives Begleiter-Pet nach dem Auf- und Abmounten automatisch erneut.")

-- ========================================
-- UI-Status
-- ========================================

-- Die Seite liest ihren Zustand direkt aus dem Modul, damit UI und Logik zusammenbleiben.
function PagePetStuff:RefreshState()
    local autoRespawnPetEnabled = false

    if PetStuff.IsAutoRespawnPetEnabled then
        autoRespawnPetEnabled = PetStuff.IsAutoRespawnPetEnabled()
    end

    AutoRespawnPetCheckbox:SetChecked(autoRespawnPetEnabled)
end

-- ========================================
-- Klicklogik
-- ========================================

AutoRespawnPetCheckbox:SetScript("OnClick", function(self)
    if PetStuff.SetAutoRespawnPetEnabled then
        PetStuff.SetAutoRespawnPetEnabled(self:GetChecked())
    end

    PagePetStuff:RefreshState()
end)

PagePetStuff:SetScript("OnShow", function()
    PagePetStuff:RefreshState()
end)

PagePetStuff:RefreshState()

BeavisAddon.Pages.PetStuff = PagePetStuff
