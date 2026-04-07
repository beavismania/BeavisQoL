local _, BeavisQoL = ...

BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc
local L = BeavisQoL.L
local HookSecureFunction = rawget(_G, "hooksecurefunc")
local HidePanel = rawget(_G, "HideUIPanel")
local TimerAfter = C_Timer and C_Timer.After
local baseGetMiscDB = Misc.GetMiscDB
local CurrencySearchWatcher = CreateFrame("Frame")

local TOKEN_UI_ADDON_NAME = "Blizzard_TokenUI"

local currencySearchQuery = ""
local defaultCurrencyScrollBoxPoints = nil
local defaultCurrencyTransferLogButtonPoints = nil

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

local function BuildCurrencySearchText(entry)
    if not entry then
        return ""
    end

    local parts = {}
    if entry.name and entry.name ~= "" then
        parts[#parts + 1] = entry.name
    end

    if entry.isAccountTransferable and type(ACCOUNT_TRANSFERRABLE_CURRENCY) == "string" then
        parts[#parts + 1] = ACCOUNT_TRANSFERRABLE_CURRENCY
    elseif entry.isAccountWide and type(ACCOUNT_LEVEL_CURRENCY) == "string" then
        parts[#parts + 1] = ACCOUNT_LEVEL_CURRENCY
    end

    return table.concat(parts, " ")
end

local function IsTokenUILoaded()
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(TOKEN_UI_ADDON_NAME) == true
    end

    return rawget(_G, "TokenFrame") ~= nil
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

local function RememberCurrencyDefaultLayout(frame)
    if not frame then
        return
    end

    if (not defaultCurrencyScrollBoxPoints or #defaultCurrencyScrollBoxPoints == 0) and frame.ScrollBox then
        defaultCurrencyScrollBoxPoints = CaptureAnchorPoints(frame.ScrollBox)
    end

    if (not defaultCurrencyTransferLogButtonPoints or #defaultCurrencyTransferLogButtonPoints == 0) and frame.CurrencyTransferLogToggleButton then
        defaultCurrencyTransferLogButtonPoints = CaptureAnchorPoints(frame.CurrencyTransferLogToggleButton)
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

    if db.currencySearchEnabled == nil then
        db.currencySearchEnabled = true
    end

    return db
end

function Misc.IsCurrencySearchEnabled()
    return Misc.GetMiscDB().currencySearchEnabled == true
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

local function IsInsetLayoutActive(inset)
    return inset and inset.IsShown and inset:IsShown()
end

local function ApplyFrameOrderFromReference(referenceFrame, targetFrame)
    if not referenceFrame or not targetFrame then
        return
    end

    if referenceFrame.GetFrameStrata and targetFrame.SetFrameStrata then
        targetFrame:SetFrameStrata(referenceFrame:GetFrameStrata())
    end

    if referenceFrame.GetFrameLevel and targetFrame.SetFrameLevel then
        targetFrame:SetFrameLevel((referenceFrame:GetFrameLevel() or 0) + 5)
    end
end

local function BuildCurrencyHierarchy(currencyList)
    local hierarchy = {}
    local headerStack = {}

    for index, entry in ipairs(currencyList) do
        local depth = math.max(tonumber(entry and entry.currencyListDepth) or 0, 0)

        while #headerStack > 0 and headerStack[#headerStack].depth >= depth do
            headerStack[#headerStack] = nil
        end

        local ancestors = {}
        for ancestorIndex = 1, #headerStack do
            ancestors[ancestorIndex] = headerStack[ancestorIndex].index
        end

        hierarchy[index] = {
            depth = depth,
            ancestors = ancestors,
        }

        if entry and entry.isHeader then
            headerStack[#headerStack + 1] = {
                index = index,
                depth = depth,
            }
        end
    end

    return hierarchy
end

local function FilterCurrencyList(currencyList, query, selectedCurrencyIndex)
    if query == "" then
        return currencyList, true
    end

    local hierarchy = BuildCurrencyHierarchy(currencyList)
    local includedEntries = {}
    local filteredList = {}
    local selectedVisible = false

    local function IncludeEntry(index)
        if includedEntries[index] then
            return
        end

        local entry = currencyList[index]
        if not entry then
            return
        end

        includedEntries[index] = true
        if selectedCurrencyIndex and entry.currencyIndex == selectedCurrencyIndex then
            selectedVisible = true
        end
    end

    local function IncludeAncestors(index)
        local entryInfo = hierarchy[index]
        if not entryInfo then
            return
        end

        for _, ancestorIndex in ipairs(entryInfo.ancestors) do
            IncludeEntry(ancestorIndex)
        end
    end

    local function IncludeDescendants(index)
        local entryInfo = hierarchy[index]
        if not entryInfo then
            return
        end

        local parentDepth = entryInfo.depth
        for descendantIndex = index + 1, #currencyList do
            local descendantInfo = hierarchy[descendantIndex]
            if not descendantInfo or descendantInfo.depth <= parentDepth then
                break
            end

            IncludeEntry(descendantIndex)
        end
    end

    for index, entry in ipairs(currencyList) do
        if SearchTextContains(BuildCurrencySearchText(entry), query) then
            IncludeAncestors(index)
            IncludeEntry(index)

            if entry.isHeader then
                IncludeDescendants(index)
            end
        end
    end

    for index, entry in ipairs(currencyList) do
        if includedEntries[index] then
            filteredList[#filteredList + 1] = entry
        end
    end

    return filteredList, selectedVisible
end

local function ClearCurrencySelection(frame)
    if not frame then
        return
    end

    frame.selectedToken = nil
    frame.selectedID = nil

    if frame.Popup then
        frame.Popup:Hide()
    end

    local currencyTransferMenu = rawget(_G, "CurrencyTransferMenu")
    if currencyTransferMenu and HidePanel then
        HidePanel(currencyTransferMenu)
    end
end

local function ApplyCurrencySearchFilter(frame)
    if not Misc.IsCurrencySearchEnabled or not Misc.IsCurrencySearchEnabled() then
        return
    end

    if not frame
        or not frame.ScrollBox
        or not C_CurrencyInfo
        or not C_CurrencyInfo.GetCurrencyListSize
        or not C_CurrencyInfo.GetCurrencyListInfo then
        return
    end

    local requiresAccountData = C_CurrencyInfo.DoesCurrentFilterRequireAccountCurrencyData
        and C_CurrencyInfo.DoesCurrentFilterRequireAccountCurrencyData()
    local isAccountDataReady = not requiresAccountData
        or (C_CurrencyInfo.IsAccountCharacterCurrencyDataReady and C_CurrencyInfo.IsAccountCharacterCurrencyDataReady())
    if not isAccountDataReady then
        return
    end

    local currencyList = {}
    for currencyIndex = 1, C_CurrencyInfo.GetCurrencyListSize() do
        local currencyData = C_CurrencyInfo.GetCurrencyListInfo(currencyIndex)
        if currencyData then
            currencyData.currencyIndex = currencyIndex
            currencyList[#currencyList + 1] = currencyData
        end
    end

    local selectedCurrencyIndex = frame.selectedID
    local filteredList, selectedVisible = FilterCurrencyList(currencyList, currencySearchQuery, selectedCurrencyIndex)

    if currencySearchQuery ~= "" and selectedCurrencyIndex and not selectedVisible then
        ClearCurrencySelection(frame)
    end

    frame.ScrollBox:SetDataProvider(CreateDataProvider(filteredList), ScrollBoxConstants.RetainScrollPosition)
end

local function RestoreDefaultCurrencyLayout(frame)
    if not frame then
        return
    end

    RememberCurrencyDefaultLayout(frame)
    RestoreAnchorPoints(frame.ScrollBox, defaultCurrencyScrollBoxPoints)
    RestoreAnchorPoints(frame.CurrencyTransferLogToggleButton, defaultCurrencyTransferLogButtonPoints)
end

local function LayoutCurrencySearchUI(frame, searchBox)
    if not frame or not searchBox then
        return
    end

    local inset = frame:GetParent() and frame:GetParent().Inset or nil
    local filterDropdown = frame.filterDropdown
    local transferLogButton = frame.CurrencyTransferLogToggleButton
    local useInsetLayout = IsInsetLayoutActive(inset)
    local frameReference = filterDropdown or frame

    searchBox:ClearAllPoints()
    ApplyFrameOrderFromReference(frameReference, searchBox)

    if transferLogButton and filterDropdown then
        transferLogButton:ClearAllPoints()
        transferLogButton:SetPoint("RIGHT", filterDropdown, "LEFT", -8, 0)
        ApplyFrameOrderFromReference(frameReference, transferLogButton)
    elseif transferLogButton then
        ApplyFrameOrderFromReference(frameReference, transferLogButton)
    end

    if useInsetLayout and filterDropdown and transferLogButton then
        searchBox:SetPoint("LEFT", inset, "TOPLEFT", 8, -19)
        searchBox:SetPoint("RIGHT", transferLogButton, "LEFT", -8, 0)

        frame.ScrollBox:ClearAllPoints()
        frame.ScrollBox:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", -4, -8)
        frame.ScrollBox:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -22, 2)
    elseif useInsetLayout and filterDropdown then
        searchBox:SetPoint("LEFT", inset, "TOPLEFT", 8, -19)
        searchBox:SetPoint("RIGHT", filterDropdown, "LEFT", -12, 0)

        frame.ScrollBox:ClearAllPoints()
        frame.ScrollBox:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", -4, -8)
        frame.ScrollBox:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -22, 2)
    elseif filterDropdown and transferLogButton then
        searchBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -62)
        searchBox:SetPoint("RIGHT", transferLogButton, "LEFT", -8, 0)

        frame.ScrollBox:ClearAllPoints()
        frame.ScrollBox:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", -20, -10)
        frame.ScrollBox:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 26)
    elseif filterDropdown then
        searchBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -62)
        searchBox:SetPoint("RIGHT", filterDropdown, "LEFT", -12, 0)

        frame.ScrollBox:ClearAllPoints()
        frame.ScrollBox:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", -20, -10)
        frame.ScrollBox:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 26)
    else
        searchBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -56)
        searchBox:SetSize(170, 22)
    end
end

local function RefreshCurrencySearchLayout(frame, searchBox)
    LayoutCurrencySearchUI(frame, searchBox)

    if TimerAfter then
        TimerAfter(0, function()
            local liveFrame = rawget(_G, "TokenFrame")
            if liveFrame and liveFrame == frame and searchBox and searchBox:IsShown() then
                LayoutCurrencySearchUI(liveFrame, searchBox)
            end
        end)
    end
end

local function EnsureCurrencySearchUI()
    local frame = rawget(_G, "TokenFrame")
    if not frame or frame.BeavisCurrencySearchInitialized then
        return
    end

    frame.BeavisCurrencySearchInitialized = true
    RememberCurrencyDefaultLayout(frame)

    local searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    searchBox:SetHeight(22)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(80)
    searchBox:SetFontObject(ChatFontNormal)

    RefreshCurrencySearchLayout(frame, searchBox)

    local placeholder = searchBox:CreateFontString(nil, "ARTWORK")
    placeholder:SetPoint("LEFT", searchBox, "LEFT", 6, 0)
    placeholder:SetPoint("RIGHT", searchBox, "RIGHT", -8, 0)
    placeholder:SetJustifyH("LEFT")
    placeholder:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    placeholder:SetTextColor(0.58, 0.58, 0.60, 1)
    placeholder:SetText(L("CURRENCY_SEARCH_PLACEHOLDER"))

    searchBox.Placeholder = placeholder
    frame.BeavisCurrencySearchBox = searchBox

    frame:HookScript("OnShow", function()
        if Misc.IsCurrencySearchEnabled and Misc.IsCurrencySearchEnabled() then
            searchBox:Show()
            RefreshCurrencySearchLayout(frame, searchBox)
            UpdatePlaceholder(searchBox)
        else
            searchBox:Hide()
            RestoreDefaultCurrencyLayout(frame)
        end
    end)

    searchBox:SetScript("OnTextChanged", function(self)
        currencySearchQuery = NormalizeSearchText(self:GetText())
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

    HookSecureFunction(frame, "Update", ApplyCurrencySearchFilter)
    UpdatePlaceholder(searchBox)
end

local function RefreshCurrencySearchState(forceUpdate)
    local frame = rawget(_G, "TokenFrame")
    if not frame then
        return
    end

    local searchBox = frame.BeavisCurrencySearchBox
    local enabled = Misc.IsCurrencySearchEnabled and Misc.IsCurrencySearchEnabled() or false

    RememberCurrencyDefaultLayout(frame)

    if enabled then
        if searchBox then
            searchBox:Show()
            RefreshCurrencySearchLayout(frame, searchBox)
            UpdatePlaceholder(searchBox)
        end
    else
        currencySearchQuery = ""

        if searchBox then
            searchBox:SetText("")
            searchBox:ClearFocus()
            UpdatePlaceholder(searchBox)
            searchBox:Hide()
        end

        RestoreDefaultCurrencyLayout(frame)
    end

    if forceUpdate and frame.Update then
        frame:Update()
    end
end

local function InitializeCurrencySearch()
    EnsureCurrencySearchUI()
    RefreshCurrencySearchState(true)
end

function Misc.SetCurrencySearchEnabled(value)
    Misc.GetMiscDB().currencySearchEnabled = value == true

    if IsTokenUILoaded() then
        InitializeCurrencySearch()
    end

    RefreshMiscPageState()
end

CurrencySearchWatcher:RegisterEvent("ADDON_LOADED")
CurrencySearchWatcher:RegisterEvent("PLAYER_LOGIN")
CurrencySearchWatcher:SetScript("OnEvent", function(_, event, ...)
    local eventArg1 = ...

    if event == "ADDON_LOADED" then
        if eventArg1 == TOKEN_UI_ADDON_NAME then
            InitializeCurrencySearch()
        end

        return
    end

    if event == "PLAYER_LOGIN" and IsTokenUILoaded() then
        InitializeCurrencySearch()
    end
end)
