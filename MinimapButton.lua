local ADDON_NAME, BeavisQoL = ...

--[[
MinimapButton.lua verbindet das Addon mit dem kleinen Symbol an der Minimap.

Wichtig:
1. LibDataBroker erstellt das Datenobjekt (also das, was "angeboten" wird)
2. LibDBIcon zeigt dieses Objekt als Minimap-Button an
3. Linksklick, Rechtsklick und Shift-Klick landen alle in derselben Datei,
   damit sich das Verhalten an einer Stelle pflegen laesst
]]

-- Die beiden LDB-Bibliotheken sind die Grundlage für den Minimap-Button.
local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)
local L = BeavisQoL.L
local MenuUtil = _G.MenuUtil
local EasyMenu = rawget(_G, "EasyMenu")
local CloseDropDownMenus = rawget(_G, "CloseDropDownMenus")
local MinimapContextMenu

-- Ohne beide Libraries gibt es hier nichts zu tun.
if not LDB or not LDBIcon then
    return
end

local addonTitle = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title") or ADDON_NAME

-- Position und Sichtbarkeit sollen zwischen Sessions erhalten bleiben.
-- Genau diese Struktur erwartet LibDBIcon später für sein internes Speichern.
BeavisQoLDB = BeavisQoLDB or {}
BeavisQoLDB.minimap = BeavisQoLDB.minimap or {}
-- settings sollte den primären Source of Truth liefern (falls vorhanden)
BeavisQoLDB.minimap.hide = (BeavisQoLDB.settings and BeavisQoLDB.settings.hideMinimap) or BeavisQoLDB.minimap.hide or false

-- Slash-Command und Minimap-Button sollen sich gleich verhalten.
local function ToggleMainWindow()
    -- Derselbe Helfer wird auch vom Slash-Command sinngemaess genutzt:
    -- einmal klicken = Fenster zeigen oder wieder verstecken.
    if not BeavisQoL.Frame then
        return
    end

    if BeavisQoL.Frame:IsShown() then
        BeavisQoL.Frame:Hide()
    else
        BeavisQoL.Frame:Show()
    end
end

local function OpenAddonPage(pageKey)
    -- Bevorzugt den zentralen Tree-Helfer.
    -- Der Fallback darunter ist nur dafür da, dass der Minimap-Button nicht
    -- plötzlich nutzlos wird, falls der Tree einmal noch nicht bereit ist.
    if BeavisQoL.OpenPage then
        BeavisQoL.OpenPage(pageKey)
        return
    end

    if not BeavisQoL.Frame then
        return
    end

    if not BeavisQoL.Frame:IsShown() then
        BeavisQoL.Frame:Show()
    end

    if not BeavisQoL.Pages then
        return
    end

    for _, page in pairs(BeavisQoL.Pages) do
        page:Hide()
    end

    if BeavisQoL.Pages[pageKey] then
        BeavisQoL.Pages[pageKey]:Show()
    end
end

local function IsChecklistTrackerEnabled()
    local checklist = BeavisQoL.Checklist
    return checklist and checklist.IsTrackerEnabled and checklist.IsTrackerEnabled() == true
end

local function ToggleChecklistTracker()
    local checklist = BeavisQoL.Checklist
    if not checklist or not checklist.IsTrackerEnabled or not checklist.SetTrackerEnabled then
        return
    end

    checklist.SetTrackerEnabled(not checklist.IsTrackerEnabled())
end

local function IsStatsOverlayEnabled()
    local statsModule = BeavisQoL.StatsModule
    return statsModule and statsModule.IsOverlayEnabled and statsModule.IsOverlayEnabled() == true
end

local function ToggleStatsOverlay()
    local statsModule = BeavisQoL.StatsModule
    if not statsModule or not statsModule.IsOverlayEnabled or not statsModule.SetOverlayEnabled then
        return
    end

    statsModule.SetOverlayEnabled(not statsModule.IsOverlayEnabled())
end

local function IsWeeklyKeysOverlayEnabled()
    local weeklyKeysModule = BeavisQoL.WeeklyKeysModule
    return weeklyKeysModule and weeklyKeysModule.IsOverlayEnabled and weeklyKeysModule.IsOverlayEnabled() == true
end

