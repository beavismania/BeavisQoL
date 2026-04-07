local _, BeavisQoL = ...

BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc
local L = BeavisQoL.L
local HookSecureFunction = rawget(_G, "hooksecurefunc")
local baseGetMiscDB = Misc.GetMiscDB
local ReputationSearchWatcher = CreateFrame("Frame")

local REPUTATION_UI_ADDON_NAME = "Blizzard_UIPanels_Game"

local reputationSearchQuery = ""
local defaultReputationScrollBoxPoints = nil

local function NormalizeSearchText(text)
    local normalizedText = tostring(text or "")
    normalizedText = string.lower(normalizedText)
    normalizedText = string.gsub(normalizedText, "[%c%p]", " ")
    normalizedText = string.gsub(normalizedText, "%s+", " ")
    normalizedText = string.match(normalizedText, "^%s*(.-)%s*$") or ""

    return normalizedText
end

local function SearchTextContains(text, query)
    if not query or query == "" then
        return true
    end

    if not text or text == "" then
        return false
    end

    return string.find(NormalizeSearchText(text), query, 1, true) ~= nil
end

local function IsReputationUILoaded()
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(REPUTATION_UI_ADDON_NAME) == true
    end

    return rawget(_G, "ReputationFrame") ~= nil
end

local function RefreshMiscPageState()
    local miscPage = BeavisQoL.Pages and BeavisQoL.Pages.Misc
    if miscPage and miscPage:IsShown() and miscPage.RefreshState then
        miscPage:RefreshState()
    end
end

local function CaptureAnchorPoints(frame)
    local points = {}
    if not frame or not frame.GetNumPoints or not frame.GetPoint then
        return points
    end

    for pointIndex = 1, (frame:GetNumPoints() or 0) do
        local point, relativeTo, relativePoint, xOffset, yOffset = frame:GetPoint(pointIndex)
        if point then
            points[#points + 1] = {
                point = point,
                relativeTo = relativeTo,
                relativePoint = relativePoint,
                xOffset = xOffset or 0,
                yOffset = yOffset or 0,
            }
        end
    end

    return points
end

local function RestoreAnchorPoints(frame, points)
    if not frame or not frame.ClearAllPoints or not frame.SetPoint or not points or #points == 0 then
        return
    end

    frame:ClearAllPoints()
    for _, pointInfo in ipairs(points) do
        frame:SetPoint(
            pointInfo.point,
            pointInfo.relativeTo,
            pointInfo.relativePoint,
            pointInfo.xOffset,
            pointInfo.yOffset
        )
    end
end

local function RememberReputationDefaultLayout(frame)
    if not frame or not frame.ScrollBox then
        return
    end

    if not defaultReputationScrollBoxPoints or #defaultReputationScrollBoxPoints == 0 then
        defaultReputationScrollBoxPoints = CaptureAnchorPoints(frame.ScrollBox)
    end
end

function Misc.GetMiscDB()
    local db

    if baseGetMiscDB then
        db = baseGetMiscDB()
    else
        BeavisQoLDB = BeavisQoLDB or {}
        BeavisQoLDB.misc = BeavisQoLDB.misc or {}
        db = BeavisQoLDB.misc
    end

    if db.reputationSearchEnabled == nil then
        db.reputationSearchEnabled = true
    end

    return db
end

function Misc.IsReputationSearchEnabled()
    return Misc.GetMiscDB().reputationSearchEnabled == true
end

local function UpdatePlaceholder(editBox)
    if not editBox or not editBox.Placeholder then
        return
    end

    if editBox:HasFocus() or editBox:GetText() ~= "" then
        editBox.Placeholder:Hide()
    else
        editBox.Placeholder:Show()
    end
end

