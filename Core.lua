local ADDON_NAME, BeavisQoL = ...

--[[
Core.lua ist bewusst sehr klein gehalten.

Diese Datei hat nur zwei Aufgaben:
1. eine gemeinsame Sammelstelle für alle Seiten-Frames vorbereiten
2. den Slash-Command `/beavis` registrieren

Alles, was sichtbar gebaut wird, passiert später in UI.lua und den
einzelnen Seiten-Dateien.
]]

-- Hier sammeln die Seiten-Dateien ihre Frames ein.
BeavisQoL.Pages = BeavisQoL.Pages or {}

local L = BeavisQoL.L

local function GetAddonMetadataValue(metadataKey, fallbackValue)
    local metadataValue = C_AddOns.GetAddOnMetadata(ADDON_NAME, metadataKey)
    if metadataValue == nil or metadataValue == "" then
        return fallbackValue
    end

    return metadataValue
end

local function NormalizeReleaseChannel(channelName)
    local normalizedChannel = string.lower(tostring(channelName or "release"))

    if normalizedChannel == "alpha" or normalizedChannel == "beta" or normalizedChannel == "rc" or normalizedChannel == "release" then
        return normalizedChannel
    end

    return "release"
end

BeavisQoL.Metadata = BeavisQoL.Metadata or {}

local Metadata = BeavisQoL.Metadata
Metadata.name = ADDON_NAME
Metadata.title = GetAddonMetadataValue("Title", L("UNKNOWN"))
Metadata.version = GetAddonMetadataValue("Version", L("UNKNOWN"))
Metadata.author = GetAddonMetadataValue("Author", L("UNKNOWN"))
Metadata.gameVersion = GetAddonMetadataValue("X-GameVersion", L("UNKNOWN"))
Metadata.gameVersionLabel = GetAddonMetadataValue("X-GameVersionLabel", L("UNKNOWN"))
Metadata.releaseDate = GetAddonMetadataValue("X-ReleaseDate", L("UNKNOWN"))
Metadata.releaseChannel = NormalizeReleaseChannel(GetAddonMetadataValue("X-ReleaseChannel", "release"))

BeavisQoL.Title = Metadata.title
BeavisQoL.Version = Metadata.version

local RELEASE_CHANNEL_LABEL_KEYS = {
    alpha = "RELEASE_CHANNEL_ALPHA",
    beta = "RELEASE_CHANNEL_BETA",
    rc = "RELEASE_CHANNEL_RC",
    release = "RELEASE_CHANNEL_RELEASE",
}

function BeavisQoL.GetReleaseChannel()
    return Metadata.releaseChannel
end

function BeavisQoL.GetReleaseChannelLabel()
    local channelKey = RELEASE_CHANNEL_LABEL_KEYS[Metadata.releaseChannel] or RELEASE_CHANNEL_LABEL_KEYS.release
    return L(channelKey)
end

function BeavisQoL.GetReleaseStatusText()
    return L("RELEASE_STATUS_FORMAT"):format(BeavisQoL.GetReleaseChannelLabel())
end

function BeavisQoL.GetGlobalSettings()
    BeavisQoLDB = BeavisQoLDB or {}
    BeavisQoLDB.settings = BeavisQoLDB.settings or {}

    local settings = BeavisQoLDB.settings

    if settings.quickHideOverlays == nil then
        settings.quickHideOverlays = settings.hideOverlaysInCombat == true
    end

    if settings.quickHideOverlaysInCombat == nil then
        settings.quickHideOverlaysInCombat = true
    end

    if settings.quickHideChecklistOverlay == nil then
        settings.quickHideChecklistOverlay = true
    end

    if settings.quickHideWeeklyOverlay == nil then
        settings.quickHideWeeklyOverlay = true
    end

    if settings.quickHideStatsOverlay == nil then
        settings.quickHideStatsOverlay = settings.hideOverlaysInCombat == true and false or true
    end

    if settings.lockWindow == nil then
        settings.lockWindow = false
    end

    if settings.hideMinimap == nil then
        settings.hideMinimap = false
    end

    if settings.hideOverlaysInCombat == nil then
        settings.hideOverlaysInCombat = settings.quickHideOverlaysInCombat == true
    end

    return settings
end

local DEFAULT_MINIMAP_CONTEXT_MENU_ENTRY_VISIBILITY = {
    levelTime = true,
    questCheck = true,
    questAbandon = true,
    logging = true,
    checklist = true,
    weeklyKeys = true,
    stats = true,
    markerBar = true,
    streamerPlanner = true,
    easyLFG = true,
    portalViewer = true,
    quickHideOverlays = true,
}

