local ADDON_NAME, BeavisQoL = ...

--[[
UI.lua baut das feste Grundgerüst des Addons.

Hier entsteht nur der gemeinsame Rahmen:
- Hauptfenster
- Header
- Sidebar
- Content-Fläche
- zentrales Link-Popup
]]

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

local L = BeavisQoL.L
local metadata = BeavisQoL.Metadata or {}
local version = metadata.version or C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or L("UNKNOWN")
local name = metadata.title or C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title") or L("UNKNOWN")
local FRAME_VISUAL_SCALE = 0.924
local CATEGORY_TAB_TITLE_EXCLUSIONS = {
    Home = true,
    Settings = true,
    Version = true,
}

BeavisQoL.Version = version
BeavisQoL.Title = name
BeavisQoL.FrameVisualScale = FRAME_VISUAL_SCALE
BeavisQoL.DebugConsole = BeavisQoL.DebugConsole or {}

local DebugConsole = BeavisQoL.DebugConsole
local DebugConsoleState = {
    modules = {},
    moduleOrder = {},
    latestModuleKey = nil,
    selectedModuleKey = nil,
}

function BeavisQoL.GetModulePageTitle(pageKey, defaultText)
    return defaultText or ""
end

local function TrimText(text)
    return tostring(text or ""):match("^%s*(.-)%s*$") or ""
end

local function NormalizeDebugModuleKey(moduleKey)
    local normalizedKey = string.lower(TrimText(moduleKey))
    if normalizedKey == "" then
        return nil
    end

    return normalizedKey
end

