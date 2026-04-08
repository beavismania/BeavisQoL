local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content

local L = BeavisQoL.L
local metadata = BeavisQoL.Metadata or {}
local version = metadata.version or C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or L("UNKNOWN")
local name = metadata.title or C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title") or L("UNKNOWN")
local TWITCH_URL = "https://www.twitch.tv/beavismania"
local WEBSITE_URL = "https://www.beavismania.de"
local DONATION_URL = "https://streamelements.com/beavismania/tip"

local function ApplyTextureGradient(texture, orientation, startR, startG, startB, startA, endR, endG, endB, endA)
    if not texture then
        return
    end

    if texture.SetGradientAlpha then
        texture:SetGradientAlpha(orientation, startR, startG, startB, startA, endR, endG, endB, endA)
        return
    end

    if texture.SetGradient and CreateColor then
        texture:SetGradient(
            orientation,
            CreateColor(startR, startG, startB, startA),
            CreateColor(endR, endG, endB, endA)
        )
        return
    end

    texture:SetColorTexture(startR, startG, startB, math.max(startA or 0, endA or 0))
end

local function CreatePanelSurface(frame)
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()

    local detail = frame:CreateTexture(nil, "ARTWORK")
    detail:SetAllPoints()
    detail:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background-Dark")

    local glow = frame:CreateTexture(nil, "BORDER")
    glow:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    glow:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    glow:SetHeight(30)
    glow:SetTexture("Interface\\Buttons\\WHITE8X8")

    local vignette = frame:CreateTexture(nil, "ARTWORK")
    vignette:SetAllPoints()
    vignette:SetTexture("Interface\\Buttons\\WHITE8X8")

    local accent = frame:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -10)
    accent:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 10)
    accent:SetWidth(2)

    local topLine = frame:CreateTexture(nil, "ARTWORK")
    topLine:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    topLine:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    topLine:SetHeight(1)

    local border = frame:CreateTexture(nil, "ARTWORK")
    border:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    border:SetHeight(1)

    return {
        bg = bg,
        detail = detail,
        glow = glow,
        vignette = vignette,
        accent = accent,
        topLine = topLine,
        border = border,
    }
end

local function ApplyPanelSurface(surface, style, highlighted)
    local bgR = 0.055
    local bgG = 0.039
    local bgB = 0.029
    local bgA = 0.92
    local detailA = 0.09
    local glowA = 0.05
    local vignetteA = 0.16
    local accentA = 0.2
    local topLineA = 0.2
    local borderA = 0.26

    if style == "hero" then
        bgR = 0.062
        bgG = 0.044
        bgB = 0.032
        bgA = 0.95
        detailA = 0.12
        glowA = 0.08
        vignetteA = 0.2
        accentA = 0.28
        topLineA = 0.3
        borderA = 0.34
    elseif style == "footer" then
        bgR = 0.05
        bgG = 0.036
        bgB = 0.026
        bgA = 0.88
        detailA = 0.07
        glowA = 0.035
        vignetteA = 0.12
        accentA = 0.14
        topLineA = 0.14
        borderA = 0.18
    end

    if highlighted then
        bgR = math.min(1, bgR + 0.018)
        bgG = math.min(1, bgG + 0.018)
        bgB = math.min(1, bgB + 0.018)
        detailA = detailA + 0.03
        glowA = glowA + 0.03
        accentA = math.min(1, accentA + 0.08)
        topLineA = math.min(1, topLineA + 0.08)
        borderA = math.min(1, borderA + 0.08)
    end

    surface.bg:SetColorTexture(bgR, bgG, bgB, bgA)
    surface.detail:SetVertexColor(0.96, 0.82, 0.56, detailA)
    ApplyTextureGradient(surface.glow, "VERTICAL", 1, 0.88, 0.58, glowA, 1, 0.88, 0.58, 0)
    ApplyTextureGradient(surface.vignette, "HORIZONTAL", 0, 0, 0, 0.02, 0, 0, 0, vignetteA)
    surface.accent:SetColorTexture(0.9, 0.76, 0.5, accentA)
    surface.topLine:SetColorTexture(0.92, 0.79, 0.56, topLineA)
    surface.border:SetColorTexture(0.92, 0.79, 0.56, borderA)
end

