local _, BeavisQoL = ...

BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc
local L = BeavisQoL.L
local baseGetMiscDB = Misc.GetMiscDB
local ReputationSearchWatcher = CreateFrame("Frame")

local REPUTATION_UI_ADDON_NAME = "Blizzard_UIPanels_Game"
local MAX_RESULT_BUTTONS = 8
local RESULT_BUTTON_HEIGHT = 20

local reputationSearchQuery = ""
local reputationSearchBox = nil
local reputationSearchFrame = nil
local reputationSearchResultsFrame = nil
local reputationSearchResultButtons = {}
local reputationSearchResults = {}
local reputationSearchFrameHooksInstalled = false

local RefreshReputationSearchResults

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

    local hasFocus = editBox.HasFocus and editBox:HasFocus()
    local hasText = editBox.GetText and editBox:GetText() ~= ""

    if hasFocus or hasText then
        editBox.Placeholder:Hide()
    else
        editBox.Placeholder:Show()
    end
end

local function HideReputationSearchResults()
    reputationSearchResults = {}

    if reputationSearchResultsFrame then
        reputationSearchResultsFrame:Hide()
    end

    for _, button in ipairs(reputationSearchResultButtons) do
        button.Entry = nil
        button:Hide()
    end
end

local function GetVisibleReputationEntries()
    local entries = {}

    if not C_Reputation or not C_Reputation.GetNumFactions or not C_Reputation.GetFactionDataByIndex then
        return entries
    end

    for index = 1, C_Reputation.GetNumFactions() do
        local factionData = C_Reputation.GetFactionDataByIndex(index)
        if factionData and factionData.name and factionData.name ~= "" then
            entries[#entries + 1] = {
                factionIndex = index,
                factionID = factionData.factionID,
                name = factionData.name,
                isHeader = factionData.isHeader == true,
                isChild = factionData.isChild == true,
                isCollapsed = factionData.isCollapsed == true,
            }
        end
    end

    return entries
end

local function BuildReputationSearchResults(query)
    local results = {}

    if query == "" then
        return results
    end

    for _, entry in ipairs(GetVisibleReputationEntries()) do
        if SearchTextContains(entry.name, query) then
            results[#results + 1] = entry

            if #results >= MAX_RESULT_BUTTONS then
                break
            end
        end
    end

    return results
end

local function FormatReputationResultLabel(entry)
    local indent = entry.isChild and "    " or ""
    local prefix = entry.isHeader and "> " or ""
    return indent .. prefix .. (entry.name or "")
end

local function ApplyResultButtonVisual(button, hovered)
    if not button or not button.Background or not button.Label then
        return
    end

    local entry = button.Entry
    local isHeader = entry and entry.isHeader == true

    if hovered then
        button.Background:SetColorTexture(1, 0.82, 0, 0.18)
    else
        button.Background:SetColorTexture(1, 1, 1, isHeader and 0.06 or 0.03)
    end

    if isHeader then
        button.Label:SetTextColor(1, 0.82, 0, 1)
    else
        button.Label:SetTextColor(0.94, 0.92, 0.88, 1)
    end
end

local function FindFirstSelectableEntryAfterHeader(headerEntry)
    local foundHeader = false

    for _, entry in ipairs(GetVisibleReputationEntries()) do
        if not foundHeader then
            if entry.factionIndex == headerEntry.factionIndex then
                foundHeader = true
            end
        else
            if headerEntry.isChild then
                if not entry.isChild or (entry.isHeader and entry.isChild) then
                    break
                end
            elseif entry.isHeader and not entry.isChild then
                break
            end

            if not entry.isHeader then
                return entry
            end
        end
    end

    return nil
end

local function ApplyReputationSearchResult(entry)
    if not entry then
        return
    end

    if entry.isHeader then
        if entry.isCollapsed and C_Reputation and C_Reputation.ExpandFactionHeader then
            pcall(C_Reputation.ExpandFactionHeader, entry.factionIndex)
            return
        end

        entry = FindFirstSelectableEntryAfterHeader(entry)
        if not entry then
            return
        end
    end

    if C_Reputation and C_Reputation.SetSelectedFaction then
        pcall(C_Reputation.SetSelectedFaction, entry.factionIndex)
    end
end

local function EnsureResultsFrame()
    if reputationSearchResultsFrame or not reputationSearchFrame or not reputationSearchBox then
        return reputationSearchResultsFrame
    end

    local resultsFrame = CreateFrame("Frame", nil, reputationSearchFrame)
    resultsFrame:SetPoint("TOPLEFT", reputationSearchBox, "BOTTOMLEFT", 0, -4)
    resultsFrame:SetPoint("TOPRIGHT", reputationSearchBox, "BOTTOMRIGHT", 0, -4)
    resultsFrame:SetHeight(10)
    resultsFrame:Hide()

    local background = resultsFrame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.04, 0.04, 0.05, 0.96)
    resultsFrame.Background = background

    local topBorder = resultsFrame:CreateTexture(nil, "BORDER")
    topBorder:SetPoint("TOPLEFT")
    topBorder:SetPoint("TOPRIGHT")
    topBorder:SetHeight(1)
    topBorder:SetColorTexture(1, 0.82, 0, 0.35)

    local bottomBorder = resultsFrame:CreateTexture(nil, "BORDER")
    bottomBorder:SetPoint("BOTTOMLEFT")
    bottomBorder:SetPoint("BOTTOMRIGHT")
    bottomBorder:SetHeight(1)
    bottomBorder:SetColorTexture(1, 0.82, 0, 0.35)

    local leftBorder = resultsFrame:CreateTexture(nil, "BORDER")
    leftBorder:SetPoint("TOPLEFT")
    leftBorder:SetPoint("BOTTOMLEFT")
    leftBorder:SetWidth(1)
    leftBorder:SetColorTexture(1, 0.82, 0, 0.35)

    local rightBorder = resultsFrame:CreateTexture(nil, "BORDER")
    rightBorder:SetPoint("TOPRIGHT")
    rightBorder:SetPoint("BOTTOMRIGHT")
    rightBorder:SetWidth(1)
    rightBorder:SetColorTexture(1, 0.82, 0, 0.35)

    reputationSearchResultsFrame = resultsFrame
    return resultsFrame
