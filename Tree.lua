local ADDON_NAME, BeavisQoL = ...

--[[
Tree.lua rendert die linke Navigation.
Die Seite selbst zeigt keine Inhalte, sondern nur:
- Hauptgruppen
- Modulsektionen
- Einträge zum Öffnen der Seiten
]]

local SidebarFrame = BeavisQoL.Sidebar
local Pages = BeavisQoL.Pages

local L = BeavisQoL.L
local SidebarCaption = SidebarFrame:CreateFontString(nil, "ARTWORK")
SidebarCaption:SetPoint("TOPLEFT", SidebarFrame, "TOPLEFT", 14, -12)
SidebarCaption:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
SidebarCaption:SetTextColor(1, 0.82, 0, 1)
SidebarCaption:SetText(L("NAVIGATION"))

local SidebarCaptionHint = SidebarFrame:CreateFontString(nil, "ARTWORK")
SidebarCaptionHint:SetPoint("TOPLEFT", SidebarCaption, "BOTTOMLEFT", 0, -4)
SidebarCaptionHint:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
SidebarCaptionHint:SetTextColor(0.74, 0.74, 0.76, 1)
SidebarCaptionHint:SetText(L("NAVIGATION_HINT"))

local SidebarSearchEditBox = CreateFrame("EditBox", nil, SidebarFrame, "InputBoxTemplate")
SidebarSearchEditBox:SetSize(184, 22)
SidebarSearchEditBox:SetPoint("TOPLEFT", SidebarCaptionHint, "BOTTOMLEFT", 4, -14)
SidebarSearchEditBox:SetAutoFocus(false)
SidebarSearchEditBox:SetMaxLetters(80)
SidebarSearchEditBox:SetFontObject(ChatFontNormal)

local SidebarSearchPlaceholder = SidebarFrame:CreateFontString(nil, "ARTWORK")
SidebarSearchPlaceholder:SetPoint("LEFT", SidebarSearchEditBox, "LEFT", 6, 0)
SidebarSearchPlaceholder:SetPoint("RIGHT", SidebarSearchEditBox, "RIGHT", -8, 0)
SidebarSearchPlaceholder:SetJustifyH("LEFT")
SidebarSearchPlaceholder:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
SidebarSearchPlaceholder:SetTextColor(0.58, 0.58, 0.60, 1)
SidebarSearchPlaceholder:SetText(L("NAVIGATION_SEARCH_PLACEHOLDER"))

local SidebarSearchStatus = SidebarFrame:CreateFontString(nil, "ARTWORK")
SidebarSearchStatus:SetPoint("TOPLEFT", SidebarSearchEditBox, "BOTTOMLEFT", -2, -7)
SidebarSearchStatus:SetPoint("RIGHT", SidebarFrame, "RIGHT", -12, 0)
SidebarSearchStatus:SetJustifyH("LEFT")
SidebarSearchStatus:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
SidebarSearchStatus:SetTextColor(0.74, 0.74, 0.76, 1)
SidebarSearchStatus:SetText(L("NAVIGATION_SEARCH_HINT"))

local SidebarScrollFrame = CreateFrame("ScrollFrame", nil, SidebarFrame, "UIPanelScrollFrameTemplate")
SidebarScrollFrame:SetPoint("TOPLEFT", SidebarFrame, "TOPLEFT", 10, -92)
SidebarScrollFrame:SetPoint("BOTTOMRIGHT", SidebarFrame, "BOTTOMRIGHT", -28, 10)
SidebarScrollFrame:EnableMouseWheel(true)

local Sidebar = CreateFrame("Frame", nil, SidebarScrollFrame)
Sidebar:SetSize(1, 1)
SidebarScrollFrame:SetScrollChild(Sidebar)

local GeneralExpanded = true
local ModuleExpanded = true
local NavigationSearchQuery = ""

local GeneralEntries = {}
local ModuleSectionHeaders = {}
local ModuleEntries = {}
local AllEntries = {}

local function NormalizeSearchText(text)
    local normalizedText = tostring(text or "")
    normalizedText = string.lower(normalizedText)
    normalizedText = string.gsub(normalizedText, "[%c%p]", " ")
    normalizedText = string.gsub(normalizedText, "%s+", " ")
    normalizedText = string.match(normalizedText, "^%s*(.-)%s*$") or ""

    return normalizedText
end

local function IsSearchActive()
    return NavigationSearchQuery ~= ""
end

local function SearchTextContains(haystack, needle)
    if needle == nil or needle == "" then
        return true
    end

    if haystack == nil or haystack == "" then
        return false
    end

    return string.find(haystack, needle, 1, true) ~= nil
end

local function GetLocalizedSearchText(textKey)
    if not textKey then
        return nil
    end

    local localizedText = L(textKey)
    if not localizedText or localizedText == "" then
        return nil
    end

    if localizedText == textKey and string.find(textKey, "^[A-Z0-9_]+$") then
        return nil
    end

    return localizedText
