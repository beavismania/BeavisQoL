local ADDON_NAME, BeavisQoL = ...

local Pages = BeavisQoL.Pages
local L = BeavisQoL.L
local metadata = BeavisQoL.Metadata or {}
local addonTitle = metadata.title or C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title") or L("UNKNOWN")
local version = metadata.version or C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "dev"
local FRAME_VISUAL_SCALE = BeavisQoL.FrameVisualScale or 1
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

local QUICK_VIEW_PAGE_TITLES = {
    LevelTime = "LEVEL_TIME",
    ItemLevelGuide = "ITEMLEVEL_GUIDE",
    QuestCheck = "QUEST_CHECK",
    QuestAbandon = "QUEST_ABANDON",
    Logging = "GOLDAUSWERTUNG",
}

local QUICK_VIEW_PAGE_ORDER = {
    { pageKey = "LevelTime", entryKey = "levelTime" },
    { pageKey = "ItemLevelGuide", entryKey = "itemLevelGuide" },
    { pageKey = "QuestCheck", entryKey = "questCheck" },
    { pageKey = "QuestAbandon", entryKey = "questAbandon" },
    { pageKey = "Logging", entryKey = "logging" },
}

local DEFAULT_QUICK_VIEW_PAGE_CONFIG = {
    widthFactor = 0.50,
    heightFactor = 0.58,
    minWidth = 980,
    minHeight = 760,
    horizontalInset = 140,
    verticalInset = 120,
}

local QUICK_VIEW_PAGE_CONFIG = {
    ItemLevelGuide = {
        widthFactor = 0.74,
        heightFactor = 0.80,
        minWidth = 1180,
        minHeight = 760,
        horizontalInset = 76,
        verticalInset = 78,
    },
}

local function Clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end

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

local function GetQuickViewTitle(pageKey)
    local titleKey = QUICK_VIEW_PAGE_TITLES[pageKey]
    if titleKey and titleKey ~= "" then
        return L(titleKey)
    end

    return pageKey or addonTitle
end

local function ResolveQuickViewPageConfig(pageKey)
    local config = QUICK_VIEW_PAGE_CONFIG[pageKey] or {}

    return {
        widthFactor = config.widthFactor or DEFAULT_QUICK_VIEW_PAGE_CONFIG.widthFactor,
        heightFactor = config.heightFactor or DEFAULT_QUICK_VIEW_PAGE_CONFIG.heightFactor,
        minWidth = config.minWidth or DEFAULT_QUICK_VIEW_PAGE_CONFIG.minWidth,
        minHeight = config.minHeight or DEFAULT_QUICK_VIEW_PAGE_CONFIG.minHeight,
        horizontalInset = config.horizontalInset or DEFAULT_QUICK_VIEW_PAGE_CONFIG.horizontalInset,
        verticalInset = config.verticalInset or DEFAULT_QUICK_VIEW_PAGE_CONFIG.verticalInset,
    }
end

local function GetSharedQuickViewFrameConfig()
    local sharedConfig = ResolveQuickViewPageConfig(nil)

    for _, tabInfo in ipairs(QUICK_VIEW_PAGE_ORDER) do
        local pageConfig = ResolveQuickViewPageConfig(tabInfo.pageKey)
        sharedConfig.widthFactor = math.max(sharedConfig.widthFactor, pageConfig.widthFactor)
        sharedConfig.heightFactor = math.max(sharedConfig.heightFactor, pageConfig.heightFactor)
        sharedConfig.minWidth = math.max(sharedConfig.minWidth, pageConfig.minWidth)
        sharedConfig.minHeight = math.max(sharedConfig.minHeight, pageConfig.minHeight)
        sharedConfig.horizontalInset = math.min(sharedConfig.horizontalInset, pageConfig.horizontalInset)
        sharedConfig.verticalInset = math.min(sharedConfig.verticalInset, pageConfig.verticalInset)
    end

    return sharedConfig
end

local QuickView = BeavisQoL.QuickView or {}
BeavisQoL.QuickView = QuickView

local TabBar
local TabButtons = {}
local LayoutQuickViewTabs
local RefreshQuickViewTabs

