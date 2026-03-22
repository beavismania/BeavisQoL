local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content

local L = BeavisQoL.L
local version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or L("UNKNOWN")
local name = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title") or L("UNKNOWN")
local TWITCH_URL = "https://www.twitch.tv/beavismania"
local WEBSITE_URL = "https://www.beavismania.de"

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

local function ApplyPanelSurface(surface, style, highlighted)
    local bgR = 0.085
    local bgG = 0.085
    local bgB = 0.09
    local bgA = 0.94
    local glowA = 0.05
    local accentA = 0.7
    local borderA = 0.78

    if style == "hero" then
        bgR = 0.065
        bgG = 0.065
        bgB = 0.07
        bgA = 0.97
        glowA = 0.09
        accentA = 0.88
        borderA = 0.88
    elseif style == "footer" then
        bgR = 0.075
        bgG = 0.075
        bgB = 0.08
        bgA = 0.9
        glowA = 0.04
        accentA = 0.55
        borderA = 0.6
    end

    if highlighted then
        bgR = bgR + 0.03
        bgG = bgG + 0.03
        bgB = bgB + 0.03
        glowA = glowA + 0.05
        accentA = math.min(1, accentA + 0.12)
    end

    surface.bg:SetColorTexture(bgR, bgG, bgB, bgA)
    surface.glow:SetColorTexture(1, 0.82, 0, glowA)
    surface.accent:SetColorTexture(1, 0.82, 0, accentA)
    surface.border:SetColorTexture(1, 0.82, 0, borderA)
end

local function CreateInfoCard(parent, titleText, bodyText, footerText)
    local frame = CreateFrame("Frame", nil, parent)
    local surface = CreatePanelSurface(frame)
    ApplyPanelSurface(surface, "card", false)

    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -18)
    title:SetPoint("RIGHT", frame, "RIGHT", -18, 0)
    title:SetJustifyH("LEFT")
    title:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
    title:SetTextColor(1, 0.82, 0, 1)
    title:SetText(titleText)

    local body = frame:CreateFontString(nil, "OVERLAY")
    body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
    body:SetPoint("RIGHT", frame, "RIGHT", -18, 0)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    body:SetTextColor(0.96, 0.96, 0.96, 1)
    body:SetText(bodyText)

    local footer = frame:CreateFontString(nil, "OVERLAY")
    footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 14)
    footer:SetPoint("RIGHT", frame, "RIGHT", -18, 0)
    footer:SetJustifyH("LEFT")
    footer:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    footer:SetTextColor(1, 0.85, 0.25, 1)
    footer:SetText(footerText)

    frame.Title = title
    frame.Body = body
    frame.Footer = footer

    return frame
end

local function CreateActionCard(parent, iconPath, titleText, bodyText, footerText, popupTitle, urlText)
    local button = CreateFrame("Button", nil, parent)
    local surface = CreatePanelSurface(button)
    ApplyPanelSurface(surface, "card", false)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(38, 38)
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", 18, -18)
    icon:SetTexture(iconPath)

    local title = button:CreateFontString(nil, "OVERLAY")
    title:SetPoint("LEFT", icon, "RIGHT", 12, 5)
    title:SetPoint("RIGHT", button, "RIGHT", -18, 0)
    title:SetJustifyH("LEFT")
    title:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
    title:SetTextColor(1, 0.82, 0, 1)
    title:SetText(titleText)

    local body = button:CreateFontString(nil, "OVERLAY")
    body:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -12)
    body:SetPoint("RIGHT", button, "RIGHT", -18, 0)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    body:SetTextColor(0.96, 0.96, 0.96, 1)
    body:SetText(bodyText)

    local footer = button:CreateFontString(nil, "OVERLAY")
    footer:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 18, 14)
    footer:SetPoint("RIGHT", button, "RIGHT", -18, 0)
    footer:SetJustifyH("LEFT")
    footer:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    footer:SetTextColor(1, 0.85, 0.25, 1)
    footer:SetText(footerText)

    button.Title = title
    button.Body = body
    button.Footer = footer

    button:SetScript("OnEnter", function()
        ApplyPanelSurface(surface, "card", true)
    end)

    button:SetScript("OnLeave", function()
        ApplyPanelSurface(surface, "card", false)
    end)

    button:SetScript("OnClick", function()
        if BeavisQoL.ShowLinkPopup then
            BeavisQoL.ShowLinkPopup(popupTitle, urlText)
        else
            print(urlText)
        end
    end)

    return button
