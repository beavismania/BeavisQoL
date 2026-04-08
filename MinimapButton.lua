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
local MenuTemplates = _G.MenuTemplates
local MenuVariants = _G.MenuVariants
local EasyMenu = rawget(_G, "EasyMenu")
local CloseDropDownMenus = rawget(_G, "CloseDropDownMenus")
local MinimapContextMenu

-- Ohne beide Libraries gibt es hier nichts zu tun.
if not LDB or not LDBIcon then
    return
end

local addonTitle = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title") or ADDON_NAME
local addonMenuTitle = string.format("|TInterface\\AddOns\\BeavisQoL\\Media\\logo.tga:16:16:0:0|t %s", addonTitle)

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

local function OpenQuickViewPage(pageKey)
    if BeavisQoL.OpenQuickView and BeavisQoL.OpenQuickView(pageKey) then
        return
    end

    OpenAddonPage(pageKey)
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

local function GetQuickHideOverlaysEnabled()
    return BeavisQoL.GetQuickHideOverlaysEnabled and BeavisQoL.GetQuickHideOverlaysEnabled() == true
end

local function ToggleQuickHideOverlays()
    if not BeavisQoL.SetQuickHideOverlaysEnabled then
        return
    end

    BeavisQoL.SetQuickHideOverlaysEnabled(not GetQuickHideOverlaysEnabled())
end

local function OpenQuickHideSettings()
    OpenAddonPage("Settings")
end

local function OpenPortalViewerWindow()
    local portalViewerModule = BeavisQoL.PortalViewerModule
    if not portalViewerModule then
        OpenAddonPage("PortalViewer")
        return
    end

    if portalViewerModule.SetWindowEnabled then
        portalViewerModule.SetWindowEnabled(true)
        return
    end

    if portalViewerModule.RefreshWindow then
        portalViewerModule.RefreshWindow()
        return
    end

    OpenAddonPage("PortalViewer")
end

local function OpenPortalViewerSettings()
    OpenAddonPage("PortalViewer")
end

local function OpenStreamerPlannerOverlay()
    local streamerPlannerModule = BeavisQoL.StreamerPlannerModule
    if not streamerPlannerModule then
        OpenAddonPage("StreamerPlanner")
        return
    end

    if streamerPlannerModule.SetOverlayEnabled then
        streamerPlannerModule.SetOverlayEnabled(true)
        return
    end

    if streamerPlannerModule.RefreshOverlayWindow then
        streamerPlannerModule.RefreshOverlayWindow()
        return
    end

    OpenAddonPage("StreamerPlanner")
end

local function OpenStreamerPlannerSettings()
    OpenAddonPage("StreamerPlanner")
end

local function OpenChecklistTracker()
    local checklistModule = BeavisQoL.Checklist
    if not checklistModule then
        OpenAddonPage("Checklist")
        return
    end

    if checklistModule.SetTrackerEnabled then
        checklistModule.SetTrackerEnabled(true)
        return
    end

    if checklistModule.RefreshTrackerWindow then
        checklistModule.RefreshTrackerWindow()
        return
    end

    OpenAddonPage("Checklist")
end

local function OpenChecklistSettings()
    OpenAddonPage("Checklist")
end

local QUICK_HIDE_SETTINGS_ICON = "|TInterface\\Buttons\\UI-OptionsButton:14:14:0:0:64:64:0:64:0:64|t"
local MENU_ITEM_ICONS = {
    portalViewer = "Interface\\ICONS\\INV_Misc_Rune_01",
    checklist = "Interface\\ICONS\\INV_Misc_Note_01",
    streamerPlanner = "Interface\\ICONS\\INV_Misc_GroupNeedMore",
    levelTime = "Interface\\ICONS\\INV_Misc_PocketWatch_01",
    itemLevelGuide = "Interface\\ICONS\\INV_Helmet_06",
    questCheck = "Interface\\ICONS\\INV_Misc_Note_05",
    questAbandon = "Interface\\ICONS\\Ability_Rogue_FeignDeath",
    logging = "Interface\\ICONS\\INV_Misc_Coin_01",
    weeklyKeys = "Interface\\ICONS\\INV_Relics_Hourglass",
    stats = "Interface\\ICONS\\Ability_Hunter_MasterMarksman",
    markerBar = "Interface\\ICONS\\INV_Misc_Map_01",
    easyLFG = "Interface\\ICONS\\INV_Misc_GroupLooking",
    quickHide = "Interface\\ICONS\\Ability_Spy",
}

