local ADDON_NAME, BeavisQoL = ...

--[[
UI.lua baut das feste Grundgeruest des Addons.

Hier entsteht nur der gemeinsame Rahmen:
- Hauptfenster
- Header
- Sidebar
- Content-Flaeche
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

local L = BeavisQoL.L
local version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or L("UNKNOWN")
local name = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title") or L("UNKNOWN")

BeavisQoL.Version = version
BeavisQoL.Title = name

local BeavisFrame = CreateFrame("Frame", "BeavisQoLMainFrame", UIParent, "BasicFrameTemplateWithInset")
BeavisFrame:SetPoint("CENTER")
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
    local maxWidth = math.max(900, UIParent:GetWidth() - 48)
    local maxHeight = math.max(620, UIParent:GetHeight() - 64)
    local minWidth = math.min(1120, maxWidth)
    local minHeight = math.min(720, maxHeight)
    local width = Clamp(UIParent:GetWidth() * 0.76, minWidth, maxWidth)
    local height = Clamp(UIParent:GetHeight() * 0.78, minHeight, maxHeight)
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
Header:SetPoint("TOPLEFT", BeavisFrame, "TOPLEFT", 8, -26)
Header:SetPoint("TOPRIGHT", BeavisFrame, "TOPRIGHT", -8, -26)
Header:SetHeight(88)

BeavisQoL.Header = Header

local HeaderBg = Header:CreateTexture(nil, "BACKGROUND")
HeaderBg:SetAllPoints()
HeaderBg:SetColorTexture(0.045, 0.045, 0.05, 0.94)

local HeaderGlow = Header:CreateTexture(nil, "BORDER")
HeaderGlow:SetPoint("TOPLEFT", Header, "TOPLEFT", 0, 0)
HeaderGlow:SetPoint("TOPRIGHT", Header, "TOPRIGHT", 0, 0)
HeaderGlow:SetHeight(34)
HeaderGlow:SetColorTexture(1, 0.82, 0, 0.06)

local HeaderBorder = Header:CreateTexture(nil, "ARTWORK")
HeaderBorder:SetPoint("BOTTOMLEFT", Header, "BOTTOMLEFT", 0, 0)
HeaderBorder:SetPoint("BOTTOMRIGHT", Header, "BOTTOMRIGHT", 0, 0)
HeaderBorder:SetHeight(1)
HeaderBorder:SetColorTexture(1, 0.82, 0, 0.9)

local Logo = Header:CreateTexture(nil, "ARTWORK")
Logo:SetSize(64, 64)
Logo:SetPoint("LEFT", Header, "LEFT", 14, 2)
Logo:SetTexture("Interface\\AddOns\\BeavisQoL\\Media\\logo.tga")

local Title = Header:CreateFontString(nil, "OVERLAY")
Title:SetPoint("TOPLEFT", Logo, "TOPRIGHT", 14, -6)
Title:SetPoint("RIGHT", Header, "RIGHT", -190, 0)
Title:SetJustifyH("LEFT")
Title:SetFont("Fonts\\FRIZQT__.TTF", 28, "OUTLINE")
Title:SetTextColor(1, 0.82, 0, 1)
Title:SetText(name)

local HeaderSubtitle = Header:CreateFontString(nil, "OVERLAY")
HeaderSubtitle:SetPoint("TOPLEFT", Title, "BOTTOMLEFT", 0, -6)
HeaderSubtitle:SetPoint("RIGHT", Header, "RIGHT", -190, 0)
HeaderSubtitle:SetJustifyH("LEFT")
HeaderSubtitle:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
HeaderSubtitle:SetTextColor(0.82, 0.82, 0.84, 1)
HeaderSubtitle:SetText(L("HEADER_SUBTITLE"))

local VersionContainer = CreateFrame("Frame", nil, Header)
VersionContainer:SetPoint("TOPRIGHT", Header, "TOPRIGHT", -16, -8)
VersionContainer:SetSize(180, 44)

local VersionBadge = CreateFrame("Frame", nil, VersionContainer)
VersionBadge:SetPoint("TOPRIGHT", VersionContainer, "TOPRIGHT", 0, 0)
VersionBadge:SetSize(148, 24)

local VersionBadgeBg = VersionBadge:CreateTexture(nil, "BACKGROUND")
VersionBadgeBg:SetAllPoints()
VersionBadgeBg:SetColorTexture(1, 0.82, 0, 0.08)

local VersionBadgeAccent = VersionBadge:CreateTexture(nil, "ARTWORK")
VersionBadgeAccent:SetPoint("TOPLEFT", VersionBadge, "TOPLEFT", 0, 0)
VersionBadgeAccent:SetPoint("BOTTOMLEFT", VersionBadge, "BOTTOMLEFT", 0, 0)
VersionBadgeAccent:SetWidth(2)
VersionBadgeAccent:SetColorTexture(1, 0.82, 0, 0.8)

local VersionBadgeText = VersionBadge:CreateFontString(nil, "OVERLAY")
VersionBadgeText:SetPoint("LEFT", VersionBadge, "LEFT", 8, 0)
VersionBadgeText:SetPoint("RIGHT", VersionBadge, "RIGHT", -8, 0)
VersionBadgeText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
VersionBadgeText:SetTextColor(1, 0.92, 0.45, 1)
VersionBadgeText:SetJustifyH("CENTER")
VersionBadgeText:SetText(L("VERSION") .. " " .. version)

local ReloadButton = CreateFrame("Button", nil, VersionContainer, "UIPanelButtonTemplate")
ReloadButton:SetSize(148, 18)
ReloadButton:SetPoint("BOTTOMRIGHT", VersionContainer, "BOTTOMRIGHT", 0, 0)
ReloadButton:SetText(L("RELOAD"))
ReloadButton:SetNormalFontObject("GameFontNormalSmall")
ReloadButton:SetHighlightFontObject("GameFontHighlightSmall")
ReloadButton:SetScript("OnClick", function()
    ReloadUI()
end)

local Sidebar = CreateFrame("Frame", nil, BeavisFrame)
Sidebar:SetPoint("TOPLEFT", BeavisFrame, "TOPLEFT", 10, -124)
Sidebar:SetPoint("BOTTOMLEFT", BeavisFrame, "BOTTOMLEFT", 10, 10)
Sidebar:SetWidth(228)

BeavisQoL.Sidebar = Sidebar

local SidebarBg = Sidebar:CreateTexture(nil, "BACKGROUND")
SidebarBg:SetAllPoints()
SidebarBg:SetColorTexture(0.035, 0.035, 0.04, 0.92)

local SidebarGlow = Sidebar:CreateTexture(nil, "BORDER")
SidebarGlow:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", 0, 0)
SidebarGlow:SetPoint("TOPRIGHT", Sidebar, "TOPRIGHT", 0, 0)
SidebarGlow:SetHeight(38)
SidebarGlow:SetColorTexture(1, 0.82, 0, 0.035)

local SidebarRightBorder = Sidebar:CreateTexture(nil, "ARTWORK")
SidebarRightBorder:SetPoint("TOPRIGHT", Sidebar, "TOPRIGHT", 0, 0)
SidebarRightBorder:SetPoint("BOTTOMRIGHT", Sidebar, "BOTTOMRIGHT", 0, 0)
SidebarRightBorder:SetWidth(1)
SidebarRightBorder:SetColorTexture(1, 0.82, 0, 0.9)

local Content = CreateFrame("Frame", nil, BeavisFrame)
Content:SetPoint("TOPLEFT", Sidebar, "TOPRIGHT", 14, 0)
Content:SetPoint("BOTTOMRIGHT", BeavisFrame, "BOTTOMRIGHT", -10, 10)

BeavisQoL.Content = Content

local ContentBg = Content:CreateTexture(nil, "BACKGROUND")
ContentBg:SetAllPoints()
ContentBg:SetColorTexture(0.055, 0.055, 0.06, 0.78)

local ContentGlow = Content:CreateTexture(nil, "BORDER")
ContentGlow:SetPoint("TOPLEFT", Content, "TOPLEFT", 0, 0)
ContentGlow:SetPoint("TOPRIGHT", Content, "TOPRIGHT", 0, 0)
ContentGlow:SetHeight(44)
ContentGlow:SetColorTexture(1, 1, 1, 0.025)

local ContentTopBorder = Content:CreateTexture(nil, "ARTWORK")
ContentTopBorder:SetPoint("TOPLEFT", Content, "TOPLEFT", 0, 0)
ContentTopBorder:SetPoint("TOPRIGHT", Content, "TOPRIGHT", 0, 0)
ContentTopBorder:SetHeight(1)
ContentTopBorder:SetColorTexture(1, 0.82, 0, 0.35)

local LinkPopup = CreateFrame("Frame", nil, BeavisFrame)
LinkPopup:SetSize(520, 170)
LinkPopup:SetPoint("CENTER", BeavisFrame, "CENTER", 0, 0)
LinkPopup:SetFrameStrata("DIALOG")
LinkPopup:EnableMouse(true)
LinkPopup:Hide()

local LinkPopupBg = LinkPopup:CreateTexture(nil, "BACKGROUND")
LinkPopupBg:SetAllPoints()
LinkPopupBg:SetColorTexture(0.06, 0.06, 0.06, 0.96)

local LinkPopupGlow = LinkPopup:CreateTexture(nil, "BORDER")
LinkPopupGlow:SetPoint("TOPLEFT", LinkPopup, "TOPLEFT", 0, 0)
LinkPopupGlow:SetPoint("TOPRIGHT", LinkPopup, "TOPRIGHT", 0, 0)
LinkPopupGlow:SetHeight(26)
LinkPopupGlow:SetColorTexture(1, 0.82, 0, 0.08)

local LinkPopupBorderTop = LinkPopup:CreateTexture(nil, "ARTWORK")
LinkPopupBorderTop:SetPoint("TOPLEFT", LinkPopup, "TOPLEFT", 0, 0)
LinkPopupBorderTop:SetPoint("TOPRIGHT", LinkPopup, "TOPRIGHT", 0, 0)
LinkPopupBorderTop:SetHeight(1)
LinkPopupBorderTop:SetColorTexture(1, 0.82, 0, 0.9)

local LinkPopupBorderBottom = LinkPopup:CreateTexture(nil, "ARTWORK")
LinkPopupBorderBottom:SetPoint("BOTTOMLEFT", LinkPopup, "BOTTOMLEFT", 0, 0)
LinkPopupBorderBottom:SetPoint("BOTTOMRIGHT", LinkPopup, "BOTTOMRIGHT", 0, 0)
LinkPopupBorderBottom:SetHeight(1)
LinkPopupBorderBottom:SetColorTexture(1, 0.82, 0, 0.9)

local LinkPopupTitle = LinkPopup:CreateFontString(nil, "OVERLAY")
LinkPopupTitle:SetPoint("TOPLEFT", LinkPopup, "TOPLEFT", 16, -14)
LinkPopupTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
LinkPopupTitle:SetTextColor(1, 0.82, 0, 1)
LinkPopupTitle:SetText(L("LINK_OPEN"))

local LinkPopupText = LinkPopup:CreateFontString(nil, "OVERLAY")
LinkPopupText:SetPoint("TOPLEFT", LinkPopupTitle, "BOTTOMLEFT", 0, -10)
LinkPopupText:SetPoint("RIGHT", LinkPopup, "RIGHT", -16, 0)
LinkPopupText:SetJustifyH("LEFT")
LinkPopupText:SetJustifyV("TOP")
LinkPopupText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
LinkPopupText:SetTextColor(1, 1, 1, 1)
LinkPopupText:SetText(L("LINK_COPY_DESC"))

local LinkPopupEditBox = CreateFrame("EditBox", nil, LinkPopup, "InputBoxTemplate")
LinkPopupEditBox:SetSize(470, 30)
LinkPopupEditBox:SetPoint("TOPLEFT", LinkPopupText, "BOTTOMLEFT", 0, -14)
LinkPopupEditBox:SetAutoFocus(false)
LinkPopupEditBox:SetFontObject(ChatFontNormal)

local LinkPopupHint = LinkPopup:CreateFontString(nil, "OVERLAY")
LinkPopupHint:SetPoint("TOPLEFT", LinkPopupEditBox, "BOTTOMLEFT", 4, -10)
LinkPopupHint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
LinkPopupHint:SetTextColor(0.75, 0.75, 0.75, 1)
LinkPopupHint:SetText(L("LINK_COPY_HINT"))

local function HideLinkPopup()
    LinkPopupEditBox:ClearFocus()
    LinkPopup:Hide()
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

BeavisQoL.UpdateUI = function()
    HeaderSubtitle:SetText(L("HEADER_SUBTITLE"))
    VersionBadgeText:SetText(L("VERSION") .. " " .. version)
    ReloadButton:SetText(L("RELOAD"))
    LinkPopupTitle:SetText(L("LINK_OPEN"))
    LinkPopupText:SetText(L("LINK_COPY_DESC"))
    LinkPopupHint:SetText(L("LINK_COPY_HINT"))
    LinkCloseButton:SetText(L("CLOSE"))
end

function BeavisQoL.ShowLinkPopup(titleText, urlText)
    if not urlText or urlText == "" then
        return
    end

    LinkPopupTitle:SetText(titleText or L("LINK_OPEN"))
    LinkPopupEditBox:SetText(urlText)
    LinkPopup:Show()
    LinkPopupEditBox:SetFocus()
    LinkPopupEditBox:HighlightText()
end