end

local PageHome = CreateFrame("Frame", nil, Content)
PageHome:SetAllPoints()

local IntroPanel = CreateFrame("Frame", nil, PageHome)
IntroPanel:SetPoint("TOPLEFT", PageHome, "TOPLEFT", 22, -22)
IntroPanel:SetPoint("TOPRIGHT", PageHome, "TOPRIGHT", -22, -22)
IntroPanel:SetHeight(220)

local IntroSurface = CreatePanelSurface(IntroPanel)
ApplyPanelSurface(IntroSurface, "hero", false)

local IntroEyebrow = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroEyebrow:SetPoint("TOPLEFT", IntroPanel, "TOPLEFT", 22, -18)
IntroEyebrow:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
IntroEyebrow:SetTextColor(1, 0.88, 0.35, 1)
IntroEyebrow:SetText(L("HOME"))

local IntroTitle = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroTitle:SetPoint("TOPLEFT", IntroEyebrow, "BOTTOMLEFT", 0, -8)
IntroTitle:SetPoint("RIGHT", IntroPanel, "RIGHT", -340, 0)
IntroTitle:SetJustifyH("LEFT")
IntroTitle:SetFont("Fonts\\FRIZQT__.TTF", 30, "OUTLINE")
IntroTitle:SetTextColor(1, 0.82, 0, 1)
IntroTitle:SetText(L("WELCOME_TITLE"):format(name))

local IntroSubtitle = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroSubtitle:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -8)
IntroSubtitle:SetPoint("RIGHT", IntroPanel, "RIGHT", -340, 0)
IntroSubtitle:SetJustifyH("LEFT")
IntroSubtitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
IntroSubtitle:SetTextColor(0.84, 0.84, 0.86, 1)
IntroSubtitle:SetText(L("WELCOME_SUBTITLE"))

local IntroText = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroText:SetPoint("TOPLEFT", IntroSubtitle, "BOTTOMLEFT", 0, -16)
IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -340, 0)
IntroText:SetJustifyH("LEFT")
IntroText:SetJustifyV("TOP")
IntroText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroText:SetTextColor(0.96, 0.96, 0.96, 1)
IntroText:SetText(L("WELCOME_BODY"))

local SpotlightPanel = CreateFrame("Frame", nil, IntroPanel)
SpotlightPanel:SetPoint("TOPRIGHT", IntroPanel, "TOPRIGHT", -20, -18)
SpotlightPanel:SetPoint("BOTTOMRIGHT", IntroPanel, "BOTTOMRIGHT", -20, 18)
SpotlightPanel:SetWidth(292)

local SpotlightSurface = CreatePanelSurface(SpotlightPanel)
ApplyPanelSurface(SpotlightSurface, "card", false)

local SpotlightLogo = SpotlightPanel:CreateTexture(nil, "ARTWORK")
SpotlightLogo:SetSize(52, 52)
SpotlightLogo:SetPoint("TOPLEFT", SpotlightPanel, "TOPLEFT", 18, -16)
SpotlightLogo:SetTexture("Interface\\AddOns\\BeavisQoL\\Media\\logo.tga")

