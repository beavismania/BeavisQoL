local ADDON_NAME, BeavisAddon = ...

local Content = BeavisAddon.Content

-- Laden der Meta Infos 
local version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "Unbekannt"
local name = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title") or "Unbekannt"

local PageHome = CreateFrame("Frame", nil, Content)
PageHome:SetAllPoints()

-- =========================
-- Intro-Bereich
-- =========================

local IntroPanel = CreateFrame("Frame", nil, PageHome)
IntroPanel:SetPoint("TOPLEFT", PageHome, "TOPLEFT", 20, -20)
IntroPanel:SetPoint("TOPRIGHT", PageHome, "TOPRIGHT", -20, -20)
IntroPanel:SetHeight(155)

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
IntroTitle:SetText("Willkommen bei " .. name)

local IntroSubtitle = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroSubtitle:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -8)
IntroSubtitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
IntroSubtitle:SetTextColor(0.85, 0.85, 0.85, 1)
IntroSubtitle:SetText("Beavis · Twitchstreamer auf Beavismania")

local IntroText = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroText:SetPoint("TOPLEFT", IntroSubtitle, "BOTTOMLEFT", 0, -12)
IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
IntroText:SetJustifyH("LEFT")
IntroText:SetJustifyV("TOP")
IntroText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroText:SetTextColor(1, 1, 1, 1)
IntroText:SetText(
    "Hi, ich bin Beavis und streame auf Twitch unter dem Namen Beavismania.\n\n" ..
    "Dieses Addon ist mein erstes eigenes WoW-Addon. Ich versuche hier nach und nach komfortable und nützliche Funktionen an einem Ort zu vereinen.\n\n" ..
    "Ich freue mich über jeden Support, jedes Feedback und jede Idee, um das Addon Schritt für Schritt weiterzuentwickeln."
)

-- =========================
-- Karten-Zeile
-- =========================

local CardsRow = CreateFrame("Frame", nil, PageHome)
CardsRow:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -20)
CardsRow:SetPoint("TOPRIGHT", PageHome, "TOPRIGHT", -20, -195)
CardsRow:SetHeight(145)

-- =========================
-- Twitch-Karte
-- =========================

local TwitchPanel = CreateFrame("Button", nil, CardsRow)
TwitchPanel:SetPoint("TOPLEFT", CardsRow, "TOPLEFT", 0, 0)
TwitchPanel:SetPoint("BOTTOMLEFT", CardsRow, "BOTTOMLEFT", 0, 0)
TwitchPanel:SetPoint("RIGHT", CardsRow, "CENTER", -10, 0)

local TwitchBg = TwitchPanel:CreateTexture(nil, "BACKGROUND")
TwitchBg:SetAllPoints()
TwitchBg:SetColorTexture(0.10, 0.10, 0.10, 0.92)

local TwitchBorder = TwitchPanel:CreateTexture(nil, "ARTWORK")
TwitchBorder:SetPoint("BOTTOMLEFT", TwitchPanel, "BOTTOMLEFT", 0, 0)
TwitchBorder:SetPoint("BOTTOMRIGHT", TwitchPanel, "BOTTOMRIGHT", 0, 0)
TwitchBorder:SetHeight(1)
TwitchBorder:SetColorTexture(1, 0.82, 0, 0.9)

local TwitchLogo = TwitchPanel:CreateTexture(nil, "ARTWORK")
TwitchLogo:SetSize(36, 36)
TwitchLogo:SetPoint("TOPLEFT", TwitchPanel, "TOPLEFT", 16, -16)
TwitchLogo:SetTexture("Interface\\AddOns\\BeavisAddon\\Media\\twitch.tga")

local TwitchTitle = TwitchPanel:CreateFontString(nil, "OVERLAY")
TwitchTitle:SetPoint("LEFT", TwitchLogo, "RIGHT", 10, 6)
TwitchTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
TwitchTitle:SetTextColor(1, 0.82, 0, 1)
TwitchTitle:SetText("Twitch")

local TwitchLink = TwitchPanel:CreateFontString(nil, "OVERLAY")
TwitchLink:SetPoint("BOTTOMLEFT", TwitchPanel, "BOTTOMLEFT", 16, 14)
TwitchLink:SetPoint("BOTTOMRIGHT", TwitchPanel, "BOTTOMRIGHT", -16, 14)
TwitchLink:SetJustifyH("LEFT")
TwitchLink:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
TwitchLink:SetTextColor(1, 0.82, 0, 1)
TwitchLink:SetText("Zum Twitch-Kanal")