function BeavisQoL.GetMinimapContextMenuSettings()
    local settings = BeavisQoL.GetGlobalSettings()

    if type(settings.minimapContextMenuEntries) ~= "table" then
        settings.minimapContextMenuEntries = {}
    end

    local entries = settings.minimapContextMenuEntries
    local legacyPortalViewerSettings = BeavisQoLDB and BeavisQoLDB.portalViewer

    if entries.portalViewer == nil
        and legacyPortalViewerSettings
        and legacyPortalViewerSettings.showMinimapContextMenuEntry ~= nil
    then
        entries.portalViewer = legacyPortalViewerSettings.showMinimapContextMenuEntry ~= false
    end

    for entryKey, defaultVisible in pairs(DEFAULT_MINIMAP_CONTEXT_MENU_ENTRY_VISIBILITY) do
        if entries[entryKey] == nil then
            entries[entryKey] = defaultVisible
        end
    end

    return entries
end

function BeavisQoL.IsMinimapContextMenuEntryVisible(entryKey)
    if DEFAULT_MINIMAP_CONTEXT_MENU_ENTRY_VISIBILITY[entryKey] == nil then
        return true
    end

    return BeavisQoL.GetMinimapContextMenuSettings()[entryKey] ~= false
end

function BeavisQoL.SetMinimapContextMenuEntryVisible(entryKey, visible)
    if DEFAULT_MINIMAP_CONTEXT_MENU_ENTRY_VISIBILITY[entryKey] == nil then
        return
    end

    BeavisQoL.GetMinimapContextMenuSettings()[entryKey] = visible ~= false
end

local function RefreshOverlayQuickHideState()
    if BeavisQoL.UpdateSettings then
        BeavisQoL.UpdateSettings()
    end

    if BeavisQoL.Checklist and BeavisQoL.Checklist.RefreshTrackerWindow then
        BeavisQoL.Checklist.RefreshTrackerWindow()
    end

    if BeavisQoL.WeeklyKeysModule and BeavisQoL.WeeklyKeysModule.RefreshOverlayWindow then
        BeavisQoL.WeeklyKeysModule.RefreshOverlayWindow()
    end

    if BeavisQoL.StatsModule and BeavisQoL.StatsModule.RefreshOverlayWindow then
        BeavisQoL.StatsModule.RefreshOverlayWindow()
    end
end

function BeavisQoL.GetQuickHideOverlaysEnabled()
    return BeavisQoL.GetGlobalSettings().quickHideOverlays == true
end

function BeavisQoL.SetQuickHideOverlaysEnabled(enabled)
    local settings = BeavisQoL.GetGlobalSettings()
    settings.quickHideOverlays = enabled == true
    RefreshOverlayQuickHideState()
end

function BeavisQoL.GetQuickHideOverlaysInCombat()
    return BeavisQoL.GetGlobalSettings().quickHideOverlaysInCombat == true
end

function BeavisQoL.SetQuickHideOverlaysInCombat(enabled)
    local settings = BeavisQoL.GetGlobalSettings()
    settings.quickHideOverlaysInCombat = enabled == true
    settings.hideOverlaysInCombat = settings.quickHideOverlaysInCombat
    RefreshOverlayQuickHideState()
end

function BeavisQoL.GetQuickHideOverlayEnabled(overlayKey)
    local settings = BeavisQoL.GetGlobalSettings()

    if overlayKey == "checklist" then
        return settings.quickHideChecklistOverlay == true
    end

    if overlayKey == "weekly" then
        return settings.quickHideWeeklyOverlay == true
    end

    if overlayKey == "stats" then
        return settings.quickHideStatsOverlay == true
    end

    return false
end

function BeavisQoL.SetQuickHideOverlayEnabled(overlayKey, enabled)
    local settings = BeavisQoL.GetGlobalSettings()

    if overlayKey == "checklist" then
        settings.quickHideChecklistOverlay = enabled == true
    elseif overlayKey == "weekly" then
        settings.quickHideWeeklyOverlay = enabled == true
    elseif overlayKey == "stats" then
        settings.quickHideStatsOverlay = enabled == true
    else
        return
    end

    RefreshOverlayQuickHideState()
end

function BeavisQoL.GetHideOverlaysInCombat()
    return BeavisQoL.GetQuickHideOverlaysInCombat and BeavisQoL.GetQuickHideOverlaysInCombat() == true
end

function BeavisQoL.SetHideOverlaysInCombat(enabled)
    if BeavisQoL.SetQuickHideOverlaysInCombat then
        BeavisQoL.SetQuickHideOverlaysInCombat(enabled)
    end
end

local function IsQuickHideInstanceType(instanceType)
    return instanceType == "party"
        or instanceType == "raid"
        or instanceType == "pvp"
        or instanceType == "arena"
        or instanceType == "delve"
end

local function IsInQuickHideArea()
    local instanceType

    if GetInstanceInfo then
        local _, resolvedInstanceType = GetInstanceInfo()
        if type(resolvedInstanceType) == "string" and resolvedInstanceType ~= "" and resolvedInstanceType ~= "none" then
            instanceType = resolvedInstanceType
        end
    end

    if not instanceType and IsInInstance then
        local isInInstance, resolvedInstanceType = IsInInstance()
        if isInInstance and type(resolvedInstanceType) == "string" and resolvedInstanceType ~= "" then
            instanceType = resolvedInstanceType
        end
    end

    if C_PvP and C_PvP.IsActiveBattlefield and C_PvP.IsActiveBattlefield() then
        return true
    end

    return IsQuickHideInstanceType(instanceType)