local function CreateInfoCard(parent, titleText, bodyText, footerText)
    local frame = CreateFrame("Frame", nil, parent)
    local surface = CreatePanelSurface(frame)
    ApplyPanelSurface(surface, "card", false)

    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -14)
    title:SetPoint("RIGHT", frame, "RIGHT", -16, 0)
    title:SetJustifyH("LEFT")
    title:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    title:SetTextColor(0.97, 0.9, 0.76, 1)
    title:SetText(titleText)

    local body = frame:CreateFontString(nil, "OVERLAY")
    body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    body:SetPoint("RIGHT", frame, "RIGHT", -16, 0)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    body:SetTextColor(0.91, 0.89, 0.86, 1)
    body:SetText(bodyText)

    local footer = frame:CreateFontString(nil, "OVERLAY")
    footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 12)
    footer:SetPoint("RIGHT", frame, "RIGHT", -16, 0)
    footer:SetJustifyH("LEFT")
    footer:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    footer:SetTextColor(0.92, 0.8, 0.58, 1)
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
    button:SetHitRectInsets(-4, -4, -4, -4)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(40, 40)
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", 16, -14)
    icon:SetTexture(iconPath)
    icon:SetVertexColor(1, 1, 1, 0.94)

    local title = button:CreateFontString(nil, "OVERLAY")
    title:SetPoint("LEFT", icon, "RIGHT", 12, 3)
    title:SetPoint("RIGHT", button, "RIGHT", -16, 0)
    title:SetJustifyH("LEFT")
    title:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    title:SetTextColor(0.97, 0.9, 0.76, 1)
    title:SetText(titleText)

    local body = button:CreateFontString(nil, "OVERLAY")
    body:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -10)
    body:SetPoint("RIGHT", button, "RIGHT", -16, 0)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    body:SetTextColor(0.91, 0.89, 0.86, 1)
    body:SetText(bodyText)

    local footer = button:CreateFontString(nil, "OVERLAY")
    footer:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 16, 12)
    footer:SetPoint("RIGHT", button, "RIGHT", -16, 0)
    footer:SetJustifyH("LEFT")
    footer:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    footer:SetTextColor(0.92, 0.8, 0.58, 1)
    footer:SetText(footerText)

    button.Title = title
    button.Body = body
    button.Footer = footer
    button.Icon = icon

    button:SetScript("OnEnter", function()
        ApplyPanelSurface(surface, "card", true)
        button.Title:SetTextColor(1, 0.94, 0.84, 1)
        button.Footer:SetTextColor(0.98, 0.86, 0.64, 1)
    end)

    button:SetScript("OnLeave", function()
        ApplyPanelSurface(surface, "card", false)
        button.Title:SetTextColor(0.97, 0.9, 0.76, 1)
        button.Footer:SetTextColor(0.92, 0.8, 0.58, 1)
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

local function SetOptionalText(fontString, text)
    local value = tostring(text or "")
    fontString:SetText(value)

    if value ~= "" then
        fontString:Show()
    else
        fontString:Hide()
    end
end

local function GetActionCardHeight(card)
    local iconHeight = card.Icon and card.Icon.GetHeight and card.Icon:GetHeight() or 40
    local titleBlockHeight = math.max(iconHeight, GetTextHeight(card.Title, 15))

    return math.ceil(
        14
        + titleBlockHeight
        + 10
        + GetTextHeight(card.Body, 11)
        + 12
        + GetTextHeight(card.Footer, 10)
        + 12
    )
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
IntroPanel:SetPoint("TOPLEFT", PageHomeContent, "TOPLEFT", 18, -18)
IntroPanel:SetPoint("TOPRIGHT", PageHomeContent, "TOPRIGHT", -18, -18)
IntroPanel:SetHeight(196)

local IntroSurface = CreatePanelSurface(IntroPanel)
ApplyPanelSurface(IntroSurface, "hero", false)

local IntroEyebrow = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroEyebrow:SetPoint("TOPLEFT", IntroPanel, "TOPLEFT", 18, -16)
IntroEyebrow:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
IntroEyebrow:SetTextColor(0.93, 0.82, 0.62, 1)
IntroEyebrow:SetText(L("HOME"))

local SpotlightPanel = CreateFrame("Button", nil, IntroPanel)
SpotlightPanel:SetPoint("TOPRIGHT", IntroPanel, "TOPRIGHT", -18, -20)
SpotlightPanel:SetWidth(280)
SpotlightPanel:SetHeight(150)
SpotlightPanel:SetHitRectInsets(-4, -4, -4, -4)
SpotlightPanel:RegisterForClicks("LeftButtonUp")

local SpotlightSurface = CreatePanelSurface(SpotlightPanel)
ApplyPanelSurface(SpotlightSurface, "card", false)

local SpotlightHeader = CreateFrame("Frame", nil, SpotlightPanel)
SpotlightHeader:SetPoint("TOPLEFT", SpotlightPanel, "TOPLEFT", 16, -14)
SpotlightHeader:SetPoint("TOPRIGHT", SpotlightPanel, "TOPRIGHT", -16, -14)
SpotlightHeader:SetHeight(36)

local SpotlightLogo = SpotlightPanel:CreateTexture(nil, "ARTWORK")
SpotlightLogo:SetSize(36, 36)
SpotlightLogo:SetPoint("TOPLEFT", SpotlightHeader, "TOPLEFT", 0, 0)
SpotlightLogo:SetTexture("Interface\\AddOns\\BeavisQoL\\Media\\logo.tga")

local SpotlightTitle = SpotlightPanel:CreateFontString(nil, "OVERLAY")
SpotlightTitle:SetPoint("LEFT", SpotlightLogo, "RIGHT", 12, 0)
SpotlightTitle:SetPoint("RIGHT", SpotlightHeader, "RIGHT", 0, 0)
SpotlightTitle:SetPoint("CENTER", SpotlightLogo, "CENTER", 0, 0)
SpotlightTitle:SetJustifyH("LEFT")
SpotlightTitle:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
SpotlightTitle:SetTextColor(0.97, 0.9, 0.76, 1)
SpotlightTitle:SetText(L("HOME_SUPPORT_TITLE"))

local SpotlightVersion = SpotlightPanel:CreateFontString(nil, "OVERLAY")
SpotlightVersion:SetPoint("TOPLEFT", SpotlightTitle, "BOTTOMLEFT", 0, -8)
SpotlightVersion:SetPoint("RIGHT", SpotlightPanel, "RIGHT", -16, 0)
SpotlightVersion:SetJustifyH("LEFT")
SpotlightVersion:SetJustifyV("TOP")
SpotlightVersion:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
SpotlightVersion:SetTextColor(0.94, 0.91, 0.86, 1)
SpotlightVersion:SetText(L("HOME_SUPPORT_BODY"))

local SpotlightState = SpotlightPanel:CreateFontString(nil, "OVERLAY")
SpotlightState:SetPoint("TOPLEFT", SpotlightVersion, "BOTTOMLEFT", 0, -7)
SpotlightState:SetPoint("RIGHT", SpotlightPanel, "RIGHT", -16, 0)
SpotlightState:SetJustifyH("LEFT")
SpotlightState:SetJustifyV("TOP")
SpotlightState:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
SpotlightState:SetTextColor(0.94, 0.91, 0.86, 1)
SpotlightState:SetText(L("HOME_SUPPORT_HINT"))

local SpotlightFocus = SpotlightPanel:CreateFontString(nil, "OVERLAY")
SpotlightFocus:SetPoint("TOPLEFT", SpotlightState, "BOTTOMLEFT", 0, -8)
SpotlightFocus:SetPoint("RIGHT", SpotlightPanel, "RIGHT", -16, 0)
SpotlightFocus:SetJustifyH("LEFT")
SpotlightFocus:SetJustifyV("TOP")
SpotlightFocus:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
SpotlightFocus:SetTextColor(0.92, 0.8, 0.58, 1)
SetOptionalText(SpotlightFocus, L("HOME_SUPPORT_LINK"))

SpotlightPanel:SetScript("OnEnter", function()
    ApplyPanelSurface(SpotlightSurface, "card", true)
    SpotlightTitle:SetTextColor(1, 0.94, 0.84, 1)
    SpotlightFocus:SetTextColor(0.98, 0.86, 0.64, 1)
end)

SpotlightPanel:SetScript("OnLeave", function()
    ApplyPanelSurface(SpotlightSurface, "card", false)
    SpotlightTitle:SetTextColor(0.97, 0.9, 0.76, 1)
    SpotlightFocus:SetTextColor(0.92, 0.8, 0.58, 1)
end)

SpotlightPanel:SetScript("OnClick", function()
    if BeavisQoL.ShowLinkPopup then
        BeavisQoL.ShowLinkPopup(L("HOME_SUPPORT_POPUP"), DONATION_URL)
    else
        print(DONATION_URL)
    end
end)

local IntroTitle = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroTitle:SetPoint("TOPLEFT", IntroEyebrow, "BOTTOMLEFT", 0, -10)
IntroTitle:SetPoint("RIGHT", SpotlightPanel, "LEFT", -24, 0)
IntroTitle:SetJustifyH("LEFT")
IntroTitle:SetFont("Fonts\\FRIZQT__.TTF", 22, "")
IntroTitle:SetTextColor(0.99, 0.93, 0.84, 1)
IntroTitle:SetText(L("WELCOME_TITLE"):format(name))

local IntroSubtitle = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroSubtitle:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -6)
IntroSubtitle:SetPoint("RIGHT", SpotlightPanel, "LEFT", -24, 0)
IntroSubtitle:SetJustifyH("LEFT")
IntroSubtitle:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroSubtitle:SetTextColor(0.82, 0.79, 0.75, 1)
SetOptionalText(IntroSubtitle, L("WELCOME_SUBTITLE"))

