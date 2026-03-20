local ADDON_NAME, BeavisAddon = ...

-- Das Hauptfenster bauen wir hier einmal zentral auf. Alle anderen Dateien hängen sich später daran.
local BeavisFrame = CreateFrame("Frame", "BeavisMainFrame", UIParent, "BasicFrameTemplateWithInset")
BeavisFrame:SetSize(UIParent:GetWidth() * 0.7, UIParent:GetHeight() * 0.7)
BeavisFrame:RegisterForDrag("LeftButton")
BeavisFrame:SetScript("OnDragStart", BeavisFrame.StartMoving)
BeavisFrame:SetScript("OnDragStop", BeavisFrame.StopMovingOrSizing)
BeavisFrame:SetMovable(true)
BeavisFrame:EnableMouse(true)
BeavisFrame:SetPoint("CENTER")
BeavisFrame:SetToplevel(true)
BeavisFrame:SetFrameStrata("HIGH")
BeavisFrame:Hide()

BeavisAddon.Frame = BeavisFrame

if UISpecialFrames then
    local alreadyRegistered = false

    -- Nur Frames in UISpecialFrames reagieren auf ESC. Darum tragen wir uns hier einmal ein.
    for _, frameName in ipairs(UISpecialFrames) do
        if frameName == "BeavisMainFrame" then
            alreadyRegistered = true
            break
        end
    end

    if not alreadyRegistered then
        table.insert(UISpecialFrames, "BeavisMainFrame")
    end
end

-- Die Fenstergröße ziehen wir bei UI-Änderungen nach.
-- So bleibt das Verhältnis auf kleinen und großen Auflösungen halbwegs gleich.
local function UpdateBeavisFrameSize()
    local width = UIParent:GetWidth() * 0.7
    local height = UIParent:GetHeight() * 0.7
    BeavisFrame:SetSize(width, height)
end

-- Einmal direkt ausführen, damit die Startgröße sofort stimmt.
UpdateBeavisFrameSize()

-- Die paar Events reichen hier aus. Permanentes Polling wäre nur unnötig.
local resizeWatcher = CreateFrame("Frame")
resizeWatcher:RegisterEvent("UI_SCALE_CHANGED")
resizeWatcher:RegisterEvent("DISPLAY_SIZE_CHANGED")
resizeWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Alle Größen-Events landen in derselben Funktion.
resizeWatcher:SetScript("OnEvent", function()
    UpdateBeavisFrameSize()
end)

-- Die Metadaten brauchen wir später an mehreren Stellen.
local version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "Unbekannt"
local name = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title") or "Unbekannt"

BeavisAddon.Version = version
BeavisAddon.Title = name

-- Header, Sidebar und Seitenbereich hängen direkt am Hauptfenster.
-- Header
local Header = CreateFrame("Frame", nil, BeavisFrame)
Header:SetPoint("TOPLEFT", BeavisFrame, "TOPLEFT", 8, -28)
Header:SetPoint("TOPRIGHT", BeavisFrame, "TOPRIGHT", -8, -28)
Header:SetHeight(72)

BeavisAddon.Header = Header

-- Eine schlichte Linie trennt den Header vom Rest des Fensters.
local HeaderBorder = Header:CreateTexture(nil, "ARTWORK")
HeaderBorder:SetPoint("BOTTOMLEFT", Header, "BOTTOMLEFT", 0, 0)
HeaderBorder:SetPoint("BOTTOMRIGHT", Header, "BOTTOMRIGHT", 0, 0)
HeaderBorder:SetHeight(1)
HeaderBorder:SetColorTexture(1, 0.82, 0, 0.9)

-- Logo und Titel sitzen links im Header.
local Logo = Header:CreateTexture(nil, "ARTWORK")
Logo:SetSize(64, 64)
Logo:SetPoint("LEFT", Header, "LEFT", 12, 0)
Logo:SetTexture("Interface\\AddOns\\BeavisAddon\\Media\\logo.tga")

local Title = Header:CreateFontString(nil, "OVERLAY")
Title:SetPoint("LEFT", Logo, "RIGHT", 12, 0)
Title:SetFontObject(GameFontNormalHuge)
Title:SetTextColor(1, 0.82, 0, 1)
Title:SetFont("Fonts\\FRIZQT__.TTF", 28, "OUTLINE")
Title:SetText(name)

