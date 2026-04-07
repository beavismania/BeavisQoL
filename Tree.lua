local ADDON_NAME, BeavisQoL = ...

--[[
Tree.lua rendert die linke Navigation.
Die Seite selbst zeigt keine Inhalte, sondern nur:
- Unterkategorien
- Modulsektionen
- Einträge zum Öffnen der Seiten
]]

local SidebarFrame = BeavisQoL.Sidebar
local Pages = BeavisQoL.Pages

local L = BeavisQoL.L
local FrameWithBackdrop = BackdropTemplateMixin and "BackdropTemplate" or nil

local NAV_SECTION_HEIGHT = 18
local NAV_SECTION_STEP = 21
local NAV_GROUP_GAP = 7
local NAV_ENTRY_HEIGHT = 24
local NAV_ENTRY_STEP = 26
local NAV_SECTION_LEFT = 10
local NAV_ENTRY_LEFT = 6
local NAV_RIGHT_INSET = 9

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

local SEARCH_FRAME_BACKDROP = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 10,
    insets = {
        left = 3,
        right = 3,
        top = 3,
        bottom = 3,
    },
}

local NAV_ENTRY_BACKDROP = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 10,
    insets = {
        left = 3,
        right = 3,
        top = 3,
        bottom = 3,
    },
}

local SidebarCaption = SidebarFrame:CreateFontString(nil, "ARTWORK")
SidebarCaption:SetPoint("TOPLEFT", SidebarFrame, "TOPLEFT", 15, -13)
SidebarCaption:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
SidebarCaption:SetTextColor(0.98, 0.88, 0.68, 1)
SidebarCaption:SetText(L("NAVIGATION"))

local SidebarCaptionHint = SidebarFrame:CreateFontString(nil, "ARTWORK")
SidebarCaptionHint:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
SidebarCaptionHint:SetTextColor(0.78, 0.74, 0.68, 0.76)

local SidebarSearchFrame = CreateFrame("Frame", nil, SidebarFrame, FrameWithBackdrop)
SidebarSearchFrame:SetHeight(24)
if SidebarSearchFrame.SetBackdrop then
    SidebarSearchFrame:SetBackdrop(SEARCH_FRAME_BACKDROP)
    SidebarSearchFrame:SetBackdropColor(0.09, 0.07, 0.05, 0.84)
    SidebarSearchFrame:SetBackdropBorderColor(0.72, 0.6, 0.4, 0.32)
end

local SidebarSearchShade = SidebarSearchFrame:CreateTexture(nil, "BACKGROUND")
SidebarSearchShade:SetAllPoints()
SidebarSearchShade:SetTexture("Interface\\Buttons\\WHITE8X8")
ApplyTextureGradient(SidebarSearchShade, "VERTICAL", 0.32, 0.22, 0.12, 0.14, 0.08, 0.05, 0.03, 0.02)

local SidebarSearchGlow = SidebarSearchFrame:CreateTexture(nil, "ARTWORK")
SidebarSearchGlow:SetPoint("TOPLEFT", SidebarSearchFrame, "TOPLEFT", 6, -4)
SidebarSearchGlow:SetPoint("TOPRIGHT", SidebarSearchFrame, "TOPRIGHT", -6, -4)
SidebarSearchGlow:SetHeight(5)
SidebarSearchGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
ApplyTextureGradient(SidebarSearchGlow, "VERTICAL", 1, 0.95, 0.78, 0.14, 1, 0.95, 0.78, 0)
SidebarSearchGlow:SetAlpha(0.38)

local SidebarSearchEditBox = CreateFrame("EditBox", nil, SidebarSearchFrame)
SidebarSearchEditBox:SetPoint("TOPLEFT", SidebarSearchFrame, "TOPLEFT", 9, -4)
SidebarSearchEditBox:SetPoint("BOTTOMRIGHT", SidebarSearchFrame, "BOTTOMRIGHT", -9, 4)
SidebarSearchEditBox:SetAutoFocus(false)
SidebarSearchEditBox:SetMaxLetters(80)
SidebarSearchEditBox:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
SidebarSearchEditBox:SetTextColor(0.97, 0.94, 0.89, 1)

local SidebarSearchPlaceholder = SidebarSearchFrame:CreateFontString(nil, "ARTWORK")
SidebarSearchPlaceholder:SetPoint("LEFT", SidebarSearchEditBox, "LEFT", 0, 0)
SidebarSearchPlaceholder:SetPoint("RIGHT", SidebarSearchEditBox, "RIGHT", 0, 0)
SidebarSearchPlaceholder:SetJustifyH("LEFT")
SidebarSearchPlaceholder:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
SidebarSearchPlaceholder:SetTextColor(0.62, 0.58, 0.53, 0.92)
SidebarSearchPlaceholder:SetText(L("NAVIGATION_SEARCH_PLACEHOLDER"))