local function EnsureDebugModuleEntry(moduleKey, options)
    local normalizedKey = NormalizeDebugModuleKey(moduleKey)
    if not normalizedKey then
        return nil
    end

    local entry = DebugConsoleState.modules[normalizedKey]
    if not entry then
        entry = {
            key = normalizedKey,
            titleText = tostring((options and options.titleText) or moduleKey or normalizedKey),
            lines = {},
        }

        DebugConsoleState.modules[normalizedKey] = entry
        DebugConsoleState.moduleOrder[#DebugConsoleState.moduleOrder + 1] = normalizedKey
    end

    if options and type(options.titleText) == "string" and options.titleText ~= "" then
        entry.titleText = options.titleText
    end

    return entry
end

local function GetDebugModuleEntry(moduleKey)
    local normalizedKey = NormalizeDebugModuleKey(moduleKey)
    if not normalizedKey then
        return nil
    end

    return DebugConsoleState.modules[normalizedKey]
end

local BeavisFrame = CreateFrame("Frame", "BeavisQoLMainFrame", UIParent, "BasicFrameTemplateWithInset")
BeavisFrame:SetPoint("CENTER")
BeavisFrame:SetScale(FRAME_VISUAL_SCALE)
BeavisFrame:SetClampedToScreen(true)
BeavisFrame:RegisterForDrag("LeftButton")
BeavisFrame:SetScript("OnDragStart", function(self)
    if BeavisQoLDB.settings and BeavisQoLDB.settings.lockWindow then return end
    self:StartMoving()
end)
BeavisFrame:SetScript("OnDragStop", function(self)
    if BeavisQoLDB.settings and BeavisQoLDB.settings.lockWindow then return end
    self:StopMovingOrSizing()
end)
BeavisFrame:SetMovable(true)
BeavisFrame:EnableMouse(true)
BeavisFrame:SetToplevel(true)
BeavisFrame:SetFrameStrata("HIGH")
BeavisFrame:Hide()

-- Berücksichtige Lock-Einstellung
if BeavisQoLDB.settings and BeavisQoLDB.settings.lockWindow then
    BeavisFrame:SetMovable(false)
end

if _G.BeavisQoLMainFrameTitleText then
    _G.BeavisQoLMainFrameTitleText:SetText("")
end

if _G.BeavisQoLMainFramePortrait then
    _G.BeavisQoLMainFramePortrait:Hide()
end

if _G.BeavisQoLMainFrameTitleBg then
    _G.BeavisQoLMainFrameTitleBg:Hide()
end

if _G.BeavisQoLMainFrameBg then
    _G.BeavisQoLMainFrameBg:Hide()
end

if _G.BeavisQoLMainFrameInset and _G.BeavisQoLMainFrameInset.Bg then
    _G.BeavisQoLMainFrameInset.Bg:Hide()
end

BeavisQoL.Frame = BeavisFrame

if UISpecialFrames then
    local alreadyRegistered = false

    for _, frameName in ipairs(UISpecialFrames) do
        if frameName == "BeavisQoLMainFrame" then
            alreadyRegistered = true
            break
        end
    end

    if not alreadyRegistered then
        table.insert(UISpecialFrames, "BeavisQoLMainFrame")
    end
end

local function UpdateBeavisFrameSize()
    local maxWidth = math.max(940, UIParent:GetWidth() - 56)
    local maxHeight = math.max(680, UIParent:GetHeight() - 72)
    local minWidth = math.min(1080, maxWidth)
    local minHeight = math.min(740, maxHeight)
    local width = Clamp(UIParent:GetWidth() * 0.64, minWidth, maxWidth)
    local height = Clamp(UIParent:GetHeight() * 0.66, minHeight, maxHeight)
    BeavisFrame:SetScale(FRAME_VISUAL_SCALE)
    BeavisFrame:SetSize(width, height)
end

UpdateBeavisFrameSize()

local resizeWatcher = CreateFrame("Frame")
resizeWatcher:RegisterEvent("UI_SCALE_CHANGED")
resizeWatcher:RegisterEvent("DISPLAY_SIZE_CHANGED")
resizeWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
resizeWatcher:SetScript("OnEvent", function()
    UpdateBeavisFrameSize()
end)

local Header = CreateFrame("Frame", nil, BeavisFrame)
Header:SetPoint("TOPLEFT", BeavisFrame, "TOPLEFT", 10, -26)
Header:SetPoint("TOPRIGHT", BeavisFrame, "TOPRIGHT", -10, -26)
Header:SetHeight(78)

BeavisQoL.Header = Header

local FrameSurface = BeavisFrame:CreateTexture(nil, "BACKGROUND")
FrameSurface:SetPoint("TOPLEFT", BeavisFrame, "TOPLEFT", 4, -24)
FrameSurface:SetPoint("BOTTOMRIGHT", BeavisFrame, "BOTTOMRIGHT", -4, 4)
FrameSurface:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background-Dark")
FrameSurface:SetVertexColor(0.46, 0.31, 0.18, 0.12)

local FrameBase = BeavisFrame:CreateTexture(nil, "BACKGROUND")
FrameBase:SetPoint("TOPLEFT", BeavisFrame, "TOPLEFT", 6, -26)
FrameBase:SetPoint("BOTTOMRIGHT", BeavisFrame, "BOTTOMRIGHT", -6, 6)
FrameBase:SetColorTexture(0.055, 0.039, 0.028, 0.98)

local FrameTopShade = BeavisFrame:CreateTexture(nil, "ARTWORK")
FrameTopShade:SetPoint("TOPLEFT", BeavisFrame, "TOPLEFT", 6, -26)
FrameTopShade:SetPoint("TOPRIGHT", BeavisFrame, "TOPRIGHT", -6, -26)
FrameTopShade:SetHeight(100)
FrameTopShade:SetTexture("Interface\\Buttons\\WHITE8X8")
ApplyTextureGradient(FrameTopShade, "VERTICAL", 0.48, 0.31, 0.18, 0.13, 0.08, 0.05, 0.035, 0)

local FrameEdgeShade = BeavisFrame:CreateTexture(nil, "ARTWORK")
FrameEdgeShade:SetPoint("TOPLEFT", BeavisFrame, "TOPLEFT", 6, -26)
FrameEdgeShade:SetPoint("BOTTOMRIGHT", BeavisFrame, "BOTTOMRIGHT", -6, 6)
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
Logo:SetPoint("LEFT", Header, "LEFT", 14, 0)
Logo:SetTexture("Interface\\AddOns\\BeavisQoL\\Media\\logo.tga")

local Title = Header:CreateFontString(nil, "OVERLAY")
Title:SetPoint("TOPLEFT", Logo, "TOPRIGHT", 12, -2)
Title:SetPoint("RIGHT", Header, "RIGHT", -176, 0)
Title:SetJustifyH("LEFT")
Title:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
Title:SetTextColor(1, 0.88, 0.62, 1)
Title:SetText(name)

local HeaderSubtitle = Header:CreateFontString(nil, "OVERLAY")
HeaderSubtitle:SetPoint("TOPLEFT", Title, "BOTTOMLEFT", 0, -4)
HeaderSubtitle:SetPoint("RIGHT", Header, "RIGHT", -176, 0)
HeaderSubtitle:SetJustifyH("LEFT")
HeaderSubtitle:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
HeaderSubtitle:SetTextColor(0.83, 0.78, 0.71, 1)
HeaderSubtitle:SetText(L("HEADER_SUBTITLE"))

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

local Sidebar = CreateFrame("Frame", nil, BeavisFrame)
Sidebar:SetPoint("TOPLEFT", Header, "BOTTOMLEFT", 0, 0)
Sidebar:SetPoint("BOTTOMLEFT", BeavisFrame, "BOTTOMLEFT", 10, 10)
Sidebar:SetWidth(220)

BeavisQoL.Sidebar = Sidebar

local SidebarBg = Sidebar:CreateTexture(nil, "BACKGROUND")
SidebarBg:SetAllPoints()
SidebarBg:SetColorTexture(0.075, 0.05, 0.034, 0.96)

local SidebarTexture = Sidebar:CreateTexture(nil, "ARTWORK")
SidebarTexture:SetAllPoints()
SidebarTexture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background-Dark")
SidebarTexture:SetVertexColor(0.95, 0.78, 0.52, 0.13)

local SidebarTopShade = Sidebar:CreateTexture(nil, "BORDER")
SidebarTopShade:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", 0, 0)
SidebarTopShade:SetPoint("TOPRIGHT", Sidebar, "TOPRIGHT", 0, 0)
SidebarTopShade:SetHeight(52)
SidebarTopShade:SetTexture("Interface\\Buttons\\WHITE8X8")
ApplyTextureGradient(SidebarTopShade, "VERTICAL", 0.5, 0.32, 0.18, 0.16, 0.1, 0.06, 0.04, 0)

local SidebarInnerShade = Sidebar:CreateTexture(nil, "ARTWORK")
SidebarInnerShade:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", 0, 0)
SidebarInnerShade:SetPoint("BOTTOMRIGHT", Sidebar, "BOTTOMRIGHT", 0, 0)
SidebarInnerShade:SetTexture("Interface\\Buttons\\WHITE8X8")
ApplyTextureGradient(SidebarInnerShade, "HORIZONTAL", 0, 0, 0, 0.04, 0, 0, 0, 0.2)

local SidebarGlow = Sidebar:CreateTexture(nil, "BORDER")
SidebarGlow:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", 0, 0)
SidebarGlow:SetPoint("TOPRIGHT", Sidebar, "TOPRIGHT", 0, 0)
SidebarGlow:SetHeight(28)
SidebarGlow:SetColorTexture(1, 0.86, 0.58, 0.05)

local SidebarTopBorder = Sidebar:CreateTexture(nil, "ARTWORK")
SidebarTopBorder:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", 0, 0)
SidebarTopBorder:SetPoint("TOPRIGHT", Sidebar, "TOPRIGHT", 0, 0)
SidebarTopBorder:SetHeight(1)
SidebarTopBorder:SetColorTexture(0.84, 0.68, 0.44, 0.42)

local SidebarRightBorder = Sidebar:CreateTexture(nil, "ARTWORK")
SidebarRightBorder:SetPoint("TOPRIGHT", Sidebar, "TOPRIGHT", 0, 0)
SidebarRightBorder:SetPoint("BOTTOMRIGHT", Sidebar, "BOTTOMRIGHT", 0, 0)
SidebarRightBorder:SetWidth(1)
SidebarRightBorder:SetColorTexture(0.88, 0.72, 0.46, 0.46)

local Content = CreateFrame("Frame", nil, BeavisFrame)
Content:SetPoint("TOPLEFT", Sidebar, "TOPRIGHT", 10, 0)
Content:SetPoint("BOTTOMRIGHT", BeavisFrame, "BOTTOMRIGHT", -10, 10)

BeavisQoL.Content = Content

local ContentBg = Content:CreateTexture(nil, "BACKGROUND")
ContentBg:SetAllPoints()
ContentBg:SetColorTexture(0.07, 0.05, 0.036, 0.94)

local ContentTexture = Content:CreateTexture(nil, "ARTWORK")
ContentTexture:SetAllPoints()
ContentTexture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background-Dark")
ContentTexture:SetVertexColor(0.95, 0.78, 0.52, 0.08)

local ContentGlow = Content:CreateTexture(nil, "BORDER")
ContentGlow:SetPoint("TOPLEFT", Content, "TOPLEFT", 0, 0)
ContentGlow:SetPoint("TOPRIGHT", Content, "TOPRIGHT", 0, 0)
ContentGlow:SetHeight(44)
ContentGlow:SetColorTexture(1, 0.88, 0.64, 0.04)

local ContentTopBorder = Content:CreateTexture(nil, "ARTWORK")
ContentTopBorder:SetPoint("TOPLEFT", Content, "TOPLEFT", 0, 0)
ContentTopBorder:SetPoint("TOPRIGHT", Content, "TOPRIGHT", 0, 0)
ContentTopBorder:SetHeight(1)
ContentTopBorder:SetColorTexture(0.86, 0.72, 0.46, 0.32)

local ContentEdgeShade = Content:CreateTexture(nil, "ARTWORK")
ContentEdgeShade:SetPoint("TOPLEFT", Content, "TOPLEFT", 0, 0)
ContentEdgeShade:SetPoint("BOTTOMRIGHT", Content, "BOTTOMRIGHT", 0, 0)
ContentEdgeShade:SetTexture("Interface\\Buttons\\WHITE8X8")
ApplyTextureGradient(ContentEdgeShade, "HORIZONTAL", 0, 0, 0, 0.1, 0, 0, 0, 0.02)

local LinkPopup = CreateFrame("Frame", nil, BeavisFrame)
LinkPopup:SetSize(520, 170)
LinkPopup:SetPoint("CENTER", BeavisFrame, "CENTER", 0, 0)
LinkPopup:SetFrameStrata("DIALOG")
LinkPopup:EnableMouse(true)
LinkPopup:Hide()

local LinkPopupBg = LinkPopup:CreateTexture(nil, "BACKGROUND")
LinkPopupBg:SetAllPoints()
LinkPopupBg:SetColorTexture(0.08, 0.055, 0.038, 0.98)

local LinkPopupTexture = LinkPopup:CreateTexture(nil, "ARTWORK")
LinkPopupTexture:SetAllPoints()
LinkPopupTexture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background-Dark")
LinkPopupTexture:SetVertexColor(0.95, 0.78, 0.52, 0.12)

local LinkPopupGlow = LinkPopup:CreateTexture(nil, "BORDER")
LinkPopupGlow:SetPoint("TOPLEFT", LinkPopup, "TOPLEFT", 0, 0)
LinkPopupGlow:SetPoint("TOPRIGHT", LinkPopup, "TOPRIGHT", 0, 0)
LinkPopupGlow:SetHeight(26)
LinkPopupGlow:SetColorTexture(1, 0.86, 0.62, 0.09)

local LinkPopupBorderTop = LinkPopup:CreateTexture(nil, "ARTWORK")
LinkPopupBorderTop:SetPoint("TOPLEFT", LinkPopup, "TOPLEFT", 0, 0)
LinkPopupBorderTop:SetPoint("TOPRIGHT", LinkPopup, "TOPRIGHT", 0, 0)
LinkPopupBorderTop:SetHeight(1)
LinkPopupBorderTop:SetColorTexture(0.9, 0.76, 0.5, 0.9)

local LinkPopupBorderBottom = LinkPopup:CreateTexture(nil, "ARTWORK")
LinkPopupBorderBottom:SetPoint("BOTTOMLEFT", LinkPopup, "BOTTOMLEFT", 0, 0)
LinkPopupBorderBottom:SetPoint("BOTTOMRIGHT", LinkPopup, "BOTTOMRIGHT", 0, 0)
LinkPopupBorderBottom:SetHeight(1)
LinkPopupBorderBottom:SetColorTexture(0.9, 0.76, 0.5, 0.9)

local LinkPopupTitle = LinkPopup:CreateFontString(nil, "OVERLAY")
LinkPopupTitle:SetPoint("TOPLEFT", LinkPopup, "TOPLEFT", 16, -14)
LinkPopupTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
LinkPopupTitle:SetTextColor(1, 0.88, 0.62, 1)
LinkPopupTitle:SetText(L("LINK_OPEN"))

local LinkPopupText = LinkPopup:CreateFontString(nil, "OVERLAY")
LinkPopupText:SetPoint("TOPLEFT", LinkPopupTitle, "BOTTOMLEFT", 0, -10)
LinkPopupText:SetPoint("RIGHT", LinkPopup, "RIGHT", -16, 0)
LinkPopupText:SetJustifyH("LEFT")
LinkPopupText:SetJustifyV("TOP")
LinkPopupText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
LinkPopupText:SetTextColor(0.93, 0.89, 0.84, 1)
LinkPopupText:SetText(L("LINK_COPY_DESC"))

local LinkPopupEditBox = CreateFrame("EditBox", nil, LinkPopup, "InputBoxTemplate")
LinkPopupEditBox:SetSize(470, 30)
LinkPopupEditBox:SetPoint("TOPLEFT", LinkPopupText, "BOTTOMLEFT", 0, -14)
LinkPopupEditBox:SetAutoFocus(false)
LinkPopupEditBox:SetFontObject(ChatFontNormal)

local LinkPopupHint = LinkPopup:CreateFontString(nil, "OVERLAY")
LinkPopupHint:SetPoint("TOPLEFT", LinkPopupEditBox, "BOTTOMLEFT", 4, -10)
LinkPopupHint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
LinkPopupHint:SetTextColor(0.8, 0.74, 0.68, 1)
LinkPopupHint:SetText(L("LINK_COPY_HINT"))

local DebugConsolePopup
local RefreshDebugConsolePopup

local function HideLinkPopup()
    LinkPopupEditBox:ClearFocus()
    LinkPopup:Hide()
end

local function GetPopupParent()
    local quickView = BeavisQoL.QuickView
    if quickView and quickView.Frame and quickView.Frame:IsShown() then
        return quickView.Frame
    end

    return BeavisFrame
end

local function GetLinkPopupParent()
    return GetPopupParent()
end

local function GetDebugConsoleParent()
    local popupParent = GetPopupParent()
    if popupParent and popupParent:IsShown() then
        return popupParent
    end

    return UIParent
end

local function BuildDebugConsoleText(entry)
    if not entry or type(entry.lines) ~= "table" or #entry.lines <= 0 then
        return L("DEBUG_CONSOLE_EMPTY")
    end

    return table.concat(entry.lines, "\n")
end

local function EnsureDebugConsolePopup()
    if DebugConsolePopup then
        return DebugConsolePopup
    end

    DebugConsolePopup = CreateFrame("Frame", nil, BeavisFrame)
    DebugConsolePopup:SetSize(760, 500)
    DebugConsolePopup:SetPoint("CENTER", BeavisFrame, "CENTER", 0, 0)
    DebugConsolePopup:SetFrameStrata("DIALOG")
    DebugConsolePopup:EnableMouse(true)
    DebugConsolePopup:SetMovable(true)
    DebugConsolePopup:RegisterForDrag("LeftButton")
    DebugConsolePopup:SetClampedToScreen(true)
    DebugConsolePopup:SetScript("OnDragStart", DebugConsolePopup.StartMoving)
    DebugConsolePopup:SetScript("OnDragStop", DebugConsolePopup.StopMovingOrSizing)
    DebugConsolePopup:Hide()

    local background = DebugConsolePopup:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.08, 0.055, 0.038, 0.98)
    DebugConsolePopup.Background = background

    local texture = DebugConsolePopup:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    texture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background-Dark")
    texture:SetVertexColor(0.95, 0.78, 0.52, 0.12)
    DebugConsolePopup.Texture = texture

    local glow = DebugConsolePopup:CreateTexture(nil, "BORDER")
    glow:SetPoint("TOPLEFT", DebugConsolePopup, "TOPLEFT", 0, 0)
    glow:SetPoint("TOPRIGHT", DebugConsolePopup, "TOPRIGHT", 0, 0)
    glow:SetHeight(28)
    glow:SetColorTexture(1, 0.86, 0.62, 0.09)
    DebugConsolePopup.Glow = glow

    local borderTop = DebugConsolePopup:CreateTexture(nil, "ARTWORK")
    borderTop:SetPoint("TOPLEFT", DebugConsolePopup, "TOPLEFT", 0, 0)
    borderTop:SetPoint("TOPRIGHT", DebugConsolePopup, "TOPRIGHT", 0, 0)
    borderTop:SetHeight(1)
    borderTop:SetColorTexture(0.9, 0.76, 0.5, 0.9)
    DebugConsolePopup.BorderTop = borderTop

    local borderBottom = DebugConsolePopup:CreateTexture(nil, "ARTWORK")
    borderBottom:SetPoint("BOTTOMLEFT", DebugConsolePopup, "BOTTOMLEFT", 0, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", DebugConsolePopup, "BOTTOMRIGHT", 0, 0)
    borderBottom:SetHeight(1)
    borderBottom:SetColorTexture(0.9, 0.76, 0.5, 0.9)
    DebugConsolePopup.BorderBottom = borderBottom

    local title = DebugConsolePopup:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOPLEFT", DebugConsolePopup, "TOPLEFT", 16, -14)
    title:SetPoint("RIGHT", DebugConsolePopup, "RIGHT", -46, 0)
    title:SetJustifyH("LEFT")
    title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    title:SetTextColor(1, 0.88, 0.62, 1)
    DebugConsolePopup.Title = title

    local moduleLabel = DebugConsolePopup:CreateFontString(nil, "OVERLAY")
    moduleLabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    moduleLabel:SetPoint("RIGHT", DebugConsolePopup, "RIGHT", -18, 0)
    moduleLabel:SetJustifyH("LEFT")
    moduleLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    moduleLabel:SetTextColor(0.96, 0.9, 0.78, 1)
    DebugConsolePopup.ModuleLabel = moduleLabel

    local instructions = DebugConsolePopup:CreateFontString(nil, "OVERLAY")
    instructions:SetPoint("TOPLEFT", moduleLabel, "BOTTOMLEFT", 0, -8)
    instructions:SetPoint("RIGHT", DebugConsolePopup, "RIGHT", -18, 0)
    instructions:SetJustifyH("LEFT")
    instructions:SetJustifyV("TOP")
    instructions:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    instructions:SetTextColor(0.82, 0.76, 0.7, 1)
    DebugConsolePopup.Instructions = instructions

    local textPanel = CreateFrame("Frame", nil, DebugConsolePopup)
    textPanel:SetPoint("TOPLEFT", instructions, "BOTTOMLEFT", 0, -12)
    textPanel:SetPoint("BOTTOMRIGHT", DebugConsolePopup, "BOTTOMRIGHT", -18, 50)

    local textPanelBg = textPanel:CreateTexture(nil, "BACKGROUND")
    textPanelBg:SetAllPoints()
    textPanelBg:SetColorTexture(0.035, 0.035, 0.04, 0.94)
    textPanel.TextPanelBg = textPanelBg

    local textPanelBorder = textPanel:CreateTexture(nil, "ARTWORK")
    textPanelBorder:SetPoint("TOPLEFT", textPanel, "TOPLEFT", 0, 0)
    textPanelBorder:SetPoint("BOTTOMRIGHT", textPanel, "BOTTOMRIGHT", 0, 0)
    textPanelBorder:SetColorTexture(0.55, 0.44, 0.25, 0.18)
    textPanel.TextPanelBorder = textPanelBorder

    DebugConsolePopup.TextPanel = textPanel

    local scrollFrame = CreateFrame("ScrollFrame", nil, textPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 8)
    DebugConsolePopup.ScrollFrame = scrollFrame

    local measureText = DebugConsolePopup:CreateFontString(nil, "OVERLAY")
    measureText:Hide()
    measureText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    measureText:SetJustifyH("LEFT")
    measureText:SetJustifyV("TOP")
    measureText:SetWidth(660)
    DebugConsolePopup.MeasureText = measureText

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    editBox:SetTextColor(1, 0.96, 0.86, 1)
    editBox:SetWidth(660)
    editBox:SetTextInsets(0, 0, 0, 0)
    editBox:SetJustifyH("LEFT")
    editBox:SetJustifyV("TOP")
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        DebugConsolePopup:Hide()
    end)
    editBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)
    editBox:SetScript("OnMouseUp", function(self)
        self:HighlightText()
    end)
    editBox:SetScript("OnCursorChanged", function(_, _, y, _, height)
        local visibleHeight = scrollFrame:GetHeight() or 0
        local currentScroll = scrollFrame:GetVerticalScroll() or 0
        if y < currentScroll then
            scrollFrame:SetVerticalScroll(y)
        elseif (y + height) > (currentScroll + visibleHeight) then
            scrollFrame:SetVerticalScroll(math.max(0, y + height - visibleHeight))
        end
    end)
    editBox:SetScript("OnTextChanged", function(self)
        measureText:SetWidth(math.max(1, self:GetWidth() or 660))
        measureText:SetText(self:GetText() or "")
        self:SetHeight(math.max(scrollFrame:GetHeight() or 1, measureText:GetStringHeight() + 12))
    end)
    scrollFrame:SetScrollChild(editBox)
    DebugConsolePopup.EditBox = editBox

    local closeButton = CreateFrame("Button", nil, DebugConsolePopup, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -4, -4)
    DebugConsolePopup.CloseButton = closeButton

    local closeActionButton = CreateFrame("Button", nil, DebugConsolePopup, "UIPanelButtonTemplate")
    closeActionButton:SetSize(110, 26)
    closeActionButton:SetPoint("BOTTOMRIGHT", DebugConsolePopup, "BOTTOMRIGHT", -16, 12)
    closeActionButton:SetText(L("CLOSE"))
    closeActionButton:SetScript("OnClick", function()
        DebugConsolePopup:Hide()
    end)
    DebugConsolePopup.CloseActionButton = closeActionButton

    return DebugConsolePopup
