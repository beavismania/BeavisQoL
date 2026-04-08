local ADDON_NAME, BeavisQoL = ...

local Pages = BeavisQoL.Pages
local L = BeavisQoL.L
local metadata = BeavisQoL.Metadata or {}
local addonTitle = metadata.title or C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title") or L("UNKNOWN")
local FRAME_VISUAL_SCALE = BeavisQoL.FrameVisualScale or 1

local QUICK_VIEW_PAGE_TITLES = {
    LevelTime = "LEVEL_TIME",
    ItemLevelGuide = "ITEMLEVEL_GUIDE",
    QuestCheck = "QUEST_CHECK",
    QuestAbandon = "QUEST_ABANDON",
    Logging = "GOLDAUSWERTUNG",
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

local QuickView = BeavisQoL.QuickView or {}
BeavisQoL.QuickView = QuickView

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
    local pageConfig = QUICK_VIEW_PAGE_CONFIG[pageKey] or {}
    local widthFactor = pageConfig.widthFactor or 0.50
    local heightFactor = pageConfig.heightFactor or 0.58
    local horizontalInset = pageConfig.horizontalInset or 140
    local verticalInset = pageConfig.verticalInset or 120
    local maxWidth = math.max(760, UIParent:GetWidth() - horizontalInset)
    local maxHeight = math.max(560, UIParent:GetHeight() - verticalInset)
    local minWidth = math.min(pageConfig.minWidth or 980, maxWidth)
    local minHeight = math.min(pageConfig.minHeight or 760, maxHeight)
    local width = Clamp(UIParent:GetWidth() * widthFactor, minWidth, maxWidth)
    local height = Clamp(UIParent:GetHeight() * heightFactor, minHeight, maxHeight)
    QuickViewFrame:SetScale(FRAME_VISUAL_SCALE)
    QuickViewFrame:SetSize(width, height)
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
Header:SetHeight(72)

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
HeaderGlow:SetHeight(28)
HeaderGlow:SetColorTexture(1, 0.86, 0.6, 0.085)

local HeaderBorder = Header:CreateTexture(nil, "ARTWORK")
HeaderBorder:SetPoint("BOTTOMLEFT", Header, "BOTTOMLEFT", 0, 0)
HeaderBorder:SetPoint("BOTTOMRIGHT", Header, "BOTTOMRIGHT", 0, 0)
HeaderBorder:SetHeight(1)
HeaderBorder:SetColorTexture(0.86, 0.72, 0.46, 0.8)

local Logo = Header:CreateTexture(nil, "ARTWORK")
Logo:SetSize(44, 44)
Logo:SetPoint("LEFT", Header, "LEFT", 14, 0)
Logo:SetTexture("Interface\\AddOns\\BeavisQoL\\Media\\logo.tga")

local Title = Header:CreateFontString(nil, "OVERLAY")
Title:SetPoint("TOPLEFT", Logo, "TOPRIGHT", 12, -1)
Title:SetPoint("RIGHT", Header, "RIGHT", -42, 0)
Title:SetJustifyH("LEFT")
Title:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
Title:SetTextColor(1, 0.88, 0.62, 1)
Title:SetText(addonTitle)

local Subtitle = Header:CreateFontString(nil, "OVERLAY")
Subtitle:SetPoint("TOPLEFT", Title, "BOTTOMLEFT", 0, -3)
Subtitle:SetPoint("RIGHT", Header, "RIGHT", -42, 0)
Subtitle:SetJustifyH("LEFT")
Subtitle:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
Subtitle:SetTextColor(0.83, 0.78, 0.71, 1)
Subtitle:SetText(L("MINIMAP_CONTEXT_QUICK_VIEW"))

local ContentFrame = CreateFrame("Frame", nil, QuickViewFrame)
ContentFrame:SetPoint("TOPLEFT", QuickViewFrame, "TOPLEFT", 10, -108)
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
ContentTopBorder:SetColorTexture(0.86, 0.72, 0.46, 0.32)

local ContentEdgeShade = ContentFrame:CreateTexture(nil, "ARTWORK")
ContentEdgeShade:SetPoint("TOPLEFT", ContentFrame, "TOPLEFT", 0, 0)
ContentEdgeShade:SetPoint("BOTTOMRIGHT", ContentFrame, "BOTTOMRIGHT", 0, 0)
ContentEdgeShade:SetTexture("Interface\\Buttons\\WHITE8X8")
ApplyTextureGradient(ContentEdgeShade, "HORIZONTAL", 0, 0, 0, 0.1, 0, 0, 0, 0.02)

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
    UpdateQuickViewFrameSize(pageKey)
    Title:SetText(GetQuickViewTitle(pageKey))
    Subtitle:SetText(L("MINIMAP_CONTEXT_QUICK_VIEW"))
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
    Subtitle:SetText(L("MINIMAP_CONTEXT_QUICK_VIEW"))

    if QuickView.ActivePageKey then
        Title:SetText(GetQuickViewTitle(QuickView.ActivePageKey))
        UpdateQuickViewFrameSize(QuickView.ActivePageKey)
    else
        Title:SetText(addonTitle)
        UpdateQuickViewFrameSize()
    end
end

QuickView.Frame = QuickViewFrame
QuickView.Content = ContentFrame