local function InsertFilteredEntry(targetList, entry, selectedFactionIndex, selectedVisible)
    targetList[#targetList + 1] = entry
    if selectedFactionIndex and entry and entry.factionIndex == selectedFactionIndex then
        selectedVisible = true
    end

    return selectedVisible
end

local function FilterFactionList(factionList, query, selectedFactionIndex)
    if query == "" then
        return factionList, true
    end

    local topGroups = {}
    local currentTopGroup = nil
    local currentChildBlock = nil

    local function EnsureTopGroup(headerEntry)
        local group = {
            header = headerEntry,
            blocks = {},
        }
        topGroups[#topGroups + 1] = group
        currentTopGroup = group
        currentChildBlock = nil
        return group
    end

    for _, entry in ipairs(factionList) do
        if entry.isHeader and not entry.isChild then
            EnsureTopGroup(entry)
        elseif entry.isHeader and entry.isChild then
            if not currentTopGroup then
                EnsureTopGroup(nil)
            end

            currentChildBlock = {
                subHeader = entry,
                items = {},
            }
            currentTopGroup.blocks[#currentTopGroup.blocks + 1] = currentChildBlock
        elseif entry.isChild then
            if not currentTopGroup then
                EnsureTopGroup(nil)
            end

            if not currentChildBlock then
                currentChildBlock = {
                    subHeader = nil,
                    items = {},
                }
                currentTopGroup.blocks[#currentTopGroup.blocks + 1] = currentChildBlock
            end

            currentChildBlock.items[#currentChildBlock.items + 1] = entry
        else
            if not currentTopGroup then
                EnsureTopGroup(nil)
            end

            currentTopGroup.blocks[#currentTopGroup.blocks + 1] = {
                entry = entry,
            }
            currentChildBlock = nil
        end
    end

    local filteredList = {}
    local selectedVisible = false

    for _, group in ipairs(topGroups) do
        local topHeaderMatches = group.header and SearchTextContains(group.header.name, query) or false
        local hasAnyMatch = topHeaderMatches

        if not hasAnyMatch then
            for _, block in ipairs(group.blocks) do
                if block.entry then
                    if SearchTextContains(block.entry.name, query) then
                        hasAnyMatch = true
                        break
                    end
                else
                    local subHeaderMatches = block.subHeader and SearchTextContains(block.subHeader.name, query) or false
                    if subHeaderMatches then
                        hasAnyMatch = true
                        break
                    end

                    for _, childEntry in ipairs(block.items) do
                        if SearchTextContains(childEntry.name, query) then
                            hasAnyMatch = true
                            break
                        end
                    end

                    if hasAnyMatch then
                        break
                    end
                end
            end
        end

        if hasAnyMatch then
            local groupHeaderInserted = false

            local function EnsureGroupHeader()
                if group.header and not groupHeaderInserted then
                    selectedVisible = InsertFilteredEntry(filteredList, group.header, selectedFactionIndex, selectedVisible)
                    groupHeaderInserted = true
                end
            end

            if topHeaderMatches then
                EnsureGroupHeader()

                for _, block in ipairs(group.blocks) do
                    if block.entry then
                        selectedVisible = InsertFilteredEntry(filteredList, block.entry, selectedFactionIndex, selectedVisible)
                    else
                        if block.subHeader then
                            selectedVisible = InsertFilteredEntry(filteredList, block.subHeader, selectedFactionIndex, selectedVisible)
                        end

                        for _, childEntry in ipairs(block.items) do
                            selectedVisible = InsertFilteredEntry(filteredList, childEntry, selectedFactionIndex, selectedVisible)
                        end
                    end
                end
            else
                for _, block in ipairs(group.blocks) do
                    if block.entry then
                        if SearchTextContains(block.entry.name, query) then
                            EnsureGroupHeader()
                            selectedVisible = InsertFilteredEntry(filteredList, block.entry, selectedFactionIndex, selectedVisible)
                        end
                    else
                        local subHeaderMatches = block.subHeader and SearchTextContains(block.subHeader.name, query) or false
                        local matchingChildren = {}

                        for _, childEntry in ipairs(block.items) do
                            if SearchTextContains(childEntry.name, query) then
                                matchingChildren[#matchingChildren + 1] = childEntry
                            end
                        end

                        if subHeaderMatches or #matchingChildren > 0 then
                            EnsureGroupHeader()

                            if block.subHeader then
                                selectedVisible = InsertFilteredEntry(filteredList, block.subHeader, selectedFactionIndex, selectedVisible)
                            end

                            if subHeaderMatches then
                                for _, childEntry in ipairs(block.items) do
                                    selectedVisible = InsertFilteredEntry(filteredList, childEntry, selectedFactionIndex, selectedVisible)
                                end
                            else
                                for _, childEntry in ipairs(matchingChildren) do
                                    selectedVisible = InsertFilteredEntry(filteredList, childEntry, selectedFactionIndex, selectedVisible)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return filteredList, selectedVisible
end

local function ApplyReputationSearchFilter(frame)
    if not Misc.IsReputationSearchEnabled or not Misc.IsReputationSearchEnabled() then
        return
    end

    if not frame or not frame.ScrollBox or not C_Reputation or not C_Reputation.GetNumFactions or not C_Reputation.GetFactionDataByIndex then
        return
    end

    local factionList = {}
    for index = 1, C_Reputation.GetNumFactions() do
        local factionData = C_Reputation.GetFactionDataByIndex(index)
        if factionData then
            factionData.factionIndex = index
            factionList[#factionList + 1] = factionData
        end
    end

    local selectedFactionIndex = C_Reputation.GetSelectedFaction and C_Reputation.GetSelectedFaction() or 0
    local filteredList, selectedVisible = FilterFactionList(factionList, reputationSearchQuery, selectedFactionIndex)

    if reputationSearchQuery ~= "" and selectedFactionIndex and selectedFactionIndex > 0 and not selectedVisible and C_Reputation.SetSelectedFaction then
        C_Reputation.SetSelectedFaction(0)
    end

    frame.ScrollBox:SetDataProvider(CreateDataProvider(filteredList), ScrollBoxConstants.RetainScrollPosition)

    if frame.ReputationDetailFrame and frame.ReputationDetailFrame.Refresh then
        frame.ReputationDetailFrame:Refresh()
    end
end

local function RestoreDefaultReputationLayout(frame)
    if not frame or not frame.ScrollBox then
        return
    end

    RememberReputationDefaultLayout(frame)
    RestoreAnchorPoints(frame.ScrollBox, defaultReputationScrollBoxPoints)
end

local function IsInsetLayoutActive(inset)
    return inset and inset.IsShown and inset:IsShown()
end

local function ApplySearchBoxFrameOrder(frame, searchBox)
    if not frame or not searchBox then
        return
    end

    local referenceFrame = frame.filterDropdown or frame

    if referenceFrame.GetFrameStrata and searchBox.SetFrameStrata then
        searchBox:SetFrameStrata(referenceFrame:GetFrameStrata())
    end

    if referenceFrame.GetFrameLevel and searchBox.SetFrameLevel then
        searchBox:SetFrameLevel((referenceFrame:GetFrameLevel() or 0) + 5)
    end
end

local function LayoutReputationSearchUI(frame, searchBox)
    if not frame or not searchBox then
        return
    end

    local inset = frame:GetParent() and frame:GetParent().Inset or nil
    local filterDropdown = frame.filterDropdown
    local useInsetLayout = IsInsetLayoutActive(inset)

    searchBox:ClearAllPoints()
    ApplySearchBoxFrameOrder(frame, searchBox)

    if useInsetLayout and filterDropdown then
        searchBox:SetPoint("LEFT", inset, "TOPLEFT", 8, -19)
        searchBox:SetPoint("RIGHT", filterDropdown, "LEFT", -12, 0)

        frame.ScrollBox:ClearAllPoints()
        frame.ScrollBox:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", -4, -8)
        frame.ScrollBox:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -22, 2)
    elseif useInsetLayout then
        searchBox:SetPoint("TOPLEFT", inset, "TOPLEFT", 8, -8)
        searchBox:SetSize(170, 22)

        frame.ScrollBox:ClearAllPoints()
        frame.ScrollBox:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", -4, -8)
        frame.ScrollBox:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -22, 2)
    elseif filterDropdown then
        searchBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -62)
        searchBox:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -72, -62)

        frame.ScrollBox:ClearAllPoints()
        frame.ScrollBox:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", -20, -10)
        frame.ScrollBox:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 7)
    else
        searchBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -56)
        searchBox:SetSize(170, 22)
    end
end

local function EnsureReputationSearchUI()
    local frame = rawget(_G, "ReputationFrame")
    if not frame or frame.BeavisReputationSearchInitialized then
        return
    end

    frame.BeavisReputationSearchInitialized = true
    RememberReputationDefaultLayout(frame)

    local searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    searchBox:SetHeight(22)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(80)
    searchBox:SetFontObject(ChatFontNormal)

    LayoutReputationSearchUI(frame, searchBox)

    local placeholder = searchBox:CreateFontString(nil, "ARTWORK")
    placeholder:SetPoint("LEFT", searchBox, "LEFT", 6, 0)
    placeholder:SetPoint("RIGHT", searchBox, "RIGHT", -8, 0)
    placeholder:SetJustifyH("LEFT")
    placeholder:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    placeholder:SetTextColor(0.58, 0.58, 0.60, 1)
    placeholder:SetText(L("REPUTATION_SEARCH_PLACEHOLDER"))

    searchBox.Placeholder = placeholder
    frame.BeavisReputationSearchBox = searchBox
    frame:HookScript("OnShow", function()
        if Misc.IsReputationSearchEnabled and Misc.IsReputationSearchEnabled() then
            searchBox:Show()
            LayoutReputationSearchUI(frame, searchBox)
            UpdatePlaceholder(searchBox)
        else
            searchBox:Hide()
            RestoreDefaultReputationLayout(frame)
        end
    end)

    searchBox:SetScript("OnTextChanged", function(self)
        reputationSearchQuery = NormalizeSearchText(self:GetText())
        UpdatePlaceholder(self)
        if frame.Update then
            frame:Update()
        end
    end)

    searchBox:SetScript("OnEditFocusGained", function(self)
        UpdatePlaceholder(self)
    end)

    searchBox:SetScript("OnEditFocusLost", function(self)
        UpdatePlaceholder(self)
    end)

    searchBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)

    searchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    HookSecureFunction(frame, "Update", ApplyReputationSearchFilter)
    UpdatePlaceholder(searchBox)