end

local function EnsureResultButton(index)
    if reputationSearchResultButtons[index] then
        return reputationSearchResultButtons[index]
    end

    local parent = EnsureResultsFrame()
    if not parent then
        return nil
    end

    local button = CreateFrame("Button", nil, parent)
    button:SetHeight(RESULT_BUTTON_HEIGHT)
    button:SetPoint("LEFT", parent, "LEFT", 6, 0)
    button:SetPoint("RIGHT", parent, "RIGHT", -6, 0)

    if index == 1 then
        button:SetPoint("TOP", parent, "TOP", 0, -5)
    else
        button:SetPoint("TOP", reputationSearchResultButtons[index - 1], "BOTTOM", 0, 0)
    end

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    button.Background = background

    local label = button:CreateFontString(nil, "OVERLAY")
    label:SetPoint("LEFT", button, "LEFT", 6, 0)
    label:SetPoint("RIGHT", button, "RIGHT", -6, 0)
    label:SetJustifyH("LEFT")
    label:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    button.Label = label

    button:SetScript("OnEnter", function(self)
        ApplyResultButtonVisual(self, true)
    end)

    button:SetScript("OnLeave", function(self)
        ApplyResultButtonVisual(self, false)
    end)

    button:SetScript("OnClick", function(self)
        if not self.Entry then
            return
        end

        ApplyReputationSearchResult(self.Entry)
        if not self.Entry.isHeader then
            HideReputationSearchResults()
        end
        RefreshReputationSearchResults()
    end)

    reputationSearchResultButtons[index] = button
    ApplyResultButtonVisual(button, false)
    return button
end

local function ApplySearchBoxFrameOrder(frame)
    if not frame or not reputationSearchBox then
        return
    end

    local referenceFrame = frame.filterDropdown or frame

    if referenceFrame.GetFrameStrata and reputationSearchBox.SetFrameStrata then
        reputationSearchBox:SetFrameStrata(referenceFrame:GetFrameStrata())
    end

    if referenceFrame.GetFrameLevel and reputationSearchBox.SetFrameLevel then
        reputationSearchBox:SetFrameLevel((referenceFrame:GetFrameLevel() or 0) + 5)
    end

    if reputationSearchResultsFrame and referenceFrame.GetFrameStrata and reputationSearchResultsFrame.SetFrameStrata then
        reputationSearchResultsFrame:SetFrameStrata(referenceFrame:GetFrameStrata())
    end

    if reputationSearchResultsFrame and referenceFrame.GetFrameLevel and reputationSearchResultsFrame.SetFrameLevel then
        reputationSearchResultsFrame:SetFrameLevel((referenceFrame:GetFrameLevel() or 0) + 6)
    end
end

local function LayoutReputationSearchUI(frame)
    if not frame or not reputationSearchBox then
        return
    end

    local filterDropdown = frame.filterDropdown

    reputationSearchBox:ClearAllPoints()
    ApplySearchBoxFrameOrder(frame)

    if filterDropdown then
        reputationSearchBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -30)
        reputationSearchBox:SetPoint("RIGHT", filterDropdown, "LEFT", -10, 0)
    else
        reputationSearchBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -30)
        reputationSearchBox:SetSize(180, 20)
    end

    if reputationSearchResultsFrame then
        reputationSearchResultsFrame:ClearAllPoints()
        reputationSearchResultsFrame:SetPoint("TOPLEFT", reputationSearchBox, "BOTTOMLEFT", 0, -4)
        reputationSearchResultsFrame:SetPoint("TOPRIGHT", reputationSearchBox, "BOTTOMRIGHT", 0, -4)
    end
end

