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
local EasyMenu = _G.EasyMenu
local CloseDropDownMenus = _G.CloseDropDownMenus
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
    -- Der Fallback darunter ist nur dafuer da, dass der Minimap-Button nicht
    -- ploetzlich nutzlos wird, falls der Tree einmal noch nicht bereit ist.
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

local function EnsureContextMenuSupport()
    -- Das alte Dropdown-Menue ist in manchen Clients nicht sofort geladen.
    -- Diese Funktion zieht Blizzard_UIDropDownMenu nur bei Bedarf nach.
    if not EasyMenu or not CloseDropDownMenus or not _G.UIDropDownMenuTemplate then
        if C_AddOns and C_AddOns.LoadAddOn then
            C_AddOns.LoadAddOn("Blizzard_UIDropDownMenu")
        elseif UIParentLoadAddOn then
            UIParentLoadAddOn("Blizzard_UIDropDownMenu")
        end

        EasyMenu = _G.EasyMenu
        CloseDropDownMenus = _G.CloseDropDownMenus
    end

    if not EasyMenu or not CloseDropDownMenus or not _G.UIDropDownMenuTemplate then
        return false
    end

    if not MinimapContextMenu then
        MinimapContextMenu = CreateFrame("Frame", "BeavisQoLMinimapContextMenu", UIParent, "UIDropDownMenuTemplate")
    end

    return MinimapContextMenu ~= nil
end

local function ShowMinimapContextMenu(anchorFrame)
    -- Zuerst versuchen wir das moderne Blizzard-Menuesystem zu nutzen.
    -- Falls das im Client nicht vorhanden ist, faellt der Code darunter sauber
    -- auf das aeltere EasyMenu zurueck.
    MenuUtil = _G.MenuUtil
    local hasChecklistToggle = BeavisQoL.Checklist and BeavisQoL.Checklist.IsTrackerEnabled and BeavisQoL.Checklist.SetTrackerEnabled
    local hasStatsToggle = BeavisQoL.StatsModule and BeavisQoL.StatsModule.IsOverlayEnabled and BeavisQoL.StatsModule.SetOverlayEnabled
    local hasWeeklyKeysToggle = BeavisQoL.WeeklyKeysModule and BeavisQoL.WeeklyKeysModule.IsOverlayEnabled and BeavisQoL.WeeklyKeysModule.SetOverlayEnabled

    if MenuUtil and MenuUtil.CreateContextMenu then
        MenuUtil.CreateContextMenu(anchorFrame or UIParent, function(_, rootDescription)
            rootDescription:CreateTitle(addonTitle)
            rootDescription:CreateDivider()
            rootDescription:CreateButton(L("LEVEL_TIME"), function()
                OpenAddonPage("LevelTime")
            end)
            rootDescription:CreateButton(L("QUEST_CHECK"), function()
                OpenAddonPage("QuestCheck")
            end)
            rootDescription:CreateButton(L("LOGGING"), function()
                OpenAddonPage("Logging")
            end)

            if hasChecklistToggle then
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

            if hasWeeklyKeysToggle then
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

            if hasStatsToggle then
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
        {
            text = L("LEVEL_TIME"),
            notCheckable = true,
            func = function()
                OpenAddonPage("LevelTime")
            end,
        },
        {
            text = L("QUEST_CHECK"),
            notCheckable = true,
            func = function()
                OpenAddonPage("QuestCheck")
            end,
        },
        {
            text = L("LOGGING"),
            notCheckable = true,
            func = function()
                OpenAddonPage("Logging")
            end,
        },
        {
            text = L("MINIMAP_TRACKER_SHOW"),
            checked = IsChecklistTrackerEnabled(),
            isNotRadio = true,
            disabled = not hasChecklistToggle,
            func = function()
                ToggleChecklistTracker()
            end,
        },
        {
            text = L("MINIMAP_WEEKLY_KEYS_SHOW"),
            checked = IsWeeklyKeysOverlayEnabled(),
            isNotRadio = true,
            disabled = not hasWeeklyKeysToggle,
            func = function()
                ToggleWeeklyKeysOverlay()
            end,
        },
        {
            text = L("MINIMAP_STATS_SHOW"),
            checked = IsStatsOverlayEnabled(),
            isNotRadio = true,
            disabled = not hasStatsToggle,
            func = function()
                ToggleStatsOverlay()
            end,
        },
    }

    if CloseDropDownMenus then
        CloseDropDownMenus()
    end

    EasyMenu(menu, MinimapContextMenu, anchorFrame or "cursor", 0, 0, "MENU", 2)
end

-- Linksklick öffnet das Fenster, Shift-Klick lädt die UI neu.
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