local QuickViewFrame = CreateFrame("Frame", "BeavisQoLQuickViewFrame", UIParent, "BasicFrameTemplateWithInset")
QuickViewFrame:SetPoint("CENTER")
QuickViewFrame:SetScale(FRAME_VISUAL_SCALE)
QuickViewFrame:SetClampedToScreen(true)
QuickViewFrame:SetMovable(true)
QuickViewFrame:SetToplevel(true)
QuickViewFrame:EnableMouse(true)
QuickViewFrame:RegisterForDrag("LeftButton")
QuickViewFrame:SetFrameStrata("HIGH")
QuickViewFrame:Hide()

QuickViewFrame:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

QuickViewFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)

if _G.BeavisQoLQuickViewFrameTitleText then
    _G.BeavisQoLQuickViewFrameTitleText:SetText("")
end

if _G.BeavisQoLQuickViewFramePortrait then
    _G.BeavisQoLQuickViewFramePortrait:Hide()
end

if _G.BeavisQoLQuickViewFrameTitleBg then
    _G.BeavisQoLQuickViewFrameTitleBg:Hide()
end

if _G.BeavisQoLQuickViewFrameBg then
    _G.BeavisQoLQuickViewFrameBg:Hide()
end

if _G.BeavisQoLQuickViewFrameInset and _G.BeavisQoLQuickViewFrameInset.Bg then
    _G.BeavisQoLQuickViewFrameInset.Bg:Hide()
end

if UISpecialFrames then
    local alreadyRegistered = false

    for _, frameName in ipairs(UISpecialFrames) do
        if frameName == "BeavisQoLQuickViewFrame" then
            alreadyRegistered = true
            break
        end
    end

    if not alreadyRegistered then
        table.insert(UISpecialFrames, "BeavisQoLQuickViewFrame")
    end
end

local function UpdateQuickViewFrameSize(pageKey)
    local pageConfig = GetSharedQuickViewFrameConfig()
    local widthFactor = pageConfig.widthFactor
    local heightFactor = pageConfig.heightFactor
    local horizontalInset = pageConfig.horizontalInset
    local verticalInset = pageConfig.verticalInset
    local maxWidth = math.max(760, UIParent:GetWidth() - horizontalInset)
    local maxHeight = math.max(560, UIParent:GetHeight() - verticalInset)
    local minWidth = math.min(pageConfig.minWidth, maxWidth)
    local minHeight = math.min(pageConfig.minHeight, maxHeight)
    local width = Clamp(UIParent:GetWidth() * widthFactor, minWidth, maxWidth)
    local height = Clamp(UIParent:GetHeight() * heightFactor, minHeight, maxHeight)
    QuickViewFrame:SetScale(FRAME_VISUAL_SCALE)
    QuickViewFrame:SetSize(width, height)
    if LayoutQuickViewTabs then
        LayoutQuickViewTabs()
    end
end

UpdateQuickViewFrameSize()

local resizeWatcher = CreateFrame("Frame")
resizeWatcher:RegisterEvent("UI_SCALE_CHANGED")
resizeWatcher:RegisterEvent("DISPLAY_SIZE_CHANGED")
resizeWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
resizeWatcher:SetScript("OnEvent", function()
    UpdateQuickViewFrameSize(QuickView.ActivePageKey)
end)

local Header = CreateFrame("Frame", nil, QuickViewFrame)
Header:SetPoint("TOPLEFT", QuickViewFrame, "TOPLEFT", 10, -26)
Header:SetPoint("TOPRIGHT", QuickViewFrame, "TOPRIGHT", -10, -26)
Header:SetHeight(126)

local FrameSurface = QuickViewFrame:CreateTexture(nil, "BACKGROUND")
FrameSurface:SetPoint("TOPLEFT", QuickViewFrame, "TOPLEFT", 4, -24)
FrameSurface:SetPoint("BOTTOMRIGHT", QuickViewFrame, "BOTTOMRIGHT", -4, 4)
FrameSurface:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background-Dark")
FrameSurface:SetVertexColor(0.46, 0.31, 0.18, 0.12)