local SidebarSearchStatus = SidebarFrame:CreateFontString(nil, "ARTWORK")
SidebarSearchStatus:SetPoint("TOPLEFT", SidebarSearchFrame, "BOTTOMLEFT", 2, -4)
SidebarSearchStatus:SetPoint("RIGHT", SidebarFrame, "RIGHT", -16, 0)
SidebarSearchStatus:SetJustifyH("LEFT")
SidebarSearchStatus:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
SidebarSearchStatus:SetTextColor(0.82, 0.76, 0.68, 1)
SidebarSearchStatus:Hide()

local SidebarScrollFrame = CreateFrame("ScrollFrame", nil, SidebarFrame, "UIPanelScrollFrameTemplate")
SidebarScrollFrame:SetPoint("TOPLEFT", SidebarSearchStatus, "BOTTOMLEFT", -2, -8)
SidebarScrollFrame:SetPoint("BOTTOMRIGHT", SidebarFrame, "BOTTOMRIGHT", -28, 8)
SidebarScrollFrame:EnableMouseWheel(true)

local Sidebar = CreateFrame("Frame", nil, SidebarScrollFrame)
Sidebar:SetSize(1, 1)
SidebarScrollFrame:SetScrollChild(Sidebar)

local NavigationSearchQuery = ""

local GeneralEntries = {}
local ModuleSectionHeaders = {}
local ModuleEntries = {}
local AllEntries = {}
local GeneralSectionHeader

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

local function GetSectionSearchText(section)
    return section and section.searchText or ""
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
    if GeneralSectionHeader then
        RefreshSectionSearchText(GeneralSectionHeader)
    end

    for _, section in ipairs(ModuleSectionHeaders) do
        RefreshSectionSearchText(section)
    end

    for _, entry in ipairs(AllEntries) do
        RefreshEntrySearchText(entry)
    end
end

local function UpdateSidebarHeaderLayout()
    local hintText = L("NAVIGATION_HINT")

    SidebarCaptionHint:ClearAllPoints()
    SidebarSearchFrame:ClearAllPoints()

    if hintText and hintText ~= "" then
        SidebarCaptionHint:SetPoint("TOPLEFT", SidebarCaption, "BOTTOMLEFT", 1, -2)
        SidebarCaptionHint:SetPoint("RIGHT", SidebarFrame, "RIGHT", -18, 0)
        SidebarCaptionHint:SetText(hintText)
        SidebarCaptionHint:Show()
        SidebarSearchFrame:SetPoint("TOPLEFT", SidebarCaptionHint, "BOTTOMLEFT", -4, -7)
    else
        SidebarCaptionHint:SetText("")
        SidebarCaptionHint:Hide()
        SidebarSearchFrame:SetPoint("TOPLEFT", SidebarCaption, "BOTTOMLEFT", -4, -8)
    end

    SidebarSearchFrame:SetPoint("RIGHT", SidebarFrame, "RIGHT", -14, 0)
end

local function UpdateSearchFrameVisual()
    local isActive = SidebarSearchEditBox:HasFocus() or SidebarSearchEditBox:GetText() ~= ""

    if SidebarSearchFrame.SetBackdropColor then
        SidebarSearchFrame:SetBackdropColor(0.09, 0.07, 0.05, isActive and 0.92 or 0.84)
    end

    if SidebarSearchFrame.SetBackdropBorderColor then
        SidebarSearchFrame:SetBackdropBorderColor(0.8, 0.67, 0.45, isActive and 0.58 or 0.32)
    end

    SidebarSearchGlow:SetAlpha(isActive and 0.62 or 0.38)
end

local function UpdateSearchPlaceholder()
    if SidebarSearchEditBox:HasFocus() or SidebarSearchEditBox:GetText() ~= "" then
        SidebarSearchPlaceholder:Hide()
    else
        SidebarSearchPlaceholder:Show()
    end

    UpdateSearchFrameVisual()
end