end

RefreshDebugConsolePopup = function()
    local popup = EnsureDebugConsolePopup()
    local entry = nil
    local moduleLabelText = nil

    if DebugConsoleState.selectedModuleKey then
        entry = GetDebugModuleEntry(DebugConsoleState.selectedModuleKey)
    end

    if entry then
        moduleLabelText = string.format(L("DEBUG_CONSOLE_MODULE"), tostring(entry.titleText or entry.key or ""))
    else
        moduleLabelText = L("DEBUG_CONSOLE_MODULE_NONE")
    end

    popup.Title:SetText(L("DEBUG_CONSOLE_TITLE"))
    popup.ModuleLabel:SetText(moduleLabelText)
    popup.Instructions:SetText(L("DEBUG_CONSOLE_COPY_HINT"))
    popup.EditBox:SetText(BuildDebugConsoleText(entry))
    popup.EditBox:SetCursorPosition(0)
    popup.ScrollFrame:SetVerticalScroll(0)
    popup.CloseActionButton:SetText(L("CLOSE"))
end

LinkPopupEditBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
    HideLinkPopup()
end)

LinkPopupEditBox:SetScript("OnEditFocusGained", function(self)
    self:HighlightText()
end)

local LinkCloseButton = CreateFrame("Button", nil, LinkPopup, "UIPanelButtonTemplate")
LinkCloseButton:SetSize(110, 26)
LinkCloseButton:SetPoint("BOTTOMRIGHT", LinkPopup, "BOTTOMRIGHT", -16, 12)
LinkCloseButton:SetText(L("CLOSE"))
LinkCloseButton:SetScript("OnClick", HideLinkPopup)