local IntroText = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroText:SetPoint("TOPLEFT", IntroSubtitle, "BOTTOMLEFT", 0, -12)
IntroText:SetPoint("RIGHT", SpotlightPanel, "LEFT", -24, 0)
IntroText:SetJustifyH("LEFT")
IntroText:SetJustifyV("TOP")
IntroText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroText:SetTextColor(0.91, 0.89, 0.86, 1)
SetOptionalText(IntroText, L("WELCOME_BODY"))

local HighlightsRow = CreateFrame("Frame", nil, PageHomeContent)
HighlightsRow:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -14)
HighlightsRow:SetPoint("RIGHT", PageHomeContent, "RIGHT", -18, 0)
HighlightsRow:SetHeight(138)

local ProgressCard = CreateInfoCard(
    HighlightsRow,
    L("PROGRESS_CARD_TITLE"),
    L("PROGRESS_CARD_BODY"),
    L("PROGRESS_CARD_FOOTER")
)
ProgressCard:SetPoint("TOPLEFT", HighlightsRow, "TOPLEFT", 0, 0)
ProgressCard:SetPoint("BOTTOMLEFT", HighlightsRow, "BOTTOMLEFT", 0, 0)
ProgressCard:SetPoint("RIGHT", HighlightsRow, "CENTER", -7, 0)