end

local function RefreshReputationSearchState(forceUpdate)
    local frame = rawget(_G, "ReputationFrame")
    if not frame then
        return
    end

    local searchBox = frame.BeavisReputationSearchBox
    local enabled = Misc.IsReputationSearchEnabled and Misc.IsReputationSearchEnabled() or false

    RememberReputationDefaultLayout(frame)

    if enabled then
        if searchBox then
            searchBox:Show()
            LayoutReputationSearchUI(frame, searchBox)
            UpdatePlaceholder(searchBox)
        end
    else
        reputationSearchQuery = ""

        if searchBox then
            searchBox:SetText("")
            searchBox:ClearFocus()
            UpdatePlaceholder(searchBox)
            searchBox:Hide()
        end

        RestoreDefaultReputationLayout(frame)
    end

    if forceUpdate and frame.Update then
        frame:Update()
    end
end

local function InitializeReputationSearch()
    EnsureReputationSearchUI()
    RefreshReputationSearchState(true)
end

function Misc.SetReputationSearchEnabled(value)
    Misc.GetMiscDB().reputationSearchEnabled = value == true

    if IsReputationUILoaded() then
        InitializeReputationSearch()
    end

    RefreshMiscPageState()
end

ReputationSearchWatcher:RegisterEvent("ADDON_LOADED")
ReputationSearchWatcher:RegisterEvent("PLAYER_LOGIN")
ReputationSearchWatcher:SetScript("OnEvent", function(_, event, ...)
    local eventArg1 = ...

    if event == "ADDON_LOADED" then
        if eventArg1 == REPUTATION_UI_ADDON_NAME then
            InitializeReputationSearch()
        end

        return
    end

    if event == "PLAYER_LOGIN" and IsReputationUILoaded() then
        InitializeReputationSearch()
    end
end)
