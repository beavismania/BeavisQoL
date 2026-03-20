local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content

-- Platzhalter, bis hier echte globale Einstellungen landen.
local PageSettings = CreateFrame("Frame", nil, Content)
PageSettings:SetAllPoints()
PageSettings:Hide()

local PageSettingsText = PageSettings:CreateFontString(nil, "OVERLAY")
PageSettingsText:SetPoint("TOPLEFT", PageSettings, "TOPLEFT", 20, -20)
PageSettingsText:SetFont("Fonts\\FRIZQT__.TTF", 20, "")
PageSettingsText:SetTextColor(1, 0.82, 0, 1)
PageSettingsText:SetText("Das sind die Einstellungen")

BeavisQoL.Pages.Settings = PageSettings