local function ToggleWeeklyKeysOverlay()
    local weeklyKeysModule = BeavisQoL.WeeklyKeysModule
    if not weeklyKeysModule or not weeklyKeysModule.IsOverlayEnabled or not weeklyKeysModule.SetOverlayEnabled then
        return
    end

    weeklyKeysModule.SetOverlayEnabled(not weeklyKeysModule.IsOverlayEnabled())
end

local function IsMarkerBarOverlayEnabled()
    local markerBarModule = BeavisQoL.MarkerBarModule
    return markerBarModule and markerBarModule.IsOverlayEnabled and markerBarModule.IsOverlayEnabled() == true
end

local function IsStreamerPlannerOverlayEnabled()
    local streamerPlannerModule = BeavisQoL.StreamerPlannerModule
    return streamerPlannerModule and streamerPlannerModule.IsOverlayEnabled and streamerPlannerModule.IsOverlayEnabled() == true
end

local function IsEasyLFGOverlayEnabled()
    local lfgModule = BeavisQoL.LFG
    return lfgModule and lfgModule.IsEasyLFGEnabled and lfgModule.IsEasyLFGEnabled() == true
end

local function IsPortalViewerEnabled()
    local portalViewerModule = BeavisQoL.PortalViewerModule
    return portalViewerModule and portalViewerModule.IsWindowEnabled and portalViewerModule.IsWindowEnabled() == true
end

local function ToggleMarkerBarOverlay()
    local markerBarModule = BeavisQoL.MarkerBarModule
    if not markerBarModule or not markerBarModule.IsOverlayEnabled or not markerBarModule.SetOverlayEnabled then
        return
    end

    markerBarModule.SetOverlayEnabled(not markerBarModule.IsOverlayEnabled())

    if BeavisQoL.Pages and BeavisQoL.Pages.MarkerBar and BeavisQoL.Pages.MarkerBar.RefreshState then
        BeavisQoL.Pages.MarkerBar:RefreshState()
    end
end

local function ToggleStreamerPlannerOverlay()
    local streamerPlannerModule = BeavisQoL.StreamerPlannerModule
    if not streamerPlannerModule or not streamerPlannerModule.IsOverlayEnabled or not streamerPlannerModule.SetOverlayEnabled then
        return
    end

    streamerPlannerModule.SetOverlayEnabled(not streamerPlannerModule.IsOverlayEnabled())

    if BeavisQoL.Pages and BeavisQoL.Pages.StreamerPlanner and BeavisQoL.Pages.StreamerPlanner.RefreshState then
        BeavisQoL.Pages.StreamerPlanner:RefreshState()
    end
end

local function ToggleEasyLFGOverlay()
    local lfgModule = BeavisQoL.LFG
    if not lfgModule or not lfgModule.IsEasyLFGEnabled or not lfgModule.SetEasyLFGEnabled then
        return
    end

    lfgModule.SetEasyLFGEnabled(not lfgModule.IsEasyLFGEnabled())

    if BeavisQoL.Pages and BeavisQoL.Pages.LFG and BeavisQoL.Pages.LFG.RefreshState then
        BeavisQoL.Pages.LFG:RefreshState()
    end
end

local function TogglePortalViewer()
    local portalViewerModule = BeavisQoL.PortalViewerModule
    if not portalViewerModule or not portalViewerModule.ToggleWindow then
        return
    end

    portalViewerModule.ToggleWindow()
end

local function GetQuickHideOverlaysEnabled()
    return BeavisQoL.GetQuickHideOverlaysEnabled and BeavisQoL.GetQuickHideOverlaysEnabled() == true
end

local function ToggleQuickHideOverlays()
    if not BeavisQoL.SetQuickHideOverlaysEnabled then
        return
    end

    BeavisQoL.SetQuickHideOverlaysEnabled(not GetQuickHideOverlaysEnabled())
end

local function IsMinimapContextEntryVisible(entryKey)
    if not BeavisQoL.IsMinimapContextMenuEntryVisible then
        return true
    end

    return BeavisQoL.IsMinimapContextMenuEntryVisible(entryKey)
end