local function CreateMenuTextureTag(texturePath)
    if not texturePath or texturePath == "" then
        return ""
    end

    return string.format("|T%s:14:14:0:0|t", texturePath)
end

local function WithMenuIcon(iconKey, text)
    local textureTag = CreateMenuTextureTag(MENU_ITEM_ICONS[iconKey])
    if textureTag == "" then
        return text
    end

    return string.format("%s %s", textureTag, text)
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
    MenuTemplates = _G.MenuTemplates
    MenuVariants = _G.MenuVariants
    local hasStatsToggle = BeavisQoL.StatsModule and BeavisQoL.StatsModule.IsOverlayEnabled and BeavisQoL.StatsModule.SetOverlayEnabled
    local hasWeeklyKeysToggle = BeavisQoL.WeeklyKeysModule and BeavisQoL.WeeklyKeysModule.IsOverlayEnabled and BeavisQoL.WeeklyKeysModule.SetOverlayEnabled
    local hasMarkerBarToggle = BeavisQoL.MarkerBarModule and BeavisQoL.MarkerBarModule.IsOverlayEnabled and BeavisQoL.MarkerBarModule.SetOverlayEnabled
    local hasStreamerPlannerToggle = BeavisQoL.StreamerPlannerModule and BeavisQoL.StreamerPlannerModule.IsOverlayEnabled and BeavisQoL.StreamerPlannerModule.SetOverlayEnabled
    local hasEasyLFGToggle = BeavisQoL.LFG and BeavisQoL.LFG.IsEasyLFGEnabled and BeavisQoL.LFG.SetEasyLFGEnabled
    local showLevelTimeEntry = IsMinimapContextEntryVisible("levelTime")
    local showItemLevelGuideEntry = IsMinimapContextEntryVisible("itemLevelGuide")
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
    local hasQuickViewEntries = showPortalViewerEntry or showChecklistEntry or showStreamerPlannerEntry or showLevelTimeEntry or showItemLevelGuideEntry or showQuestCheckEntry or showQuestAbandonEntry or showLoggingEntry
    local hasToggleEntries = (hasWeeklyKeysToggle and showWeeklyKeysEntry)
        or (hasStatsToggle and showStatsEntry)
        or (hasMarkerBarToggle and showMarkerBarEntry)
        or (hasEasyLFGToggle and showEasyLFGEntry)
        or showQuickHideEntry

    if MenuUtil and MenuUtil.CreateContextMenu then
        MenuUtil.CreateContextMenu(anchorFrame or UIParent, function(_, rootDescription)
            rootDescription:CreateTitle(addonMenuTitle)
            rootDescription:CreateDivider()
            if hasQuickViewEntries then
                rootDescription:CreateTitle(L("MINIMAP_CONTEXT_QUICK_VIEW"))

                if showPortalViewerEntry then
                    local portalViewerDescription = rootDescription:CreateButton(WithMenuIcon("portalViewer", L("PORTAL_VIEWER_TITLE")), function()
                        OpenPortalViewerWindow()
                    end)

                    if portalViewerDescription and portalViewerDescription.AddInitializer and MenuTemplates and MenuVariants then
                        portalViewerDescription:AddInitializer(function(button, _, menu)
                            if not button then
                                return
                            end

                            local gearButton = button.BeavisPortalViewerGearButton
                            if not gearButton then
                                gearButton = MenuTemplates.AttachAutoHideGearButton(button)
                                button.BeavisPortalViewerGearButton = gearButton
                            end

                            if not gearButton then
                                return
                            end

                            MenuTemplates.SetUtilityButtonTooltipText(gearButton, L("SETTINGS"))
                            MenuTemplates.SetUtilityButtonAnchor(gearButton, MenuVariants.GearButtonAnchor, button)
                            MenuTemplates.SetUtilityButtonClickHandler(gearButton, function()
                                OpenPortalViewerSettings()
                                if menu and menu.Close then
                                    menu:Close()
                                end
                            end)
                            gearButton:Show()
                        end)
                    end
                end

                if showChecklistEntry then
                    local checklistDescription = rootDescription:CreateButton(WithMenuIcon("checklist", L("CHECKLIST")), function()
                        OpenChecklistTracker()
                    end)

                    if checklistDescription and checklistDescription.AddInitializer and MenuTemplates and MenuVariants then
                        checklistDescription:AddInitializer(function(button, _, menu)
                            if not button then
                                return
                            end

                            local gearButton = button.BeavisChecklistGearButton
                            if not gearButton then
                                gearButton = MenuTemplates.AttachAutoHideGearButton(button)
                                button.BeavisChecklistGearButton = gearButton
                            end

                            if not gearButton then
                                return
                            end

                            MenuTemplates.SetUtilityButtonTooltipText(gearButton, L("CHECKLIST_SETTINGS_TOOLTIP"))
                            MenuTemplates.SetUtilityButtonAnchor(gearButton, MenuVariants.GearButtonAnchor, button)
                            MenuTemplates.SetUtilityButtonClickHandler(gearButton, function()
                                OpenChecklistSettings()
                                if menu and menu.Close then
                                    menu:Close()
                                end
                            end)
                            gearButton:Show()
                        end)
                    end
                end

                if showStreamerPlannerEntry then
                    local streamerPlannerDescription = rootDescription:CreateButton(WithMenuIcon("streamerPlanner", L("STREAMER_PLANNER_TITLE")), function()
                        OpenStreamerPlannerOverlay()
                    end)

                    if streamerPlannerDescription and streamerPlannerDescription.AddInitializer and MenuTemplates and MenuVariants then
                        streamerPlannerDescription:AddInitializer(function(button, _, menu)
                            if not button then
                                return
                            end

                            local gearButton = button.BeavisStreamerPlannerGearButton
                            if not gearButton then
                                gearButton = MenuTemplates.AttachAutoHideGearButton(button)
                                button.BeavisStreamerPlannerGearButton = gearButton
                            end

                            if not gearButton then
                                return
                            end

                            MenuTemplates.SetUtilityButtonTooltipText(gearButton, L("SETTINGS"))
                            MenuTemplates.SetUtilityButtonAnchor(gearButton, MenuVariants.GearButtonAnchor, button)
                            MenuTemplates.SetUtilityButtonClickHandler(gearButton, function()
                                OpenStreamerPlannerSettings()
                                if menu and menu.Close then
                                    menu:Close()
                                end
                            end)
                            gearButton:Show()
                        end)
                    end
                end

                if showLevelTimeEntry then
                    rootDescription:CreateButton(WithMenuIcon("levelTime", L("LEVEL_TIME")), function()
                        OpenQuickViewPage("LevelTime")
                    end)
                end

                if showItemLevelGuideEntry then
                    rootDescription:CreateButton(WithMenuIcon("itemLevelGuide", L("ITEMLEVEL_GUIDE")), function()
                        OpenQuickViewPage("ItemLevelGuide")
                    end)
                end

                if showQuestCheckEntry then
                    rootDescription:CreateButton(WithMenuIcon("questCheck", L("QUEST_CHECK")), function()
                        OpenQuickViewPage("QuestCheck")
                    end)
                end

                if showQuestAbandonEntry then
                    rootDescription:CreateButton(WithMenuIcon("questAbandon", L("QUEST_ABANDON")), function()
                        OpenQuickViewPage("QuestAbandon")
                    end)
                end

                if showLoggingEntry then
                    rootDescription:CreateButton(WithMenuIcon("logging", L("GOLDAUSWERTUNG")), function()
                        OpenQuickViewPage("Logging")
                    end)
                end
            end

            if hasQuickViewEntries and hasToggleEntries then
                rootDescription:CreateDivider()
            end

            if hasToggleEntries then
                rootDescription:CreateTitle(L("MINIMAP_CONTEXT_TOGGLE_SECTION"))

                if hasWeeklyKeysToggle and showWeeklyKeysEntry then
                    rootDescription:CreateCheckbox(
                        WithMenuIcon("weeklyKeys", L("MINIMAP_WEEKLY_KEYS_SHOW")),
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
                        WithMenuIcon("stats", L("MINIMAP_STATS_SHOW")),
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
                        WithMenuIcon("markerBar", L("MINIMAP_MARKER_BAR_SHOW")),
                        function()
                            return IsMarkerBarOverlayEnabled()
                        end,
                        function()
                            ToggleMarkerBarOverlay()
                        end
                    )
                end

                if hasEasyLFGToggle and showEasyLFGEntry then
                    rootDescription:CreateCheckbox(
                        WithMenuIcon("easyLFG", L("MINIMAP_EASY_LFG_SHOW")),
                        function()
                            return IsEasyLFGOverlayEnabled()
                        end,
                        function()
                            ToggleEasyLFGOverlay()
                        end
                    )
                end

                if showQuickHideEntry then
                    local quickHideDescription = rootDescription:CreateCheckbox(
                        WithMenuIcon("quickHide", L("MINIMAP_QUICK_HIDE_SHOW")),
                        function()
                            return GetQuickHideOverlaysEnabled()
                        end,
                        function()
                            ToggleQuickHideOverlays()
                        end
                    )

                    if quickHideDescription and quickHideDescription.AddInitializer and MenuTemplates and MenuVariants then
                        quickHideDescription:AddInitializer(function(button, _, menu)
                            if not button then
                                return
                            end

                            local gearButton = button.BeavisQuickHideGearButton
                            if not gearButton then
                                gearButton = MenuTemplates.AttachAutoHideGearButton(button)
                                button.BeavisQuickHideGearButton = gearButton
                            end

                            if not gearButton then
                                return
                            end

                            MenuTemplates.SetUtilityButtonTooltipText(gearButton, L("MINIMAP_QUICK_HIDE_SETTINGS"))
                            MenuTemplates.SetUtilityButtonAnchor(gearButton, MenuVariants.GearButtonAnchor, button)
                            MenuTemplates.SetUtilityButtonClickHandler(gearButton, function()
                                OpenQuickHideSettings()
                                if menu and menu.Close then
                                    menu:Close()
                                end
                            end)
                            gearButton:Show()
                        end)
                    else
                        rootDescription:CreateButton(
                            string.format("%s %s", QUICK_HIDE_SETTINGS_ICON, L("MINIMAP_QUICK_HIDE_SETTINGS")),
                            function()
                                OpenQuickHideSettings()
                            end
                        )
                    end
                end
            end
        end)
        return
    end

    if not EnsureContextMenuSupport() then
        return
    end

    local menu = {
        {
            text = addonMenuTitle,
            isTitle = true,
            notCheckable = true,
        },
    }

    local function AddSectionTitle(visible, text)
        if not visible then
            return
        end

        menu[#menu + 1] = {
            text = text,
            isTitle = true,
            notCheckable = true,
        }
    end

    local function AddActionEntry(visible, text, pageKey)
        if not visible then
            return
        end

        menu[#menu + 1] = {
            text = text,
            notCheckable = true,
            func = function()
                OpenQuickViewPage(pageKey)
            end,
        }
    end

    local function AddPortalViewerEntries(visible)
        if not visible then
            return
        end

        menu[#menu + 1] = {
            text = WithMenuIcon("portalViewer", L("PORTAL_VIEWER_TITLE")),
            notCheckable = true,
            func = function()
                OpenPortalViewerWindow()
            end,
        }

        menu[#menu + 1] = {
            text = string.format("%s %s", QUICK_HIDE_SETTINGS_ICON, L("SETTINGS")),
            notCheckable = true,
            func = function()
                OpenPortalViewerSettings()
            end,
        }
    end

    local function AddChecklistEntries(visible)
        if not visible then
            return
        end

        menu[#menu + 1] = {
            text = WithMenuIcon("checklist", L("CHECKLIST")),
            notCheckable = true,
            func = function()
                OpenChecklistTracker()
            end,
        }

        menu[#menu + 1] = {
            text = string.format("%s %s", QUICK_HIDE_SETTINGS_ICON, L("CHECKLIST_SETTINGS_TOOLTIP")),
            notCheckable = true,
            func = function()
                OpenChecklistSettings()
            end,
        }
    end

    local function AddStreamerPlannerEntries(visible)
        if not visible then
            return
        end

        menu[#menu + 1] = {
            text = WithMenuIcon("streamerPlanner", L("STREAMER_PLANNER_TITLE")),
            notCheckable = true,
            func = function()
                OpenStreamerPlannerOverlay()
            end,
        }

        menu[#menu + 1] = {
            text = string.format("%s %s", QUICK_HIDE_SETTINGS_ICON, L("SETTINGS")),
            notCheckable = true,
            func = function()
                OpenStreamerPlannerSettings()
            end,
        }
    end

    local function AddToggleEntry(visible, text, checked, disabled, callback)
        if not visible then
            return
        end

        menu[#menu + 1] = {
            text = text,
            checked = checked,
            isNotRadio = true,
            disabled = disabled,
            func = callback,
        }
    end

    local function AddQuickHideEntries(visible)
        if not visible then
            return
        end

        menu[#menu + 1] = {
            text = WithMenuIcon("quickHide", L("MINIMAP_QUICK_HIDE_SHOW")),
            checked = GetQuickHideOverlaysEnabled(),
            isNotRadio = true,
            func = function()
                ToggleQuickHideOverlays()
            end,
        }

        menu[#menu + 1] = {
            text = string.format("%s %s", QUICK_HIDE_SETTINGS_ICON, L("MINIMAP_QUICK_HIDE_SETTINGS")),
            notCheckable = true,
            func = function()
                OpenQuickHideSettings()
            end,
        }
    end

    AddSectionTitle(hasQuickViewEntries, L("MINIMAP_CONTEXT_QUICK_VIEW"))
    AddPortalViewerEntries(showPortalViewerEntry)
    AddChecklistEntries(showChecklistEntry)
    AddStreamerPlannerEntries(showStreamerPlannerEntry)
    AddActionEntry(showLevelTimeEntry, WithMenuIcon("levelTime", L("LEVEL_TIME")), "LevelTime")
    AddActionEntry(showItemLevelGuideEntry, WithMenuIcon("itemLevelGuide", L("ITEMLEVEL_GUIDE")), "ItemLevelGuide")
    AddActionEntry(showQuestCheckEntry, WithMenuIcon("questCheck", L("QUEST_CHECK")), "QuestCheck")
    AddActionEntry(showQuestAbandonEntry, WithMenuIcon("questAbandon", L("QUEST_ABANDON")), "QuestAbandon")
    AddActionEntry(showLoggingEntry, WithMenuIcon("logging", L("GOLDAUSWERTUNG")), "Logging")

    AddSectionTitle(hasToggleEntries, L("MINIMAP_CONTEXT_TOGGLE_SECTION"))
    AddToggleEntry(hasWeeklyKeysToggle and showWeeklyKeysEntry, WithMenuIcon("weeklyKeys", L("MINIMAP_WEEKLY_KEYS_SHOW")), IsWeeklyKeysOverlayEnabled(), not hasWeeklyKeysToggle, function()
        ToggleWeeklyKeysOverlay()
    end)
    AddToggleEntry(hasStatsToggle and showStatsEntry, WithMenuIcon("stats", L("MINIMAP_STATS_SHOW")), IsStatsOverlayEnabled(), not hasStatsToggle, function()
        ToggleStatsOverlay()
    end)
    AddToggleEntry(hasMarkerBarToggle and showMarkerBarEntry, WithMenuIcon("markerBar", L("MINIMAP_MARKER_BAR_SHOW")), IsMarkerBarOverlayEnabled(), not hasMarkerBarToggle, function()
        ToggleMarkerBarOverlay()
    end)
    AddToggleEntry(hasEasyLFGToggle and showEasyLFGEntry, WithMenuIcon("easyLFG", L("MINIMAP_EASY_LFG_SHOW")), IsEasyLFGOverlayEnabled(), not hasEasyLFGToggle, function()
        ToggleEasyLFGOverlay()
    end)
    AddQuickHideEntries(showQuickHideEntry)

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