-- Sidebar
local Sidebar = CreateFrame("Frame", nil, BeavisFrame)
Sidebar:SetPoint("TOPLEFT", BeavisFrame, "TOPLEFT", 8, -110)
Sidebar:SetPoint("BOTTOMLEFT", BeavisFrame, "BOTTOMLEFT", 8, 8)
Sidebar:SetWidth(180)

BeavisAddon.Sidebar = Sidebar

-- Die Sidebar bekommt nur einen leichten Hintergrund und eine rechte Trennlinie.
local SidebarBg = Sidebar:CreateTexture(nil, "BACKGROUND")
SidebarBg:SetAllPoints()
SidebarBg:SetColorTexture(0.05, 0.05, 0.05, 0.85)

local SidebarRightBorder = Sidebar:CreateTexture(nil, "ARTWORK")
SidebarRightBorder:SetPoint("TOPRIGHT", Sidebar, "TOPRIGHT", 0, 0)
SidebarRightBorder:SetPoint("BOTTOMRIGHT", Sidebar, "BOTTOMRIGHT", 0, 0)
SidebarRightBorder:SetWidth(1)
SidebarRightBorder:SetColorTexture(1, 0.82, 0, 0.9)

-- Im Content-Bereich liegen später alle Seiten deckungsgleich übereinander.
local Content = CreateFrame("Frame", nil, BeavisFrame)
Content:SetPoint("TOPLEFT", Sidebar, "TOPRIGHT", 8, 0)
Content:SetPoint("BOTTOMRIGHT", BeavisFrame, "BOTTOMRIGHT", -8, 8)

BeavisAddon.Content = Content

local ContentBg = Content:CreateTexture(nil, "BACKGROUND")
ContentBg:SetAllPoints()
ContentBg:SetColorTexture(0.08, 0.08, 0.08, 0.65)

-- Das Copy-Popup hängt zentral am Hauptfenster, damit Home und Version dieselbe Lösung nutzen.
local LinkPopup = CreateFrame("Frame", nil, BeavisFrame)
LinkPopup:SetSize(520, 170)
LinkPopup:SetPoint("CENTER", BeavisFrame, "CENTER", 0, 0)
LinkPopup:SetFrameStrata("DIALOG")
LinkPopup:EnableMouse(true)
LinkPopup:Hide()

local LinkPopupBg = LinkPopup:CreateTexture(nil, "BACKGROUND")
LinkPopupBg:SetAllPoints()
LinkPopupBg:SetColorTexture(0.06, 0.06, 0.06, 0.96)

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
LinkPopupTitle:SetText("Link öffnen")

local LinkPopupText = LinkPopup:CreateFontString(nil, "OVERLAY")
LinkPopupText:SetPoint("TOPLEFT", LinkPopupTitle, "BOTTOMLEFT", 0, -10)
LinkPopupText:SetPoint("RIGHT", LinkPopup, "RIGHT", -16, 0)
LinkPopupText:SetJustifyH("LEFT")
LinkPopupText:SetJustifyV("TOP")
LinkPopupText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
LinkPopupText:SetTextColor(1, 1, 1, 1)
LinkPopupText:SetText("World of Warcraft erlaubt Addons nicht, Webseiten direkt zu öffnen. Du kannst die Adresse hier markieren und kopieren:")

local LinkPopupEditBox = CreateFrame("EditBox", nil, LinkPopup, "InputBoxTemplate")
LinkPopupEditBox:SetSize(470, 30)
LinkPopupEditBox:SetPoint("TOPLEFT", LinkPopupText, "BOTTOMLEFT", 0, -14)
LinkPopupEditBox:SetAutoFocus(false)
LinkPopupEditBox:SetFontObject(ChatFontNormal)

local LinkPopupHint = LinkPopup:CreateFontString(nil, "OVERLAY")
LinkPopupHint:SetPoint("TOPLEFT", LinkPopupEditBox, "BOTTOMLEFT", 4, -10)
LinkPopupHint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
LinkPopupHint:SetTextColor(0.75, 0.75, 0.75, 1)
LinkPopupHint:SetText("Tipp: Link markieren und mit Strg+C kopieren.")

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
LinkCloseButton:SetText("Schließen")
LinkCloseButton:SetScript("OnClick", HideLinkPopup)

function BeavisAddon.ShowLinkPopup(titleText, urlText)
    if not urlText or urlText == "" then
        return
    end

    LinkPopupTitle:SetText(titleText or "Link öffnen")
    LinkPopupEditBox:SetText(urlText)
    LinkPopup:Show()
    LinkPopupEditBox:SetFocus()
    LinkPopupEditBox:HighlightText()
end