local function SetSearchStatusText(text, red, green, blue)
    if not IsSearchActive() or not text or text == "" then
        SidebarSearchStatus:SetText("")
        SidebarSearchStatus:Hide()
        return
    end

    SidebarSearchStatus:SetText(text)
    SidebarSearchStatus:SetTextColor(red or 0.82, green or 0.76, blue or 0.68, 1)
    SidebarSearchStatus:Show()
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
        if entry.button.SetBackdropColor then
            entry.button:SetBackdropColor(0.13, 0.11, 0.09, 0.72)
        end
        if entry.button.SetBackdropBorderColor then
            entry.button:SetBackdropBorderColor(0.74, 0.63, 0.48, 0.34)
        end
        entry.button.Sheen:SetAlpha(0.36)
        entry.button.InnerGlow:SetAlpha(0.04)
        entry.text:SetTextColor(0.99, 0.96, 0.9, 1)
        return
    end

    if hovered then
        if entry.button.SetBackdropColor then
            entry.button:SetBackdropColor(0.11, 0.09, 0.075, 0.28)
        end
        if entry.button.SetBackdropBorderColor then
            entry.button:SetBackdropBorderColor(0.62, 0.52, 0.4, 0.16)
        end
        entry.button.Sheen:SetAlpha(0.12)
        entry.button.InnerGlow:SetAlpha(0.015)
        entry.text:SetTextColor(0.98, 0.93, 0.84, 1)
        return
    end

    if entry.button.SetBackdropColor then
        entry.button:SetBackdropColor(0.08, 0.06, 0.045, 0)
    end
    if entry.button.SetBackdropBorderColor then
        entry.button:SetBackdropBorderColor(0.58, 0.48, 0.38, 0)
    end
    entry.button.Sheen:SetAlpha(0)
    entry.button.InnerGlow:SetAlpha(0)
    entry.text:SetTextColor(0.93, 0.84, 0.72, 1)
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
    local button = CreateFrame("Button", nil, Sidebar, FrameWithBackdrop)
    button:SetHeight(NAV_ENTRY_HEIGHT)
    button:SetHitRectInsets(-4, -4, -2, -2)

    if button.SetBackdrop then
        button:SetBackdrop(NAV_ENTRY_BACKDROP)
        button:SetBackdropColor(0.08, 0.06, 0.045, 0)
        button:SetBackdropBorderColor(0.58, 0.48, 0.38, 0)
    end

    local innerGlow = button:CreateTexture(nil, "BACKGROUND")
    innerGlow:SetPoint("TOPLEFT", button, "TOPLEFT", 5, -4)
    innerGlow:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -5, 4)
    innerGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
    ApplyTextureGradient(innerGlow, "HORIZONTAL", 1, 0.86, 0.58, 0.05, 1, 0.86, 0.58, 0.01)
    innerGlow:SetAlpha(0)
    button.InnerGlow = innerGlow

    local sheen = button:CreateTexture(nil, "ARTWORK")
    sheen:SetPoint("TOPLEFT", button, "TOPLEFT", 8, -4)
    sheen:SetPoint("TOPRIGHT", button, "TOPRIGHT", -8, -4)
    sheen:SetHeight(5)
    sheen:SetTexture("Interface\\Buttons\\WHITE8X8")
    ApplyTextureGradient(sheen, "VERTICAL", 1, 1, 1, 0.05, 1, 1, 1, 0)
    sheen:SetAlpha(0)
    button.Sheen = sheen

    local text = button:CreateFontString(nil, "OVERLAY")
    text:SetPoint("LEFT", button, "LEFT", 12, 0)
    text:SetPoint("RIGHT", button, "RIGHT", -10, 0)
    text:SetJustifyH("LEFT")
    text:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    text:SetWordWrap(false)
    text:SetShadowOffset(1, -1)
    text:SetShadowColor(0, 0, 0, 0.35)
    text:SetTextColor(0.93, 0.84, 0.72, 1)
    text:SetText(L(labelTextKey))

    return button, text
end

local function CreateSectionHeader(labelTextKey)
    local frame = CreateFrame("Frame", nil, Sidebar)
    frame:SetHeight(NAV_SECTION_HEIGHT)

    local line = frame:CreateTexture(nil, "BACKGROUND")
    line:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 5, 0)
    line:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 0)
    line:SetHeight(1)
    line:SetTexture("Interface\\Buttons\\WHITE8X8")
    ApplyTextureGradient(line, "HORIZONTAL", 0.86, 0.72, 0.46, 0.18, 0.86, 0.72, 0.46, 0)

    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -1)
    text:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
    text:SetJustifyH("LEFT")
    text:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    text:SetWordWrap(false)
    text:SetShadowOffset(1, -1)
    text:SetShadowColor(0, 0, 0, 0.35)
    text:SetTextColor(0.9, 0.8, 0.62, 0.95)
    text:SetText(L(labelTextKey))

    return frame, text