local function EnsureContextMenuSupport()
    -- Das alte Dropdown-Menü ist in manchen Clients nicht sofort geladen.
    -- Diese Funktion zieht Blizzard_UIDropDownMenu nur bei Bedarf nach.
    if not EasyMenu or not CloseDropDownMenus or not rawget(_G, "UIDropDownMenuTemplate") then
        if C_AddOns and C_AddOns.LoadAddOn then
            C_AddOns.LoadAddOn("Blizzard_UIDropDownMenu")
        elseif UIParentLoadAddOn then
            UIParentLoadAddOn("Blizzard_UIDropDownMenu")
        end

        EasyMenu = rawget(_G, "EasyMenu")
        CloseDropDownMenus = rawget(_G, "CloseDropDownMenus")
    end

    if not EasyMenu or not CloseDropDownMenus or not rawget(_G, "UIDropDownMenuTemplate") then
        return false
    end

    if not MinimapContextMenu then
        MinimapContextMenu = CreateFrame("Frame", "BeavisQoLMinimapContextMenu", UIParent, "UIDropDownMenuTemplate")
    end

    return MinimapContextMenu ~= nil
end

local function ShowMinimapContextMenu(anchorFrame)
    -- Zuerst versuchen wir das moderne Blizzard-Menüsystem zu nutzen.
    -- Falls das im Client nicht vorhanden ist, fällt der Code darunter sauber
    -- auf das ältere EasyMenu zurück.
    MenuUtil = _G.MenuUtil
    local hasChecklistToggle = BeavisQoL.Checklist and BeavisQoL.Checklist.IsTrackerEnabled and BeavisQoL.Checklist.SetTrackerEnabled
    local hasStatsToggle = BeavisQoL.StatsModule and BeavisQoL.StatsModule.IsOverlayEnabled and BeavisQoL.StatsModule.SetOverlayEnabled
    local hasWeeklyKeysToggle = BeavisQoL.WeeklyKeysModule and BeavisQoL.WeeklyKeysModule.IsOverlayEnabled and BeavisQoL.WeeklyKeysModule.SetOverlayEnabled
    local hasMarkerBarToggle = BeavisQoL.MarkerBarModule and BeavisQoL.MarkerBarModule.IsOverlayEnabled and BeavisQoL.MarkerBarModule.SetOverlayEnabled
    local hasStreamerPlannerToggle = BeavisQoL.StreamerPlannerModule and BeavisQoL.StreamerPlannerModule.IsOverlayEnabled and BeavisQoL.StreamerPlannerModule.SetOverlayEnabled
    local hasEasyLFGToggle = BeavisQoL.LFG and BeavisQoL.LFG.IsEasyLFGEnabled and BeavisQoL.LFG.SetEasyLFGEnabled
    local hasPortalViewerToggle = BeavisQoL.PortalViewerModule and BeavisQoL.PortalViewerModule.IsWindowEnabled and BeavisQoL.PortalViewerModule.SetWindowEnabled
    local showLevelTimeEntry = IsMinimapContextEntryVisible("levelTime")
    local showQuestCheckEntry = IsMinimapContextEntryVisible("questCheck")
    local showQuestAbandonEntry = IsMinimapContextEntryVisible("questAbandon")
    local showLoggingEntry = IsMinimapContextEntryVisible("logging")
    local showChecklistEntry = IsMinimapContextEntryVisible("checklist")
    local showWeeklyKeysEntry = IsMinimapContextEntryVisible("weeklyKeys")
    local showStatsEntry = IsMinimapContextEntryVisible("stats")
    local showMarkerBarEntry = IsMinimapContextEntryVisible("markerBar")
    local showStreamerPlannerEntry = IsMinimapContextEntryVisible("streamerPlanner")
    local showEasyLFGEntry = IsMinimapContextEntryVisible("easyLFG")
    local showPortalViewerEntry = IsMinimapContextEntryVisible("portalViewer")
    local showQuickHideEntry = IsMinimapContextEntryVisible("quickHideOverlays")

    if MenuUtil and MenuUtil.CreateContextMenu then
        MenuUtil.CreateContextMenu(anchorFrame or UIParent, function(_, rootDescription)
            rootDescription:CreateTitle(addonTitle)
            rootDescription:CreateDivider()
            if showLevelTimeEntry then
                rootDescription:CreateButton(L("LEVEL_TIME"), function()
                    OpenAddonPage("LevelTime")
                end)
            end

            if showQuestCheckEntry then
                rootDescription:CreateButton(L("QUEST_CHECK"), function()
                    OpenAddonPage("QuestCheck")
                end)
            end

            if showQuestAbandonEntry then
                rootDescription:CreateButton(L("QUEST_ABANDON"), function()
                    OpenAddonPage("QuestAbandon")
                end)
            end

            if showLoggingEntry then
                rootDescription:CreateButton(L("LOGGING"), function()
                    OpenAddonPage("Logging")
                end)
            end

            if hasChecklistToggle and showChecklistEntry then
                rootDescription:CreateCheckbox(
                    L("MINIMAP_TRACKER_SHOW"),
                    function()
                        return IsChecklistTrackerEnabled()
                    end,
                    function()
                        ToggleChecklistTracker()
                    end
                )
            end

            if hasWeeklyKeysToggle and showWeeklyKeysEntry then
                rootDescription:CreateCheckbox(
                    L("MINIMAP_WEEKLY_KEYS_SHOW"),
                    function()
                        return IsWeeklyKeysOverlayEnabled()
                    end,
                    function()
                        ToggleWeeklyKeysOverlay()
                    end
                )
            end

            if hasStatsToggle and showStatsEntry then
                rootDescription:CreateCheckbox(
                    L("MINIMAP_STATS_SHOW"),
                    function()
                        return IsStatsOverlayEnabled()
                    end,
                    function()
                        ToggleStatsOverlay()
                    end
                )
            end

            if hasMarkerBarToggle and showMarkerBarEntry then
                rootDescription:CreateCheckbox(
                    L("MINIMAP_MARKER_BAR_SHOW"),
                    function()
                        return IsMarkerBarOverlayEnabled()
                    end,
                    function()
                        ToggleMarkerBarOverlay()
                    end
                )
            end

            if hasStreamerPlannerToggle and showStreamerPlannerEntry then
                rootDescription:CreateCheckbox(
                    L("MINIMAP_STREAMER_PLANNER_SHOW"),
                    function()
                        return IsStreamerPlannerOverlayEnabled()
                    end,
                    function()
                        ToggleStreamerPlannerOverlay()
                    end
                )
            end

            if hasEasyLFGToggle and showEasyLFGEntry then
                rootDescription:CreateCheckbox(
                    L("MINIMAP_EASY_LFG_SHOW"),
                    function()
                        return IsEasyLFGOverlayEnabled()
                    end,
                    function()
                        ToggleEasyLFGOverlay()
                    end
                )
            end

            if hasPortalViewerToggle and showPortalViewerEntry then
                rootDescription:CreateCheckbox(
                    L("MINIMAP_PORTAL_VIEWER_SHOW"),
                    function()
                        return IsPortalViewerEnabled()
                    end,
                    function()
                        TogglePortalViewer()
                    end
                )
            end

            if showQuickHideEntry then
                rootDescription:CreateCheckbox(
                    L("QUICK_HIDE_OVERLAYS"),
                    function()
                        return GetQuickHideOverlaysEnabled()
                    end,
                    function()
                        ToggleQuickHideOverlays()
                    end
                )
            end
        end)
        return
    end

    if not EnsureContextMenuSupport() then
        return
    end

    local menu = {
        {
            text = addonTitle,
            isTitle = true,
            notCheckable = true,
        },
    }

    local function AddActionEntry(visible, textKey, pageKey)
        if not visible then
            return
        end

        menu[#menu + 1] = {
            text = L(textKey),
            notCheckable = true,
            func = function()
                OpenAddonPage(pageKey)
            end,
        }
    end

    local function AddToggleEntry(visible, textKey, checked, disabled, callback)
        if not visible then
            return
        end

        menu[#menu + 1] = {
            text = L(textKey),
            checked = checked,
            isNotRadio = true,
            disabled = disabled,
            func = callback,
        }
    end

    AddActionEntry(showLevelTimeEntry, "LEVEL_TIME", "LevelTime")
    AddActionEntry(showQuestCheckEntry, "QUEST_CHECK", "QuestCheck")
    AddActionEntry(showQuestAbandonEntry, "QUEST_ABANDON", "QuestAbandon")
    AddActionEntry(showLoggingEntry, "LOGGING", "Logging")

    AddToggleEntry(showChecklistEntry, "MINIMAP_TRACKER_SHOW", IsChecklistTrackerEnabled(), not hasChecklistToggle, function()
        ToggleChecklistTracker()
    end)
    AddToggleEntry(showWeeklyKeysEntry, "MINIMAP_WEEKLY_KEYS_SHOW", IsWeeklyKeysOverlayEnabled(), not hasWeeklyKeysToggle, function()
        ToggleWeeklyKeysOverlay()
    end)
    AddToggleEntry(showStatsEntry, "MINIMAP_STATS_SHOW", IsStatsOverlayEnabled(), not hasStatsToggle, function()
        ToggleStatsOverlay()
    end)
    AddToggleEntry(showMarkerBarEntry, "MINIMAP_MARKER_BAR_SHOW", IsMarkerBarOverlayEnabled(), not hasMarkerBarToggle, function()
        ToggleMarkerBarOverlay()
    end)
    AddToggleEntry(showStreamerPlannerEntry, "MINIMAP_STREAMER_PLANNER_SHOW", IsStreamerPlannerOverlayEnabled(), not hasStreamerPlannerToggle, function()
        ToggleStreamerPlannerOverlay()
    end)
    AddToggleEntry(showEasyLFGEntry, "MINIMAP_EASY_LFG_SHOW", IsEasyLFGOverlayEnabled(), not hasEasyLFGToggle, function()
        ToggleEasyLFGOverlay()
    end)
    AddToggleEntry(showPortalViewerEntry, "MINIMAP_PORTAL_VIEWER_SHOW", IsPortalViewerEnabled(), not hasPortalViewerToggle, function()
        TogglePortalViewer()
    end)
    AddToggleEntry(showQuickHideEntry, "QUICK_HIDE_OVERLAYS", GetQuickHideOverlaysEnabled(), false, function()
        ToggleQuickHideOverlays()
    end)

    if CloseDropDownMenus then
        CloseDropDownMenus()
    end

    EasyMenu(menu, MinimapContextMenu, anchorFrame or "cursor", 0, 0, "MENU", 2)