local FrameBase = QuickViewFrame:CreateTexture(nil, "BACKGROUND")
FrameBase:SetPoint("TOPLEFT", QuickViewFrame, "TOPLEFT", 6, -26)
FrameBase:SetPoint("BOTTOMRIGHT", QuickViewFrame, "BOTTOMRIGHT", -6, 6)
FrameBase:SetColorTexture(0.055, 0.039, 0.028, 0.98)

local FrameTopShade = QuickViewFrame:CreateTexture(nil, "ARTWORK")
FrameTopShade:SetPoint("TOPLEFT", QuickViewFrame, "TOPLEFT", 6, -26)
FrameTopShade:SetPoint("TOPRIGHT", QuickViewFrame, "TOPRIGHT", -6, -26)
FrameTopShade:SetHeight(90)
FrameTopShade:SetTexture("Interface\\Buttons\\WHITE8X8")
ApplyTextureGradient(FrameTopShade, "VERTICAL", 0.48, 0.31, 0.18, 0.13, 0.08, 0.05, 0.035, 0)

local FrameEdgeShade = QuickViewFrame:CreateTexture(nil, "ARTWORK")
FrameEdgeShade:SetPoint("TOPLEFT", QuickViewFrame, "TOPLEFT", 6, -26)
FrameEdgeShade:SetPoint("BOTTOMRIGHT", QuickViewFrame, "BOTTOMRIGHT", -6, 6)
FrameEdgeShade:SetTexture("Interface\\Buttons\\WHITE8X8")
ApplyTextureGradient(FrameEdgeShade, "HORIZONTAL", 0, 0, 0, 0.14, 0, 0, 0, 0.04)

local HeaderBg = Header:CreateTexture(nil, "BACKGROUND")
HeaderBg:SetAllPoints()
HeaderBg:SetColorTexture(0.09, 0.064, 0.044, 0.96)

local HeaderTexture = Header:CreateTexture(nil, "ARTWORK")
HeaderTexture:SetAllPoints()
HeaderTexture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background-Dark")
HeaderTexture:SetVertexColor(0.95, 0.78, 0.52, 0.14)

local HeaderGlow = Header:CreateTexture(nil, "BORDER")
HeaderGlow:SetPoint("TOPLEFT", Header, "TOPLEFT", 0, 0)
HeaderGlow:SetPoint("TOPRIGHT", Header, "TOPRIGHT", 0, 0)
HeaderGlow:SetHeight(30)
HeaderGlow:SetColorTexture(1, 0.86, 0.6, 0.085)

local HeaderBorder = Header:CreateTexture(nil, "ARTWORK")
HeaderBorder:SetPoint("BOTTOMLEFT", Header, "BOTTOMLEFT", 0, 0)
HeaderBorder:SetPoint("BOTTOMRIGHT", Header, "BOTTOMRIGHT", 0, 0)
HeaderBorder:SetHeight(1)
HeaderBorder:SetColorTexture(0.86, 0.72, 0.46, 0.8)

local Logo = Header:CreateTexture(nil, "ARTWORK")
Logo:SetSize(48, 48)
Logo:SetPoint("TOPLEFT", Header, "TOPLEFT", 14, -12)
Logo:SetTexture("Interface\\AddOns\\BeavisQoL\\Media\\logo.tga")

local Title = Header:CreateFontString(nil, "OVERLAY")
Title:SetPoint("TOPLEFT", Logo, "TOPRIGHT", 12, -2)
Title:SetPoint("RIGHT", Header, "RIGHT", -176, 0)
Title:SetJustifyH("LEFT")
Title:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
Title:SetTextColor(1, 0.88, 0.62, 1)
Title:SetText(addonTitle)

local Subtitle = Header:CreateFontString(nil, "OVERLAY")
Subtitle:SetPoint("TOPLEFT", Title, "BOTTOMLEFT", 0, -4)
Subtitle:SetPoint("RIGHT", Header, "RIGHT", -176, 0)
Subtitle:SetJustifyH("LEFT")
Subtitle:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
Subtitle:SetTextColor(0.83, 0.78, 0.71, 1)
Subtitle:SetText(L("HEADER_SUBTITLE"))