end

local function RegisterGeneralEntry(pageKey, labelTextKey, options)
    local button, text = CreateEntryButton(labelTextKey)
    local entry = {
        pageKey = pageKey,
        button = button,
        text = text,
        miscSection = nil,
        searchTextKeys = options and options.searchTextKeys or {},
        searchAliases = options and options.searchAliases or nil,
        section = GeneralSectionHeader,
        isActive = false,
    }

    GeneralEntries[#GeneralEntries + 1] = entry
    if GeneralSectionHeader then
        GeneralSectionHeader.entries[#GeneralSectionHeader.entries + 1] = entry
    end
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

GeneralSectionHeader = {
    frame = nil,
    text = nil,
    entries = {},
    searchText = "",
}

do
    local frame, text = CreateSectionHeader("NAVIGATION_SECTION_ADDON")
    GeneralSectionHeader.frame = frame
    GeneralSectionHeader.text = text
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
    searchTextKeys = { "WELCOME_SUBTITLE", "WELCOME_BODY", "PROJECT_STATUS", "TWITCH_BODY", "DISCORD_BODY" },
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

local ProgressSection = RegisterModuleSection("PROGRESS_QUESTS")
local GoldSection = RegisterModuleSection("GOLD_VENDOR")
local EverydaySection = RegisterModuleSection("EVERYDAY_AUTOMATION")
local WindowsSection = RegisterModuleSection("WINDOWS_SEARCH")
local WorldSection = RegisterModuleSection("WORLD_TRAVEL")
local InterfaceSection = RegisterModuleSection("INTERFACE_OVERLAYS")
local GroupSection = RegisterModuleSection("GROUP_INSTANCES")
local StreamerSection = RegisterModuleSection("STREAMER_TOOLS")

local LevelTimeEntry = RegisterModuleEntry(ProgressSection, "LEVEL_TIME", "LevelTime", {
    searchTextKeys = { "LEVELTIME_TOOLTIP_TITLE", "LEVELTIME_TOOLTIP_TEXT", "CURRENT_LEVEL", "TIME_ON_CURRENT_LEVEL", "TOTAL_TIME" },
    searchAliases = "level xp leveling time tracker",
})
local ChecklistEntry = RegisterModuleEntry(ProgressSection, "CHECKLIST", "Checklist", {
    searchTextKeys = { "CHECKLIST_DESC", "CHECKLIST_INTRO_HINT", "CHECKLIST_DAILY_HINT", "CHECKLIST_WEEKLY_HINT", "CHECKLIST_SHOW_TRACKER_HINT" },
    searchAliases = "todo daily weekly tracker tasks",
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

local LoggingEntry = RegisterModuleEntry(GoldSection, "GOLDAUSWERTUNG", "Logging", {
    searchTextKeys = { "LOGGING_DESC", "LOGGING_SALES_HINT", "LOGGING_REPAIRS_HINT", "LOGGING_INCOME_HINT", "LOGGING_EXPENSE_HINT" },
    searchAliases = "gold sales repairs income expenses vendor auction trade",
})
local AutoSellEntry = RegisterModuleEntry(GoldSection, "AUTOSELL_JUNK", "AutoSell", {
    miscSection = "AutoSell",
    searchTextKeys = { "AUTOSELL_HINT", "LOGGING_AUTOSELL" },
    searchAliases = "sell junk gray vendor trash",
})
local AutoRepairEntry = RegisterModuleEntry(GoldSection, "AUTOREPAIR", "AutoRepair", {
    miscSection = "AutoRepair",
    searchTextKeys = { "AUTOREPAIR_HINT", "AUTOREPAIR_GUILD_HINT" },
    searchAliases = "repair merchant guild gear",
})

local FastLootEntry = RegisterModuleEntry(EverydaySection, "FAST_LOOT", "FastLoot", {
    miscSection = "FastLoot",
    searchTextKeys = { "FAST_LOOT_HINT" },
    searchAliases = "loot auto loot plunder",
})
local EasyDeleteEntry = RegisterModuleEntry(EverydaySection, "EASY_DELETE", "EasyDelete", {
    miscSection = "EasyDelete",
    searchTextKeys = { "EASY_DELETE_HINT" },
    searchAliases = "delete remove confirm item",
})
local CutsceneSkipEntry = RegisterModuleEntry(EverydaySection, "CUTSCENE_SKIP", "CutsceneSkip", {
    miscSection = "CutsceneSkip",
    searchTextKeys = { "CUTSCENE_SKIP_HINT" },
    searchAliases = "cutscene cinematic movie story video skip autoskip",
})
local AutoRespawnPetEntry = RegisterModuleEntry(EverydaySection, "AUTO_RESPAWN_PET_TITLE", "AutoRespawnPet", {
    miscSection = "AutoRespawnPet",
    searchTextKeys = { "AUTO_RESPAWN_PET_HINT" },
    searchAliases = "pet companion battle pet respawn summon revive",
})
local FlightMasterTimerEntry = RegisterModuleEntry(WorldSection, "FLIGHT_MASTER_TIMER", "FlightMasterTimer", {
    miscSection = "FlightMasterTimer",
    searchTextKeys = { "FLIGHT_MASTER_TIMER_HINT", "FLIGHT_MASTER_TIMER_UNKNOWN" },
    searchAliases = "flight taxi gryphon wyvern flightmaster travel timer arrival countdown",
})
local TooltipItemLevelEntry = RegisterModuleEntry(WindowsSection, "TOOLTIP_ITEMLEVEL", "TooltipItemLevel", {
    miscSection = "TooltipItemLevel",
    searchTextKeys = { "TOOLTIP_ITEMLEVEL_HINT", "TOOLTIP_ITEMLEVEL_LABEL" },
    searchAliases = "tooltip inspect ilvl itemlevel mouseover",
})
local CameraDistanceEntry = RegisterModuleEntry(EverydaySection, "CAMERA_DISTANCE", "CameraDistance", {
    miscSection = "CameraDistance",
    searchTextKeys = { "CAMERA_DISTANCE_HINT", "CAMERA_DISTANCE_MAX" },
    searchAliases = "camera zoom distance max",
})
local MacroFrameEntry = RegisterModuleEntry(WindowsSection, "MACRO_FRAME", "MacroFrame", {
    miscSection = "MacroFrame",
    searchTextKeys = { "MACRO_FRAME_HINT" },
    searchAliases = "macro macros macroframe macro ui window larger bigger",
})
local ReputationSearchEntry = RegisterModuleEntry(WindowsSection, "REPUTATION_SEARCH", "ReputationSearch", {
    miscSection = "ReputationSearch",
    searchTextKeys = { "REPUTATION_SEARCH_HINT", "REPUTATION_SEARCH_PLACEHOLDER" },
    searchAliases = "reputation factions renown standing search filter ruf",
})
local CurrencySearchEntry = RegisterModuleEntry(WindowsSection, "CURRENCY_SEARCH", "CurrencySearch", {
    miscSection = "CurrencySearch",
    searchTextKeys = { "CURRENCY_SEARCH_HINT", "CURRENCY_SEARCH_PLACEHOLDER" },
    searchAliases = "currency currencies search filter token badge crest währung",
})
local PreyHuntProgressEntry = RegisterModuleEntry(WorldSection, "PREY_HUNT_PROGRESS", "PreyHuntProgress", {
    miscSection = "PreyHuntProgress",
    searchTextKeys = { "PREY_HUNT_PROGRESS_HINT" },
    searchAliases = "midnight prey hunt jagd progress percent prozent symbol",
})
local WeeklyKeysEntry = RegisterModuleEntry(GroupSection, "WEEKLY_KEYS", "WeeklyKeys", {
    searchTextKeys = { "WEEKLY_KEYS_DESC", "WEEKLY_KEYS_SHOW_OVERLAY_HINT", "WEEKLY_KEYS_SUMMARY" },
    searchAliases = "mythic dungeon vault overlay",
})
local KeystoneActionsEntry = RegisterModuleEntry(GroupSection, "KEYSTONE_ACTIONS", "KeystoneActions", {
    miscSection = "KeystoneActions",
    searchTextKeys = { "KEYSTONE_ACTIONS_HINT", "KEYSTONE_ACTIONS_READYCHECK", "KEYSTONE_ACTIONS_PULLTIMER" },
    searchAliases = "mythic plus keystone readycheck pulltimer countdown start",
})
local PortalViewerEntry = RegisterModuleEntry(WorldSection, "PORTAL_VIEWER_TITLE", "PortalViewer", {
    miscSection = "PortalViewer",
    searchTextKeys = { "PORTAL_VIEWER_HINT", "PORTAL_VIEWER_SECTION_AVAILABLE", "PORTAL_VIEWER_SECTION_MISSING" },
    searchAliases = "portal viewer portals dungeon teleport midnight mythic plus season",
})
local FishingEntry = RegisterModuleEntry(WorldSection, "FISHING_HELPER", "Fishing", {
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
    searchAliases = "mouse cursor circle trail pointer highlight blizzard large cast casting ring progress",
})
local MinimapCollectorEntry = RegisterModuleEntry(InterfaceSection, "MINIMAP_COLLECTOR", "MinimapCollector", {
    searchTextKeys = {
        "MINIMAP_COLLECTOR_DESC",
        "MINIMAP_COLLECTOR_ENABLE",
        "MINIMAP_COLLECTOR_BUTTONS_DESC",
        "MINIMAP_COLLECTOR_BUTTONS_HINT",
    },
    searchAliases = "minimap collector buttons tray launcher drag transparent panel",
})
local BossGuidesEntry = RegisterModuleEntry(GroupSection, "BOSS_GUIDES", "BossGuides", {
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
    searchTextKeys = { "LFG_DESC", "FLAGS_HINT", "EASY_LFG_HINT", "EASY_LFG_SHOW_OVERLAY_HINT", "INVITE_TIMER_HINT" },
    searchAliases = "group finder premade flags realms applicants invite easy lfg overlay queue timer countdown ready",
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

local function SetActiveTreeItem(activeText)
    for _, entry in ipairs(AllEntries) do
        entry.isActive = activeText ~= nil and entry.text == activeText
        ApplyEntryVisual(entry, false)
    end
end

local function UpdateTreeScrollLayout(contentBottomY)
    Sidebar:SetWidth(math.max(1, SidebarScrollFrame:GetWidth()))
    Sidebar:SetHeight(math.max(SidebarScrollFrame:GetHeight(), -contentBottomY + 20))

    local maxScroll = math.max(0, Sidebar:GetHeight() - SidebarScrollFrame:GetHeight())
    if SidebarScrollFrame:GetVerticalScroll() > maxScroll then
        SidebarScrollFrame:SetVerticalScroll(maxScroll)
    end
end

local function HideSection(section)
    section.frame:Hide()
    section.frame:ClearAllPoints()

    for _, entry in ipairs(section.entries) do
        entry.button:Hide()
        entry.button:ClearAllPoints()
    end
end

local function LayoutSectionFrame(section, currentY)
    section.frame:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", NAV_SECTION_LEFT, currentY)
    section.frame:SetPoint("RIGHT", Sidebar, "RIGHT", -NAV_RIGHT_INSET, 0)
    section.frame:Show()
    return currentY - NAV_SECTION_STEP
end

local function LayoutEntryButton(entry, currentY)
    entry.button:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", NAV_ENTRY_LEFT, currentY)
    entry.button:SetPoint("RIGHT", Sidebar, "RIGHT", -NAV_RIGHT_INSET, 0)
    entry.button:Show()
    return currentY - NAV_ENTRY_STEP
end

local function UpdateTreeLayout()
    for _, entry in ipairs(GeneralEntries) do
        entry.button:Hide()
        entry.button:ClearAllPoints()
    end

    if GeneralSectionHeader then
        HideSection(GeneralSectionHeader)
    end

    for _, section in ipairs(ModuleSectionHeaders) do
        HideSection(section)
    end

    local currentY = -4

    if IsSearchActive() then
        local visibleGeneralEntries = BuildVisibleEntriesForSearch(GeneralEntries, NormalizeSearchText(L("NAVIGATION_SECTION_ADDON")))
        local visibleGeneralCount = #visibleGeneralEntries
        local visibleModuleCount = 0
        local visibleModuleSections = {}

        if visibleGeneralCount > 0 then
            currentY = LayoutSectionFrame(GeneralSectionHeader, currentY)

            for _, entry in ipairs(visibleGeneralEntries) do
                currentY = LayoutEntryButton(entry, currentY)
            end

            currentY = currentY - NAV_GROUP_GAP
        end

        for _, section in ipairs(ModuleSectionHeaders) do
            local visibleEntries = BuildVisibleEntriesForSearch(section.entries, GetSectionSearchText(section))

            if #visibleEntries > 0 then
                visibleModuleSections[#visibleModuleSections + 1] = {
                    section = section,
                    entries = visibleEntries,
                }
                visibleModuleCount = visibleModuleCount + #visibleEntries
            end
        end

        if #visibleModuleSections > 0 then
            for _, sectionState in ipairs(visibleModuleSections) do
                local section = sectionState.section

                currentY = LayoutSectionFrame(section, currentY)

                for _, entry in ipairs(sectionState.entries) do
                    currentY = LayoutEntryButton(entry, currentY)
                end

                currentY = currentY - NAV_GROUP_GAP
            end
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

    SetSearchStatusText(L("NAVIGATION_SEARCH_HINT"))

    currentY = LayoutSectionFrame(GeneralSectionHeader, currentY)

    for _, entry in ipairs(GeneralEntries) do
        currentY = LayoutEntryButton(entry, currentY)
    end

    currentY = currentY - NAV_GROUP_GAP

    for _, section in ipairs(ModuleSectionHeaders) do
        currentY = LayoutSectionFrame(section, currentY)

        for _, entry in ipairs(section.entries) do
            currentY = LayoutEntryButton(entry, currentY)
        end

        currentY = currentY - NAV_GROUP_GAP
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
    UpdateSidebarHeaderLayout()

    GeneralSectionHeader.text:SetText(L("NAVIGATION_SECTION_ADDON"))

    TreeHomeText:SetText(L("HOME"))
    TreeVersionText:SetText(L("VERSION"))
    TreeSettingsText:SetText(L("SETTINGS"))

    ProgressSection.text:SetText(L("PROGRESS_QUESTS"))
    GoldSection.text:SetText(L("GOLD_VENDOR"))
    EverydaySection.text:SetText(L("EVERYDAY_AUTOMATION"))
    WindowsSection.text:SetText(L("WINDOWS_SEARCH"))
    WorldSection.text:SetText(L("WORLD_TRAVEL"))
    InterfaceSection.text:SetText(L("INTERFACE_OVERLAYS"))
    GroupSection.text:SetText(L("GROUP_INSTANCES"))
    StreamerSection.text:SetText(L("STREAMER_TOOLS"))

    LevelTimeEntry.text:SetText(L("LEVEL_TIME"))
    ChecklistEntry.text:SetText(L("CHECKLIST"))
    WeeklyKeysEntry.text:SetText(L("WEEKLY_KEYS"))
    ItemLevelGuideEntry.text:SetText(L("ITEMLEVEL_GUIDE"))
    QuestCheckEntry.text:SetText(L("QUEST_CHECK"))
    QuestAbandonEntry.text:SetText(L("QUEST_ABANDON"))
    LoggingEntry.text:SetText(L("GOLDAUSWERTUNG"))
    AutoSellEntry.text:SetText(L("AUTOSELL_JUNK"))
    AutoRepairEntry.text:SetText(L("AUTOREPAIR"))
    FastLootEntry.text:SetText(L("FAST_LOOT"))
    EasyDeleteEntry.text:SetText(L("EASY_DELETE"))
    CutsceneSkipEntry.text:SetText(L("CUTSCENE_SKIP"))
    AutoRespawnPetEntry.text:SetText(L("AUTO_RESPAWN_PET_TITLE"))
    TooltipItemLevelEntry.text:SetText(L("TOOLTIP_ITEMLEVEL"))
    CameraDistanceEntry.text:SetText(L("CAMERA_DISTANCE"))
    MacroFrameEntry.text:SetText(L("MACRO_FRAME"))
    ReputationSearchEntry.text:SetText(L("REPUTATION_SEARCH"))
    CurrencySearchEntry.text:SetText(L("CURRENCY_SEARCH"))
    PreyHuntProgressEntry.text:SetText(L("PREY_HUNT_PROGRESS"))
    KeystoneActionsEntry.text:SetText(L("KEYSTONE_ACTIONS"))
    PortalViewerEntry.text:SetText(L("PORTAL_VIEWER_TITLE"))
    FishingEntry.text:SetText(L("FISHING_HELPER"))
    StatsEntry.text:SetText(L("STATS"))
    MarkerBarEntry.text:SetText(L("MARKER_BAR"))
    CombatTextEntry.text:SetText(L("COMBAT_TEXT"))
    MouseHelperEntry.text:SetText(L("MOUSE_HELPER"))
    MinimapCollectorEntry.text:SetText(L("MINIMAP_COLLECTOR"))
    BossGuidesEntry.text:SetText(L("BOSS_GUIDES"))
    LFGEntry.text:SetText(L("LFG"))
    StreamerPlannerEntry.text:SetText(L("STREAMER_PLANNER"))

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
        AutoSell = { page = Pages.Misc, text = AutoSellEntry.text, group = "module", miscSection = "AutoSell" },
        AutoRepair = { page = Pages.Misc, text = AutoRepairEntry.text, group = "module", miscSection = "AutoRepair" },
        FastLoot = { page = Pages.Misc, text = FastLootEntry.text, group = "module", miscSection = "FastLoot" },
        EasyDelete = { page = Pages.Misc, text = EasyDeleteEntry.text, group = "module", miscSection = "EasyDelete" },
        CutsceneSkip = { page = Pages.Misc, text = CutsceneSkipEntry.text, group = "module", miscSection = "CutsceneSkip" },
        AutoRespawnPet = { page = Pages.Misc, text = AutoRespawnPetEntry.text, group = "module", miscSection = "AutoRespawnPet" },
        FlightMasterTimer = { page = Pages.Misc, text = FlightMasterTimerEntry.text, group = "module", miscSection = "FlightMasterTimer" },
        TooltipItemLevel = { page = Pages.Misc, text = TooltipItemLevelEntry.text, group = "module", miscSection = "TooltipItemLevel" },
        CameraDistance = { page = Pages.Misc, text = CameraDistanceEntry.text, group = "module", miscSection = "CameraDistance" },
        MacroFrame = { page = Pages.Misc, text = MacroFrameEntry.text, group = "module", miscSection = "MacroFrame" },
        ReputationSearch = { page = Pages.Misc, text = ReputationSearchEntry.text, group = "module", miscSection = "ReputationSearch" },
        CurrencySearch = { page = Pages.Misc, text = CurrencySearchEntry.text, group = "module", miscSection = "CurrencySearch" },
        PreyHuntProgress = { page = Pages.Misc, text = PreyHuntProgressEntry.text, group = "module", miscSection = "PreyHuntProgress" },
        KeystoneActions = { page = Pages.Misc, text = KeystoneActionsEntry.text, group = "module", miscSection = "KeystoneActions" },
        PortalViewer = { page = Pages.Misc, text = PortalViewerEntry.text, group = "module", miscSection = "PortalViewer" },
        Fishing = { page = Pages.Fishing, text = FishingEntry.text, group = "module" },
        Stats = { page = Pages.Stats, text = StatsEntry.text, group = "module" },
        MarkerBar = { page = Pages.MarkerBar, text = MarkerBarEntry.text, group = "module" },
        LFG = { page = Pages.LFG, text = LFGEntry.text, group = "module" },
        StreamerPlanner = { page = Pages.StreamerPlanner, text = StreamerPlannerEntry.text, group = "module" },
        DamageText = { page = Pages.DamageText, text = CombatTextEntry.text, group = "module" },
        MouseHelper = { page = Pages.MouseHelper, text = MouseHelperEntry.text, group = "module" },
        MinimapCollector = { page = Pages.MinimapCollector, text = MinimapCollectorEntry.text, group = "module" },
        BossGuides = { page = Pages.BossGuides, text = BossGuidesEntry.text, group = "module" },
    }

    local target = pageMap[pageKey]
    if not target or not target.page then
        return
    end

    local miscPage = Pages and Pages.Misc
    if miscPage and miscPage.SetStandaloneSection then
        if target.page == miscPage then
            miscPage:SetStandaloneSection(target.miscSection)
        else
            miscPage:SetStandaloneSection(nil)
        end
    end

    UpdateTreeLayout()

    if not BeavisQoL.Frame:IsShown() then
        BeavisQoL.Frame:Show()
    end

    ShowPage(target.page)
    SetActiveTreeItem(activeTextOverride or target.text)
end

function BeavisQoL.OpenMiscSection(sectionKey, activeTextOverride)
    local sectionPageMap = {
        AutoSell = "AutoSell",
        AutoRepair = "AutoRepair",
        FastLoot = "FastLoot",
        EasyDelete = "EasyDelete",
        CutsceneSkip = "CutsceneSkip",
        AutoRespawnPet = "AutoRespawnPet",
        FlightMasterTimer = "FlightMasterTimer",
        TooltipItemLevel = "TooltipItemLevel",
        CameraDistance = "CameraDistance",
        MacroFrame = "MacroFrame",
        ReputationSearch = "ReputationSearch",
        CurrencySearch = "CurrencySearch",
        PreyHuntProgress = "PreyHuntProgress",
        KeystoneActions = "KeystoneActions",
        PortalViewer = "PortalViewer",
    }

    BeavisQoL.OpenPage(sectionPageMap[sectionKey] or "Misc", activeTextOverride)
end

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

UpdateSidebarHeaderLayout()
UpdateSearchPlaceholder()
UpdateTreeLayout()
ShowPage(Pages.Home)
SetActiveTreeItem(TreeHomeText)