end

function BeavisQoL.ShouldHideOverlay(overlayKey)
    if not BeavisQoL.GetQuickHideOverlaysEnabled or not BeavisQoL.GetQuickHideOverlaysEnabled() then
        return false
    end

    if not BeavisQoL.GetQuickHideOverlayEnabled or not BeavisQoL.GetQuickHideOverlayEnabled(overlayKey) then
        return false
    end

    if not IsInQuickHideArea() then
        return false
    end

    if BeavisQoL.GetQuickHideOverlaysInCombat and BeavisQoL.GetQuickHideOverlaysInCombat() then
        return InCombatLockdown and InCombatLockdown() or false
    end

    return true
end

function BeavisQoL.ShouldHideOverlaysInCurrentContext()
    return BeavisQoL.ShouldHideOverlay and BeavisQoL.ShouldHideOverlay("checklist") or false
end

function BeavisQoL.RefreshLocale()
    if BeavisQoL.UpdateUI then
        BeavisQoL.UpdateUI()
    end

    if BeavisQoL.UpdateTree then
        BeavisQoL.UpdateTree()
    end

    if BeavisQoL.UpdateHome then
        BeavisQoL.UpdateHome()
    end

    if BeavisQoL.UpdateVersion then
        BeavisQoL.UpdateVersion()
    end

    if BeavisQoL.UpdateSettings then
        BeavisQoL.UpdateSettings()
    end

    if BeavisQoL.UpdateLevelTime then
        BeavisQoL.UpdateLevelTime()
    end

    if BeavisQoL.UpdateItemLevelGuide then
        BeavisQoL.UpdateItemLevelGuide()
    end

    if BeavisQoL.UpdateQuestCheck then
        BeavisQoL.UpdateQuestCheck()
    end

    if BeavisQoL.UpdateQuestAbandon then
        BeavisQoL.UpdateQuestAbandon()
    end

    if BeavisQoL.UpdateFishing then
        BeavisQoL.UpdateFishing()
    end

    if BeavisQoL.UpdateStreamerPlanner then
        BeavisQoL.UpdateStreamerPlanner()
    end

    if BeavisQoL.UpdatePortalViewer then
        BeavisQoL.UpdatePortalViewer()
    end

    local refreshablePages = {
        BeavisQoL.Pages.Misc,
        BeavisQoL.Pages.Fishing,
        BeavisQoL.Pages.StreamerPlanner,
        BeavisQoL.Pages.LFG,
        BeavisQoL.Pages.DamageText,
        BeavisQoL.Pages.Stats,
        BeavisQoL.Pages.MarkerBar,
        BeavisQoL.Pages.WeeklyKeys,
        BeavisQoL.Pages.Logging,
        BeavisQoL.Pages.Checklist,
        BeavisQoL.Pages.MouseHelper,
    }

    for _, page in ipairs(refreshablePages) do
        if page and page.RefreshState then
            page:RefreshState()
        end
    end
end

-- Initialisiere SavedVariables nach dem Laden
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == ADDON_NAME then
        BeavisQoLDB = BeavisQoLDB or {}
        BeavisQoL.GetGlobalSettings()
        BeavisQoLDB.minimap = BeavisQoLDB.minimap or {}
        BeavisQoLDB.minimap.hide = BeavisQoLDB.settings.hideMinimap or BeavisQoLDB.minimap.hide or false
        BeavisQoLCharDB = BeavisQoLCharDB or {}

        -- Aktualisiere die Settings-Checkboxen
        if BeavisQoL.UpdateSettings then
            BeavisQoL.UpdateSettings()
        end

        if BeavisQoL.RefreshLocale then
            BeavisQoL.RefreshLocale()
        end

        -- Erzwinge Minimap-Button-Status bei jedem Addon-Load:
        if BeavisQoL.MinimapIcon then
            BeavisQoL.MinimapIcon:Refresh(ADDON_NAME, BeavisQoLDB.minimap)
        end
    end
end)

-- Blizzard liest Slash-Commands über genau diese beiden Globals aus:
-- SLASH_<NAME><nummer> definiert die Befehle
-- SlashCmdList["<NAME>"] hinterlegt die Funktion dazu.
SLASH_BEAVIS1 = "/beavis"
SlashCmdList["BEAVIS"] = function(msg)
    if BeavisQoL.HandleSlashCommand and BeavisQoL.HandleSlashCommand(msg) then
        return
    end

    -- Der Slash-Command macht nur das Fenster auf und zu. Alles andere läuft über die UI.
    -- `msg` wäre der Text hinter `/beavis`, wird aktuell aber noch nicht gebraucht.
    if not BeavisQoL.Frame then
        return
    end

    if BeavisQoL.Frame:IsShown() then
        BeavisQoL.Frame:Hide()
    else
        BeavisQoL.Frame:Show()
    end
end