end

local function AppendSearchText(searchParts, text)
    local normalizedText = NormalizeSearchText(text)
    if normalizedText == "" then
        return
    end

    searchParts[#searchParts + 1] = normalizedText
end

local function RefreshEntrySearchText(entry)
    local searchParts = {}

    if entry.text and entry.text.GetText then
        AppendSearchText(searchParts, entry.text:GetText())
    end

    AppendSearchText(searchParts, entry.pageKey)
    AppendSearchText(searchParts, entry.miscSection)
    AppendSearchText(searchParts, entry.searchAliases)

    if entry.section and entry.section.text and entry.section.text.GetText then
        AppendSearchText(searchParts, entry.section.text:GetText())
    end

    for _, searchTextKey in ipairs(entry.searchTextKeys or {}) do
        AppendSearchText(searchParts, GetLocalizedSearchText(searchTextKey))
    end

    entry.searchText = table.concat(searchParts, " ")
end

local function RefreshSectionSearchText(section)
    local searchParts = {}

    if section.text and section.text.GetText then
        AppendSearchText(searchParts, section.text:GetText())
    end

    section.searchText = table.concat(searchParts, " ")
end

local function RefreshSearchIndex()
    for _, section in ipairs(ModuleSectionHeaders) do
        RefreshSectionSearchText(section)
    end

    for _, entry in ipairs(AllEntries) do
        RefreshEntrySearchText(entry)
    end
end

local function UpdateSearchPlaceholder()
    if SidebarSearchEditBox:HasFocus() or SidebarSearchEditBox:GetText() ~= "" then
        SidebarSearchPlaceholder:Hide()
        return
    end

    SidebarSearchPlaceholder:Show()
end

local function SetSearchStatusText(text, red, green, blue)
    SidebarSearchStatus:SetText(text or "")
    SidebarSearchStatus:SetTextColor(red or 0.74, green or 0.74, blue or 0.76, 1)
end

local function BuildVisibleEntriesForSearch(entries, groupSearchText)
    local visibleEntries = {}
    local groupMatches = SearchTextContains(groupSearchText, NavigationSearchQuery)

    for _, entry in ipairs(entries) do
        local entryMatches = groupMatches or SearchTextContains(entry.searchText, NavigationSearchQuery)

        if entry.section and SearchTextContains(entry.section.searchText, NavigationSearchQuery) then
            entryMatches = true
        end

        if entryMatches then
            visibleEntries[#visibleEntries + 1] = entry
        end
    end

    return visibleEntries
end

local function ShowPage(pageToShow)
    if not pageToShow then
        return
    end

    for _, page in pairs(Pages) do
        page:Hide()
    end

    pageToShow:Show()
end

local function ApplyToggleVisual(button, hovered)
    local backgroundAlpha = hovered and 0.08 or 0.04
    local indicatorAlpha = hovered and 0.22 or 0.14

    button.Bg:SetColorTexture(1, 0.82, 0, backgroundAlpha)
    button.IndicatorBg:SetColorTexture(1, 0.82, 0, indicatorAlpha)
    button.Indicator:SetText(button.IsExpanded and "-" or "+")
end

local function CreateToggleButton(labelTextKey)
    local button = CreateFrame("Button", nil, Sidebar)
    button:SetSize(192, 26)
    button:SetHitRectInsets(-4, -4, -2, -2)

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(1, 0.82, 0, 0.04)
    button.Bg = bg

    local indicatorBg = button:CreateTexture(nil, "ARTWORK")
    indicatorBg:SetSize(18, 18)
    indicatorBg:SetPoint("LEFT", button, "LEFT", 8, 0)
    indicatorBg:SetColorTexture(1, 0.82, 0, 0.14)
    button.IndicatorBg = indicatorBg

    local indicator = button:CreateFontString(nil, "OVERLAY")
    indicator:SetPoint("CENTER", indicatorBg, "CENTER", 0, 0)
    indicator:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    indicator:SetTextColor(1, 0.92, 0.45, 1)
    indicator:SetText("+")

    local text = button:CreateFontString(nil, "OVERLAY")
    text:SetPoint("LEFT", indicatorBg, "RIGHT", 10, 0)
    text:SetPoint("RIGHT", button, "RIGHT", -8, 0)
    text:SetJustifyH("LEFT")
    text:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
    text:SetTextColor(1, 0.82, 0, 1)
    text:SetText(L(labelTextKey))

    button.Indicator = indicator
    button.Text = text
    button.IsExpanded = false

    button:SetScript("OnEnter", function(self)
        ApplyToggleVisual(self, true)
    end)

    button:SetScript("OnLeave", function(self)
        ApplyToggleVisual(self, false)
    end)

    ApplyToggleVisual(button, false)
    return button, indicator, text
end

local function ApplyEntryVisual(entry, hovered)
    if entry.isActive then
        entry.button.Bg:SetColorTexture(1, 0.82, 0, 0.11)
        entry.button.Accent:SetAlpha(1)
        entry.text:SetTextColor(1, 0.9, 0.35, 1)
        return
    end

    if hovered then
        entry.button.Bg:SetColorTexture(1, 0.82, 0, 0.055)
        entry.button.Accent:SetAlpha(0.45)
        entry.text:SetTextColor(1, 1, 1, 1)
        return
    end

    entry.button.Bg:SetColorTexture(1, 0.82, 0, 0.015)
    entry.button.Accent:SetAlpha(0)
    entry.text:SetTextColor(0.92, 0.92, 0.95, 1)
end

local function AttachEntryVisual(entry)
    entry.button:SetScript("OnEnter", function()
        ApplyEntryVisual(entry, true)
    end)

    entry.button:SetScript("OnLeave", function()
        ApplyEntryVisual(entry, false)
    end)

    ApplyEntryVisual(entry, false)
end

local function CreateEntryButton(labelTextKey)
    local button = CreateFrame("Button", nil, Sidebar)
    button:SetSize(192, 24)
    button:SetHitRectInsets(-4, -4, -2, -2)

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(1, 0.82, 0, 0.015)
    button.Bg = bg

    local accent = button:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    accent:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    accent:SetWidth(2)
    accent:SetColorTexture(1, 0.82, 0, 0.95)
    accent:SetAlpha(0)
    button.Accent = accent

    local text = button:CreateFontString(nil, "OVERLAY")
    text:SetPoint("LEFT", button, "LEFT", 12, 0)
    text:SetPoint("RIGHT", button, "RIGHT", -8, 0)
    text:SetJustifyH("LEFT")
    text:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    text:SetTextColor(0.92, 0.92, 0.95, 1)
    text:SetText(L(labelTextKey))

    return button, text
end

local function CreateSectionHeader(labelTextKey)
    local frame = CreateFrame("Frame", nil, Sidebar)
    frame:SetSize(192, 22)

    local line = frame:CreateTexture(nil, "BACKGROUND")
    line:SetPoint("LEFT", frame, "LEFT", 0, 0)
    line:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    line:SetHeight(1)
    line:SetColorTexture(1, 0.82, 0, 0.12)

    local accent = frame:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("LEFT", frame, "LEFT", 0, 0)
    accent:SetSize(18, 2)
    accent:SetColorTexture(1, 0.82, 0, 0.8)

    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetPoint("LEFT", frame, "LEFT", 0, 8)
    text:SetPoint("RIGHT", frame, "RIGHT", 0, 8)
    text:SetJustifyH("LEFT")
    text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    text:SetTextColor(1, 0.82, 0, 0.85)
    text:SetText(L(labelTextKey))

    return frame, text
end

local TreeGeneralButton, TreeGeneralIndicator = CreateToggleButton("GENERAL")
local TreeModuleButton, TreeModuleIndicator = CreateToggleButton("MODULES")

local function RegisterGeneralEntry(pageKey, labelTextKey, options)
    local button, text = CreateEntryButton(labelTextKey)
    local entry = {
        pageKey = pageKey,
        button = button,
        text = text,
        miscSection = nil,
        searchTextKeys = options and options.searchTextKeys or {},
        searchAliases = options and options.searchAliases or nil,
        section = nil,
        isActive = false,
    }

    GeneralEntries[#GeneralEntries + 1] = entry
    AllEntries[#AllEntries + 1] = entry
    AttachEntryVisual(entry)
    return button, text
end

local function RegisterModuleSection(labelTextKey)
    local frame, text = CreateSectionHeader(labelTextKey)
    local section = {
        frame = frame,
        text = text,
        entries = {},
        searchText = "",
    }

    ModuleSectionHeaders[#ModuleSectionHeaders + 1] = section
    return section
end

local function RegisterModuleEntry(section, labelTextKey, pageKey, options)
    local button, text = CreateEntryButton(labelTextKey)
    local entry = {
        pageKey = pageKey,
        button = button,
        text = text,
        miscSection = options and options.miscSection or nil,
        searchTextKeys = options and options.searchTextKeys or {},
        searchAliases = options and options.searchAliases or nil,
        section = section,
        isActive = false,
    }

    section.entries[#section.entries + 1] = entry
    ModuleEntries[#ModuleEntries + 1] = entry
    AllEntries[#AllEntries + 1] = entry
    AttachEntryVisual(entry)
    return entry
end

local TreeHomeButton, TreeHomeText = RegisterGeneralEntry("Home", "HOME", {
    searchTextKeys = { "WELCOME_SUBTITLE", "WELCOME_BODY", "PROJECT_STATUS", "PROGRESS_CARD_BODY", "COMFORT_CARD_BODY", "DISCORD_BODY" },
    searchAliases = "hub dashboard start overview",
})
local TreeVersionButton, TreeVersionText = RegisterGeneralEntry("Version", "VERSION", {
    searchTextKeys = { "VERSIONS_INFO_DESC", "CURRENT_VERSION", "RELEASE_DATE", "SUPPORTED_GAME_VERSION", "VERSION_CHECK_HINT" },
    searchAliases = "release changelog toc update",
})
local TreeSettingsButton, TreeSettingsText = RegisterGeneralEntry("Settings", "SETTINGS", {
    searchTextKeys = { "GLOBAL_SETTINGS_DESC", "LOCK_WINDOW", "MINIMAP_BUTTON_HIDE", "QUICK_HIDE_OVERLAYS", "QUICK_HIDE_CHECKLIST_OVERLAY", "QUICK_HIDE_WEEKLY_OVERLAY", "QUICK_HIDE_STATS_OVERLAY", "QUICK_HIDE_OVERLAYS_IN_COMBAT", "RESET_POSITION" },
    searchAliases = "config option minimap window",
})

local ProgressSection = RegisterModuleSection("PROGRESS")
local GoldSection = RegisterModuleSection("GOLD_TRADE")
local ComfortSection = RegisterModuleSection("COMFORT")
local InterfaceSection = RegisterModuleSection("INTERFACE_COMBAT")
local GroupSection = RegisterModuleSection("GROUP_SEARCH")
local StreamerSection = RegisterModuleSection("STREAMER_TOOLS")
local CompanionSection = RegisterModuleSection("COMPANION")

local LevelTimeEntry = RegisterModuleEntry(ProgressSection, "LEVEL_TIME", "LevelTime", {
    searchTextKeys = { "LEVELTIME_TOOLTIP_TITLE", "LEVELTIME_TOOLTIP_TEXT", "CURRENT_LEVEL", "TIME_ON_CURRENT_LEVEL", "TOTAL_TIME" },
    searchAliases = "level xp leveling time tracker",
})
local ChecklistEntry = RegisterModuleEntry(ProgressSection, "CHECKLIST", "Checklist", {
    searchTextKeys = { "CHECKLIST_DESC", "CHECKLIST_INTRO_HINT", "CHECKLIST_DAILY_HINT", "CHECKLIST_WEEKLY_HINT", "CHECKLIST_SHOW_TRACKER_HINT" },
    searchAliases = "todo daily weekly tracker tasks",
})
local WeeklyKeysEntry = RegisterModuleEntry(ProgressSection, "WEEKLY_KEYS", "WeeklyKeys", {
    searchTextKeys = { "WEEKLY_KEYS_DESC", "WEEKLY_KEYS_SHOW_OVERLAY_HINT", "WEEKLY_KEYS_SUMMARY" },
    searchAliases = "mythic dungeon vault overlay",
})
local ItemLevelGuideEntry = RegisterModuleEntry(ProgressSection, "ITEMLEVEL_GUIDE", "ItemLevelGuide", {
    searchTextKeys = { "ITEM_GUIDE_TITLE", "ITEM_GUIDE_SUBTITLE", "ITEM_GUIDE_DESC", "ITEM_GUIDE_DUNGEON_CARD_SUBTITLE", "ITEM_GUIDE_RAID_CARD_SUBTITLE" },
    searchAliases = "gear crest crafting raid dungeon delve",
})
local QuestCheckEntry = RegisterModuleEntry(ProgressSection, "QUEST_CHECK", "QuestCheck", {
    searchTextKeys = { "QUESTCHECK_DESC", "QUEST_SEARCH_HINT", "QUESTCHECK_RESULT_HINT" },
    searchAliases = "quest wowhead id search completed",
})
local QuestAbandonEntry = RegisterModuleEntry(ProgressSection, "QUEST_ABANDON", "QuestAbandon", {
    searchTextKeys = { "QUEST_ABANDON_DESC", "QUEST_ABANDON_SELECTED", "QUEST_ABANDON_SELECT_ALL" },
    searchAliases = "quest remove abandon cancel marked selected",
})

local LoggingEntry = RegisterModuleEntry(GoldSection, "LOGGING", "Logging", {
    searchTextKeys = { "LOGGING_DESC", "LOGGING_SALES_HINT", "LOGGING_REPAIRS_HINT", "LOGGING_INCOME_HINT", "LOGGING_EXPENSE_HINT" },
    searchAliases = "gold sales repairs income expenses vendor auction trade",
})
local AutoSellEntry = RegisterModuleEntry(GoldSection, "AUTOSELL_JUNK", "Misc", {
    miscSection = "AutoSell",
    searchTextKeys = { "AUTOSELL_HINT", "LOGGING_AUTOSELL" },
    searchAliases = "sell junk gray vendor trash",
})
local AutoRepairEntry = RegisterModuleEntry(GoldSection, "AUTOREPAIR", "Misc", {
    miscSection = "AutoRepair",
    searchTextKeys = { "AUTOREPAIR_HINT", "AUTOREPAIR_GUILD_HINT" },
    searchAliases = "repair merchant guild gear",
})

local FastLootEntry = RegisterModuleEntry(ComfortSection, "FAST_LOOT", "Misc", {
    miscSection = "FastLoot",
    searchTextKeys = { "FAST_LOOT_HINT" },
    searchAliases = "loot auto loot plunder",
})
local EasyDeleteEntry = RegisterModuleEntry(ComfortSection, "EASY_DELETE", "Misc", {
    miscSection = "EasyDelete",
    searchTextKeys = { "EASY_DELETE_HINT" },
    searchAliases = "delete remove confirm item",
})
-- Dieser Tree-Eintrag springt nicht auf eine eigene Seite, sondern direkt auf
-- die passende Karte innerhalb der Misc-Seite.
local TooltipItemLevelEntry = RegisterModuleEntry(ComfortSection, "TOOLTIP_ITEMLEVEL", "Misc", {
    miscSection = "TooltipItemLevel",
    searchTextKeys = { "TOOLTIP_ITEMLEVEL_HINT", "TOOLTIP_ITEMLEVEL_LABEL" },
    searchAliases = "tooltip inspect ilvl itemlevel mouseover",
})
local CameraDistanceEntry = RegisterModuleEntry(ComfortSection, "CAMERA_DISTANCE", "Misc", {
    miscSection = "CameraDistance",
    searchTextKeys = { "CAMERA_DISTANCE_HINT", "CAMERA_DISTANCE_MAX" },
    searchAliases = "camera zoom distance max",
})
local FishingEntry = RegisterModuleEntry(ComfortSection, "FISHING_HELPER", "Fishing", {
    searchTextKeys = {
        "FISHING_HELPER_DESC",
        "FISHING_HELPER_USAGE_HINT",
        "FISHING_HELPER_INTERACT_HINT",
        "FISHING_HELPER_SOUND_HINT",
        "FISHING_HELPER_ENABLE",
    },
    searchAliases = "fishing angeln hotkey interact bobber splash sound one key",
})

local StatsEntry = RegisterModuleEntry(InterfaceSection, "STATS", "Stats", {
    searchTextKeys = { "STATS_DESC", "STATS_SHOW_OVERLAY_HINT", "STATS_SETTINGS_HINT" },
    searchAliases = "secondary stats overlay crit haste mastery versa",
})
local MarkerBarEntry = RegisterModuleEntry(InterfaceSection, "MARKER_BAR", "MarkerBar", {
    searchTextKeys = { "MARKER_BAR_DESC", "MARKER_BAR_USAGE_HINT", "MARKER_BAR_PERMISSION_HINT", "MARKER_BAR_SHOW_OVERLAY", "MARKER_BAR_LOCK_OVERLAY", "MARKER_BAR_SCALE_HINT" },
    searchAliases = "raid marker marks skull star circle cross diamond moon square triangle world marker overlay bar",
})
local CombatTextEntry = RegisterModuleEntry(InterfaceSection, "COMBAT_TEXT", "DamageText", {
    searchTextKeys = { "DAMAGE_TEXT_DESC", "DAMAGE_TEXT_ENABLE_HINT", "DAMAGE_TEXT_APPEARANCE_HINT" },
    searchAliases = "damage combat text font numbers scrolling",
})
local MouseHelperEntry = RegisterModuleEntry(InterfaceSection, "MOUSE_HELPER", "MouseHelper", {
    searchTextKeys = {
        "MOUSE_HELPER_DESC",
        "MOUSE_HELPER_CIRCLE_HINT",
        "MOUSE_HELPER_TRAIL_HINT",
        "MOUSE_HELPER_BLIZZARD_CURSOR_HINT",
    },
    searchAliases = "mouse cursor circle trail pointer highlight blizzard large",
})
local BossGuidesEntry = RegisterModuleEntry(InterfaceSection, "BOSS_GUIDES", "BossGuides", {
    searchTextKeys = {
        "BOSS_GUIDES_DESC",
        "BOSS_GUIDES_SHOW_OVERLAY",
        "BOSS_GUIDES_LOCK_OVERLAY",
        "BOSS_GUIDES_SCALE",
        "BOSS_GUIDES_FONT_SIZE",
    },
    searchAliases = "boss guide raid dungeon tactics tabs overlay button",
})
local LFGEntry = RegisterModuleEntry(GroupSection, "LFG", "LFG", {
    searchTextKeys = { "LFG_DESC", "FLAGS_HINT", "EASY_LFG_HINT", "EASY_LFG_SHOW_OVERLAY_HINT" },
    searchAliases = "group finder premade flags realms applicants invite easy lfg overlay queue",
})
local StreamerPlannerEntry = RegisterModuleEntry(StreamerSection, "STREAMER_PLANNER", "StreamerPlanner", {
    searchTextKeys = {
        "STREAMER_PLANNER_DESC",
        "STREAMER_PLANNER_USAGE_HINT",
        "STREAMER_PLANNER_PREVIEW_HINT",
        "STREAMER_PLANNER_SETTINGS_HINT",
        "STREAMER_PLANNER_EDIT_HINT",
    },
    searchAliases = "stream streamer planner overlay roster lineup raid dungeon group planning slots",
})
local PetStuffEntry = RegisterModuleEntry(CompanionSection, "PET_STUFF", "PetStuff", {
    searchTextKeys = { "PET_STUFF_DESC", "AUTO_RESPAWN_PET_HINT" },
    searchAliases = "pet companion respawn summon mount",
})

local function SetActiveTreeItem(activeText)
    for _, entry in ipairs(AllEntries) do
        entry.isActive = activeText ~= nil and entry.text == activeText
        ApplyEntryVisual(entry, false)
    end
end

local function UpdateTreeScrollLayout(contentBottomY)
    Sidebar:SetWidth(math.max(1, SidebarScrollFrame:GetWidth()))
    Sidebar:SetHeight(math.max(SidebarScrollFrame:GetHeight(), -contentBottomY + 28))

    local maxScroll = math.max(0, Sidebar:GetHeight() - SidebarScrollFrame:GetHeight())
    if SidebarScrollFrame:GetVerticalScroll() > maxScroll then
        SidebarScrollFrame:SetVerticalScroll(maxScroll)
    end
end

local function HideModuleSection(section)
    section.frame:Hide()
    section.frame:ClearAllPoints()

    for _, entry in ipairs(section.entries) do
        entry.button:Hide()
        entry.button:ClearAllPoints()
    end
end

local function UpdateTreeLayout()
    TreeGeneralButton:ClearAllPoints()
    TreeModuleButton:ClearAllPoints()

    for _, entry in ipairs(GeneralEntries) do
        entry.button:Hide()
        entry.button:ClearAllPoints()
    end

    for _, section in ipairs(ModuleSectionHeaders) do
        HideModuleSection(section)
    end

    TreeGeneralButton.IsExpanded = GeneralExpanded
    TreeModuleButton.IsExpanded = ModuleExpanded
    ApplyToggleVisual(TreeGeneralButton, false)
    ApplyToggleVisual(TreeModuleButton, false)

    local groupX = 6
    local childX = 16
    local sectionX = 16
    local sectionChildX = 24
    local currentY = -4

    if IsSearchActive() then
        local visibleGeneralEntries = BuildVisibleEntriesForSearch(GeneralEntries, NormalizeSearchText(L("GENERAL")))
        local visibleGeneralCount = #visibleGeneralEntries
        local visibleModuleCount = 0
        local visibleModuleSections = {}

        if visibleGeneralCount > 0 then
            TreeGeneralButton:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", groupX, currentY)
            TreeGeneralButton.IsExpanded = true
            ApplyToggleVisual(TreeGeneralButton, false)
            TreeGeneralIndicator:SetText("-")
            TreeGeneralButton:Show()
            currentY = currentY - 34

            for _, entry in ipairs(visibleGeneralEntries) do
                entry.button:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", childX, currentY)
                entry.button:Show()
                currentY = currentY - 30
            end

            currentY = currentY - 4
        else
            TreeGeneralButton:Hide()
        end

        for _, section in ipairs(ModuleSectionHeaders) do
            local visibleEntries = BuildVisibleEntriesForSearch(section.entries, NormalizeSearchText(L("MODULES")))

            if #visibleEntries > 0 then
                visibleModuleSections[#visibleModuleSections + 1] = {
                    section = section,
                    entries = visibleEntries,
                }
                visibleModuleCount = visibleModuleCount + #visibleEntries
            end
        end

        if #visibleModuleSections > 0 then
            TreeModuleButton:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", groupX, currentY)
            TreeModuleButton.IsExpanded = true
            ApplyToggleVisual(TreeModuleButton, false)
            TreeModuleIndicator:SetText("-")
            TreeModuleButton:Show()
            currentY = currentY - 34

            for _, sectionState in ipairs(visibleModuleSections) do
                local section = sectionState.section

                section.frame:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", sectionX, currentY)
                section.frame:Show()
                currentY = currentY - 28

                for _, entry in ipairs(sectionState.entries) do
                    entry.button:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", sectionChildX, currentY)
                    entry.button:Show()
                    currentY = currentY - 28
                end

                currentY = currentY - 10
            end
        else
            TreeModuleButton:Hide()
        end

        local totalVisibleEntries = visibleGeneralCount + visibleModuleCount

        if totalVisibleEntries > 0 then
            SetSearchStatusText(L("NAVIGATION_SEARCH_RESULTS"):format(totalVisibleEntries), 1, 0.82, 0)
        else
            SetSearchStatusText(L("NAVIGATION_SEARCH_EMPTY"), 1, 0.45, 0.45)
        end

        UpdateTreeScrollLayout(currentY)
        return
    end

    TreeGeneralButton:Show()
    TreeModuleButton:Show()
    SetSearchStatusText(L("NAVIGATION_SEARCH_HINT"))

    TreeGeneralButton:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", groupX, currentY)

    if GeneralExpanded then
        TreeGeneralIndicator:SetText("-")
        currentY = currentY - 34

        for _, entry in ipairs(GeneralEntries) do
            entry.button:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", childX, currentY)
            entry.button:Show()
            currentY = currentY - 30
        end

        currentY = currentY - 4
    else
        TreeGeneralIndicator:SetText("+")
        currentY = currentY - 40
    end

    TreeModuleButton:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", groupX, currentY)

    if not ModuleExpanded then
        TreeModuleIndicator:SetText("+")
        UpdateTreeScrollLayout(currentY - 12)
        return
    end

    TreeModuleIndicator:SetText("-")
    currentY = currentY - 34

    for _, section in ipairs(ModuleSectionHeaders) do
        section.frame:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", sectionX, currentY)
        section.frame:Show()
        currentY = currentY - 28

        for _, entry in ipairs(section.entries) do
            entry.button:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", sectionChildX, currentY)
            entry.button:Show()
            currentY = currentY - 28
        end

        currentY = currentY - 10
    end

    UpdateTreeScrollLayout(currentY)
end

SidebarScrollFrame:SetScript("OnSizeChanged", function()
    UpdateTreeLayout()
end)

SidebarScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local step = 44
    local currentScroll = self:GetVerticalScroll()
    local maxScroll = math.max(0, Sidebar:GetHeight() - self:GetHeight())
    local nextScroll = currentScroll - (delta * step)

    if nextScroll < 0 then
        nextScroll = 0
    elseif nextScroll > maxScroll then
        nextScroll = maxScroll
    end

    self:SetVerticalScroll(nextScroll)
end)

BeavisQoL.UpdateTree = function()
    SidebarCaption:SetText(L("NAVIGATION"))
    SidebarCaptionHint:SetText(L("NAVIGATION_HINT"))
    SidebarSearchPlaceholder:SetText(L("NAVIGATION_SEARCH_PLACEHOLDER"))

    TreeGeneralButton.Text:SetText(L("GENERAL"))
    TreeModuleButton.Text:SetText(L("MODULES"))

    TreeHomeText:SetText(L("HOME"))
    TreeVersionText:SetText(L("VERSION"))
    TreeSettingsText:SetText(L("SETTINGS"))

    ProgressSection.text:SetText(L("PROGRESS"))
    GoldSection.text:SetText(L("GOLD_TRADE"))
    ComfortSection.text:SetText(L("COMFORT"))
    InterfaceSection.text:SetText(L("INTERFACE_COMBAT"))
    GroupSection.text:SetText(L("GROUP_SEARCH"))
    StreamerSection.text:SetText(L("STREAMER_TOOLS"))
    CompanionSection.text:SetText(L("COMPANION"))

    LevelTimeEntry.text:SetText(L("LEVEL_TIME"))
    ChecklistEntry.text:SetText(L("CHECKLIST"))
    WeeklyKeysEntry.text:SetText(L("WEEKLY_KEYS"))
    ItemLevelGuideEntry.text:SetText(L("ITEMLEVEL_GUIDE"))
    QuestCheckEntry.text:SetText(L("QUEST_CHECK"))
    QuestAbandonEntry.text:SetText(L("QUEST_ABANDON"))
    LoggingEntry.text:SetText(L("LOGGING"))
    AutoSellEntry.text:SetText(L("AUTOSELL_JUNK"))
    AutoRepairEntry.text:SetText(L("AUTOREPAIR"))
    FastLootEntry.text:SetText(L("FAST_LOOT"))
    EasyDeleteEntry.text:SetText(L("EASY_DELETE"))
    TooltipItemLevelEntry.text:SetText(L("TOOLTIP_ITEMLEVEL"))
    CameraDistanceEntry.text:SetText(L("CAMERA_DISTANCE"))
    FishingEntry.text:SetText(L("FISHING_HELPER"))
    StatsEntry.text:SetText(L("STATS"))
    MarkerBarEntry.text:SetText(L("MARKER_BAR"))
    CombatTextEntry.text:SetText(L("COMBAT_TEXT"))
    MouseHelperEntry.text:SetText(L("MOUSE_HELPER"))
    BossGuidesEntry.text:SetText(L("BOSS_GUIDES"))
    LFGEntry.text:SetText(L("LFG"))
    StreamerPlannerEntry.text:SetText(L("STREAMER_PLANNER"))
    PetStuffEntry.text:SetText(L("PET_STUFF"))

    RefreshSearchIndex()
    UpdateSearchPlaceholder()
    UpdateTreeLayout()
end

function BeavisQoL.OpenPage(pageKey, activeTextOverride)
    if not BeavisQoL.Frame or not Pages then
        return
    end

    local pageMap = {
        Home = { page = Pages.Home, text = TreeHomeText, group = "general" },
        Version = { page = Pages.Version, text = TreeVersionText, group = "general" },
        Settings = { page = Pages.Settings, text = TreeSettingsText, group = "general" },
        LevelTime = { page = Pages.LevelTime, text = LevelTimeEntry.text, group = "module" },
        Checklist = { page = Pages.Checklist, text = ChecklistEntry.text, group = "module" },
        WeeklyKeys = { page = Pages.WeeklyKeys, text = WeeklyKeysEntry.text, group = "module" },
        ItemLevelGuide = { page = Pages.ItemLevelGuide, text = ItemLevelGuideEntry.text, group = "module" },
        Logging = { page = Pages.Logging, text = LoggingEntry.text, group = "module" },
        QuestCheck = { page = Pages.QuestCheck, text = QuestCheckEntry.text, group = "module" },
        QuestAbandon = { page = Pages.QuestAbandon, text = QuestAbandonEntry.text, group = "module" },
        Misc = { page = Pages.Misc, text = nil, group = "module" },
        Fishing = { page = Pages.Fishing, text = FishingEntry.text, group = "module" },
        Stats = { page = Pages.Stats, text = StatsEntry.text, group = "module" },
        MarkerBar = { page = Pages.MarkerBar, text = MarkerBarEntry.text, group = "module" },
        PetStuff = { page = Pages.PetStuff, text = PetStuffEntry.text, group = "module" },
        LFG = { page = Pages.LFG, text = LFGEntry.text, group = "module" },
        StreamerPlanner = { page = Pages.StreamerPlanner, text = StreamerPlannerEntry.text, group = "module" },
        DamageText = { page = Pages.DamageText, text = CombatTextEntry.text, group = "module" },
        MouseHelper = { page = Pages.MouseHelper, text = MouseHelperEntry.text, group = "module" },
        BossGuides = { page = Pages.BossGuides, text = BossGuidesEntry.text, group = "module" },
    }

    local target = pageMap[pageKey]
    if not target or not target.page then
        return
    end

    if target.group == "general" then
        GeneralExpanded = true
    elseif target.group == "module" then
        ModuleExpanded = true
    end

    UpdateTreeLayout()

    if not BeavisQoL.Frame:IsShown() then
        BeavisQoL.Frame:Show()
    end

    ShowPage(target.page)
    SetActiveTreeItem(activeTextOverride or target.text)
end

function BeavisQoL.OpenMiscSection(sectionKey, activeTextOverride)
    BeavisQoL.OpenPage("Misc", activeTextOverride)

    local miscPage = Pages and Pages.Misc
    if miscPage and miscPage.OpenSection then
        miscPage:OpenSection(sectionKey)
    end
end

TreeGeneralButton:SetScript("OnClick", function()
    if IsSearchActive() then
        return
    end

    GeneralExpanded = not GeneralExpanded
    UpdateTreeLayout()
end)

TreeModuleButton:SetScript("OnClick", function()
    if IsSearchActive() then
        return
    end

    ModuleExpanded = not ModuleExpanded
    UpdateTreeLayout()
end)

TreeHomeButton:SetScript("OnClick", function()
    BeavisQoL.OpenPage("Home")
end)

TreeVersionButton:SetScript("OnClick", function()
    BeavisQoL.OpenPage("Version")
end)

TreeSettingsButton:SetScript("OnClick", function()
    BeavisQoL.OpenPage("Settings")
end)

for _, entry in ipairs(ModuleEntries) do
    entry.button:SetScript("OnClick", function()
        if entry.miscSection then
            BeavisQoL.OpenMiscSection(entry.miscSection, entry.text)
            return
        end

        BeavisQoL.OpenPage(entry.pageKey, entry.text)
    end)
end

SidebarSearchEditBox:SetScript("OnTextChanged", function(self)
    NavigationSearchQuery = NormalizeSearchText(self:GetText())
    UpdateSearchPlaceholder()
    UpdateTreeLayout()
end)

SidebarSearchEditBox:SetScript("OnEditFocusGained", function()
    UpdateSearchPlaceholder()
end)

SidebarSearchEditBox:SetScript("OnEditFocusLost", function()
    UpdateSearchPlaceholder()
end)

SidebarSearchEditBox:SetScript("OnEscapePressed", function(self)
    self:SetText("")
    self:ClearFocus()
end)

UpdateTreeLayout()
ShowPage(Pages.Home)
SetActiveTreeItem(TreeHomeText)