local SpotlightTitle = SpotlightPanel:CreateFontString(nil, "OVERLAY")
SpotlightTitle:SetPoint("LEFT", SpotlightLogo, "RIGHT", 12, 10)
SpotlightTitle:SetPoint("RIGHT", SpotlightPanel, "RIGHT", -18, 0)
SpotlightTitle:SetJustifyH("LEFT")
SpotlightTitle:SetFont("Fonts\\FRIZQT__.TTF", 17, "OUTLINE")
SpotlightTitle:SetTextColor(1, 0.82, 0, 1)
SpotlightTitle:SetText(L("PROJECT_STATUS"))

local SpotlightVersion = SpotlightPanel:CreateFontString(nil, "OVERLAY")
SpotlightVersion:SetPoint("TOPLEFT", SpotlightLogo, "BOTTOMLEFT", 0, -14)
SpotlightVersion:SetPoint("RIGHT", SpotlightPanel, "RIGHT", -18, 0)
SpotlightVersion:SetJustifyH("LEFT")
SpotlightVersion:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
SpotlightVersion:SetTextColor(1, 1, 1, 1)
SpotlightVersion:SetText(L("VERSION") .. ": " .. version)

local SpotlightState = SpotlightPanel:CreateFontString(nil, "OVERLAY")
SpotlightState:SetPoint("TOPLEFT", SpotlightVersion, "BOTTOMLEFT", 0, -10)
SpotlightState:SetPoint("RIGHT", SpotlightPanel, "RIGHT", -18, 0)
SpotlightState:SetJustifyH("LEFT")
SpotlightState:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
SpotlightState:SetTextColor(1, 1, 1, 1)
SpotlightState:SetText(L("STATUS_ALPHA"))

local SpotlightFocus = SpotlightPanel:CreateFontString(nil, "OVERLAY")
SpotlightFocus:SetPoint("TOPLEFT", SpotlightState, "BOTTOMLEFT", 0, -10)
SpotlightFocus:SetPoint("RIGHT", SpotlightPanel, "RIGHT", -18, 0)
SpotlightFocus:SetJustifyH("LEFT")
SpotlightFocus:SetJustifyV("TOP")
SpotlightFocus:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
SpotlightFocus:SetTextColor(0.93, 0.93, 0.95, 1)
SpotlightFocus:SetText(L("STATUS_FOCUS"))

local HighlightsRow = CreateFrame("Frame", nil, PageHome)
HighlightsRow:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -18)
HighlightsRow:SetPoint("RIGHT", PageHome, "RIGHT", -22, 0)
HighlightsRow:SetHeight(162)

local ProgressCard = CreateInfoCard(
    HighlightsRow,
    L("PROGRESS_CARD_TITLE"),
    L("PROGRESS_CARD_BODY"),
    L("PROGRESS_CARD_FOOTER")
)
ProgressCard:SetPoint("TOPLEFT", HighlightsRow, "TOPLEFT", 0, 0)
ProgressCard:SetPoint("BOTTOMLEFT", HighlightsRow, "BOTTOMLEFT", 0, 0)
ProgressCard:SetPoint("RIGHT", HighlightsRow, "CENTER", -9, 0)

local ComfortCard = CreateInfoCard(
    HighlightsRow,
    L("COMFORT_CARD_TITLE"),
    L("COMFORT_CARD_BODY"),
    L("COMFORT_CARD_FOOTER")
)
ComfortCard:SetPoint("TOPRIGHT", HighlightsRow, "TOPRIGHT", 0, 0)
ComfortCard:SetPoint("BOTTOMRIGHT", HighlightsRow, "BOTTOMRIGHT", 0, 0)
ComfortCard:SetPoint("LEFT", HighlightsRow, "CENTER", 9, 0)

local ActionRow = CreateFrame("Frame", nil, PageHome)
ActionRow:SetPoint("TOPLEFT", HighlightsRow, "BOTTOMLEFT", 0, -18)
ActionRow:SetPoint("RIGHT", PageHome, "RIGHT", -22, 0)
ActionRow:SetHeight(170)