RefreshReputationSearchResults = function()
    if not reputationSearchFrame or not reputationSearchBox or not reputationSearchResultsFrame then
        return
    end

    if not Misc.IsReputationSearchEnabled or not Misc.IsReputationSearchEnabled() then
        HideReputationSearchResults()
        return
    end

    if not reputationSearchFrame.IsShown or not reputationSearchFrame:IsShown() then
        HideReputationSearchResults()
        return
    end

    local query = NormalizeSearchText(reputationSearchQuery)
    if query == "" then
        HideReputationSearchResults()
        return
    end

    local results = BuildReputationSearchResults(query)
    reputationSearchResults = results

    if #results == 0 then
        HideReputationSearchResults()
        return
    end

    reputationSearchResultsFrame:SetHeight((#results * RESULT_BUTTON_HEIGHT) + 10)
    reputationSearchResultsFrame:Show()

    for index = 1, MAX_RESULT_BUTTONS do
        local button = EnsureResultButton(index)
        if button then
            local entry = results[index]
            if entry then
                button.Entry = entry
                button.Label:SetText(FormatReputationResultLabel(entry))
                ApplyResultButtonVisual(button, false)
                button:Show()
            else
                button.Entry = nil
                button:Hide()
            end
        end
    end
end

local function EnsureReputationSearchUI()
    if reputationSearchBox then
        return
    end

    local frame = rawget(_G, "ReputationFrame")
    if not frame then
        return
    end

    reputationSearchFrame = frame

    local searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    searchBox:SetHeight(20)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(80)
    searchBox:SetFontObject(ChatFontNormal)

    local placeholder = searchBox:CreateFontString(nil, "ARTWORK")
    placeholder:SetPoint("LEFT", searchBox, "LEFT", 6, 0)
    placeholder:SetPoint("RIGHT", searchBox, "RIGHT", -8, 0)
    placeholder:SetJustifyH("LEFT")
    placeholder:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    placeholder:SetTextColor(0.58, 0.58, 0.60, 1)
    placeholder:SetText(L("REPUTATION_SEARCH_PLACEHOLDER"))

    searchBox.Placeholder = placeholder
    reputationSearchBox = searchBox

    EnsureResultsFrame()
    LayoutReputationSearchUI(frame)
    UpdatePlaceholder(searchBox)

    searchBox:SetScript("OnTextChanged", function(self)
        reputationSearchQuery = self:GetText() or ""
        UpdatePlaceholder(self)
        RefreshReputationSearchResults()
    end)

    searchBox:SetScript("OnEditFocusGained", function(self)
        UpdatePlaceholder(self)
        RefreshReputationSearchResults()
    end)

    searchBox:SetScript("OnEditFocusLost", function(self)
        UpdatePlaceholder(self)
    end)

    searchBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)

    searchBox:SetScript("OnEnterPressed", function(self)
        local firstResult = reputationSearchResults[1]
        if firstResult then
            ApplyReputationSearchResult(firstResult)
            if not firstResult.isHeader then
                HideReputationSearchResults()
            end
            RefreshReputationSearchResults()
        end

        self:ClearFocus()
    end)

    if not reputationSearchFrameHooksInstalled then
        frame:HookScript("OnShow", function()
            LayoutReputationSearchUI(frame)

            if Misc.IsReputationSearchEnabled and Misc.IsReputationSearchEnabled() then
                reputationSearchBox:Show()
                UpdatePlaceholder(reputationSearchBox)
                RefreshReputationSearchResults()
            else
                HideReputationSearchResults()
                reputationSearchBox:Hide()
            end
        end)

        frame:HookScript("OnHide", function()
            if reputationSearchBox then
                reputationSearchBox:SetText("")
                reputationSearchBox:ClearFocus()
            end

            reputationSearchQuery = ""
            HideReputationSearchResults()
        end)

        reputationSearchFrameHooksInstalled = true
    end
end

local function RefreshReputationSearchState()
    EnsureReputationSearchUI()

    if not reputationSearchFrame or not reputationSearchBox then
        return
    end

    LayoutReputationSearchUI(reputationSearchFrame)

    if Misc.IsReputationSearchEnabled and Misc.IsReputationSearchEnabled() then
        reputationSearchBox:Show()
        UpdatePlaceholder(reputationSearchBox)
        RefreshReputationSearchResults()
    else
        reputationSearchQuery = ""
        reputationSearchBox:SetText("")
        reputationSearchBox:ClearFocus()
        UpdatePlaceholder(reputationSearchBox)
        HideReputationSearchResults()
        reputationSearchBox:Hide()
    end
end

local function InitializeReputationSearch()
    RefreshReputationSearchState()
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
ReputationSearchWatcher:RegisterEvent("UPDATE_FACTION")
ReputationSearchWatcher:SetScript("OnEvent", function(_, event, ...)
    local eventArg1 = ...

    if event == "ADDON_LOADED" then
        if eventArg1 == REPUTATION_UI_ADDON_NAME then
            InitializeReputationSearch()
        end

        return
    end

    if event == "PLAYER_LOGIN" then
        if IsReputationUILoaded() then
            InitializeReputationSearch()
        end

        return
    end

    if event == "UPDATE_FACTION" then
        RefreshReputationSearchResults()
    end
end)
