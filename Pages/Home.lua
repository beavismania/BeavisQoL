local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content

local L = BeavisQoL.L
local metadata = BeavisQoL.Metadata or {}
local version = metadata.version or C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or L("UNKNOWN")
local name = metadata.title or C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title") or L("UNKNOWN")
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
    icon:SetSize(56, 56)
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", 18, -18)
    icon:SetTexture(iconPath)

    local title = button:CreateFontString(nil, "OVERLAY")
    title:SetPoint("LEFT", icon, "RIGHT", 16, 5)
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

local function GetTextHeight(fontString, minimumHeight)
    local textHeight = fontString and fontString.GetStringHeight and fontString:GetStringHeight() or 0
    if textHeight == nil or textHeight < (minimumHeight or 0) then
        return minimumHeight or 0
    end

    return textHeight
end

local PageHome = CreateFrame("Frame", nil, Content)
PageHome:SetAllPoints()

local PageHomeScrollFrame = CreateFrame("ScrollFrame", nil, PageHome, "UIPanelScrollFrameTemplate")
PageHomeScrollFrame:SetPoint("TOPLEFT", PageHome, "TOPLEFT", 0, 0)
PageHomeScrollFrame:SetPoint("BOTTOMRIGHT", PageHome, "BOTTOMRIGHT", -28, 0)
PageHomeScrollFrame:EnableMouseWheel(true)

local PageHomeContent = CreateFrame("Frame", nil, PageHomeScrollFrame)
PageHomeContent:SetSize(1, 1)
PageHomeScrollFrame:SetScrollChild(PageHomeContent)

local IntroPanel = CreateFrame("Frame", nil, PageHomeContent)
IntroPanel:SetPoint("TOPLEFT", PageHomeContent, "TOPLEFT", 22, -22)
IntroPanel:SetPoint("TOPRIGHT", PageHomeContent, "TOPRIGHT", -22, -22)
IntroPanel:SetHeight(220)

local IntroSurface = CreatePanelSurface(IntroPanel)
ApplyPanelSurface(IntroSurface, "hero", false)

local IntroEyebrow = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroEyebrow:SetPoint("TOPLEFT", IntroPanel, "TOPLEFT", 22, -18)
IntroEyebrow:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
IntroEyebrow:SetTextColor(1, 0.88, 0.35, 1)
IntroEyebrow:SetText(L("HOME"))

local SpotlightPanel = CreateFrame("Frame", nil, IntroPanel)
SpotlightPanel:SetPoint("TOPRIGHT", IntroPanel, "TOPRIGHT", -20, -28)
SpotlightPanel:SetWidth(292)
SpotlightPanel:SetHeight(174)

local SpotlightSurface = CreatePanelSurface(SpotlightPanel)
ApplyPanelSurface(SpotlightSurface, "card", false)

local SpotlightHeader = CreateFrame("Frame", nil, SpotlightPanel)
SpotlightHeader:SetPoint("TOPLEFT", SpotlightPanel, "TOPLEFT", 18, -16)
SpotlightHeader:SetPoint("TOPRIGHT", SpotlightPanel, "TOPRIGHT", -18, -16)
SpotlightHeader:SetHeight(44)

local SpotlightLogo = SpotlightPanel:CreateTexture(nil, "ARTWORK")
SpotlightLogo:SetSize(44, 44)
SpotlightLogo:SetPoint("TOPLEFT", SpotlightHeader, "TOPLEFT", 0, 0)
SpotlightLogo:SetTexture("Interface\\AddOns\\BeavisQoL\\Media\\logo.tga")

local SpotlightTitle = SpotlightPanel:CreateFontString(nil, "OVERLAY")
SpotlightTitle:SetPoint("LEFT", SpotlightLogo, "RIGHT", 14, 0)
SpotlightTitle:SetPoint("RIGHT", SpotlightHeader, "RIGHT", 0, 0)
SpotlightTitle:SetPoint("CENTER", SpotlightLogo, "CENTER", 0, 0)
SpotlightTitle:SetJustifyH("LEFT")
SpotlightTitle:SetFont("Fonts\\FRIZQT__.TTF", 17, "OUTLINE")
SpotlightTitle:SetTextColor(1, 0.82, 0, 1)
SpotlightTitle:SetText(L("PROJECT_STATUS"))

local SpotlightVersion = SpotlightPanel:CreateFontString(nil, "OVERLAY")
SpotlightVersion:SetPoint("TOPLEFT", SpotlightTitle, "BOTTOMLEFT", 0, -12)
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
SpotlightState:SetText(BeavisQoL.GetReleaseStatusText and BeavisQoL.GetReleaseStatusText() or L("STATUS_ALPHA"))

local SpotlightFocus = SpotlightPanel:CreateFontString(nil, "OVERLAY")
SpotlightFocus:SetPoint("TOPLEFT", SpotlightState, "BOTTOMLEFT", 0, -10)
SpotlightFocus:SetPoint("RIGHT", SpotlightPanel, "RIGHT", -18, 0)
SpotlightFocus:SetJustifyH("LEFT")
SpotlightFocus:SetJustifyV("TOP")
SpotlightFocus:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
SpotlightFocus:SetTextColor(0.93, 0.93, 0.95, 1)
SpotlightFocus:SetText("")
SpotlightFocus:Hide()