end

-- Linksklick öffnet das Fenster, Shift-Klick lädt die UI neu.
BeavisQoL.ShowMinimapContextMenu = ShowMinimapContextMenu

local launcher = LDB:NewDataObject(ADDON_NAME, {
    type = "launcher",
    text = addonTitle,
    icon = "Interface\\AddOns\\BeavisQoL\\Media\\logo.tga",

    OnClick = function(clickedFrame, button)
        -- Shift wird hier bewusst als globaler Schnellbefehl priorisiert.
        -- So funktioniert das Reloaden unabhängig von der Maustaste immer gleich.
        -- Shift hat Vorrang, damit der schnelle Reload immer klappt.
        if IsShiftKeyDown() then
            ReloadUI()
        elseif button == "LeftButton" then
            ToggleMainWindow()
        elseif button == "RightButton" then
            ShowMinimapContextMenu(clickedFrame)
        end
    end,

    OnTooltipShow = function(tooltip)
        if not tooltip or not tooltip.AddLine then
            return
        end

        -- Der Tooltip zeigt absichtlich nur die echten Aktionen des Buttons.
        -- Kein "Werbetext", sondern nur Bedienung.
        tooltip:AddLine(addonTitle, 1, 0.82, 0)
        tooltip:AddLine(" ")
        tooltip:AddLine(L("MINIMAP_LEFT_CLICK"), 1, 1, 1)
        tooltip:AddLine(L("MINIMAP_RIGHT_CLICK"), 1, 1, 1)
        tooltip:AddLine(L("MINIMAP_SHIFT_CLICK"), 1, 1, 1)
        tooltip:AddLine(L("MINIMAP_DRAG"), 1, 1, 1)
    end,
})

-- LibDBIcon kümmert sich um Position, Anzeigen und Verstecken.
LDBIcon:Register(ADDON_NAME, launcher, BeavisQoLDB.minimap)

-- Nach Registrierung den gespeicherten Zustand erzwingen.
-- Refresh stellt sicher, dass LibDBIcon intern auch db.hide verwendet.
LDBIcon:Refresh(ADDON_NAME, BeavisQoLDB.minimap)

-- Die Referenzen behalten wir, falls später noch Einstellungen dazukommen.
BeavisQoL.MinimapLauncher = launcher
BeavisQoL.MinimapIcon = LDBIcon
