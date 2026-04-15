local _, BeavisQoL = ...

BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc
local L = BeavisQoL.L
local baseGetMiscDB = Misc.GetMiscDB
local HookSecureFunction = rawget(_G, "hooksecurefunc")
local CurrencySearchWatcher = CreateFrame("Frame")

local TOKEN_UI_ADDON_NAME = "Blizzard_TokenUI"
local CHONKY_ADDON_NAME = "ChonkyCharacterSheet"

local currencySearchQuery = ""
local currencySearchBox = nil
local savedHeaderExpansionStates = nil
local headersExpandedForSearch = false
local refreshHooksInstalled = false
local runtimeEventsRegistered = false
local tokenFrameHooksInstalled = false
local currencyFrameHooksInstalled = false
local applyingFilter = false
local RefreshCurrencySearchIfVisible

local function NormalizeSearchText(text)
    local normalizedText = tostring(text or "")
    normalizedText = string.lower(normalizedText)
    normalizedText = string.gsub(normalizedText, "[%c%p]", " ")
    normalizedText = string.gsub(normalizedText, "%s+", " ")
    normalizedText = string.match(normalizedText, "^%s*(.-)%s*$") or ""

    return normalizedText
end

local function TokenizeSearchText(text)
    local tokens = {}

    for token in string.gmatch(text or "", "%S+") do
        tokens[#tokens + 1] = token
    end

    return tokens
end

local function MatchesSearchQuery(labelText, query)
    local normalizedLabel = NormalizeSearchText(labelText)
    if normalizedLabel == "" or query == "" then
        return false
    end

    if string.find(normalizedLabel, query, 1, true) ~= nil then
        return true
    end

    local labelWords = TokenizeSearchText(normalizedLabel)
    local queryWords = TokenizeSearchText(query)

    if #queryWords == 0 then
        return false
    end

    for _, queryWord in ipairs(queryWords) do
        local matchedWord = false

        for _, labelWord in ipairs(labelWords) do
            if string.find(labelWord, queryWord, 1, true) ~= nil then
                matchedWord = true
                break
            end
        end

        if not matchedWord then
            return false
        end
    end

    return true
end

local function IsTokenUILoaded()
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(TOKEN_UI_ADDON_NAME) == true
    end

    return rawget(_G, "TokenFrame") ~= nil
end

local function IsChonkyLoaded()
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(CHONKY_ADDON_NAME) == true
    end

    return rawget(_G, "CCS_PSpecBtn1") ~= nil
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

    if db.currencySearchEnabled == nil then
        db.currencySearchEnabled = true
    end

    return db
end

function Misc.IsCurrencySearchEnabled()
    return Misc.GetMiscDB().currencySearchEnabled == true
end

local function GetCurrencyRootFrame()
    if TokenFrame and TokenFrame.IsObjectType and TokenFrame:IsObjectType("Frame") then
        return TokenFrame
    end

    if CurrencyFrame and CurrencyFrame.IsObjectType and CurrencyFrame:IsObjectType("Frame") then
        return CurrencyFrame
    end

    return nil
end

local function GetCurrencyButtonData(button)
    if not button then
        return nil
    end

    if button.GetElementData then
        local elementData = button:GetElementData()
        if elementData then
            return elementData
        end
    end

    return button.data
end

local function GetCurrencyButtonInfo(button)
    if not button then
        return nil
    end

    if button.currencyInfo then
        return button.currencyInfo
    end

    if button.info then
        return button.info
    end

    local data = GetCurrencyButtonData(button)
    if data then
        if data.currencyInfo then
            return data.currencyInfo
        end

        if data.info then
            return data.info
        end

        if data.name or data.isHeader ~= nil then
            return data
        end
    end

    if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListInfo then
        local index = button.index or button.currencyIndex or button.dataIndex or (button.GetID and button:GetID())
        if not index and data then
            index = data.index or data.currencyIndex or data.listIndex
        end

        if index then
            return C_CurrencyInfo.GetCurrencyListInfo(index)
        end
    end

    return nil
end

local function GetCurrencyListIndex(button, info)
    local data = GetCurrencyButtonData(button)

    if info then
        if info.index then
            return info.index
        end

        if info.currencyIndex then
            return info.currencyIndex
        end

        if info.listIndex then
            return info.listIndex
        end
    end

    if data then
        if data.index then
            return data.index
        end

        if data.currencyIndex then
            return data.currencyIndex
        end

        if data.listIndex then
            return data.listIndex
        end
    end

    return button and (button.index or button.currencyIndex or button.dataIndex or (button.GetID and button:GetID())) or nil
end
local function IsHeaderExpanded(info)
    if not info then
        return nil
    end

    if info.isHeaderExpanded ~= nil then
        return info.isHeaderExpanded
    end

    if info.isExpanded ~= nil then
        return info.isExpanded
    end

    return nil
end

local function SetHeaderExpanded(index, shouldExpand)
    if not index then
        return
    end

    if C_CurrencyInfo and C_CurrencyInfo.ExpandCurrencyList then
        pcall(C_CurrencyInfo.ExpandCurrencyList, index, shouldExpand)
        return
    end

    if ExpandCurrencyList then
        pcall(ExpandCurrencyList, index, shouldExpand and 1 or 0)
    end
end

local function GetCurrencyButtonLabel(button, info)
    if info and info.name and info.name ~= "" then
        return info.name
    end

    if button and button.Name and button.Name.GetText then
        return button.Name:GetText()
    end

    if button and button.name and button.name.GetText then
        return button.name:GetText()
    end

    if button and button.CurrencyName and button.CurrencyName.GetText then
        return button.CurrencyName:GetText()
    end

    if button and button.GetRegions then
        for _, region in ipairs({ button:GetRegions() }) do
            if region and region.GetObjectType and region:GetObjectType() == "FontString" then
                local text = region:GetText()
                if text and text ~= "" then
                    return text
                end
            end
        end
    end

    return nil
end

local function IsHeaderButton(button, info)
    if info and info.isHeader ~= nil then
        return info.isHeader
    end

    if button and button.isHeader ~= nil then
        return button.isHeader
    end

    local data = GetCurrencyButtonData(button)
    if data and data.isHeader ~= nil then
        return data.isHeader
    end

    return false
end

local function IsTransferUtilityButton(button)
    if not button then
        return false
    end

    local objectName = button.GetName and button:GetName() or nil
    if objectName and string.find(objectName, "Transfer", 1, true) then
        return true
    end

    local data = GetCurrencyButtonData(button)
    if data then
        local dataType = data.entryType or data.type or data.buttonType
        if dataType == "transfer" or dataType == "transferLog" then
            return true
        end
    end

    return false
end

local function IsFilterableCurrencyButton(button, info)
    if IsHeaderButton(button, info) then
        return false
    end

    if info and info.name ~= nil then
        return true
    end

    local label = GetCurrencyButtonLabel(button, info)
    return label ~= nil and NormalizeSearchText(label) ~= ""
end

local function CollectCurrencyButtons()
    local buttons = {}

    if TokenFrameContainer and TokenFrameContainer.buttons then
        for _, button in ipairs(TokenFrameContainer.buttons) do
            if button and button.IsObjectType and button:IsObjectType("Button") then
                buttons[#buttons + 1] = button
            end
        end
    end

    if CurrencyFrame and CurrencyFrame.Container and CurrencyFrame.Container.buttons then
        for _, button in ipairs(CurrencyFrame.Container.buttons) do
            if button and button.IsObjectType and button:IsObjectType("Button") then
                buttons[#buttons + 1] = button
            end
        end
    end

    if #buttons > 0 then
        return buttons
    end

    local root = GetCurrencyRootFrame()
    if not root then
        return buttons
    end

    local stack = { root }
    while #stack > 0 do
        local node = table.remove(stack)
        for _, child in ipairs({ node:GetChildren() }) do
            stack[#stack + 1] = child
            if child and child.IsObjectType and child:IsObjectType("Button") then
                local info = GetCurrencyButtonInfo(child)
                if info and (info.name or info.isHeader ~= nil) then
                    buttons[#buttons + 1] = child
                end
            end
        end
    end

    return buttons
end

local function HookCurrencyButtons(buttons)
    for _, button in ipairs(buttons) do
        if button and not button.BeavisCurrencySearchHooked and button.HookScript then
            button:HookScript("OnShow", function()
                if RefreshCurrencySearchIfVisible and GetCurrencyRootFrame() and GetCurrencyRootFrame():IsShown() then
                    RefreshCurrencySearchIfVisible()
                end
            end)
            button.BeavisCurrencySearchHooked = true
        end
    end
end

local function RestoreSavedHeaderStates()
    if not headersExpandedForSearch or not savedHeaderExpansionStates then
        savedHeaderExpansionStates = nil
        headersExpandedForSearch = false
        return
    end

    for index, expanded in pairs(savedHeaderExpansionStates) do
        SetHeaderExpanded(index, expanded)
    end

    savedHeaderExpansionStates = nil
    headersExpandedForSearch = false
end

local function RememberAndExpandHeaders(buttons)
    if headersExpandedForSearch then
        return
    end

    savedHeaderExpansionStates = {}

    for _, button in ipairs(buttons) do
        local info = GetCurrencyButtonInfo(button)

        if IsHeaderButton(button, info) then
            local index = GetCurrencyListIndex(button, info)
            local expanded = IsHeaderExpanded(info)

            if index and expanded ~= nil and savedHeaderExpansionStates[index] == nil then
                savedHeaderExpansionStates[index] = expanded
            end

            if index and expanded == false then
                SetHeaderExpanded(index, true)
            end
        end
    end

    headersExpandedForSearch = true
end

local function ShouldShowSearchBox()
    local root = GetCurrencyRootFrame()
    return Misc.IsCurrencySearchEnabled() and root and root:IsShown()
end

local function IsInsetLayoutActive(inset)
    return inset and inset.IsShown and inset:IsShown()
end

local function LayoutCurrencySearchBox()
    if not currencySearchBox then
        return
    end

    local root = GetCurrencyRootFrame()
    if not root then
        return
    end

    local referenceFrame = root.filterDropdown or root
    if referenceFrame and referenceFrame.GetFrameStrata and currencySearchBox.SetFrameStrata then
        currencySearchBox:SetFrameStrata(referenceFrame:GetFrameStrata())
    end

    if referenceFrame and referenceFrame.GetFrameLevel and currencySearchBox.SetFrameLevel then
        currencySearchBox:SetFrameLevel((referenceFrame:GetFrameLevel() or 0) + 5)
    end

    currencySearchBox:ClearAllPoints()

    local characterFrame = rawget(_G, "CharacterFrame")
    local characterInset = rawget(_G, "CharacterFrameInset") or (characterFrame and characterFrame.Inset)
    local filterDropdown = root.filterDropdown

    if IsChonkyLoaded() and filterDropdown then
        currencySearchBox:SetPoint("TOPLEFT", root, "TOPLEFT", 24, -30)
        currencySearchBox:SetPoint("TOPRIGHT", filterDropdown, "TOPLEFT", -12, -2)
    elseif IsInsetLayoutActive(characterInset) and filterDropdown then
        currencySearchBox:SetPoint("LEFT", characterInset, "TOPLEFT", 8, -19)
        currencySearchBox:SetPoint("RIGHT", filterDropdown, "LEFT", -12, 0)
    elseif filterDropdown then
        currencySearchBox:SetPoint("TOPLEFT", root, "TOPLEFT", 24, -62)
        currencySearchBox:SetPoint("TOPRIGHT", root, "TOPRIGHT", -72, -62)
    else
        currencySearchBox:SetPoint("TOPLEFT", root, "TOPLEFT", 16, -56)
        currencySearchBox:SetSize(180, 20)
    end
end

local function ApplyCurrencyButtonVisibility(button, shouldShow)
    if not button then
        return
    end

    if shouldShow then
        button:Show()
    else
        button:Hide()
    end
end

local function ApplyCurrencySearchFilter()
    if applyingFilter then
        return
    end

    applyingFilter = true

    local enabled = Misc.IsCurrencySearchEnabled()
    local query = NormalizeSearchText(currencySearchQuery)
    local hasQuery = query ~= ""

    local buttons = CollectCurrencyButtons()
    HookCurrencyButtons(buttons)

    if enabled and hasQuery then
        if not headersExpandedForSearch then
            RememberAndExpandHeaders(buttons)
            buttons = CollectCurrencyButtons()
            HookCurrencyButtons(buttons)
        end
    elseif headersExpandedForSearch then
        RestoreSavedHeaderStates()
        buttons = CollectCurrencyButtons()
        HookCurrencyButtons(buttons)
    end

    for _, button in ipairs(buttons) do
        local info = GetCurrencyButtonInfo(button)

        if not enabled or not hasQuery then
            ApplyCurrencyButtonVisibility(button, true)
        elseif IsTransferUtilityButton(button) then
            ApplyCurrencyButtonVisibility(button, true)
        elseif IsHeaderButton(button, info) then
            ApplyCurrencyButtonVisibility(button, false)
        else
            local label = GetCurrencyButtonLabel(button, info) or ""
            local shouldShow = IsFilterableCurrencyButton(button, info) and MatchesSearchQuery(label, query)
            ApplyCurrencyButtonVisibility(button, shouldShow)
        end
    end

    applyingFilter = false
end

local function ClearCurrencySearch(clearText)
    currencySearchQuery = ""

    if clearText and currencySearchBox and currencySearchBox:GetText() ~= "" then
        currencySearchBox:SetText("")
    end

    ApplyCurrencySearchFilter()
end

RefreshCurrencySearchIfVisible = function()
    local root = GetCurrencyRootFrame()

    if currencySearchBox then
        LayoutCurrencySearchBox()

        if ShouldShowSearchBox() then
            currencySearchBox:Show()
        else
            currencySearchBox:Hide()
        end
    end

    if root and root:IsShown() then
        ApplyCurrencySearchFilter()
    end
end

local function HookRefreshRegion(region)
    if not region or not region.HookScript then
        return
    end

    local function HookRegionScript(scriptName)
        pcall(region.HookScript, region, scriptName, function()
            RefreshCurrencySearchIfVisible()
        end)
    end

    HookRegionScript("OnVerticalScroll")
    HookRegionScript("OnValueChanged")
    HookRegionScript("OnMouseWheel")

    if region.ScrollBar then
        HookRefreshRegion(region.ScrollBar)
    end

    if region.scrollBar then
        HookRefreshRegion(region.scrollBar)
    end
end

local function InstallRefreshHooks()
    if refreshHooksInstalled then
        return
    end

    HookRefreshRegion(TokenFrameContainer)

    if TokenFrame and TokenFrame.ScrollBar then
        HookRefreshRegion(TokenFrame.ScrollBar)
    end

    if CurrencyFrame and CurrencyFrame.Container then
        HookRefreshRegion(CurrencyFrame.Container)
    end

    if HookSecureFunction and TokenFrame_Update then
        HookSecureFunction("TokenFrame_Update", function()
            RefreshCurrencySearchIfVisible()
        end)
    end

    refreshHooksInstalled = true
end

local function InstallRootHooks()
    if TokenFrame and not tokenFrameHooksInstalled then
        TokenFrame:HookScript("OnShow", function()
            RefreshCurrencySearchIfVisible()
        end)

        TokenFrame:HookScript("OnHide", function()
            ClearCurrencySearch(true)
        end)

        tokenFrameHooksInstalled = true
    end

    if CurrencyFrame and not currencyFrameHooksInstalled then
        CurrencyFrame:HookScript("OnShow", function()
            RefreshCurrencySearchIfVisible()
        end)

        CurrencyFrame:HookScript("OnHide", function()
            ClearCurrencySearch(true)
        end)

        currencyFrameHooksInstalled = true
    end
end

local function RegisterRuntimeEvents()
    if runtimeEventsRegistered then
        return
    end

    CurrencySearchWatcher:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    CurrencySearchWatcher:RegisterEvent("PLAYER_MONEY")
    CurrencySearchWatcher:RegisterEvent("CURRENCY_TRANSFER_LOG_UPDATE")
    CurrencySearchWatcher:RegisterEvent("ACCOUNT_CHARACTER_CURRENCY_DATA_RECEIVED")
    CurrencySearchWatcher:RegisterEvent("DISPLAY_SIZE_CHANGED")
    CurrencySearchWatcher:RegisterEvent("UI_SCALE_CHANGED")

    runtimeEventsRegistered = true
end

local function CreateCurrencySearchBox()
    if currencySearchBox then
        LayoutCurrencySearchBox()
        return currencySearchBox
    end

    local root = GetCurrencyRootFrame()
    if not root then
        return nil
    end

    local searchBox = CreateFrame("EditBox", "BeavisQoLCurrencySearchBox", root, "SearchBoxTemplate")
    searchBox:SetSize(180, 20)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(32)

    if searchBox.Instructions then
        searchBox.Instructions:SetText(L("CURRENCY_SEARCH_PLACEHOLDER"))
    end

    searchBox:HookScript("OnTextChanged", function(editBox)
        currencySearchQuery = editBox:GetText() or ""
        ApplyCurrencySearchFilter()
    end)

    searchBox:HookScript("OnEscapePressed", function(editBox)
        editBox:ClearFocus()
    end)

    searchBox:HookScript("OnEnterPressed", function(editBox)
        editBox:ClearFocus()
    end)

    local clearButton = searchBox.ClearButton
    if clearButton and clearButton.HookScript then
        clearButton:HookScript("OnClick", function()
            ClearCurrencySearch(false)
        end)
    end

    currencySearchBox = searchBox
    LayoutCurrencySearchBox()
    RefreshCurrencySearchIfVisible()

    return searchBox
end

local function InitializeCurrencySearch()
    if not IsTokenUILoaded() then
        return
    end

    CreateCurrencySearchBox()
    InstallRefreshHooks()
    InstallRootHooks()
    RegisterRuntimeEvents()
    RefreshCurrencySearchIfVisible()
end

function Misc.SetCurrencySearchEnabled(value)
    Misc.GetMiscDB().currencySearchEnabled = value == true

    if not Misc.GetMiscDB().currencySearchEnabled then
        RestoreSavedHeaderStates()
        ClearCurrencySearch(true)

        if currencySearchBox then
            currencySearchBox:Hide()
        end
    else
        RefreshCurrencySearchIfVisible()
    end

    RefreshMiscPageState()
end

CurrencySearchWatcher:SetScript("OnEvent", function(_, event, ...)
    local eventArg1 = ...

    if event == "ADDON_LOADED" then
        if eventArg1 == TOKEN_UI_ADDON_NAME then
            InitializeCurrencySearch()
        end

        return
    end

    if event == "PLAYER_LOGIN" then
        if IsTokenUILoaded() then
            InitializeCurrencySearch()
        end

        return
    end

    if event == "DISPLAY_SIZE_CHANGED" or event == "UI_SCALE_CHANGED" then
        LayoutCurrencySearchBox()
        return
    end

    RefreshCurrencySearchIfVisible()
end)

CurrencySearchWatcher:RegisterEvent("ADDON_LOADED")
CurrencySearchWatcher:RegisterEvent("PLAYER_LOGIN")