local ComfortCard = CreateInfoCard(
    HighlightsRow,
    L("COMFORT_CARD_TITLE"),
    L("COMFORT_CARD_BODY"),
    L("COMFORT_CARD_FOOTER")
)
ComfortCard:SetPoint("TOPRIGHT", HighlightsRow, "TOPRIGHT", 0, 0)
ComfortCard:SetPoint("BOTTOMRIGHT", HighlightsRow, "BOTTOMRIGHT", 0, 0)
ComfortCard:SetPoint("LEFT", HighlightsRow, "CENTER", 7, 0)
HighlightsRow:Hide()

local ActionRow = CreateFrame("Frame", nil, PageHomeContent)
ActionRow:SetPoint("TOPLEFT", IntroPanel, "BOTTOMLEFT", 0, -8)
ActionRow:SetPoint("RIGHT", PageHomeContent, "RIGHT", -18, 0)
ActionRow:SetHeight(156)

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
TwitchCard:SetPoint("RIGHT", ActionRow, "CENTER", -7, 0)

local DiscordCard = CreateActionCard(
    ActionRow,
    "Interface\\AddOns\\BeavisQoL\\Media\\logo.tga",
    L("HOME_FEEDBACK_TITLE"),
    L("HOME_FEEDBACK_BODY"),
    L("HOME_FEEDBACK_FOOTER"),
    L("HOME_FEEDBACK_POPUP"),
    WEBSITE_URL
)
DiscordCard:SetPoint("TOPRIGHT", ActionRow, "TOPRIGHT", 0, 0)
DiscordCard:SetPoint("BOTTOMRIGHT", ActionRow, "BOTTOMRIGHT", 0, 0)
DiscordCard:SetPoint("LEFT", ActionRow, "CENTER", 7, 0)

local WebsiteRow = CreateFrame("Frame", nil, PageHomeContent)
WebsiteRow:SetPoint("TOPLEFT", ActionRow, "BOTTOMLEFT", 0, -10)
WebsiteRow:SetPoint("RIGHT", PageHomeContent, "RIGHT", -18, 0)
WebsiteRow:SetHeight(124)

