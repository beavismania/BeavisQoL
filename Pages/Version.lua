local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content
local L = BeavisQoL.L
local metadata = BeavisQoL.Metadata or {}

--[[
Diese Seite hat zwei Rollen:
1. feste Informationen zur lokal installierten Version anzeigen
2. per Addon-Chat mit anderen Spielern abgleichen, ob irgendwo schon eine
    höhere BeavisQoL-Version gesehen wurde

Wichtig dabei: Es gibt keine direkte GitHub-Abfrage aus WoW heraus.
Der Versionsvergleich funktioniert rein über Spieler, die dieselbe
Versionsnachricht im Spiel austauschen.
]]

local addonTitle = metadata.title or C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title") or ADDON_NAME
local addonVersion = metadata.version or C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or L("UNKNOWN")
local addonAuthor = metadata.author or C_AddOns.GetAddOnMetadata(ADDON_NAME, "Author") or L("UNKNOWN")
local addonGameVersion = metadata.gameVersion or C_AddOns.GetAddOnMetadata(ADDON_NAME, "X-GameVersion") or L("UNKNOWN")
local addonGameVersionLabel = metadata.gameVersionLabel or C_AddOns.GetAddOnMetadata(ADDON_NAME, "X-GameVersionLabel") or L("UNKNOWN")
local addonReleaseDate = metadata.releaseDate or C_AddOns.GetAddOnMetadata(ADDON_NAME, "X-ReleaseDate") or L("UNKNOWN")

local WEBSITE_URL = "https://www.beavismania.de"
local RELEASES_URL = "https://github.com/beavismania/BeavisQoL/releases"
local VERSION_PREFIX = "BEAVISQOLVER"
local VERSION_QUERY = "QUERY"
local VERSION_REPLY = "VERSION"

BeavisQoL.VersionCheck = BeavisQoL.VersionCheck or {}
local VersionCheck = BeavisQoL.VersionCheck

VersionCheck.currentVersion = addonVersion
VersionCheck.currentReleaseDate = addonReleaseDate
VersionCheck.hasNewerVersion = VersionCheck.hasNewerVersion or false
VersionCheck.newerVersion = VersionCheck.newerVersion or nil
VersionCheck.newerReleaseDate = VersionCheck.newerReleaseDate or nil
VersionCheck.newerSender = VersionCheck.newerSender or nil
VersionCheck.newerChannel = VersionCheck.newerChannel or nil
VersionCheck.lastQueryAt = VersionCheck.lastQueryAt or 0
VersionCheck.queryPending = false

local function GetShortName(name)
    if not name or name == "" then
        return L("UNKNOWN")
    end

    if Ambiguate then
        return Ambiguate(name, "short")
    end

    return name
end

local function GetPlayerFullName()
    local playerName, realmName = UnitFullName("player")
    if not playerName or playerName == "" then
        return nil
    end

    if realmName and realmName ~= "" then
        return playerName .. "-" .. realmName
    end

    return playerName
end