local IntroTitle = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroTitle:SetPoint("TOPLEFT", IntroEyebrow, "BOTTOMLEFT", 0, -14)
IntroTitle:SetPoint("RIGHT", SpotlightPanel, "LEFT", -28, 0)
IntroTitle:SetJustifyH("LEFT")
IntroTitle:SetFont("Fonts\\FRIZQT__.TTF", 30, "OUTLINE")
IntroTitle:SetTextColor(1, 0.82, 0, 1)
IntroTitle:SetText(L("WELCOME_TITLE"):format(name))

local IntroSubtitle = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroSubtitle:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -8)
IntroSubtitle:SetPoint("RIGHT", SpotlightPanel, "LEFT", -28, 0)
IntroSubtitle:SetJustifyH("LEFT")
IntroSubtitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
IntroSubtitle:SetTextColor(0.84, 0.84, 0.86, 1)
IntroSubtitle:SetText(L("WELCOME_SUBTITLE"))

local IntroText = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroText:SetPoint("TOPLEFT", IntroSubtitle, "BOTTOMLEFT", 0, -16)
IntroText:SetPoint("RIGHT", SpotlightPanel, "LEFT", -28, 0)
IntroText:SetJustifyH("LEFT")
IntroText:SetJustifyV("TOP")
IntroText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroText:SetTextColor(0.96, 0.96, 0.96, 1)
IntroText:SetText(L("WELCOME_BODY"))

local HighlightsRow = CreateFrame("Frame", nil, PageHomeContent)
HighlightsRow:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -18)
HighlightsRow:SetPoint("RIGHT", PageHomeContent, "RIGHT", -22, 0)
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
HighlightsRow:Hide()

local ActionRow = CreateFrame("Frame", nil, PageHomeContent)
ActionRow:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -10)
ActionRow:SetPoint("RIGHT", PageHomeContent, "RIGHT", -22, 0)
ActionRow:SetHeight(184)

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

local function LayoutHomePage()
    local contentWidth = math.max(1, PageHomeScrollFrame:GetWidth())
    if contentWidth <= 1 then
        return
    end

    PageHomeContent:SetWidth(contentWidth)

    IntroTitle:ClearAllPoints()
    IntroSubtitle:ClearAllPoints()
    IntroText:ClearAllPoints()
    SpotlightPanel:ClearAllPoints()

    IntroTitle:SetPoint("TOPLEFT", IntroEyebrow, "BOTTOMLEFT", 0, -14)
    IntroTitle:SetPoint("RIGHT", IntroPanel, "RIGHT", -22, 0)

    IntroSubtitle:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -8)
    IntroSubtitle:SetPoint("RIGHT", IntroPanel, "RIGHT", -22, 0)

    IntroText:SetPoint("TOPLEFT", IntroSubtitle, "BOTTOMLEFT", 0, -16)
    IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -22, 0)

    SpotlightPanel:SetPoint("TOPLEFT", IntroText, "BOTTOMLEFT", 0, -12)
    SpotlightPanel:SetPoint("RIGHT", IntroPanel, "RIGHT", -20, 0)

    local headerHeight = math.max(40, SpotlightLogo:GetHeight())
    SpotlightHeader:SetHeight(headerHeight)

    local leftColumnHeight =
        18
        + GetTextHeight(IntroEyebrow, 11)
        + 14
        + GetTextHeight(IntroTitle, 30)
        + 8
        + GetTextHeight(IntroSubtitle, 14)
        + 16
        + GetTextHeight(IntroText, 13)
        + 12

    local spotlightHeight =
        16
        + headerHeight
        + GetTextHeight(SpotlightVersion, 12)
        + 10
        + GetTextHeight(SpotlightState, 12)
        + 18

    SpotlightPanel:SetHeight(math.max(104, math.ceil(spotlightHeight)))
    IntroPanel:SetHeight(math.max(176, math.ceil(leftColumnHeight + 12 + spotlightHeight + 10)))

    local contentHeight = 22
        + IntroPanel:GetHeight()
        + 10 + ActionRow:GetHeight()
        + 20

    PageHomeContent:SetHeight(contentHeight)
end

BeavisQoL.UpdateHome = function()
    IntroEyebrow:SetText(L("HOME"))
    IntroTitle:SetText(L("WELCOME_TITLE"):format(name))
    IntroSubtitle:SetText(L("WELCOME_SUBTITLE"))
    IntroText:SetText(L("WELCOME_BODY"))
    SpotlightTitle:SetText(L("PROJECT_STATUS"))
    SpotlightVersion:SetText(L("VERSION") .. ": " .. version)
    SpotlightState:SetText(BeavisQoL.GetReleaseStatusText and BeavisQoL.GetReleaseStatusText() or L("STATUS_ALPHA"))
    SpotlightFocus:SetText("")
    SpotlightFocus:Hide()
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
    LayoutHomePage()
end

PageHomeScrollFrame:SetScript("OnSizeChanged", LayoutHomePage)
PageHomeScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local step = 40
    local currentScroll = self:GetVerticalScroll()
    local maxScroll = math.max(0, PageHomeContent:GetHeight() - self:GetHeight())
    local nextScroll = currentScroll - (delta * step)

    if nextScroll < 0 then
        nextScroll = 0
    elseif nextScroll > maxScroll then
        nextScroll = maxScroll
    end

    self:SetVerticalScroll(nextScroll)
end)

PageHome:SetScript("OnShow", function()
    LayoutHomePage()
    PageHomeScrollFrame:SetVerticalScroll(0)
end)

BeavisQoL.Pages.Home = PageHome