local VersionContainer = CreateFrame("Frame", nil, Header)
VersionContainer:SetPoint("TOPRIGHT", Header, "TOPRIGHT", -12, -26)
VersionContainer:SetSize(168, 46)

local VersionBadge = CreateFrame("Frame", nil, VersionContainer)
VersionBadge:SetSize(136, 22)

local VersionBadgeBg = VersionBadge:CreateTexture(nil, "BACKGROUND")
VersionBadgeBg:SetAllPoints()
VersionBadgeBg:SetColorTexture(0.18, 0.11, 0.07, 0.72)

local VersionBadgeAccent = VersionBadge:CreateTexture(nil, "ARTWORK")
VersionBadgeAccent:SetPoint("TOPLEFT", VersionBadge, "TOPLEFT", 0, 0)
VersionBadgeAccent:SetPoint("BOTTOMLEFT", VersionBadge, "BOTTOMLEFT", 0, 0)
VersionBadgeAccent:SetWidth(2)
VersionBadgeAccent:SetColorTexture(0.96, 0.8, 0.5, 0.86)

local VersionBadgeText = VersionBadge:CreateFontString(nil, "OVERLAY")
VersionBadgeText:SetPoint("LEFT", VersionBadge, "LEFT", 8, 0)
VersionBadgeText:SetPoint("RIGHT", VersionBadge, "RIGHT", -8, 0)
VersionBadgeText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
VersionBadgeText:SetTextColor(1, 0.9, 0.64, 1)
VersionBadgeText:SetJustifyH("CENTER")
VersionBadgeText:SetText(L("VERSION") .. " " .. version)

local ReloadButton = CreateFrame("Button", nil, VersionContainer, "UIPanelButtonTemplate")
ReloadButton:SetSize(136, 18)
ReloadButton:SetPoint("TOPRIGHT", VersionContainer, "TOPRIGHT", 0, 0)
ReloadButton:SetText(L("RELOAD"))
ReloadButton:SetNormalFontObject("GameFontNormalSmall")
ReloadButton:SetHighlightFontObject("GameFontHighlightSmall")
ReloadButton:SetScript("OnClick", function()
    ReloadUI()
end)

VersionBadge:ClearAllPoints()
VersionBadge:SetPoint("TOPRIGHT", ReloadButton, "BOTTOMRIGHT", 0, -5)

local HeaderTabDivider = Header:CreateTexture(nil, "ARTWORK")
HeaderTabDivider:SetPoint("TOPLEFT", Header, "TOPLEFT", 0, -74)
HeaderTabDivider:SetPoint("TOPRIGHT", Header, "TOPRIGHT", 0, -74)
HeaderTabDivider:SetHeight(1)
HeaderTabDivider:SetColorTexture(0.86, 0.72, 0.46, 0.72)

TabBar = CreateFrame("Frame", nil, Header)
TabBar:SetPoint("TOPLEFT", Header, "TOPLEFT", 14, -86)
TabBar:SetPoint("TOPRIGHT", Header, "TOPRIGHT", -14, -86)
TabBar:SetHeight(28)

local function ApplyQuickViewTabVisual(button, isHovered)
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

    if button.Sheen then
        button.Sheen:SetAlpha(sheenAlpha)
    end

    if button.Label then
        button.Label:SetTextColor(textColor[1], textColor[2], textColor[3], textColor[4])
    end
end

local function GetVisibleQuickViewTabEntries()
    local entries = {}
    local isEntryVisible = BeavisQoL.IsMinimapContextMenuEntryVisible

    for _, tabInfo in ipairs(QUICK_VIEW_PAGE_ORDER) do
        local visible = true
        if type(isEntryVisible) == "function" and tabInfo.entryKey then
            visible = isEntryVisible(tabInfo.entryKey) == true
        end

        if visible or QuickView.ActivePageKey == tabInfo.pageKey then
            entries[#entries + 1] = tabInfo
        end
    end

    return entries
end

local function EnsureQuickViewTabButton(index)
    if TabButtons[index] then
        return TabButtons[index]
    end

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
        ApplyQuickViewTabVisual(self, true)
    end)

    button:SetScript("OnLeave", function(self)
        ApplyQuickViewTabVisual(self, false)
    end)

    button:SetScript("OnClick", function(self)
        if self.pageKey and QuickView and QuickView.Open then
            QuickView:Open(self.pageKey)
        end
    end)

    ApplyQuickViewTabVisual(button, false)
    TabButtons[index] = button
    return button