local function ParseReleaseDateToNumber(releaseDateText)
    local year, month, day = string.match(releaseDateText or "", "^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
    if not year then
        return 0
    end

    return tonumber(year .. month .. day) or 0
end

local function ParseVersionTuple(versionText)
    -- Wir zerlegen Versionsstrings defensiv.
    -- Damit funktionieren sowohl "0.0.2 Alpha" als auch weniger sauber
    -- formatierte Strings mit Zahlen plus Stufe.
    local major, minor, patch = string.match(versionText or "", "(%d+)%.(%d+)%.(%d+)")

    if not major then
        local foundNumbers = {}

        for value in string.gmatch(versionText or "", "(%d+)") do
            foundNumbers[#foundNumbers + 1] = tonumber(value) or 0
            if #foundNumbers == 3 then
                break
            end
        end

        major = foundNumbers[1] or 0
        minor = foundNumbers[2] or 0
        patch = foundNumbers[3] or 0
    else
        major = tonumber(major) or 0
        minor = tonumber(minor) or 0
        patch = tonumber(patch) or 0
    end

    local stageWeight = 4
    local loweredVersionText = string.lower(versionText or "")

    if string.find(loweredVersionText, "alpha", 1, true) then
        stageWeight = 1
    elseif string.find(loweredVersionText, "beta", 1, true) then
        stageWeight = 2
    elseif string.find(loweredVersionText, "rc", 1, true) or string.find(loweredVersionText, "release candidate", 1, true) then
        stageWeight = 3
    end

    return major, minor, patch, stageWeight
end

local function CompareVersionInfo(versionAText, releaseDateAText, versionBText, releaseDateBText)
    -- Rueckgabewert:
    -- -1 = A ist aelter als B
    --  0 = beide gleich
    --  1 = A ist neuer als B
    local majorA, minorA, patchA, stageA = ParseVersionTuple(versionAText)
    local majorB, minorB, patchB, stageB = ParseVersionTuple(versionBText)

    if majorA ~= majorB then
        return majorA < majorB and -1 or 1
    end

    if minorA ~= minorB then
        return minorA < minorB and -1 or 1
    end

    if patchA ~= patchB then
        return patchA < patchB and -1 or 1
    end

    if stageA ~= stageB then
        return stageA < stageB and -1 or 1
    end

    local releaseDateA = ParseReleaseDateToNumber(releaseDateAText)
    local releaseDateB = ParseReleaseDateToNumber(releaseDateBText)

    if releaseDateA ~= releaseDateB then
        return releaseDateA < releaseDateB and -1 or 1
    end

    local versionStringA = tostring(versionAText or "")
    local versionStringB = tostring(versionBText or "")

    if versionStringA == versionStringB then
        return 0
    end

    return versionStringA < versionStringB and -1 or 1
end

local function IsRemoteVersionNewer(remoteVersionText, remoteReleaseDateText)
    return CompareVersionInfo(addonVersion, addonReleaseDate, remoteVersionText, remoteReleaseDateText) < 0
end

local function IsRemoteVersionNewerThanKnown(remoteVersionText, remoteReleaseDateText)
    if not VersionCheck.newerVersion then
        return true
    end

    return CompareVersionInfo(VersionCheck.newerVersion, VersionCheck.newerReleaseDate, remoteVersionText, remoteReleaseDateText) < 0
end

local function GetVersionChannels()
    -- Wir fragen nur Kanaele an, in denen der Spieler gerade wirklich ist.
    -- So vermeiden wir unnoetige Addon-Nachrichten.
    local channels = {}
    local seenChannels = {}

    local function AddChannel(channelName)
        if channelName and not seenChannels[channelName] then
            seenChannels[channelName] = true
            channels[#channels + 1] = channelName
        end
    end

    if LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        AddChannel("INSTANCE_CHAT")
    elseif IsInRaid() then
        AddChannel("RAID")
    elseif IsInGroup() then
        AddChannel("PARTY")
    end

    if IsInGuild and IsInGuild() then
        AddChannel("GUILD")
    end

    return channels
end

local function SendVersionMessage(channelName, messageType)
    -- Das Nachrichtenformat bleibt bewusst simpel:
    -- TYP <tab> VERSION <tab> RELEASEDATUM
    if not C_ChatInfo or not C_ChatInfo.SendAddonMessage or not channelName then
        return
    end

    local message = table.concat({
        messageType,
        addonVersion,
        addonReleaseDate,
    }, "\t")

    C_ChatInfo.SendAddonMessage(VERSION_PREFIX, message, channelName)
end

local PageVersion = CreateFrame("Frame", nil, Content)
PageVersion:SetAllPoints()
PageVersion:Hide()

local UpdateStatusValue
local UpdateStatusText
local UpdateStatusSubText

function PageVersion:RefreshVersionStatus()
    -- Diese Methode schreibt den kompletten UI-Zustand für den Versionsblock
    -- jedes Mal neu. So bleibt die Seite stabil, egal ob wir gerade frisch
    -- geladen haben oder später eine neuere Version entdeckt wurde.
    if VersionCheck.hasNewerVersion then
        UpdateStatusValue:SetText(L("VERSION_CHECK_AVAILABLE"):format(tostring(VersionCheck.newerVersion or L("UNKNOWN"))))
        UpdateStatusValue:SetTextColor(1, 0.82, 0, 1)
        UpdateStatusText:SetText(L("VERSION_CHECK_SEEN_AT"):format(GetShortName(VersionCheck.newerSender), tostring(VersionCheck.newerChannel or L("VERSION_CHECK_CHANNEL")), addonVersion))
        UpdateStatusSubText:SetText(L("VERSION_CHECK_HINT"))
    else
        UpdateStatusValue:SetText(L("VERSION_CHECK_CURRENT"))
        UpdateStatusValue:SetTextColor(0.45, 0.90, 0.45, 1)
        UpdateStatusText:SetText(L("VERSION_CHECK_CURRENT_TEXT"))
        UpdateStatusSubText:SetText(L("VERSION_CHECK_CURRENT_SUBTEXT"):format(addonVersion, tostring(addonReleaseDate)))
    end
end

local function RefreshVersionPageIfVisible()
    if PageVersion:IsShown() then
        PageVersion:RefreshVersionStatus()
    end
end

local function RememberNewerVersion(remoteVersionText, remoteReleaseDateText, senderName, channelName)
    -- Wir merken uns nur echte Verbesserungen:
    -- erst gegen unsere lokale Version prüfen, dann gegen den bereits
    -- gemerkten besten Fund.
    if not IsRemoteVersionNewer(remoteVersionText, remoteReleaseDateText) then
        return
    end

    if not IsRemoteVersionNewerThanKnown(remoteVersionText, remoteReleaseDateText) then
        return
    end

    VersionCheck.hasNewerVersion = true
    VersionCheck.newerVersion = remoteVersionText
    VersionCheck.newerReleaseDate = remoteReleaseDateText
    VersionCheck.newerSender = senderName
    VersionCheck.newerChannel = channelName

    RefreshVersionPageIfVisible()
end

local function QueryForVersions(forceRefresh)
    -- Kleine Anti-Spam-Sperre, damit Gruppenwechsel oder Seitenwechsel nicht
    -- sofort mehrere identische Queries hintereinander schicken.
    local now = GetTime and GetTime() or 0
    if not forceRefresh and (now - (VersionCheck.lastQueryAt or 0)) < 8 then
        return
    end

    VersionCheck.lastQueryAt = now

    for _, channelName in ipairs(GetVersionChannels()) do
        SendVersionMessage(channelName, VERSION_QUERY)
    end
end

local function ScheduleVersionQuery(delaySeconds, forceRefresh)
    if VersionCheck.queryPending then
        return
    end

    VersionCheck.queryPending = true

    if C_Timer and C_Timer.After then
        C_Timer.After(delaySeconds or 0, function()
            VersionCheck.queryPending = false
            QueryForVersions(forceRefresh)
        end)
    else
        VersionCheck.queryPending = false
        QueryForVersions(forceRefresh)
    end
end

local function HandleVersionAddonMessage(prefix, message, distribution, senderName)
    -- Eigene Antworten ignorieren wir, sonst wuerden wir unsere lokale Version
    -- als "fremde" Rueckmeldung verarbeiten.
    if prefix ~= VERSION_PREFIX or not message or message == "" then
        return
    end

    local playerFullName = GetPlayerFullName()
    if playerFullName and (senderName == playerFullName or GetShortName(senderName) == GetShortName(playerFullName)) then
        return
    end

    local messageType, remoteVersionText, remoteReleaseDateText = strsplit("\t", message)

    if messageType == VERSION_QUERY then
        SendVersionMessage(distribution, VERSION_REPLY)
        return
    end

    if messageType ~= VERSION_REPLY then
        return
    end

    RememberNewerVersion(remoteVersionText, remoteReleaseDateText, senderName, distribution)
end

local VersionSyncFrame = CreateFrame("Frame")
VersionSyncFrame:RegisterEvent("PLAYER_LOGIN")
VersionSyncFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
VersionSyncFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
VersionSyncFrame:RegisterEvent("PLAYER_GUILD_UPDATE")
VersionSyncFrame:RegisterEvent("CHAT_MSG_ADDON")
VersionSyncFrame:SetScript("OnEvent", function(_, eventName, ...)
    if eventName == "PLAYER_LOGIN" then
        if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
            C_ChatInfo.RegisterAddonMessagePrefix(VERSION_PREFIX)
        end

        ScheduleVersionQuery(6, true)
        return
    end

    if eventName == "PLAYER_ENTERING_WORLD" or eventName == "GROUP_ROSTER_UPDATE" or eventName == "PLAYER_GUILD_UPDATE" then
        ScheduleVersionQuery(2, false)
        return
    end

    if eventName == "CHAT_MSG_ADDON" then
        HandleVersionAddonMessage(...)
    end
end)

local function ShowExternalLink(titleText, urlText)
    if BeavisQoL.ShowLinkPopup then
        BeavisQoL.ShowLinkPopup(titleText, urlText)
        return
    end

    if not urlText or urlText == "" then
        return
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
IntroTitle:SetText(L("VERSIONS_INFO_TITLE"):format(addonTitle))

local IntroText = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroText:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -10)
IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
IntroText:SetJustifyH("LEFT")
IntroText:SetJustifyV("TOP")
IntroText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroText:SetTextColor(1, 1, 1, 1)
IntroText:SetText(L("VERSIONS_INFO_DESC"))

-- ========================================
-- Info-Karten
-- ========================================

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
VersionLabel:SetText(L("CURRENT_VERSION"))

local VersionValue = VersionCard:CreateFontString(nil, "OVERLAY")
VersionValue:SetPoint("TOPLEFT", VersionLabel, "BOTTOMLEFT", 0, -8)
VersionValue:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
VersionValue:SetTextColor(1, 0.82, 0, 1)
VersionValue:SetText(addonVersion)

local VersionSubValue = VersionCard:CreateFontString(nil, "OVERLAY")
VersionSubValue:SetPoint("TOPLEFT", VersionValue, "BOTTOMLEFT", 0, -4)
VersionSubValue:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
VersionSubValue:SetTextColor(0.75, 0.75, 0.75, 1)
VersionSubValue:SetText(L("RELEASE_DATE") .. ": " .. tostring(addonReleaseDate))

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
AuthorLabel:SetText(L("PROGRAMMER"))

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
InterfaceLabel:SetText(L("SUPPORTED_GAME_VERSION"))

local InterfaceValue = InterfaceCard:CreateFontString(nil, "OVERLAY")
InterfaceValue:SetPoint("TOPLEFT", InterfaceLabel, "BOTTOMLEFT", 0, -8)
InterfaceValue:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
InterfaceValue:SetTextColor(1, 0.82, 0, 1)
InterfaceValue:SetText(addonGameVersionLabel)

local InterfaceSubValue = InterfaceCard:CreateFontString(nil, "OVERLAY")
InterfaceSubValue:SetPoint("TOPLEFT", InterfaceValue, "BOTTOMLEFT", 0, -4)
InterfaceSubValue:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
InterfaceSubValue:SetTextColor(0.75, 0.75, 0.75, 1)
InterfaceSubValue:SetText(L("TOC_VERSION") .. ": " .. tostring(addonGameVersion))

-- ========================================
-- Versionsabgleich
-- ========================================

local UpdatePanel = CreateFrame("Frame", nil, PageVersion)
UpdatePanel:SetPoint("TOPLEFT", InfoRow, "BOTTOMLEFT", 0, -18)
UpdatePanel:SetPoint("TOPRIGHT", InfoRow, "BOTTOMRIGHT", 0, -18)
UpdatePanel:SetHeight(150)

local UpdateBg = UpdatePanel:CreateTexture(nil, "BACKGROUND")
UpdateBg:SetAllPoints()
UpdateBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local UpdateBorder = UpdatePanel:CreateTexture(nil, "ARTWORK")
UpdateBorder:SetPoint("BOTTOMLEFT", UpdatePanel, "BOTTOMLEFT", 0, 0)
UpdateBorder:SetPoint("BOTTOMRIGHT", UpdatePanel, "BOTTOMRIGHT", 0, 0)
UpdateBorder:SetHeight(1)
UpdateBorder:SetColorTexture(1, 0.82, 0, 0.9)

local UpdateTitle = UpdatePanel:CreateFontString(nil, "OVERLAY")
UpdateTitle:SetPoint("TOPLEFT", UpdatePanel, "TOPLEFT", 18, -14)
UpdateTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
UpdateTitle:SetTextColor(1, 0.82, 0, 1)
UpdateTitle:SetText(L("VERSION_CHECK"))

UpdateStatusValue = UpdatePanel:CreateFontString(nil, "OVERLAY")
UpdateStatusValue:SetPoint("TOPLEFT", UpdateTitle, "BOTTOMLEFT", 0, -12)
UpdateStatusValue:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
UpdateStatusValue:SetTextColor(0.45, 0.90, 0.45, 1)

UpdateStatusText = UpdatePanel:CreateFontString(nil, "OVERLAY")
UpdateStatusText:SetPoint("TOPLEFT", UpdateStatusValue, "BOTTOMLEFT", 0, -8)
UpdateStatusText:SetPoint("RIGHT", UpdatePanel, "RIGHT", -18, 0)
UpdateStatusText:SetJustifyH("LEFT")
UpdateStatusText:SetJustifyV("TOP")
UpdateStatusText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
UpdateStatusText:SetTextColor(1, 1, 1, 1)

UpdateStatusSubText = UpdatePanel:CreateFontString(nil, "OVERLAY")
UpdateStatusSubText:SetPoint("TOPLEFT", UpdateStatusText, "BOTTOMLEFT", 0, -8)
UpdateStatusSubText:SetPoint("RIGHT", UpdatePanel, "RIGHT", -18, 0)
UpdateStatusSubText:SetJustifyH("LEFT")
UpdateStatusSubText:SetJustifyV("TOP")
UpdateStatusSubText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
UpdateStatusSubText:SetTextColor(0.75, 0.75, 0.75, 1)

local RefreshVersionsButton = CreateFrame("Button", nil, UpdatePanel, "UIPanelButtonTemplate")
RefreshVersionsButton:SetSize(150, 28)
RefreshVersionsButton:SetPoint("BOTTOMLEFT", UpdatePanel, "BOTTOMLEFT", 18, 16)
RefreshVersionsButton:SetText(L("VERSION_COMPARE_NOW"))
RefreshVersionsButton:SetScript("OnClick", function()
    QueryForVersions(true)
    PageVersion:RefreshVersionStatus()
end)

local ReleasesButton = CreateFrame("Button", nil, UpdatePanel, "UIPanelButtonTemplate")
ReleasesButton:SetSize(150, 28)
ReleasesButton:SetPoint("LEFT", RefreshVersionsButton, "RIGHT", 12, 0)
ReleasesButton:SetText(L("VERSION_RELEASE_LINK"))
ReleasesButton:SetScript("OnClick", function()
    ShowExternalLink(L("RELEASES_POPUP"), RELEASES_URL)
end)

-- ========================================
-- Aktionsbereich
-- ========================================

local ActionPanel = CreateFrame("Frame", nil, PageVersion)
ActionPanel:SetPoint("TOPLEFT", UpdatePanel, "BOTTOMLEFT", 0, -18)
ActionPanel:SetPoint("TOPRIGHT", UpdatePanel, "BOTTOMRIGHT", 0, -18)
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
ActionTitle:SetText(L("CONTACT_TITLE"))

local ActionText = ActionPanel:CreateFontString(nil, "OVERLAY")
ActionText:SetPoint("TOPLEFT", ActionTitle, "BOTTOMLEFT", 0, -10)
ActionText:SetPoint("RIGHT", ActionPanel, "RIGHT", -18, 0)
ActionText:SetJustifyH("LEFT")
ActionText:SetJustifyV("TOP")
ActionText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
ActionText:SetTextColor(1, 1, 1, 1)
ActionText:SetText(L("CONTACT_TEXT"))

local FeedbackButton = CreateFrame("Button", nil, ActionPanel, "UIPanelButtonTemplate")
FeedbackButton:SetSize(180, 30)
FeedbackButton:SetPoint("BOTTOMLEFT", ActionPanel, "BOTTOMLEFT", 18, 18)
FeedbackButton:SetText(L("SEND_FEEDBACK"))
FeedbackButton:SetScript("OnClick", function()
    ShowExternalLink(L("FEEDBACK_POPUP"), WEBSITE_URL)
end)

local IdeaButton = CreateFrame("Button", nil, ActionPanel, "UIPanelButtonTemplate")
IdeaButton:SetSize(180, 30)
IdeaButton:SetPoint("LEFT", FeedbackButton, "RIGHT", 14, 0)
IdeaButton:SetText(L("SUBMIT_IDEA"))
IdeaButton:SetScript("OnClick", function()
    ShowExternalLink(L("IDEA_POPUP"), WEBSITE_URL)
end)

local WebsiteHint = ActionPanel:CreateFontString(nil, "OVERLAY")
WebsiteHint:SetPoint("LEFT", IdeaButton, "RIGHT", 18, 0)
WebsiteHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
WebsiteHint:SetTextColor(0.85, 0.85, 0.85, 1)
WebsiteHint:SetText("www.beavismania.de")

BeavisQoL.UpdateVersion = function()
    IntroTitle:SetText(L("VERSIONS_INFO_TITLE"):format(addonTitle))
    IntroText:SetText(L("VERSIONS_INFO_DESC"))
    VersionLabel:SetText(L("CURRENT_VERSION"))
    VersionSubValue:SetText(L("RELEASE_DATE") .. ": " .. tostring(addonReleaseDate))
    AuthorLabel:SetText(L("PROGRAMMER"))
    InterfaceLabel:SetText(L("SUPPORTED_GAME_VERSION"))
    InterfaceSubValue:SetText(L("TOC_VERSION") .. ": " .. tostring(addonGameVersion))
    UpdateTitle:SetText(L("VERSION_CHECK"))
    RefreshVersionsButton:SetText(L("VERSION_COMPARE_NOW"))
    ReleasesButton:SetText(L("VERSION_RELEASE_LINK"))
    ActionTitle:SetText(L("CONTACT_TITLE"))
    ActionText:SetText(L("CONTACT_TEXT"))
    FeedbackButton:SetText(L("SEND_FEEDBACK"))
    IdeaButton:SetText(L("SUBMIT_IDEA"))
    PageVersion:RefreshVersionStatus()
end

PageVersion:SetScript("OnShow", function()
    PageVersion:RefreshVersionStatus()
    ScheduleVersionQuery(0.5, true)
end)

PageVersion:RefreshVersionStatus()

BeavisQoL.Pages.Version = PageVersion
