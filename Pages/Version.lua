local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content

-- Die Versionsseite zeigt nur TOC-Infos und Kontaktmöglichkeiten.
-- Sie bleibt absichtlich statisch, damit man hier nichts verstellen kann.
local PageVersion = CreateFrame("Frame", nil, Content)
PageVersion:SetAllPoints()
PageVersion:Hide()

-- ========================================
-- TOC-Daten holen
-- ========================================

local addonTitle = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title") or ADDON_NAME
local addonVersion = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "Unbekannt"
local addonAuthor = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Author") or "Unbekannt"

-- Die Interface-Version liest Blizzard hier nicht immer sauber aus.
-- Darum ziehen wir sie über eigene X-Felder aus der TOC.
local addonGameVersion = C_AddOns.GetAddOnMetadata(ADDON_NAME, "X-GameVersion") or "Nicht hinterlegt"
local addonGameVersionLabel = C_AddOns.GetAddOnMetadata(ADDON_NAME, "X-GameVersionLabel") or "Nicht hinterlegt"

local WEBSITE_URL = "https://www.beavismania.de"

-- ========================================
-- Popup für Link / Copy
-- ========================================

-- Addons dürfen keine Browser-Links öffnen. Deshalb zeigen wir die URL nur in einem Copy-Popup an.
local WebsitePopup = CreateFrame("Frame", nil, PageVersion)
WebsitePopup:SetSize(520, 170)
WebsitePopup:SetPoint("CENTER", PageVersion, "CENTER", 0, 0)
WebsitePopup:SetFrameStrata("DIALOG")
WebsitePopup:EnableMouse(true)
WebsitePopup:Hide()

local WebsitePopupBg = WebsitePopup:CreateTexture(nil, "BACKGROUND")
WebsitePopupBg:SetAllPoints()
WebsitePopupBg:SetColorTexture(0.06, 0.06, 0.06, 0.96)

local WebsitePopupBorderTop = WebsitePopup:CreateTexture(nil, "ARTWORK")
WebsitePopupBorderTop:SetPoint("TOPLEFT", WebsitePopup, "TOPLEFT", 0, 0)
WebsitePopupBorderTop:SetPoint("TOPRIGHT", WebsitePopup, "TOPRIGHT", 0, 0)
WebsitePopupBorderTop:SetHeight(1)
WebsitePopupBorderTop:SetColorTexture(1, 0.82, 0, 0.9)

local WebsitePopupBorderBottom = WebsitePopup:CreateTexture(nil, "ARTWORK")
WebsitePopupBorderBottom:SetPoint("BOTTOMLEFT", WebsitePopup, "BOTTOMLEFT", 0, 0)
WebsitePopupBorderBottom:SetPoint("BOTTOMRIGHT", WebsitePopup, "BOTTOMRIGHT", 0, 0)
WebsitePopupBorderBottom:SetHeight(1)
WebsitePopupBorderBottom:SetColorTexture(1, 0.82, 0, 0.9)

local WebsitePopupTitle = WebsitePopup:CreateFontString(nil, "OVERLAY")
WebsitePopupTitle:SetPoint("TOPLEFT", WebsitePopup, "TOPLEFT", 16, -14)
WebsitePopupTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
WebsitePopupTitle:SetTextColor(1, 0.82, 0, 1)
WebsitePopupTitle:SetText("Beavismania öffnen")

local WebsitePopupText = WebsitePopup:CreateFontString(nil, "OVERLAY")
WebsitePopupText:SetPoint("TOPLEFT", WebsitePopupTitle, "BOTTOMLEFT", 0, -10)
WebsitePopupText:SetPoint("RIGHT", WebsitePopup, "RIGHT", -16, 0)
WebsitePopupText:SetJustifyH("LEFT")
WebsitePopupText:SetJustifyV("TOP")
WebsitePopupText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
WebsitePopupText:SetTextColor(1, 1, 1, 1)
WebsitePopupText:SetText("World of Warcraft erlaubt Addons nicht, Webseiten direkt zu öffnen. Du kannst die Adresse hier markieren und kopieren:")

local WebsiteEditBox = CreateFrame("EditBox", nil, WebsitePopup, "InputBoxTemplate")
WebsiteEditBox:SetSize(470, 30)
WebsiteEditBox:SetPoint("TOPLEFT", WebsitePopupText, "BOTTOMLEFT", 0, -14)
WebsiteEditBox:SetAutoFocus(false)
WebsiteEditBox:SetFontObject(ChatFontNormal)
WebsiteEditBox:SetText(WEBSITE_URL)
WebsiteEditBox:SetCursorPosition(0)
WebsiteEditBox:HighlightText()

WebsiteEditBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
    WebsitePopup:Hide()
end)

WebsiteEditBox:SetScript("OnEditFocusGained", function(self)
    self:HighlightText()
end)

local WebsitePopupHint = WebsitePopup:CreateFontString(nil, "OVERLAY")
WebsitePopupHint:SetPoint("TOPLEFT", WebsiteEditBox, "BOTTOMLEFT", 4, -10)
WebsitePopupHint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
WebsitePopupHint:SetTextColor(0.75, 0.75, 0.75, 1)
WebsitePopupHint:SetText("Tipp: Link markieren und mit Strg+C kopieren.")