local WebsiteCard = CreateActionCard(
    WebsiteRow,
    "Interface\\AddOns\\BeavisQoL\\Media\\logo.tga",
    L("WEBSITE_CARD_TITLE"),
    L("WEBSITE_CARD_BODY"),
    L("WEBSITE_CARD_FOOTER"),
    L("WEBSITE_CARD_POPUP"),
    WEBSITE_URL
)
WebsiteCard:SetAllPoints(WebsiteRow)

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

    IntroTitle:SetPoint("TOPLEFT", IntroEyebrow, "BOTTOMLEFT", 0, -10)
    IntroTitle:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)

    local previousTextAnchor = IntroTitle
    local leftColumnHeight = 16 + GetTextHeight(IntroEyebrow, 9) + 10 + GetTextHeight(IntroTitle, 24)

    if IntroSubtitle:IsShown() then
        IntroSubtitle:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -6)
        IntroSubtitle:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
        previousTextAnchor = IntroSubtitle
        leftColumnHeight = leftColumnHeight + 6 + GetTextHeight(IntroSubtitle, 12)
    end

    if IntroText:IsShown() then
        local introTextTopOffset = previousTextAnchor == IntroSubtitle and -12 or -10
        IntroText:SetPoint("TOPLEFT", previousTextAnchor, "BOTTOMLEFT", 0, introTextTopOffset)
        IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
        previousTextAnchor = IntroText
        leftColumnHeight = leftColumnHeight + math.abs(introTextTopOffset) + GetTextHeight(IntroText, 12)
    end

    leftColumnHeight = leftColumnHeight + 10

    SpotlightPanel:SetPoint("TOPLEFT", previousTextAnchor, "BOTTOMLEFT", 0, -10)
    SpotlightPanel:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)

    local headerHeight = math.max(36, SpotlightLogo:GetHeight())
    SpotlightHeader:SetHeight(headerHeight)

    local spotlightHeight =
        14
        + headerHeight
        + 8
        + GetTextHeight(SpotlightVersion, 11)
        + 7
        + GetTextHeight(SpotlightState, 11)
        + 12

    if SpotlightFocus:IsShown() then
        spotlightHeight = spotlightHeight + 8 + GetTextHeight(SpotlightFocus, 11)
    end

    SpotlightPanel:SetHeight(math.max(92, math.ceil(spotlightHeight)))
    IntroPanel:SetHeight(math.max(164, math.ceil(leftColumnHeight + 8 + spotlightHeight + 10)))
    ActionRow:SetHeight(math.max(132, math.max(GetActionCardHeight(TwitchCard), GetActionCardHeight(DiscordCard))))
    WebsiteRow:SetHeight(math.max(108, GetActionCardHeight(WebsiteCard)))

    local contentHeight = 18
        + IntroPanel:GetHeight()
        + 8 + ActionRow:GetHeight()
        + 10 + WebsiteRow:GetHeight()
        + 18

    PageHomeContent:SetHeight(contentHeight)
end

BeavisQoL.UpdateHome = function()
    IntroEyebrow:SetText(L("HOME"))
    IntroTitle:SetText(L("WELCOME_TITLE"):format(name))
    SetOptionalText(IntroSubtitle, L("WELCOME_SUBTITLE"))
    SetOptionalText(IntroText, L("WELCOME_BODY"))
    SpotlightTitle:SetText(L("HOME_SUPPORT_TITLE"))
    SpotlightVersion:SetText(L("HOME_SUPPORT_BODY"))
    SpotlightState:SetText(L("HOME_SUPPORT_HINT"))
    SetOptionalText(SpotlightFocus, L("HOME_SUPPORT_LINK"))
    ProgressCard.Title:SetText(L("PROGRESS_CARD_TITLE"))
    ProgressCard.Body:SetText(L("PROGRESS_CARD_BODY"))
    ProgressCard.Footer:SetText(L("PROGRESS_CARD_FOOTER"))
    ComfortCard.Title:SetText(L("COMFORT_CARD_TITLE"))
    ComfortCard.Body:SetText(L("COMFORT_CARD_BODY"))
    ComfortCard.Footer:SetText(L("COMFORT_CARD_FOOTER"))
    TwitchCard.Title:SetText(L("TWITCH_TITLE"))
    TwitchCard.Body:SetText(L("TWITCH_BODY"))
    TwitchCard.Footer:SetText(L("TWITCH_FOOTER"))
    DiscordCard.Title:SetText(L("HOME_FEEDBACK_TITLE"))
    DiscordCard.Body:SetText(L("HOME_FEEDBACK_BODY"))
    DiscordCard.Footer:SetText(L("HOME_FEEDBACK_FOOTER"))
    WebsiteCard.Title:SetText(L("WEBSITE_CARD_TITLE"))
    WebsiteCard.Body:SetText(L("WEBSITE_CARD_BODY"))
    WebsiteCard.Footer:SetText(L("WEBSITE_CARD_FOOTER"))
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

