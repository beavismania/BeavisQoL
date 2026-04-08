local _, BeavisQoL = ...

local Content = BeavisQoL.Content
local Pages = BeavisQoL.Pages
local L = BeavisQoL.L
local FrameWithBackdrop = BackdropTemplateMixin and "BackdropTemplate" or nil

local TAB_BUTTON_BACKDROP = {
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

local PageCategoryTabs = CreateFrame("Frame", nil, Content)
PageCategoryTabs:SetAllPoints()
PageCategoryTabs:Hide()

local HeaderPanel = CreateFrame("Frame", nil, PageCategoryTabs)
HeaderPanel:SetPoint("TOPLEFT", PageCategoryTabs, "TOPLEFT", 0, 0)
HeaderPanel:SetPoint("TOPRIGHT", PageCategoryTabs, "TOPRIGHT", 0, 0)
HeaderPanel:SetHeight(56)

local HeaderBg = HeaderPanel:CreateTexture(nil, "BACKGROUND")
HeaderBg:SetAllPoints()
HeaderBg:SetColorTexture(0.1, 0.068, 0.046, 0.94)

local HeaderTexture = HeaderPanel:CreateTexture(nil, "ARTWORK")
HeaderTexture:SetAllPoints()
HeaderTexture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background-Dark")
HeaderTexture:SetVertexColor(0.95, 0.78, 0.52, 0.12)

local HeaderGlow = HeaderPanel:CreateTexture(nil, "BORDER")
HeaderGlow:SetPoint("TOPLEFT", HeaderPanel, "TOPLEFT", 0, 0)
HeaderGlow:SetPoint("TOPRIGHT", HeaderPanel, "TOPRIGHT", 0, 0)
HeaderGlow:SetHeight(18)
HeaderGlow:SetColorTexture(1, 0.88, 0.62, 0.07)

local HeaderBorder = HeaderPanel:CreateTexture(nil, "ARTWORK")
HeaderBorder:SetPoint("BOTTOMLEFT", HeaderPanel, "BOTTOMLEFT", 0, 0)
HeaderBorder:SetPoint("BOTTOMRIGHT", HeaderPanel, "BOTTOMRIGHT", 0, 0)
HeaderBorder:SetHeight(1)
HeaderBorder:SetColorTexture(0.88, 0.72, 0.46, 0.28)

local CategoryCaption = HeaderPanel:CreateFontString(nil, "OVERLAY")
CategoryCaption:SetPoint("TOPLEFT", HeaderPanel, "TOPLEFT", 16, -6)
CategoryCaption:SetPoint("RIGHT", HeaderPanel, "RIGHT", -18, 0)
CategoryCaption:SetJustifyH("LEFT")
CategoryCaption:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
CategoryCaption:SetTextColor(0.9, 0.8, 0.62, 0.95)

local TabBar = CreateFrame("Frame", nil, HeaderPanel)
TabBar:SetPoint("TOPLEFT", HeaderPanel, "TOPLEFT", 14, -22)
TabBar:SetPoint("TOPRIGHT", HeaderPanel, "TOPRIGHT", -14, -22)
TabBar:SetHeight(30)

local PageContainer = CreateFrame("Frame", nil, PageCategoryTabs)
PageContainer:SetPoint("TOPLEFT", HeaderPanel, "BOTTOMLEFT", 0, -7)
PageContainer:SetPoint("BOTTOMRIGHT", PageCategoryTabs, "BOTTOMRIGHT", 0, 0)

local PageContainerShade = PageContainer:CreateTexture(nil, "BACKGROUND")
PageContainerShade:SetAllPoints()
PageContainerShade:SetTexture("Interface\\Buttons\\WHITE8X8")
PageContainerShade:SetColorTexture(0.05, 0.036, 0.026, 0.1)

local TabButtons = {}
local ActiveCategory
local ActiveEntries
local ActiveTab
local ActivePage
local LastPageByCategory = {}

local function GetTextForKey(textKey, fallbackText)
    if textKey and textKey ~= "" then
        local localizedText = L(textKey)
        if localizedText and localizedText ~= "" then
            return localizedText
        end
    end

    return fallbackText or ""
end

local function ResolveTabPage(tab)
    if not tab then
        return nil
    end

    if tab.miscSection then
        return Pages and Pages.Misc or nil
    end

    local resolvedPageKey = tab.contentPageKey or tab.pageKey
    return Pages and Pages[resolvedPageKey] or nil
end

local function GetAvailableCategoryEntries(category)
    local entries = {}

    for _, entry in ipairs(category and category.entries or {}) do
        if not entry.quickViewOnly then
            entries[#entries + 1] = entry
        end
    end

    return entries
end

local function AnchorPageToContainer(page)
    if not page then
        return
    end

    if page:GetParent() ~= PageContainer then
        page:SetParent(PageContainer)
    end

    page:ClearAllPoints()
    page:SetPoint("TOPLEFT", PageContainer, "TOPLEFT", 0, 0)
    page:SetPoint("BOTTOMRIGHT", PageContainer, "BOTTOMRIGHT", 0, 0)
end

local function ApplyTabVisual(button, isHovered)
    local isActive = button.isActive == true
    local alpha = 0
    local borderAlpha = 0
    local sheenAlpha = 0
    local textColor = { 0.92, 0.84, 0.74, 1 }

    if isActive then
        alpha = 0.78
        borderAlpha = 0.26
        sheenAlpha = 0.18
        textColor = { 1, 0.95, 0.88, 1 }
    elseif isHovered then
        alpha = 0.34
        borderAlpha = 0.12
        sheenAlpha = 0.08
        textColor = { 0.98, 0.92, 0.84, 1 }
    end

    if button.SetBackdropColor then
        button:SetBackdropColor(0.16, 0.11, 0.075, alpha)
    end

    if button.SetBackdropBorderColor then
        button:SetBackdropBorderColor(0.78, 0.64, 0.44, borderAlpha)
    end

    button.Sheen:SetAlpha(sheenAlpha)
    button.Label:SetTextColor(textColor[1], textColor[2], textColor[3], textColor[4])
end

local function CreateTabButton()
    local button = CreateFrame("Button", nil, TabBar, FrameWithBackdrop)
    button:SetHeight(28)
    button:SetHitRectInsets(-2, -2, -2, -2)

    if button.SetBackdrop then
        button:SetBackdrop(TAB_BUTTON_BACKDROP)
        button:SetBackdropColor(0.12, 0.09, 0.07, 0)
        button:SetBackdropBorderColor(0.72, 0.61, 0.46, 0)
    end

    local sheen = button:CreateTexture(nil, "ARTWORK")
    sheen:SetPoint("TOPLEFT", button, "TOPLEFT", 8, -4)
    sheen:SetPoint("TOPRIGHT", button, "TOPRIGHT", -8, -4)
    sheen:SetHeight(4)
    sheen:SetTexture("Interface\\Buttons\\WHITE8X8")
    sheen:SetColorTexture(1, 0.95, 0.82, 0.1)
    sheen:SetAlpha(0)
    button.Sheen = sheen

    local label = button:CreateFontString(nil, "OVERLAY")
    label:SetPoint("LEFT", button, "LEFT", 12, 0)
    label:SetPoint("RIGHT", button, "RIGHT", -12, 0)
    label:SetJustifyH("CENTER")
    label:SetWordWrap(false)
    label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    label:SetShadowOffset(1, -1)
    label:SetShadowColor(0, 0, 0, 0.35)
    button.Label = label

    button:SetScript("OnEnter", function(self)
        ApplyTabVisual(self, true)
    end)

    button:SetScript("OnLeave", function(self)
        ApplyTabVisual(self, false)
    end)

    ApplyTabVisual(button, false)
    return button
end

local function GetVisibleTabButtons()
    local visibleButtons = {}

    for _, button in ipairs(TabButtons) do
        if button:IsShown() then
            visibleButtons[#visibleButtons + 1] = button
        end
    end

    return visibleButtons
end

local function LayoutTabButtons()
    local visibleButtons = GetVisibleTabButtons()
    local buttonCount = #visibleButtons

    if buttonCount == 0 then
        return
    end

    local gap = 6
    local availableWidth = TabBar:GetWidth()
    if availableWidth == nil or availableWidth <= 0 then
        availableWidth = math.max(460, PageCategoryTabs:GetWidth() - 40)
    end

    local buttonWidth = math.floor((availableWidth - ((buttonCount - 1) * gap)) / buttonCount)
    buttonWidth = math.max(96, math.min(260, buttonWidth))

    for index, button in ipairs(visibleButtons) do
        button:ClearAllPoints()
        button:SetWidth(buttonWidth)

        if index == 1 then
            button:SetPoint("LEFT", TabBar, "LEFT", 0, 0)
        else
            button:SetPoint("LEFT", visibleButtons[index - 1], "RIGHT", gap, 0)
        end
    end
end

local function RefreshTabButtonTexts()
    for _, button in ipairs(TabButtons) do
        if button.tabData then
            button.Label:SetText(GetTextForKey(button.tabData.tabLabelTextKey or button.tabData.labelTextKey, button.tabData.pageKey))
        end
    end
end

function PageCategoryTabs:RefreshTabLayout()
    LayoutTabButtons()
    RefreshTabButtonTexts()
end

function PageCategoryTabs:SelectTab(pageKey)
    if not ActiveEntries or #ActiveEntries == 0 then
        return
    end

    local targetTab

    for _, entry in ipairs(ActiveEntries) do
        if entry.pageKey == pageKey then
            targetTab = entry
            break
        end
    end

    if not targetTab then
        targetTab = ActiveEntries[1]
    end

    if not targetTab then
        return
    end

    for _, entry in ipairs(ActiveEntries) do
        local page = ResolveTabPage(entry)
        if page then
            page:Hide()
        end
    end

    local targetPage = ResolveTabPage(targetTab)
    if not targetPage then
        return
    end

    local miscPage = Pages and Pages.Misc
    if miscPage and miscPage.SetStandaloneSection then
        if targetPage == miscPage then
            miscPage:SetStandaloneSection(targetTab.miscSection)
        else
            miscPage:SetStandaloneSection(nil)
        end
    end

    AnchorPageToContainer(targetPage)
    BeavisQoL.ActiveCategoryTabsPageKey = targetTab.pageKey
    targetPage:Show()

    if targetPage.RefreshState then
        targetPage:RefreshState()
    end

    ActiveTab = targetTab
    ActivePage = targetPage
    LastPageByCategory[ActiveCategory.key] = targetTab.pageKey

    for _, button in ipairs(TabButtons) do
        button.isActive = button.tabData == targetTab
        ApplyTabVisual(button, false)
    end
end

function PageCategoryTabs:OpenCategory(category, pageKey)
    local availableEntries = GetAvailableCategoryEntries(category)
    if not category or #availableEntries == 0 then
        return
    end

    if ActiveEntries and #ActiveEntries > 0 then
        for _, entry in ipairs(ActiveEntries) do
            local page = ResolveTabPage(entry)
            if page then
                page:Hide()
            end
        end
    end

    ActiveCategory = category
    ActiveEntries = availableEntries
    CategoryCaption:SetText(GetTextForKey(category.labelTextKey, category.key))

    for index, tabData in ipairs(availableEntries) do
        local button = TabButtons[index]
        local currentTab = tabData
        if not button then
            button = CreateTabButton()
            TabButtons[index] = button
        end

        button.tabData = currentTab
        button.Label:SetText(GetTextForKey(currentTab.tabLabelTextKey or currentTab.labelTextKey, currentTab.pageKey))
        button:SetScript("OnClick", function()
            PageCategoryTabs:SelectTab(currentTab.pageKey)
        end)
        button:Show()
    end

    for index = #availableEntries + 1, #TabButtons do
        local button = TabButtons[index]
        button.tabData = nil
        button.isActive = false
        button:Hide()
    end

    self:RefreshTabLayout()
    self:SelectTab(pageKey or LastPageByCategory[category.key] or category.defaultPageKey)
end

PageCategoryTabs:SetScript("OnShow", function(self)
    self:RefreshTabLayout()
end)

TabBar:SetScript("OnSizeChanged", function()
    PageCategoryTabs:RefreshTabLayout()
end)

BeavisQoL.Pages.CategoryTabs = PageCategoryTabs