end

LayoutQuickViewTabs = function()
    if not TabBar then
        return
    end

    local visibleButtons = {}

    for _, button in ipairs(TabButtons) do
        if button:IsShown() then
            visibleButtons[#visibleButtons + 1] = button
        end
    end

    local buttonCount = #visibleButtons
    if buttonCount == 0 then
        return
    end

    local gap = 6
    local availableWidth = TabBar:GetWidth()
    if not availableWidth or availableWidth <= 0 then
        availableWidth = math.max(560, QuickViewFrame:GetWidth() - 80)
    end

    local buttonWidth = math.floor((availableWidth - ((buttonCount - 1) * gap)) / buttonCount)
    buttonWidth = math.max(112, math.min(188, buttonWidth))

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

RefreshQuickViewTabs = function()
    local visibleEntries = GetVisibleQuickViewTabEntries()

    for index, tabInfo in ipairs(visibleEntries) do
        local button = EnsureQuickViewTabButton(index)
        button.pageKey = tabInfo.pageKey
        button.isActive = QuickView.ActivePageKey == tabInfo.pageKey
        button.Label:SetText(GetQuickViewTitle(tabInfo.pageKey))
        button:Show()
        ApplyQuickViewTabVisual(button, false)
    end

    for index = #visibleEntries + 1, #TabButtons do
        TabButtons[index].pageKey = nil
        TabButtons[index].isActive = false
        TabButtons[index]:Hide()
    end

    LayoutQuickViewTabs()
end

TabBar:SetScript("OnSizeChanged", function()
    LayoutQuickViewTabs()
end)

local ContentFrame = CreateFrame("Frame", nil, QuickViewFrame)
ContentFrame:SetPoint("TOPLEFT", QuickViewFrame, "TOPLEFT", 10, -162)
ContentFrame:SetPoint("BOTTOMRIGHT", QuickViewFrame, "BOTTOMRIGHT", -10, 10)

local ContentBg = ContentFrame:CreateTexture(nil, "BACKGROUND")
ContentBg:SetAllPoints()
ContentBg:SetColorTexture(0.07, 0.05, 0.036, 0.94)

local ContentTexture = ContentFrame:CreateTexture(nil, "ARTWORK")
ContentTexture:SetAllPoints()
ContentTexture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background-Dark")
ContentTexture:SetVertexColor(0.95, 0.78, 0.52, 0.08)

local ContentGlow = ContentFrame:CreateTexture(nil, "BORDER")
ContentGlow:SetPoint("TOPLEFT", ContentFrame, "TOPLEFT", 0, 0)
ContentGlow:SetPoint("TOPRIGHT", ContentFrame, "TOPRIGHT", 0, 0)
ContentGlow:SetHeight(40)
ContentGlow:SetColorTexture(1, 0.88, 0.64, 0.04)

local ContentTopBorder = ContentFrame:CreateTexture(nil, "ARTWORK")
ContentTopBorder:SetPoint("TOPLEFT", ContentFrame, "TOPLEFT", 0, 0)
ContentTopBorder:SetPoint("TOPRIGHT", ContentFrame, "TOPRIGHT", 0, 0)
ContentTopBorder:SetHeight(1)
ContentTopBorder:SetColorTexture(0.88, 0.72, 0.46, 0.28)

local ContentEdgeShade = ContentFrame:CreateTexture(nil, "ARTWORK")
ContentEdgeShade:SetPoint("TOPLEFT", ContentFrame, "TOPLEFT", 0, 0)
ContentEdgeShade:SetPoint("BOTTOMRIGHT", ContentFrame, "BOTTOMRIGHT", 0, 0)
ContentEdgeShade:SetTexture("Interface\\Buttons\\WHITE8X8")
ApplyTextureGradient(ContentEdgeShade, "HORIZONTAL", 0, 0, 0, 0.1, 0, 0, 0, 0.02)

local function RefreshActiveQuickViewLayout()
    if not QuickView.ActivePageKey or not Pages then
        return
    end

    local page = Pages[QuickView.ActivePageKey]
    if not page or not page:IsShown() then
        return
    end

    if page.RefreshState then
        page:RefreshState()
    elseif page.UpdateScrollLayout then
        page:UpdateScrollLayout()
    end
end

QuickViewFrame:SetScript("OnSizeChanged", function()
    if LayoutQuickViewTabs then
        LayoutQuickViewTabs()
    end

    RefreshActiveQuickViewLayout()
end)

local function RestorePageToMainWindow(pageKey)
    if not pageKey or not Pages then
        return
    end

    local page = Pages[pageKey]
    if not page then
        return
    end

    if page.SetQuickViewMode then
        page:SetQuickViewMode(false)
    end

    page.IsDetachedQuickView = nil
    page:SetParent(page._beavisQuickViewOriginalParent or BeavisQoL.Content or UIParent)
    page:ClearAllPoints()
    page:SetAllPoints()
    page:Hide()
end

local function AttachPageToQuickView(pageKey)
    if not pageKey or not Pages then
        return false
    end

    local page = Pages[pageKey]
    if not page then
        return false
    end

    if BeavisQoL.Frame and BeavisQoL.Frame:IsShown() and page:IsShown() and page:GetParent() ~= ContentFrame and BeavisQoL.OpenPage then
        BeavisQoL.OpenPage("Home")
    end

    if page:GetParent() ~= ContentFrame then
        page._beavisQuickViewOriginalParent = page:GetParent() or BeavisQoL.Content
    end
    page:SetParent(ContentFrame)
    page:ClearAllPoints()
    page:SetAllPoints()
    page.IsDetachedQuickView = true

    if page.SetQuickViewMode then
        page:SetQuickViewMode(true)
    end

    page:Show()

    if page.RefreshState then
        page:RefreshState()
    end

    return true
end

function QuickView:RestoreActivePage()
    if not self.ActivePageKey then
        return
    end

    RestorePageToMainWindow(self.ActivePageKey)
    self.ActivePageKey = nil
    if RefreshQuickViewTabs then
        RefreshQuickViewTabs()
    end
    UpdateQuickViewFrameSize()
end

function QuickView:Open(pageKey)
    if QUICK_VIEW_PAGE_TITLES[pageKey] == nil then
        return false
    end

    if self.ActivePageKey and self.ActivePageKey ~= pageKey then
        RestorePageToMainWindow(self.ActivePageKey)
        self.ActivePageKey = nil
    end

    if not AttachPageToQuickView(pageKey) then
        return false
    end

    self.ActivePageKey = pageKey
    Title:SetText(addonTitle)
    Subtitle:SetText(L("HEADER_SUBTITLE"))
    if RefreshQuickViewTabs then
        RefreshQuickViewTabs()
    end
    UpdateQuickViewFrameSize(pageKey)
    QuickViewFrame:Show()
    QuickViewFrame:Raise()
    return true
end

function QuickView:Close()
    if QuickViewFrame:IsShown() then
        QuickViewFrame:Hide()
    else
        self:RestoreActivePage()
    end
end

QuickViewFrame:SetScript("OnHide", function()
    if BeavisQoL.HideLinkPopup then
        BeavisQoL.HideLinkPopup()
    end

    QuickView:RestoreActivePage()
end)

BeavisQoL.OpenQuickView = function(pageKey)
    return QuickView:Open(pageKey)
end

BeavisQoL.UpdateQuickViewUI = function()
    Title:SetText(addonTitle)
    Subtitle:SetText(L("HEADER_SUBTITLE"))
    VersionBadgeText:SetText(L("VERSION") .. " " .. version)
    ReloadButton:SetText(L("RELOAD"))
    if RefreshQuickViewTabs then
        RefreshQuickViewTabs()
    end

    if QuickView.ActivePageKey then
        UpdateQuickViewFrameSize(QuickView.ActivePageKey)
    else
        UpdateQuickViewFrameSize()
    end
end

QuickView.Frame = QuickViewFrame
QuickView.Content = ContentFrame
QuickView.TabBar = TabBar