local TwitchCard = CreateActionCard(
    ActionRow,
    "Interface\\AddOns\\BeavisQoL\\Media\\twitch.tga",
    L("TWITCH_TITLE"),
    L("TWITCH_BODY"),
    L("TWITCH_FOOTER"),
    L("TWITCH_POPUP"),
    TWITCH_URL
)
TwitchCard:SetPoint("TOPLEFT", ActionRow, "TOPLEFT", 0, 0)
TwitchCard:SetPoint("BOTTOMLEFT", ActionRow, "BOTTOMLEFT", 0, 0)
TwitchCard:SetPoint("RIGHT", ActionRow, "CENTER", -9, 0)

local DiscordCard = CreateActionCard(
    ActionRow,
    "Interface\\AddOns\\BeavisQoL\\Media\\discord.tga",
    L("DISCORD_TITLE"),
    L("DISCORD_BODY"),
    L("DISCORD_FOOTER"),
    L("DISCORD_POPUP"),
    WEBSITE_URL
)
DiscordCard:SetPoint("TOPRIGHT", ActionRow, "TOPRIGHT", 0, 0)
DiscordCard:SetPoint("BOTTOMRIGHT", ActionRow, "BOTTOMRIGHT", 0, 0)
DiscordCard:SetPoint("LEFT", ActionRow, "CENTER", 9, 0)

local FooterPanel = CreateFrame("Frame", nil, PageHome)
FooterPanel:SetPoint("TOPLEFT", ActionRow, "BOTTOMLEFT", 0, -18)
FooterPanel:SetPoint("TOPRIGHT", PageHome, "TOPRIGHT", -22, 0)
FooterPanel:SetHeight(64)

local FooterSurface = CreatePanelSurface(FooterPanel)
ApplyPanelSurface(FooterSurface, "footer", false)

local FooterText = FooterPanel:CreateFontString(nil, "OVERLAY")
FooterText:SetPoint("LEFT", FooterPanel, "LEFT", 18, 0)
FooterText:SetPoint("RIGHT", FooterPanel, "RIGHT", -18, 0)
FooterText:SetJustifyH("LEFT")
FooterText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
FooterText:SetTextColor(0.9, 0.9, 0.92, 1)
FooterText:SetText(L("FOOTER_TEXT"))

BeavisQoL.UpdateHome = function()
    IntroEyebrow:SetText(L("HOME"))
    IntroTitle:SetText(L("WELCOME_TITLE"):format(name))
    IntroSubtitle:SetText(L("WELCOME_SUBTITLE"))
    IntroText:SetText(L("WELCOME_BODY"))
    SpotlightTitle:SetText(L("PROJECT_STATUS"))
    SpotlightVersion:SetText(L("VERSION") .. ": " .. version)
    SpotlightState:SetText(L("STATUS_ALPHA"))
    SpotlightFocus:SetText(L("STATUS_FOCUS"))
    ProgressCard.Title:SetText(L("PROGRESS_CARD_TITLE"))
    ProgressCard.Body:SetText(L("PROGRESS_CARD_BODY"))
    ProgressCard.Footer:SetText(L("PROGRESS_CARD_FOOTER"))
    ComfortCard.Title:SetText(L("COMFORT_CARD_TITLE"))
    ComfortCard.Body:SetText(L("COMFORT_CARD_BODY"))
    ComfortCard.Footer:SetText(L("COMFORT_CARD_FOOTER"))
    TwitchCard.Title:SetText(L("TWITCH_TITLE"))
    TwitchCard.Body:SetText(L("TWITCH_BODY"))
    TwitchCard.Footer:SetText(L("TWITCH_FOOTER"))
    DiscordCard.Title:SetText(L("DISCORD_TITLE"))
    DiscordCard.Body:SetText(L("DISCORD_BODY"))
    DiscordCard.Footer:SetText(L("DISCORD_FOOTER"))
    FooterText:SetText(L("FOOTER_TEXT"))
end

BeavisQoL.Pages.Home = PageHome