local TwitchText = TwitchPanel:CreateFontString(nil, "OVERLAY")
TwitchText:SetPoint("TOPLEFT", TwitchLogo, "BOTTOMLEFT", 0, -12)
TwitchText:SetPoint("TOPRIGHT", TwitchPanel, "TOPRIGHT", -16, -60)
TwitchText:SetPoint("BOTTOMLEFT", TwitchLink, "TOPLEFT", 0, 8)
TwitchText:SetJustifyH("LEFT")
TwitchText:SetJustifyV("TOP")
TwitchText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
TwitchText:SetTextColor(1, 1, 1, 1)
TwitchText:SetText("Besuche meinen Kanal und begleite mich live auf twitch.tv/beavismania")

TwitchPanel:SetScript("OnEnter", function()
    TwitchBg:SetColorTexture(0.14, 0.14, 0.14, 0.96)
end)

TwitchPanel:SetScript("OnLeave", function()
    TwitchBg:SetColorTexture(0.10, 0.10, 0.10, 0.92)
end)

TwitchPanel:SetScript("OnClick", function()
    if LaunchURL then
        LaunchURL("https://www.twitch.tv/beavismania")
    else
        print("Twitch: https://www.twitch.tv/beavismania")
    end
end)

-- =========================
-- Discord-Karte
-- =========================

local DiscordPanel = CreateFrame("Button", nil, CardsRow)
DiscordPanel:SetPoint("TOPRIGHT", CardsRow, "TOPRIGHT", 0, 0)
DiscordPanel:SetPoint("BOTTOMRIGHT", CardsRow, "BOTTOMRIGHT", 0, 0)
DiscordPanel:SetPoint("LEFT", CardsRow, "CENTER", 10, 0)

local DiscordBg = DiscordPanel:CreateTexture(nil, "BACKGROUND")
DiscordBg:SetAllPoints()
DiscordBg:SetColorTexture(0.10, 0.10, 0.10, 0.92)

local DiscordBorder = DiscordPanel:CreateTexture(nil, "ARTWORK")
DiscordBorder:SetPoint("BOTTOMLEFT", DiscordPanel, "BOTTOMLEFT", 0, 0)
DiscordBorder:SetPoint("BOTTOMRIGHT", DiscordPanel, "BOTTOMRIGHT", 0, 0)
DiscordBorder:SetHeight(1)
DiscordBorder:SetColorTexture(1, 0.82, 0, 0.9)

local DiscordLogo = DiscordPanel:CreateTexture(nil, "ARTWORK")
DiscordLogo:SetSize(36, 36)
DiscordLogo:SetPoint("TOPLEFT", DiscordPanel, "TOPLEFT", 16, -16)
DiscordLogo:SetTexture("Interface\\AddOns\\BeavisAddon\\Media\\discord.tga")

local DiscordTitle = DiscordPanel:CreateFontString(nil, "OVERLAY")
DiscordTitle:SetPoint("LEFT", DiscordLogo, "RIGHT", 10, 6)
DiscordTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
DiscordTitle:SetTextColor(1, 0.82, 0, 1)
DiscordTitle:SetText("Discord & Support")

local DiscordLink = DiscordPanel:CreateFontString(nil, "OVERLAY")
DiscordLink:SetPoint("BOTTOMLEFT", DiscordPanel, "BOTTOMLEFT", 16, 14)
DiscordLink:SetPoint("BOTTOMRIGHT", DiscordPanel, "BOTTOMRIGHT", -16, 14)
DiscordLink:SetJustifyH("LEFT")
DiscordLink:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
DiscordLink:SetTextColor(1, 0.82, 0, 1)
DiscordLink:SetText("Zur Beavismania-Website")

local DiscordText = DiscordPanel:CreateFontString(nil, "OVERLAY")
DiscordText:SetPoint("TOPLEFT", DiscordLogo, "BOTTOMLEFT", 0, -12)
DiscordText:SetPoint("TOPRIGHT", DiscordPanel, "TOPRIGHT", -16, -60)
DiscordText:SetPoint("BOTTOMLEFT", DiscordLink, "TOPLEFT", 0, 8)
DiscordText:SetJustifyH("LEFT")
DiscordText:SetJustifyV("TOP")
DiscordText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
DiscordText:SetTextColor(1, 1, 1, 1)
DiscordText:SetText("Support, Feedback und Austausch findest du über meinen Discord auf www.beavismania.de")

DiscordPanel:SetScript("OnEnter", function()
    DiscordBg:SetColorTexture(0.14, 0.14, 0.14, 0.96)
end)

DiscordPanel:SetScript("OnLeave", function()
    DiscordBg:SetColorTexture(0.10, 0.10, 0.10, 0.92)
end)

DiscordPanel:SetScript("OnClick", function()
    if LaunchURL then
        LaunchURL("https://www.beavismania.de")
    else
        print("Website: https://www.beavismania.de")
    end
end)

BeavisAddon.Pages.Home = PageHome