function DebugConsole.RegisterModule(moduleKey, options)
    return EnsureDebugModuleEntry(moduleKey, options)
end

function DebugConsole.Clear(moduleKey, options)
    local entry = EnsureDebugModuleEntry(moduleKey, options)
    if not entry then
        return nil
    end

    entry.lines = {}
    DebugConsoleState.latestModuleKey = entry.key

    if options and options.select == true then
        DebugConsoleState.selectedModuleKey = entry.key
    end

    if DebugConsolePopup and DebugConsolePopup:IsShown() and DebugConsoleState.selectedModuleKey == entry.key then
        RefreshDebugConsolePopup()
    end

    return entry
end

function DebugConsole.AppendLine(moduleKey, text, options)
    local entry = EnsureDebugModuleEntry(moduleKey, options)
    if not entry or text == nil then
        return nil
    end

    entry.lines = entry.lines or {}
    entry.lines[#entry.lines + 1] = tostring(text)
    DebugConsoleState.latestModuleKey = entry.key

    if not DebugConsoleState.selectedModuleKey or (options and options.select == true) then
        DebugConsoleState.selectedModuleKey = entry.key
    end

    if DebugConsolePopup and DebugConsolePopup:IsShown() and DebugConsoleState.selectedModuleKey == entry.key then
        RefreshDebugConsolePopup()
    end

    return entry
end

function DebugConsole.Open(moduleKey)
    local entry = nil
    if moduleKey and moduleKey ~= "" then
        entry = EnsureDebugModuleEntry(moduleKey)
    elseif DebugConsoleState.latestModuleKey then
        entry = GetDebugModuleEntry(DebugConsoleState.latestModuleKey)
    end

    if entry then
        DebugConsoleState.selectedModuleKey = entry.key
    end

    local popupParent = GetDebugConsoleParent()
    local popup = EnsureDebugConsolePopup()

    if popup:GetParent() ~= popupParent then
        popup:SetParent(popupParent)
    end

    popup:ClearAllPoints()
    popup:SetPoint("CENTER", popupParent, "CENTER", 0, 0)
    RefreshDebugConsolePopup()
    popup:Show()
    popup.EditBox:SetFocus()
    popup.EditBox:HighlightText()

    return true
end

BeavisQoL.UpdateUI = function()
    HeaderSubtitle:SetText(L("HEADER_SUBTITLE"))
    VersionBadgeText:SetText(L("VERSION") .. " " .. version)
    ReloadButton:SetText(L("RELOAD"))
    LinkPopupTitle:SetText(L("LINK_OPEN"))
    LinkPopupText:SetText(L("LINK_COPY_DESC"))
    LinkPopupHint:SetText(L("LINK_COPY_HINT"))
    LinkCloseButton:SetText(L("CLOSE"))

    if DebugConsolePopup then
        RefreshDebugConsolePopup()
    end
end

function BeavisQoL.ShowLinkPopup(titleText, urlText)
    if not urlText or urlText == "" then
        return
    end

    local popupParent = GetLinkPopupParent()
    if LinkPopup:GetParent() ~= popupParent then
        LinkPopup:SetParent(popupParent)
    end

    LinkPopup:ClearAllPoints()
    LinkPopup:SetPoint("CENTER", popupParent, "CENTER", 0, 0)
    LinkPopupTitle:SetText(titleText or L("LINK_OPEN"))
    LinkPopupEditBox:SetText(urlText)
    LinkPopup:Show()
    LinkPopupEditBox:SetFocus()
    LinkPopupEditBox:HighlightText()
end

BeavisQoL.HideLinkPopup = HideLinkPopup
BeavisQoL.ShowDebugConsole = function(moduleKey)
    return DebugConsole.Open(moduleKey)
end