local WebsiteCloseButton = CreateFrame("Button", nil, WebsitePopup, "UIPanelButtonTemplate")
WebsiteCloseButton:SetSize(110, 26)
WebsiteCloseButton:SetPoint("BOTTOMRIGHT", WebsitePopup, "BOTTOMRIGHT", -16, 12)
WebsiteCloseButton:SetText("Schließen")
WebsiteCloseButton:SetScript("OnClick", function()
    WebsitePopup:Hide()
end)

-- Kleiner Helfer, damit beide Buttons dasselbe Popup mit passendem Titel nutzen.
local function ShowWebsitePopup(titleText)
    WebsitePopupTitle:SetText(titleText or "Beavismania öffnen")
    WebsiteEditBox:SetText(WEBSITE_URL)
    WebsitePopup:Show()
    WebsiteEditBox:SetFocus()
    WebsiteEditBox:HighlightText()
end

local ShowWebsitePopupFallback = ShowWebsitePopup
ShowWebsitePopup = function(titleText)
    -- Wenn die zentrale Popup-Hilfe da ist, nutzen wir dieselbe Logik wie auf Home.
    if BeavisQoL.ShowLinkPopup then
        BeavisQoL.ShowLinkPopup(titleText or "Beavismania öffnen", WEBSITE_URL)
    else
        ShowWebsitePopupFallback(titleText)
    end
end

-- ========================================
-- Header / Intro
-- ========================================

local IntroPanel = CreateFrame("Frame", nil, PageVersion)
IntroPanel:SetPoint("TOPLEFT", PageVersion, "TOPLEFT", 20, -20)
IntroPanel:SetPoint("TOPRIGHT", PageVersion, "TOPRIGHT", -20, -20)
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
IntroTitle:SetText(addonTitle .. " – Versionsinfos")

local IntroText = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroText:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -10)
IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
IntroText:SetJustifyH("LEFT")
IntroText:SetJustifyV("TOP")
IntroText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroText:SetTextColor(1, 1, 1, 1)
IntroText:SetText("Hier findest du die wichtigsten Infos zur aktuellen Addon-Version sowie direkte Wege für Feedback und neue Ideen.")

-- ========================================
-- Info-Karten
-- ========================================

-- Drei Karten reichen hier für die wichtigsten Metadaten.
local InfoRow = CreateFrame("Frame", nil, PageVersion)
InfoRow:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -18)
InfoRow:SetPoint("TOPRIGHT", IntroPanel, "BOTTOMRIGHT", 0, -18)
InfoRow:SetHeight(90)

local VersionCard = CreateFrame("Frame", nil, InfoRow)
VersionCard:SetPoint("TOPLEFT", InfoRow, "TOPLEFT", 0, 0)
VersionCard:SetSize(220, 90)

local VersionCardBg = VersionCard:CreateTexture(nil, "BACKGROUND")
VersionCardBg:SetAllPoints()
VersionCardBg:SetColorTexture(0.10, 0.10, 0.10, 0.95)

local VersionLabel = VersionCard:CreateFontString(nil, "OVERLAY")
VersionLabel:SetPoint("TOPLEFT", VersionCard, "TOPLEFT", 12, -10)
VersionLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
VersionLabel:SetTextColor(0.85, 0.85, 0.85, 1)
VersionLabel:SetText("Aktuelle Version")

local VersionValue = VersionCard:CreateFontString(nil, "OVERLAY")
VersionValue:SetPoint("TOPLEFT", VersionLabel, "BOTTOMLEFT", 0, -8)
VersionValue:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
VersionValue:SetTextColor(1, 0.82, 0, 1)
VersionValue:SetText(addonVersion)

local AuthorCard = CreateFrame("Frame", nil, InfoRow)
AuthorCard:SetPoint("LEFT", VersionCard, "RIGHT", 14, 0)
AuthorCard:SetSize(220, 90)

local AuthorCardBg = AuthorCard:CreateTexture(nil, "BACKGROUND")
AuthorCardBg:SetAllPoints()
AuthorCardBg:SetColorTexture(0.10, 0.10, 0.10, 0.95)

local AuthorLabel = AuthorCard:CreateFontString(nil, "OVERLAY")
AuthorLabel:SetPoint("TOPLEFT", AuthorCard, "TOPLEFT", 12, -10)
AuthorLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
AuthorLabel:SetTextColor(0.85, 0.85, 0.85, 1)
AuthorLabel:SetText("Programmierer")

local AuthorValue = AuthorCard:CreateFontString(nil, "OVERLAY")
AuthorValue:SetPoint("TOPLEFT", AuthorLabel, "BOTTOMLEFT", 0, -8)
AuthorValue:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
AuthorValue:SetTextColor(1, 0.82, 0, 1)
AuthorValue:SetText(addonAuthor)

local InterfaceCard = CreateFrame("Frame", nil, InfoRow)
InterfaceCard:SetPoint("LEFT", AuthorCard, "RIGHT", 14, 0)
InterfaceCard:SetPoint("RIGHT", InfoRow, "RIGHT", 0, 0)
InterfaceCard:SetHeight(90)

local InterfaceCardBg = InterfaceCard:CreateTexture(nil, "BACKGROUND")
InterfaceCardBg:SetAllPoints()
InterfaceCardBg:SetColorTexture(0.10, 0.10, 0.10, 0.95)

local InterfaceLabel = InterfaceCard:CreateFontString(nil, "OVERLAY")
InterfaceLabel:SetPoint("TOPLEFT", InterfaceCard, "TOPLEFT", 12, -10)
InterfaceLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
InterfaceLabel:SetTextColor(0.85, 0.85, 0.85, 1)
InterfaceLabel:SetText("Unterstützte Spielversion")

local InterfaceValue = InterfaceCard:CreateFontString(nil, "OVERLAY")
InterfaceValue:SetPoint("TOPLEFT", InterfaceLabel, "BOTTOMLEFT", 0, -8)
InterfaceValue:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
InterfaceValue:SetTextColor(1, 0.82, 0, 1)
InterfaceValue:SetText(addonGameVersionLabel)

local InterfaceSubValue = InterfaceCard:CreateFontString(nil, "OVERLAY")
InterfaceSubValue:SetPoint("TOPLEFT", InterfaceValue, "BOTTOMLEFT", 0, -4)
InterfaceSubValue:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
InterfaceSubValue:SetTextColor(0.75, 0.75, 0.75, 1)
InterfaceSubValue:SetText("TOC Version: " .. tostring(addonGameVersion))

-- ========================================
-- Aktionsbereich
-- ========================================

-- Der Bereich bleibt bewusst schlicht. Hier soll man einfach schnell zu Feedback und Ideen kommen.
local ActionPanel = CreateFrame("Frame", nil, PageVersion)
ActionPanel:SetPoint("TOPLEFT", InfoRow, "BOTTOMLEFT", 0, -18)
ActionPanel:SetPoint("TOPRIGHT", InfoRow, "BOTTOMRIGHT", 0, -18)
ActionPanel:SetHeight(160)

local ActionBg = ActionPanel:CreateTexture(nil, "BACKGROUND")
ActionBg:SetAllPoints()
ActionBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local ActionBorder = ActionPanel:CreateTexture(nil, "ARTWORK")
ActionBorder:SetPoint("BOTTOMLEFT", ActionPanel, "BOTTOMLEFT", 0, 0)
ActionBorder:SetPoint("BOTTOMRIGHT", ActionPanel, "BOTTOMRIGHT", 0, 0)
ActionBorder:SetHeight(1)
ActionBorder:SetColorTexture(1, 0.82, 0, 0.9)

local ActionTitle = ActionPanel:CreateFontString(nil, "OVERLAY")
ActionTitle:SetPoint("TOPLEFT", ActionPanel, "TOPLEFT", 18, -14)
ActionTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
ActionTitle:SetTextColor(1, 0.82, 0, 1)
ActionTitle:SetText("Mithelfen & Kontakt")

local ActionText = ActionPanel:CreateFontString(nil, "OVERLAY")
ActionText:SetPoint("TOPLEFT", ActionTitle, "BOTTOMLEFT", 0, -10)
ActionText:SetPoint("RIGHT", ActionPanel, "RIGHT", -18, 0)
ActionText:SetJustifyH("LEFT")
ActionText:SetJustifyV("TOP")
ActionText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
ActionText:SetTextColor(1, 1, 1, 1)
ActionText:SetText("Wenn du Feedback geben oder neue Ideen einreichen möchtest, kannst du direkt über die Beavismania-Webseite Kontakt aufnehmen.")

local FeedbackButton = CreateFrame("Button", nil, ActionPanel, "UIPanelButtonTemplate")
FeedbackButton:SetSize(180, 30)
FeedbackButton:SetPoint("BOTTOMLEFT", ActionPanel, "BOTTOMLEFT", 18, 18)
FeedbackButton:SetText("Feedback senden")
FeedbackButton:SetScript("OnClick", function()
    ShowWebsitePopup("Feedback senden")
end)

local IdeaButton = CreateFrame("Button", nil, ActionPanel, "UIPanelButtonTemplate")
IdeaButton:SetSize(180, 30)
IdeaButton:SetPoint("LEFT", FeedbackButton, "RIGHT", 14, 0)
IdeaButton:SetText("Idee einschicken")
IdeaButton:SetScript("OnClick", function()
    ShowWebsitePopup("Idee einschicken")
end)

local WebsiteHint = ActionPanel:CreateFontString(nil, "OVERLAY")
WebsiteHint:SetPoint("LEFT", IdeaButton, "RIGHT", 18, 0)
WebsiteHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
WebsiteHint:SetTextColor(0.85, 0.85, 0.85, 1)
WebsiteHint:SetText("www.beavismania.de")

BeavisQoL.Pages.Version = PageVersion
